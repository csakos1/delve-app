import '../l10n/app_localizations.dart';
import '../ui/chat/approval_card.dart' show approvalClassLabel;
import '../ui/format.dart';
import 'push_message.dart';

/// The two Android notification channels (design 18).
enum NotifyChannel { approvals, runs }

/// Action ids on a notification.
abstract final class NotifyActions {
  /// Opens the app (Android asks to unlock first), which answers `once`.
  static const allowOnce = 'allow_once';

  /// Answered in the background, also from the lock screen.
  static const deny = 'deny';
  static const open = 'open';
}

class NotifyAction {
  const NotifyAction(this.id, this.label, {required this.opensApp});
  final String id;
  final String label;

  /// Starts the app (and so needs an unlocked phone) instead of a background
  /// handler.
  final bool opensApp;
}

/// A notification, independent of the plugin that shows it (tests read
/// these; `LocalNotifications` turns them into Android notifications).
class NotificationSpec {
  const NotificationSpec({
    required this.id,
    required this.channel,
    required this.title,
    required this.body,
    required this.payload,
    this.actions = const [],
    this.countdownTo,
    this.timeoutAt,
  });

  final int id;
  final NotifyChannel channel;
  final String title;
  final String body;

  /// [PushTarget.encode].
  final String payload;
  final List<NotifyAction> actions;

  /// The header shows a live countdown to this time (the agent's deadline).
  final DateTime? countdownTo;

  /// Android removes the notification at this time (the approval window ends).
  final DateTime? timeoutAt;
}

/// "Approval needed · service restart", the command, "Agent waits · the chat title";
/// once the agent stopped waiting: "Agent stopped waiting · …" with the time
/// the approval stays answerable. Allow once / Deny / Open either way.
NotificationSpec approvalNotification(
  AppLocalizations l,
  ApprovalPush p,
  DateTime now,
) {
  final kind = approvalClassLabel(l, p.actionClass);
  final chat = p.title.trim();
  final String title;
  final String line;
  if (p.stoppedWaiting) {
    title = l.notifyLateTitle(kind);
    final until = p.expiresAt == null ? '' : clockTime(p.expiresAt!, now);
    line = chat.isEmpty
        ? l.notifyLateBodyNoChat(until)
        : l.notifyLateBody(until, chat);
  } else {
    title = l.notifyApprovalTitle(kind);
    line = chat.isEmpty
        ? l.notifyApprovalWaitsNoChat
        : l.notifyApprovalWaits(chat);
  }
  final deadline = p.hermesDeadline;
  return NotificationSpec(
    id: notificationId(p.requestId),
    channel: NotifyChannel.approvals,
    title: title,
    body: '${p.command}\n$line',
    payload: PushTarget(
      kind: 'approval',
      conversationId: p.conversationId,
      requestId: p.requestId,
    ).encode(),
    actions: [
      NotifyAction(
        NotifyActions.allowOnce,
        l.approvalAllowOnce,
        opensApp: true,
      ),
      NotifyAction(NotifyActions.deny, l.approvalDeny, opensApp: false),
      NotifyAction(NotifyActions.open, l.notifyOpen, opensApp: true),
    ],
    countdownTo: !p.stoppedWaiting && deadline != null && deadline.isAfter(now)
        ? deadline
        : null,
    timeoutAt: p.expiresAt,
  );
}

/// "Run finished · the chat title" (or "Run failed · …") with the start of the
/// answer; Open. (Reply comes later.)
NotificationSpec runDoneNotification(AppLocalizations l, RunDonePush p) {
  final chat = p.title.trim();
  final title = switch ((p.failed, chat.isEmpty)) {
    (false, false) => l.notifyRunDone(chat),
    (false, true) => l.notifyRunDoneNoChat,
    (true, false) => l.notifyRunFailed(chat),
    (true, true) => l.notifyRunFailedNoChat,
  };
  return NotificationSpec(
    id: notificationId(p.runId),
    channel: NotifyChannel.runs,
    title: title,
    body: p.preview,
    payload: PushTarget(
      kind: 'run_done',
      conversationId: p.conversationId,
    ).encode(),
    actions: [NotifyAction(NotifyActions.open, l.notifyOpen, opensApp: true)],
  );
}
