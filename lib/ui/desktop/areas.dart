import 'package:flutter/widgets.dart';

import '../../app/router.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/news_ui.dart';
import '../widgets/page_scaffolds.dart';

/// The areas of the desktop layout (design 27 Workbench), in rail order.
/// The Inbox (Ctrl+1) and Search (the palette) come with L2e and L2d.
enum DesktopArea {
  chats(DelveIcons.chats, Routes.chats, digit: '2'),
  approvals(DelveIcons.approvals, Routes.approvals, digit: '3'),
  dashboard(DelveIcons.dashboard, Routes.dashboard, digit: '4'),
  news(NewsIcons.news, Routes.news, digit: '5'),
  watches(DelveIcons.watches, Routes.watches, digit: '6'),
  schedules(DelveIcons.schedules, Routes.schedules, digit: '7'),
  system(DelveIcons.system, Routes.system, digit: '8'),
  observability(DelveIcons.observability, Routes.observability),
  terminal(DelveIcons.terminal, Routes.terminal, digit: '9', tool: true),
  files(DelveIcons.files, Routes.files, digit: '0', tool: true),
  about(DelveIcons.person, Routes.about),
  settings(DelveIcons.settings, Routes.settings);

  const DesktopArea(this.icon, this.route, {this.digit, this.tool = false});

  final IconData icon;

  /// Where the rail item goes (the area's first page).
  final String route;

  /// Ctrl+digit, if the area has one (Observability and About me are in the
  /// palette only, Settings is Ctrl+,).
  final String? digit;

  /// Terminal and Files: only with the desktop tools.
  final bool tool;

  /// The rail's groups: needs you · talk · decide | look | the machine |
  /// the tools, then (after the spacer) the foot.
  static const List<List<DesktopArea>> groups = [
    [chats, approvals],
    [dashboard, news, watches, schedules],
    [system, observability],
    [terminal, files],
  ];
  static const List<DesktopArea> foot = [about, settings];

  String title(AppLocalizations l) => switch (this) {
    chats => l.navChats,
    approvals => l.navApprovals,
    dashboard => l.navDashboard,
    news => l.newsTitle,
    watches => l.moreWatches,
    schedules => l.moreSchedules,
    system => l.moreSystem,
    observability => l.moreObservability,
    terminal => l.navTerminal,
    files => l.navFiles,
    about => l.moreAbout,
    settings => l.moreSettings,
  };

  /// The key shown in the rail's tooltip.
  String? keys(AppLocalizations l) => switch (this) {
    settings => l.desktopKeySettings,
    _ => switch (digit) {
      final d? => l.desktopKeyArea(d),
      null => null,
    },
  };

  /// The area a [location] belongs to (null: none, e.g. the clipboard).
  static DesktopArea? of(String location) {
    final path = Uri.parse(location).path;
    bool under(String route) => path == route || path.startsWith('$route/');
    if (under(Routes.approvals)) return approvals;
    if (under(Routes.chats) || under(Routes.archived)) return chats;
    for (final area in values) {
      if (area != chats && area != approvals && under(area.route)) {
        return area;
      }
    }
    return null;
  }

  /// The area with Ctrl+[digit].
  static DesktopArea? ofDigit(String digit) {
    for (final area in values) {
      if (area.digit == digit) return area;
    }
    return null;
  }
}
