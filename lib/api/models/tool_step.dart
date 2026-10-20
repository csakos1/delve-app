import 'package:freezed_annotation/freezed_annotation.dart';

import 'approval.dart';

part 'tool_step.freezed.dart';
part 'tool_step.g.dart';

/// `tool_step` shape. `status`: running | ok | error | cancelled | denied |
/// timeout | blocked.
@freezed
abstract class ToolStep with _$ToolStep {
  const factory ToolStep({
    required int id,
    required String runId,
    required String tool,
    required String status,
    String? preview,
    Map<String, Object?>? result,
    String? resultRaw,
    String? userSummary,
    double? durationS,
    int? seqStarted,
    int? seqCompleted,
    String? approvalRequestId,
    Approval? approval,
  }) = _ToolStep;

  factory ToolStep.fromJson(Map<String, Object?> json) =>
      _$ToolStepFromJson(json);
}
