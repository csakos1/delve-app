import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'dock.dart';
import 'panes.dart';

/// Where the desktop's own settings live (decision 1142 of the L plan): one
/// JSON file in the app's data folder – not the keyring (a drag writes
/// often), not the database (no migration for a window's panes).
abstract interface class DesktopPrefsStore {
  /// The file's text; null when there is none (or it cannot be read).
  Future<String?> read();
  Future<void> write(String text);
}

/// `<application support>/desktop.json` (Linux:
/// `~/.local/share/hu.csakos.delve/desktop.json`), written through a
/// temporary file and a rename.
class FileDesktopPrefsStore implements DesktopPrefsStore {
  FileDesktopPrefsStore();

  Future<File> _file() async =>
      File('${(await getApplicationSupportDirectory()).path}/desktop.json');

  @override
  Future<String?> read() async {
    try {
      final file = await _file();
      return await file.exists() ? await file.readAsString() : null;
    } on Object {
      return null;
    }
  }

  @override
  Future<void> write(String text) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(text, flush: true);
    await tmp.rename(file.path);
  }
}

/// Tests: the file in memory.
class MemoryDesktopPrefsStore implements DesktopPrefsStore {
  MemoryDesktopPrefsStore([this.text]);

  String? text;

  @override
  Future<String?> read() async => text;

  @override
  Future<void> write(String text) async => this.text = text;
}

final desktopPrefsStoreProvider = Provider<DesktopPrefsStore>(
  (ref) => FileDesktopPrefsStore(),
);

/// Settings → Desktop tools → Text size (decision 1143): the system's
/// factor, or a fixed one. Only the text grows; panes, icons and radii stay.
enum DesktopTextScale {
  system(null),
  normal(1),
  large(1.15),
  larger(1.3);

  const DesktopTextScale(this.factor);

  /// null: the system's own factor.
  final double? factor;

  static DesktopTextScale of(Object? name) => values.firstWhere(
    (s) => s.name == name,
    orElse: () => DesktopTextScale.system,
  );
}

/// The desktop's settings (Settings → Desktop tools).
@immutable
class DesktopPrefs {
  const DesktopPrefs({
    this.loaded = false,
    this.rememberPanes = true,
    this.inspectorByDefault = true,
    this.textScale = DesktopTextScale.system,
  });

  /// The file was read (before that the defaults show).
  final bool loaded;

  /// Keep each area's list and inspector widths, and whether they are open,
  /// and the dock's height and whether it is open, across starts.
  final bool rememberPanes;

  /// An area's inspector starts open.
  final bool inspectorByDefault;
  final DesktopTextScale textScale;

  DesktopPrefs copyWith({
    bool? loaded,
    bool? rememberPanes,
    bool? inspectorByDefault,
    DesktopTextScale? textScale,
  }) => DesktopPrefs(
    loaded: loaded ?? this.loaded,
    rememberPanes: rememberPanes ?? this.rememberPanes,
    inspectorByDefault: inspectorByDefault ?? this.inspectorByDefault,
    textScale: textScale ?? this.textScale,
  );
}

/// The panes as the file keeps them: widths and open / closed (the overlays
/// of narrow windows are per visit).
@visibleForTesting
Map<String, Object?> panesToJson(Map<String, PaneLayout> panes) => {
  for (final e in panes.entries)
    e.key: {
      'list': e.value.list,
      'list_open': e.value.listOpen,
      'inspector': e.value.inspector,
      'inspector_open': e.value.inspectorOpen,
    },
};

@visibleForTesting
Map<String, PaneLayout> panesFromJson(Object? json) {
  if (json is! Map<String, Object?>) return const {};
  final out = <String, PaneLayout>{};
  for (final e in json.entries) {
    final v = e.value;
    if (v is! Map<String, Object?>) continue;
    final list = v['list'];
    final inspector = v['inspector'];
    if (list is! num || inspector is! num) continue;
    out[e.key] = PaneLayout(
      list: list.toDouble(),
      listOpen: v['list_open'] != false,
      inspector: inspector.toDouble(),
      inspectorOpen: v['inspector_open'] != false,
    );
  }
  return out;
}

class DesktopPrefsController extends Notifier<DesktopPrefs> {
  /// The panes the file keeps (empty while Remember pane widths is off).
  Map<String, PaneLayout> _panes = const {};

  /// The dock's height and open / closed, kept with the panes (L2c4b).
  DockState? _dock;
  bool _writing = false;
  bool _dirty = false;

  @override
  DesktopPrefs build() {
    unawaited(_load());
    return const DesktopPrefs();
  }

  DesktopPrefsStore get _store => ref.read(desktopPrefsStoreProvider);

  Future<void> _load() async {
    final text = await _store.read();
    if (!ref.mounted) return;
    var json = const <String, Object?>{};
    try {
      final decoded = text == null ? null : jsonDecode(text);
      if (decoded is Map<String, Object?>) json = decoded;
    } on FormatException {
      // a broken file: the defaults, and the next change writes a good one
    }
    final prefs = DesktopPrefs(
      loaded: true,
      rememberPanes: json['remember_panes'] != false,
      inspectorByDefault: json['inspector_by_default'] != false,
      textScale: DesktopTextScale.of(json['text_scale']),
    );
    state = prefs;
    if (prefs.rememberPanes) {
      _panes = panesFromJson(json['panes']);
      ref.read(paneLayoutsProvider.notifier).restore(_panes);
      final dock = dockFromJson(json['dock']);
      if (dock != null) {
        _dock = dock;
        ref.read(dockProvider.notifier).restore(dock);
      }
    }
  }

  void setRememberPanes({required bool on}) {
    state = state.copyWith(rememberPanes: on);
    _panes = on ? ref.read(paneLayoutsProvider) : const {};
    _dock = on ? ref.read(dockProvider) : null;
    _save();
  }

  /// Also opens or closes every area's docked inspector now.
  void setInspectorByDefault({required bool on}) {
    state = state.copyWith(inspectorByDefault: on);
    ref.read(paneLayoutsProvider.notifier).setInspectorsOpen(open: on);
    _save();
  }

  void setTextScale(DesktopTextScale scale) {
    state = state.copyWith(textScale: scale);
    _save();
  }

  /// [PaneLayouts] changed: kept if Remember pane widths is on (and the file
  /// was read – a change before that would overwrite it).
  void panesChanged(Map<String, PaneLayout> panes) {
    if (!state.loaded || !state.rememberPanes) return;
    _panes = panes;
    _save();
  }

  /// The dock changed: kept like the panes.
  void dockChanged(DockState dock) {
    if (!state.loaded || !state.rememberPanes) return;
    _dock = dock;
    _save();
  }

  Map<String, Object?> _json() => {
    'remember_panes': state.rememberPanes,
    'inspector_by_default': state.inspectorByDefault,
    'text_scale': state.textScale.name,
    if (state.rememberPanes) 'panes': panesToJson(_panes),
    if (state.rememberPanes && _dock != null) 'dock': dockToJson(_dock!),
  };

  /// One write at a time; changes while it runs (a drag) are written once
  /// more after it, with the latest state. No timer.
  void _save() {
    _dirty = true;
    if (_writing) return;
    unawaited(_flush());
  }

  Future<void> _flush() async {
    _writing = true;
    try {
      while (_dirty && ref.mounted) {
        _dirty = false;
        await _store.write(const JsonEncoder.withIndent('  ').convert(_json()));
      }
    } on Object {
      // not kept this time; the window still has it
    } finally {
      _writing = false;
    }
  }
}

final desktopPrefsProvider =
    NotifierProvider<DesktopPrefsController, DesktopPrefs>(
      DesktopPrefsController.new,
    );

/// The desktop layout's text size (around the router, so dialogs and menus
/// follow it): the system's factor, or Settings → Desktop tools' one.
class DesktopTextScaleScope extends ConsumerWidget {
  const DesktopTextScaleScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final factor = ref.watch(desktopPrefsProvider).textScale.factor;
    if (factor == null) return child;
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(factor)),
      child: child,
    );
  }
}
