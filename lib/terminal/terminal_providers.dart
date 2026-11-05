import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/session.dart';
import 'secrets.dart';
import 'ssh_link.dart';
import 'terminal_connection.dart';
import 'terminal_keep_alive.dart';
import 'terminal_lock.dart';
import 'terminal_service.dart';
import 'terminal_trace.dart';

/// Where the terminal keeps its key and settings (tests: in memory).
final terminalStoreProvider = Provider<SecretStore>(
  (ref) => SecureSecretStore(),
);

/// Opens SSH connections (tests: a fake).
final sshDialerProvider = Provider<SshDialer>((ref) => const Dartssh2Dialer());

/// The lock screen's fingerprint check (tests: a fake).
final biometricsProvider = Provider<Biometrics>((ref) => LocalAuthBiometrics());

/// "Keep connected in background": the Android service (tests: a fake).
final terminalKeepAliveProvider = Provider<TerminalKeepAlive>(
  (ref) => const ChannelKeepAlive(),
);

final terminalTimingProvider = Provider<TerminalTiming>(
  (ref) => const TerminalTiming(),
);

/// The phone's network changes: a live connection is checked at once, a
/// waiting reconnect tries at once (tests: a controller). The events are
/// connectivity_plus's lists (wifi, mobile, vpn, none) – the trace shows
/// them.
final terminalNetworkProvider = Provider<Stream<Object?>>(
  (ref) => Connectivity().onConnectivityChanged,
);

/// A network event for the trace: `wifi+vpn`, `none`.
String networkText(Object? event) => switch (event) {
  final List<ConnectivityResult> list => list.map((r) => r.name).join('+'),
  null => '-',
  _ => '$event',
};

/// The app's one terminal. It does not follow later session changes: the
/// connection must survive them (the paired host is only the default for a
/// new setup).
final terminalServiceProvider = Provider<TerminalService>((ref) {
  final session = ref.read(sessionProvider);
  final service = TerminalService(
    secrets: TerminalSecrets(ref.watch(terminalStoreProvider)),
    dialer: ref.watch(sshDialerProvider),
    biometrics: ref.watch(biometricsProvider),
    keepAlive: ref.watch(terminalKeepAliveProvider),
    timing: ref.watch(terminalTimingProvider),
    defaultHost: session.credentials?.server.host ?? '',
  );
  final network = ref.read(terminalNetworkProvider).listen((event) {
    terminalTrace.add('net', networkText(event));
    service.networkChanged();
  }, onError: (Object _) {});
  ref.onDispose(() {
    unawaited(network.cancel());
    service.dispose();
  });
  return service;
});
