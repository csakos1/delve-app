import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/session.dart';
import '../data/db/database.dart';
import 'connection_status.dart';
import 'live_runs.dart';
import 'sync_engine.dart';
import 'transport.dart';

/// Widget tests turn the socket off (they talk to the fake REST server only).
final syncEnabledProvider = Provider<bool>((ref) => true);

final wsTransportProvider = Provider<WsTransport>(
  (ref) => const IoWsTransport(),
);

/// Network changes (a reason to retry at once instead of waiting out the
/// backoff).
final networkChangesProvider = Provider<Stream<void>>(
  (ref) => Connectivity().onConnectivityChanged.map((_) {}),
);

/// The WebSocket client of the paired server; null when not paired (or the
/// server is too old, or sync is off). Recreated when the pairing changes.
final syncEngineProvider = Provider<SyncEngine?>((ref) {
  if (!ref.watch(syncEnabledProvider)) return null;
  final creds = ref.watch(
    sessionProvider.select((s) => s is SessionPaired ? s.credentials : null),
  );
  final api = ref.watch(apiProvider);
  if (creds == null || api == null) return null;
  final engine = SyncEngine(
    db: ref.watch(databaseProvider),
    credentials: creds,
    api: api,
    transport: ref.watch(wsTransportProvider),
    networkChanges: ref.watch(networkChangesProvider),
    onUnauthorized: () {
      if (ref.mounted) {
        ref.read(sessionProvider.notifier).handleUnauthorized();
      }
    },
    onLiveRuns: (runs) {
      if (ref.mounted) ref.read(liveRunsProvider.notifier).set(runs);
    },
  );
  ref.onDispose(() => unawaited(engine.dispose()));
  unawaited(engine.start());
  return engine;
});

/// Connection state for banners and Settings.
final connectionStatusProvider = StreamProvider<ConnectionStatus>((ref) async* {
  final engine = ref.watch(syncEngineProvider);
  if (engine == null) {
    yield ConnectionStatus.initial;
    return;
  }
  yield engine.status;
  yield* engine.statusChanges;
});

/// Streaming runs by conversation id (the chat overlays them).
class LiveRunsNotifier extends Notifier<Map<String, LiveRun>> {
  @override
  Map<String, LiveRun> build() {
    ref.watch(syncEngineProvider); // a new engine (or none) starts empty
    return const {};
  }

  void set(Map<String, LiveRun> runs) => state = runs;
}

final liveRunsProvider =
    NotifierProvider<LiveRunsNotifier, Map<String, LiveRun>>(
      LiveRunsNotifier.new,
    );

/// Settings → Connection log, newest first.
final connectionLogProvider = StreamProvider<List<ConnectionLogRow>>(
  (ref) => ref.watch(databaseProvider).watchConnectionLog(),
);
