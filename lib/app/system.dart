import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models/models.dart';
import '../api/protocol.dart';
import '../api/rest_client.dart';
import '../sync/sync_providers.dart';
import 'session.dart';

/// How often the System screen asks again while it is open (N47).
const Duration kSystemPoll = Duration(seconds: 10);

/// What the System screen and the dashboard's System card show (B3). Kept in
/// memory only: it is live state of the desktop, a stored copy would mislead.
@immutable
class SystemView {
  const SystemView({this.info, this.error, this.busy});

  /// The last answer of the server (null before the first one).
  final SystemInfo? info;

  /// The last refresh failed (an older [info] may still be shown).
  final Object? error;

  /// A stop, a start, a model switch or a dismiss is on its way.
  final LlamaAction? busy;

  SystemView withInfo(SystemInfo info) => SystemView(info: info, busy: busy);
  SystemView withError(Object error) =>
      SystemView(info: info, error: error, busy: busy);
  SystemView withBusy(LlamaAction? action) =>
      SystemView(info: info, error: error, busy: action);
}

/// Loads the system view over REST and takes `system.updated` events from the
/// socket. Stop and start answer with the new view.
class SystemController extends Notifier<SystemView> {
  @override
  SystemView build() {
    final engine = ref.watch(syncEngineProvider);
    ref.watch(apiProvider); // another server starts empty
    if (engine != null) {
      final sub = engine.systemUpdates.listen((info) {
        if (ref.mounted) state = state.withInfo(info);
      });
      ref.onDispose(sub.cancel);
    }
    return const SystemView();
  }

  /// Reloads the view; a failure is kept in [SystemView.error] and rethrown.
  Future<void> refresh() async {
    final api = ref.read(apiProvider);
    if (api == null) return;
    try {
      final info = await api.system();
      if (ref.mounted) state = state.withInfo(info);
    } on Object catch (e) {
      if (ref.mounted) state = state.withError(e);
      rethrow;
    }
  }

  /// Stops or starts llama-server ([force]: stop although a run is active).
  /// Throws the server's error (409 `run_active`, 503, 502) unchanged.
  Future<SystemInfo?> llama(LlamaAction action, {bool force = false}) async {
    assert(action == LlamaAction.start || action == LlamaAction.stop);
    return _act(action, (api) => api.llama(action, force: force));
  }

  /// Loads the preset [name] ([force]: although a run is active); while
  /// llama-server is stopped only the selection changes. Throws the server's
  /// error (409 `run_active`, `already_active`, …; 404) unchanged.
  Future<SystemInfo?> switchModel(String name, {bool force = false}) => _act(
    LlamaAction.switchModel,
    (api) => api.switchModel(name, force: force),
  );

  /// Forgets a failed switch.
  Future<SystemInfo?> dismissSwitch() =>
      _act(LlamaAction.dismiss, (api) => api.dismissSwitch());

  Future<SystemInfo?> _act(
    LlamaAction action,
    Future<SystemInfo> Function(DelveApi api) call,
  ) async {
    final api = ref.read(apiProvider);
    if (api == null || state.busy != null) return null;
    state = state.withBusy(action);
    try {
      final info = await call(api);
      if (ref.mounted) state = SystemView(info: info);
      return info;
    } finally {
      if (ref.mounted && state.busy == action) state = state.withBusy(null);
    }
  }
}

final systemProvider = NotifierProvider<SystemController, SystemView>(
  SystemController.new,
);

/// Display helpers shared by the System screen and the dashboard card.
extension SystemInfoX on SystemInfo {
  /// The button offers Start (stopped, failed, unreachable), else Stop.
  bool get canStart =>
      llama.status == 'stopped' ||
      llama.status == 'failed' ||
      llama.status == 'down';
}

/// The model presets as the cards show them (M).
extension LlamaInfoX on LlamaInfo {
  /// A switch is on its way: the new model loads.
  bool get switching => switchState?.state == 'switching';

  /// The preset with this id, if the desktop still lists it.
  LlamaModel? presetNamed(String? name) {
    if (name == null) return null;
    for (final m in models ?? const <LlamaModel>[]) {
      if (m.name == name) return m;
    }
    return null;
  }

  /// A preset as text ("Qwen3.8-27B · IQ4_XS"); its id when the desktop no
  /// longer lists it.
  String? presetText(String? name) {
    final m = presetNamed(name);
    return m == null ? name : modelText(m.model, m.quant);
  }

  /// What the Model row says: the model that loads during a switch, the
  /// loaded one, else the preset Start loads. null: not known.
  String? get modelLine {
    if (switching) return presetText(switchState!.to);
    if (model case final m?) return modelText(m, quant);
    return presetText(preset);
  }
}

/// "Qwen3.8-27B · IQ4_XS" (the name alone without a quantization).
String modelText(String model, String? quant) =>
    quant == null ? model : '$model · $quant';
