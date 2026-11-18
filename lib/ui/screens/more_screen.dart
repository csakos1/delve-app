import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../widgets/news_ui.dart';
import '../widgets/page_scaffolds.dart';

/// The sub-pages reachable from More.
enum MorePage {
  system('system', DelveIcons.system, Routes.system),
  schedules('schedules', DelveIcons.schedules, Routes.schedules),
  watches('watches', DelveIcons.watches, Routes.watches),
  news('news', NewsIcons.news, Routes.news),
  clipboard('clipboard', DelveIcons.paste, Routes.clipboard),
  mirroring('mirroring', DelveIcons.notifications, Routes.mirroring),
  about('about', DelveIcons.person, Routes.about),
  observability(
    'observability',
    DelveIcons.observability,
    Routes.observability,
  ),
  settings('settings', DelveIcons.settings, Routes.settings),
  archived('archived', DelveIcons.archive, Routes.archived);

  const MorePage(this.segment, this.icon, this.route);

  final String segment;
  final IconData icon;
  final String route;

  String title(AppLocalizations l) => switch (this) {
    MorePage.system => l.moreSystem,
    MorePage.schedules => l.moreSchedules,
    MorePage.watches => l.moreWatches,
    MorePage.news => l.newsTitle,
    MorePage.clipboard => l.moreClipboard,
    MorePage.mirroring => l.moreMirroring,
    MorePage.about => l.moreAbout,
    MorePage.observability => l.moreObservability,
    MorePage.settings => l.moreSettings,
    MorePage.archived => l.moreArchived,
  };

  String subtitle(AppLocalizations l) => switch (this) {
    MorePage.system => l.moreSystemSub,
    MorePage.schedules => l.moreSchedulesSub,
    MorePage.watches => l.moreWatchesSub,
    MorePage.news => l.moreNewsSub,
    MorePage.clipboard => l.moreClipboardSub,
    MorePage.mirroring => l.moreMirroringSub,
    MorePage.about => l.moreAboutSub,
    MorePage.observability => l.moreObservabilitySub,
    MorePage.settings => l.moreSettingsSub,
    MorePage.archived => l.moreArchivedSub,
  };
}

/// 13-0 More — System, Schedules, Watches, News, Clipboard, Mirroring, About me,
/// Observability, Settings, Archived chats.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return TopLevelPage(
      title: l.navMore,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: DelveTokens.space2),
        children: [
          for (final page in MorePage.values)
            ListTile(
              minTileHeight: DelveTokens.listRow - DelveTokens.space4,
              leading: SymbolIcon(page.icon),
              title: Text(page.title(l), style: context.text.titleSmall),
              subtitle: Text(page.subtitle(l)),
              trailing: SymbolIcon(
                DelveIcons.chevronRight,
                size: DelveTokens.iconMd,
                color: context.delve.textMuted,
              ),
              onTap: () => context.push(page.route),
            ),
        ],
      ),
    );
  }
}
