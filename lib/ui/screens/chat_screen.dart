import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/chat.dart';
import '../../app/chat_list.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/session.dart';
import '../../data/db/database.dart';
import '../../l10n/app_localizations.dart';
import '../../sync/live_runs.dart';
import '../../sync/sync_engine.dart';
import '../../sync/sync_providers.dart';
import '../../theme/delve_theme.dart';
import '../chat/chat_items.dart';
import '../chat/composer.dart';
import '../format.dart';
import '../widgets/chat_row.dart';
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
  const ChatScreen({super.key, required this.conversationId});

  final String? conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  /// New chat: the outbox entry of the first message.
  String? _firstClientMsgId;

  /// The new chat exists; the screen is moving to it.
  bool _moving = false;
  ChatActions? _opened;

  @override
  void initState() {
    super.initState();
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
    _opened?.close();
    super.dispose();
  }

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

  Future<void> _send(String text) async {
    final actions = ref.read(chatActionsProvider);
    if (actions == null) return;
    final id = await actions.send(text, conversationId: widget.conversationId);
    if (widget.conversationId == null && mounted) {
      setState(() => _firstClientMsgId = id);
    }
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

  Future<void> _setArchived(String id, {required bool archived}) async {
    final l = AppLocalizations.of(context);
    try {
      await ref
          .read(chatListPagerProvider(false).notifier)
          .setArchived(id, archived: archived);
      if (mounted) _snack(archived ? l.chatsArchived : l.archivedRestored);
    } on Exception catch (e) {
      if (mounted) _snack(l.chatsArchiveFailed(apiErrorText(l, e)));
    }
  }

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
    if (first != null && !_moving) {
      // watched, not listened: the rebuild this triggers runs the post-frame
      // callback; a callback on its own schedules no frame
      final created = ref.watch(_createdMessageProvider(first)).value;
      if (created != null) {
        _moving = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.replace(Routes.chat(created.conversationId));
        });
      }
    }
    final outbox = first == null
        ? null
        : ref.watch(_outboxRowProvider(first)).value;
    final host =
        ref.watch(sessionProvider.select((s) => s.credentials?.server.host)) ??
        '';

    return Scaffold(
      appBar: _ChatAppBar(title: l.newChat),
      body: Column(
        children: [
          Expanded(
            child: outbox == null
                ? _NewChatIntro(host: host.split('.').first)
                : ListView(
                    reverse: true,
                    padding: const EdgeInsets.all(DelveTokens.space4),
                    children: [
                      OutboxBubble(
                        row: outbox,
                        onRetry: () => unawaited(
                          ref
                              .read(chatActionsProvider)
                              ?.retry(outbox.clientMsgId),
                        ),
                        onDiscard: () {
                          unawaited(
                            ref
                                .read(chatActionsProvider)
                                ?.discard(outbox.clientMsgId),
                          );
                          setState(() => _firstClientMsgId = null);
                        },
                      ),
                    ],
                  ),
          ),
          Composer(onSend: _send),
        ],
      ),
    );
  }

  // --- a chat (04, 06, 09) ----------------------------------------------------

  Widget _buildChat(BuildContext context, String id) {
    final l = AppLocalizations.of(context);
    final data = ref.watch(chatProvider(id)).value;
    final live = ref.watch(liveRunsProvider.select((m) => m[id]));

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
    final items = data == null ? const <Widget>[] : _items(data, live);

    return Scaffold(
      appBar: _ChatAppBar(
        title: title,
        actions: [
          if (conversation != null)
            PopupMenuButton<bool>(
              key: const Key('chat.menu'),
              tooltip: l.chatMenu,
              icon: const SymbolIcon(DelveIcons.moreVert),
              onSelected: (archive) =>
                  unawaited(_setArchived(id, archived: archive)),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: !conversation.archived,
                  child: Text(
                    conversation.archived ? l.archivedRestore : l.chatsArchive,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              key: const Key('chat.list'),
              reverse: true,
              padding: const EdgeInsets.all(DelveTokens.space4),
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: DelveTokens.space3),
              // reversed: the newest item sits at the bottom, next to the
              // composer, and stays there while text streams in
              itemBuilder: (_, i) => items[items.length - 1 - i],
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
          Composer(
            onSend: _send,
            onStop: stopTarget == null
                ? null
                : () => unawaited(_stop(stopTarget.runId)),
            queued: data?.queuedCount ?? 0,
          ),
        ],
      ),
    );
  }

  /// The chat oldest first: messages (a run per assistant message), then
  /// what is still in the outbox.
  List<Widget> _items(ChatData data, LiveRun? live) {
    final out = <Widget>[];
    for (final m in data.messages) {
      final key = ValueKey('msg.${m.id}');
      switch (m.role) {
        case 'user':
          out.add(UserBubble(key: key, text: m.content));
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
              onRetry: asked == null
                  ? null
                  : () => unawaited(_send(asked.content)),
            ),
          );
        default:
          out.add(SystemLine(key: key, text: m.content));
      }
    }
    for (final o in data.outbox) {
      out.add(
        OutboxBubble(
          row: o,
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

/// Top bar: surface-2, back, title (titleMedium, one line), actions. The
/// usage line under it arrives with A6.
class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ChatAppBar({required this.title, this.actions = const []});

  final String title;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(DelveTokens.topBar);

  @override
  Widget build(BuildContext context) => AppBar(
    backgroundColor: context.colors.surfaceContainer,
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
            Text('Delve', style: context.text.displaySmall),
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
