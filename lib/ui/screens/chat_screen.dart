import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/models/models.dart';
import '../../api/protocol.dart';
import '../../app/chat.dart';
import '../../app/layout.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/session.dart';
import '../../app/system.dart';
import '../../attachments/attachment_store.dart';
import '../../attachments/composer_attachments.dart';
import '../../attachments/image_prep.dart';
import '../../attachments/picker.dart';
import '../../data/db/database.dart';
import '../../general/general_database.dart' show GeneralMetaKeys;
import '../../general/general_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../sync/connection_status.dart';
import '../../sync/live_runs.dart';
import '../../sync/sync_engine.dart';
import '../../sync/sync_providers.dart';
import '../../theme/delve_theme.dart';
import '../chat/attachments.dart';
import '../chat/chat_items.dart';
import '../chat/composer.dart';
import '../chat/usage.dart';
import '../desktop/areas.dart';
import '../desktop/chat_find.dart';
import '../desktop/chat_inspector.dart';
import '../desktop/intake.dart';
import '../desktop/panes.dart';
import '../format.dart';
import '../general/general_widgets.dart'
    show ChatKind, ChatKindSwitch, GeneralThinkingPill, chatKindOf;
import '../widgets/chat_row.dart';
import '../widgets/delve_mark.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/status_ui.dart';
import 'general_chat_screen.dart';

final _createdMessageProvider = StreamProvider.autoDispose
    .family<MessageRow?, String>(
      (ref, clientMsgId) =>
          ref.watch(databaseProvider).watchMessageByClientId(clientMsgId),
    );

final _outboxRowProvider = StreamProvider.autoDispose
    .family<OutboxRow?, String>(
      (ref, clientMsgId) =>
          ref.watch(databaseProvider).watchOutboxRow(clientMsgId),
    );

/// A new chat opened with something to say (design 21g): [text] fills the
/// composer ("Change the watch …"), [watchHint] shows how to describe a
/// watch with two examples that fill it.
@immutable
class NewChatDraft {
  const NewChatDraft({this.text = '', this.watchHint = false});
  final String text;
  final bool watchHint;
}

/// 03–10 Chat (detail, no bottom nav). [conversationId] is null for a new
/// chat: its first message creates the conversation, and the screen moves to
/// it once the server has made a message of the outbox entry.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
    this.firstClientMsgId,
    this.draft,
    this.kind,
  });

  final String? conversationId;

  /// A new chat's kind chosen before it opened (the desktop's Ctrl+N /
  /// Ctrl+Shift+N); null: the remembered choice.
  final ChatKind? kind;

  /// A new chat's starting text and hint (New watch, Change in chat).
  final NewChatDraft? draft;

  /// A new chat whose first message was sent elsewhere (Share to Delve): the
  /// screen shows its outbox entry and moves to the conversation like after
  /// its own Send.
  final String? firstClientMsgId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  /// New chat: the outbox entry of the first message.
  String? _firstClientMsgId;

  /// The new chat exists; the screen is moving to it.
  bool _moving = false;

  /// The last outbox entry of the first message seen: shown on if the entry
  /// is gone a frame before the message made of it is (two streams).
  OutboxRow? _lastOutbox;
  ChatActions? _opened;

  /// Thinking for a new chat (sent with its first message).
  bool _newThinking = false;

  /// A new chat: Agent or General as chosen here; null: the remembered
  /// choice.
  ChatKind? _kind;

  /// An existing chat's Thinking switch while the server has not confirmed
  /// it yet.
  bool? _thinkingPending;

  /// "Applies to your next message" under the composer, for 2 s.
  Timer? _captionTimer;
  bool _caption = false;

  /// The photos and files of the next message (kept when a new chat moves to
  /// its conversation: same state).
  late final ComposerAttachments _attachments;

  /// The message field (filled from [ChatScreen.draft]).
  late final TextEditingController _text;

  /// The desktop's chat keys go to the chat that is open (L2b2).
  late final ChatCommandSlot _slot;
  late final ChatCommands _commands = ChatCommands(
    attachFile: _attachFromKey,
    paste: _paste,
    stop: _stopOpenRun,
    toggleThinking: _toggleThinking,
    find: _openFind,
  );

  /// Ctrl+F in the chat (L2b2) and the item it shows.
  final ChatFind _find = ChatFind();
  final FindScroller _scroller = FindScroller();

  @override
  void initState() {
    super.initState();
    _slot = ref.read(chatCommandSlotProvider);
    _find.addListener(_findChanged);
    _kind = widget.kind;
    _text = TextEditingController(text: widget.draft?.text ?? '');
    _attachments = ComposerAttachments(
      api: () => mounted ? ref.read(attachmentApiProvider) : null,
      prep: ref.read(imagePrepProvider),
      cache: ref.read(attachmentCacheProvider),
    );
    _firstClientMsgId = widget.firstClientMsgId;
    final id = widget.conversationId;
    if (id != null) _openAfterFrame(id);
    // what the loaded model can do (images, thinking) shapes the composer;
    // the view is only kept fresh while the dashboard or System is open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || ref.read(systemProvider).info != null) return;
      unawaited(
        ref.read(systemProvider.notifier).refresh().catchError((Object _) {}),
      );
    });
  }

  /// A new chat moves to its conversation with `replace`, which keeps this
  /// state (no second transition): the new id is opened here, not in
  /// [initState].
  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final id = widget.conversationId;
    if (id != null && id != oldWidget.conversationId) _openAfterFrame(id);
    // a share sent to a new chat while this new chat was open
    final first = widget.firstClientMsgId;
    if (id == null && first != null && first != oldWidget.firstClientMsgId) {
      _firstClientMsgId = first;
      _lastOutbox = null;
      _moving = false;
    }
  }

  void _openAfterFrame(String id) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _opened?.close();
      final actions = ref.read(chatActionsProvider);
      _opened = actions;
      if (actions != null) unawaited(actions.open(id));
    });
  }

  @override
  void dispose() {
    _slot.unregister(this);
    _find.dispose();
    _captionTimer?.cancel();
    _opened?.close();
    _attachments.dispose();
    _text.dispose();
    super.dispose();
  }

  void _showCaption() {
    _captionTimer?.cancel();
    setState(() => _caption = true);
    _captionTimer = Timer(DelveTokens.caption, () {
      if (mounted) setState(() => _caption = false);
    });
  }

  /// Thinking for the next message: local for a new chat, otherwise saved
  /// on the server (the pill shows the wanted state until it answers).
  Future<void> _setThinking(bool on) async {
    final id = widget.conversationId;
    _showCaption();
    if (id == null) {
      setState(() => _newThinking = on);
      return;
    }
    final l = AppLocalizations.of(context);
    final actions = ref.read(chatActionsProvider);
    if (actions == null) return;
    setState(() => _thinkingPending = on);
    try {
      await actions.setThinking(id, thinking: on);
    } on Exception catch (e) {
      if (mounted) _snack(l.thinkingFailed(apiErrorText(l, e)));
    } finally {
      if (mounted) setState(() => _thinkingPending = null);
    }
  }

  Widget _pill({required bool on}) => ThinkingPill(
    on: on,
    onChanged: ref.watch(chatActionsProvider) == null
        ? null
        : (v) => unawaited(_setThinking(v)),
  );

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  static String _syncErrorText(AppLocalizations l, Object e) => switch (e) {
    NotConnected() => l.chatNotConnected,
    NoAnswer() => l.chatNoAnswer,
    RequestRejected(:final message?) when message.isNotEmpty => message,
    RequestRejected(:final code) => code,
    _ => '$e',
  };

  /// The composer's text and uploaded attachments.
  Future<void> _sendComposer(String text) async {
    await _send(text, attachments: _attachments.ready);
    _attachments.clear();
  }

  Future<void> _send(
    String text, {
    List<Attachment> attachments = const [],
  }) async {
    final actions = ref.read(chatActionsProvider);
    if (actions == null) return;
    final id = await actions.send(
      text,
      conversationId: widget.conversationId,
      thinking: widget.conversationId == null ? _newThinking : null,
      attachments: attachments,
    );
    if (widget.conversationId == null && mounted) {
      setState(() {
        _firstClientMsgId = id;
        _lastOutbox = null;
      });
    }
  }

  /// Retry of a failed run: its message again, with copies of its
  /// attachments (an id can be sent once); deleted ones are left out.
  Future<void> _resend(MessageRow asked) async {
    final l = AppLocalizations.of(context);
    final api = ref.read(attachmentApiProvider);
    final copies = <Attachment>[];
    if (api != null) {
      try {
        for (final a in asked.attachments) {
          if (a.available) copies.add(await api.copy(a.id));
        }
      } on Exception catch (e) {
        if (mounted) _snack(l.attachCopyFailed(apiErrorText(l, e)));
        return;
      }
    }
    if (asked.content.trim().isEmpty && copies.isEmpty) return;
    await _send(asked.content, attachments: copies);
  }

  // --- attachments --------------------------------------------------------------

  /// "+": Photos, Camera or File; what is picked starts uploading at once.
  Future<void> _addAttachments() {
    final llama = ref.read(systemProvider).info?.llama;
    _dropIdleFocus();
    return pickAttachmentsInto(
      context,
      ref.read(attachmentPickerProvider),
      _attachments,
      noImagesModel: llama?.vision == false ? _modelName(llama!) : null,
    );
  }

  /// The loaded (stopped: the selected) model's name without its
  /// quantization, for a sentence.
  String _modelName(LlamaInfo llama) =>
      llama.model ??
      llama.presetNamed(llama.preset)?.model ??
      AppLocalizations.of(context).modelThisModel;

  /// A photo full screen, a file's details; both offer "Send again".
  void _openAttachment(Attachment a) {
    void again() => _sendAgain(a);
    final canAgain = a.available;
    if (a.isImage && a.available) {
      unawaited(
        AttachmentViewer.open(context, a, onSendAgain: canAgain ? again : null),
      );
    } else {
      _dropIdleFocus();
      unawaited(
        showFileSheet(context, a, onSendAgain: canAgain ? again : null),
      );
    }
  }

  void _sendAgain(Attachment a) {
    final l = AppLocalizations.of(context);
    final preview = a.isImage
        ? ref.read(attachmentCacheProvider).get(a.id)
        : null;
    if (_attachments.addCopy(a, preview: preview)) {
      _snack(l.attachAdded);
    } else {
      _snack(l.attachLimit(kMaxAttachments));
    }
  }

  // --- the desktop: drop, paste and keys (L2b2) -----------------------------------

  /// The note when the loaded model reads no images (they are left out).
  String? _noImagesNote() {
    final llama = ref.read(systemProvider).info?.llama;
    if (llama == null || llama.vision != false) return null;
    return AppLocalizations.of(context).modelCantReadImages(_modelName(llama));
  }

  bool get _canAttachNow =>
      ref.read(attachmentApiProvider) != null &&
      ref.read(connectionStatusProvider).value?.phase == ConnectionPhase.live;

  /// A drop, a paste: into the composer, as “+” would add them.
  void _addPicked(List<PickedAttachment> picked) {
    if (picked.isEmpty) return;
    if (!_canAttachNow) {
      _snack(AppLocalizations.of(context).attachNeedsConnection);
      return;
    }
    addPickedInto(context, _attachments, picked, refuseImages: _noImagesNote());
  }

  void _dropped(List<String> paths) =>
      _addPicked([for (final p in paths) ?pickedFromPath(p)]);

  /// Ctrl+V: an image or files from the clipboard; false for text.
  Future<bool> _paste() async {
    final content = await ref.read(desktopPasteboardProvider).read();
    if (!mounted) return false;
    final picked = pickedOfPaste(content);
    if (picked == null) return false;
    _addPicked(picked);
    return true;
  }

  /// Ctrl+O: the file dialog, as “+”.
  void _attachFromKey() {
    if (!_canAttachNow) {
      _snack(AppLocalizations.of(context).attachNeedsConnection);
      return;
    }
    unawaited(_addAttachments());
  }

  /// Ctrl+.: the chat's open run stops.
  void _stopOpenRun() {
    final id = widget.conversationId;
    final target = id == null
        ? null
        : ref.read(chatProvider(id)).value?.openRuns.firstOrNull;
    if (target != null) unawaited(_stop(target.runId));
  }

  /// Ctrl+T: Thinking for the next message, where the model lets it change.
  void _toggleThinking() {
    final llama = ref.read(systemProvider).info?.llama;
    if (llama?.thinking == 'always' || llama?.thinking == 'none') return;
    if (ref.read(chatActionsProvider) == null) return;
    final id = widget.conversationId;
    final on = id == null
        ? _newThinking
        : _thinkingPending ??
              ref.read(chatProvider(id)).value?.conversation?.thinking ??
              false;
    unawaited(_setThinking(!on));
  }

  void _findChanged() {
    if (mounted) setState(() {});
  }

  /// Ctrl+F: search in this chat (a new chat has nothing to find).
  void _openFind() {
    if (widget.conversationId != null) _find.show();
  }

  /// What Ctrl+F searches, item by item as [_items] lays them out.
  static List<String> _texts(ChatData data) => [
    for (final m in data.messages) '${m.content}\n${m.interim ?? ''}',
    for (final o in data.outbox) o.body,
  ];

  /// The desktop: this chat takes the chat keys while it is built.
  void _takeKeys(BuildContext context) {
    if (DesktopLayout.of(context)) _slot.register(this, _commands);
  }

  Widget _composer({
    required bool connected,
    VoidCallback? onStop,
    int queued = 0,
    required bool thinking,
    bool autofocus = false,
  }) {
    final l = AppLocalizations.of(context);
    final canAttach = connected && ref.watch(attachmentApiProvider) != null;
    // 25h: the pill follows what the loaded model can do - a switch, locked
    // on (it always thinks) or gone (it cannot); the chat's choice is kept
    final llama = ref.watch(systemProvider.select((v) => v.info?.llama));
    return Composer(
      onSend: _sendComposer,
      onStop: onStop,
      queued: queued,
      leading: [
        if (llama?.thinking == 'always')
          GeneralThinkingPill(
            on: true,
            locked: true,
            label: l.composerThinking,
            lockedTip: l.modelAlwaysThinks(_modelName(llama!)),
          )
        else if (llama?.thinking != 'none')
          _pill(on: thinking),
      ],
      caption: _caption ? l.composerThinkingCaption : null,
      attachments: _attachments,
      onAdd: canAttach ? () => unawaited(_addAttachments()) : null,
      attachmentsAllowed: connected,
      controller: _text,
      onPaste: DesktopLayout.of(context) ? _paste : null,
      autofocus: autofocus,
    );
  }

  Future<void> _stop(String runId) async {
    final l = AppLocalizations.of(context);
    final actions = ref.read(chatActionsProvider);
    if (actions == null) return;
    try {
      await actions.stop(runId);
    } on Exception catch (e) {
      if (mounted) _snack(l.chatStopFailed(_syncErrorText(l, e)));
    }
  }

  /// Answers an approval in the chat over the socket (decision 246).
  Future<void> _answer(ApprovalRow approval, ApprovalChoice choice) async {
    final l = AppLocalizations.of(context);
    final actions = ref.read(chatActionsProvider);
    if (actions == null) return;
    try {
      await actions.answer(approval.requestId, choice);
    } on Exception catch (e) {
      if (mounted) _snack(l.approvalFailed(_syncErrorText(l, e)));
    }
  }

  /// Before a sheet opens. Closing it gives the focus back to the composer,
  /// which would open the keyboard: when the keyboard was closed before (the
  /// field may still hold the focus after Back hid it), the focus goes first.
  void _dropIdleFocus() {
    if (MediaQuery.viewInsetsOf(context).bottom == 0) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  /// Usage sheet.
  Future<void> _openUsage(String id, String title) async {
    _dropIdleFocus();
    await showUsageSheet(context, conversationId: id, title: title);
  }

  /// The user's own message in the moment between its outbox entry and the
  /// chat that holds it (a new chat moving to its conversation): the same
  /// bubble, so nothing blinks.
  Widget _writtenBubble(MessageRow m) => UserBubble(
    key: ValueKey('msg.${m.id}'),
    text: m.content,
    attachments: m.attachments,
    onOpenAttachment: _openAttachment,
  );

  /// A plain new chat offers Agent / General (not one opened with a draft
  /// or a shared first message, and not once its first message is sent).
  bool get _offersKinds =>
      widget.conversationId == null &&
      widget.draft == null &&
      _firstClientMsgId == null;

  void _chooseKind(ChatKind kind) {
    setState(() => _kind = kind);
    unawaited(
      ref
          .read(generalDatabaseProvider)
          .setMeta(GeneralMetaKeys.newChatKind, kind.name),
    );
  }

  Widget _kindSwitch(ChatKind kind) =>
      ChatKindSwitch(value: kind, onChanged: _chooseKind);

  @override
  Widget build(BuildContext context) {
    final id = widget.conversationId;
    if (id != null) return _buildChat(context, id);
    if (_offersKinds) {
      final remembered = ref.watch(
        generalMetaProvider(GeneralMetaKeys.newChatKind),
      );
      final kind =
          _kind ?? (remembered.isLoading ? null : chatKindOf(remembered.value));
      if (kind == null) {
        // one frame, while the remembered choice is read
        return Scaffold(
          appBar: _ChatAppBar(
            title: AppLocalizations.of(context).newChat,
            desktop: DesktopLayout.of(context),
          ),
        );
      }
      if (kind == ChatKind.general) {
        return GeneralChatScreen(
          key: const Key('general.new'),
          chatId: null,
          kindSwitch: _kindSwitch(kind),
        );
      }
    }
    return _buildNew(context);
  }

  // --- new chat (03) ----------------------------------------------------------

  Widget _buildNew(BuildContext context) {
    final l = AppLocalizations.of(context);
    _takeKeys(context);
    final first = _firstClientMsgId;
    // watched, not listened: the rebuild this triggers runs the post-frame
    // callback (a callback on its own schedules no frame); watched until the
    // chat shows, so the message stays on screen while the screen moves
    final created = first == null
        ? null
        : ref.watch(_createdMessageProvider(first)).value;
    if (created != null && !_moving) {
      _moving = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.replace(Routes.chat(created.conversationId));
      });
    }
    final current = first == null
        ? null
        : ref.watch(_outboxRowProvider(first)).value;
    if (current != null) _lastOutbox = current;
    final outbox =
        current ?? (first != null && created == null ? _lastOutbox : null);
    final host =
        ref.watch(sessionProvider.select((s) => s.credentials?.server.host)) ??
        '';
    final connected = ref.watch(
      connectionStatusProvider.select(
        (s) => s.value?.phase == ConnectionPhase.live,
      ),
    );

    // the outbox entry until the server's message is written, then that
    // message until the screen has moved to the conversation
    final Widget? sent = outbox != null
        ? OutboxBubble(
            row: outbox,
            onOpenAttachment: _openAttachment,
            onRetry: () => unawaited(
              ref.read(chatActionsProvider)?.retry(outbox.clientMsgId),
            ),
            onDiscard: () {
              unawaited(
                ref.read(chatActionsProvider)?.discard(outbox.clientMsgId),
              );
              setState(() {
                _firstClientMsgId = null;
                _lastOutbox = null;
              });
            },
          )
        : created != null
        ? _writtenBubble(created)
        : null;

    return Scaffold(
      appBar: _ChatAppBar(title: l.newChat, desktop: DesktopLayout.of(context)),
      body: DesktopDropZone(
        onPaths: _dropped,
        child: ReadingColumn(
          child: Column(
            children: [
              if (_offersKinds && sent == null) _kindSwitch(ChatKind.agent),
              Expanded(
                child: UnderBarFade(
                  fadeKey: const Key('chat.fade'),
                  child: sent == null
                      ? _NewChatIntro(host: host.split('.').first)
                      : ListView(
                          reverse: true,
                          padding: _listPadding,
                          children: [sent],
                        ),
                ),
              ),
              if (widget.draft?.watchHint ?? false)
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _text,
                  // gone once something is typed or sent
                  builder: (_, value, _) => value.text.isEmpty && sent == null
                      ? _WatchHint(onPick: _fillExample)
                      : const SizedBox.shrink(),
                ),
              // the desktop's new chat: the composer has the focus (27W-2h)
              _composer(
                connected: connected,
                thinking: _newThinking,
                autofocus: DesktopLayout.of(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// An example fills the composer; a `<film>` placeholder is selected.
  void _fillExample(String text) {
    final at = text.indexOf('<');
    final end = at < 0 ? -1 : text.indexOf('>', at);
    _text.value = TextEditingValue(
      text: text,
      selection: at >= 0 && end > at
          ? TextSelection(baseOffset: at, extentOffset: end + 1)
          : TextSelection.collapsed(offset: text.length),
    );
  }

  // --- a chat (04, 06, 09) ----------------------------------------------------

  Widget _buildChat(BuildContext context, String id) {
    final l = AppLocalizations.of(context);
    final desktop = DesktopLayout.of(context);
    _takeKeys(context);
    final data = ref.watch(chatProvider(id)).value;
    final live = ref.watch(liveRunsProvider.select((m) => m[id]));
    final connected = ref.watch(
      connectionStatusProvider.select(
        (s) => s.value?.phase == ConnectionPhase.live,
      ),
    );
    final selfDevice = ref.watch(
      sessionProvider.select((s) => s.credentials?.deviceName),
    );

    final conversation = data?.conversation;
    final firstUser = data?.messages
        .where((m) => m.role == 'user')
        .firstOrNull
        ?.content;
    final title = conversation == null
        ? l.chatTitle
        : ChatRow.titleOf(
            ChatListItem(conversation: conversation, firstUserText: firstUser),
            l.newChat,
          );
    final stopTarget = data?.openRuns.firstOrNull;
    // a new chat that has just moved here: its first message until the chat
    // has loaded (one frame), so the screen does not blink empty
    final first = _firstClientMsgId;
    final carried = first == null
        ? null
        : ref.watch(_createdMessageProvider(first)).value;
    final items = data == null
        ? [if (carried != null) _writtenBubble(carried)]
        : _items(
            data,
            live,
            connected: connected,
            selfDevice: selfDevice,
            desktop: desktop,
          );
    // Ctrl+F (L2b2): the matches newest first, the current one framed
    final finding = desktop && _find.open;
    final matches = finding && data != null
        ? findMatches(_find.query, _texts(data))
        : const <int>[];
    final current = matches.isEmpty
        ? null
        : matches[_find.position(matches.length)];
    if (finding) {
      _scroller.follow(_find, current == null ? null : items[current].key);
    }

    return Scaffold(
      appBar: _ChatAppBar(
        title: title,
        desktop: desktop,
        actions: [
          if (conversation != null)
            Padding(
              // the chip ends on the page's 16 dp gutter (the desktop: the
              // inspector toggle follows)
              padding: EdgeInsets.only(
                right: desktop ? DelveTokens.space1 : DelveTokens.space4,
              ),
              child: ContextChip(
                numbers: UsageNumbers.of(conversation, live?.context),
                // the desktop: Usage is the inspector's second tab
                onTap: desktop
                    ? () => showChatInspectorTab(
                        ref,
                        context,
                        DesktopArea.chats.name,
                        ChatInspectorTab.usage,
                      )
                    : () => unawaited(_openUsage(id, title)),
              ),
            ),
          if (desktop && conversation != null)
            IconButton(
              key: const Key('chat.find'),
              tooltip: l.desktopFindTooltip,
              onPressed: _openFind,
              icon: const SymbolIcon(
                DelveIcons.search,
                size: DelveDesktop.iconButtonIcon,
              ),
            ),
        ],
      ),
      body: DesktopDropZone(
        onPaths: _dropped,
        child: ReadingColumn(
          child: Column(
            children: [
              if (finding) ChatFindBar(find: _find, count: matches.length),
              Expanded(
                child: UnderBarFade(
                  fadeKey: const Key('chat.fade'),
                  child: ListView.separated(
                    key: const Key('chat.list'),
                    reverse: true,
                    padding: _listPadding,
                    // while searching every item is built, so a match far up
                    // can be scrolled to
                    cacheExtent: finding ? 100000 : null,
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: DelveTokens.space3),
                    // reversed: the newest item sits at the bottom, next to the
                    // composer, and stays there while text streams in
                    itemBuilder: (_, i) {
                      final at = items.length - 1 - i;
                      final item = items[at];
                      final key = item.key;
                      if (!desktop || key == null) return item;
                      return FindMark(
                        key: _scroller.keyOf(key),
                        current: finding && at == current,
                        child: item,
                      );
                    },
                  ),
                ),
              ),
              if (conversation != null && conversation.contextWarn)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DelveTokens.space3,
                    0,
                    DelveTokens.space3,
                    DelveTokens.space2,
                  ),
                  child: StatusBanner(
                    key: const Key('chat.contextWarn'),
                    kind: StatusKind.warn,
                    icon: DelveIcons.warning,
                    text: l.chatContextWarn(
                      (conversation.contextPct ?? 0).round(),
                    ),
                    actionLabel: l.newChat,
                    onAction: () => context.pushReplacement(Routes.newChat),
                  ),
                ),
              _composer(
                connected: connected,
                onStop: stopTarget == null
                    ? null
                    : () => unawaited(_stop(stopTarget.runId)),
                queued: data?.queuedCount ?? 0,
                thinking: _thinkingPending ?? conversation?.thinking ?? false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The chat oldest first: messages (a run per assistant message), then
  /// what is still in the outbox.
  List<Widget> _items(
    ChatData data,
    LiveRun? live, {
    required bool connected,
    String? selfDevice,
    bool desktop = false,
  }) {
    final out = <Widget>[];
    for (final m in data.messages) {
      final key = ValueKey('msg.${m.id}');
      switch (m.role) {
        case 'user':
          out.add(
            UserBubble(
              key: key,
              text: m.content,
              attachments: m.attachments,
              onOpenAttachment: _openAttachment,
            ),
          );
        case 'assistant':
          final runId = m.runId;
          final run = runId == null ? null : data.runs[runId];
          final asked = runId == null
              ? null
              : data.messages
                    .where((u) => u.role == 'user' && u.runId == runId)
                    .firstOrNull;
          out.add(
            RunBlock(
              key: key,
              message: m,
              run: run,
              steps: runId == null
                  ? const <ToolStepRow>[]
                  : data.steps[runId] ?? const <ToolStepRow>[],
              approvals: data.approvals,
              live: live != null && live.runId == runId ? live : null,
              onRetry: asked == null ? null : () => unawaited(_resend(asked)),
              onAnswer: connected ? _answer : null,
              selfDevice: selfDevice,
              // the desktop's “Show in inspector” (context menus, L2b2)
              onInspect: desktop && runId != null
                  ? (stepId) => showRunInInspector(
                      ref,
                      context,
                      area: DesktopArea.chats.name,
                      conversationId: m.conversationId,
                      runId: runId,
                      stepId: stepId,
                    )
                  : null,
            ),
          );
        default:
          final run = m.runId == null ? null : data.runs[m.runId];
          if (run?.origin == 'late_approval') {
            out.add(
              FollowUpLine(key: key, command: followUpCommand(m.content)),
            );
          } else {
            out.add(SystemLine(key: key, text: m.content));
          }
      }
    }
    for (final o in data.outbox) {
      out.add(
        OutboxBubble(
          key: ValueKey('outbox.${o.clientMsgId}'),
          row: o,
          onOpenAttachment: _openAttachment,
          onRetry: () =>
              unawaited(ref.read(chatActionsProvider)?.retry(o.clientMsgId)),
          onDiscard: () =>
              unawaited(ref.read(chatActionsProvider)?.discard(o.clientMsgId)),
        ),
      );
    }
    return out;
  }
}

/// The chat list's padding: on top, room for the fade under the bar, so the
/// oldest item is clear of it when scrolled to the top.
const _listPadding = EdgeInsets.fromLTRB(
  DelveTokens.space4,
  UnderBarFade.height,
  DelveTokens.space4,
  DelveTokens.space4,
);

/// Top bar: the page colour (it does not change when the chat scrolls under
/// it), back, title (titleMedium, one line) and the context chip on the
/// right (an existing chat).
class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ChatAppBar({
    required this.title,
    this.actions = const [],
    this.desktop = false,
  });

  final String title;
  final List<Widget> actions;

  /// The desktop's 48 dp pane header (L2b): Jost 16, the inspector toggle
  /// last.
  final bool desktop;

  @override
  Size get preferredSize =>
      Size.fromHeight(desktop ? DelveDesktop.paneHeader : DelveTokens.topBar);

  @override
  Widget build(BuildContext context) => AppBar(
    key: const Key('chat.topBar'),
    backgroundColor: context.colors.surface,
    notificationPredicate: (_) => false,
    toolbarHeight: desktop ? DelveDesktop.paneHeader : null,
    leading: pageBackButton(context),
    titleSpacing: desktop ? DelveTokens.space4 : null,
    title: Text(
      title,
      key: const Key('chat.title'),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: desktop
          ? DelveDesktopText.paneTitle.copyWith(color: context.colors.onSurface)
          : context.text.titleMedium,
    ),
    actions: [
      ...actions,
      if (desktop) ...[const InspectorToggle(), const SizedBox(width: 10)],
    ],
  );
}

/// 21g: how to describe a watch, and two examples that fill the composer.
class _WatchHint extends StatelessWidget {
  const _WatchHint({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final muted = context.delve.textMuted;
    return Padding(
      key: const Key('chat.watchHint'),
      padding: const EdgeInsets.fromLTRB(
        DelveTokens.space4,
        0,
        DelveTokens.space4,
        DelveTokens.space3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SymbolIcon(
                DelveIcons.info,
                size: DelveTokens.iconSm,
                color: muted,
              ),
              const SizedBox(width: DelveTokens.space2),
              Expanded(
                child: Text(
                  l.watchHint,
                  style: context.text.bodySmall!.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          for (final (i, example) in [
            l.watchExampleHardverapro,
            l.watchExampleCinema,
          ].indexed) ...[
            const SizedBox(height: DelveTokens.space2),
            Material(
              color: context.colors.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: context.colors.outlineVariant),
                borderRadius: BorderRadius.circular(DelveTokens.rmd),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: Key('chat.watchExample.$i'),
                onTap: () => onPick(example),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: DelveTokens.touchTarget,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(DelveTokens.space3),
                    child: Row(
                      children: [
                        SymbolIcon(
                          DelveIcons.watches,
                          size: 18,
                          color: context.colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: DelveTokens.space2),
                        Expanded(
                          child: Text(example, style: context.text.bodySmall),
                        ),
                        const SizedBox(width: DelveTokens.space2),
                        SymbolIcon(
                          DelveIcons.fillIn,
                          size: DelveTokens.iconSm,
                          color: muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 03: the empty new chat.
class _NewChatIntro extends StatelessWidget {
  const _NewChatIntro({required this.host});

  final String host;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DelveTokens.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const DelveMark(height: 36),
                const SizedBox(width: DelveTokens.space3),
                Text('Delve', style: context.text.displaySmall),
              ],
            ),
            const SizedBox(height: DelveTokens.space2),
            Text(
              host.isEmpty ? l.newChatIntroNoHost : l.newChatIntro(host),
              textAlign: TextAlign.center,
              style: context.text.bodyMedium!.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
