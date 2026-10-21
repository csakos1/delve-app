import 'package:flutter/foundation.dart';

/// A time of day on a schedule.
@immutable
class ClockTime implements Comparable<ClockTime> {
  const ClockTime(this.hour, this.minute);

  final int hour;
  final int minute;

  String get text =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  int compareTo(ClockTime other) =>
      hour != other.hour ? hour - other.hour : minute - other.minute;

  @override
  bool operator ==(Object other) =>
      other is ClockTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);
}

/// The editor's reading of a 5-field cron expression (design 14b): every day
/// at some times, some weekdays at one time, or anything else as plain cron.
/// Weekdays are ISO numbers, 1 = Monday … 7 = Sunday.
sealed class CronPreset {
  const CronPreset();

  static CronPreset parse(String cron) {
    final f = cron.trim().split(RegExp(r'\s+'));
    if (f.length != 5 || f[2] != '*' || f[3] != '*') return CustomCron(cron);
    final minute = _int(f[0], 0, 59);
    final hours = _list(f[1], 0, 23);
    if (minute == null || hours == null || hours.isEmpty) {
      return CustomCron(cron);
    }
    if (f[4] == '*') {
      return DailyCron([for (final h in hours) ClockTime(h, minute)]..sort());
    }
    final days = _list(f[4], 0, 7);
    if (days == null || days.isEmpty || hours.length != 1) {
      return CustomCron(cron);
    }
    return WeeklyCron({
      for (final d in days) d == 0 ? 7 : d,
    }, ClockTime(hours.single, minute));
  }

  /// The cron expression, or null when it cannot be one (daily times that do
  /// not share their minute, no time, no day).
  String? toCron();

  static int? _int(String s, int lo, int hi) {
    final v = int.tryParse(s);
    return v != null && v >= lo && v <= hi && '$v' == s ? v : null;
  }

  /// `a,b,c` and `a-b` parts; null for steps, names or anything else.
  static List<int>? _list(String s, int lo, int hi) {
    final out = <int>{};
    for (final part in s.split(',')) {
      final range = part.split('-');
      if (range.length == 2) {
        final a = _int(range[0], lo, hi);
        final b = _int(range[1], lo, hi);
        if (a == null || b == null || a > b) return null;
        out.addAll([for (var i = a; i <= b; i++) i]);
      } else {
        final v = _int(part, lo, hi);
        if (v == null) return null;
        out.add(v);
      }
    }
    return out.toList()..sort();
  }
}

final class DailyCron extends CronPreset {
  const DailyCron(this.times);

  /// Sorted.
  final List<ClockTime> times;

  /// Cron can run at several hours only on one shared minute.
  bool get sharesMinute =>
      times.isEmpty || times.every((t) => t.minute == times.first.minute);

  @override
  String? toCron() {
    if (times.isEmpty || !sharesMinute) return null;
    final hours = {for (final t in times) t.hour}.toList()..sort();
    return '${times.first.minute} ${hours.join(',')} * * *';
  }
}

final class WeeklyCron extends CronPreset {
  const WeeklyCron(this.days, this.time);

  /// ISO weekdays, 1 = Monday … 7 = Sunday.
  final Set<int> days;
  final ClockTime time;

  List<int> get sortedDays => days.toList()..sort();

  @override
  String? toCron() {
    if (days.isEmpty) return null;
    final cronDays = [for (final d in sortedDays) d == 7 ? 0 : d]..sort();
    return '${time.minute} ${time.hour} * * ${cronDays.join(',')}';
  }
}

final class CustomCron extends CronPreset {
  const CustomCron(this.cron);
  final String cron;

  @override
  String? toCron() {
    final norm = cron.trim().split(RegExp(r'\s+')).join(' ');
    return norm.split(' ').length == 5 ? norm : null;
  }
}
