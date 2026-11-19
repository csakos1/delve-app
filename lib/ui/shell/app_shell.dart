import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/platform.dart';
import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../widgets/page_scaffolds.dart';

/// The shell branch of the Terminal tab.
const kTerminalBranch = 1;

/// The shell branch of the Files tab.
const kFilesBranch = 2;

/// The shell branches the bottom navigation shows, in order: all five, or
/// without Terminal and Files when the desktop tools are off (the Linux
/// app's default).
List<int> visibleBranches({required bool desktopTools}) => [
  0,
  if (desktopTools) ...[kTerminalBranch, kFilesBranch],
  3,
  4,
];

/// Bottom navigation for the top-level screens: Chats · Terminal · Files ·
/// Dashboard · More (Terminal and Files only with the desktop tools). Chats
/// carries a warn dot while an approval waits (its count is in the Chats
/// header).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final pending = ref.watch(answerableApprovalCountProvider).value ?? 0;
    final branches = visibleBranches(
      desktopTools: ref.watch(desktopToolsProvider),
    );
    // a hidden branch in front (the tools were just turned off): Chats
    final selected = branches.indexOf(shell.currentIndex);

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
          selectedIndex: selected < 0 ? 0 : selected,
          onDestinationSelected: (i) {
            final branch = branches[i];
            shell.goBranch(
              branch,
              initialLocation: branch == shell.currentIndex,
            );
          },
          destinations: [
            for (final branch in branches)
              switch (branch) {
                0 => dest(
                  DelveIcons.chats,
                  l.navChats,
                  dot: pending > 0,
                  semantics: pending > 0
                      ? '${l.navChats}, ${l.approvalsBadge(pending)}'
                      : null,
                ),
                kTerminalBranch => dest(DelveIcons.terminal, l.navTerminal),
                kFilesBranch => dest(DelveIcons.files, l.navFiles),
                3 => dest(DelveIcons.dashboard, l.navDashboard),
                _ => dest(DelveIcons.more, l.navMore),
              },
          ],
        ),
      ),
    );
  }
}
