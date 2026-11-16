import 'package:freezed_annotation/freezed_annotation.dart';

part 'mirror.freezed.dart';
part 'mirror.g.dart';

/// `GET /api/v1/mirror` (API 11): whether the desktop agent is there to show
/// this phone's notifications.
@freezed
abstract class MirrorStatus with _$MirrorStatus {
  const factory MirrorStatus({required DeskLink desk}) = _MirrorStatus;

  factory MirrorStatus.fromJson(Map<String, Object?> json) =>
      _$MirrorStatusFromJson(json);
}

/// The desktop agent as the backend sees it. [connected]: it asked within the
/// last minute; [lastSeenS]: seconds since it last asked, null when it has
/// not since the backend started.
@freezed
abstract class DeskLink with _$DeskLink {
  const factory DeskLink({required bool connected, int? lastSeenS}) = _DeskLink;

  factory DeskLink.fromJson(Map<String, Object?> json) =>
      _$DeskLinkFromJson(json);
}
