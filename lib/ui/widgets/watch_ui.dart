import 'dart:async';

import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/models/models.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../desktop/desktop_row.dart';
import '../format.dart';
import '../links.dart';
import '../watch_text.dart';
import 'page_scaffolds.dart';
import 'status_ui.dart';

/// "2 new" (design 21c): accent-container pill, not tappable.
class NewPill extends StatelessWidget {
  const NewPill({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 20),
    padding: const EdgeInsets.symmetric(horizontal: DelveTokens.space2),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: context.colors.primaryContainer,
      borderRadius: BorderRadius.circular(DelveTokens.rxl),
    ),
    child: Text(
      label,
      style: context.text.labelSmall!.copyWith(
        color: context.colors.onPrimaryContainer,
      ),
    ),
  );
}

/// A watch in the list (design 21a): source icon, name, "source · schedule",
/// the error line when the last check failed; the state on the right, "N new"
/// under it.
class WatchRow extends StatelessWidget {
  const WatchRow({super.key, required this.watch, required this.onTap});

  final Watch watch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final w = watch;
    final secondary = context.text.bodySmall!.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    final alert = context.delve.alertFg;
    return InkWell(
      key: Key('watch.row.${w.slug}'),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.symmetric(
          horizontal: DelveTokens.space4,
          vertical: DelveTokens.space3,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: context.colors.outlineVariant),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SymbolIcon(
              sourceIcon(w.source),
              color: context.colors.onSurfaceVariant,
            ),
            const SizedBox(width: DelveTokens.space4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    w.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall,
                  ),
                  const SizedBox(height: DelveTokens.space1),
                  Text(
                    '${sourceLabel(l, w.source)} · '
                    '${watchScheduleText(l, w.schedule)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: secondary,
                  ),
                  if (w.failing) ...[
                    const SizedBox(height: DelveTokens.space1),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: SymbolIcon(
                            DelveIcons.error,
                            size: 14,
                            filled: true,
                            color: alert,
                          ),
                        ),
                        const SizedBox(width: DelveTokens.space1),
                        Expanded(
                          child: Text(
                            [
                              w.lastError ?? w.lastErrorCode ?? '',
                              if (w.errorsInRow > 1)
                                l.watchErrorsInRow(w.errorsInRow),
                            ].join(' · '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: secondary.copyWith(color: alert),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: DelveTokens.space4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                watchStatus(l, w),
                if (w.hits24h > 0) ...[
                  const SizedBox(height: DelveTokens.space1),
                  NewPill(
                    key: Key('watch.new.${w.slug}'),
                    label: l.watchNew(w.hits24h),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The marker under an item (design 21c), or null.
Widget? itemMarker(AppLocalizations l, WatchItem i) => switch (i) {
  WatchItem(verdict: 'error') => StatusText(
    kind: StatusKind.alert,
    icon: DelveIcons.error,
    label: l.watchItemCouldntJudge,
  ),
  WatchItem(verdict: 'pending') => StatusText(
    kind: StatusKind.info,
    icon: DelveIcons.hourglass,
    label: l.watchItemWaiting,
  ),
  WatchItem(reserved: true) => StatusText(
    kind: StatusKind.warn,
    icon: DelveIcons.onHold,
    label: l.watchItemOnHold,
  ),
  WatchItem(availableAt: _?) => StatusText(
    kind: StatusKind.ok,
    icon: DelveIcons.ok,
    label: l.watchItemAvailable,
  ),
  _ => null,
};

/// A listing (design 21c): title (2 lines), "price · place", the judge's
/// reason (or "Matched by filters" for a hit without a judge), a marker;
/// the time and Open link on the right. Tap opens the link, long-press
/// copies it.
class HitRow extends ConsumerWidget {
  const HitRow({super.key, required this.item, required this.now});

  final WatchItem item;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final i = item;
    final rejected = i.verdict == 'reject';
    final muted = context.delve.textMuted;
    final secondary = context.colors.onSurfaceVariant;
    final meta = itemMeta(i);
    final marker = itemMarker(l, i);
    final reason = i.reason;
    final Widget? line3 = switch (i.verdict) {
      'mechanical' => _IconLine(
        icon: DelveIcons.filter,
        text: l.watchItemByFilters,
        color: muted,
      ),
      'reject' when reason != null => _IconLine(
        icon: DelveIcons.block,
        text: reason,
        color: secondary,
      ),
      _ when reason != null && i.verdict != 'error' => _IconLine(
        icon: DelveIcons.thinking,
        text: reason,
        color: secondary,
      ),
      _ => null,
    };
    void open() => openLink(context, ref, i.url);
    return Semantics(
      button: true,
      label: [
        i.title,
        ?meta,
        if (marker is StatusText) marker.label,
        l.watchOpenLink,
      ].join('. '),
      onLongPressHint: l.watchCopyLink,
      excludeSemantics: true,
      child: InkWell(
        key: Key('watch.item.${i.id}'),
        onTap: open,
        onLongPress: () => copyLink(context, i.url),
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.fromLTRB(
            DelveTokens.space4,
            DelveTokens.space3,
            DelveTokens.space1,
            DelveTokens.space3,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: context.colors.outlineVariant),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      i.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall!.copyWith(
                        color: rejected ? muted : null,
                      ),
                    ),
                    if (meta != null) ...[
                      const SizedBox(height: DelveTokens.space1),
                      Text(
                        meta,
                        style: context.text.labelMedium!.copyWith(
                          color: secondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                    if (line3 != null) ...[
                      const SizedBox(height: DelveTokens.space1),
                      line3,
                    ],
                    if (marker != null) ...[
                      const SizedBox(height: DelveTokens.space1),
                      marker,
                    ],
                  ],
                ),
              ),
              SizedBox(
                width: DelveTokens.touchTarget,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: DelveTokens.space3),
                      child: Text(
                        listTime(i.seenAt, now),
                        key: Key('watch.item.time.${i.id}'),
                        softWrap: false,
                        style: context.text.labelMedium!.copyWith(color: muted),
                      ),
                    ),
                    IconButton(
                      key: Key('watch.item.open.${i.id}'),
                      tooltip: l.watchOpenLink,
                      onPressed: open,
                      icon: SymbolIcon(
                        DelveIcons.openLink,
                        size: DelveTokens.iconMd,
                        color: secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({
    required this.icon,
    required this.text,
    required this.color,
    this.maxLines = 3,
  });

  final IconData icon;
  final String text;
  final Color color;
  final int maxLines;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 1),
        child: SymbolIcon(
          icon,
          size: DelveTokens.iconSm,
          color: context.delve.textMuted,
        ),
      ),
      const SizedBox(width: DelveTokens.space1),
      Expanded(
        child: Text(
          text,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: context.text.bodySmall!.copyWith(color: color),
        ),
      ),
    ],
  );
}

/// A watch in the desktop's list column (27W-9a): a 52 px two-line row –
/// source icon, name and “N new”; under it the next check, the paused state
/// or the error (in `alert`). The open watch's row is selected.
class DesktopWatchRow extends StatelessWidget {
  const DesktopWatchRow({
    super.key,
    required this.watch,
    required this.selected,
    required this.now,
    required this.onTap,
  });

  final Watch watch;
  final bool selected;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final w = watch;
    final cs = context.colors;
    final d = context.delve;
    final secondary = DelveDesktopText.rowSecondary;
    final Widget line2;
    if (w.failing) {
      line2 = Row(
        children: [
          SymbolIcon(
            DelveIcons.error,
            size: 13,
            filled: true,
            color: d.alertFg,
          ),
          const SizedBox(width: DelveTokens.space1),
          Expanded(
            child: Text(
              [
                w.lastError ?? w.lastErrorCode ?? l.watchStateError,
                if (w.errorsInRow > 1) l.watchErrorsInRow(w.errorsInRow),
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: secondary.copyWith(color: d.alertFg),
            ),
          ),
        ],
      );
    } else {
      final status = watchStatus(l, w);
      final active = w.state == 'active' && !w.paused;
      line2 = Text(
        active
            ? '${sourceLabel(l, w.source)} · '
                  '${l.desktopWatchNext(nextCheckText(l, w, now))}'
            : '${sourceLabel(l, w.source)} · ${status.label}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: secondary.copyWith(
          color: active ? cs.onSurfaceVariant : d.textMuted,
        ),
      );
    }
    return DesktopRowFrame(
      key: Key('watch.row.${w.slug}'),
      selected: selected,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: SymbolIcon(
              sourceIcon(w.source),
              size: 16,
              filled: selected,
              color: selected ? cs.onSurface : cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        w.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DelveDesktopText.rowTitle.copyWith(
                          color: w.paused ? cs.onSurfaceVariant : cs.onSurface,
                        ),
                      ),
                    ),
                    if (w.hits24h > 0) ...[
                      const SizedBox(width: DelveTokens.space2),
                      NewPill(
                        key: Key('watch.new.${w.slug}'),
                        label: l.watchNew(w.hits24h),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                line2,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A listing in a watch's tab on the desktop (27W-9a): the phone's lines in
/// desktop density, on the content's `background`. A click selects it (the
/// Hit inspector shows it), a double click or the arrow opens the link,
/// right-click has Open link · Copy link.
class DesktopHitRow extends ConsumerStatefulWidget {
  const DesktopHitRow({
    super.key,
    required this.item,
    required this.now,
    required this.selected,
    required this.onSelect,
  });

  final WatchItem item;
  final DateTime now;
  final bool selected;
  final VoidCallback onSelect;

  @override
  ConsumerState<DesktopHitRow> createState() => _DesktopHitRowState();
}

class _DesktopHitRowState extends ConsumerState<DesktopHitRow> {
  /// The last click (a second one within [kDoubleTapTimeout] opens).
  DateTime? _lastTap;

  void _open() => unawaited(openLink(context, ref, widget.item.url));

  void _tap() {
    final now = DateTime.now();
    final last = _lastTap;
    _lastTap = now;
    if (last != null && now.difference(last) < kDoubleTapTimeout) {
      _lastTap = null;
      _open();
      return;
    }
    if (!widget.selected) widget.onSelect();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final i = widget.item;
    final cs = context.colors;
    final muted = context.delve.textMuted;
    final rejected = i.verdict == 'reject';
    final meta = itemMeta(i);
    final marker = itemMarker(l, i);
    final reason = i.reason;
    final Widget? line3 = switch (i.verdict) {
      'mechanical' => _IconLine(
        icon: DelveIcons.filter,
        text: l.watchItemByFilters,
        color: muted,
        maxLines: 1,
      ),
      'reject' when reason != null => _IconLine(
        icon: DelveIcons.block,
        text: reason,
        color: cs.onSurfaceVariant,
        maxLines: 2,
      ),
      _ when reason != null && i.verdict != 'error' => _IconLine(
        icon: DelveIcons.thinking,
        text: reason,
        color: cs.onSurfaceVariant,
        maxLines: 2,
      ),
      _ => null,
    };
    return DesktopRowFrame(
      key: Key('watch.item.${i.id}'),
      selected: widget.selected,
      onContent: true,
      onTap: _tap,
      menu: [
        DesktopMenuItem(
          key: const Key('watch.item.menu.open'),
          icon: DelveIcons.openLink,
          label: l.watchOpenLink,
          onSelected: _open,
        ),
        DesktopMenuItem(
          key: const Key('watch.item.menu.copy'),
          icon: DelveIcons.copy,
          label: l.watchCopyLink,
          onSelected: () => unawaited(copyLink(context, i.url)),
        ),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  i.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: DelveDesktopText.rowTitle.copyWith(
                    color: rejected ? muted : cs.onSurface,
                  ),
                ),
                if (meta != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    meta,
                    style: DelveDesktopText.rowSecondary.copyWith(
                      color: cs.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
                if (line3 != null) ...[const SizedBox(height: 3), line3],
                if (marker != null) ...[const SizedBox(height: 4), marker],
              ],
            ),
          ),
          const SizedBox(width: DelveTokens.space3),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                listTime(i.seenAt, widget.now),
                key: Key('watch.item.time.${i.id}'),
                softWrap: false,
                style: DelveDesktopText.meta.copyWith(color: muted),
              ),
              const SizedBox(height: 2),
              SizedBox.square(
                dimension: 22,
                child: IconButton(
                  key: Key('watch.item.open.${i.id}'),
                  tooltip: l.watchOpenLink,
                  padding: EdgeInsets.zero,
                  iconSize: 16,
                  onPressed: _open,
                  icon: SymbolIcon(
                    DelveIcons.openLink,
                    size: 16,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
