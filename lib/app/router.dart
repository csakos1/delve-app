import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ui/screens/approvals_screen.dart';
import '../ui/screens/archived_chats_screen.dart';
import '../ui/screens/chat_screen.dart';
import '../ui/screens/chats_screen.dart';
import '../ui/screens/connection_log_screen.dart';
import '../ui/screens/dashboard_screen.dart';
import '../ui/screens/more_screen.dart';
import '../ui/screens/observability_screen.dart';
import '../ui/screens/pairing_screen.dart';
import '../ui/screens/schedule_editor_screen.dart';
import '../ui/screens/schedules_screen.dart';
import '../ui/screens/server_too_old_screen.dart';
import '../ui/screens/settings_screen.dart';
import '../ui/screens/splash_screen.dart';
import '../ui/screens/system_screen.dart';
import '../ui/shell/app_shell.dart';
import 'session.dart';

/// Route paths. Top-level screens live in the shell (bottom nav); Chat and
/// the More sub-pages are pushed on the root navigator, so they have none.
abstract final class Routes {
  static const splash = '/splash';
  static const pair = '/pair';
  static const serverTooOld = '/server-too-old';
  static const chats = '/chats';
  static const dashboard = '/dashboard';
  static const approvals = '/approvals';
  static const more = '/more';
  static const newChat = '/chats/new';
  static String chat(String id) => '/chats/c/${Uri.encodeComponent(id)}';
  static const system = '/more/system';
  static const schedules = '/more/schedules';
  static const newSchedule = '/more/schedules/new';
  static String editSchedule(String id) =>
      '/more/schedules/edit/${Uri.encodeComponent(id)}';
  static const observability = '/more/observability';
  static const settings = '/more/settings';
  static const connectionLog = '/more/settings/log';
  static const archived = '/more/archived';

  /// Screens that are only reachable in one session state.
  static const gates = {splash, pair, serverTooOld};
}

/// Where the session state sends the user; null = stay.
@visibleForTesting
String? sessionRedirect(SessionState session, String location) {
  final target = switch (session) {
    SessionLoading() => Routes.splash,
    SessionUnpaired() => Routes.pair,
    SessionServerTooOld() => Routes.serverTooOld,
    SessionPaired() => Routes.gates.contains(location) ? Routes.chats : null,
  };
  return target == location ? null : target;
}

GoRouter buildRouter({
  required ValueListenable<SessionState> session,
  String initialLocation = Routes.splash,
}) {
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: initialLocation,
    refreshListenable: session,
    redirect: (context, state) =>
        sessionRedirect(session.value, state.matchedLocation),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.pair, builder: (_, _) => const PairingScreen()),
      GoRoute(
        path: Routes.serverTooOld,
        builder: (_, _) => const ServerTooOldScreen(),
      ),
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
                      builder: (_, _) => switch (page) {
                        MorePage.settings => const SettingsScreen(),
                        MorePage.archived => const ArchivedChatsScreen(),
                        MorePage.system => const SystemScreen(),
                        MorePage.schedules => const SchedulesScreen(),
                        MorePage.observability => const ObservabilityScreen(),
                      },
                      routes: [
                        if (page == MorePage.settings)
                          GoRoute(
                            path: 'log',
                            parentNavigatorKey: rootKey,
                            builder: (_, _) => const ConnectionLogScreen(),
                          ),
                        if (page == MorePage.schedules) ...[
                          GoRoute(
                            path: 'new',
                            parentNavigatorKey: rootKey,
                            builder: (_, _) => const ScheduleEditorScreen(),
                          ),
                          GoRoute(
                            path: 'edit/:id',
                            parentNavigatorKey: rootKey,
                            builder: (_, state) => ScheduleEditorScreen(
                              scheduleId: state.pathParameters['id'],
                            ),
                          ),
                        ],
                      ],
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

/// The app's router, driven by the session state.
final routerProvider = Provider<GoRouter>((ref) {
  final session = ValueNotifier<SessionState>(ref.read(sessionProvider));
  ref.listen(sessionProvider, (_, next) => session.value = next);
  final router = buildRouter(session: session);
  ref.onDispose(() {
    router.dispose();
    session.dispose();
  });
  return router;
});
