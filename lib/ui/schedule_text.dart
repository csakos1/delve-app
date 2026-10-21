import 'package:intl/intl.dart';

import '../api/models/models.dart';
import '../app/cron_preset.dart';
import '../l10n/app_localizations.dart';
import 'format.dart';

/// `a`, `a and b`, `a, b and c`.
String joinAnd(AppLocalizations l, List<String> items) => switch (items) {
  [] => '',
  [final one] => one,
  _ => l.schedulesListAnd(
    items.sublist(0, items.length - 1).join(', '),
    items.last,
  ),
};

/// ISO weekday (1 = Monday) as a name: `Monday`, or [short] `Mon`.
String weekdayName(int day, {bool short = false}) => DateFormat(
  short ? 'EEE' : 'EEEE',
  'en_US',
).format(DateTime(2024, 1, day)); // 2024-01-01 was a Monday

/// "Every day at 08:52, 12:52 and 20:52", "Sundays at 18:00",
/// "Weekdays at 09:00"; [fallback] (the server's reading) for other cron.
String presetText(AppLocalizations l, CronPreset preset, String fallback) {
  switch (preset) {
    case DailyCron(:final times) when times.isNotEmpty:
      return l.schedulesEveryDay(joinAnd(l, [for (final t in times) t.text]));
    case WeeklyCron(:final days, :final time) when days.isNotEmpty:
      final sorted = days.toList()..sort();
      if (sorted.length == 7) return l.schedulesEveryDay(time.text);
      if (sorted.length == 5 && sorted.every((d) => d <= 5)) {
        return l.schedulesWeekdays(time.text);
      }
      if (sorted.length == 2 && sorted.first == 6) {
        return l.schedulesWeekends(time.text);
      }
      if (sorted.length == 1) {
        return l.schedulesEveryWeek(weekdayName(sorted.single), time.text);
      }
      return l.schedulesOnDays(
        joinAnd(l, [for (final d in sorted) weekdayName(d, short: true)]),
        time.text,
      );
    case DailyCron() || WeeklyCron() || CustomCron():
      return fallback;
  }
}

/// The schedule's timing in words.
String scheduleTimingText(AppLocalizations l, Schedule s) =>
    presetText(l, CronPreset.parse(s.cron), s.description);

/// A time ahead of [now]: `today 08:52`, `tomorrow 07:30`, `Mon 09:00`,
/// `3 Nov 09:00`. Local time.
String aheadText(AppLocalizations l, DateTime at, DateTime now) {
  final a = at.toLocal();
  final n = now.toLocal();
  final days = DateTime.utc(
    a.year,
    a.month,
    a.day,
  ).difference(DateTime.utc(n.year, n.month, n.day)).inDays;
  final time = DateFormat('HH:mm').format(a);
  if (days <= 0) return l.schedulesToday(time);
  if (days == 1) return l.schedulesTomorrow(time);
  if (days < 7) return DateFormat('EEE HH:mm').format(a);
  return DateFormat('d MMM HH:mm').format(a);
}

/// "Next run in 9 h · tomorrow 08:52", "Next run Mon 09:00", "Paused".
String nextRunText(AppLocalizations l, Schedule s, DateTime now) {
  final next = s.nextRunAt;
  if (!s.enabled || next == null) return l.schedulesPaused;
  final wait = next.difference(now);
  final when = aheadText(l, next, now);
  return wait < const Duration(hours: 24)
      ? l.schedulesNextRunIn(ageText(wait), when)
      : l.schedulesNextRun(when);
}

/// How the last firing went, as the list shows it.
enum LastOutcome { ok, failed, stopped, running, queued }

LastOutcome? lastOutcome(Schedule s) => switch (s.lastStatus) {
  'ok' || 'completed' => LastOutcome.ok,
  'failed' => LastOutcome.failed,
  'cancelled' => LastOutcome.stopped,
  'queued' => LastOutcome.queued,
  null => s.lastRunAt == null ? null : LastOutcome.queued,
  _ => LastOutcome.running,
};

String outcomeWord(AppLocalizations l, LastOutcome o) => switch (o) {
  LastOutcome.ok => l.schedulesStatusOk,
  LastOutcome.failed => l.schedulesStatusFailed,
  LastOutcome.stopped => l.schedulesStatusStopped,
  LastOutcome.running => l.schedulesStatusRunning,
  LastOutcome.queued => l.schedulesStatusQueued,
};

/// "Last run 20:52 · OK", "Last run Sun 18:00 · Failed", "Not run yet".
String lastRunText(AppLocalizations l, Schedule s, DateTime now) {
  final at = s.lastRunAt;
  final outcome = lastOutcome(s);
  if (at == null || outcome == null) return l.schedulesNotRunYet;
  return l.schedulesLastRun(clockTime(at, now), outcomeWord(l, outcome));
}

/// The server's 422 codes for a schedule, in words (null: not one of them).
String? scheduleErrorText(AppLocalizations l, String code) => switch (code) {
  'invalid_cron' => l.schedErrInvalidCron,
  'too_frequent' => l.schedErrTooFrequent,
  'invalid_name' => l.schedErrName,
  'invalid_prompt' => l.schedErrPrompt,
  'conversation_required' || 'conversation_not_found' => l.schedErrChat,
  _ => null,
};
