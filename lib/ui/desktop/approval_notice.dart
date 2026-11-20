import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/protocol.dart';
import '../../app/approvals.dart';
import '../../app/router.dart';
import '../../app/session.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../chat/tool_step_card.dart' show displayCommand;
import '../format.dart';
import '../widgets/page_scaffolds.dart';
import 'approvals_card.dart';

/// The window is in front (the desktop's own notification tells of what
/// arrives while it is not – L3).
bool _windowFocused() {
  final state = WidgetsBinding.instance.lifecycleState;
  return state == null || state == AppLifecycleState.resumed;
}

/// The in-app approval notice (design 27W-14i, L2d4): an approval that
/// arrives while the window is in front and another page is open shows at
/// the bottom right of the content – the chat as a link, the command in
/// full, the countdown, Allow once / Deny. It stays until it is answered
/// (here or anywhere: the outcome shows for 1.5 s), closed or opened. One at
/// a time: a second approval only counts in the status bar. Nothing shows
/// for what waited already when the app started, or where the approval is
/// on the page anyway (its chat, Approvals, the Dashboard's card).
class ApprovalNotice extends ConsumerStatefulWidget {
  const ApprovalNotice({super.key, required this.location});

  /// The router's location.
  final String location;

  @override
  ConsumerState<ApprovalNotice> createState() => _ApprovalNoticeState();
}

class _ApprovalNoticeState extends ConsumerState<ApprovalNotice> {
  /// The pending approvals seen so far (null: the inbox has not loaded).
  Set<String>? _known;

  /// The approval shown.
  InboxApproval? _item;

  /// It was answered (or its time ran out): its outcome, until the timer.
  bool _leaving = false;
  String? _failed;
  bool _busy = false;
  Timer? _tick;
  Timer? _hold;

  @override
  void dispose() {
    _tick?.cancel();
    _hold?.cancel();
    super.dispose();
  }

  /// The page shows the approval itself.
  bool _onPage(InboxApproval item) {
    final path = Uri.parse(widget.location).path;
    return path == Routes.dashboard ||
        path.startsWith(Routes.approvals) ||
        path == Routes.chat(item.approval.conversationId);
  }

  static InboxApproval? _in(List<InboxApproval> list, String id) {
    for (final i in list) {
      if (i.approval.requestId == id) return i;
    }
    return null;
  }

  void _close() {
    _hold?.cancel();
    setState(() {
      _item = null;
      _leaving = false;
      _failed = null;
    });
  }

  Future<void> _answer(ApprovalChoice choice) async {
    final item = _item;
    final service = ref.read(approvalInboxServiceProvider);
    if (item == null || service == null || _busy || _leaving) return;
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _failed = null;
    });
    try {
      await service.answer(item.approval.requestId, choice);
    } on Object catch (e) {
      if (mounted) setState(() => _failed = apiErrorText(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// What the inbox means for the notice (called in build, as the
  /// Dashboard's card does).
  void _follow(ApprovalInbox inbox) {
    final known = _known;
    if (known == null) {
      _known = {for (final i in inbox.pending) i.approval.requestId};
      return;
    }
    for (final i in inbox.pending) {
      // every arrival is known from now on, shown or not
      if (!known.add(i.approval.requestId)) continue;
      if (_item == null && _windowFocused() && !_onPage(i)) {
        _item = i;
        _leaving = false;
        _failed = null;
      }
    }
    final shown = _item;
    if (shown == null || _leaving) return;
    final id = shown.approval.requestId;
    final waiting = _in(inbox.pending, id);
    if (waiting != null) {
      // opened: the page shows it now
      _item = _onPage(waiting) ? null : waiting;
      return;
    }
    final answered = _in(inbox.recent, id);
    if (answered == null) {
      // the agent stopped waiting: Approvals has it from here
      _item = null;
      return;
    }
    _item = answered;
    _leaving = true;
    _hold?.cancel();
    _hold = Timer(DelveDesktop.outcomeHold, () {
      if (!mounted) return;
      setState(() {
        _item = null;
        _leaving = false;
      });
    });
  }

  /// A second's tick only while the countdown shows.
  void _ticking(bool on) {
    if (on && _tick == null) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!on && _tick != null) {
      _tick!.cancel();
      _tick = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final inbox = ref.watch(approvalInboxProvider).value;
    final self = ref.watch(
      sessionProvider.select((s) => s.credentials?.deviceName),
    );
    if (inbox != null) _follow(inbox);
    final item = _item;
    _ticking(item != null && !_leaving);
    if (item == null) return const SizedBox.shrink();

    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final d = context.delve;
    final a = item.approval;
    final failed = _failed;
    return Material(
      key: const Key('approval.notice'),
      color: cs.surfaceContainerHigh,
      elevation: 2,
      shadowColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DelveDesktop.popoverRadius),
        side: BorderSide(color: d.warnBorder),
      ),
      clipBehavior: Clip.antiAlias,
      // it never takes the keyboard: the answer keys need a focused approval
      child: ExcludeFocus(
        child: SizedBox(
          width: DelveDesktop.noticeWidth,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 8, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SymbolIcon(
                      DelveIcons.approvals,
                      size: 18,
                      filled: true,
                      color: d.warnFg,
                    ),
                    const SizedBox(width: DelveTokens.space2),
                    Expanded(
                      child: Text(
                        l.desktopApprovalsTitle,
                        style: context.text.titleSmall!.copyWith(
                          color: d.warnFg,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('approval.notice.close'),
                      tooltip: l.close,
                      onPressed: _close,
                      icon: const SymbolIcon(
                        DelveIcons.close,
                        size: DelveDesktop.iconButtonIcon,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ApprovalChatLink(
                        key: const Key('approval.notice.chat'),
                        title: item.chatTitle ?? l.chatTitle,
                        onTap: () {
                          final chat = Routes.chat(a.conversationId);
                          _close();
                          context.go(chat);
                        },
                      ),
                      const SizedBox(height: DelveTokens.space2),
                      // in full; a very long one scrolls in its well
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(
                          maxHeight: DelveDesktop.noticeCommandMax,
                        ),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(
                            DelveDesktop.approvalsWellRadius,
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Text(
                            displayCommand(a.command),
                            key: const Key('approval.notice.command'),
                            style: DelveText.mono.copyWith(color: cs.onSurface),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_leaving)
                        ApprovalOutcomeLine(approval: a, self: self)
                      else ...[
                        ApprovalStateLine(approval: a, now: DateTime.now()),
                        if (failed != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            l.desktopApprovalsFailed(failed),
                            key: const Key('approval.notice.failed'),
                            style: context.text.bodySmall!.copyWith(
                              color: d.alertFg,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            FilledButton(
                              key: const Key('approval.notice.once'),
                              onPressed: _busy
                                  ? null
                                  : () =>
                                        unawaited(_answer(ApprovalChoice.once)),
                              child: Text(l.approvalAllowOnce),
                            ),
                            const SizedBox(width: DelveTokens.space2),
                            FilledButton(
                              key: const Key('approval.notice.deny'),
                              style: FilledButton.styleFrom(
                                backgroundColor: cs.surfaceContainerHighest,
                                foregroundColor: cs.onSurface,
                              ),
                              onPressed: _busy
                                  ? null
                                  : () =>
                                        unawaited(_answer(ApprovalChoice.deny)),
                              child: Text(l.approvalDeny),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
