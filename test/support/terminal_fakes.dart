import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:delve/terminal/phone_key.dart';
import 'package:delve/terminal/secrets.dart';
import 'package:delve/terminal/ssh_link.dart';
import 'package:delve/terminal/terminal_connection.dart';
import 'package:delve/terminal/terminal_keep_alive.dart';
import 'package:delve/terminal/terminal_lock.dart';

import 'files_fakes.dart';

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
    FakeKeepAlive? keepAlive,
    FakeFilesDialer? files,
    FakeDeviceFiles? device,
    FakePdfPages? pdf,
    this.timing = fastTerminalTiming,
  }) : store = store ?? MemorySecretStore(),
       dialer = dialer ?? FakeSshDialer(),
       biometrics = biometrics ?? FakeBiometrics(),
       keepAlive = keepAlive ?? FakeKeepAlive(),
       files = files ?? FakeFilesDialer(sampleFs),
       device = device ?? FakeDeviceFiles(),
       pdf = pdf ?? FakePdfPages();

  final MemorySecretStore store;
  final FakeSshDialer dialer;
  final FakeBiometrics biometrics;
  final FakeKeepAlive keepAlive;
  final TerminalTiming timing;

  /// The Files tab's desktop (F1) and the phone's Downloads.
  final FakeFilesDialer files;
  final FakeDeviceFiles device;

  /// The phone's PDF renderer (the preview).
  final FakePdfPages pdf;

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
  keepPrevious: Duration(milliseconds: 150),
  probeEvery: Duration(milliseconds: 300),
  probeTimeout: Duration(milliseconds: 60),
  echoWait: Duration(milliseconds: 50),
  backgroundProbeEvery: Duration(milliseconds: 600),
);

/// A session on the fake desktop's tmux.
class FakeSession {
  FakeSession(
    this.name, {
    this.attached = 0,
    this.windows = 1,
    this.app = false,
    this.status = 'on',
    this.created = 1793800000,
  });

  String name;
  int attached;
  int windows;
  bool app;
  String status;
  int created;
}

/// The desktop's tmux for exec commands: lists, renames and kills
/// [sessions], the way the real one answers (T3-0).
class FakeTmux {
  final List<FakeSession> sessions = [];

  /// Every command run, in order (link or own connection).
  final List<String> commands = [];

  /// The next commands fail with this stderr (exit 1).
  final List<String> failures = [];

  FakeSession? byName(String name) {
    for (final s in sessions) {
      if (s.name == name) return s;
    }
    return null;
  }

  /// The pane's cursor and history size that `display-message` tells
  /// (where the shell's cursor is in copy mode); null: not answered.
  (int, int, int)? cursor;

  static final _display = RegExp(r"display-message -p -t '(.*):' ");
  static final _rename = RegExp(r"rename-session -t '=(.*)' '(.*)'$");
  static final _kill = RegExp(r"kill-session -t '=(.*)'$");

  SshRunResult run(String command) {
    commands.add(command);
    if (failures.isNotEmpty) {
      return SshRunResult('', 1, error: failures.removeAt(0));
    }
    if (command.contains('list-sessions')) {
      return SshRunResult(
        [
          for (final s in sessions)
            '${s.attached}|${s.windows}|${s.created}|${s.app ? 1 : 0}|'
                '${s.status}|${s.name}\n',
        ].join(),
        0,
      );
    }
    if (cursor case final c? when _display.hasMatch(command)) {
      final name = _display.firstMatch(command)![1]!;
      return SshRunResult('${c.$1}|${c.$2}|${c.$3}|$name\n', 0);
    }
    if (_rename.firstMatch(command) case final m?) {
      final s = byName(m[1]!);
      if (s == null) {
        return SshRunResult('', 1, error: "can't find session: ${m[1]}");
      }
      s.name = m[2]!;
      return const SshRunResult('', 0);
    }
    if (_kill.firstMatch(command) case final m?) {
      final s = byName(m[1]!);
      if (s == null) {
        return SshRunResult('', 1, error: "can't find session: ${m[1]}");
      }
      sessions.remove(s);
      return const SshRunResult('', 0);
    }
    return const SshRunResult('', 127, error: 'unknown command');
  }
}

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

  /// The desktop's tmux (exec commands).
  final tmux = FakeTmux();

  /// Commands run over a connection of their own ([run]).
  final List<String> runs = [];

  /// Consumed one per [run]: a failure to throw, or null for success.
  final List<SshFailure?> runFailures = [];

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
    final link = FakeSshLink(tmux: tmux)..alive = linksAlive;
    links.add(link);
    return link;
  }

  @override
  Future<SshRunResult> run(
    SshTarget target, {
    required PhoneKey key,
    required HostKeyCheck verify,
    required String command,
    Duration timeout = kRunTimeout,
  }) async {
    runs.add(command);
    final hk = hostKey;
    if (hk != null && !await verify(hk.$1, hk.$2)) {
      throw const SshHostKeyRejected('Hostkey verification failed');
    }
    final failure = runFailures.isEmpty ? null : runFailures.removeAt(0);
    if (failure != null) throw failure;
    return tmux.run(command);
  }
}

/// One live session: what was written and resized, and how it ends.
class FakeSshLink implements SshLink {
  FakeSshLink({FakeTmux? tmux}) : tmux = tmux ?? FakeTmux();

  /// Answers [run] (the desktop's tmux).
  final FakeTmux tmux;

  /// Commands run over this connection.
  final List<String> runs = [];

  @override
  Future<SshRunResult> run(
    String command, {
    Duration timeout = kRunTimeout,
  }) async {
    runs.add(command);
    if (!alive) throw const SshUnreachable('timed out');
    return tmux.run(command);
  }

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

/// The keep-alive service (T4): records starts and stops.
class FakeKeepAlive implements TerminalKeepAlive {
  /// Whether a start is allowed (Android refuses one from the background).
  bool allow = true;
  bool exempt = false;

  /// The notification texts of the starts, in order.
  final starts = <String>[];
  int stops = 0;
  int exemptRequests = 0;

  /// Running now (the last call was a successful start).
  bool running = false;

  @override
  Future<bool> start(String text) async {
    if (!allow) return false;
    starts.add(text);
    running = true;
    return true;
  }

  @override
  Future<void> stop() async {
    stops++;
    running = false;
  }

  @override
  Future<bool> batteryExempt() async => exempt;

  @override
  Future<bool> requestBatteryExempt() async {
    exemptRequests++;
    return true;
  }
}
