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
  String get notBuiltYet => 'Not built yet';

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
  String chatsApprovalPreview(String command) {
    return 'Approval needed: $command';
  }

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
}
