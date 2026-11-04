import 'dart:math' as math;

import 'ssh_link.dart';
import 'terminal_connection.dart';
import 'terminal_wheel.dart';

/// Lines per wheel step in a session started on the desktop: tmux's own
/// copy-mode step (T3: such a session keeps tmux's defaults).
const kDesktopWheelStepLines = 5.0;

/// One terminal tab: a tmux session and its own SSH connection (T3).
class TerminalTab {
  TerminalTab({
    required this.id,
    required this.session,
    required this.app,
    required this.statusRows,
    required this.connection,
  });

  /// Stable while the app runs (widget keys); not saved.
  final int id;

  /// The tmux session's name (changes with a rename).
  String session;

  /// The app's own session ([SshTarget.app]); false: a desktop session,
  /// shown with its status line and tmux's 5-line wheel step.
  final bool app;

  /// tmux status lines at the bottom (0 in the app's sessions).
  final int statusRows;

  final TerminalConnection connection;

  SavedTab get saved =>
      SavedTab(session: session, app: app, statusRows: statusRows);
}

/// A tab as saved: the session and how to show it.
class SavedTab {
  const SavedTab({required this.session, this.app = true, this.statusRows = 0});

  factory SavedTab.fromJson(Map<String, Object?> j) => SavedTab(
    session: j['session']! as String,
    app: j['app'] != false,
    statusRows: (j['status'] as int?) ?? (j['app'] == false ? 1 : 0),
  );

  final String session;
  final bool app;
  final int statusRows;

  Map<String, Object?> toJson() => {
    'session': session,
    'app': app,
    'status': statusRows,
  };

  @override
  bool operator ==(Object other) =>
      other is SavedTab &&
      other.session == session &&
      other.app == app &&
      other.statusRows == statusRows;

  @override
  int get hashCode => Object.hash(session, app, statusRows);
}

/// The open tabs and the active one (-1: none).
class SavedTabs {
  const SavedTabs(this.tabs, this.active);

  factory SavedTabs.fromJson(Map<String, Object?> j) {
    final tabs = [
      for (final t in (j['tabs']! as List<Object?>))
        SavedTab.fromJson(t! as Map<String, Object?>),
    ];
    final active = (j['active'] as int?) ?? 0;
    return SavedTabs(
      tabs,
      tabs.isEmpty ? -1 : active.clamp(0, tabs.length - 1),
    );
  }

  /// Before T3 the terminal had one tab.
  static const first = SavedTabs([SavedTab(session: kFirstSession)], 0);

  final List<SavedTab> tabs;
  final int active;

  Map<String, Object?> toJson() => {
    'tabs': [for (final t in tabs) t.toJson()],
    'active': active,
  };
}

/// The tmux session of the first tab.
const kFirstSession = 'delve-1';

/// A session on the desktop (`tmux list-sessions`).
class TmuxSession {
  const TmuxSession({
    required this.name,
    required this.attached,
    required this.windows,
    required this.app,
    required this.statusRows,
    this.created,
  });

  final String name;

  /// Clients attached (the phone's tabs included).
  final int attached;
  final int windows;

  /// Marked as the app's (`@delve`): opened again as an app tab.
  final bool app;

  /// Its status lines (`status`: off 0, on 1, 2…5).
  final int statusRows;
  final DateTime? created;
}

/// The session list, one per line: the name last, after `|` (tmux turns a
/// tab and other control characters in its output into `_`, and `.` and
/// `:` in names too – T3-0).
const listSessionsCommand =
    'LANG=en_US.UTF-8 tmux -u list-sessions -F '
    "'#{session_attached}|#{session_windows}|#{session_created}|"
    "#{?@delve,1,0}|#{status}|#{session_name}' 2>/dev/null; true";

/// Parses [listSessionsCommand]'s output (no server: empty).
List<TmuxSession> parseSessions(String output) {
  final out = <TmuxSession>[];
  for (final line in output.split('\n')) {
    final l = line.trimRight();
    if (l.isEmpty) continue;
    final parts = l.split('|');
    if (parts.length < 6) continue;
    final name = parts.sublist(5).join('|');
    if (name.isEmpty) continue;
    final created = int.tryParse(parts[2]);
    out.add(
      TmuxSession(
        name: name,
        attached: int.tryParse(parts[0]) ?? 0,
        windows: int.tryParse(parts[1]) ?? 1,
        created: created == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(created * 1000),
        app: parts[3] == '1',
        statusRows: statusRowsOf(parts[4]),
      ),
    );
  }
  return out;
}

/// tmux's `status` option as rows.
int statusRowsOf(String status) => switch (status) {
  'off' => 0,
  'on' => 1,
  _ => int.tryParse(status)?.clamp(0, 5) ?? 1,
};

/// `delve-N` with the smallest N not in [taken].
String nextSessionName(Iterable<String> taken) {
  final used = taken.toSet();
  for (var n = 1; ; n++) {
    final name = 'delve-$n';
    if (!used.contains(name)) return name;
  }
}

/// A name the user typed, as tmux will keep it: trimmed, at most 32
/// characters of ASCII letters, digits, `-` and `_`. tmux turns `.` and `:`
/// into `_`, and other characters too when its server did not start with a
/// UTF-8 locale (T3-0: `kettő` became `kett_`) – the tab would then name a
/// session that does not exist. null: not usable.
String? cleanSessionName(String input) {
  final s = input.trim();
  if (s.isEmpty || s.length > 32) return null;
  return RegExp(r'^[A-Za-z0-9_][A-Za-z0-9_-]*$').hasMatch(s) ? s : null;
}

String renameSessionCommand(String from, String to) =>
    'LANG=en_US.UTF-8 tmux -u rename-session -t ${shellQuote('=$from')} '
    '${shellQuote(to)}';

String killSessionCommand(String name) =>
    'LANG=en_US.UTF-8 tmux -u kill-session -t ${shellQuote('=$name')}';

/// Wheel step of a tab: one line in the app's sessions, tmux's 5 elsewhere.
double wheelLinesFor({required bool app}) =>
    app ? kWheelStepLines : kDesktopWheelStepLines;

/// tmux's status lines as the terminal view knows them (one at most).
int viewStatusRows(int rows) => math.min(rows, 1);
