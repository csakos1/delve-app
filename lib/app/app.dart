import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../files/transfers_host.dart';
import '../l10n/app_localizations.dart';
import '../mirror/mirror_controller.dart';
import '../push/push_host.dart';
import '../share/share_host.dart';
import '../sync/sync_lifecycle.dart';
import '../theme/delve_theme.dart';
import 'desktop_router.dart';
import 'layout.dart';
import 'router.dart';

/// The app: the phone layout, or on a computer with a window of 720 dp and
/// more the desktop layout (L2) with its own router and denser theme. A
/// resize across 720 dp swaps the two and keeps the place.
class DelveApp extends ConsumerStatefulWidget {
  const DelveApp({super.key});

  @override
  ConsumerState<DelveApp> createState() => _DelveAppState();
}

class _DelveAppState extends ConsumerState<DelveApp>
    with WidgetsBindingObserver {
  final ThemeData _theme = buildDelveTheme();
  late final ThemeData _desktopTheme = delveDesktopTheme(_theme);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (mounted) ref.read(desktopLayoutProvider.notifier).update(windowWidth());
  }

  /// The other layout's router takes over where this one was.
  void _swap(bool desktop) {
    final from = ref.read(
      desktop ? phoneRouterProvider : desktopRouterProvider,
    );
    final to = ref.read(desktop ? desktopRouterProvider : phoneRouterProvider);
    final at = from.routerDelegate.currentConfiguration.uri.toString();
    to.go(desktop ? desktopLocation(at) : phoneLocation(at));
  }

  @override
  Widget build(BuildContext context) {
    // notification mirroring follows the session (an unpair wipes the Android
    // side's copy of the token) whether or not its page is ever opened
    ref.listen(mirrorProvider, (_, _) {});
    ref.listen<bool>(desktopLayoutProvider, (was, now) {
      if (was != null && was != now) _swap(now);
    });
    final desktop = ref.watch(desktopLayoutProvider);
    final theme = desktop ? _desktopTheme : _theme;
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.dark,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
      onNavigationNotification: delveHandlesBack,
      builder: (context, child) => SyncLifecycle(
        child: PushHost(
          child: ShareHost(
            child: TransfersHost(child: child ?? const SizedBox()),
          ),
        ),
      ),
    );
  }
}

/// Android (predictive back) asks after every navigator change whether the
/// app takes the back gesture. A page pushed over the tabs and popped again
/// (a file preview) reports "no" from the root navigator although a tab
/// below still has a [PopScope] waiting (Files: the folder before), and the
/// system then closes the app. Delve always takes back: the router pops what
/// it can, and at the root `SystemNavigator.pop` closes the app as before.
bool delveHandlesBack(NavigationNotification notification) {
  switch (WidgetsBinding.instance.lifecycleState) {
    case null || AppLifecycleState.detached:
      break;
    case _:
      unawaited(
        SystemNavigator.setFrameworkHandlesBack(true).catchError((Object _) {}),
      );
  }
  return true;
}
