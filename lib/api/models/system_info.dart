import 'package:freezed_annotation/freezed_annotation.dart';

part 'system_info.freezed.dart';
part 'system_info.g.dart';

/// `system` shape (`GET /system`, `POST /system/llama`, `system.updated`):
/// Hermes, llama-server, the run queue and the GPUs, as the backend sees them
/// through its privileged helper (B3).
@freezed
abstract class SystemInfo with _$SystemInfo {
  const factory SystemInfo({
    required DateTime checkedAt,
    required HelperState helper,
    required HermesInfo hermes,
    required LlamaInfo llama,
    required QueueInfo queue,

    /// null without the helper (no GPU data at all).
    List<GpuInfo>? gpus,
  }) = _SystemInfo;

  factory SystemInfo.fromJson(Map<String, Object?> json) =>
      _$SystemInfoFromJson(json);
}

/// Whether the privileged helper answered every question; [error] is the
/// first problem (`helper_unavailable`, `gpu.status: nvidia-smi: …`).
@freezed
abstract class HelperState with _$HelperState {
  const factory HelperState({required bool ok, String? error}) = _HelperState;

  factory HelperState.fromJson(Map<String, Object?> json) =>
      _$HelperStateFromJson(json);
}

/// `status`: ok | degraded | down | unknown. `since`: the gateway's start.
@freezed
abstract class HermesInfo with _$HermesInfo {
  const factory HermesInfo({
    required String status,
    String? version,
    DateTime? since,
    @Default(<HermesIssue>[]) List<HermesIssue> issues,
  }) = _HermesInfo;

  factory HermesInfo.fromJson(Map<String, Object?> json) =>
      _$HermesInfoFromJson(json);
}

/// A readiness check of Hermes that is not ok (`disk`, `degraded`, `96% used`).
@freezed
abstract class HermesIssue with _$HermesIssue {
  const factory HermesIssue({
    required String check,
    required String status,
    String? detail,
  }) = _HermesIssue;

  factory HermesIssue.fromJson(Map<String, Object?> json) =>
      _$HermesIssueFromJson(json);
}

/// `status`: running | loading | starting | stopping | stopped | failed |
/// down | unknown. `intent`: stopped (stopped from Delve; queued runs wait) |
/// starting (started, the model loads) | null.
///
/// The model presets (M): [preset] is the one the desktop points to (what
/// Start loads while stopped), [vision] and [thinking] (toggle | always |
/// none) say what the loaded or selected model can do, [models] lists every
/// preset (null: the desktop's helper cannot list them) and [switchState] is
/// the switch in progress or the one that failed.
@freezed
abstract class LlamaInfo with _$LlamaInfo {
  const factory LlamaInfo({
    required String status,
    String? intent,
    DateTime? since,
    String? model,
    String? quant,
    int? ctx,
    int? slots,
    int? slotsBusy,

    /// The last completed run's generation speed, tok/s.
    double? genTps,
    String? preset,
    bool? vision,
    String? thinking,
    List<LlamaModel>? models,
    @JsonKey(name: 'switch') LlamaSwitch? switchState,
  }) = _LlamaInfo;

  factory LlamaInfo.fromJson(Map<String, Object?> json) =>
      _$LlamaInfoFromJson(json);
}

/// `llama_model` shape: one preset on the desktop. [name] is the preset's
/// id (what a switch takes), [model] and [quant] what to show. `thinking`:
/// toggle | always | none. A preset that is not [usable] says why in
/// [reason]: no_model | model_missing | mmproj_missing | no_context |
/// context_below_64k. [active]: the desktop points to it.
@freezed
abstract class LlamaModel with _$LlamaModel {
  const factory LlamaModel({
    required String name,
    required String model,
    String? quant,
    String? note,
    int? ctx,
    @Default(false) bool vision,
    @Default('toggle') String thinking,
    int? sizeBytes,
    @Default(false) bool usable,
    String? reason,
    @Default(false) bool active,
  }) = _LlamaModel;

  factory LlamaModel.fromJson(Map<String, Object?> json) =>
      _$LlamaModelFromJson(json);
}

/// `llama_switch` shape. `state`: switching | failed (the previous model is
/// back) | down (llama-server is not running). [from] and [to] are preset
/// ids, [by] the device that asked, [at] when the desktop started; a failed
/// one says why (`error`: exited | timeout) and how long the new model was
/// given ([elapsedS]).
@freezed
abstract class LlamaSwitch with _$LlamaSwitch {
  const factory LlamaSwitch({
    required String state,
    String? from,
    required String to,
    String? by,
    DateTime? at,
    String? error,
    int? elapsedS,
  }) = _LlamaSwitch;

  factory LlamaSwitch.fromJson(Map<String, Object?> json) =>
      _$LlamaSwitchFromJson(json);
}

@freezed
abstract class QueueInfo with _$QueueInfo {
  const factory QueueInfo({required int active, required int queued}) =
      _QueueInfo;

  factory QueueInfo.fromJson(Map<String, Object?> json) =>
      _$QueueInfoFromJson(json);
}

/// One GPU from `nvidia-smi`; a value the driver does not report is null.
@freezed
abstract class GpuInfo with _$GpuInfo {
  const factory GpuInfo({
    required int index,
    required String name,
    double? tempC,
    int? memUsedMib,
    int? memTotalMib,
    double? utilPct,
    double? powerW,
    double? powerLimitW,
  }) = _GpuInfo;

  factory GpuInfo.fromJson(Map<String, Object?> json) =>
      _$GpuInfoFromJson(json);
}
