import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/models/models.dart';
import '../../api/protocol.dart';
import '../../app/chat.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/session.dart';
import '../../attachments/attachment_store.dart';
import '../../attachments/composer_attachments.dart';
import '../../attachments/image_prep.dart';
import '../../attachments/picker.dart';
import '../../data/db/database.dart';
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
import '../format.dart';
import '../widgets/chat_row.dart';
import '../widgets/delve_mark.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/status_ui.dart';

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

/// 03–10 Chat (detail, no bottom nav). [conversationId] is null for a new
/// chat: its first message creates the conversation, and the screen moves to
/// it once the server has made a message of the outbox entry.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
    this.firstClientMsgId,
  });

  final String? conversationId;

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

  /// An existing chat's Thinking switch while the server has not confirmed
  /// it yet.
  bool? _thinkingPending;

  /// "Applies to your next message" under the composer, for 2 s.
  Timer? _captionTimer;
  bool _caption = false;

  /// The photos and files of the next message (kept when a new chat moves to
  /// its conversation: same state).
  late final ComposerAttachments _attachments;

  @override
  void initState() {
    super.initState();
    _attachments = ComposerAttachments(
      api: () => mounted ? ref.read(attachmentApiProvider) : null,
      prep: ref.read(imagePrepProvider),
      cache: ref.read(attachmentCacheProvider),
    );
    _firstClientMsgId = widget.firstClientMsgId;
    final id = widget.conversationId;
    if (id != null) _openAfterFrame(id);
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
    _captionTimer?.cancel();
    _opened?.close();
    _attachments.dispose();
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
  Future<void> _addAttachments() => pickAttachmentsInto(
    context,
    ref.read(attachmentPickerProvider),
    _attachments,
  );

  /// A photo full screen, a file's details; both offer "Send again".
  void _openAttachment(Attachment a) {
    void again() => _sendAgain(a);
    final canAgain = a.available;
    if (a.isImage && a.available) {
      unawaited(
        AttachmentViewer.open(context, a, onSendAgain: canAgain ? again : null),
      );
    } else {
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

  Widget _composer({
    required bool connected,
    VoidCallback? onStop,
    int queued = 0,
    required bool thinking,
  }) {
    final l = AppLocalizations.of(context);
    final canAttach = connected && ref.watch(attachmentApiProvider) != null;
    return Composer(
      onSend: _sendComposer,
      onStop: onStop,
      queued: queued,
      leading: [_pill(on: thinking)],
      caption: _caption ? l.composerThinkingCaption : null,
      attachments: _attachments,
      onAdd: canAttach ? () => unawaited(_addAttachments()) : null,
      attachmentsAllowed: connected,
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

  /// Usage sheet. Closing it gives the focus back to the composer, which
  /// would open the keyboard: when the keyboard was closed before (the field
  /// may still hold the focus after Back hid it), the focus goes first.
  Future<void> _openUsage(String id, String title) async {
    if (MediaQuery.viewInsetsOf(context).bottom == 0) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
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

  @override
  Widget build(BuildContext context) {
    final id = widget.conversationId;
    if (id == null) return _buildNew(context);
    return _buildChat(context, id);
  }

  // --- new chat (03) ----------------------------------------------------------

  Widget _buildNew(BuildContext context) {
    final l = AppLocalizations.of(context);
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
      appBar: _ChatAppBar(title: l.newChat),
      body: Column(
        children: [
          Expanded(
            child: _UnderBarFade(
              child: sent == null
                  ? _NewChatIntro(host: host.split('.').first)
                  : ListView(
                      reverse: true,
                      padding: _listPadding,
                      children: [sent],
                    ),
            ),
          ),
          _composer(connected: connected, thinking: _newThinking),
        ],
      ),
    );
  }

  // --- a chat (04, 06, 09) ----------------------------------------------------

  Widget _buildChat(BuildContext context, String id) {
    final l = AppLocalizations.of(context);
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
        : _items(data, live, connected: connected, selfDevice: selfDevice);

    return Scaffold(
      appBar: _ChatAppBar(
        title: title,
        actions: [
          if (conversation != null)
            Padding(
              // the chip ends on the page's 16 dp gutter
              padding: const EdgeInsets.only(right: DelveTokens.space4),
              child: ContextChip(
                numbers: UsageNumbers.of(conversation, live?.context),
                onTap: () => unawaited(_openUsage(id, title)),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _UnderBarFade(
              child: ListView.separated(
                key: const Key('chat.list'),
                reverse: true,
                padding: _listPadding,
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: DelveTokens.space3),
                // reversed: the newest item sits at the bottom, next to the
                // composer, and stays there while text streams in
                itemBuilder: (_, i) => items[items.length - 1 - i],
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
                text: l.chatContextWarn((conversation.contextPct ?? 0).round()),
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
    );
  }

  /// The chat oldest first: messages (a run per assistant message), then
  /// what is still in the outbox.
  List<Widget> _items(
    ChatData data,
    LiveRun? live, {
    required bool connected,
    String? selfDevice,
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
  _UnderBarFade.height,
  DelveTokens.space4,
  DelveTokens.space4,
);

/// The chat under its top bar: the bar has the page colour, and right under
/// it the page colour fades out over [height], so text scrolling up dims out
/// under the bar instead of being cut at a line. Taps go through the fade.
class _UnderBarFade extends StatelessWidget {
  const _UnderBarFade({required this.child});

  static const double height = DelveTokens.space6;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final page = context.colors.surface;
    return Stack(
      children: [
        Positioned.fill(child: child),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: height,
          child: IgnorePointer(
            child: DecoratedBox(
              key: const Key('chat.fade'),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [page, page.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Top bar: the page colour (it does not change when the chat scrolls under
/// it), back, title (titleMedium, one line) and the context chip on the
/// right (an existing chat).
class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ChatAppBar({required this.title, this.actions = const []});

  final String title;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(DelveTokens.topBar);

  @override
  Widget build(BuildContext context) => AppBar(
    key: const Key('chat.topBar'),
    backgroundColor: context.colors.surface,
    notificationPredicate: (_) => false,
    leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
    title: Text(
      title,
      key: const Key('chat.title'),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.text.titleMedium,
    ),
    actions: actions,
  );
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
