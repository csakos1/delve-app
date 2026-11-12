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

  @override
  String dashBriefLate(String time, String late) {
    return '$time · $late late';
  }

  @override
  String dashWatchesActive(int count) {
    return '$count active';
  }

  @override
  String dashWatchesNext(String when) {
    return 'Next check $when';
  }

  @override
  String get dashWatchesTitle => 'Watches';

  @override
  String get linkOpenFailed => 'Couldn\'t open the link — it\'s copied';

  @override
  String get moreWatches => 'Watches';

  @override
  String get moreWatchesSub => 'Listings and tickets the agent checks for you';

  @override
  String notifyBriefLate(String late) {
    return '$late late';
  }

  @override
  String get notifyChannelWatches => 'Watches';

  @override
  String get notifyChannelWatchesDesc => 'When a watch finds something new';

  @override
  String get notifyOpenLink => 'Open link';

  @override
  String notifyWatchAvailable(String name) {
    return 'Now available · $name';
  }

  @override
  String notifyWatchTitle(String name) {
    return 'Watch · $name';
  }

  @override
  String get runFailedCutOff =>
      'The answer was cut off: the agent ran out of room. Try a new chat or a shorter request.';

  @override
  String get settingsNotifyWatches => 'Watch hits';

  @override
  String get settingsNotifyWatchesSub => 'When a watch finds something new';

  @override
  String watchActionFailed(String reason) {
    return 'Couldn\'t change the watch: $reason';
  }

  @override
  String watchChangeDraft(String name) {
    return 'Change the watch “$name”: ';
  }

  @override
  String get watchChangeInChat => 'Change in chat';

  @override
  String get watchCondition => 'Condition';

  @override
  String get watchCopyLink => 'Copy link';

  @override
  String get watchDetailsOn => 'On — opens each new listing';

  @override
  String get watchDetailsPages => 'Details pages';

  @override
  String watchErrorsInRow(int count) {
    return '$count errors in a row';
  }

  @override
  String watchEveryHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count hours',
      one: 'Every hour',
    );
    return '$_temp0';
  }

  @override
  String watchEveryMinutes(int count) {
    return 'Every $count minutes';
  }

  @override
  String get watchExampleCinema =>
      'Tell me when tickets for <film> are on sale at Cinema City.';

  @override
  String get watchExampleHardverapro =>
      'Watch Hardverapró for RTX 4070 Supers under 180 000 Ft, not used for mining, three times a day.';

  @override
  String watchFixDraft(String name, String error) {
    return 'The watch “$name” keeps failing ($error). Check it and fix it.';
  }

  @override
  String get watchFixInChat => 'Fix in chat';

  @override
  String get watchGone =>
      'This watch is gone: it was deleted in a chat, or the desktop no longer has it.';

  @override
  String get watchHint =>
      'Describe what to watch, where, how often, and what counts.';

  @override
  String watchHits(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hits · $count',
      zero: 'Hits',
    );
    return '$_temp0';
  }

  @override
  String watchHits24h(int count) {
    return '$count in the last 24 h';
  }

  @override
  String get watchItemAvailable => 'Now available';

  @override
  String get watchItemByFilters => 'Matched by filters · no judge';

  @override
  String get watchItemCouldntJudge => 'Couldn\'t judge';

  @override
  String get watchItemOnHold => 'On hold';

  @override
  String get watchItemWaiting => 'Waiting for judge';

  @override
  String get watchKeywords => 'Keywords';

  @override
  String watchKeywordsAny(String words) {
    return 'any of $words';
  }

  @override
  String watchKeywordsNot(String words) {
    return 'not $words';
  }

  @override
  String get watchLastCheck => 'Last check';

  @override
  String watchListings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count listings',
      one: '1 listing',
    );
    return '$_temp0';
  }

  @override
  String get watchLoadMore => 'Load more';

  @override
  String watchMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches',
      one: '1 match',
    );
    return '$_temp0';
  }

  @override
  String watchNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new',
      one: '1 new',
    );
    return '$_temp0';
  }

  @override
  String get watchNextCheck => 'Next check';

  @override
  String watchNextIn(String when, String wait) {
    return '$when · in $wait';
  }

  @override
  String get watchNextPaused => '— paused';

  @override
  String get watchNoCondition => 'No condition — filters only';

  @override
  String get watchNoHits => 'No hits yet.';

  @override
  String get watchNoHitsYet => 'No hits yet';

  @override
  String get watchOff => 'Off';

  @override
  String get watchOn => 'On';

  @override
  String get watchOpenLink => 'Open link';

  @override
  String get watchPause => 'Pause';

  @override
  String watchPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count listings wait for the judge',
      one: '1 listing waits for the judge',
    );
    return '$_temp0';
  }

  @override
  String get watchPrice => 'Price';

  @override
  String watchRejected(int count) {
    return 'Rejected ($count)';
  }

  @override
  String get watchResume => 'Resume';

  @override
  String get watchRunNow => 'Run now';

  @override
  String get watchRunStarted =>
      'Checking now — new hits show up here in a minute';

  @override
  String get watchSchedule => 'Schedule';

  @override
  String get watchSearch => 'Search';

  @override
  String get watchSource => 'Source';

  @override
  String get watchSourcePage => 'Web page';

  @override
  String get watchStateActive => 'Active';

  @override
  String get watchStateError => 'Error';

  @override
  String get watchStatePaused => 'Paused';

  @override
  String get watchStateStopped => 'Stopped after hit';

  @override
  String get watchStateUnknown => 'Setting up';

  @override
  String get watchStopAfterHit => 'Stop after hit';

  @override
  String watchStoppedAfterHit(String when) {
    return 'Paused after its first hit · $when';
  }

  @override
  String watchYesterday(String time) {
    return 'yesterday $time';
  }

  @override
  String get watchesEmptyBody =>
      'Watches are made in a chat: describe what to watch, where, how often and what counts. They run on a schedule without the model.';

  @override
  String get watchesEmptyTitle => 'No watches yet';

  @override
  String watchesLoadFailed(String reason) {
    return 'Couldn\'t load watches: $reason';
  }

  @override
  String get watchesNew => 'New watch';

  @override
  String get watchesNote =>
      'Watches run on a schedule without the model. New ones and changes are made in a chat.';

  @override
  String get navTerminal => 'Terminal';

  @override
  String get settingsTerminal => 'Terminal';

  @override
  String get termTitle => 'Terminal';

  @override
  String get termSetupSubtitle =>
      'Set up once · the key never leaves this phone';

  @override
  String get termStepKey => 'This phone\'s key';

  @override
  String get termStepKeyBody =>
      'Delve generated a key for this phone. Add this line to ~/.ssh/authorized_keys on the desktop.';

  @override
  String get termKeyLine => 'authorized_keys line';

  @override
  String get termKeyCommand => 'Or run this on the desktop';

  @override
  String get termStepHost => 'Host and port';

  @override
  String get termStepHostBody =>
      'From the paired server. Change them if sshd listens elsewhere.';

  @override
  String get termHost => 'Host';

  @override
  String get termUser => 'User';

  @override
  String get termPort => 'Port';

  @override
  String get termStepVerify => 'Verify the desktop';

  @override
  String get termStepVerifyBody =>
      'After Connect, compare the host key fingerprint.';

  @override
  String get termVerifyBody =>
      'Compare this with the desktop\'s key. If one group differs, cancel.';

  @override
  String get termVerifyCommand => 'On the desktop';

  @override
  String get termTrust => 'Trust and connect';

  @override
  String get termConnect => 'Connect';

  @override
  String get termConnecting => 'Connecting…';

  @override
  String get termReconnectingNow => 'Reconnecting…';

  @override
  String get termDenied =>
      'Permission denied – is the line in authorized_keys?';

  @override
  String get termCheckModes => '~/.ssh is 0700 and authorized_keys is 0600';

  @override
  String get termCheckTailnet =>
      'This phone is on the tailnet (Tailscale is on)';

  @override
  String get termCopyLine => 'Copy the line';

  @override
  String get termTryAgain => 'Try again';

  @override
  String get termNotTrusted =>
      'The desktop\'s key was not trusted. Connect again to check it.';

  @override
  String get termHostChangedLine => 'Host key changed – connection refused';

  @override
  String get termHostChangedTitle => 'Host key changed';

  @override
  String get termHostChangedBody =>
      'The desktop answered with a different key than the one you trusted. Someone may be in between, or the desktop\'s keys were replaced.';

  @override
  String get termShowDetails => 'Show details';

  @override
  String get termTrusted => 'Trusted';

  @override
  String get termReceived => 'Received';

  @override
  String get termForgetVerify => 'Forget and verify again';

  @override
  String get termNextNow => 'now';

  @override
  String get termOfflineUser => 'Disconnected – tap to reconnect';

  @override
  String get termOfflineEnded => 'Session ended – tap to start it again';

  @override
  String get termOfflineBackground =>
      'Paused in the background – tap to reconnect';

  @override
  String get termStateConnected => 'connected';

  @override
  String get termStateConnecting => 'connecting';

  @override
  String get termStateReconnecting => 'reconnecting';

  @override
  String get termStateDisconnected => 'disconnected';

  @override
  String get termStateRefused => 'refused';

  @override
  String get termMenu => 'Terminal menu';

  @override
  String get termMenuSettings => 'Terminal settings';

  @override
  String get termMenuDisconnect => 'Disconnect';

  @override
  String get termMenuReconnect => 'Reconnect';

  @override
  String get termMenuCopyTrace => 'Copy connection trace';

  @override
  String termTraceCopied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copied $count trace lines',
      one: 'Copied 1 trace line',
    );
    return '$_temp0';
  }

  @override
  String get termKeyCtrl => 'Control';

  @override
  String get termKeyAlt => 'Alt';

  @override
  String get termLockTitle => 'Unlock the terminal';

  @override
  String get termLockBody =>
      'Locked after 15 min of inactivity. Your session keeps running on the desktop.';

  @override
  String get termUnlock => 'Unlock';

  @override
  String get termUnlockReason => 'Unlock the Delve terminal';

  @override
  String get termSettingsConnection => 'Connection';

  @override
  String get termBackground => 'Keep connected in background';

  @override
  String get termBackgroundSub =>
      'The tab in front stays connected while Delve is in the background, so it is ready at once when you come back. Uses a little more battery; a quiet notification shows it.';

  @override
  String get termBackgroundNoStart =>
      'Android did not let the background connection start';

  @override
  String get termBackgroundBattery =>
      'Allow Delve to run without battery limits, or Android may still cut the connection';

  @override
  String get termHostPort => 'Host & port';

  @override
  String get termLockRow => 'Lock';

  @override
  String get termLockRowSub => 'After 15 min of inactivity';

  @override
  String get termDisplay => 'Display';

  @override
  String get termFontSize => 'Font size';

  @override
  String get termFontSmaller => 'Smaller';

  @override
  String get termFontBigger => 'Bigger';

  @override
  String get termPhoneKey => 'This phone\'s key';

  @override
  String get termShowLine => 'Show the authorized_keys line';

  @override
  String get termShowLineSub => 'To add on the desktop';

  @override
  String get termRegenerate => 'Regenerate key';

  @override
  String get termRegenerateSub => 'The old line stops working';

  @override
  String get termRegenerateTitle => 'Regenerate the key?';

  @override
  String get termRegenerateBody =>
      'The desktop refuses this phone until you add the new line to ~/.ssh/authorized_keys.';

  @override
  String get termRegenerateConfirm => 'Regenerate';

  @override
  String get termRegenerated => 'New key made – add its line on the desktop';

  @override
  String get termHostKey => 'Host key';

  @override
  String get termHostKeyNone => 'Not verified yet';

  @override
  String get termHostKeyTrustedUndated => 'Trusted';

  @override
  String get termForgetHostKey => 'Forget host key';

  @override
  String get termForgetHostKeyBody =>
      'The next connection shows the desktop\'s fingerprint again.';

  @override
  String get termForgetConfirm => 'Forget';

  @override
  String get termSave => 'Save';

  @override
  String settingsTerminalSub(int port) {
    return 'Background connection off · port $port';
  }

  @override
  String settingsTerminalSubOn(int port) {
    return 'Background connection on · port $port';
  }

  @override
  String termCheckLine(String user) {
    return 'The line is in ~/.ssh/authorized_keys of $user';
  }

  @override
  String termCheckPort(int port) {
    return 'sshd listens on $port (sudo sshd -T | grep -i port)';
  }

  @override
  String termFailed(String target, String detail) {
    return 'Can\'t reach $target: $detail';
  }

  @override
  String termFontSizeValue(int size) {
    return '$size sp';
  }

  @override
  String termHostKeyTrusted(String date) {
    return 'Trusted since $date';
  }

  @override
  String termKeyArmed(String key) {
    return '$key, armed';
  }

  @override
  String termKeyLocked(String key) {
    return '$key, locked';
  }

  @override
  String termNextIn(int seconds) {
    return 'next in $seconds s';
  }

  @override
  String termReconnecting(int attempt) {
    return 'Reconnecting · attempt $attempt';
  }

  @override
  String termUnlockFailed(String detail) {
    return 'Couldn\'t unlock: $detail';
  }

  @override
  String get termSelCopy => 'Copy';

  @override
  String get termSelSendToChat => 'Send to chat';

  @override
  String termSelCopied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copied $count lines',
      one: 'Copied 1 line',
    );
    return '$_temp0';
  }

  @override
  String get termSelStart => 'Selection start';

  @override
  String get termSelEnd => 'Selection end';

  @override
  String termPinchChip(int size, int columns, int rows) {
    return '$size sp · $columns × $rows';
  }

  @override
  String termTabSemantics(String name, int index, int count, String state) {
    return '$name, tab $index of $count, $state';
  }

  @override
  String termTabTooltip(String name, String state, int columns, int rows) {
    return '$name · $state · $columns × $rows';
  }

  @override
  String get termTabRename => 'Rename';

  @override
  String get termTabClose => 'Close tab';

  @override
  String get termTabKill => 'Kill session…';

  @override
  String get termNewTab => 'New tab';

  @override
  String termMenuSessions(String host) {
    return 'Sessions on $host';
  }

  @override
  String termSessionsTitle(String host) {
    return 'Sessions on $host';
  }

  @override
  String termSessionsSummary(int count, int open) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tmux · $count sessions · $open open here',
      one: 'tmux · 1 session · $open open here',
    );
    return '$_temp0';
  }

  @override
  String get termSessionsNew => 'New session';

  @override
  String get termSessionsNewSub =>
      'Starts tmux on the desktop and opens it here';

  @override
  String get termSessionTag => 'tab';

  @override
  String get termSessionAttachedHere => 'Attached here';

  @override
  String get termSessionAttachedBoth => 'Attached here and on the desktop';

  @override
  String get termSessionAttachedDesktop => 'Attached on the desktop';

  @override
  String get termSessionDetached => 'Detached';

  @override
  String termSessionWindows(int windows) {
    String _temp0 = intl.Intl.pluralLogic(
      windows,
      locale: localeName,
      other: '$windows windows',
      one: '1 window',
    );
    return '$_temp0';
  }

  @override
  String termSessionMeta(int windows, String age) {
    String _temp0 = intl.Intl.pluralLogic(
      windows,
      locale: localeName,
      other: '$windows windows · created $age ago',
      one: '1 window · created $age ago',
    );
    return '$_temp0';
  }

  @override
  String get termSessionOpen => 'Open as tab';

  @override
  String get termSessionsEmpty => 'No tmux sessions on the desktop.';

  @override
  String termSessionsFailed(String detail) {
    return 'Couldn\'t reach tmux on the desktop: $detail';
  }

  @override
  String termTmuxFailed(String detail) {
    return 'tmux said: $detail';
  }

  @override
  String get termSessionsButton => 'Sessions';

  @override
  String get termRenameTitle => 'Rename session';

  @override
  String get termRenameLabel => 'Session name';

  @override
  String get termRenameHint => 'Letters, digits, - and _ (up to 32)';

  @override
  String get termRenameInvalid => 'Only letters, digits, - and _ (up to 32)';

  @override
  String get termRenameSave => 'Rename';

  @override
  String termKillTitle(String name) {
    return 'Kill “$name”?';
  }

  @override
  String get termKillBody =>
      'Every window in it, and whatever runs there, stops on the desktop. This can\'t be undone.';

  @override
  String get termKill => 'Kill';

  @override
  String get termNoTabsTitle => 'No tabs open';

  @override
  String get termNoTabsBody =>
      'Your tmux sessions keep running on the desktop. Open one here, or start a new one.';

  @override
  String get navFiles => 'Files';

  @override
  String get filesQuickHome => 'Home';

  @override
  String get filesQuickDownloads => 'Downloads';

  @override
  String get filesQuickDocuments => 'Documents';

  @override
  String filesItems(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$n items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String filesShownHidden(String shown, String hidden) {
    return '$shown shown · $hidden hidden';
  }

  @override
  String filesUsedPct(int pct) {
    return '$pct % used';
  }

  @override
  String filesLinkTo(String target) {
    return 'link → $target';
  }

  @override
  String filesBrokenLink(String target) {
    return 'broken link → $target';
  }

  @override
  String filesDeniedRow(String owner) {
    return 'Permission denied · $owner';
  }

  @override
  String get filesSortName => 'Name';

  @override
  String get filesSortSize => 'Size';

  @override
  String get filesSortDate => 'Date modified';

  @override
  String get filesMenuHidden => 'Show hidden files';

  @override
  String get filesMenuSortBy => 'Sort by';

  @override
  String get filesMenuRefresh => 'Refresh';

  @override
  String get filesActOpen => 'Open';

  @override
  String get filesActDownload => 'Download';

  @override
  String filesActDownloadHint(String folder) {
    return 'To $folder';
  }

  @override
  String get filesActPreview => 'Preview';

  @override
  String get filesActGoToTarget => 'Go to target';

  @override
  String get filesActCopyPath => 'Copy path';

  @override
  String get filesPathCopied => 'Path copied';

  @override
  String get filesEmptyTitle => 'This folder is empty';

  @override
  String filesEmptyHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hidden items',
      one: '1 hidden item',
    );
    return '$_temp0';
  }

  @override
  String get filesDeniedTitle => 'Permission denied';

  @override
  String filesDeniedOwned(String owner, String mode) {
    return ' belongs to $owner ($mode). Files never uses sudo.';
  }

  @override
  String get filesDeniedPlain =>
      ' can\'t be opened as your user. Files never uses sudo.';

  @override
  String get filesGoRoot => 'Go to /';

  @override
  String get filesGoHome => 'Go to home folder';

  @override
  String get filesNotFoundTitle => 'Folder not found';

  @override
  String get filesErrorTitle => 'Couldn\'t open this folder';

  @override
  String get filesRetry => 'Retry';

  @override
  String filesReconnecting(int n) {
    return 'Reconnecting · attempt $n';
  }

  @override
  String filesNextIn(int s) {
    return 'next in $s s';
  }

  @override
  String get filesNotSetUpTitle => 'Set up the terminal first';

  @override
  String get filesNotSetUpBody =>
      'Files uses the terminal\'s connection to your desktop: this phone\'s key, the host and the trusted host key.';

  @override
  String get filesOpenTerminal => 'Open Terminal';

  @override
  String get filesHostKeyTitle => 'The desktop\'s host key changed';

  @override
  String get filesHostKeyBody =>
      'Files won\'t connect until the terminal trusts the desktop again. The Terminal tab shows the details.';

  @override
  String get filesKeyDeniedTitle => 'The desktop refused this phone\'s key';

  @override
  String get filesKeyDeniedBody =>
      'Check that the key line is still in authorized_keys (Terminal settings show it).';

  @override
  String get filesLockTitle => 'Unlock Files';

  @override
  String get filesLockBody =>
      'Locked after 15 min of inactivity. One unlock opens Files and the Terminal.';

  @override
  String get filesUnlockReason => 'Unlock Delve Files';

  @override
  String get filesTransfers => 'Transfers';

  @override
  String filesTransferChip(int n, int total) {
    return '$n of $total';
  }

  @override
  String filesTransfersSummary(int active, int done) {
    return '$active running · $done done';
  }

  @override
  String get filesClearFinished => 'Clear finished';

  @override
  String get filesTransferQueued => 'Queued';

  @override
  String get filesTransferDone => 'Done';

  @override
  String get filesTransferFailed => 'Failed';

  @override
  String get filesTransferCancelled => 'Cancelled';

  @override
  String filesTransferOf(String done, String total) {
    return '$done of $total';
  }

  @override
  String get filesTransferInDownloads => 'in Downloads/Delve';

  @override
  String get filesTransferCancel => 'Cancel';

  @override
  String get filesTransferRetry => 'Retry';

  @override
  String get filesOpen => 'Open';

  @override
  String filesSaved(String folder) {
    return 'Saved to $folder';
  }

  @override
  String get filesNoApp => 'No app on this phone opens this file';

  @override
  String filesDownloadFailed(String name, String reason) {
    return 'Couldn\'t download $name: $reason';
  }

  @override
  String filesDownloadQueued(String folder) {
    return 'Downloading to $folder';
  }

  @override
  String get filesLineNumbers => 'Line numbers';

  @override
  String get filesPreviewFailed => 'Couldn\'t read the file';

  @override
  String get filesPreviewTooBig => 'Too big to preview here';

  @override
  String get filesPreviewBinary => 'Not a text file';

  @override
  String get filesPreviewBinaryBody => 'Download it to open it in another app.';

  @override
  String get filesPreviewCut => 'Read-only · the first 1 MB';

  @override
  String filesPreviewInfo(int lines) {
    String _temp0 = intl.Intl.pluralLogic(
      lines,
      locale: localeName,
      other: 'Read-only · $lines lines · UTF-8',
      one: 'Read-only · 1 line · UTF-8',
    );
    return '$_temp0';
  }

  @override
  String filesPreviewPosition(int index, int count) {
    return '$index / $count';
  }

  @override
  String filesPdfPage(int page, int count) {
    return 'Page $page / $count';
  }

  @override
  String get filesPdfLocked => 'Password-protected PDF';

  @override
  String get filesPdfLockedBody =>
      'The phone\'s viewer can\'t open PDFs with a password. Download it and open it in another app.';

  @override
  String get filesPdfBroken => 'Can\'t read this PDF';

  @override
  String get filesPdfBrokenBody =>
      'It may be damaged, or not really a PDF. Download it to try another app.';

  @override
  String get filesUpload => 'Upload';

  @override
  String filesUploadTo(String folder) {
    return 'Upload to $folder';
  }

  @override
  String get filesUploadPhotosHint => 'From the gallery';

  @override
  String get filesUploadCameraHint => 'Take a photo';

  @override
  String get filesUploadFiles => 'Files';

  @override
  String get filesUploadFilesHint => 'Phone storage, Drive…';

  @override
  String filesUploaded(String folder) {
    return 'Uploaded to $folder';
  }

  @override
  String filesUploadFailed(String reason) {
    return 'Couldn\'t upload: $reason';
  }

  @override
  String filesUploadFailedFile(String name, String reason) {
    return 'Couldn\'t upload $name: $reason';
  }

  @override
  String get filesShowFolder => 'Show folder';

  @override
  String get filesNewFolder => 'New folder';

  @override
  String get filesCreate => 'Create';

  @override
  String get filesRename => 'Rename';

  @override
  String get filesRenameAction => 'Rename';

  @override
  String get filesNameEmpty => 'Enter a name';

  @override
  String get filesNameDots => '“.” and “..” can\'t be names';

  @override
  String get filesNameSlash => 'A name can\'t contain /';

  @override
  String get filesNameTooLong => 'Too long: 255 bytes at most';

  @override
  String filesNameTaken(String name) {
    return '$name already exists here';
  }

  @override
  String get filesWriteDenied => 'Permission denied (Files never uses sudo)';

  @override
  String get filesWriteOffline => 'No connection to the desktop';

  @override
  String get filesFolder => 'Folder';

  @override
  String get filesConflictTitle => ' already exists here';

  @override
  String get filesConflictHere => 'Here';

  @override
  String get filesConflictIncoming => 'New';

  @override
  String get filesConflictSkip => 'Skip';

  @override
  String get filesConflictSkipHint => 'Keep the one here, leave this one out';

  @override
  String get filesConflictReplace => 'Replace';

  @override
  String get filesConflictReplaceHint =>
      'The one here goes to the desktop\'s trash';

  @override
  String get filesConflictReplaceFolder => 'A folder is never replaced';

  @override
  String get filesConflictKeepBoth => 'Keep both';

  @override
  String filesConflictKeepBothHint(String name) {
    return 'Saves as $name';
  }

  @override
  String filesConflictAll(int count) {
    return 'Apply to all $count conflicts';
  }

  @override
  String get filesConflictCancelUpload => 'Cancel upload';

  @override
  String get filesActTrash => 'Move to trash';

  @override
  String get filesActDeleteForever => 'Delete permanently…';

  @override
  String filesTrashed(String name) {
    return '$name moved to the trash';
  }

  @override
  String get filesUndo => 'Undo';

  @override
  String filesTrashFailed(String reason) {
    return 'Couldn\'t move to the trash: $reason';
  }

  @override
  String get filesDeleteForeverTitle => 'Delete permanently?';

  @override
  String get filesDeleteForever => 'Delete permanently';

  @override
  String get filesNoTrashBody =>
      'Only your home folder has a trash. Files outside it are deleted at once, and this can\'t be undone.';

  @override
  String get filesNoTrashOtherFs =>
      'This is on another filesystem than your home folder\'s trash, so it can\'t go there. It is deleted at once, and this can\'t be undone.';

  @override
  String filesDeleted(String name) {
    return '$name deleted';
  }

  @override
  String filesDeleteFailed(String reason) {
    return 'Couldn\'t delete: $reason';
  }

  @override
  String get filesTrash => 'Trash';

  @override
  String filesTrashCount(int count) {
    return 'Trash ($count)';
  }

  @override
  String get trashShared => 'shared with the desktop\'s file managers';

  @override
  String get trashNoneTitle => 'The trash is empty';

  @override
  String get trashNoneBody =>
      'The desktop\'s file managers use the same trash.';

  @override
  String get trashErrorTitle => 'Couldn\'t read the trash';

  @override
  String trashDeletedAt(String time) {
    return 'Deleted $time';
  }

  @override
  String get trashRestore => 'Restore';

  @override
  String trashRestoreTo(String folder) {
    return 'Restore to $folder';
  }

  @override
  String trashRestored(String name, String folder) {
    return '$name restored to $folder';
  }

  @override
  String trashRestoreFailed(String reason) {
    return 'Couldn\'t restore: $reason';
  }

  @override
  String get trashDeleteBody =>
      'It is deleted from the desktop\'s trash for good. This can\'t be undone.';

  @override
  String get trashEmpty => 'Empty trash';

  @override
  String get trashEmptyTitle => 'Empty the trash?';

  @override
  String get trashEmptyBody =>
      'Everything in the desktop\'s trash is deleted for good, also what was deleted on the desktop. This can\'t be undone.';

  @override
  String trashEmptySure(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'I understand these $count items will be gone for good',
      one: 'I understand this item will be gone for good',
    );
    return '$_temp0';
  }

  @override
  String get trashEmptied => 'Trash emptied';

  @override
  String get saveTitle => 'Save to desktop folder';

  @override
  String saveFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String get saveHere => 'Save here';

  @override
  String get shareSaveSection => 'Save to the desktop';

  @override
  String get shareSaveToDesktop => 'Save to desktop folder';

  @override
  String get shareSaveNotSetUp => 'Set up the terminal first';

  @override
  String get shareSaveNoFiles => 'Only photos and files can be saved';

  @override
  String get shareSaveChoose => 'Choose a folder on the desktop';

  @override
  String shareSaveLast(String folder) {
    return 'Choose a folder · last used $folder';
  }

  @override
  String get editorEdit => 'Edit';

  @override
  String get editorEditTooBig => 'Over 1 MB – download it';

  @override
  String get editorSave => 'Save';

  @override
  String get editorSaving => 'Saving…';

  @override
  String get editorUndo => 'Undo';

  @override
  String get editorRedo => 'Redo';

  @override
  String get editorMore => 'More';

  @override
  String get editorWrap => 'Wrap lines';

  @override
  String get editorFindLater => 'Find · later';

  @override
  String get editorReload => 'Reload from desktop';

  @override
  String editorReloadFailed(String reason) {
    return 'Couldn\'t reload: $reason';
  }

  @override
  String get editorDiscardChanges => 'Discard changes';

  @override
  String get editorEdited => 'Edited';

  @override
  String editorUnsaved(String name) {
    return '$name, unsaved changes';
  }

  @override
  String get editorStatusEditing => 'Editing';

  @override
  String editorStatusSaved(String time) {
    return 'Saved $time';
  }

  @override
  String get editorStatusNotSaved => 'Not saved';

  @override
  String get editorStatusOffline => 'Offline · Save is back when connected';

  @override
  String editorPosition(int line, int col) {
    return 'Ln $line, Col $col';
  }

  @override
  String editorLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lines',
      one: '1 line',
    );
    return '$_temp0';
  }

  @override
  String editorChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lines changed',
      one: '1 line changed',
    );
    return '$_temp0';
  }

  @override
  String get editorSaved => 'Saved to the desktop';

  @override
  String editorSaveFailed(String reason) {
    return 'Not saved: $reason';
  }

  @override
  String get editorBlockTooBig => 'Over 1 MB: shown in part, not editable';

  @override
  String get editorBlockNotText => 'Not UTF-8 text: not editable';

  @override
  String editorBlockReadOnly(String user) {
    return 'Read-only for $user';
  }

  @override
  String editorInfoNotText(int lines) {
    String _temp0 = intl.Intl.pluralLogic(
      lines,
      locale: localeName,
      other: 'Read-only · $lines lines · not UTF-8',
      one: 'Read-only · 1 line · not UTF-8',
    );
    return '$_temp0';
  }

  @override
  String get editorOpenInTerminal => 'Open in terminal';

  @override
  String editorDenied(String user, String folder) {
    return '$folder doesn\'t let $user save here';
  }

  @override
  String get editorSaveCopy => 'Save a copy to ~';

  @override
  String get editorCopyAll => 'Copy all';

  @override
  String get editorCopied => 'Copied the whole file';

  @override
  String editorCopySaved(String path) {
    return 'Copy saved as $path';
  }

  @override
  String get editorConflictTitle => ' changed on the desktop';

  @override
  String get editorConflictDesktop => 'On the desktop';

  @override
  String get editorConflictOpened => 'When you opened it';

  @override
  String get editorConflictYours => 'Your edit';

  @override
  String get editorConflictDeleted => 'deleted';

  @override
  String get editorOverwrite => 'Overwrite';

  @override
  String get editorOverwriteHint =>
      'Save your edit over the desktop\'s version';

  @override
  String editorReloadHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Load the desktop\'s version · $count changed lines lost',
      one: 'Load the desktop\'s version · 1 changed line lost',
      zero: 'Load the desktop\'s version',
    );
    return '$_temp0';
  }

  @override
  String get editorDiscardTitle => 'Discard changes?';

  @override
  String editorDiscardBody(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changed lines in $name are not saved to the desktop.',
      one: '1 changed line in $name is not saved to the desktop.',
    );
    return '$_temp0';
  }

  @override
  String get editorDiscardAction => 'Discard';

  @override
  String get editorKeepEditing => 'Keep editing';

  @override
  String get editorDone => 'Done';

  @override
  String get editorLockedBody => 'Your edit is kept. Unlock to go on.';

  @override
  String get editorKeyTab => 'Tab, 4 spaces';

  @override
  String get editorKeyLeft => 'Left';

  @override
  String get editorKeyRight => 'Right';

  @override
  String get editorKeyUp => 'Up';

  @override
  String get editorKeyDown => 'Down';

  @override
  String get editorKeyHome => 'Line start';

  @override
  String get editorKeyEnd => 'Line end';

  @override
  String get filesActCopy => 'Copy';

  @override
  String get filesActMove => 'Move';

  @override
  String filesActDownloadFolderHint(String folder) {
    return 'To $folder, with its folders';
  }

  @override
  String filesSelected(int count) {
    return '$count selected';
  }

  @override
  String filesSelectedOf(int count, int total) {
    return '$count of $total selected';
  }

  @override
  String get filesSelectAll => 'Select all';

  @override
  String get filesCopyPaths => 'Copy paths';

  @override
  String filesPathsCopied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paths copied',
      one: 'Path copied',
    );
    return '$_temp0';
  }

  @override
  String get filesPaste => 'Paste';

  @override
  String filesPasteCopyTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copy $count items here',
      one: 'Copy 1 item here',
    );
    return '$_temp0';
  }

  @override
  String filesPasteMoveTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Move $count items here',
      one: 'Move 1 item here',
    );
    return '$_temp0';
  }

  @override
  String filesPasteFrom(String folder) {
    return 'from $folder';
  }

  @override
  String get filesPasteSameFolder =>
      'Already in this folder – open another one';

  @override
  String get filesPasteIntoItself =>
      'Can\'t go into itself – open another folder';

  @override
  String filesPasteFailed(String reason) {
    return 'Couldn\'t paste: $reason';
  }

  @override
  String get filesConflictCancelPaste => 'Cancel paste';

  @override
  String filesMovedHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Moved $count items here',
      one: 'Moved 1 item here',
    );
    return '$_temp0';
  }

  @override
  String filesMoveFailed(String name, String reason) {
    return 'Couldn\'t move $name: $reason';
  }

  @override
  String filesCopiedTo(String folder) {
    return 'Copied to $folder';
  }

  @override
  String filesMovedTo(String folder) {
    return 'Moved to $folder';
  }

  @override
  String filesMovedSourceKept(String folder, String reason) {
    return 'Copied to $folder, but the original stayed: $reason';
  }

  @override
  String filesCopyFailed(String name, String reason) {
    return 'Couldn\'t copy $name: $reason';
  }

  @override
  String filesTrashedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items moved to the trash',
      one: '1 item moved to the trash',
    );
    return '$_temp0';
  }

  @override
  String filesTrashFailedName(String name, String reason) {
    return 'Couldn\'t move $name to the trash: $reason';
  }

  @override
  String filesDeletedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items deleted',
      one: '1 item deleted',
    );
    return '$_temp0';
  }

  @override
  String filesDeleteFailedName(String name, String reason) {
    return 'Couldn\'t delete $name: $reason';
  }

  @override
  String get filesTransferReading => 'Reading';

  @override
  String filesTransferFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files found',
      one: '1 file found',
    );
    return '$_temp0';
  }

  @override
  String filesTransferFiles(int done, int total) {
    return '$done of $total files';
  }

  @override
  String filesTransferFilesDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String filesTransferUnreadable(int count) {
    return '$count unreadable';
  }

  @override
  String filesTransferLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count links left out',
      one: '1 link left out',
    );
    return '$_temp0';
  }

  @override
  String filesNoticeDownloading(String name) {
    return 'Downloading $name';
  }

  @override
  String filesNoticeUploading(String name) {
    return 'Uploading $name';
  }

  @override
  String filesNoticeCopying(String name) {
    return 'Copying $name';
  }

  @override
  String filesNoticeMoving(String name) {
    return 'Moving $name';
  }

  @override
  String get filesNoticeWaiting => 'Waiting for the desktop';

  @override
  String filesNoticeQueued(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transfers queued',
      one: '1 transfer queued',
    );
    return '$_temp0';
  }

  @override
  String get filesNoticeCancelAll => 'Cancel all';

  @override
  String get filesNoticeFinished => 'Transfers finished';

  @override
  String get filesNoticeAllFailed => 'Transfers failed';

  @override
  String filesNoticeDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transfers done',
      one: '1 transfer done',
    );
    return '$_temp0';
  }

  @override
  String filesNoticeFailed(int count) {
    return '$count failed';
  }

  @override
  String filesNoticeItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get chatsFilterAll => 'All';

  @override
  String get chatsFilterAgent => 'Agent';

  @override
  String get chatsFilterGeneral => 'General';

  @override
  String chatsFilterLabel(String kind) {
    return 'Show $kind chats';
  }

  @override
  String generalMarker(String model) {
    return 'General · $model';
  }

  @override
  String get chatsGeneralEmpty => 'No General chats yet';

  @override
  String get chatsGeneralWorks => 'General chats work as usual.';

  @override
  String get newChatAgent => 'Agent';

  @override
  String get newChatAgentSub =>
      'Local model on your desktop\nTools, files and memory';

  @override
  String get newChatGeneral => 'General';

  @override
  String get newChatGeneralSub =>
      'Cloud models via OpenRouter\nStraight from this phone';

  @override
  String get generalIntroVia => 'via OpenRouter · straight from this phone';

  @override
  String get generalIntroShield =>
      'Zero data retention · nothing from your desktop';

  @override
  String get generalNoKeyTitle => 'Chat with cloud models';

  @override
  String get generalNoKeyBody =>
      'Add an OpenRouter key to chat with cloud models straight from this phone.\nNothing from your desktop is sent.';

  @override
  String get generalAddKey => 'Add an OpenRouter key';

  @override
  String generalComposerHint(String model) {
    return 'Message $model…';
  }

  @override
  String get generalPickModel => 'Pick a model';

  @override
  String generalModelChipSemantics(String model, int percent) {
    return 'Model $model, context $percent percent, change model';
  }

  @override
  String generalModelChipEmpty(String model) {
    return 'Model $model, change model';
  }

  @override
  String get generalMenu => 'Chat options';

  @override
  String get generalMenuEffort => 'Thinking effort';

  @override
  String get generalMenuRename => 'Rename';

  @override
  String get generalMenuArchive => 'Archive';

  @override
  String get generalMenuDelete => 'Delete';

  @override
  String get generalRenameTitle => 'Rename chat';

  @override
  String get generalRenameSave => 'Save';

  @override
  String get generalDeleteTitle => 'Delete this chat?';

  @override
  String get generalDeleteBody =>
      'Its messages and images are removed from this phone. This can\'t be undone.';

  @override
  String get generalDeleted => 'Chat deleted';

  @override
  String generalSwitched(String model, String time) {
    return 'Switched to $model · $time';
  }

  @override
  String get generalWriting => 'writing';

  @override
  String get generalStopped => 'Stopped';

  @override
  String get generalFailed => 'Failed';

  @override
  String generalTokens(String count) {
    return '$count tok';
  }

  @override
  String generalAlwaysThinks(String model) {
    return '$model always thinks';
  }

  @override
  String generalThinkingEffort(String effort) {
    return 'Thinking · $effort';
  }

  @override
  String get generalEffortTitle => 'Thinking effort';

  @override
  String generalEffortSub(String model) {
    return 'for $model · applies to your next message';
  }

  @override
  String generalEffortDefault(String effort) {
    return 'Model default ($effort)';
  }

  @override
  String get generalEffortDefaultPlain => 'Model default';

  @override
  String get generalEffortHint => 'Long-press for the effort';

  @override
  String get effortMinimal => 'Minimal';

  @override
  String get effortLow => 'Low';

  @override
  String get effortMedium => 'Medium';

  @override
  String get effortHigh => 'High';

  @override
  String get effortXhigh => 'Extra high';

  @override
  String get effortMax => 'Max';

  @override
  String get generalErrKey => 'OpenRouter rejected the key';

  @override
  String get generalErrLimit => 'Key limit reached';

  @override
  String get generalErrNoProvider =>
      'No zero-retention provider for this model';

  @override
  String generalErrRate(int seconds) {
    return 'Rate limited — try again in $seconds s';
  }

  @override
  String get generalErrRateNow => 'Rate limited — try again';

  @override
  String get generalErrNetwork => 'Couldn’t reach OpenRouter';

  @override
  String get generalErrBadRequest => 'OpenRouter refused the request';

  @override
  String get generalErrUpstream => 'The model’s provider failed';

  @override
  String get generalErrUnknown => 'The answer failed';

  @override
  String get generalOpenSettings => 'Open settings';

  @override
  String get generalPickAnother => 'Pick another model';

  @override
  String generalNoImages(String model, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count earlier images won’t',
      one: '1 earlier image won’t',
    );
    return '$model doesn’t read images — $_temp0 be sent';
  }

  @override
  String generalProviderWarning(String provider) {
    return 'Served by $provider, not on the zero-retention list. Nothing more is sent until you acknowledge it.';
  }

  @override
  String get generalAcknowledge => 'OK';

  @override
  String generalNotSent(String reason) {
    return 'Not sent: $reason';
  }

  @override
  String get generalNoKeyShort => 'No OpenRouter key';

  @override
  String generalModelsFailed(String reason) {
    return 'Couldn\'t load the models: $reason';
  }

  @override
  String get pickerTitle => 'Model';

  @override
  String pickerSub(String chat) {
    return 'for $chat · per 1M tokens in / out';
  }

  @override
  String get pickerSubDefault =>
      'default for new chats · per 1M tokens in / out';

  @override
  String pickerSearch(int count) {
    return 'Search $count models';
  }

  @override
  String get pickerFavourites => 'Favourites';

  @override
  String get pickerAll => 'All models · A–Z';

  @override
  String pickerUpdated(String ago) {
    return 'Updated $ago ago · pull to refresh';
  }

  @override
  String get pickerNever => 'Not loaded yet · pull to refresh';

  @override
  String get pickerNoZdr => 'No zero-retention provider';

  @override
  String pickerNoMatch(String query) {
    return 'No model matches “$query”';
  }

  @override
  String get pickerEmpty => 'The model list isn\'t loaded yet.';

  @override
  String get pickerLoad => 'Load models';

  @override
  String pickerAddFavourite(String model) {
    return 'Add $model to favourites';
  }

  @override
  String pickerRemoveFavourite(String model) {
    return 'Remove $model from favourites';
  }

  @override
  String get pickerReadsImages => 'Reads images';

  @override
  String get pickerThinks => 'Can think';

  @override
  String get pickerAlwaysThinks => 'Always thinks';

  @override
  String get generalAddTitle => 'Add to message';

  @override
  String get generalImagesOnly => 'Only images can be added to a General chat';

  @override
  String generalNoImageInput(String model) {
    return '$model doesn’t read images';
  }

  @override
  String get generalSwitchModel => 'Switch model';

  @override
  String generalImage(int index) {
    return 'Image $index';
  }

  @override
  String get settingsGeneralSection => 'General chat';

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsGeneralNoKey => 'OpenRouter · no key yet';

  @override
  String settingsGeneralSub(String model) {
    return 'OpenRouter · $model';
  }

  @override
  String get generalSettingsKey => 'OpenRouter key';

  @override
  String get generalKeyPaste => 'Paste an OpenRouter key';

  @override
  String get generalKeyPasteAction => 'Paste';

  @override
  String get generalKeyHelper =>
      'Create a separate key for this phone with a monthly limit at openrouter.ai/keys';

  @override
  String get generalKeySave => 'Save';

  @override
  String get generalKeyReplace => 'Replace';

  @override
  String get generalKeyRemove => 'Remove';

  @override
  String get generalKeyRemoveTitle => 'Remove the key?';

  @override
  String get generalKeyRemoveBody =>
      'General chats stay on this phone. Nothing can be sent until you add a key again.';

  @override
  String get generalKeyRejected => 'OpenRouter rejected this key';

  @override
  String get generalKeyNotKey => 'This doesn\'t look like an OpenRouter key';

  @override
  String get generalKeySaved => 'Key saved';

  @override
  String get generalKeySavedUnchecked =>
      'Key saved — OpenRouter couldn\'t be reached to check it';

  @override
  String generalKeySpend(String used, String limit) {
    return '$used of $limit';
  }

  @override
  String generalKeySpendNoLimit(String used) {
    return '$used spent · no limit';
  }

  @override
  String generalKeyResets(String date) {
    return 'Resets $date';
  }

  @override
  String get generalKeyPeriodMonthly => 'this month';

  @override
  String get generalKeyPeriodWeekly => 'this week';

  @override
  String get generalKeyPeriodDaily => 'today';

  @override
  String get generalKeyNoReset =>
      'This key\'s limit never resets. A monthly limit keeps a leaked key cheap: set one at openrouter.ai/keys.';

  @override
  String generalKeyInfoFailed(String reason) {
    return 'Couldn\'t read the key\'s limits: $reason';
  }

  @override
  String get generalSettingsModels => 'Models';

  @override
  String get generalDefaultModel => 'Default model';

  @override
  String get generalShowTokens => 'Show tokens under answers';

  @override
  String get generalShowTokensSub => 'Output tokens next to the model and cost';

  @override
  String get generalPrivacyNote =>
      'Requests go straight from this phone to OpenRouter. Zero data retention and no training are required on every request. Nothing from your desktop is sent.';

  @override
  String get generalMenuUsage => 'Usage';

  @override
  String get generalUsageCost => 'Cost';

  @override
  String get generalUsageAnswersTile => 'Answers';

  @override
  String get generalUsageContext => 'Context of the last answer';

  @override
  String get generalUsageByModel => 'By model';

  @override
  String get generalUsageNoAnswers => 'No answers yet.';

  @override
  String generalUsageAnswers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count answers',
      one: '1 answer',
    );
    return '$_temp0';
  }

  @override
  String generalUsageResets(String date) {
    return 'resets $date';
  }

  @override
  String get generalFavAdd => 'Add';

  @override
  String get generalFavEmpty =>
      'No favourites. Add one here or star a model in the picker.';

  @override
  String generalFavRemoved(String model) {
    return '$model removed from favourites';
  }

  @override
  String get pickerSubFavourite => 'add to favourites · per 1M tokens in / out';

  @override
  String get generalSettingsPrompt => 'System prompt';

  @override
  String get generalPromptHint => 'Empty';

  @override
  String get generalPromptHelper =>
      'Sent with every General message. Empty by default.';

  @override
  String get generalSettingsChats => 'Chats on this phone';

  @override
  String get generalExport => 'Export chats';

  @override
  String get generalExportSub =>
      'One .zip with chats, images and settings · never the key';

  @override
  String generalExportDone(int count, String folder) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Exported $count chats to $folder',
      one: 'Exported 1 chat to $folder',
    );
    return '$_temp0';
  }

  @override
  String get generalExportShare => 'Share';

  @override
  String generalExportFailed(String error) {
    return 'Couldn\'t export: $error';
  }

  @override
  String get generalImport => 'Import chats';

  @override
  String get generalImportSub =>
      'Adds the chats of a Delve export · the newer version of a chat wins';

  @override
  String generalImportChats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Imported $count chats',
      one: 'Imported 1 chat',
    );
    return '$_temp0';
  }

  @override
  String generalImportImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count images',
      one: '1 image',
    );
    return '$_temp0';
  }

  @override
  String generalImportResult(
    String chats,
    int created,
    int updated,
    String images,
  ) {
    return '$chats — $created new, $updated updated, $images';
  }

  @override
  String get generalImportOk => 'OK';

  @override
  String get generalImportNotExport => 'This file isn\'t a Delve export';

  @override
  String get generalImportTooNew =>
      'This export is from a newer version of Delve. Update the app to import it.';

  @override
  String get generalImportDamaged =>
      'This export is damaged — nothing was imported.';

  @override
  String get generalImportPickAnother => 'Pick another file';

  @override
  String generalImportFailed(String error) {
    return 'Couldn\'t import: $error';
  }

  @override
  String get systemStateSwitching => 'switching';

  @override
  String get modelLoadsOnStart => 'loads on Start';

  @override
  String get modelPickerTitle => 'Local models';

  @override
  String get modelPickerSubtitle => 'One model is loaded at a time.';

  @override
  String get modelPickerStopped =>
      'llama-server is stopped. Start loads the model you pick.';

  @override
  String modelPickerFooter(String path) {
    return 'Presets live on the desktop in $path.';
  }

  @override
  String get modelReasonContext => 'Needs 65,536 tok of context for the agent';

  @override
  String get modelReasonMissing => 'Model file not found';

  @override
  String get modelReasonProjector => 'Image projector file not found';

  @override
  String get modelReasonNoModel => 'The preset names no model file';

  @override
  String get modelReasonOther => 'Can\'t be loaded';

  @override
  String get modelCapImages => 'Images';

  @override
  String get modelCapTextOnly => 'Text only';

  @override
  String get modelCapThinking => 'Thinking';

  @override
  String get modelCapAlways => 'Always thinks';

  @override
  String get modelCapNoThinking => 'No thinking';

  @override
  String modelLoading(String model) {
    return 'Loading $model…';
  }

  @override
  String modelStartedFrom(String device, String time) {
    return 'Started from $device · $time';
  }

  @override
  String modelSwitchTitle(String model) {
    return 'Switch to $model?';
  }

  @override
  String get modelSwitchBody =>
      'Loading takes about a minute. Messages you send meanwhile wait.';

  @override
  String modelSwitchRunChat(String chat) {
    return 'in “$chat”';
  }

  @override
  String modelSwitchQueued(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count queued messages run on the new model.',
      one: '1 queued message runs on the new model.',
    );
    return '$_temp0';
  }

  @override
  String get modelSwitch => 'Switch';

  @override
  String get modelStopAndSwitch => 'Stop run and switch';

  @override
  String modelQueueWaits(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages wait for the new model.',
      one: '1 message waits for the new model.',
    );
    return '$_temp0';
  }

  @override
  String modelFailed(String model, String previous) {
    return 'Couldn\'t load $model. Back on $previous.';
  }

  @override
  String modelFailedAlone(String model) {
    return 'Couldn\'t load $model.';
  }

  @override
  String modelFailedDown(String model, String previous) {
    return 'Couldn\'t load $model and couldn\'t go back to $previous. llama-server is down.';
  }

  @override
  String modelFailedDownAlone(String model) {
    return 'Couldn\'t load $model. llama-server is down.';
  }

  @override
  String modelFailedShort(String model, String previous) {
    return 'Couldn\'t load $model · back on $previous';
  }

  @override
  String get modelFailedDownShort => 'Switch failed — llama-server is down';

  @override
  String modelExitedAfter(String time) {
    return 'llama-server exited after $time';
  }

  @override
  String modelNotReadyAfter(String time) {
    return 'Not ready after $time';
  }

  @override
  String get modelDismiss => 'Dismiss';

  @override
  String modelDismissFailed(String reason) {
    return 'Couldn\'t dismiss: $reason';
  }

  @override
  String get modelNotUsable => 'That model can\'t be loaded.';

  @override
  String get modelSwitchInProgress => 'A model switch is already in progress.';

  @override
  String get modelUnknown => 'That preset is no longer on the desktop.';

  @override
  String modelSwitchFailed(String reason) {
    return 'Couldn\'t switch the model: $reason';
  }

  @override
  String get usageLastAnswer => 'Last answer';

  @override
  String modelCantReadImages(String model) {
    return '$model can\'t read images';
  }

  @override
  String get modelChangedIn => 'The local model is changed in More → System.';

  @override
  String modelAlwaysThinks(String model) {
    return '$model always thinks';
  }

  @override
  String get modelThisModel => 'The loaded model';

  @override
  String get outboxNoVision => 'the loaded model can\'t read images';

  @override
  String get notifyChannelSystem => 'System';

  @override
  String get notifyChannelSystemDesc => 'When a model switch fails';

  @override
  String notifySwitchTitle(String model) {
    return 'Couldn\'t load $model';
  }

  @override
  String notifySwitchBack(String model) {
    return 'Back on $model';
  }

  @override
  String get notifySwitchBackPlain => 'The previous model is loaded again';

  @override
  String get notifySwitchDown => 'llama-server is stopped';

  @override
  String get settingsNotifySystem => 'Model switch failed';

  @override
  String get settingsNotifySystemSub =>
      'When the desktop could not load the model you picked';
}
