import '../../general/general_database.dart';
import '../../general/model_catalog.dart';
import '../../l10n/app_localizations.dart';

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

/// The context fill of a chat's last answer, in percent (null before it).
double? generalContextPct(GeneralChatRow chat) {
  final used = chat.lastPromptTokens;
  final max = chat.lastContextLength;
  if (used == null || max == null || max <= 0) return null;
  return used * 100 / max;
}
