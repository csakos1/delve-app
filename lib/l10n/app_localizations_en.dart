// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Delve';

  @override
  String get navChats => 'Chats';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navApprovals => 'Approvals';

  @override
  String get navMore => 'More';

  @override
  String approvalsBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count approvals waiting',
      one: '1 approval waiting',
    );
    return '$_temp0';
  }

  @override
  String get moreSystem => 'System';

  @override
  String get moreSystemSub => 'llama-server, Hermes, backend';

  @override
  String get moreSchedules => 'Schedules';

  @override
  String get moreSchedulesSub => 'Recurring prompts';

  @override
  String get moreObservability => 'Observability';

  @override
  String get moreObservabilitySub => 'Throughput, tokens, runs';

  @override
  String get moreSettings => 'Settings';

  @override
  String get moreSettingsSub => 'Server, device, about';

  @override
  String get newChat => 'New chat';

  @override
  String get chatTitle => 'Chat';

  @override
  String get back => 'Back';

  @override
  String get pairTitle => 'Pair this phone';

  @override
  String get pairIntro =>
      'Connect to your Delve server over Tailscale. Get an 8-digit code on the desktop with: sudo delve pair';

  @override
  String get pairServerUrl => 'Server URL';

  @override
  String get pairServerUrlHint => 'https://archlinux.<tailnet>.ts.net';

  @override
  String get pairServerUrlHelper => 'Your desktop\'s Tailscale address';

  @override
  String get pairUrlInvalid => 'Not a valid address';

  @override
  String get pairUrlNotHttps => 'Use the https:// address';

  @override
  String get pairUrlNotTailnet =>
      'Use the desktop\'s Tailscale name (….ts.net)';

  @override
  String get pairCode => 'Pairing code';

  @override
  String get pairCodeHelper => '8 digits, valid for 10 minutes';

  @override
  String get pairCodeInvalid => 'Invalid or expired code';

  @override
  String get pairButton => 'Pair';

  @override
  String pairButtonWait(int seconds) {
    return 'Pair · $seconds s';
  }

  @override
  String pairRateLimited(int seconds) {
    return 'Too many attempts — try again in $seconds s';
  }

  @override
  String get pairUnreachable => 'Can\'t reach the server — is Tailscale on?';

  @override
  String pairFailed(String reason) {
    return 'Pairing failed: $reason';
  }

  @override
  String pairFailedServer(int status) {
    return 'server error (HTTP $status)';
  }

  @override
  String get pairFailedNotDelve =>
      'unexpected answer — is this the Delve server?';

  @override
  String get pairFootnote => 'Traffic stays inside your tailnet.';

  @override
  String get pairNoteUnpaired =>
      'This phone was unpaired. Pair again with a new code.';

  @override
  String get pairNoteUnpairedLocally =>
      'Unpaired on this phone, but the server could not be reached. Revoke the old token there: sudo delve token list, then sudo delve token revoke <id>.';

  @override
  String get pairNoteRevoked =>
      'The server no longer accepts this phone\'s token. Pair again with a new code.';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get copied => 'Copied';

  @override
  String get copy => 'Copy';

  @override
  String get settingsServer => 'Server';

  @override
  String get settingsServerUrl => 'Server URL';

  @override
  String get settingsThisDevice => 'This device';

  @override
  String settingsPairedSeen(String date, String seen) {
    return 'Paired $date · last seen $seen';
  }

  @override
  String get settingsSeenNow => 'now';

  @override
  String settingsSeenMinutes(int minutes) {
    return '$minutes min ago';
  }

  @override
  String get settingsSeenNever => 'never';

  @override
  String get settingsThinkingRoute => 'Thinking route';

  @override
  String get settingsStatus => 'Status';

  @override
  String get settingsRouteOk => 'OK';

  @override
  String settingsRouteOkDetail(String time) {
    return 'Last thinking run at $time used the thinking model';
  }

  @override
  String get settingsRouteFailed => 'Check failed';

  @override
  String settingsRouteFailedDetail(String time) {
    return 'Last thinking run at $time did not use the thinking model';
  }

  @override
  String get settingsRouteNone => 'No data';

  @override
  String get settingsRouteNoneDetail =>
      'No thinking run since the server started';

  @override
  String get settingsCheckAgain => 'Check again';

  @override
  String get settingsVersions => 'Versions';

  @override
  String get settingsApp => 'App';

  @override
  String get settingsServerVersion => 'Server';

  @override
  String get settingsApiRevision => 'API revision';

  @override
  String get settingsHermes => 'Hermes Agent';

  @override
  String get settingsHermesDown => 'down';

  @override
  String get settingsUnknown => '—';

  @override
  String settingsLoadFailed(String reason) {
    return 'Couldn\'t load: $reason';
  }

  @override
  String get settingsUnpair => 'Unpair this device';

  @override
  String get settingsUnpairNote =>
      'You will need a new pairing code to connect again.';

  @override
  String get unpairDialogTitle => 'Unpair this device?';

  @override
  String get unpairDialogBody =>
      'The server stops accepting this phone and the local copy of your chats is deleted. You will need a new pairing code to connect again.';

  @override
  String get unpairDialogConfirm => 'Unpair';

  @override
  String get tooOldTitle => 'Server version too old for this app';

  @override
  String tooOldBody(String app, int min) {
    return 'Delve $app needs API revision $min or newer. Update the Delve server on your desktop, then try again.';
  }

  @override
  String get tooOldThisApp => 'This app';

  @override
  String tooOldNeeds(String app, int min) {
    return '$app · needs API ≥ $min';
  }

  @override
  String get tooOldServer => 'Server';

  @override
  String tooOldServerValue(String version, int revision) {
    return '$version · API $revision';
  }

  @override
  String get tooOldServerUrl => 'Server URL';

  @override
  String tooOldStillOld(int revision) {
    return 'The server still reports API revision $revision';
  }

  @override
  String get tooOldPairOther => 'Pair with another server';

  @override
  String get settingsConnection => 'Connection';

  @override
  String get connLive => 'Live';

  @override
  String connLiveSince(String time) {
    return 'Live since $time';
  }

  @override
  String get connReloading => 'Live · reloading after a server restart';

  @override
  String get connConnecting => 'Connecting…';

  @override
  String connRetrying(String problem, int attempt) {
    return '$problem Retrying (attempt $attempt).';
  }

  @override
  String get connOffline => 'Not connected';

  @override
  String get connPaused => 'Disconnected while the app is in the background';

  @override
  String get connAuthFailed => 'The server refused this device\'s token';

  @override
  String get connUnreachable => 'Can\'t reach the server — is Tailscale on?';

  @override
  String get connRejected =>
      'The server is reachable, but Delve isn\'t answering.';

  @override
  String get connHelloTimeout => 'The server didn\'t answer in time.';

  @override
  String get connSilent => 'The connection went silent.';

  @override
  String get connClosed => 'The server closed the connection.';

  @override
  String get connResyncFailed => 'Reloading after a server restart failed.';

  @override
  String get chipLive => 'Live';

  @override
  String get chipConnecting => 'Connecting';

  @override
  String get chipRetrying => 'Retrying';

  @override
  String get chipOffline => 'Offline';

  @override
  String get chipRefused => 'Refused';

  @override
  String get logTitle => 'Connection log';

  @override
  String get logEmpty => 'Nothing logged yet';

  @override
  String get logReconnectNow => 'Reconnect now';

  @override
  String get logKindConnecting => 'Connecting';

  @override
  String get logKindConnected => 'Connected';

  @override
  String get logKindResync => 'Reloaded';

  @override
  String get logKindClosed => 'Closed';

  @override
  String get logKindFailed => 'Failed';

  @override
  String get logKindBackoff => 'Waiting';

  @override
  String get logKindPaused => 'Paused';

  @override
  String get logKindResumed => 'Resumed';

  @override
  String get logKindAuthFailed => 'Token refused';

  @override
  String get logKindOutbox => 'Outbox';

  @override
  String get logKindHermes => 'Hermes';

  @override
  String get logKindServerError => 'Server error';

  @override
  String get logKindProtocol => 'Protocol';

  @override
  String get chatsSearch => 'Search chats';

  @override
  String get chatsSearchClose => 'Close search';

  @override
  String get chatsSearchHint => 'Search titles and messages';

  @override
  String chatsNoMatch(String query) {
    return 'No chats match “$query”';
  }

  @override
  String get chatsEmptyTitle => 'No chats yet';

  @override
  String get chatsEmptyBody =>
      'Ask your agent anything. Runs happen on your desktop; this phone only talks to it over Tailscale.';

  @override
  String get chatsMarkerApproval => 'approval needed';

  @override
  String get chatsMarkerRunning => 'running';

  @override
  String chatsMarkerRunningQueued(int count) {
    return 'running · $count queued';
  }

  @override
  String get chatsMarkerWaiting => 'queued';

  @override
  String get chatsDetails => 'Details';

  @override
  String get chatsArchive => 'Archive';

  @override
  String get chatsArchived => 'Chat archived';

  @override
  String get chatsUndo => 'Undo';

  @override
  String chatsArchiveFailed(String reason) {
    return 'Couldn\'t archive: $reason';
  }

  @override
  String chatsRefreshFailed(String reason) {
    return 'Couldn\'t refresh: $reason';
  }

  @override
  String errorRateLimited(int seconds) {
    return 'too many requests, try again in $seconds s';
  }

  @override
  String errorHttp(String status) {
    return 'server error (HTTP $status)';
  }

  @override
  String get errorCancelled => 'cancelled';

  @override
  String get moreArchived => 'Archived chats';

  @override
  String get moreArchivedSub => 'Chats you swiped away';

  @override
  String get archivedEmpty =>
      'No archived chats. Swipe a chat to the left on the Chats screen to archive it.';

  @override
  String get archivedRestore => 'Restore';

  @override
  String get archivedRestored => 'Chat restored';

  @override
  String archivedRestoreFailed(String reason) {
    return 'Couldn\'t restore: $reason';
  }

  @override
  String get chatCopied => 'Copied';

  @override
  String get chatLinkCopied => 'Link copied';

  @override
  String get chatMenu => 'Chat options';

  @override
  String get chatNotConnected => 'not connected to the server';

  @override
  String get chatNoAnswer => 'the server did not answer';

  @override
  String chatStopFailed(String reason) {
    return 'Couldn\'t stop: $reason';
  }

  @override
  String get chatWorking => 'Working…';

  @override
  String get chatRunStopped => 'Run stopped';

  @override
  String chatRunRunning(String clock) {
    return 'running · $clock';
  }

  @override
  String chatRunWaiting(String clock) {
    return 'waiting for approval · $clock';
  }

  @override
  String get chatRunQueued => 'queued';

  @override
  String chatContextWarn(int pct) {
    return 'Context $pct% full — consider a new chat';
  }

  @override
  String newChatIntro(String host) {
    return 'Your agent on $host · over Tailscale';
  }

  @override
  String get newChatIntroNoHost => 'Your agent, over Tailscale';

  @override
  String get composerHint => 'Message Delve…';

  @override
  String get composerSend => 'Send';

  @override
  String get composerStop => 'Stop run';

  @override
  String get composerAttach => 'Add a photo or file';

  @override
  String composerQueued(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more messages queued',
      one: '1 more message queued',
    );
    return '$_temp0';
  }

  @override
  String get attachPhotos => 'Photos';

  @override
  String get attachCamera => 'Camera';

  @override
  String get attachFile => 'File';

  @override
  String attachLimit(int max) {
    return 'Up to $max attachments per message';
  }

  @override
  String attachLeftOut(int count, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count were left out: up to $max per message',
      one: '1 was left out: up to $max per message',
    );
    return '$_temp0';
  }

  @override
  String get attachNeedsConnection => 'Attachments need a live connection';

  @override
  String attachUploading(String name) {
    return 'Uploading $name';
  }

  @override
  String attachFailedRetry(String name) {
    return '$name: not uploaded, tap to retry';
  }

  @override
  String get attachFailedShort => 'Not uploaded · tap to retry';

  @override
  String attachTooLarge(String size) {
    return 'Too large (max $size)';
  }

  @override
  String get attachUnreadable => 'Not a readable image';

  @override
  String attachRemove(String name) {
    return 'Remove $name';
  }

  @override
  String attachImage(String name) {
    return 'Image $name';
  }

  @override
  String get attachGone => 'No longer available';

  @override
  String get attachSendAgain => 'Send again';

  @override
  String get attachAdded => 'Added to your message';

  @override
  String attachPickFailed(String reason) {
    return 'Could not open the picker: $reason';
  }

  @override
  String attachCopyFailed(String reason) {
    return 'Could not add it again: $reason';
  }

  @override
  String get attachLoadFailed => 'Could not load the image';

  @override
  String get outboxWaiting => 'Waiting for the connection';

  @override
  String get outboxSending => 'Sending…';

  @override
  String get outboxFailed => 'Not sent';

  @override
  String outboxFailedWhy(String reason) {
    return 'Not sent: $reason';
  }

  @override
  String get outboxRetry => 'Retry';

  @override
  String get outboxDiscard => 'Discard';

  @override
  String get stepRunning => 'Running';

  @override
  String get stepWaiting => 'Approval needed';

  @override
  String get stepOk => 'OK';

  @override
  String get stepError => 'Error';

  @override
  String get stepCancelled => 'Cancelled';

  @override
  String get stepDenied => 'Denied';

  @override
  String get stepTimeout => 'Timed out';

  @override
  String get stepBlocked => 'Blocked';

  @override
  String get stepCancelledNote => 'Run stopped before this step finished.';

  @override
  String get stepDeniedNote => 'Not run. The agent was told it was denied.';

  @override
  String get stepBlockedNote =>
      'Matched a deny rule · never asks for approval.';

  @override
  String get stepWaitingNote => 'The agent waits for your approval.';

  @override
  String get showMore => 'Show more';

  @override
  String get runFailed => 'Run failed';

  @override
  String get runRetry => 'Retry';

  @override
  String get runFailedUnknown => 'The run ended with an error.';

  @override
  String get runFailedLost => 'The agent restarted and lost this run.';

  @override
  String get runFailedUnstable => 'The connection to the agent kept dropping.';

  @override
  String runFailedHermes(String code) {
    return 'The agent refused the run ($code).';
  }

  @override
  String get approvalNeeded => 'Approval needed';

  @override
  String get approvalStoppedWaiting => 'Agent stopped waiting';

  @override
  String approvalWaits(String time) {
    return 'Agent waits $time';
  }

  @override
  String approvalLateBody(String time) {
    return 'Agent stopped waiting. You can still approve until $time — Delve will run it in a follow-up.';
  }

  @override
  String approvalClosed(String time) {
    return 'The approval window closed at $time.';
  }

  @override
  String get approvalAllowOnce => 'Allow once';

  @override
  String get approvalDeny => 'Deny';

  @override
  String get approvalAllowSession => 'Allow for session';

  @override
  String get approvalOffline =>
      'Not connected — you can answer once the connection is back.';

  @override
  String approvalFailed(String reason) {
    return 'Couldn\'t answer: $reason';
  }

  @override
  String get approvalClassPkgUpgrade => 'package upgrade';

  @override
  String get approvalClassServiceRestart => 'service restart';

  @override
  String get approvalClassDeleteKill => 'delete / kill';

  @override
  String get approvalClassOther => 'command';

  @override
  String get approvalApproved => 'Approved';

  @override
  String get approvalApprovedLate => 'Approved late';

  @override
  String get approvalRanLater => 'Ran in a follow-up';

  @override
  String get approvalSuperseded => 'Follow-up ran something else';

  @override
  String get approvalDenied => 'Denied';

  @override
  String get approvalExpired => 'Expired';

  @override
  String get approvalCancelled => 'Cancelled';

  @override
  String get approvalByYou => 'by you';

  @override
  String approvalBy(String name) {
    return 'by $name';
  }

  @override
  String get approvalsPending => 'Pending';

  @override
  String get approvalsExpired => 'Expired in agent — still approvable';

  @override
  String get approvalsRecent => 'Recent';

  @override
  String get approvalsNothingWaiting => 'Nothing is waiting for you.';

  @override
  String get approvalsEmptyTitle => 'Nothing to approve';

  @override
  String get approvalsEmptyBody =>
      'Commands the agent wants your OK for show up here.';

  @override
  String approvalsRefreshFailed(String reason) {
    return 'Couldn\'t reload: $reason';
  }

  @override
  String get approvalsLateStarted => 'Approved — Delve runs it in a follow-up.';

  @override
  String approvalsExpiredUntil(String time) {
    return 'Expired in agent · approvable until $time';
  }

  @override
  String approvalsClosedAt(String time) {
    return 'Expired in agent · closed at $time';
  }

  @override
  String get approvalsMore => 'More options';

  @override
  String get approvalsOpenChat => 'Open chat';

  @override
  String get approvalsWhoYou => 'You';

  @override
  String get approvalsWhoAuto => 'Delve (follow-up)';

  @override
  String get chatFollowUp => 'Follow-up run: approved';

  @override
  String get composerThinking => 'Thinking';

  @override
  String get composerThinkingCaption => 'Applies to your next message';

  @override
  String thinkingFailed(String reason) {
    return 'Couldn\'t switch Thinking: $reason';
  }

  @override
  String get thinkingNow => 'Thinking…';

  @override
  String thinkingTokens(String count) {
    return '$count tok';
  }

  @override
  String get thinkingThought => 'Thought';

  @override
  String thinkingThoughtFor(String time) {
    return 'Thought for $time';
  }

  @override
  String get thinkingShowAll => 'Show all';

  @override
  String get close => 'Close';

  @override
  String get usageNoContext => '—';

  @override
  String get usageTitle => 'Usage';

  @override
  String usageRunCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count runs',
      one: '1 run',
    );
    return '$_temp0';
  }

  @override
  String usageLoadFailed(String reason) {
    return 'Couldn\'t load usage: $reason';
  }

  @override
  String get usageInput => 'Input';

  @override
  String get usageOutput => 'Output';

  @override
  String get usageCacheRead => 'Cache read';

  @override
  String get usageTotal => 'Total';

  @override
  String get usageContext => 'Context';

  @override
  String get usageWarnMark => '75% · warn';

  @override
  String get usageRuns => 'Runs';

  @override
  String get usageNewestFirst => 'newest first';

  @override
  String get usageNoRuns => 'No runs yet.';

  @override
  String get usagePrefillNote =>
      'Prefill speed is shown only for prompts of 500 tokens or more.';

  @override
  String usageRun(int number) {
    return 'Run $number';
  }

  @override
  String usageRunState(int number, String state) {
    return 'Run $number · $state';
  }

  @override
  String get usageRunFailed => 'failed';

  @override
  String get usageRunStopped => 'stopped';

  @override
  String get usageRunQueued => 'queued';

  @override
  String get usageRunRunning => 'running';

  @override
  String usageIn(String count) {
    return 'in $count';
  }

  @override
  String usageOut(String count) {
    return 'out $count';
  }

  @override
  String get usagePrefill => 'Prefill';

  @override
  String get usageGeneration => 'Generation';

  @override
  String get usageFirstToken => 'First token';

  @override
  String contextChipSemantics(int percent) {
    return 'Context $percent percent, opens usage';
  }

  @override
  String contextChipWarn(int percent) {
    return 'Context $percent percent, almost full, opens usage';
  }

  @override
  String get contextChipEmpty => 'Context not measured yet, opens usage';

  @override
  String notifyApprovalTitle(String kind) {
    return 'Approval needed · $kind';
  }

  @override
  String notifyApprovalWaits(String chat) {
    return 'Agent waits · $chat';
  }

  @override
  String get notifyApprovalWaitsNoChat => 'Agent waits';

  @override
  String notifyLateTitle(String kind) {
    return 'Agent stopped waiting · $kind';
  }

  @override
  String notifyLateBody(String time, String chat) {
    return 'Approvable until $time · $chat';
  }

  @override
  String notifyLateBodyNoChat(String time) {
    return 'Approvable until $time';
  }

  @override
  String notifyRunDone(String chat) {
    return 'Run finished · $chat';
  }

  @override
  String get notifyRunDoneNoChat => 'Run finished';

  @override
  String notifyRunFailed(String chat) {
    return 'Run failed · $chat';
  }

  @override
  String get notifyRunFailedNoChat => 'Run failed';

  @override
  String get notifyOpen => 'Open';

  @override
  String get notifyChannelApprovals => 'Approvals';

  @override
  String get notifyChannelApprovalsDesc => 'Commands waiting for your OK';

  @override
  String get notifyChannelRuns => 'Finished runs';

  @override
  String get notifyChannelRunsDesc =>
      'Answers that arrive while Delve is in the background';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotifyApprovals => 'Approvals';

  @override
  String get settingsNotifyApprovalsSub =>
      'Allow once / Deny from the notification';

  @override
  String get settingsNotifyRunDone => 'Run finished';

  @override
  String get settingsNotifyRunDoneSub =>
      'Only when the app is in the background';

  @override
  String get settingsNotifyWater => 'Water level';

  @override
  String get settingsNotifyBrief => 'Morning brief';

  @override
  String get settingsNotifyBriefSub => 'After each morning brief';

  @override
  String get settingsNotifyPermissionOff =>
      'Notifications are off for Delve on this phone.';

  @override
  String get settingsNotifyAllow => 'Allow';

  @override
  String get settingsNotifyNoServer =>
      'The server can\'t send notifications yet (no Firebase key).';

  @override
  String get settingsNotifyNoApp =>
      'This build can\'t receive notifications (no Firebase configuration).';

  @override
  String settingsNotifySaveFailed(String reason) {
    return 'Couldn\'t save: $reason';
  }

  @override
  String dashUpdated(String time) {
    return 'Updated $time';
  }

  @override
  String get dashConnected => 'Connected · tailnet';

  @override
  String get dashWaterTitle => 'Lake Balaton water level';

  @override
  String dashToday(String time) {
    return 'today $time';
  }

  @override
  String get dashCm => 'cm';

  @override
  String get dashLakeAverage => 'Lake average';

  @override
  String get dashVsYesterday => 'vs yesterday';

  @override
  String get dashWaterEmpty =>
      'No water reading yet. It arrives after the next scheduled reading.';

  @override
  String notifyWaterTitle(String station, String level) {
    return 'Water level · $station $level cm';
  }

  @override
  String notifyWaterLake(String level) {
    return 'Lake average $level cm';
  }

  @override
  String notifyWaterTrend(String change) {
    return '$change cm vs yesterday';
  }

  @override
  String get notifyChannelCards => 'Water level';

  @override
  String get notifyChannelCardsDesc => 'After each scheduled reading';

  @override
  String get settingsNotifyWaterSub => 'After each scheduled reading';

  @override
  String systemChecked(String time) {
    return 'checked $time';
  }

  @override
  String get systemHermes => 'Hermes Agent';

  @override
  String get systemStatus => 'Status';

  @override
  String get systemVersion => 'Version';

  @override
  String get systemUptime => 'Uptime';

  @override
  String get systemQueue => 'Queue';

  @override
  String systemQueueActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count runs active',
      one: '1 run active',
    );
    return '$_temp0';
  }

  @override
  String systemQueueQueued(int count) {
    return '$count queued';
  }

  @override
  String get systemLlama => 'llama-server';

  @override
  String get systemModel => 'Model';

  @override
  String get systemContext => 'Context';

  @override
  String get systemSlots => 'Slots';

  @override
  String get systemGeneration => 'Generation';

  @override
  String systemSince(String time) {
    return 'since $time';
  }

  @override
  String systemTokens(String tokens) {
    return '$tokens tok';
  }

  @override
  String systemSlotsBusy(int busy, int total) {
    return '$busy / $total busy';
  }

  @override
  String systemSlotsIdle(int busy, int total) {
    return '$busy / $total';
  }

  @override
  String systemTps(String tps) {
    return '$tps tok/s';
  }

  @override
  String get systemStop => 'Stop llama-server';

  @override
  String get systemStart => 'Start llama-server';

  @override
  String get systemStopping => 'Stopping…';

  @override
  String get systemStarting => 'Starting…';

  @override
  String get systemGpus => 'GPUs';

  @override
  String systemGpuSource(String age) {
    return 'nvidia-smi · $age';
  }

  @override
  String systemGpuCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count GPUs',
      one: '1 GPU',
    );
    return '$_temp0';
  }

  @override
  String get systemTitle => 'System';

  @override
  String get systemHermesShort => 'Hermes';

  @override
  String get systemStateRunning => 'running';

  @override
  String get systemStateLoading => 'loading';

  @override
  String get systemStateStarting => 'starting';

  @override
  String get systemStateStopping => 'stopping';

  @override
  String get systemStateStopped => 'stopped';

  @override
  String get systemStateFailed => 'failed';

  @override
  String get systemStateDown => 'unreachable';

  @override
  String get systemStateUnknown => 'unknown';

  @override
  String get systemStateOk => 'ok';

  @override
  String get systemStateDegraded => 'degraded';

  @override
  String get systemHelperMissing =>
      'The server can\'t reach its system helper: no GPU data, and llama-server can\'t be stopped or started from here.';

  @override
  String systemHelperProblem(String reason) {
    return 'Part of the system view is missing: $reason';
  }

  @override
  String systemHeldQueue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages wait until llama-server is back.',
      one: '1 message waits until llama-server is back.',
      zero: 'Messages you send wait until llama-server is back.',
    );
    return '$_temp0';
  }

  @override
  String get systemLoadingNote =>
      'Waiting messages start once the model is loaded.';

  @override
  String get systemStopTitle => 'Stop llama-server?';

  @override
  String get systemStopActive => 'The active run will be stopped.';

  @override
  String systemStopQueued(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count queued messages wait until you start it again.',
      one: '1 queued message waits until you start it again.',
    );
    return '$_temp0';
  }

  @override
  String get systemStopBody =>
      'Hermes keeps running, and you can start llama-server again from here.';

  @override
  String get systemStopConfirm => 'Stop';

  @override
  String get systemRunStarted =>
      'A run just started. Check the queue and try again.';

  @override
  String systemStopFailed(String reason) {
    return 'Couldn\'t stop llama-server: $reason';
  }

  @override
  String systemStartFailed(String reason) {
    return 'Couldn\'t start llama-server: $reason';
  }

  @override
  String systemLoadFailed(String reason) {
    return 'Couldn\'t load the system view: $reason';
  }

  @override
  String get schedulesNew => 'New schedule';

  @override
  String get schedulesEmptyBody =>
      'A schedule sends a prompt to the agent at set times, in a new chat each time or always in the same one.';

  @override
  String get schedulesRunNow => 'Run now';

  @override
  String get schedulesPaused => 'Paused';

  @override
  String schedulesNextRun(String when) {
    return 'Next run $when';
  }

  @override
  String schedulesNextRunIn(String wait, String when) {
    return 'Next run in $wait · $when';
  }

  @override
  String schedulesLastRun(String when, String status) {
    return 'Last run $when · $status';
  }

  @override
  String get schedulesNotRunYet => 'Not run yet';

  @override
  String get schedulesStatusOk => 'OK';

  @override
  String get schedulesStatusFailed => 'Failed';

  @override
  String get schedulesStatusStopped => 'Stopped';

  @override
  String get schedulesStatusRunning => 'Running';

  @override
  String get schedulesStatusQueued => 'Queued';

  @override
  String schedulesToday(String time) {
    return 'today $time';
  }

  @override
  String schedulesTomorrow(String time) {
    return 'tomorrow $time';
  }

  @override
  String schedulesLoadFailed(String reason) {
    return 'Couldn\'t load schedules: $reason';
  }

  @override
  String schedulesSaveFailed(String reason) {
    return 'Couldn\'t save: $reason';
  }

  @override
  String schedulesRunFailed(String reason) {
    return 'Couldn\'t run it: $reason';
  }

  @override
  String get schedulesRunQueued => 'Queued — the answer arrives in its chat.';

  @override
  String get schedulesBriefWritten =>
      'Morning brief written — it\'s on the dashboard.';

  @override
  String schedulesEveryDay(String times) {
    return 'Every day at $times';
  }

  @override
  String schedulesWeekdays(String time) {
    return 'Weekdays at $time';
  }

  @override
  String schedulesWeekends(String time) {
    return 'Weekends at $time';
  }

  @override
  String schedulesEveryWeek(String day, String time) {
    return '${day}s at $time';
  }

  @override
  String schedulesOnDays(String days, String time) {
    return '$days at $time';
  }

  @override
  String schedulesListAnd(String head, String last) {
    return '$head and $last';
  }

  @override
  String get schedEditTitle => 'Edit schedule';

  @override
  String get schedNewTitle => 'New schedule';

  @override
  String get schedSave => 'Save';

  @override
  String get schedName => 'Name';

  @override
  String get schedRepeats => 'Repeats';

  @override
  String get schedDaily => 'Daily';

  @override
  String get schedWeekly => 'Weekly';

  @override
  String get schedCron => 'Cron';

  @override
  String get schedAddTime => 'Add time';

  @override
  String schedRemoveTime(String time) {
    return 'Remove $time';
  }

  @override
  String get schedSameMinute =>
      'Several times a day must share the minute past the hour (a cron limit). Use Cron for anything else.';

  @override
  String get schedNoTime => 'Add a time.';

  @override
  String get schedNoDay => 'Pick at least one day.';

  @override
  String get schedCronHelp =>
      'minute · hour · day · month · weekday, in Budapest time';

  @override
  String get schedCronInvalid => 'Five fields: minute hour day month weekday.';

  @override
  String get schedPrompt => 'Prompt';

  @override
  String get schedPostTo => 'Post results to';

  @override
  String get schedNewChat => 'New chat for each run';

  @override
  String get schedFixedChat => 'Fixed chat';

  @override
  String get schedPickChat => 'Pick a chat';

  @override
  String get schedNoChats => 'No chats yet. Start one first.';

  @override
  String get schedThinking => 'Thinking';

  @override
  String get schedThinkingSub => 'Off is faster for short, routine prompts';

  @override
  String get schedDelete => 'Delete schedule';

  @override
  String schedDeleteTitle(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get schedDeleteBody => 'Its past runs stay in their chats.';

  @override
  String get schedDeleteConfirm => 'Delete';

  @override
  String get schedBriefNote =>
      'The morning brief is written by the server without the model: uptime, package updates, open incidents, llama-server and the water level.';

  @override
  String get schedMissing => 'This schedule no longer exists.';

  @override
  String get schedErrInvalidCron => 'Not a valid cron expression.';

  @override
  String get schedErrTooFrequent =>
      'A schedule may run at most every 10 minutes.';

  @override
  String get schedErrName => 'Give it a name (at most 64 characters).';

  @override
  String get schedErrPrompt => 'Write a prompt.';

  @override
  String get schedErrChat => 'Pick a chat that still exists.';

  @override
  String get dashBriefTitle => 'Morning brief';

  @override
  String get dashBriefUptime => 'Uptime';

  @override
  String get dashBriefUpdates => 'Package updates';

  @override
  String get dashBriefIncidents => 'Open incidents';

  @override
  String get dashBriefLastBoot => 'Last boot';

  @override
  String dashBriefMissing(String sources) {
    return 'Not available this morning: $sources';
  }

  @override
  String notifyBriefTitle(String uptime) {
    return 'Morning brief · up $uptime';
  }

  @override
  String get notifyBriefTitlePlain => 'Morning brief';

  @override
  String notifyBriefUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count updates',
      one: '1 update',
      zero: 'no updates',
    );
    return '$_temp0';
  }

  @override
  String notifyBriefIncidents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open incidents',
      one: '1 open incident',
      zero: 'no open incidents',
    );
    return '$_temp0';
  }

  @override
  String notifyBriefLlama(String state) {
    return 'llama-server $state';
  }

  @override
  String notifyBriefWater(String level) {
    return 'water $level cm';
  }

  @override
  String get obsRange24h => '24 h';

  @override
  String get obsRange7d => '7 d';

  @override
  String get obsRange30d => '30 d';

  @override
  String get obsGeneration => 'Generation';

  @override
  String get obsPrefill => 'Prefill';

  @override
  String obsPrefillNote(int tokens) {
    return 'prompts ≥ $tokens tok';
  }

  @override
  String get obsQueue => 'Queue length';

  @override
  String get obsApprovalLatency => 'Approval latency';

  @override
  String get obsMedianPerHour => 'median per hour';

  @override
  String get obsMedianPer6h => 'median per 6 h';

  @override
  String get obsMedianPerDay => 'median per day';

  @override
  String get obsCacheHit => 'Cache hit ratio';

  @override
  String get obsTokensPerDay => 'Tokens per day';

  @override
  String obsLastDays(int days) {
    return 'last $days d';
  }

  @override
  String get obsGpuTemp => 'GPU temperature';

  @override
  String get obsGpuPower => 'GPU power';

  @override
  String obsTokPerS(String value) {
    return '$value tok/s';
  }

  @override
  String get obsNoRuns => 'No runs in this range';

  @override
  String get obsNoApprovals => 'No answered approvals';

  @override
  String get obsNoSamples => 'No GPU samples yet';

  @override
  String obsSamplingFailed(String reason) {
    return 'GPU sampling fails: $reason';
  }

  @override
  String get obsSamplingOff => 'GPU sampling is off on the server';

  @override
  String obsLoadFailed(String reason) {
    return 'Couldn\'t load the statistics: $reason';
  }

  @override
  String get shareTitle => 'Share to Delve';

  @override
  String get shareSendTo => 'Send to';

  @override
  String get shareExisting => 'Existing chats';

  @override
  String get shareNewChatThinkingOn =>
      'Thinking on · starts a new conversation';

  @override
  String get shareNewChatThinkingOff =>
      'Thinking off · starts a new conversation';

  @override
  String shareUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shared items could not be read',
      one: '1 shared item could not be read',
    );
    return '$_temp0';
  }
}
