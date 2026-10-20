import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Delve'**
  String get appTitle;

  /// No description provided for @navChats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get navChats;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navApprovals.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get navApprovals;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @approvalsBadge.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 approval waiting} other{{count} approvals waiting}}'**
  String approvalsBadge(int count);

  /// No description provided for @moreSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get moreSystem;

  /// No description provided for @moreSystemSub.
  ///
  /// In en, this message translates to:
  /// **'llama-server, Hermes, backend'**
  String get moreSystemSub;

  /// No description provided for @moreSchedules.
  ///
  /// In en, this message translates to:
  /// **'Schedules'**
  String get moreSchedules;

  /// No description provided for @moreSchedulesSub.
  ///
  /// In en, this message translates to:
  /// **'Recurring prompts'**
  String get moreSchedulesSub;

  /// No description provided for @moreObservability.
  ///
  /// In en, this message translates to:
  /// **'Observability'**
  String get moreObservability;

  /// No description provided for @moreObservabilitySub.
  ///
  /// In en, this message translates to:
  /// **'Throughput, tokens, runs'**
  String get moreObservabilitySub;

  /// No description provided for @moreSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get moreSettings;

  /// No description provided for @moreSettingsSub.
  ///
  /// In en, this message translates to:
  /// **'Server, device, about'**
  String get moreSettingsSub;

  /// No description provided for @newChat.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get newChat;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatTitle;

  /// No description provided for @notBuiltYet.
  ///
  /// In en, this message translates to:
  /// **'Not built yet'**
  String get notBuiltYet;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @pairTitle.
  ///
  /// In en, this message translates to:
  /// **'Pair this phone'**
  String get pairTitle;

  /// No description provided for @pairIntro.
  ///
  /// In en, this message translates to:
  /// **'Connect to your Delve server over Tailscale. Get an 8-digit code on the desktop with: sudo delve pair'**
  String get pairIntro;

  /// No description provided for @pairServerUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get pairServerUrl;

  /// No description provided for @pairServerUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://archlinux.<tailnet>.ts.net'**
  String get pairServerUrlHint;

  /// No description provided for @pairServerUrlHelper.
  ///
  /// In en, this message translates to:
  /// **'Your desktop\'s Tailscale address'**
  String get pairServerUrlHelper;

  /// No description provided for @pairUrlInvalid.
  ///
  /// In en, this message translates to:
  /// **'Not a valid address'**
  String get pairUrlInvalid;

  /// No description provided for @pairUrlNotHttps.
  ///
  /// In en, this message translates to:
  /// **'Use the https:// address'**
  String get pairUrlNotHttps;

  /// No description provided for @pairUrlNotTailnet.
  ///
  /// In en, this message translates to:
  /// **'Use the desktop\'s Tailscale name (….ts.net)'**
  String get pairUrlNotTailnet;

  /// No description provided for @pairCode.
  ///
  /// In en, this message translates to:
  /// **'Pairing code'**
  String get pairCode;

  /// No description provided for @pairCodeHelper.
  ///
  /// In en, this message translates to:
  /// **'8 digits, valid for 10 minutes'**
  String get pairCodeHelper;

  /// No description provided for @pairCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired code'**
  String get pairCodeInvalid;

  /// No description provided for @pairButton.
  ///
  /// In en, this message translates to:
  /// **'Pair'**
  String get pairButton;

  /// No description provided for @pairButtonWait.
  ///
  /// In en, this message translates to:
  /// **'Pair · {seconds} s'**
  String pairButtonWait(int seconds);

  /// No description provided for @pairRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts — try again in {seconds} s'**
  String pairRateLimited(int seconds);

  /// No description provided for @pairUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the server — is Tailscale on?'**
  String get pairUnreachable;

  /// No description provided for @pairFailed.
  ///
  /// In en, this message translates to:
  /// **'Pairing failed: {reason}'**
  String pairFailed(String reason);

  /// No description provided for @pairFailedServer.
  ///
  /// In en, this message translates to:
  /// **'server error (HTTP {status})'**
  String pairFailedServer(int status);

  /// No description provided for @pairFailedNotDelve.
  ///
  /// In en, this message translates to:
  /// **'unexpected answer — is this the Delve server?'**
  String get pairFailedNotDelve;

  /// No description provided for @pairFootnote.
  ///
  /// In en, this message translates to:
  /// **'Traffic stays inside your tailnet.'**
  String get pairFootnote;

  /// No description provided for @pairNoteUnpaired.
  ///
  /// In en, this message translates to:
  /// **'This phone was unpaired. Pair again with a new code.'**
  String get pairNoteUnpaired;

  /// No description provided for @pairNoteUnpairedLocally.
  ///
  /// In en, this message translates to:
  /// **'Unpaired on this phone, but the server could not be reached. Revoke the old token there: sudo delve token list, then sudo delve token revoke <id>.'**
  String get pairNoteUnpairedLocally;

  /// No description provided for @pairNoteRevoked.
  ///
  /// In en, this message translates to:
  /// **'The server no longer accepts this phone\'s token. Pair again with a new code.'**
  String get pairNoteRevoked;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @settingsServer.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get settingsServer;

  /// No description provided for @settingsServerUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get settingsServerUrl;

  /// No description provided for @settingsThisDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get settingsThisDevice;

  /// No description provided for @settingsPairedSeen.
  ///
  /// In en, this message translates to:
  /// **'Paired {date} · last seen {seen}'**
  String settingsPairedSeen(String date, String seen);

  /// No description provided for @settingsSeenNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get settingsSeenNow;

  /// No description provided for @settingsSeenMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String settingsSeenMinutes(int minutes);

  /// No description provided for @settingsSeenNever.
  ///
  /// In en, this message translates to:
  /// **'never'**
  String get settingsSeenNever;

  /// No description provided for @settingsThinkingRoute.
  ///
  /// In en, this message translates to:
  /// **'Thinking route'**
  String get settingsThinkingRoute;

  /// No description provided for @settingsStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get settingsStatus;

  /// No description provided for @settingsRouteOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get settingsRouteOk;

  /// No description provided for @settingsRouteOkDetail.
  ///
  /// In en, this message translates to:
  /// **'Last thinking run at {time} used the thinking model'**
  String settingsRouteOkDetail(String time);

  /// No description provided for @settingsRouteFailed.
  ///
  /// In en, this message translates to:
  /// **'Check failed'**
  String get settingsRouteFailed;

  /// No description provided for @settingsRouteFailedDetail.
  ///
  /// In en, this message translates to:
  /// **'Last thinking run at {time} did not use the thinking model'**
  String settingsRouteFailedDetail(String time);

  /// No description provided for @settingsRouteNone.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get settingsRouteNone;

  /// No description provided for @settingsRouteNoneDetail.
  ///
  /// In en, this message translates to:
  /// **'No thinking run since the server started'**
  String get settingsRouteNoneDetail;

  /// No description provided for @settingsCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get settingsCheckAgain;

  /// No description provided for @settingsVersions.
  ///
  /// In en, this message translates to:
  /// **'Versions'**
  String get settingsVersions;

  /// No description provided for @settingsApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get settingsApp;

  /// No description provided for @settingsServerVersion.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get settingsServerVersion;

  /// No description provided for @settingsApiRevision.
  ///
  /// In en, this message translates to:
  /// **'API revision'**
  String get settingsApiRevision;

  /// No description provided for @settingsHermes.
  ///
  /// In en, this message translates to:
  /// **'Hermes Agent'**
  String get settingsHermes;

  /// No description provided for @settingsHermesDown.
  ///
  /// In en, this message translates to:
  /// **'down'**
  String get settingsHermesDown;

  /// No description provided for @settingsUnknown.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get settingsUnknown;

  /// No description provided for @settingsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load: {reason}'**
  String settingsLoadFailed(String reason);

  /// No description provided for @settingsUnpair.
  ///
  /// In en, this message translates to:
  /// **'Unpair this device'**
  String get settingsUnpair;

  /// No description provided for @settingsUnpairNote.
  ///
  /// In en, this message translates to:
  /// **'You will need a new pairing code to connect again.'**
  String get settingsUnpairNote;

  /// No description provided for @unpairDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Unpair this device?'**
  String get unpairDialogTitle;

  /// No description provided for @unpairDialogBody.
  ///
  /// In en, this message translates to:
  /// **'The server stops accepting this phone and the local copy of your chats is deleted. You will need a new pairing code to connect again.'**
  String get unpairDialogBody;

  /// No description provided for @unpairDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Unpair'**
  String get unpairDialogConfirm;

  /// No description provided for @tooOldTitle.
  ///
  /// In en, this message translates to:
  /// **'Server version too old for this app'**
  String get tooOldTitle;

  /// No description provided for @tooOldBody.
  ///
  /// In en, this message translates to:
  /// **'Delve {app} needs API revision {min} or newer. Update the Delve server on your desktop, then try again.'**
  String tooOldBody(String app, int min);

  /// No description provided for @tooOldThisApp.
  ///
  /// In en, this message translates to:
  /// **'This app'**
  String get tooOldThisApp;

  /// No description provided for @tooOldNeeds.
  ///
  /// In en, this message translates to:
  /// **'{app} · needs API ≥ {min}'**
  String tooOldNeeds(String app, int min);

  /// No description provided for @tooOldServer.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get tooOldServer;

  /// No description provided for @tooOldServerValue.
  ///
  /// In en, this message translates to:
  /// **'{version} · API {revision}'**
  String tooOldServerValue(String version, int revision);

  /// No description provided for @tooOldServerUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get tooOldServerUrl;

  /// No description provided for @tooOldStillOld.
  ///
  /// In en, this message translates to:
  /// **'The server still reports API revision {revision}'**
  String tooOldStillOld(int revision);

  /// No description provided for @tooOldPairOther.
  ///
  /// In en, this message translates to:
  /// **'Pair with another server'**
  String get tooOldPairOther;

  /// No description provided for @settingsConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get settingsConnection;

  /// No description provided for @connLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get connLive;

  /// No description provided for @connLiveSince.
  ///
  /// In en, this message translates to:
  /// **'Live since {time}'**
  String connLiveSince(String time);

  /// No description provided for @connReloading.
  ///
  /// In en, this message translates to:
  /// **'Live · reloading after a server restart'**
  String get connReloading;

  /// No description provided for @connConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connConnecting;

  /// No description provided for @connRetrying.
  ///
  /// In en, this message translates to:
  /// **'{problem} Retrying (attempt {attempt}).'**
  String connRetrying(String problem, int attempt);

  /// No description provided for @connOffline.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get connOffline;

  /// No description provided for @connPaused.
  ///
  /// In en, this message translates to:
  /// **'Disconnected while the app is in the background'**
  String get connPaused;

  /// No description provided for @connAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'The server refused this device\'s token'**
  String get connAuthFailed;

  /// No description provided for @connUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the server — is Tailscale on?'**
  String get connUnreachable;

  /// No description provided for @connRejected.
  ///
  /// In en, this message translates to:
  /// **'The server is reachable, but Delve isn\'t answering.'**
  String get connRejected;

  /// No description provided for @connHelloTimeout.
  ///
  /// In en, this message translates to:
  /// **'The server didn\'t answer in time.'**
  String get connHelloTimeout;

  /// No description provided for @connSilent.
  ///
  /// In en, this message translates to:
  /// **'The connection went silent.'**
  String get connSilent;

  /// No description provided for @connClosed.
  ///
  /// In en, this message translates to:
  /// **'The server closed the connection.'**
  String get connClosed;

  /// No description provided for @connResyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Reloading after a server restart failed.'**
  String get connResyncFailed;

  /// No description provided for @chipLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get chipLive;

  /// No description provided for @chipConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get chipConnecting;

  /// No description provided for @chipRetrying.
  ///
  /// In en, this message translates to:
  /// **'Retrying'**
  String get chipRetrying;

  /// No description provided for @chipOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get chipOffline;

  /// No description provided for @chipRefused.
  ///
  /// In en, this message translates to:
  /// **'Refused'**
  String get chipRefused;

  /// No description provided for @logTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection log'**
  String get logTitle;

  /// No description provided for @logEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged yet'**
  String get logEmpty;

  /// No description provided for @logReconnectNow.
  ///
  /// In en, this message translates to:
  /// **'Reconnect now'**
  String get logReconnectNow;

  /// No description provided for @logKindConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get logKindConnecting;

  /// No description provided for @logKindConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get logKindConnected;

  /// No description provided for @logKindResync.
  ///
  /// In en, this message translates to:
  /// **'Reloaded'**
  String get logKindResync;

  /// No description provided for @logKindClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get logKindClosed;

  /// No description provided for @logKindFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get logKindFailed;

  /// No description provided for @logKindBackoff.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get logKindBackoff;

  /// No description provided for @logKindPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get logKindPaused;

  /// No description provided for @logKindResumed.
  ///
  /// In en, this message translates to:
  /// **'Resumed'**
  String get logKindResumed;

  /// No description provided for @logKindAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Token refused'**
  String get logKindAuthFailed;

  /// No description provided for @logKindOutbox.
  ///
  /// In en, this message translates to:
  /// **'Outbox'**
  String get logKindOutbox;

  /// No description provided for @logKindHermes.
  ///
  /// In en, this message translates to:
  /// **'Hermes'**
  String get logKindHermes;

  /// No description provided for @logKindServerError.
  ///
  /// In en, this message translates to:
  /// **'Server error'**
  String get logKindServerError;

  /// No description provided for @logKindProtocol.
  ///
  /// In en, this message translates to:
  /// **'Protocol'**
  String get logKindProtocol;

  /// No description provided for @chatsSearch.
  ///
  /// In en, this message translates to:
  /// **'Search chats'**
  String get chatsSearch;

  /// No description provided for @chatsSearchClose.
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get chatsSearchClose;

  /// No description provided for @chatsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search titles and messages'**
  String get chatsSearchHint;

  /// No description provided for @chatsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No chats match “{query}”'**
  String chatsNoMatch(String query);

  /// No description provided for @chatsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No chats yet'**
  String get chatsEmptyTitle;

  /// No description provided for @chatsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Ask your agent anything. Runs happen on your desktop; this phone only talks to it over Tailscale.'**
  String get chatsEmptyBody;

  /// No description provided for @chatsApprovalPreview.
  ///
  /// In en, this message translates to:
  /// **'Approval needed: {command}'**
  String chatsApprovalPreview(String command);

  /// No description provided for @chatsMarkerApproval.
  ///
  /// In en, this message translates to:
  /// **'approval needed'**
  String get chatsMarkerApproval;

  /// No description provided for @chatsMarkerRunning.
  ///
  /// In en, this message translates to:
  /// **'running'**
  String get chatsMarkerRunning;

  /// No description provided for @chatsMarkerRunningQueued.
  ///
  /// In en, this message translates to:
  /// **'running · {count} queued'**
  String chatsMarkerRunningQueued(int count);

  /// No description provided for @chatsMarkerWaiting.
  ///
  /// In en, this message translates to:
  /// **'queued'**
  String get chatsMarkerWaiting;

  /// No description provided for @chatsDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get chatsDetails;

  /// No description provided for @chatsArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get chatsArchive;

  /// No description provided for @chatsArchived.
  ///
  /// In en, this message translates to:
  /// **'Chat archived'**
  String get chatsArchived;

  /// No description provided for @chatsUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get chatsUndo;

  /// No description provided for @chatsArchiveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t archive: {reason}'**
  String chatsArchiveFailed(String reason);

  /// No description provided for @chatsRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t refresh: {reason}'**
  String chatsRefreshFailed(String reason);

  /// No description provided for @errorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'too many requests, try again in {seconds} s'**
  String errorRateLimited(int seconds);

  /// No description provided for @errorHttp.
  ///
  /// In en, this message translates to:
  /// **'server error (HTTP {status})'**
  String errorHttp(String status);

  /// No description provided for @errorCancelled.
  ///
  /// In en, this message translates to:
  /// **'cancelled'**
  String get errorCancelled;

  /// No description provided for @moreArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived chats'**
  String get moreArchived;

  /// No description provided for @moreArchivedSub.
  ///
  /// In en, this message translates to:
  /// **'Chats you swiped away'**
  String get moreArchivedSub;

  /// No description provided for @archivedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No archived chats. Swipe a chat to the left on the Chats screen to archive it.'**
  String get archivedEmpty;

  /// No description provided for @archivedRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get archivedRestore;

  /// No description provided for @archivedRestored.
  ///
  /// In en, this message translates to:
  /// **'Chat restored'**
  String get archivedRestored;

  /// No description provided for @archivedRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t restore: {reason}'**
  String archivedRestoreFailed(String reason);

  /// No description provided for @chatCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get chatCopied;

  /// No description provided for @chatLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get chatLinkCopied;

  /// No description provided for @chatMenu.
  ///
  /// In en, this message translates to:
  /// **'Chat options'**
  String get chatMenu;

  /// No description provided for @chatNotConnected.
  ///
  /// In en, this message translates to:
  /// **'not connected to the server'**
  String get chatNotConnected;

  /// No description provided for @chatNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'the server did not answer'**
  String get chatNoAnswer;

  /// No description provided for @chatStopFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t stop: {reason}'**
  String chatStopFailed(String reason);

  /// No description provided for @chatWorking.
  ///
  /// In en, this message translates to:
  /// **'Working…'**
  String get chatWorking;

  /// No description provided for @chatRunStopped.
  ///
  /// In en, this message translates to:
  /// **'Run stopped'**
  String get chatRunStopped;

  /// No description provided for @chatRunRunning.
  ///
  /// In en, this message translates to:
  /// **'running · {clock}'**
  String chatRunRunning(String clock);

  /// No description provided for @chatRunWaiting.
  ///
  /// In en, this message translates to:
  /// **'waiting for approval · {clock}'**
  String chatRunWaiting(String clock);

  /// No description provided for @chatRunQueued.
  ///
  /// In en, this message translates to:
  /// **'queued'**
  String get chatRunQueued;

  /// No description provided for @chatContextWarn.
  ///
  /// In en, this message translates to:
  /// **'Context {pct}% full — consider a new chat'**
  String chatContextWarn(int pct);

  /// No description provided for @newChatIntro.
  ///
  /// In en, this message translates to:
  /// **'Your agent on {host} · over Tailscale'**
  String newChatIntro(String host);

  /// No description provided for @newChatIntroNoHost.
  ///
  /// In en, this message translates to:
  /// **'Your agent, over Tailscale'**
  String get newChatIntroNoHost;

  /// No description provided for @composerHint.
  ///
  /// In en, this message translates to:
  /// **'Message Delve…'**
  String get composerHint;

  /// No description provided for @composerSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get composerSend;

  /// No description provided for @composerStop.
  ///
  /// In en, this message translates to:
  /// **'Stop run'**
  String get composerStop;

  /// No description provided for @composerAttach.
  ///
  /// In en, this message translates to:
  /// **'Add a photo or file'**
  String get composerAttach;

  /// No description provided for @composerQueued.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 more message queued} other{{count} more messages queued}}'**
  String composerQueued(int count);

  /// No description provided for @outboxWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the connection'**
  String get outboxWaiting;

  /// No description provided for @outboxSending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get outboxSending;

  /// No description provided for @outboxFailed.
  ///
  /// In en, this message translates to:
  /// **'Not sent'**
  String get outboxFailed;

  /// No description provided for @outboxFailedWhy.
  ///
  /// In en, this message translates to:
  /// **'Not sent: {reason}'**
  String outboxFailedWhy(String reason);

  /// No description provided for @outboxRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get outboxRetry;

  /// No description provided for @outboxDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get outboxDiscard;

  /// No description provided for @stepRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get stepRunning;

  /// No description provided for @stepWaiting.
  ///
  /// In en, this message translates to:
  /// **'Approval needed'**
  String get stepWaiting;

  /// No description provided for @stepOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get stepOk;

  /// No description provided for @stepError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get stepError;

  /// No description provided for @stepCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get stepCancelled;

  /// No description provided for @stepDenied.
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get stepDenied;

  /// No description provided for @stepTimeout.
  ///
  /// In en, this message translates to:
  /// **'Timed out'**
  String get stepTimeout;

  /// No description provided for @stepBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get stepBlocked;

  /// No description provided for @stepCancelledNote.
  ///
  /// In en, this message translates to:
  /// **'Run stopped before this step finished.'**
  String get stepCancelledNote;

  /// No description provided for @stepDeniedNote.
  ///
  /// In en, this message translates to:
  /// **'Not run. The agent was told it was denied.'**
  String get stepDeniedNote;

  /// No description provided for @stepBlockedNote.
  ///
  /// In en, this message translates to:
  /// **'Matched a deny rule · never asks for approval.'**
  String get stepBlockedNote;

  /// No description provided for @stepWaitingNote.
  ///
  /// In en, this message translates to:
  /// **'The agent waits for your approval.'**
  String get stepWaitingNote;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get showMore;

  /// No description provided for @runFailed.
  ///
  /// In en, this message translates to:
  /// **'Run failed'**
  String get runFailed;

  /// No description provided for @runRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get runRetry;

  /// No description provided for @runFailedUnknown.
  ///
  /// In en, this message translates to:
  /// **'The run ended with an error.'**
  String get runFailedUnknown;

  /// No description provided for @runFailedLost.
  ///
  /// In en, this message translates to:
  /// **'The agent restarted and lost this run.'**
  String get runFailedLost;

  /// No description provided for @runFailedUnstable.
  ///
  /// In en, this message translates to:
  /// **'The connection to the agent kept dropping.'**
  String get runFailedUnstable;

  /// No description provided for @runFailedHermes.
  ///
  /// In en, this message translates to:
  /// **'The agent refused the run ({code}).'**
  String runFailedHermes(String code);

  /// No description provided for @approvalNeeded.
  ///
  /// In en, this message translates to:
  /// **'Approval needed'**
  String get approvalNeeded;

  /// No description provided for @approvalStoppedWaiting.
  ///
  /// In en, this message translates to:
  /// **'Agent stopped waiting'**
  String get approvalStoppedWaiting;

  /// No description provided for @approvalWaits.
  ///
  /// In en, this message translates to:
  /// **'Agent waits {time}'**
  String approvalWaits(String time);

  /// No description provided for @approvalLateBody.
  ///
  /// In en, this message translates to:
  /// **'Agent stopped waiting. You can still approve until {time} — Delve will run it in a follow-up.'**
  String approvalLateBody(String time);

  /// No description provided for @approvalClosed.
  ///
  /// In en, this message translates to:
  /// **'The approval window closed at {time}.'**
  String approvalClosed(String time);

  /// No description provided for @approvalAllowOnce.
  ///
  /// In en, this message translates to:
  /// **'Allow once'**
  String get approvalAllowOnce;

  /// No description provided for @approvalDeny.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get approvalDeny;

  /// No description provided for @approvalAllowSession.
  ///
  /// In en, this message translates to:
  /// **'Allow for session'**
  String get approvalAllowSession;

  /// No description provided for @approvalOffline.
  ///
  /// In en, this message translates to:
  /// **'Not connected — you can answer once the connection is back.'**
  String get approvalOffline;

  /// No description provided for @approvalFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t answer: {reason}'**
  String approvalFailed(String reason);

  /// No description provided for @approvalClassPkgUpgrade.
  ///
  /// In en, this message translates to:
  /// **'package upgrade'**
  String get approvalClassPkgUpgrade;

  /// No description provided for @approvalClassServiceRestart.
  ///
  /// In en, this message translates to:
  /// **'service restart'**
  String get approvalClassServiceRestart;

  /// No description provided for @approvalClassDeleteKill.
  ///
  /// In en, this message translates to:
  /// **'delete / kill'**
  String get approvalClassDeleteKill;

  /// No description provided for @approvalClassOther.
  ///
  /// In en, this message translates to:
  /// **'command'**
  String get approvalClassOther;

  /// No description provided for @approvalApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approvalApproved;

  /// No description provided for @approvalApprovedLate.
  ///
  /// In en, this message translates to:
  /// **'Approved late'**
  String get approvalApprovedLate;

  /// No description provided for @approvalRanLater.
  ///
  /// In en, this message translates to:
  /// **'Ran in a follow-up'**
  String get approvalRanLater;

  /// No description provided for @approvalSuperseded.
  ///
  /// In en, this message translates to:
  /// **'Follow-up ran something else'**
  String get approvalSuperseded;

  /// No description provided for @approvalDenied.
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get approvalDenied;

  /// No description provided for @approvalExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get approvalExpired;

  /// No description provided for @approvalCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get approvalCancelled;

  /// No description provided for @approvalByYou.
  ///
  /// In en, this message translates to:
  /// **'by you'**
  String get approvalByYou;

  /// No description provided for @approvalBy.
  ///
  /// In en, this message translates to:
  /// **'by {name}'**
  String approvalBy(String name);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
