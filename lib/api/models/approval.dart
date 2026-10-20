import 'package:freezed_annotation/freezed_annotation.dart';

part 'approval.freezed.dart';
part 'approval.g.dart';

/// `approval` shape. `action_class`: pkg_upgrade | service_restart |
/// delete_kill | other. `choices` never contains `always`.
@freezed
abstract class Approval with _$Approval {
  const factory Approval({
    required String requestId,
    required String runId,
    required String conversationId,
    required String command,
    String? description,
    required List<String> patternKeys,
    required String actionClass,
    required String status,
    String? choice,
    required List<String> choices,
    String? decidedBy,
    required DateTime createdAt,
    required DateTime hermesDeadline,
    required DateTime expiresAt,
    DateTime? respondedAt,
  }) = _Approval;

  factory Approval.fromJson(Map<String, Object?> json) =>
      _$ApprovalFromJson(json);
}

/// Statuses the user can still answer (the second one via late approval).
const Set<String> answerableApprovalStatuses = <String>{
  'pending',
  'expired_in_hermes',
};
