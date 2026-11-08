import 'package:drift/drift.dart';

import 'general_database.dart';
import 'openrouter_client.dart';

/// The starting favourites (decision G-13) and the default model.
const List<String> kDefaultFavourites = [
  'z-ai/glm-5.3',
  'z-ai/glm-5.3-flash',
  'moonshotai/kimi-k3.1-pro',
  'anthropic/claude-opus-5.5',
  'openai/gpt-6-astra',
];
const String kDefaultModel = 'z-ai/glm-5.3';

/// How long the model list is kept before it is fetched again.
const Duration kModelsMaxAge = Duration(hours: 24);

/// Providers per model that have a strict zero-retention endpoint: Safety
/// Retention endpoints do not count (they may keep flagged prompts).
Map<String, Set<String>> strictZdrProviders(
  List<Map<String, Object?>> endpoints,
) {
  final out = <String, Set<String>>{};
  for (final e in endpoints) {
    final model = e['model_id'];
    final provider = e['provider_name'];
    if (model is! String || provider is! String) continue;
    if (e['safety_retention'] == true) continue;
    out.putIfAbsent(model, () => <String>{}).add(provider);
  }
  return out;
}

double? _price(Object? v) => switch (v) {
  num() => v.toDouble(),
  String() => double.tryParse(v),
  _ => null,
};

List<String> _strings(Object? v) => [
  if (v is List<Object?>)
    for (final e in v)
      if (e is String) e,
];

/// A `/models` entry as a row, or null when General does not offer it:
/// not text out, an alias (`~…`, `alias_target`), a `:variant` (batch, free,
/// online), a router (`openrouter/…`, negative price).
OrModelsCompanion? modelRow(
  Map<String, Object?> m,
  Map<String, Set<String>> zdr,
) {
  final id = m['id'];
  if (id is! String || id.isEmpty) return null;
  if (id.startsWith('~') || id.contains(':') || id.startsWith('openrouter/')) {
    return null;
  }
  if (m['alias_target'] != null) return null;
  final arch = m['architecture'];
  final archMap = arch is Map<String, Object?>
      ? arch
      : const <String, Object?>{};
  final outputs = _strings(archMap['output_modalities']);
  if (!outputs.contains('text')) return null;
  final pricing = m['pricing'];
  final p = pricing is Map<String, Object?>
      ? pricing
      : const <String, Object?>{};
  final prompt = _price(p['prompt']);
  final completion = _price(p['completion']);
  if (prompt == null || completion == null || prompt < 0 || completion < 0) {
    return null;
  }
  final reasoning = m['reasoning'];
  final r = reasoning is Map<String, Object?> ? reasoning : null;
  final supported =
      r != null || _strings(m['supported_parameters']).contains('reasoning');
  final providers = (zdr[id] ?? const <String>{}).toList()..sort();
  return OrModelsCompanion.insert(
    id: id,
    name: m['name'] is String ? m['name']! as String : id,
    contextLength: Value(
      m['context_length'] is num ? (m['context_length']! as num).toInt() : null,
    ),
    inputModalities: _strings(archMap['input_modalities']),
    pricePrompt: prompt,
    priceCompletion: completion,
    priceCacheRead: Value(_price(p['input_cache_read'])),
    reasoningSupported: Value(supported),
    reasoningMandatory: Value(r?['mandatory'] == true),
    reasoningEfforts: Value(_strings(r?['supported_efforts'])),
    reasoningDefaultEffort: Value(
      r?['default_effort'] is String ? r!['default_effort']! as String : null,
    ),
    zdrProviders: Value(providers),
  );
}

extension OrModelRowX on OrModelRow {
  bool get readsImages => inputModalities.contains('image');

  /// At least one strict zero-retention provider.
  bool get selectable => zdrProviders.isNotEmpty;

  ReasoningSpec get reasoningSpec => ReasoningSpec(
    supported: reasoningSupported,
    mandatory: reasoningMandatory,
    efforts: reasoningEfforts,
    defaultEffort: reasoningDefaultEffort,
  );

  /// “GLM 5.3” from “Z.ai: GLM 5.3” (the list marker, the chip).
  String get shortName {
    final i = name.indexOf(': ');
    return i < 0 ? name : name.substring(i + 2);
  }
}

/// The model list, cached in [GeneralDatabase] for [kModelsMaxAge].
class ModelCatalog {
  ModelCatalog(this.db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final GeneralDatabase db;
  final DateTime Function() _now;

  Future<DateTime?> fetchedAt() async {
    final raw = await db.meta(GeneralMetaKeys.modelsFetchedAt);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  /// Fetches the list when it is missing or older than [kModelsMaxAge]
  /// (or always with [force]). Returns whether it fetched.
  Future<bool> refresh(OpenRouterClient client, {bool force = false}) async {
    final at = await fetchedAt();
    if (!force && at != null && _now().difference(at) < kModelsMaxAge) {
      final any = await db.models();
      if (any.isNotEmpty) return false;
    }
    final models = await client.models();
    final zdr = strictZdrProviders(await client.zdrEndpoints());
    final rows = [for (final m in models) ?modelRow(m, zdr)];
    await db.replaceModels(rows);
    await db.setMeta(
      GeneralMetaKeys.modelsFetchedAt,
      _now().toUtc().toIso8601String(),
    );
    return true;
  }

  Future<List<String>> favourites() async =>
      await db.metaList(GeneralMetaKeys.favourites) ?? kDefaultFavourites;

  Future<void> setFavourites(List<String> ids) =>
      db.setMetaList(GeneralMetaKeys.favourites, ids);

  Future<String> defaultModel() async =>
      await db.meta(GeneralMetaKeys.defaultModel) ?? kDefaultModel;

  Future<void> setDefaultModel(String id) {
    checkModelId(id);
    return db.setMeta(GeneralMetaKeys.defaultModel, id);
  }
}
