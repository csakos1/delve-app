import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ui/desktop/chats_area.dart';
import '../ui/desktop/desktop_shell.dart';
import '../ui/desktop/news_area.dart';
import '../ui/desktop/schedules_area.dart';
import '../ui/desktop/settings_area.dart';
import '../ui/desktop/watches_area.dart';
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
  final newsKey = GlobalKey<NavigatorState>(debugLabel: 'desktop.news');
  final newsSettingsKey = GlobalKey<NavigatorState>(
    debugLabel: 'desktop.newsSettings',
  );
  final watchesKey = GlobalKey<NavigatorState>(debugLabel: 'desktop.watches');
  final schedulesKey = GlobalKey<NavigatorState>(
    debugLabel: 'desktop.schedules',
  );
  final settingsKey = GlobalKey<NavigatorState>(debugLabel: 'desktop.settings');

  Widget morePage(MorePage page, GoRouterState state) => switch (page) {
    MorePage.settings => const SettingsScreen(),
    MorePage.archived => const ArchivedChatsScreen(),
    MorePage.system => const SystemScreen(),
    // a shell of its own (SchedulesArea, L2c2b)
    MorePage.schedules => const SchedulesPlaceholder(),
    MorePage.observability => const ObservabilityScreen(),
    // a shell of its own (WatchesArea, L2c2b)
    MorePage.watches => const WatchesPlaceholder(),
    // a shell of its own (NewsArea, L2c2)
    MorePage.news => const NewsPlaceholder(),
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
          // News settings: the sections in the list column (L2c2)
          ShellRoute(
            navigatorKey: newsSettingsKey,
            pageBuilder: (context, state, child) => NoTransitionPage<void>(
              key: state.pageKey,
              child: NewsSettingsArea(
                location: state.uri.toString(),
                content: child,
              ),
            ),
            routes: [
              GoRoute(
                path: Routes.newsSettings,
                pageBuilder: (_, state) => _flat(
                  state,
                  NewsSettingsScreen(
                    section: state.uri.queryParameters['section'],
                  ),
                ),
              ),
              GoRoute(
                path: '${Routes.news}/feed/:id',
                pageBuilder: (_, state) => _flat(
                  state,
                  NewsFeedScreen(id: state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          // News: the list stays while the story in the content changes
          ShellRoute(
            navigatorKey: newsKey,
            pageBuilder: (context, state, child) => NoTransitionPage<void>(
              key: state.pageKey,
              child: NewsArea(location: state.uri.toString(), content: child),
            ),
            routes: [
              GoRoute(
                path: Routes.news,
                pageBuilder: (_, state) =>
                    _flat(state, const NewsPlaceholder()),
              ),
              GoRoute(
                path: '${Routes.news}/story/:id',
                pageBuilder: (_, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return _flat(
                    state,
                    NewsStoryScreen(key: ValueKey('news.story.$id'), id: id),
                  );
                },
              ),
            ],
          ),
          // Watches: the list stays while the watch in the content changes
          ShellRoute(
            navigatorKey: watchesKey,
            pageBuilder: (context, state, child) => NoTransitionPage<void>(
              key: state.pageKey,
              child: WatchesArea(
                location: state.uri.toString(),
                content: child,
              ),
            ),
            routes: [
              GoRoute(
                path: Routes.watches,
                pageBuilder: (_, state) =>
                    _flat(state, const WatchesPlaceholder()),
              ),
              GoRoute(
                path: '${Routes.watches}/:slug',
                pageBuilder: (_, state) {
                  final slug = state.pathParameters['slug']!;
                  return _flat(
                    state,
                    WatchDetailScreen(
                      key: ValueKey('watch.$slug'),
                      slug: slug,
                      hit: int.tryParse(state.uri.queryParameters['hit'] ?? ''),
                    ),
                  );
                },
              ),
            ],
          ),
          // Schedules: the list stays; the page or the editor in the content
          ShellRoute(
            navigatorKey: schedulesKey,
            pageBuilder: (context, state, child) => NoTransitionPage<void>(
              key: state.pageKey,
              child: SchedulesArea(
                location: state.uri.toString(),
                content: child,
              ),
            ),
            routes: [
              GoRoute(
                path: Routes.schedules,
                pageBuilder: (_, state) =>
                    _flat(state, const SchedulesPlaceholder()),
              ),
              // before ':id': 'new' and 'edit' are not schedules
              GoRoute(
                path: Routes.newSchedule,
                pageBuilder: (_, state) => _flat(
                  state,
                  const ScheduleEditorScreen(key: ValueKey('schedule.new')),
                ),
              ),
              GoRoute(
                path: '${Routes.schedules}/edit/:id',
                pageBuilder: (_, state) {
                  final id = state.pathParameters['id']!;
                  return _flat(
                    state,
                    ScheduleEditorScreen(
                      key: ValueKey('schedule.edit.$id'),
                      scheduleId: id,
                    ),
                  );
                },
              ),
              GoRoute(
                path: '${Routes.schedules}/:id',
                pageBuilder: (_, state) {
                  final id = state.pathParameters['id']!;
                  return _flat(
                    state,
                    SchedulePage(key: ValueKey('schedule.page.$id'), id: id),
                  );
                },
              ),
            ],
          ),
          // Settings: the sections stay; a section or a sub-page in the content
          ShellRoute(
            navigatorKey: settingsKey,
            pageBuilder: (context, state, child) => NoTransitionPage<void>(
              key: state.pageKey,
              child: SettingsArea(
                location: state.uri.toString(),
                content: child,
              ),
            ),
            routes: [
              GoRoute(
                path: Routes.settings,
                pageBuilder: (_, state) => _flat(
                  state,
                  SettingsScreen(section: state.uri.queryParameters['section']),
                ),
              ),
              GoRoute(
                path: Routes.connectionLog,
                pageBuilder: (_, state) =>
                    _flat(state, const ConnectionLogScreen()),
              ),
              GoRoute(
                path: Routes.terminalSettings,
                pageBuilder: (_, state) =>
                    _flat(state, const TerminalSettingsScreen()),
              ),
              GoRoute(
                path: Routes.generalSettings,
                pageBuilder: (_, state) =>
                    _flat(state, const GeneralSettingsScreen()),
              ),
            ],
          ),
          for (final page in MorePage.values)
            if (page == MorePage.mirroring)
              GoRoute(path: page.route, redirect: (_, _) => Routes.dashboard)
            else if (page == MorePage.news ||
                page == MorePage.watches ||
                page == MorePage.schedules ||
                page == MorePage.settings)
              ...const <RouteBase>[]
            else
              GoRoute(
                path: page.route,
                pageBuilder: (_, state) => _flat(state, morePage(page, state)),
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
