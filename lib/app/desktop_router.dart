import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ui/desktop/chats_area.dart';
import '../ui/desktop/desktop_shell.dart';
import '../ui/general/general_widgets.dart' show ChatKind;
import '../ui/screens/approvals_screen.dart';
import '../ui/screens/archived_chats_screen.dart';
import '../ui/screens/chat_screen.dart';
import '../ui/screens/clipboard_screen.dart';
import '../ui/screens/connection_log_screen.dart';
import '../ui/screens/dashboard_screen.dart';
import '../ui/screens/file_preview_screen.dart';
import '../ui/screens/files_screen.dart';
import '../ui/screens/general_chat_screen.dart';
import '../ui/screens/general_settings_screen.dart';
import '../ui/screens/more_screen.dart';
import '../ui/screens/news_screen.dart';
import '../ui/screens/news_settings_screen.dart';
import '../ui/screens/news_story_screen.dart';
import '../ui/screens/observability_screen.dart';
import '../ui/screens/pairing_screen.dart';
import '../ui/screens/persona_screen.dart';
import '../ui/screens/schedule_editor_screen.dart';
import '../ui/screens/schedules_screen.dart';
import '../ui/screens/server_too_old_screen.dart';
import '../ui/screens/settings_screen.dart';
import '../ui/screens/splash_screen.dart';
import '../ui/screens/system_screen.dart';
import '../ui/screens/terminal_screen.dart';
import '../ui/screens/terminal_settings_screen.dart';
import '../ui/screens/trash_screen.dart';
import '../ui/screens/watch_detail_screen.dart';
import '../ui/screens/watches_screen.dart';
import 'router.dart';
import 'session.dart';

/// The page of an area's first screen: no transition (the rail switches).
Page<void> _flat(GoRouterState state, Widget child) =>
    NoTransitionPage<void>(key: state.pageKey, child: child);

/// The desktop layout's router (L2a): the phone's paths ([Routes]), placed
/// in the desktop shell instead of the bottom navigation. Each area's first
/// page is a top-level route of the shell (a rail click replaces it); the
/// pages under it (a story, a watch, Settings → Connection log) are nested,
/// so their back arrow leads to the area's page. Chats is a shell of its
/// own: the list column stays while the chat in the content changes.
/// More, Mirroring and Share do not exist here and go elsewhere.
GoRouter buildDesktopRouter({
  required ValueListenable<SessionState> session,
  String initialLocation = Routes.splash,
}) {
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'desktop.root');
  final shellKey = GlobalKey<NavigatorState>(debugLabel: 'desktop.shell');
  final chatsKey = GlobalKey<NavigatorState>(debugLabel: 'desktop.chats');

  Widget morePage(MorePage page, GoRouterState state) => switch (page) {
    MorePage.settings => const SettingsScreen(),
    MorePage.archived => const ArchivedChatsScreen(),
    MorePage.system => const SystemScreen(),
    MorePage.schedules => const SchedulesScreen(),
    MorePage.observability => const ObservabilityScreen(),
    MorePage.watches => const WatchesScreen(),
    MorePage.news => NewsScreen(
      weekly: state.uri.queryParameters['view'] == 'weekly',
    ),
    MorePage.clipboard => const ClipboardScreen(),
    MorePage.about => const PersonaScreen(),
    // phone only: the router sends it to the Dashboard
    MorePage.mirroring => const DashboardScreen(),
  };

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
      ShellRoute(
        navigatorKey: shellKey,
        pageBuilder: (context, state, child) => NoTransitionPage<void>(
          key: state.pageKey,
          child: DesktopShell(location: state.uri.toString(), child: child),
        ),
        routes: [
          // before the Chats shell: '/chats/approvals' is an area of its own
          GoRoute(
            path: Routes.approvals,
            pageBuilder: (_, state) => _flat(state, const ApprovalsScreen()),
          ),
          ShellRoute(
            navigatorKey: chatsKey,
            pageBuilder: (context, state, child) => NoTransitionPage<void>(
              key: state.pageKey,
              child: ChatsArea(location: state.uri.toString(), content: child),
            ),
            routes: [
              GoRoute(
                path: Routes.chats,
                pageBuilder: (_, state) =>
                    _flat(state, const ChatsPlaceholder()),
              ),
              GoRoute(
                path: Routes.newChat,
                pageBuilder: (_, state) {
                  final kind = switch (state.uri.queryParameters['kind']) {
                    'agent' => ChatKind.agent,
                    'general' => ChatKind.general,
                    _ => null,
                  };
                  return _flat(
                    state,
                    ChatScreen(
                      key: ValueKey('chat.new.${kind?.name}'),
                      conversationId: null,
                      kind: kind,
                      firstClientMsgId: switch (state.extra) {
                        final String id => id,
                        _ => null,
                      },
                      draft: switch (state.extra) {
                        final NewChatDraft d => d,
                        _ => null,
                      },
                    ),
                  );
                },
              ),
              GoRoute(
                path: '${Routes.chats}/c/:id',
                pageBuilder: (_, state) {
                  final id = state.pathParameters['id']!;
                  return _flat(
                    state,
                    ChatScreen(key: ValueKey('chat.c.$id'), conversationId: id),
                  );
                },
              ),
              GoRoute(
                path: '${Routes.chats}/g/:id',
                pageBuilder: (_, state) {
                  final id = state.pathParameters['id']!;
                  return _flat(
                    state,
                    GeneralChatScreen(key: ValueKey('chat.g.$id'), chatId: id),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: Routes.dashboard,
            pageBuilder: (_, state) => _flat(state, const DashboardScreen()),
          ),
          GoRoute(
            path: Routes.terminal,
            pageBuilder: (_, state) => _flat(state, const TerminalScreen()),
          ),
          GoRoute(
            path: Routes.files,
            pageBuilder: (_, state) => _flat(state, const FilesScreen()),
            routes: [
              GoRoute(
                path: 'preview',
                redirect: (_, state) =>
                    previewArgsOf(state.extra) == null ? Routes.files : null,
                builder: (_, state) =>
                    FilePreviewScreen(args: previewArgsOf(state.extra)!),
              ),
              GoRoute(path: 'trash', builder: (_, _) => const TrashScreen()),
            ],
          ),
          for (final page in MorePage.values)
            if (page == MorePage.mirroring)
              GoRoute(path: page.route, redirect: (_, _) => Routes.dashboard)
            else
              GoRoute(
                path: page.route,
                pageBuilder: (_, state) => _flat(state, morePage(page, state)),
                routes: [
                  if (page == MorePage.settings) ...[
                    GoRoute(
                      path: 'log',
                      builder: (_, _) => const ConnectionLogScreen(),
                    ),
                    GoRoute(
                      path: 'terminal',
                      builder: (_, _) => const TerminalSettingsScreen(),
                    ),
                    GoRoute(
                      path: 'general',
                      builder: (_, _) => const GeneralSettingsScreen(),
                    ),
                  ],
                  if (page == MorePage.news) ...[
                    GoRoute(
                      path: 'story/:id',
                      builder: (_, state) => NewsStoryScreen(
                        id: int.parse(state.pathParameters['id']!),
                      ),
                    ),
                    GoRoute(
                      path: 'settings',
                      builder: (_, _) => const NewsSettingsScreen(),
                    ),
                    GoRoute(
                      path: 'feed/:id',
                      builder: (_, state) =>
                          NewsFeedScreen(id: state.pathParameters['id']!),
                    ),
                  ],
                  if (page == MorePage.watches)
                    GoRoute(
                      path: ':slug',
                      builder: (_, state) => WatchDetailScreen(
                        slug: state.pathParameters['slug']!,
                      ),
                    ),
                  if (page == MorePage.schedules) ...[
                    GoRoute(
                      path: 'new',
                      builder: (_, _) => const ScheduleEditorScreen(),
                    ),
                    GoRoute(
                      path: 'edit/:id',
                      builder: (_, state) => ScheduleEditorScreen(
                        scheduleId: state.pathParameters['id'],
                      ),
                    ),
                  ],
                ],
              ),
          // after the pages under it: More itself is the phone's
          GoRoute(path: Routes.more, redirect: (_, _) => Routes.dashboard),
          GoRoute(
            path: Routes.share,
            redirect: (_, _) => Routes.chats,
            routes: [GoRoute(path: 'save', redirect: (_, _) => Routes.chats)],
          ),
        ],
      ),
    ],
  );
}

/// The desktop layout's router, built once and kept (its places survive a
/// trip through the phone layout).
final desktopRouterProvider = Provider<GoRouter>((ref) {
  final session = ValueNotifier<SessionState>(ref.read(sessionProvider));
  ref.listen(sessionProvider, (_, next) => session.value = next);
  final router = buildDesktopRouter(session: session);
  ref.onDispose(() {
    router.dispose();
    session.dispose();
  });
  return router;
});
