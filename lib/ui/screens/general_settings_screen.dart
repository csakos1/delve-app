import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../general/general_database.dart';
import '../../general/general_key_store.dart';
import '../../general/general_providers.dart';
import '../../general/model_catalog.dart';
import '../../general/openrouter_client.dart';
import '../../general/openrouter_errors.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../general/general_format.dart';
import '../general/model_picker.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/status_ui.dart';

/// 24g Settings → General: the phone's OpenRouter key (paste, replace,
/// remove) with this period's spend, the default model, the favourites
/// (reorder by drag, remove, add from the picker), the token footer, the
/// system prompt and the privacy note. Export / import come in G1c.
class GeneralSettingsScreen extends ConsumerStatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  ConsumerState<GeneralSettingsScreen> createState() =>
      _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends ConsumerState<GeneralSettingsScreen> {
  final _field = TextEditingController();
  bool _replacing = false;
  bool _saving = false;
  String? _error;

  late final GeneralDatabase _db;
  final _prompt = TextEditingController();
  bool _promptLoaded = false;
  Timer? _promptSave;

  /// The favourites as just edited, until the database has them (so a drag
  /// does not jump back for a frame).
  List<String>? _favs;

  @override
  void initState() {
    super.initState();
    _db = ref.read(generalDatabaseProvider);
    _field.addListener(() => setState(() => _error = null));
    unawaited(_loadPrompt());
  }

  @override
  void dispose() {
    // a prompt typed just before leaving is still saved
    if (_promptSave?.isActive ?? false) {
      _promptSave!.cancel();
      _savePrompt();
    }
    _field.dispose();
    _prompt.dispose();
    super.dispose();
  }

  Future<void> _loadPrompt() async {
    final saved = await _db.meta(GeneralMetaKeys.systemPrompt);
    if (!mounted) return;
    if (_prompt.text.isEmpty) _prompt.text = saved ?? '';
    setState(() => _promptLoaded = true);
  }

  void _onPromptChanged(String _) {
    _promptSave?.cancel();
    _promptSave = Timer(promptSaveDelay, _savePrompt);
  }

  /// Saves the system prompt; a blank one is removed (none is sent).
  void _savePrompt() {
    final text = _prompt.text;
    unawaited(
      _db.setMeta(
        GeneralMetaKeys.systemPrompt,
        text.trim().isEmpty ? null : text,
      ),
    );
  }

  Future<void> _setFavourites(List<String> ids) async {
    setState(() => _favs = ids);
    await ref.read(modelCatalogProvider).setFavourites(ids);
  }

  void _moveFavourite(List<String> favourites, int from, int to) {
    final ids = [...favourites];
    final id = ids.removeAt(from);
    ids.insert(to > from ? to - 1 : to, id);
    unawaited(_setFavourites(ids));
  }

  Future<void> _removeFavourite(
    List<String> favourites,
    String id,
    String name,
  ) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final catalog = ref.read(modelCatalogProvider);
    final before = [...favourites];
    await _setFavourites([...favourites]..remove(id));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l.generalFavRemoved(name)),
          persist: false,
          duration: DelveTokens.undoSnack,
          action: SnackBarAction(
            label: l.chatsUndo,
            onPressed: () => unawaited(catalog.setFavourites(before)),
          ),
        ),
      );
  }

  Future<void> _addFavourite() async {
    final l = AppLocalizations.of(context);
    final picked = await showModelPicker(
      context,
      current: null,
      subtitle: l.pickerSubFavourite,
    );
    if (picked == null || !mounted) return;
    // the picker's stars may have changed the list meanwhile
    final List<String> stored = ref.read(generalFavouritesProvider);
    final now = _favs ?? stored;
    if (now.contains(picked)) return;
    await _setFavourites([...now, picked]);
  }

  void _snack(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) _field.text = text;
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final key = _field.text.trim();
    if (!looksLikeOpenRouterKey(key)) {
      setState(() => _error = l.generalKeyNotKey);
      return;
    }
    setState(() => _saving = true);
    try {
      final info = await ref.read(generalKeyProvider.notifier).save(key);
      if (!mounted) return;
      _field.clear();
      setState(() => _replacing = false);
      _snack(info == null ? l.generalKeySavedUnchecked : l.generalKeySaved);
    } on GeneralUnauthorized {
      if (mounted) setState(() => _error = l.generalKeyRejected);
    } on GeneralFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remove() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.generalKeyRemoveTitle),
        content: Text(l.generalKeyRemoveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            key: const Key('generalSettings.remove.confirm'),
            style: TextButton.styleFrom(foregroundColor: context.delve.alertFg),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.generalKeyRemove),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(generalKeyProvider.notifier).remove();
  }

  Future<void> _pickDefault(String current) async {
    final l = AppLocalizations.of(context);
    final picked = await showModelPicker(
      context,
      current: current,
      subtitle: l.pickerSubDefault,
    );
    if (picked == null) return;
    await ref.read(modelCatalogProvider).setDefaultModel(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final key = ref.watch(generalKeyProvider).value;
    final editing = key == null || _replacing;
    final defaultModel = ref.watch(generalDefaultModelProvider);
    final models = ref.watch(generalModelsProvider).value ?? const [];
    final row = models.where((m) => m.id == defaultModel).firstOrNull;
    final showTokens =
        ref.watch(generalMetaProvider(GeneralMetaKeys.showTokens)).value == '1';
    ref.listen(generalFavouritesProvider, (_, next) {
      final pending = _favs;
      if (pending != null && pending.join('\n') == next.join('\n')) {
        setState(() => _favs = null);
      }
    });
    final storedFavourites = ref.watch(generalFavouritesProvider);
    final favourites = _favs ?? storedFavourites;
    final byId = {for (final m in models) m.id: m};
    final cs = context.colors;
    final muted = context.delve.textMuted;

    return Scaffold(
      appBar: PageColourBar(title: l.settingsGeneral),
      body: UnderBarFade(
        child: ListView(
          key: const Key('generalSettings.list'),
          padding: const EdgeInsets.fromLTRB(
            0,
            UnderBarFade.height,
            0,
            DelveTokens.space8,
          ),
          children: [
            _Section(l.generalSettingsKey),
            if (editing)
              _KeyField(
                controller: _field,
                error: _error,
                saving: _saving,
                onPaste: () => unawaited(_paste()),
                onSave: () => unawaited(_save()),
                onCancel: key == null
                    ? null
                    : () => setState(() {
                        _replacing = false;
                        _field.clear();
                      }),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DelveTokens.space4,
                  0,
                  DelveTokens.space2,
                  0,
                ),
                child: Row(
                  children: [
                    SymbolIcon(DelveIcons.key, color: cs.onSurfaceVariant),
                    const SizedBox(width: DelveTokens.space4),
                    Expanded(
                      child: Text(
                        maskKey(key),
                        key: const Key('generalSettings.masked'),
                        style: DelveText.mono,
                      ),
                    ),
                    OutlinedButton(
                      key: const Key('generalSettings.replace'),
                      onPressed: () => setState(() => _replacing = true),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(
                          horizontal: DelveTokens.space3,
                        ),
                      ),
                      child: Text(l.generalKeyReplace),
                    ),
                    TextButton(
                      key: const Key('generalSettings.remove'),
                      onPressed: () => unawaited(_remove()),
                      style: TextButton.styleFrom(
                        foregroundColor: context.delve.alertFg,
                      ),
                      child: Text(l.generalKeyRemove),
                    ),
                  ],
                ),
              ),
              const _Spend(),
            ],
            _Section(l.generalSettingsModels),
            ListTile(
              key: const Key('generalSettings.defaultModel'),
              leading: const SymbolIcon(DelveIcons.cloud),
              title: Text(l.generalDefaultModel),
              subtitle: Text(
                row == null ? defaultModel : '${row.shortName} · $defaultModel',
                style: DelveText.monoSmall.copyWith(color: muted),
              ),
              trailing: const SymbolIcon(DelveIcons.chevronRight),
              onTap: key == null
                  ? null
                  : () => unawaited(_pickDefault(defaultModel)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DelveTokens.space4,
                DelveTokens.space4,
                DelveTokens.space4,
                DelveTokens.space1,
              ),
              child: Text(
                l.pickerFavourites.toUpperCase(),
                style: context.text.labelSmall!.copyWith(color: muted),
              ),
            ),
            if (favourites.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DelveTokens.space4,
                  vertical: DelveTokens.space2,
                ),
                child: Text(
                  l.generalFavEmpty,
                  key: const Key('generalSettings.fav.empty'),
                  style: context.text.bodyMedium!.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              )
            else
              ReorderableListView(
                key: const Key('generalSettings.favs'),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                onReorder: (from, to) => _moveFavourite(favourites, from, to),
                children: [
                  for (final (i, id) in favourites.indexed)
                    _FavouriteRow(
                      key: ValueKey('generalSettings.fav.$id'),
                      index: i,
                      id: id,
                      name: modelShortName(id, byId[id]),
                      onRemove: () => unawaited(
                        _removeFavourite(
                          favourites,
                          id,
                          modelShortName(id, byId[id]),
                        ),
                      ),
                    ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DelveTokens.space2,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('generalSettings.fav.add'),
                  onPressed: key == null
                      ? null
                      : () => unawaited(_addFavourite()),
                  icon: const SymbolIcon(DelveIcons.add, size: 20),
                  label: Text(l.generalFavAdd),
                ),
              ),
            ),
            SwitchListTile(
              key: const Key('generalSettings.tokens'),
              title: Text(l.generalShowTokens),
              subtitle: Text(l.generalShowTokensSub),
              value: showTokens,
              onChanged: (v) => unawaited(
                ref
                    .read(generalDatabaseProvider)
                    .setMeta(GeneralMetaKeys.showTokens, v ? '1' : null),
              ),
            ),
            _Section(l.generalSettingsPrompt),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DelveTokens.space4,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 112),
                child: TextField(
                  key: const Key('generalSettings.prompt'),
                  controller: _prompt,
                  enabled: _promptLoaded,
                  minLines: 4,
                  maxLines: 12,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: _onPromptChanged,
                  decoration: InputDecoration(
                    hintText: l.generalPromptHint,
                    helperText: l.generalPromptHelper,
                    helperMaxLines: 3,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DelveTokens.space4,
                DelveTokens.space6,
                DelveTokens.space4,
                0,
              ),
              child: Container(
                key: const Key('generalSettings.privacy'),
                padding: const EdgeInsets.all(DelveTokens.space4),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(DelveTokens.rmd),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SymbolIcon(
                      DelveIcons.shield,
                      size: DelveTokens.iconMd,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: DelveTokens.space3),
                    Expanded(
                      child: Text(
                        l.generalPrivacyNote,
                        style: context.text.bodySmall!.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// How long the system prompt waits after the last keystroke to be saved.
const Duration promptSaveDelay = Duration(milliseconds: 500);

/// A favourite: drag handle, short name over the id, remove.
class _FavouriteRow extends StatelessWidget {
  const _FavouriteRow({
    super.key,
    required this.index,
    required this.id,
    required this.name,
    required this.onRemove,
  });

  final int index;
  final String id;
  final String name;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final muted = context.delve.textMuted;
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            ReorderableDragStartListener(
              key: Key('generalSettings.fav.drag.$id'),
              index: index,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DelveTokens.space4,
                  vertical: DelveTokens.space3,
                ),
                child: SymbolIcon(
                  DelveIcons.dragIndicator,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall,
                  ),
                  Text(
                    id,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DelveText.monoSmall.copyWith(color: muted),
                  ),
                ],
              ),
            ),
            IconButton(
              key: Key('generalSettings.fav.remove.$id'),
              tooltip: l.pickerRemoveFavourite(name),
              onPressed: onRemove,
              icon: SymbolIcon(DelveIcons.close, color: cs.onSurfaceVariant),
            ),
            const SizedBox(width: DelveTokens.space1),
          ],
        ),
      ),
    );
  }
}

/// Paste a key: the field with a paste icon, the helper and Save (enabled
/// once it starts with `sk-or-`).
class _KeyField extends StatelessWidget {
  const _KeyField({
    required this.controller,
    required this.error,
    required this.saving,
    required this.onPaste,
    required this.onSave,
    this.onCancel,
  });

  final TextEditingController controller;
  final String? error;
  final bool saving;
  final VoidCallback onPaste;
  final VoidCallback onSave;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ready = controller.text.trim().startsWith('sk-or-') && !saving;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DelveTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('generalSettings.field'),
            controller: controller,
            autofocus: onCancel == null,
            autocorrect: false,
            enableSuggestions: false,
            obscureText: true,
            style: DelveText.mono,
            onSubmitted: (_) {
              if (ready) onSave();
            },
            decoration: InputDecoration(
              labelText: l.generalKeyPaste,
              helperText: error == null ? l.generalKeyHelper : null,
              helperMaxLines: 3,
              errorText: error,
              errorMaxLines: 3,
              suffixIcon: IconButton(
                key: const Key('generalSettings.paste'),
                tooltip: l.generalKeyPasteAction,
                onPressed: onPaste,
                icon: const SymbolIcon(DelveIcons.paste),
              ),
            ),
          ),
          const SizedBox(height: DelveTokens.space3),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onCancel != null)
                TextButton(onPressed: onCancel, child: Text(l.cancel)),
              const SizedBox(width: DelveTokens.space2),
              FilledButton(
                key: const Key('generalSettings.save'),
                onPressed: ready ? onSave : null,
                child: saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l.generalKeySave),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// This period's spend against the key's limit (4 dp bar), when it resets,
/// and a note when the limit never resets (N188).
class _Spend extends ConsumerWidget {
  const _Spend();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final muted = context.delve.textMuted;
    final info = ref.watch(generalKeyInfoProvider);
    final Widget body = switch (info) {
      AsyncData(value: final KeyInfo i) => _info(context, l, i),
      AsyncError(:final error) => Text(
        l.generalKeyInfoFailed(
          error is GeneralFailure ? error.message : '$error',
        ),
        style: context.text.bodySmall!.copyWith(color: muted),
      ),
      AsyncData() => const SizedBox.shrink(),
      _ => const LinearProgressIndicator(),
    };
    return Padding(
      key: const Key('generalSettings.spend'),
      padding: const EdgeInsets.fromLTRB(
        DelveTokens.space4 + DelveTokens.iconLg + DelveTokens.space4,
        DelveTokens.space2,
        DelveTokens.space4,
        0,
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: cs.onSurfaceVariant),
        child: body,
      ),
    );
  }

  Widget _info(BuildContext context, AppLocalizations l, KeyInfo i) {
    final cs = context.colors;
    final d = context.delve;
    final limit = i.limit;
    final used = keySpent(i);
    final resets = i.resetsAt;
    final line = keySpendText(l, i);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          line,
          key: const Key('generalSettings.spend.line'),
          style: context.text.bodyMedium!.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (limit != null && limit > 0) ...[
          const SizedBox(height: DelveTokens.space2),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              key: const Key('generalSettings.spend.bar'),
              value: (used / limit).clamp(0.0, 1.0),
              minHeight: 4,
              color: used >= limit ? d.alertFg : cs.primary,
              backgroundColor: cs.surfaceContainerHighest,
            ),
          ),
        ],
        if (resets != null) ...[
          const SizedBox(height: DelveTokens.space1),
          Text(
            l.generalKeyResets(DateFormat('d MMM').format(resets.toLocal())),
            style: context.text.labelMedium!.copyWith(color: d.textMuted),
          ),
        ],
        if (limit != null && i.limitReset == null) ...[
          const SizedBox(height: DelveTokens.space3),
          StatusBanner(
            key: const Key('generalSettings.noReset'),
            kind: StatusKind.warn,
            icon: DelveIcons.warning,
            text: l.generalKeyNoReset,
          ),
        ],
      ],
    );
  }
}

/// Section eyebrow: accent, upper case, spaced (as in Settings).
class _Section extends StatelessWidget {
  const _Section(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      DelveTokens.space4,
      DelveTokens.space6,
      DelveTokens.space4,
      DelveTokens.space2,
    ),
    child: Semantics(
      header: true,
      child: Text(
        label.toUpperCase(),
        style: context.text.labelMedium!.copyWith(
          color: context.colors.primary,
          letterSpacing: 1.2,
        ),
      ),
    ),
  );
}
