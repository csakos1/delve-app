import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/models/models.dart';
import '../../app/router.dart';
import '../../app/watches.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../format.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/status_ui.dart';
import '../widgets/watch_ui.dart';
import 'chat_screen.dart' show NewChatDraft;

/// Opens a new chat for a watch: [draft] fills the composer; without it the
/// watch hint and its examples show (design 21g).
void startWatchChat(BuildContext context, {String? draft}) => unawaited(
  context.push(
    Routes.newChat,
    extra: draft == null
        ? const NewChatDraft(watchHint: true)
        : NewChatDraft(text: draft),
  ),
);

/// 21a Watches: what the agent watches, each with its state and new hits;
/// New watch opens a chat (watches are made and changed in a chat).
class WatchesScreen extends ConsumerStatefulWidget {
  const WatchesScreen({super.key});

  @override
  ConsumerState<WatchesScreen> createState() => _WatchesScreenState();
}

class _WatchesScreenState extends ConsumerState<WatchesScreen> {
  @override
  void initState() {
    super.initState();
    // after the first frame: the refresh changes provider state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_refresh(quiet: true));
    });
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
                    onTap: () => context.push(Routes.watch(w.slug)),
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
