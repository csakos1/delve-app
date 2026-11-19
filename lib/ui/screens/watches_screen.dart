import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/models/models.dart';
import '../../app/layout.dart';
import '../../app/router.dart';
import '../../app/watches.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../desktop/desktop_page.dart'
    show PageCommandSlot, PageCommands, pageCommandSlotProvider;
import '../desktop/intake.dart'
    show ListCommandSlot, ListCommands, listCommandSlotProvider;
import '../format.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/status_ui.dart';
import '../widgets/watch_ui.dart';
import 'chat_screen.dart' show NewChatDraft;

/// Opens a new chat for a watch: [draft] fills the composer; without it the
/// watch hint and its examples show (design 21g).
void startWatchChat(BuildContext context, {String? draft}) => context.open(
  Routes.newChat,
  extra: draft == null
      ? const NewChatDraft(watchHint: true)
      : NewChatDraft(text: draft),
);

/// 21a Watches: what the agent watches, each with its state and new hits;
/// New watch opens a chat (watches are made and changed in a chat). On the
/// desktop (27W-9a) the list column of the Watches area.
class WatchesScreen extends ConsumerStatefulWidget {
  const WatchesScreen({super.key, this.selected});

  /// The desktop: the watch open in the content (its row is selected).
  final String? selected;

  @override
  ConsumerState<WatchesScreen> createState() => _WatchesScreenState();
}

class _WatchesScreenState extends ConsumerState<WatchesScreen> {
  /// The desktop: the watches in the order shown (J / K).
  List<String> _order = const [];
  late final ListCommandSlot _keys;
  late final PageCommandSlot _pageKeys;

  @override
  void initState() {
    super.initState();
    _keys = ref.read(listCommandSlotProvider);
    _pageKeys = ref.read(pageCommandSlotProvider);
    // after the first frame: the refresh changes provider state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_refresh(quiet: true));
    });
  }

  @override
  void dispose() {
    _keys.unregister(this);
    _pageKeys.unregister(this);
    super.dispose();
  }

  /// J / K: the next / previous watch (the first without one open).
  void _step(int by) {
    final order = _order;
    if (order.isEmpty) return;
    final at = widget.selected == null ? -1 : order.indexOf(widget.selected!);
    final next = at < 0 ? 0 : (at + by).clamp(0, order.length - 1);
    if (next == at) return;
    context.open(Routes.watch(order[next]));
  }

  Future<void> _refresh({bool quiet = false}) async {
    try {
      await ref.read(watchesProvider.notifier).refresh();
    } on Object catch (e) {
      if (quiet || !mounted) return;
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.watchesLoadFailed(apiErrorText(l, e)))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final view = ref.watch(watchesProvider);
    final items = view.items;
    final error = view.error;
    if (DesktopLayout.of(context)) return _desktop(context, l, view);
    return Scaffold(
      appBar: PageColourBar(title: l.moreWatches),
      floatingActionButton: items == null || items.isEmpty
          ? null
          : FloatingActionButton.extended(
              key: const Key('watches.new'),
              onPressed: () => startWatchChat(context),
              icon: const SymbolIcon(DelveIcons.newWatch),
              label: Text(l.watchesNew),
            ),
      body: UnderBarFade(
        child: switch (items) {
          null when error != null => Padding(
            padding: const EdgeInsets.all(DelveTokens.space4),
            child: Align(
              alignment: Alignment.topCenter,
              child: StatusBanner(
                kind: StatusKind.alert,
                icon: DelveIcons.error,
                text: l.watchesLoadFailed(apiErrorText(l, error)),
                actionLabel: l.retry,
                onAction: _refresh,
              ),
            ),
          ),
          null => const Center(child: CircularProgressIndicator()),
          [] => _Empty(onNew: () => startWatchChat(context)),
          final List<Watch> list => RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.only(
                top: UnderBarFade.height,
                // clear of the extended FAB
                bottom:
                    DelveTokens.button +
                    DelveTokens.space8 +
                    DelveTokens.space4,
              ),
              children: [
                for (final w in list)
                  WatchRow(
                    watch: w,
                    onTap: () => context.open(Routes.watch(w.slug)),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DelveTokens.space4 * 2 + DelveTokens.iconLg,
                    DelveTokens.space4,
                    DelveTokens.space4,
                    0,
                  ),
                  child: Text(
                    l.watchesNote,
                    style: context.text.bodySmall!.copyWith(
                      color: context.delve.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        },
      ),
    );
  }

  /// Ctrl+R: the list, and the open watch's items.
  Future<void> _refreshAll() async {
    final slug = widget.selected;
    await _refresh();
    if (slug == null || !mounted) return;
    try {
      await ref.read(watchItemsProvider(slug).notifier).refresh();
    } on Object {
      // the open watch shows the failure in its tab
    }
  }

  /// The desktop's list column (27W-9a): a 48 px header with New watch,
  /// the watches as 52 px rows, the open one selected. J / K step through
  /// them, Ctrl+R reloads.
  Widget _desktop(BuildContext context, AppLocalizations l, WatchesView view) {
    _keys.register(
      this,
      ListCommands(
        next: () => _step(1),
        previous: () => _step(-1),
        archive: () {},
        undo: () {},
      ),
    );
    _pageKeys.register(
      this,
      PageCommands(refresh: () => unawaited(_refreshAll())),
    );
    final items = view.items;
    final error = view.error;
    final now = DateTime.now();
    _order = [for (final w in items ?? const <Watch>[]) w.slug];
    final muted = context.delve.textMuted;
    return TopLevelPage(
      title: l.moreWatches,
      background: context.colors.surfaceContainerLow,
      actions: [
        IconButton(
          key: const Key('watches.new'),
          tooltip: l.watchesNew,
          onPressed: () => startWatchChat(context),
          icon: const SymbolIcon(
            DelveIcons.add,
            size: DelveDesktop.iconButtonIcon,
          ),
        ),
      ],
      child: switch (items) {
        null when error != null => Padding(
          padding: const EdgeInsets.all(DelveTokens.space3),
          child: Align(
            alignment: Alignment.topCenter,
            child: StatusBanner(
              kind: StatusKind.alert,
              icon: DelveIcons.error,
              text: l.watchesLoadFailed(apiErrorText(l, error)),
              actionLabel: l.retry,
              onAction: _refresh,
            ),
          ),
        ),
        null => const Center(child: CircularProgressIndicator()),
        [] => Padding(
          key: const Key('watches.empty'),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.watchesEmptyTitle, style: context.text.titleSmall),
              const SizedBox(height: DelveTokens.space1),
              Text(
                l.watchesEmptyBody,
                style: DelveDesktopText.rowSecondary.copyWith(color: muted),
              ),
              const SizedBox(height: DelveTokens.space3),
              FilledButton.icon(
                key: const Key('watches.emptyNew'),
                onPressed: () => startWatchChat(context),
                icon: const SymbolIcon(DelveIcons.newWatch, size: 16),
                label: Text(l.watchesNew),
              ),
            ],
          ),
        ),
        final List<Watch> list => ListView(
          key: const Key('watches.list'),
          padding: const EdgeInsets.only(bottom: DelveTokens.space4),
          children: [
            for (final w in list)
              DesktopWatchRow(
                watch: w,
                now: now,
                selected: w.slug == widget.selected,
                onTap: () => context.open(Routes.watch(w.slug)),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                l.watchesNote,
                style: DelveDesktopText.meta.copyWith(color: muted),
              ),
            ),
          ],
        ),
      },
    );
  }
}

/// 21a2: no watches yet.
class _Empty extends StatelessWidget {
  const _Empty({required this.onNew});

  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        key: const Key('watches.empty'),
        padding: const EdgeInsets.all(DelveTokens.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SymbolIcon(
              DelveIcons.watches,
              size: 48,
              color: context.delve.textMuted,
            ),
            const SizedBox(height: DelveTokens.space4),
            Text(l.watchesEmptyTitle, style: context.text.titleMedium),
            const SizedBox(height: DelveTokens.space2),
            Text(
              l.watchesEmptyBody,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium!.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DelveTokens.space5),
            FilledButton.icon(
              key: const Key('watches.emptyNew'),
              onPressed: onNew,
              icon: const SymbolIcon(DelveIcons.newWatch),
              label: Text(l.watchesNew),
            ),
          ],
        ),
      ),
    );
  }
}
