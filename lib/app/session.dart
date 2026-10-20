import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../api/api_error.dart';
import '../api/models/models.dart';
import '../api/protocol.dart';
import '../api/rest_client.dart';
import '../data/credentials.dart';
import 'providers.dart';

// ---------------------------------------------------------------------------
// injectable pieces (tests override these)

final credentialStoreProvider = Provider<CredentialStore>(
  (ref) => SecureCredentialStore(),
);

/// null = dio's default HTTP adapter; tests pass a fake server.
final httpAdapterProvider = Provider<HttpClientAdapter?>((ref) => null);

class AppInfo {
  const AppInfo(this.version, this.build);
  final String version;
  final String build;

  @override
  String toString() => build.isEmpty ? version : '$version ($build)';
}

final appInfoProvider = FutureProvider<AppInfo>((ref) async {
  final p = await PackageInfo.fromPlatform();
  return AppInfo(p.version, p.buildNumber);
});

/// Device name sent when pairing (decision 171).
const String kDeviceName = 'pixel';

// ---------------------------------------------------------------------------
// session state

sealed class SessionState {
  const SessionState();
  Credentials? get credentials => null;
}

final class SessionLoading extends SessionState {
  const SessionLoading();
}

/// Why the app is back on the pairing screen (shown as a note there).
enum UnpairReason {
  /// The user unpaired and the server revoked the token.
  unpaired,

  /// The user unpaired but the server could not be told.
  unpairedLocally,

  /// The server answered 401: the token was revoked elsewhere.
  revoked,
}

final class SessionUnpaired extends SessionState {
  const SessionUnpaired([this.reason]);
  final UnpairReason? reason;
}

/// Paired. [meta] is null until the server has answered once (the app works
/// offline from the local database meanwhile).
final class SessionPaired extends SessionState {
  const SessionPaired(this.credentials, {this.meta});
  @override
  final Credentials credentials;
  final ServerMeta? meta;
}

/// The server's contract is older than [kMinApiRevision]: blocking screen.
final class SessionServerTooOld extends SessionState {
  const SessionServerTooOld(this.credentials, this.meta);
  @override
  final Credentials credentials;
  final ServerMeta meta;
}

class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() {
    Future.microtask(_load);
    return const SessionLoading();
  }

  CredentialStore get _store => ref.read(credentialStoreProvider);

  /// A short-lived client for the session's own calls (no 401 callback:
  /// the session handles the outcome itself).
  DelveApi _api(Uri server, {String? token}) => DelveApi(
    server: server,
    token: token,
    adapter: ref.read(httpAdapterProvider),
  );

  Future<void> _load() async {
    final creds = await _store.read();
    if (creds == null) {
      state = const SessionUnpaired();
      return;
    }
    state = SessionPaired(creds);
    unawaited(checkServer());
  }

  /// Reads `/meta` and applies the revision check. Returns the error when the
  /// server could not be asked (the state is left as it was).
  Future<ApiError?> checkServer() async {
    final creds = state.credentials;
    if (creds == null) return null;
    final api = _api(creds.server);
    try {
      final meta = await api.meta();
      if (!ref.mounted || state.credentials != creds) return null;
      state = meta.apiRevision < kMinApiRevision
          ? SessionServerTooOld(creds, meta)
          : SessionPaired(creds, meta: meta);
      return null;
    } on ApiError catch (e) {
      return e;
    } finally {
      api.close();
    }
  }

  /// Called by the pairing screen once the server has issued a token.
  Future<void> completePairing(Credentials creds, ServerMeta meta) async {
    await _store.write(creds);
    state = meta.apiRevision < kMinApiRevision
        ? SessionServerTooOld(creds, meta)
        : SessionPaired(creds, meta: meta);
  }

  /// Revokes the token on the server (best effort), then forgets everything
  /// local. Returns whether the server confirmed.
  Future<bool> unpair() async {
    final creds = state.credentials;
    if (creds == null) return false;
    var confirmed = false;
    final api = _api(creds.server, token: creds.token);
    try {
      await api.unpair();
      confirmed = true;
    } on ApiUnauthorized {
      confirmed = true; // already revoked
    } on ApiError {
      confirmed = false;
    } finally {
      api.close();
    }
    await _forget(
      confirmed ? UnpairReason.unpaired : UnpairReason.unpairedLocally,
    );
    return confirmed;
  }

  /// Any authenticated call that got 401 lands here.
  void handleUnauthorized() {
    if (state.credentials == null) return;
    unawaited(_forget(UnpairReason.revoked));
  }

  Future<void> _forget(UnpairReason reason) async {
    state = SessionUnpaired(reason); // first: stop using the token at once
    await _store.clear();
    await ref.read(databaseProvider).wipe();
  }
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);

/// Authenticated client for the paired server; null when not paired.
final apiProvider = Provider<DelveApi?>((ref) {
  final creds = ref.watch(sessionProvider.select((s) => s.credentials));
  if (creds == null) return null;
  final api = DelveApi(
    server: creds.server,
    token: creds.token,
    adapter: ref.watch(httpAdapterProvider),
    onUnauthorized: () =>
        ref.read(sessionProvider.notifier).handleUnauthorized(),
  );
  ref.onDispose(api.close);
  return api;
});

DelveApi _requireApi(Ref ref) {
  final api = ref.watch(apiProvider);
  if (api == null) throw const ApiUnauthorized();
  return api;
}

/// `GET /status` (Settings: thinking route, Hermes). Refresh = invalidate.
final serverStatusProvider = FutureProvider.autoDispose<ServerStatus>(
  (ref) => _requireApi(ref).status(),
);

/// `GET /devices/me` (Settings: this device).
final deviceInfoProvider = FutureProvider.autoDispose<DeviceInfo>(
  (ref) => _requireApi(ref).deviceMe(),
);
