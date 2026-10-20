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
