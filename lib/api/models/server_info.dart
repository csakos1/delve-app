import 'package:freezed_annotation/freezed_annotation.dart';

part 'server_info.freezed.dart';
part 'server_info.g.dart';

/// `GET /api/v1/meta` (no auth). Unknown keys are ignored.
@freezed
abstract class ServerMeta with _$ServerMeta {
  const factory ServerMeta({
    required String serverVersion,
    required int apiRevision,
    String? revision,
    String? hermesExpectedVersion,
    int? approvalTimeoutS,
  }) = _ServerMeta;

  factory ServerMeta.fromJson(Map<String, Object?> json) =>
      _$ServerMetaFromJson(json);
}

/// Whether the last thinking run really used the thinking provider.
@freezed
abstract class ThinkingRoute with _$ThinkingRoute {
  const factory ThinkingRoute({required bool ok, String? runId, DateTime? at}) =
      _ThinkingRoute;

  factory ThinkingRoute.fromJson(Map<String, Object?> json) =>
      _$ThinkingRouteFromJson(json);
}

/// `GET /api/v1/status`. `hermes`: ok | down | null (not polled yet).
@freezed
abstract class ServerStatus with _$ServerStatus {
  const factory ServerStatus({
    required String serverVersion,
    required int apiRevision,
    String? revision,
    String? hermes,
    String? hermesVersion,
    ThinkingRoute? thinkingRoute,
  }) = _ServerStatus;

  factory ServerStatus.fromJson(Map<String, Object?> json) =>
      _$ServerStatusFromJson(json);
}

/// `hello.ok`: the status plus the event stream position.
@freezed
abstract class HelloOk with _$HelloOk {
  const factory HelloOk({
    required String serverVersion,
    required int apiRevision,
    String? revision,
    String? hermes,
    String? hermesVersion,
    ThinkingRoute? thinkingRoute,
    required String epoch,
    required int seq,
    required bool resyncRequired,
  }) = _HelloOk;

  factory HelloOk.fromJson(Map<String, Object?> json) =>
      _$HelloOkFromJson(json);
}

/// `POST /api/v1/devices/register` → 201.
@freezed
abstract class RegisteredDevice with _$RegisteredDevice {
  const factory RegisteredDevice({
    required String deviceId,
    required String name,
    required String token,
  }) = _RegisteredDevice;

  factory RegisteredDevice.fromJson(Map<String, Object?> json) =>
      _$RegisteredDeviceFromJson(json);
}

/// `GET` / `PATCH /api/v1/devices/me`. `fcm`: the server has this phone's
/// push token; `push`: the server can send pushes at all (API 3).
@freezed
abstract class DeviceInfo with _$DeviceInfo {
  const factory DeviceInfo({
    required String id,
    required String name,
    required DateTime createdAt,
    DateTime? lastSeenAt,
    required bool fcm,
    @Default(false) bool push,
    @Default(NotifySettings()) NotifySettings notify,
  }) = _DeviceInfo;

  factory DeviceInfo.fromJson(Map<String, Object?> json) =>
      _$DeviceInfoFromJson(json);
}

/// Which pushes this device wants (`devices.notify`, decision 260).
@freezed
abstract class NotifySettings with _$NotifySettings {
  const factory NotifySettings({
    @Default(true) bool approvals,
    @Default(true) bool runDone,
    @Default(false) bool water,
    @Default(false) bool brief,

    /// Watch hits (W2); on unless turned off.
    @Default(true) bool watches,
  }) = _NotifySettings;

  factory NotifySettings.fromJson(Map<String, Object?> json) =>
      _$NotifySettingsFromJson(json);
}
