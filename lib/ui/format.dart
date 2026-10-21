import 'package:intl/intl.dart';

import '../api/api_error.dart';
import '../l10n/app_localizations.dart';

/// List timestamp: time today, weekday within the last six days, date
/// otherwise (with the year when it is not this year). Both in local time.
String listTime(DateTime at, DateTime now) {
  final a = at.toLocal();
  final n = now.toLocal();
  final days = DateTime.utc(
    n.year,
    n.month,
    n.day,
  ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
  if (days <= 0) return DateFormat('HH:mm').format(a);
  if (days < 7) return DateFormat('EEE').format(a);
  if (a.year == n.year) return DateFormat('d MMM').format(a);
  return DateFormat('d MMM y').format(a);
}

/// A time of day near [now]: `HH:mm` today, `EEE HH:mm` on another day
/// (approval deadlines, answers). Local time.
String clockTime(DateTime at, DateTime now) {
  final a = at.toLocal();
  final n = now.toLocal();
  final sameDay = a.year == n.year && a.month == n.month && a.day == n.day;
  return DateFormat(sameDay ? 'HH:mm' : 'EEE HH:mm').format(a);
}

/// A countdown as `m:ss` (`4:07`, `0:45`); negative counts as zero.
String countdownText(Duration left) {
  final s = left.isNegative ? 0 : left.inSeconds;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// A token count with thousands separators: `48,210`.
String tokenCount(num n) => NumberFormat('#,##0', 'en_US').format(n);

/// The context fill as the usage line writes it: `41,980 / 65,536 · 64%`,
/// or null when nothing was measured yet.
String? contextText(int? tokens, int? max, double? pct) {
  if (tokens == null) return null;
  final of = max == null ? '' : ' / ${tokenCount(max)}';
  final percent = pct == null ? '' : ' · ${pct.round()}%';
  return '${tokenCount(tokens)}$of$percent';
}

/// One line of message text for a list preview: no code fences or bold
/// markers, whitespace collapsed.
String previewText(String text) => text
    .replaceAll(RegExp(r'```[\w-]*'), ' ')
    .replaceAll('**', '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// A REST failure as a short reason for a snackbar.
String apiErrorText(AppLocalizations l, Object error) => switch (error) {
  ApiUnreachable() => l.pairUnreachable,
  ApiRateLimited(:final retryAfter) => l.errorRateLimited(retryAfter.inSeconds),
  ApiRequestError(:final status, :final message?) when message.isNotEmpty =>
    '$message (HTTP $status)',
  ApiRequestError(:final status, :final code) => l.errorHttp(
    code == null ? '$status' : '$status $code',
  ),
  ApiUnauthorized() => l.connAuthFailed,
  ApiBadResponse(:final detail) => detail,
  ApiCancelled() => l.errorCancelled,
  _ => '$error',
};

/// A change in whole centimetres: `−2`, `+1`, `0` (a real minus sign).
String signedCm(double v) {
  final r = v.round();
  if (r < 0) return '\u2212${-r}';
  if (r > 0) return '+$r';
  return '0';
}

/// An uptime: `3 d 20 h`, `5 h 12 min`, `12 min`, `< 1 min`.
String uptimeText(Duration d) {
  if (d.inMinutes < 1) return '< 1 min';
  if (d.inHours < 1) return '${d.inMinutes} min';
  if (d.inDays < 1) {
    final m = d.inMinutes % 60;
    return m == 0 ? '${d.inHours} h' : '${d.inHours} h $m min';
  }
  final h = d.inHours % 24;
  return h == 0 ? '${d.inDays} d' : '${d.inDays} d $h h';
}

/// How old a reading is: `5 s`, `3 min`, `2 h`.
String ageText(Duration d) {
  final s = d.isNegative ? 0 : d.inSeconds;
  if (s < 60) return '$s s';
  if (s < 3600) return '${s ~/ 60} min';
  return '${s ~/ 3600} h';
}

/// MiB as GB: one decimal (`11.1`), or whole for a [total] that is one (`12`).
String gbText(int mib, {bool total = false}) {
  final gb = mib / 1024;
  if (total && (gb - gb.round()).abs() < 0.05) return '${gb.round()}';
  return gb.toStringAsFixed(1);
}

/// `NVIDIA GeForce RTX 4070 SUPER` -> `RTX 4070 SUPER`.
String gpuName(String name) => name
    .replaceFirst(RegExp(r'^NVIDIA\s+'), '')
    .replaceFirst(RegExp(r'^GeForce\s+'), '');

/// A wait in seconds, as the Observability header shows it: `42 s`,
/// `4 min`, `1.5 h`.
String secondsText(double s) {
  if (s < 90) return '${s.round()} s';
  if (s < 5400) return '${(s / 60).round()} min';
  return '${(s / 3600).toStringAsFixed(1)} h';
}
