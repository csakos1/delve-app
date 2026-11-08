import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../files/transfers_host.dart';
import '../l10n/app_localizations.dart';
import '../push/push_host.dart';
import '../share/share_host.dart';
import '../sync/sync_lifecycle.dart';
import '../theme/delve_theme.dart';
import 'router.dart';

class DelveApp extends ConsumerWidget {
  const DelveApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = buildDelveTheme();
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
