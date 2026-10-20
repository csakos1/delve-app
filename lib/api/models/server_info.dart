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
