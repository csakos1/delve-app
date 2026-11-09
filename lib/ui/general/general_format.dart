import '../../general/general_database.dart';
import '../../general/model_catalog.dart';
import '../../general/openrouter_client.dart';
import '../../l10n/app_localizations.dart';
import '../format.dart';

/// Costs below this are not shown (a chat's list marker, an answer's footer).
const double kCostHiddenBelow = 0.0001;

/// Dollars: `$3.18` from one dollar up, `$0.0042` below it.
String usdText(double v) =>
    v >= 1 ? '\$${v.toStringAsFixed(2)}' : '\$${v.toStringAsFixed(4)}';

/// A per-token price as dollars per 1M tokens: `$1.40`, `$0.07`, `$0.009`.
String perMillionText(double perToken) {
  final m = perToken * 1e6;
  if (m == 0) return '\$0';
  if (m < 0.01) return '\$${m.toStringAsFixed(3)}';
  return '\$${m.toStringAsFixed(2)}';
}

/// A context length: `1M`, `1.5M`, `131K`.
String contextLengthText(int n) {
  String trim(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  if (n >= 1000000) return '${trim(n / 1000000)}M';
  if (n >= 1000) return '${(n / 1000).round()}K';
  return '$n';
}

/// A model row's price line: `$1.40 / $4.40 · 1M`.
String modelPriceLine(OrModelRow m) {
  final ctx = m.contextLength;
  final price =
      '${perMillionText(m.pricePrompt)} / ${perMillionText(m.priceCompletion)}';
  return ctx == null ? price : '$price · ${contextLengthText(ctx)}';
}

/// The short name of [modelId]: from the list when it is there, else the
/// id without its provider (`glm-5.3`).
String modelShortName(String modelId, OrModelRow? row) {
  if (row != null) return row.shortName;
  final i = modelId.indexOf('/');
  return i < 0 ? modelId : modelId.substring(i + 1);
}

/// An effort as the pill and the sheet name it.
String effortLabel(AppLocalizations l, String effort) => switch (effort) {
  'minimal' => l.effortMinimal,
  'low' => l.effortLow,
  'medium' => l.effortMedium,
  'high' => l.effortHigh,
  'xhigh' => l.effortXhigh,
  'max' => l.effortMax,
  _ => effort,
};

/// What a key spent in its period: the limit minus what remains, else the
/// monthly usage (Settings → General and the Usage sheet's key card).
double keySpent(KeyInfo i) {
  final limit = i.limit;
  final remaining = i.limitRemaining;
  return limit != null && remaining != null
      ? limit - remaining
      : i.usageMonthly ?? i.usage ?? 0;
}

/// The key's period as the spend line ends (`this month`); null when the
/// limit never resets.
String? keyPeriodText(AppLocalizations l, KeyInfo i) => switch (i.limitReset) {
  'monthly' => l.generalKeyPeriodMonthly,
  'weekly' => l.generalKeyPeriodWeekly,
  'daily' => l.generalKeyPeriodDaily,
  _ => null,
};

/// The spend line: `$3.18 of $10.00 this month`, `$3.68 spent · no limit`.
String keySpendText(AppLocalizations l, KeyInfo i) {
  final used = keySpent(i);
  final limit = i.limit;
  return limit == null
      ? l.generalKeySpendNoLimit(usdText(used))
      : [
          l.generalKeySpend(usdText(used), usdText(limit)),
          ?keyPeriodText(l, i),
        ].join(' ');
}

/// The context of the last answer: `1,180 / 1,048,576 · 0.1%` (one decimal
/// below 1 %, where a whole percent would read 0).
String? generalContextText(GeneralChatRow chat) {
  final used = chat.lastPromptTokens;
  if (used == null) return null;
  final max = chat.lastContextLength;
  final pct = generalContextPct(chat);
  final of = max == null ? '' : ' / ${tokenCount(max)}';
  final percent = pct == null
      ? ''
      : ' · ${pct < 1 ? pct.toStringAsFixed(1) : pct.round()}%';
  return '${tokenCount(used)}$of$percent';
}

/// The context fill of a chat's last answer, in percent (null before it).
double? generalContextPct(GeneralChatRow chat) {
  final used = chat.lastPromptTokens;
  final max = chat.lastContextLength;
  if (used == null || max == null || max <= 0) return null;
  return used * 100 / max;
}
