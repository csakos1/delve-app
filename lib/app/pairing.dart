import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_error.dart';
import '../api/rest_client.dart';
import '../data/credentials.dart';
import 'pairing_input.dart';
import 'session.dart';

/// What went wrong with the last attempt (at most one is set).
sealed class PairingProblem {
  const PairingProblem();
}

final class PairingBadUrl extends PairingProblem {
  const PairingBadUrl(this.problem);
  final ServerUrlProblem problem;
}

final class PairingBadCode extends PairingProblem {
  const PairingBadCode();
}

/// 429 from the server: no attempt for [wait].
final class PairingRateLimited extends PairingProblem {
  const PairingRateLimited(this.wait);
  final Duration wait;
}

final class PairingUnreachable extends PairingProblem {
  const PairingUnreachable();
}

final class PairingServerError extends PairingProblem {
  const PairingServerError(this.status);
  final int status;
}

final class PairingNotDelve extends PairingProblem {
  const PairingNotDelve();
}

class PairingState {
  const PairingState({this.busy = false, this.problem});
  final bool busy;
  final PairingProblem? problem;
}

/// Pairing (decision 171): `GET /meta` as a reachability and server check,
/// then `POST /devices/register` with the code; the token goes to secure
/// storage and the session takes over.
class PairingController extends Notifier<PairingState> {
  @override
  PairingState build() => const PairingState();

  Future<void> submit(String urlText, String codeText) async {
    if (state.busy) return;
    final check = checkServerUrl(urlText);
    final ServerUrlOk url;
    switch (check) {
      case ServerUrlBad(:final problem):
        state = PairingState(problem: PairingBadUrl(problem));
        return;
      case final ServerUrlOk ok:
        url = ok;
    }
    final digits = pairingDigits(codeText);
    if (digits == null) {
      state = const PairingState(problem: PairingBadCode());
      return;
    }
    state = const PairingState(busy: true);

    AppInfo? app;
    try {
      app = await ref.read(appInfoProvider.future);
    } on Object {
      app = null; // the version is informational only
    }
    final api = DelveApi(
      server: url.origin,
      adapter: ref.read(httpAdapterProvider),
    );
    PairingProblem? problem;
    try {
      final meta = await api.meta();
      final device = await api.register(
        '${digits.substring(0, 4)}-${digits.substring(4)}',
        name: kDeviceName,
        appVersion: app?.version,
      );
      await ref
          .read(sessionProvider.notifier)
          .completePairing(
            Credentials(
              server: url.origin,
              token: device.token,
              deviceId: device.deviceId,
              deviceName: device.name,
              pairedAt: DateTime.now().toUtc(),
            ),
            meta,
          );
    } on ApiUnreachable {
      problem = const PairingUnreachable();
    } on ApiRateLimited catch (e) {
      problem = PairingRateLimited(e.retryAfter);
    } on ApiRequestError catch (e) {
      problem = switch (e.status) {
        400 || 422 => const PairingBadCode(),
        404 || 405 => const PairingNotDelve(),
        _ => PairingServerError(e.status),
      };
    } on ApiError {
      problem = const PairingNotDelve();
    } finally {
      api.close();
    }
    if (ref.mounted) state = PairingState(problem: problem);
  }

  /// The rate-limit wait is over (the screen counts it down).
  void clearRateLimit() {
    if (state.problem is PairingRateLimited) state = const PairingState();
  }
}

final pairingProvider =
    NotifierProvider.autoDispose<PairingController, PairingState>(
      PairingController.new,
    );
