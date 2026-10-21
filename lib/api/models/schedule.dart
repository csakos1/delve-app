import 'package:freezed_annotation/freezed_annotation.dart';

part 'schedule.freezed.dart';
part 'schedule.g.dart';

/// `schedule` shape (`GET /schedules`, `schedule.updated`, B4): a prompt the
/// server queues on a 5-field cron in Europe/Budapest, or the built-in morning
/// brief (`kind: brief`, one of it, can be turned off but not deleted).
@freezed
abstract class Schedule with _$Schedule {
  const factory Schedule({
    required String id,

    /// `prompt` | `brief`.
    required String kind,
    required String name,
    required String cron,

    /// The server's English reading of [cron] ("At 07:30 every day").
    required String description,

    /// null for the brief.
    String? prompt,

    /// `new` (a new chat each run) | `fixed` ([conversationId]).
    required String conversationMode,
    String? conversationId,
    String? conversationTitle,
    required bool thinking,
    required bool enabled,

    /// null while disabled.
    DateTime? nextRunAt,
    DateTime? lastRunAt,

    /// A prompt's last run status (`queued` … `completed`, `failed`,
    /// `cancelled`); the brief's `ok` | `failed`.
    String? lastStatus,
    String? lastError,
    String? lastRunId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Schedule;

  factory Schedule.fromJson(Map<String, Object?> json) =>
      _$ScheduleFromJson(json);
}
