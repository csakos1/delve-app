import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ui/screens/approvals_screen.dart';
import '../ui/screens/chat_screen.dart';
import '../ui/screens/chats_screen.dart';
import '../ui/screens/dashboard_screen.dart';
import '../ui/screens/more_screen.dart';
import '../ui/screens/pairing_screen.dart';
import '../ui/screens/sub_page_placeholder.dart';
import '../ui/shell/app_shell.dart';

/// Route paths. Top-level screens live in the shell (bottom nav); Chat and
/// the More sub-pages are pushed on the root navigator, so they have none.
abstract final class Routes {
  static const chats = '/chats';
  static const dashboard = '/dashboard';
  static const approvals = '/approvals';
  static const more = '/more';
  static const newChat = '/chats/new';
  static String chat(String id) => '/chats/c/${Uri.encodeComponent(id)}';
  static const system = '/more/system';
  static const schedules = '/more/schedules';
  static const observability = '/more/observability';
  static const settings = '/more/settings';
  static const pair = '/pair';
}

GoRouter buildRouter({String initialLocation = Routes.chats}) {
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: Routes.pair, builder: (_, _) => const PairingScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.chats,
                builder: (_, _) => const ChatsScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: rootKey,
                    builder: (_, _) => const ChatScreen(conversationId: null),
                  ),
                  GoRoute(
                    path: 'c/:id',
                    parentNavigatorKey: rootKey,
                    builder: (_, state) =>
                        ChatScreen(conversationId: state.pathParameters['id']),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.dashboard,
                builder: (_, _) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.approvals,
                builder: (_, _) => const ApprovalsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.more,
                builder: (_, _) => const MoreScreen(),
                routes: [
                  for (final page in MorePage.values)
                    GoRoute(
                      path: page.segment,
                      parentNavigatorKey: rootKey,
                      builder: (_, _) => SubPagePlaceholder(page: page),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// The app's router; tests may override it with another initial location.
final routerProvider = Provider<GoRouter>((ref) {
  final router = buildRouter();
  ref.onDispose(router.dispose);
  return router;
});
