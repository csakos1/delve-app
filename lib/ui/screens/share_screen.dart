import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/chat.dart';
import '../../app/chat_list.dart';
import '../../app/router.dart';
import '../../attachments/attachment_store.dart';
import '../../attachments/composer_attachments.dart';
import '../../attachments/image_prep.dart';
import '../../attachments/picker.dart';
import '../../data/db/database.dart';
import '../../l10n/app_localizations.dart';
import '../../share/share_channel.dart';
import '../../sync/connection_status.dart';
import '../../sync/sync_providers.dart';
import '../../theme/delve_theme.dart';
import '../chat/attachments.dart';
import '../chat/composer.dart';
import '../format.dart';
import '../widgets/chat_row.dart';
import '../widgets/page_scaffolds.dart';

/// 17 Share to Delve: what another app shared goes into the composer (photos
/// and files as chips that upload at once, text into the field); the user
/// picks a new chat (the default) or an existing one, and Send opens it.
class ShareScreen extends ConsumerStatefulWidget {
  const ShareScreen({super.key});

  @override
  ConsumerState<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends ConsumerState<ShareScreen> {
  final _text = TextEditingController();
  late final ComposerAttachments _attachments;

  /// Null: a new chat.
  String? _target;

  /// Thinking for a new chat (off, as everywhere else).
  bool _newThinking = false;

  /// An existing chat's Thinking switch until the server confirms it.
  final Map<String, bool> _thinkingPending = {};

  @override
  void initState() {
    super.initState();
    _attachments = ComposerAttachments(
      api: () => mounted ? ref.read(attachmentApiProvider) : null,
      prep: ref.read(imagePrepProvider),
      cache: ref.read(attachmentCacheProvider),
    );
    // taking it changes a provider: not while the tree builds
    WidgetsBinding.instance.addPostFrameCallback((_) => _takePending());
  }

  @override
  void dispose() {
    _attachments.dispose();
    _text.dispose();
    super.dispose();
  }

  void _takePending() {
    if (!mounted) return;
    final p = ref.read(pendingShareProvider.notifier).take();
    if (p != null) _apply(p);
  }

  /// A share into the composer: text after what is already typed, photos
  /// and files as long as there is room.
  void _apply(SharedPayload p) {
    final l = AppLocalizations.of(context);
    if (p.text case final t?) {
      final now = _text.text.trimRight();
      _text.text = now.isEmpty ? t : '$now\n$t';
    }
    final left = _attachments.addAll(p.files) + p.skipped;
    if (left > 0) {
      _snack(l.attachLeftOut(left, kMaxAttachments));
    } else if (p.failed > 0) {
      _snack(l.shareUnreadable(p.failed));
    }
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.chats);
    }
  }

  Future<void> _send(String text) async {
    final actions = ref.read(chatActionsProvider);
    if (actions == null) return;
    final target = _target;
    final id = await actions.send(
      text,
      conversationId: target,
      thinking: target == null ? _newThinking : null,
      attachments: _attachments.ready,
    );
    _attachments.clear();
    if (!mounted) return;
    if (target == null) {
      // the new chat shows the outbox entry and moves to its conversation
      context.go(Routes.newChat, extra: id);
    } else {
      context.go(Routes.chat(target));
    }
  }

  bool _thinkingOf(ChatListItem? item) {
    if (item == null) return _newThinking;
    final id = item.conversation.id;
    return _thinkingPending[id] ?? item.conversation.thinking;
  }

  /// A new chat's switch is local; an existing chat's is saved on the
  /// server (the pill shows the wanted state until it answers).
  Future<void> _setThinking(ChatListItem? item, bool on) async {
    if (item == null) {
      setState(() => _newThinking = on);
      return;
    }
    final l = AppLocalizations.of(context);
    final actions = ref.read(chatActionsProvider);
    if (actions == null) return;
    final id = item.conversation.id;
    setState(() => _thinkingPending[id] = on);
    try {
      await actions.setThinking(id, thinking: on);
    } on Exception catch (e) {
      if (mounted) _snack(l.thinkingFailed(apiErrorText(l, e)));
    } finally {
      if (mounted) setState(() => _thinkingPending.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    // a second share while this screen is open
    ref.listen(pendingShareProvider, (_, next) {
      if (next != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _takePending());
      }
    });
    final chats = ref.watch(chatListProvider(false)).value ?? const [];
    final connected = ref.watch(
      connectionStatusProvider.select(
        (s) => s.value?.phase == ConnectionPhase.live,
      ),
    );
    final canAct = ref.watch(chatActionsProvider) != null;
    final selected = chats
        .where((c) => c.conversation.id == _target)
        .firstOrNull;
    // the chosen chat is gone (archived elsewhere): back to a new chat
    final target = selected == null ? null : _target;
    final now = DateTime.now();
    final muted = context.text.bodySmall!.copyWith(color: cs.onSurfaceVariant);

    Widget title(String text) => Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.text.titleSmall,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('share.close'),
          tooltip: l.close,
          icon: const SymbolIcon(DelveIcons.close),
          onPressed: _close,
        ),
        title: Text(l.shareTitle),
      ),
      body: Column(
        children: [
          Expanded(
            child: RadioGroup<String>(
              groupValue: target ?? '',
              onChanged: (v) {
                if (v == null) return;
                setState(() => _target = v.isEmpty ? null : v);
              },
              child: ListView(
                key: const Key('share.list'),
                padding: const EdgeInsets.only(bottom: DelveTokens.space4),
                children: [
                  _SectionLabel(l.shareSendTo),
                  RadioListTile<String>(
                    key: const Key('share.new'),
                    value: '',
                    title: title(l.newChat),
                    subtitle: Text(
                      _newThinking
                          ? l.shareNewChatThinkingOn
                          : l.shareNewChatThinkingOff,
                      style: muted,
                    ),
                    secondary: SymbolIcon(
                      DelveIcons.edit,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  if (chats.isNotEmpty) ...[
                    const Divider(indent: 72),
                    _SectionLabel(l.shareExisting),
                    for (final c in chats)
                      RadioListTile<String>(
                        key: ValueKey('share.chat.${c.conversation.id}'),
                        value: c.conversation.id,
                        title: title(ChatRow.titleOf(c, l.newChat)),
                        subtitle: Text(
                          listTime(c.conversation.updatedAt, now),
                          style: muted,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          Composer(
            controller: _text,
            onSend: _send,
            attachments: _attachments,
            attachmentsAllowed: connected,
            onAdd: connected && ref.watch(attachmentApiProvider) != null
                ? () => unawaited(
                    pickAttachmentsInto(
                      context,
                      ref.read(attachmentPickerProvider),
                      _attachments,
                    ),
                  )
                : null,
            leading: [
              ThinkingPill(
                on: _thinkingOf(selected),
                onChanged: canAct
                    ? (v) => unawaited(_setThinking(selected, v))
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "SEND TO", "EXISTING CHATS": muted, spaced capitals.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      DelveTokens.space4,
      DelveTokens.space4,
      DelveTokens.space4,
      DelveTokens.space2,
    ),
    child: Semantics(
      header: true,
      child: Text(
        label.toUpperCase(),
        style: context.text.labelMedium!.copyWith(
          color: context.delve.textMuted,
          letterSpacing: 1.2,
        ),
      ),
    ),
  );
}
