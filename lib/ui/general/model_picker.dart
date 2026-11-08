import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../general/general_database.dart';
import '../../general/general_providers.dart';
import '../../general/model_catalog.dart';
import '../../general/openrouter_errors.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../format.dart';
import '../widgets/page_scaffolds.dart';
import 'general_format.dart';

/// The model picker (24d): favourites in their order, then every model A–Z
/// by name; search in the name and the id; a star per row. Returns the
/// picked model's id (null: closed). Models without a strict zero-retention
/// provider are listed but cannot be picked.
Future<String?> showModelPicker(
  BuildContext context, {
  required String? current,
  required String subtitle,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: context.colors.surfaceContainerHigh,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(DelveTokens.rxl)),
  ),
  builder: (_) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.92,
    minChildSize: 0.5,
    maxChildSize: 0.92,
    builder: (context, scroll) =>
        ModelPickerSheet(current: current, subtitle: subtitle, scroll: scroll),
  ),
);

class ModelPickerSheet extends ConsumerStatefulWidget {
  const ModelPickerSheet({
    super.key,
    required this.current,
    required this.subtitle,
    this.scroll,
  });

  final String? current;
  final String subtitle;
  final ScrollController? scroll;

  @override
  ConsumerState<ModelPickerSheet> createState() => _ModelPickerSheetState();
}

class _ModelPickerSheetState extends ConsumerState<ModelPickerSheet> {
  final _search = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // the cached list is used as it is; a missing or old one is fetched
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_refresh(force: false));
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh({required bool force}) async {
    final client = ref.read(openRouterClientProvider);
    if (client == null) return;
    final l = AppLocalizations.of(context);
    setState(() => _loading = true);
    try {
      await ref.read(modelCatalogProvider).refresh(client, force: force);
    } on GeneralFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(l.generalModelsFailed(e.message))),
          );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFavourite(String id) async {
    final favourites = [...ref.read(generalFavouritesProvider)];
    if (!favourites.remove(id)) favourites.add(id);
    await ref.read(modelCatalogProvider).setFavourites(favourites);
  }

  bool _matches(OrModelRow m, String q) =>
      m.shortName.toLowerCase().contains(q) || m.id.toLowerCase().contains(q);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final muted = context.delve.textMuted;
    final models = ref.watch(generalModelsProvider).value ?? const [];
    final favourites = ref.watch(generalFavouritesProvider);
    final fetched = ref
        .watch(generalMetaProvider(GeneralMetaKeys.modelsFetchedAt))
        .value;
    final fetchedAt = fetched == null ? null : DateTime.tryParse(fetched);
    final query = _search.text.trim().toLowerCase();

    final byId = {for (final m in models) m.id: m};
    final favRows = [
      for (final id in favourites) ?byId[id],
    ].where((m) => query.isEmpty || _matches(m, query)).toList();
    final all =
        [
          for (final m in models)
            if (query.isEmpty || _matches(m, query)) m,
        ]..sort(
          (a, b) =>
              a.shortName.toLowerCase().compareTo(b.shortName.toLowerCase()),
        );

    Widget section(String label) => Padding(
      padding: const EdgeInsets.fromLTRB(
        DelveTokens.space5,
        DelveTokens.space4,
        DelveTokens.space5,
        DelveTokens.space1,
      ),
      child: Text(
        label.toUpperCase(),
        style: context.text.labelSmall!.copyWith(color: muted),
      ),
    );

    Widget row(OrModelRow m, String where) => ModelRow(
      key: Key('picker.$where.${m.id}'),
      model: m,
      query: query,
      selected: m.id == widget.current,
      favourite: favourites.contains(m.id),
      onTap: m.selectable ? () => Navigator.of(context).pop(m.id) : null,
      onStar: () => unawaited(_toggleFavourite(m.id)),
    );

    final children = <Widget>[
      if (models.isEmpty)
        Padding(
          padding: const EdgeInsets.all(DelveTokens.space6),
          child: Column(
            children: [
              Text(
                l.pickerEmpty,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium!.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: DelveTokens.space3),
              if (_loading)
                const CircularProgressIndicator()
              else
                OutlinedButton(
                  key: const Key('picker.load'),
                  onPressed: () => unawaited(_refresh(force: true)),
                  child: Text(l.pickerLoad),
                ),
            ],
          ),
        )
      else if (favRows.isEmpty && all.isEmpty)
        Padding(
          padding: const EdgeInsets.all(DelveTokens.space6),
          child: Text(
            l.pickerNoMatch(_search.text.trim()),
            textAlign: TextAlign.center,
            style: context.text.bodyMedium!.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        )
      else ...[
        if (favRows.isNotEmpty) ...[
          section(l.pickerFavourites),
          for (final m in favRows) row(m, 'fav'),
        ],
        if (all.isNotEmpty) ...[
          section(l.pickerAll),
          for (final m in all) row(m, 'all'),
        ],
      ],
      Padding(
        padding: const EdgeInsets.fromLTRB(
          DelveTokens.space5,
          DelveTokens.space3,
          DelveTokens.space5,
          DelveTokens.space6,
        ),
        child: Text(
          fetchedAt == null
              ? l.pickerNever
              : l.pickerUpdated(agoText(DateTime.now().difference(fetchedAt))),
          key: const Key('picker.updated'),
          style: context.text.labelSmall!.copyWith(color: muted),
        ),
      ),
    ];

    return Column(
      key: const Key('picker'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DelveTokens.space5,
            0,
            DelveTokens.space1,
            DelveTokens.space2,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.pickerTitle, style: context.text.titleLarge),
                    Text(
                      widget.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelMedium!.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('picker.close'),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.of(context).pop(),
                icon: const SymbolIcon(DelveIcons.close),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DelveTokens.space4,
            0,
            DelveTokens.space4,
            DelveTokens.space2,
          ),
          child: SizedBox(
            height: 48,
            child: TextField(
              key: const Key('picker.search'),
              controller: _search,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              style: context.text.bodyLarge,
              decoration: InputDecoration(
                hintText: l.pickerSearch(models.length),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                contentPadding: EdgeInsets.zero,
                prefixIcon: const SymbolIcon(DelveIcons.search, size: 22),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        key: const Key('picker.clear'),
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).deleteButtonTooltip,
                        onPressed: () => setState(_search.clear),
                        icon: const SymbolIcon(DelveIcons.close),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DelveTokens.rxl),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DelveTokens.rxl),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DelveTokens.rxl),
                  borderSide: BorderSide(color: cs.primary, width: 2),
                ),
              ),
            ),
          ),
        ),
        if (_loading && models.isNotEmpty)
          const LinearProgressIndicator(key: Key('picker.progress'))
        else
          const SizedBox(height: 2),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _refresh(force: true),
            child: ListView(
              key: const Key('picker.list'),
              controller: widget.scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}

/// One model: name with its capability icons, the id in mono, the price
/// line; a check when selected and a star. Disabled without a strict
/// zero-retention provider.
class ModelRow extends StatelessWidget {
  const ModelRow({
    super.key,
    required this.model,
    required this.selected,
    required this.favourite,
    required this.onTap,
    required this.onStar,
    this.query = '',
  });

  final OrModelRow model;
  final bool selected;
  final bool favourite;
  final String query;

  /// Null: the model cannot be picked.
  final VoidCallback? onTap;
  final VoidCallback onStar;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final d = context.delve;
    final m = model;
    final enabled = m.selectable;
    final fg = !enabled
        ? d.textDisabled
        : selected
        ? cs.onPrimaryContainer
        : cs.onSurface;
    final sub = !enabled
        ? d.textDisabled
        : selected
        ? cs.onPrimaryContainer
        : cs.onSurfaceVariant;
    final idColor = enabled ? d.textMuted : d.textDisabled;
    final spec = m.reasoningSpec;

    return Material(
      color: selected ? cs.primaryContainer : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        highlightColor: cs.surfaceContainerHighest,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 4, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: _Highlighted(
                              text: m.shortName,
                              query: query,
                              style: context.text.titleSmall!.copyWith(
                                color: fg,
                              ),
                            ),
                          ),
                          if (m.readsImages) ...[
                            const SizedBox(width: 6),
                            Semantics(
                              label: l.pickerReadsImages,
                              child: SymbolIcon(
                                DelveIcons.image,
                                size: DelveTokens.iconSm,
                                color: sub,
                              ),
                            ),
                          ],
                          if (spec.supported) ...[
                            const SizedBox(width: 4),
                            Semantics(
                              label: spec.mandatory
                                  ? l.pickerAlwaysThinks
                                  : l.pickerThinks,
                              child: SymbolIcon(
                                DelveIcons.thinking,
                                size: DelveTokens.iconSm,
                                filled: spec.mandatory,
                                color: sub,
                              ),
                            ),
                          ],
                        ],
                      ),
                      _Highlighted(
                        text: m.id,
                        query: query,
                        style: DelveText.monoSmall.copyWith(color: idColor),
                      ),
                      if (enabled)
                        Text(
                          modelPriceLine(m),
                          style: context.text.labelMedium!.copyWith(
                            color: sub,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        )
                      else
                        Row(
                          key: const Key('picker.noZdr'),
                          children: [
                            SymbolIcon(
                              DelveIcons.block,
                              size: 14,
                              color: d.textDisabled,
                            ),
                            const SizedBox(width: DelveTokens.space1),
                            Text(
                              l.pickerNoZdr,
                              style: context.text.labelMedium!.copyWith(
                                color: d.textDisabled,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (selected)
                  SymbolIcon(
                    DelveIcons.check,
                    key: const Key('picker.check'),
                    size: 22,
                    color: cs.onPrimaryContainer,
                  ),
                IconButton(
                  key: Key('picker.star.${m.id}'),
                  tooltip: favourite
                      ? l.pickerRemoveFavourite(m.shortName)
                      : l.pickerAddFavourite(m.shortName),
                  onPressed: enabled ? onStar : null,
                  icon: SymbolIcon(
                    DelveIcons.star,
                    size: 22,
                    filled: favourite,
                    color: !enabled
                        ? d.textDisabled
                        : favourite
                        ? (selected ? cs.onPrimaryContainer : cs.onSurface)
                        : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// [text] with the matches of [query] marked (primaryContainer, radius-less
/// background: a TextSpan cannot round).
class _Highlighted extends StatelessWidget {
  const _Highlighted({
    required this.text,
    required this.query,
    required this.style,
  });

  final String text;
  final String query;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    final cs = context.colors;
    final lower = text.toLowerCase();
    final spans = <TextSpan>[];
    var at = 0;
    while (true) {
      final i = lower.indexOf(query, at);
      if (i < 0) break;
      if (i > at) spans.add(TextSpan(text: text.substring(at, i)));
      spans.add(
        TextSpan(
          text: text.substring(i, i + query.length),
          style: TextStyle(
            backgroundColor: cs.primaryContainer,
            color: cs.onPrimaryContainer,
          ),
        ),
      );
      at = i + query.length;
    }
    if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
    return Text.rich(
      TextSpan(style: style, children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
