import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ssh_link.dart';
import 'terminal_providers.dart';
import 'terminal_service.dart';

/// The most text (UTF-8 bytes) the phone sends. It travels inside the
/// command, as base64, and Linux gives one argument 128 KB (measured on the
/// desktop: 90 KB of text went through, 200 KB did not).
const kClipboardSendMax = 64 * 1024;

/// The most text (UTF-8 bytes) the phone takes from the desktop.
const kClipboardFetchMax = 256 * 1024;

/// What the commands' own exit codes mean ([_prelude], [fetchCommand]).
const _exitNoSession = 40;
const _exitNoTool = 41;
const _exitEmpty = 43;
const _exitNotText = 45;

/// Why a clipboard transfer did not happen.
enum ClipboardFailureKind {
  /// The terminal was never set up: there is no trusted connection.
  noSetup,

  /// This phone's clipboard has no text.
  phoneEmpty,

  /// More than [kClipboardSendMax] / [kClipboardFetchMax]; the detail is
  /// the limit in KB.
  tooLarge,

  /// No answer from the desktop (network, sshd, host key, timeout).
  unreachable,

  /// Nobody is logged in to the desktop's graphical session.
  noSession,

  /// wl-clipboard is not installed there.
  noTool,

  /// The desktop's clipboard is empty.
  desktopEmpty,

  /// The desktop's clipboard holds something else (an image, a file).
  notText,

  /// wl-copy or wl-paste failed otherwise.
  failed,
}

class ClipboardFailure implements Exception {
  const ClipboardFailure(this.kind, [this.detail = '']);

  final ClipboardFailureKind kind;

  /// The desktop's or the connection's words, when it had any.
  final String detail;

  @override
  String toString() => 'ClipboardFailure(${kind.name}, $detail)';
}

/// An SSH command gets `XDG_RUNTIME_DIR` from PAM but not the Wayland
/// session's name: the socket in the runtime directory tells it
/// (`wayland-1`; not its lock file or another program's `wayland-1-….sock`).
/// The login shell runs this (zsh on the desktop), so it stays plain POSIX.
const _session =
    r'export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"; '
    r'if [ -z "${WAYLAND_DISPLAY:-}" ]; then '
    r'WAYLAND_DISPLAY=$(ls "$XDG_RUNTIME_DIR" 2>/dev/null '
    r"| grep -E '^wayland-[0-9]+$' | head -n 1); "
    r'export WAYLAND_DISPLAY; fi; '
    r'[ -n "$WAYLAND_DISPLAY" ] || exit 40; '
    r'[ -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ] '
    r'|| [ -S "$WAYLAND_DISPLAY" ] || exit 40; ';

String _prelude(String tool) =>
    '${_session}command -v $tool >/dev/null 2>&1 || exit $_exitNoTool; ';

/// Puts [text] on the desktop's clipboard. wl-copy stays in the background
/// to serve the selection: with its output left on the channel the command
/// never ends (measured: 20 s, then the timeout), hence the redirect. The
/// type is named because wl-copy would guess one from the content.
String sendCommand(String text) =>
    '${_prelude('wl-copy')}'
    "printf %s '${base64.encode(utf8.encode(text))}' | base64 -d "
    '| wl-copy -t text/plain >/dev/null 2>&1';

/// Prints the desktop's clipboard when it offers text, at most [max] bytes
/// and one more (so too much shows). Without the look at the types wl-paste
/// would print an image's bytes with exit 0.
String fetchCommand({int max = kClipboardFetchMax}) =>
    '${_prelude('wl-paste')}'
    r't=$(wl-paste -l 2>&1) || { '
    r'case "$t" in *"Nothing is copied"*) exit 43 ;; esac; '
    r"""printf '%s\n' "$t" >&2; exit 44; }; """
    r"""printf '%s\n' "$t" | grep -q '^text/plain' || exit 45; """
    'wl-paste -n | head -c ${max + 1}';

/// The desktop's clipboard over the terminal's SSH connection (DA1): no
/// backend and no agent on the desktop in the path.
class DesktopClipboard {
  DesktopClipboard(this._terminal);

  final TerminalService _terminal;

  /// [text] to the desktop's clipboard.
  Future<void> send(String text) async {
    if (text.isEmpty) {
      throw const ClipboardFailure(ClipboardFailureKind.phoneEmpty);
    }
    if (utf8.encode(text).length > kClipboardSendMax) {
      throw const ClipboardFailure(
        ClipboardFailureKind.tooLarge,
        '${kClipboardSendMax ~/ 1024}',
      );
    }
    _check(await _run(sendCommand(text)));
  }

  /// The text on the desktop's clipboard.
  Future<String> fetch() async {
    final r = await _run(fetchCommand());
    _check(r);
    if (utf8.encode(r.output).length > kClipboardFetchMax) {
      throw const ClipboardFailure(
        ClipboardFailureKind.tooLarge,
        '${kClipboardFetchMax ~/ 1024}',
      );
    }
    if (r.output.isEmpty) {
      throw const ClipboardFailure(ClipboardFailureKind.desktopEmpty);
    }
    return r.output;
  }

  Future<SshRunResult> _run(String command) async {
    await _terminal.load();
    if (!_terminal.config.verified) {
      throw const ClipboardFailure(ClipboardFailureKind.noSetup);
    }
    try {
      return await _terminal.runOnDesktop(command);
    } on SshFailure catch (e) {
      throw ClipboardFailure(ClipboardFailureKind.unreachable, e.detail);
    } on TimeoutException {
      throw const ClipboardFailure(
        ClipboardFailureKind.unreachable,
        'timed out',
      );
    }
  }

  static void _check(SshRunResult r) {
    final kind = switch (r.exitCode) {
      null || 0 => null,
      _exitNoSession => ClipboardFailureKind.noSession,
      _exitNoTool => ClipboardFailureKind.noTool,
      _exitEmpty => ClipboardFailureKind.desktopEmpty,
      _exitNotText => ClipboardFailureKind.notText,
      _ => ClipboardFailureKind.failed,
    };
    if (kind == null) return;
    final said = r.error.split('\n').first.trim();
    throw ClipboardFailure(kind, said.isEmpty ? 'exit ${r.exitCode}' : said);
  }
}

final desktopClipboardProvider = Provider<DesktopClipboard>(
  (ref) => DesktopClipboard(ref.watch(terminalServiceProvider)),
);

enum ClipboardDirection { toDesktop, toPhone }

/// A transfer that went through. The text is kept in memory only (the
/// Clipboard page shows it).
class ClipboardTransfer {
  const ClipboardTransfer(this.direction, this.text, this.at);

  final ClipboardDirection direction;
  final String text;
  final DateTime at;
}

class ClipboardView {
  const ClipboardView({this.busy, this.last});

  /// The transfer under way.
  final ClipboardDirection? busy;
  final ClipboardTransfer? last;
}

/// The two transfers between this phone's clipboard and the desktop's.
/// Nothing moves by itself: each is one tap (the desktop's clipboard may
/// hold a password).
class ClipboardSync extends Notifier<ClipboardView> {
  @override
  ClipboardView build() => const ClipboardView();

  /// null: another transfer is under way. Throws [ClipboardFailure].
  Future<ClipboardTransfer?> run(ClipboardDirection direction) async {
    if (state.busy != null) return null;
    final before = state.last;
    state = ClipboardView(busy: direction, last: before);
    try {
      final desktop = ref.read(desktopClipboardProvider);
      final String text;
      if (direction == ClipboardDirection.toDesktop) {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        text = data?.text ?? '';
        await desktop.send(text);
      } else {
        text = await desktop.fetch();
        await Clipboard.setData(ClipboardData(text: text));
      }
      final done = ClipboardTransfer(direction, text, DateTime.now());
      state = ClipboardView(last: done);
      return done;
    } on Object {
      state = ClipboardView(last: before);
      rethrow;
    }
  }
}

final clipboardSyncProvider = NotifierProvider<ClipboardSync, ClipboardView>(
  ClipboardSync.new,
);
