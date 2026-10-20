import 'package:freezed_annotation/freezed_annotation.dart';

part 'run.freezed.dart';
part 'run.g.dart';

/// `run` shape. `status`: queued | starting | running | waiting_for_approval |
/// stopping | reconnecting | completed | cancelled | failed.
@freezed
abstract class Run with _$Run {
  const factory Run({
    required String runId,
    required String conversationId,
    required String status,
    required bool thinking,
    required String origin,
    required DateTime queuedAt,
    DateTime? startedAt,
    DateTime? endedAt,
    Map<String, Object?>? usage,
    Map<String, Object?>? perf,
    String? error,
  }) = _Run;

  factory Run.fromJson(Map<String, Object?> json) => _$RunFromJson(json);
}

/// `open_run` shape (`GET /runs/open`): a run plus its place in the global
/// queue (`position` = runs ahead of it; 0 = active or next).
@freezed
abstract class OpenRun with _$OpenRun {
  const factory OpenRun({
    required String runId,
    required String conversationId,
    required String status,
    required bool thinking,
    required String origin,
    required DateTime queuedAt,
    DateTime? startedAt,
    DateTime? endedAt,
    Map<String, Object?>? usage,
    Map<String, Object?>? perf,
    String? error,
    required int position,
  }) = _OpenRun;

  factory OpenRun.fromJson(Map<String, Object?> json) =>
      _$OpenRunFromJson(json);
}

/// Run states in which a run still occupies the queue.
const Set<String> openRunStatuses = <String>{
  'queued',
  'starting',
  'running',
  'waiting_for_approval',
  'stopping',
  'reconnecting',
};
