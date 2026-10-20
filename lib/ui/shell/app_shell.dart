import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../widgets/page_scaffolds.dart';

/// Bottom navigation for the top-level screens: Chats · Dashboard ·
/// Approvals (badge) · More.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final pending = ref.watch(answerableApprovalCountProvider).value ?? 0;

    NavigationDestination dest(IconData icon, String label, {Widget? badge}) {
      Widget wrap(Widget icon) => badge == null
          ? icon
          : Badge(
              label: badge,
              backgroundColor: context.delve.warnFg,
              textColor: context.colors.onTertiary,
              textStyle: context.text.labelSmall,
              largeSize: 18,
              child: icon,
            );
      return NavigationDestination(
        icon: wrap(SymbolIcon(icon)),
        selectedIcon: wrap(SymbolIcon(icon, filled: true)),
        label: label,
      );
    }

    return Scaffold(
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
            dest(DelveIcons.chats, l.navChats),
            dest(DelveIcons.dashboard, l.navDashboard),
            dest(
              DelveIcons.approvals,
              l.navApprovals,
              badge: pending > 0
                  ? Semantics(
                      label: l.approvalsBadge(pending),
                      child: Text('$pending'),
                    )
                  : null,
            ),
            dest(DelveIcons.more, l.navMore),
          ],
        ),
      ),
    );
  }
}
