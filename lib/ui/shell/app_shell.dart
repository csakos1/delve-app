import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../widgets/page_scaffolds.dart';

/// The shell branch of the Terminal tab.
const kTerminalBranch = 1;

/// Bottom navigation for the top-level screens: Chats · Terminal ·
/// Dashboard · More. Chats carries a warn dot while an approval waits (its
/// count is in the Chats header).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final pending = ref.watch(answerableApprovalCountProvider).value ?? 0;

    NavigationDestination dest(
      IconData icon,
      String label, {
      bool dot = false,
      String? semantics,
    }) {
      Widget wrap(Widget icon) => dot
          ? Badge(
              key: const Key('nav.chats.dot'),
              smallSize: DelveTokens.navDot,
              backgroundColor: context.delve.warnFg,
              child: icon,
            )
          : icon;
      return NavigationDestination(
        icon: wrap(SymbolIcon(icon)),
        selectedIcon: wrap(SymbolIcon(icon, filled: true)),
        label: label,
        tooltip: semantics,
      );
    }

    return Scaffold(
      // the terminal places itself above the keyboard (it resizes its pty
      // once the keyboard has settled, not on every frame)
      resizeToAvoidBottomInset: shell.currentIndex != kTerminalBranch,
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: context.colors.outlineVariant,
              width: DelveTokens.hairline,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) =>
              shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: [
            dest(
              DelveIcons.chats,
              l.navChats,
              dot: pending > 0,
              semantics: pending > 0
                  ? '${l.navChats}, ${l.approvalsBadge(pending)}'
                  : null,
            ),
            dest(DelveIcons.terminal, l.navTerminal),
            dest(DelveIcons.dashboard, l.navDashboard),
            dest(DelveIcons.more, l.navMore),
          ],
        ),
      ),
    );
  }
}
