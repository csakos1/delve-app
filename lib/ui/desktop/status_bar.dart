import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../api/models/models.dart';
import '../../app/approvals.dart';
import '../../app/router.dart';
import '../../app/system.dart';
import '../../l10n/app_localizations.dart';
import '../../sync/connection_status.dart';
import '../../sync/live_runs.dart';
import '../../sync/sync_providers.dart';
import '../../theme/delve_theme.dart';
import '../widgets/model_ui.dart';
import '../widgets/page_scaffolds.dart';
import 'approvals_card.dart' show answerableNow;
import 'layers.dart' show LayerMark;

/// How often the status bar asks for the machine's state (the socket's
/// `system.updated` only comes on changes; VRAM and temperature drift).
const Duration kStatusBarPoll = Duration(seconds: 15);

/// "4:05": minutes and seconds of [d] (never negative).
String clockText(Duration d) {
  final s = d.isNegative ? 0 : d.inSeconds;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// "31.2 / 44.0 GB": the VRAM of all GPUs together (null without data).
@visibleForTesting
String? vramText(List<GpuInfo>? gpus) {
  var used = 0;
  var total = 0;
  for (final g in gpus ?? const <GpuInfo>[]) {
    if (g.memUsedMib == null || g.memTotalMib == null) continue;
    used += g.memUsedMib!;
    total += g.memTotalMib!;
  }
  if (total == 0) return null;
  String gb(int mib) => (mib / 1024).toStringAsFixed(1);
  return '${gb(used)} / ${gb(total)} GB';
}

/// The hottest GPU, "52 °C" (null without data).
@visibleForTesting
String? hottestText(List<GpuInfo>? gpus) {
  double? max;
  for (final g in gpus ?? const <GpuInfo>[]) {
    final t = g.tempC;
    if (t != null && (max == null || t > max)) max = t;
  }
  return max == null ? null : '${max.round()} °C';
}

/// The desktop's 24 px status bar (design 27): left what needs the reader
/// (connection, approvals with the nearest deadline), right the machine
/// (run, model, slot, VRAM, hottest GPU). Segments are absent rather than
/// zero; offline hides the machine instead of showing stale values. Every
/// segment is a button.
/// The status bar's model segment: what Ctrl+M and the palette's “Switch
/// the local model” hang the picker on (L2d3).
final GlobalKey statusModelAnchor = GlobalKey(debugLabel: 'status.model');

/// The local model can be picked from the keys now: the status bar shows
/// llama-server's model (or that it is stopped), no switch or other action
/// runs, the desktop's helper answers – the Model row's own rule – and no
/// menu or popover is up.
bool canPickModel(WidgetRef ref) {
  if (statusModelAnchor.currentContext == null || LayerMark.open > 0) {
    return false;
  }
  final view = ref.read(systemProvider);
  final info = view.info;
  return info != null &&
      !info.llama.switching &&
      view.busy == null &&
      info.helper.ok;
}

/// Opens the local model picker over the status bar's model (27W-6b), as a
/// click on it does. False: it cannot be picked now ([canPickModel]).
bool openModelPicker(WidgetRef ref) {
  if (!canPickModel(ref)) return false;
  unawaited(changeModel(statusModelAnchor.currentContext!, ref));
  return true;
}

class DesktopStatusBar extends ConsumerStatefulWidget {
  const DesktopStatusBar({super.key});

  @override
  ConsumerState<DesktopStatusBar> createState() => _DesktopStatusBarState();
}

class _DesktopStatusBarState extends ConsumerState<DesktopStatusBar> {
  Timer? _poll;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    _poll = Timer.periodic(kStatusBarPoll, (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    unawaited(
      ref.read(systemProvider.notifier).refresh().catchError((Object _) {}),
    );
  }

  /// A second's tick only while something counts.
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

  /// The approvals segment: the newest approval that can still be answered
  /// (27W-3), the list when there is none.
  void _openNewest(ApprovalInbox? inbox, DateTime now) {
    final newest = answerableNow(inbox, now).firstOrNull;
    context.go(
      newest == null
          ? Routes.approvals
          : Routes.approval(newest.approval.requestId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final dc = context.delve;
    final status =
        ref.watch(connectionStatusProvider).value ?? ConnectionStatus.initial;
    final inbox = ref.watch(approvalInboxProvider).value;
    final runs = ref.watch(liveRunsProvider);
    final info = ref.watch(systemProvider).info;
    final width = MediaQuery.sizeOf(context).width;
    final now = DateTime.now();

    final pending = inbox?.pending ?? const <InboxApproval>[];
    final late = inbox?.expired ?? const <InboxApproval>[];
    LiveRun? first;
    for (final r in runs.values) {
      if (first == null || r.startedAt.isBefore(first.startedAt)) first = r;
    }
    final run = first;
    final llama = info?.llama;
    final switching = llama?.switching ?? false;
    _ticking(pending.isNotEmpty || run != null || switching);

    final left = <Widget>[
      _connection(l, status),
      if (pending.isNotEmpty)
        _Segment(
          key: const Key('status.approvals'),
          icon: DelveIcons.approvals,
          filledIcon: true,
          color: dc.warnFg,
          text: l.desktopStatusApprovals(
            pending.length + late.length,
            clockText(pending.first.approval.hermesDeadline.difference(now)),
          ),
          onTap: () => _openNewest(inbox, now),
        )
      else if (late.isNotEmpty)
        _Segment(
          key: const Key('status.approvals'),
          icon: DelveIcons.timerOff,
          color: dc.infoFg,
          text: l.desktopStatusLate(
            late.length,
            DateFormat('HH:mm').format(late.first.approval.expiresAt.toLocal()),
          ),
          onTap: () => _openNewest(inbox, now),
        ),
    ];

    final right = <Widget>[
      if (status.isLive) ...[
        if (run != null && width >= DelveDesktop.statusBarDropRunBelow)
          _Segment(
            key: const Key('status.run'),
            icon: DelveIcons.progress,
            color: cs.primary,
            text: l.desktopStatusRun(clockText(now.difference(run.startedAt))),
            onTap: () => context.go(Routes.chat(run.conversationId)),
          ),
        if (llama != null) ...[
          if (switching)
            _Segment(
              key: const Key('status.model'),
              icon: DelveIcons.sync,
              text: l.desktopStatusSwitching(
                clockText(
                  llama.switchState?.at == null
                      ? Duration(seconds: llama.switchState?.elapsedS ?? 0)
                      : now.difference(llama.switchState!.at!),
                ),
              ),
              onTap: () => context.go(Routes.system),
            )
          else if (llama.status == 'stopped')
            KeyedSubtree(
              key: statusModelAnchor,
              child: _Segment(
                key: const Key('status.model'),
                text: l.desktopStatusLlamaStopped,
                onTap: () => context.go(Routes.system),
              ),
            )
          else if (llama.modelLine case final model?) ...[
            // the model picker as a popover over the segment (27W-6b)
            KeyedSubtree(
              key: statusModelAnchor,
              child: Builder(
                builder: (anchor) => _Segment(
                  key: const Key('status.model'),
                  text: model,
                  onTap: () => unawaited(changeModel(anchor, ref)),
                ),
              ),
            ),
            if (llama.slots != null)
              _Segment(
                key: const Key('status.slot'),
                text: (llama.slotsBusy ?? 0) > 0
                    ? l.desktopStatusSlotBusy
                    : l.desktopStatusSlotIdle,
                onTap: () => context.go(Routes.system),
              ),
          ],
        ],
        if (vramText(info?.gpus) case final vram?)
          _Segment(
            key: const Key('status.vram'),
            text: vram,
            onTap: () => context.go(Routes.system),
          ),
        if (width >= DelveDesktop.listOverlayBelow)
          if (hottestText(info?.gpus) case final temp?)
            _Segment(
              key: const Key('status.temp'),
              text: temp,
              onTap: () => context.go(Routes.system),
            ),
      ],
    ];

    return Container(
      key: const Key('desktop.statusBar'),
      height: DelveDesktop.statusBarHeight,
      color: cs.surfaceContainer,
      padding: const EdgeInsets.symmetric(
        horizontal: DelveDesktop.statusBarPadding - 6,
      ),
      child: Row(children: [...left, const Spacer(), ...right]),
    );
  }

  Widget _connection(AppLocalizations l, ConnectionStatus s) {
    final dc = context.delve;
    final hm = DateFormat('HH:mm');
    return switch (s.phase) {
      ConnectionPhase.live => _Segment(
        key: const Key('status.connection'),
        dot: dc.okFg,
        text: s.resyncing ? l.connReloading : l.desktopStatusConnected,
        onTap: () => context.go(Routes.settings),
      ),
      ConnectionPhase.connecting ||
      ConnectionPhase.awaitingHello ||
      ConnectionPhase.backoff => _Segment(
        key: const Key('status.connection'),
        icon: DelveIcons.sync,
        color: dc.warnFg,
        text: l.desktopStatusReconnecting,
        onTap: () => context.go(Routes.connectionLog),
      ),
      ConnectionPhase.offline || ConnectionPhase.authFailed => _Segment(
        key: const Key('status.connection'),
        icon: DelveIcons.offline,
        color: dc.alertFg,
        text: s.since == null
            ? l.chipOffline
            : l.desktopStatusOfflineSince(hm.format(s.since!.toLocal())),
        onTap: () => context.go(Routes.connectionLog),
      ),
    };
  }
}

/// One segment: an optional dot or icon and mono text; the bar's full height
/// is its hover target (`surface-3`).
class _Segment extends StatefulWidget {
  const _Segment({
    super.key,
    required this.text,
    required this.onTap,
    this.icon,
    this.filledIcon = false,
    this.dot,
    this.color,
  });

  final String text;
  final VoidCallback onTap;
  final IconData? icon;
  final bool filledIcon;
  final Color? dot;
  final Color? color;

  @override
  State<_Segment> createState() => _SegmentState();
}

class _SegmentState extends State<_Segment> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final color = widget.color ?? cs.onSurfaceVariant;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          height: DelveDesktop.statusBarHeight,
          color: _hover ? cs.surfaceContainerHigh : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          margin: const EdgeInsets.only(right: DelveDesktop.statusBarGap - 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.dot case final dot?)
                Container(
                  width: DelveDesktop.statusBarDot,
                  height: DelveDesktop.statusBarDot,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
              if (widget.icon case final icon?)
                Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: SymbolIcon(
                    icon,
                    size: DelveDesktop.statusBarIcon,
                    filled: widget.filledIcon,
                    color: color,
                  ),
                ),
              Text(
                widget.text,
                maxLines: 1,
                style: DelveText.monoSmall.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
