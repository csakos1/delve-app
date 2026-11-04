import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:delve/terminal/phone_key.dart';
import 'package:delve/terminal/secrets.dart';
import 'package:delve/terminal/ssh_link.dart';
import 'package:delve/terminal/terminal_connection.dart';
import 'package:delve/terminal/terminal_lock.dart';

/// A desktop host key for tests (made up).
const testHostKeyType = 'ssh-ed25519';
const testHostKey = 'SHA256:lNXKPGqfbrXcM78QpsVLDmbXDclaa7Sgp9g7y1/4n0g';
const otherHostKey = 'SHA256:AAAAbbbbCCCCddddEEEEffffGGGGhhhhIIIIjjjjKKK';

/// The terminal's plugins in tests: storage, SSH, biometrics, timings.
class TerminalFakes {
  TerminalFakes({
    MemorySecretStore? store,
    FakeSshDialer? dialer,
    FakeBiometrics? biometrics,
    this.timing = fastTerminalTiming,
  }) : store = store ?? MemorySecretStore(),
       dialer = dialer ?? FakeSshDialer(),
       biometrics = biometrics ?? FakeBiometrics();

  final MemorySecretStore store;
  final FakeSshDialer dialer;
  final FakeBiometrics biometrics;
  final TerminalTiming timing;

  /// Network changes (Wi-Fi, airplane mode); lives as long as the test.
  // ignore: close_sinks
  final network = StreamController<void>.broadcast();

  /// Setup done before the app starts: settings saved as verified and the
  /// desktop's key pinned.
  Future<void> setUpDone({String host = 'archlinux.example.ts.net'}) async {
    final secrets = TerminalSecrets(store);
    await secrets.saveConfig(TerminalConfig(host: host, verified: true));
    await secrets.pin(
      '$host:$kTerminalPort',
      PinnedHostKey(
        type: testHostKeyType,
        fingerprint: testHostKey,
        trustedAt: DateTime.utc(2026, 11, 3),
      ),
    );
  }
}

const fastTerminalTiming = TerminalTiming(
  backoff: [
    Duration(milliseconds: 20),
    Duration(milliseconds: 40),
    Duration(milliseconds: 80),
  ],
  resizeSettle: Duration(milliseconds: 30),
  staleAfter: Duration(milliseconds: 200),
  probeEvery: Duration(milliseconds: 300),
  probeTimeout: Duration(milliseconds: 60),
  echoWait: Duration(milliseconds: 50),
);

/// Opens [FakeSshLink]s; the host key and failures are set per test.
class FakeSshDialer implements SshDialer {
  FakeSshDialer({this.hostKey = (testHostKeyType, testHostKey)});

  /// What the desktop shows; null = never asks (no verify call).
  (String, String)? hostKey;

  /// Consumed one per [open]: a failure to throw, or null for success.
  final List<SshFailure?> failures = [];

  /// While set, [open] waits for it after the host key check.
  Completer<void>? gate;

  /// Whether new links answer probes.
  bool linksAlive = true;

  final List<SshTarget> opens = [];
  final List<FakeSshLink> links = [];
  final List<(int, int)> openSizes = [];

  FakeSshLink get last => links.last;

  @override
  Future<SshLink> open(
    SshTarget target, {
    required PhoneKey key,
    required HostKeyCheck verify,
    required int columns,
    required int rows,
  }) async {
    opens.add(target);
    openSizes.add((columns, rows));
    final hk = hostKey;
    if (hk != null && !await verify(hk.$1, hk.$2)) {
      throw const SshHostKeyRejected('Hostkey verification failed');
    }
    final g = gate;
    if (g != null) await g.future;
    final failure = failures.isEmpty ? null : failures.removeAt(0);
    if (failure != null) throw failure;
    final link = FakeSshLink()..alive = linksAlive;
    links.add(link);
    return link;
  }
}

/// One live session: what was written and resized, and how it ends.
class FakeSshLink implements SshLink {
  final _output = StreamController<Uint8List>();
  final _done = Completer<SshEnd>();
  final List<String> writes = [];
  final List<(int, int)> resizes = [];
  bool closed = false;
  bool aborted = false;

  /// Whether the desktop still answers (false: airplane mode – writes go
  /// nowhere, nothing comes back, the socket does not end by itself).
  bool alive = true;

  /// Whether the desktop echoes what is written (tmux does).
  bool echo = false;

  int probes = 0;

  /// How long an alive desktop takes to answer a probe.
  Duration answerAfter = Duration.zero;

  /// Bytes from the desktop.
  void send(String text) => _output.add(Uint8List.fromList(utf8.encode(text)));

  /// The connection or the session goes away.
  void end(SshEnd how) {
    if (!_done.isCompleted) _done.complete(how);
  }

  String get written => writes.join();

  @override
  Stream<Uint8List> get output => _output.stream;

  @override
  void write(Uint8List data) {
    if (!alive) {
      lost.add(utf8.decode(data));
      return;
    }
    writes.add(utf8.decode(data));
    if (echo) _output.add(data);
  }

  /// Written while the desktop did not answer (would arrive late, if ever).
  final List<String> lost = [];

  @override
  Future<bool> probe(Duration timeout) async {
    probes++;
    if (alive) {
      if (answerAfter > Duration.zero) await Future<void>.delayed(answerAfter);
      return true;
    }
    await Future<void>.delayed(timeout);
    return false;
  }

  @override
  void abort() {
    aborted = true;
    closed = true;
    end(SshEnd.connectionLost);
    unawaited(_output.close());
  }

  @override
  void resize(int columns, int rows) => resizes.add((columns, rows));

  @override
  Future<SshEnd> get done => _done.future;

  @override
  Future<void> close() async {
    closed = true;
    end(SshEnd.connectionLost);
    await _output.close();
  }
}

class FakeBiometrics implements Biometrics {
  FakeBiometrics([this.result = UnlockResult.ok]);

  UnlockResult result;
  int calls = 0;

  @override
  Future<UnlockOutcome> unlock(String reason) async {
    calls++;
    return UnlockOutcome(
      result,
      result == UnlockResult.failed ? 'lockout' : null,
    );
  }
}
