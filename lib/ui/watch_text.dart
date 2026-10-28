import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../api/models/models.dart';
import '../app/cron_preset.dart';
import '../l10n/app_localizations.dart';
import 'format.dart';
import 'schedule_text.dart';
import 'widgets/page_scaffolds.dart';
import 'widgets/status_ui.dart';

/// "Hardverapró", "Cinema City", "Web page".
String sourceLabel(AppLocalizations l, String source) => switch (source) {
  'hardverapro' => 'Hardverapró',
  'cinemacity' => 'Cinema City',
  'page' => l.watchSourcePage,
  _ => source,
};

IconData sourceIcon(String source) => switch (source) {
  'hardverapro' => DelveIcons.storefront,
  'cinemacity' => DelveIcons.theaters,
  _ => DelveIcons.webPage,
};

/// "Every day at 08:15, 13:15 and 19:15" (cron, as the Schedules list writes
/// it), "Every 8 hours" (`every 480m`), else the raw text.
String watchScheduleText(AppLocalizations l, String schedule) {
  final every = RegExp(r'^every\s+(\d+)\s*m$').firstMatch(schedule.trim());
  if (every != null) {
    final minutes = int.parse(every[1]!);
    return minutes % 60 == 0
        ? l.watchEveryHours(minutes ~/ 60)
        : l.watchEveryMinutes(minutes);
  }
  return presetText(l, CronPreset.parse(schedule), schedule);
}

/// The state word of a watch row (design 21a): Error over the rest.
StatusText watchStatus(AppLocalizations l, Watch w) {
  final (kind, label) = w.failing
      ? (StatusKind.alert, l.watchStateError)
      : w.stoppedAfterHit
      ? (StatusKind.info, l.watchStateStopped)
      : w.paused
      ? (StatusKind.info, l.watchStatePaused)
      : w.state == 'active'
      ? (StatusKind.ok, l.watchStateActive)
      : (StatusKind.info, l.watchStateUnknown);
  return StatusText(
    key: Key('watch.state.${w.slug}'),
    kind: kind,
    label: label,
  );
}

/// "4070 super · any of gigabyte, asus · not bánya, mining"; null without
/// keywords.
String? keywordsText(AppLocalizations l, Watch w) {
  final parts = [
    if (w.include.isNotEmpty) w.include.join(', '),
    if (w.any.isNotEmpty) l.watchKeywordsAny(w.any.join(', ')),
    if (w.exclude.isNotEmpty) l.watchKeywordsNot(w.exclude.join(', ')),
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

/// `180 000 Ft` (Hungarian grouping, as the listings write prices).
String forints(int n) =>
    '${NumberFormat('#,##0', 'en_US').format(n).replaceAll(',', ' ')} Ft';

/// "≤ 180 000 Ft", "≥ 50 000 Ft", "50 000 – 180 000 Ft"; null = any price.
String? priceText(Watch w) => switch ((w.minPrice, w.maxPrice)) {
  (null, null) => null,
  (null, final max?) => '≤ ${forints(max)}',
  (final min?, null) => '≥ ${forints(min)}',
  (final min?, final max?) =>
    '${forints(min).replaceAll(' Ft', '')} – ${forints(max)}',
};

/// A time not long ago: `today 13:15`, `yesterday 19:15`, `Mon 08:15`,
/// `3 Nov 08:15`. Local time.
String pastText(AppLocalizations l, DateTime at, DateTime now) {
  final a = at.toLocal();
  final n = now.toLocal();
  final days = DateTime.utc(
    n.year,
    n.month,
    n.day,
  ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
  final time = DateFormat('HH:mm').format(a);
  if (days <= 0) return l.schedulesToday(time);
  if (days == 1) return l.watchYesterday(time);
  if (days < 7) return DateFormat('EEE HH:mm').format(a);
  return DateFormat('d MMM HH:mm').format(a);
}

/// "today 19:15 · in 5 h 50 min", "— paused".
String nextCheckText(AppLocalizations l, Watch w, DateTime now) {
  final next = w.nextRunAt;
  if (w.paused) return l.watchNextPaused;
  if (next == null) return '—';
  final wait = next.difference(now);
  final when = aheadText(l, next, now);
  return wait.isNegative || wait > const Duration(hours: 24)
      ? when
      : l.watchNextIn(when, uptimeText(wait));
}

/// "today 13:15 · 27 listings · 1 match", or the error.
String? lastCheckText(AppLocalizations l, Watch w, DateTime now) {
  final at = w.lastCheckAt;
  if (at == null) return null;
  final when = pastText(l, at, now);
  if (w.failing) return '$when · ${w.lastError ?? w.lastErrorCode ?? ''}';
  return [
    when,
    if (w.lastItems case final n?) l.watchListings(n),
    if (w.lastMatched case final n?) l.watchMatches(n),
  ].join(' · ');
}

/// "165 000 Ft · Budapest XI." (either may be missing; null = neither).
String? itemMeta(WatchItem i) {
  final parts = [
    i.price,
    i.location,
  ].whereType<String>().where((s) => s.isNotEmpty);
  return parts.isEmpty ? null : parts.join(' · ');
}
