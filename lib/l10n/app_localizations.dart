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

  /// No description provided for @attachPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get attachPhotos;

  /// No description provided for @attachCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get attachCamera;

  /// No description provided for @attachFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get attachFile;

  /// No description provided for @attachLimit.
  ///
  /// In en, this message translates to:
  /// **'Up to {max} attachments per message'**
  String attachLimit(int max);

  /// No description provided for @attachLeftOut.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 was left out: up to {max} per message} other{{count} were left out: up to {max} per message}}'**
  String attachLeftOut(int count, int max);

  /// No description provided for @attachNeedsConnection.
  ///
  /// In en, this message translates to:
  /// **'Attachments need a live connection'**
  String get attachNeedsConnection;

  /// No description provided for @attachUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading {name}'**
  String attachUploading(String name);

  /// No description provided for @attachFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'{name}: not uploaded, tap to retry'**
  String attachFailedRetry(String name);

  /// No description provided for @attachFailedShort.
  ///
  /// In en, this message translates to:
  /// **'Not uploaded · tap to retry'**
  String get attachFailedShort;

  /// No description provided for @attachTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Too large (max {size})'**
  String attachTooLarge(String size);

  /// No description provided for @attachUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Not a readable image'**
  String get attachUnreadable;

  /// No description provided for @attachRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String attachRemove(String name);

  /// No description provided for @attachImage.
  ///
  /// In en, this message translates to:
  /// **'Image {name}'**
  String attachImage(String name);

  /// No description provided for @attachGone.
  ///
  /// In en, this message translates to:
  /// **'No longer available'**
  String get attachGone;

  /// No description provided for @attachSendAgain.
  ///
  /// In en, this message translates to:
  /// **'Send again'**
  String get attachSendAgain;

  /// No description provided for @attachAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to your message'**
  String get attachAdded;

  /// No description provided for @attachPickFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the picker: {reason}'**
  String attachPickFailed(String reason);

  /// No description provided for @attachCopyFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not add it again: {reason}'**
  String attachCopyFailed(String reason);

  /// No description provided for @attachLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the image'**
  String get attachLoadFailed;

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

  /// No description provided for @approvalsPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get approvalsPending;

  /// No description provided for @approvalsExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired in agent — still approvable'**
  String get approvalsExpired;

  /// No description provided for @approvalsRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get approvalsRecent;

  /// No description provided for @approvalsNothingWaiting.
  ///
  /// In en, this message translates to:
  /// **'Nothing is waiting for you.'**
  String get approvalsNothingWaiting;

  /// No description provided for @approvalsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to approve'**
  String get approvalsEmptyTitle;

  /// No description provided for @approvalsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Commands the agent wants your OK for show up here.'**
  String get approvalsEmptyBody;

  /// No description provided for @approvalsRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reload: {reason}'**
  String approvalsRefreshFailed(String reason);

  /// No description provided for @approvalsLateStarted.
  ///
  /// In en, this message translates to:
  /// **'Approved — Delve runs it in a follow-up.'**
  String get approvalsLateStarted;

  /// No description provided for @approvalsExpiredUntil.
  ///
  /// In en, this message translates to:
  /// **'Expired in agent · approvable until {time}'**
  String approvalsExpiredUntil(String time);

  /// No description provided for @approvalsClosedAt.
  ///
  /// In en, this message translates to:
  /// **'Expired in agent · closed at {time}'**
  String approvalsClosedAt(String time);

  /// No description provided for @approvalsMore.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get approvalsMore;

  /// No description provided for @approvalsOpenChat.
  ///
  /// In en, this message translates to:
  /// **'Open chat'**
  String get approvalsOpenChat;

  /// No description provided for @approvalsWhoYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get approvalsWhoYou;

  /// No description provided for @approvalsWhoAuto.
  ///
  /// In en, this message translates to:
  /// **'Delve (follow-up)'**
  String get approvalsWhoAuto;

  /// No description provided for @chatFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Follow-up run: approved'**
  String get chatFollowUp;

  /// No description provided for @composerThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking'**
  String get composerThinking;

  /// No description provided for @composerThinkingCaption.
  ///
  /// In en, this message translates to:
  /// **'Applies to your next message'**
  String get composerThinkingCaption;

  /// No description provided for @thinkingFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t switch Thinking: {reason}'**
  String thinkingFailed(String reason);

  /// No description provided for @thinkingNow.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get thinkingNow;

  /// No description provided for @thinkingTokens.
  ///
  /// In en, this message translates to:
  /// **'{count} tok'**
  String thinkingTokens(String count);

  /// No description provided for @thinkingThought.
  ///
  /// In en, this message translates to:
  /// **'Thought'**
  String get thinkingThought;

  /// No description provided for @thinkingThoughtFor.
  ///
  /// In en, this message translates to:
  /// **'Thought for {time}'**
  String thinkingThoughtFor(String time);

  /// No description provided for @thinkingShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get thinkingShowAll;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @usageNoContext.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get usageNoContext;

  /// No description provided for @usageTitle.
  ///
  /// In en, this message translates to:
  /// **'Usage'**
  String get usageTitle;

  /// No description provided for @usageRunCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 run} other{{count} runs}}'**
  String usageRunCount(int count);

  /// No description provided for @usageLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load usage: {reason}'**
  String usageLoadFailed(String reason);

  /// No description provided for @usageInput.
  ///
  /// In en, this message translates to:
  /// **'Input'**
  String get usageInput;

  /// No description provided for @usageOutput.
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get usageOutput;

  /// No description provided for @usageCacheRead.
  ///
  /// In en, this message translates to:
  /// **'Cache read'**
  String get usageCacheRead;

  /// No description provided for @usageTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get usageTotal;

  /// No description provided for @usageContext.
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get usageContext;

  /// No description provided for @usageWarnMark.
  ///
  /// In en, this message translates to:
  /// **'75% · warn'**
  String get usageWarnMark;

  /// No description provided for @usageRuns.
  ///
  /// In en, this message translates to:
  /// **'Runs'**
  String get usageRuns;

  /// No description provided for @usageNewestFirst.
  ///
  /// In en, this message translates to:
  /// **'newest first'**
  String get usageNewestFirst;

  /// No description provided for @usageNoRuns.
  ///
  /// In en, this message translates to:
  /// **'No runs yet.'**
  String get usageNoRuns;

  /// No description provided for @usagePrefillNote.
  ///
  /// In en, this message translates to:
  /// **'Prefill speed is shown only for prompts of 500 tokens or more.'**
  String get usagePrefillNote;

  /// No description provided for @usageRun.
  ///
  /// In en, this message translates to:
  /// **'Run {number}'**
  String usageRun(int number);

  /// No description provided for @usageRunState.
  ///
  /// In en, this message translates to:
  /// **'Run {number} · {state}'**
  String usageRunState(int number, String state);

  /// No description provided for @usageRunFailed.
  ///
  /// In en, this message translates to:
  /// **'failed'**
  String get usageRunFailed;

  /// No description provided for @usageRunStopped.
  ///
  /// In en, this message translates to:
  /// **'stopped'**
  String get usageRunStopped;

  /// No description provided for @usageRunQueued.
  ///
  /// In en, this message translates to:
  /// **'queued'**
  String get usageRunQueued;

  /// No description provided for @usageRunRunning.
  ///
  /// In en, this message translates to:
  /// **'running'**
  String get usageRunRunning;

  /// No description provided for @usageIn.
  ///
  /// In en, this message translates to:
  /// **'in {count}'**
  String usageIn(String count);

  /// No description provided for @usageOut.
  ///
  /// In en, this message translates to:
  /// **'out {count}'**
  String usageOut(String count);

  /// No description provided for @usagePrefill.
  ///
  /// In en, this message translates to:
  /// **'Prefill'**
  String get usagePrefill;

  /// No description provided for @usageGeneration.
  ///
  /// In en, this message translates to:
  /// **'Generation'**
  String get usageGeneration;

  /// No description provided for @usageFirstToken.
  ///
  /// In en, this message translates to:
  /// **'First token'**
  String get usageFirstToken;

  /// No description provided for @contextChipSemantics.
  ///
  /// In en, this message translates to:
  /// **'Context {percent} percent, opens usage'**
  String contextChipSemantics(int percent);

  /// No description provided for @contextChipWarn.
  ///
  /// In en, this message translates to:
  /// **'Context {percent} percent, almost full, opens usage'**
  String contextChipWarn(int percent);

  /// No description provided for @contextChipEmpty.
  ///
  /// In en, this message translates to:
  /// **'Context not measured yet, opens usage'**
  String get contextChipEmpty;

  /// No description provided for @notifyApprovalTitle.
  ///
  /// In en, this message translates to:
  /// **'Approval needed · {kind}'**
  String notifyApprovalTitle(String kind);

  /// No description provided for @notifyApprovalWaits.
  ///
  /// In en, this message translates to:
  /// **'Agent waits · {chat}'**
  String notifyApprovalWaits(String chat);

  /// No description provided for @notifyApprovalWaitsNoChat.
  ///
  /// In en, this message translates to:
  /// **'Agent waits'**
  String get notifyApprovalWaitsNoChat;

  /// No description provided for @notifyLateTitle.
  ///
  /// In en, this message translates to:
  /// **'Agent stopped waiting · {kind}'**
  String notifyLateTitle(String kind);

  /// No description provided for @notifyLateBody.
  ///
  /// In en, this message translates to:
  /// **'Approvable until {time} · {chat}'**
  String notifyLateBody(String time, String chat);

  /// No description provided for @notifyLateBodyNoChat.
  ///
  /// In en, this message translates to:
  /// **'Approvable until {time}'**
  String notifyLateBodyNoChat(String time);

  /// No description provided for @notifyRunDone.
  ///
  /// In en, this message translates to:
  /// **'Run finished · {chat}'**
  String notifyRunDone(String chat);

  /// No description provided for @notifyRunDoneNoChat.
  ///
  /// In en, this message translates to:
  /// **'Run finished'**
  String get notifyRunDoneNoChat;

  /// No description provided for @notifyRunFailed.
  ///
  /// In en, this message translates to:
  /// **'Run failed · {chat}'**
  String notifyRunFailed(String chat);

  /// No description provided for @notifyRunFailedNoChat.
  ///
  /// In en, this message translates to:
  /// **'Run failed'**
  String get notifyRunFailedNoChat;

  /// No description provided for @notifyOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get notifyOpen;

  /// No description provided for @notifyChannelApprovals.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get notifyChannelApprovals;

  /// No description provided for @notifyChannelApprovalsDesc.
  ///
  /// In en, this message translates to:
  /// **'Commands waiting for your OK'**
  String get notifyChannelApprovalsDesc;

  /// No description provided for @notifyChannelRuns.
  ///
  /// In en, this message translates to:
  /// **'Finished runs'**
  String get notifyChannelRuns;

  /// No description provided for @notifyChannelRunsDesc.
  ///
  /// In en, this message translates to:
  /// **'Answers that arrive while Delve is in the background'**
  String get notifyChannelRunsDesc;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsNotifyApprovals.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get settingsNotifyApprovals;

  /// No description provided for @settingsNotifyApprovalsSub.
  ///
  /// In en, this message translates to:
  /// **'Allow once / Deny from the notification'**
  String get settingsNotifyApprovalsSub;

  /// No description provided for @settingsNotifyRunDone.
  ///
  /// In en, this message translates to:
  /// **'Run finished'**
  String get settingsNotifyRunDone;

  /// No description provided for @settingsNotifyRunDoneSub.
  ///
  /// In en, this message translates to:
  /// **'Only when the app is in the background'**
  String get settingsNotifyRunDoneSub;

  /// No description provided for @settingsNotifyWater.
  ///
  /// In en, this message translates to:
  /// **'Water level'**
  String get settingsNotifyWater;

  /// No description provided for @settingsNotifyBrief.
  ///
  /// In en, this message translates to:
  /// **'Morning brief'**
  String get settingsNotifyBrief;

  /// No description provided for @settingsNotifyBriefSub.
  ///
  /// In en, this message translates to:
  /// **'After each morning brief'**
  String get settingsNotifyBriefSub;

  /// No description provided for @settingsNotifyPermissionOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off for Delve on this phone.'**
  String get settingsNotifyPermissionOff;

  /// No description provided for @settingsNotifyAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get settingsNotifyAllow;

  /// No description provided for @settingsNotifyNoServer.
  ///
  /// In en, this message translates to:
  /// **'The server can\'t send notifications yet (no Firebase key).'**
  String get settingsNotifyNoServer;

  /// No description provided for @settingsNotifyNoApp.
  ///
  /// In en, this message translates to:
  /// **'This build can\'t receive notifications (no Firebase configuration).'**
  String get settingsNotifyNoApp;

  /// No description provided for @settingsNotifySaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save: {reason}'**
  String settingsNotifySaveFailed(String reason);

  /// No description provided for @dashUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String dashUpdated(String time);

  /// No description provided for @dashConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected · tailnet'**
  String get dashConnected;

  /// No description provided for @dashWaterTitle.
  ///
  /// In en, this message translates to:
  /// **'Lake Balaton water level'**
  String get dashWaterTitle;

  /// No description provided for @dashToday.
  ///
  /// In en, this message translates to:
  /// **'today {time}'**
  String dashToday(String time);

  /// No description provided for @dashCm.
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get dashCm;

  /// No description provided for @dashLakeAverage.
  ///
  /// In en, this message translates to:
  /// **'Lake average'**
  String get dashLakeAverage;

  /// No description provided for @dashVsYesterday.
  ///
  /// In en, this message translates to:
  /// **'vs yesterday'**
  String get dashVsYesterday;

  /// No description provided for @dashWaterEmpty.
  ///
  /// In en, this message translates to:
  /// **'No water reading yet. It arrives after the next scheduled reading.'**
  String get dashWaterEmpty;

  /// No description provided for @notifyWaterTitle.
  ///
  /// In en, this message translates to:
  /// **'Water level · {station} {level} cm'**
  String notifyWaterTitle(String station, String level);

  /// No description provided for @notifyWaterLake.
  ///
  /// In en, this message translates to:
  /// **'Lake average {level} cm'**
  String notifyWaterLake(String level);

  /// No description provided for @notifyWaterTrend.
  ///
  /// In en, this message translates to:
  /// **'{change} cm vs yesterday'**
  String notifyWaterTrend(String change);

  /// No description provided for @notifyChannelCards.
  ///
  /// In en, this message translates to:
  /// **'Water level'**
  String get notifyChannelCards;

  /// No description provided for @notifyChannelCardsDesc.
  ///
  /// In en, this message translates to:
  /// **'After each scheduled reading'**
  String get notifyChannelCardsDesc;

  /// No description provided for @settingsNotifyWaterSub.
  ///
  /// In en, this message translates to:
  /// **'After each scheduled reading'**
  String get settingsNotifyWaterSub;

  /// No description provided for @systemChecked.
  ///
  /// In en, this message translates to:
  /// **'checked {time}'**
  String systemChecked(String time);

  /// No description provided for @systemHermes.
  ///
  /// In en, this message translates to:
  /// **'Hermes Agent'**
  String get systemHermes;

  /// No description provided for @systemStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get systemStatus;

  /// No description provided for @systemVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get systemVersion;

  /// No description provided for @systemUptime.
  ///
  /// In en, this message translates to:
  /// **'Uptime'**
  String get systemUptime;

  /// No description provided for @systemQueue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get systemQueue;

  /// No description provided for @systemQueueActive.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 run active} other{{count} runs active}}'**
  String systemQueueActive(int count);

  /// No description provided for @systemQueueQueued.
  ///
  /// In en, this message translates to:
  /// **'{count} queued'**
  String systemQueueQueued(int count);

  /// No description provided for @systemLlama.
  ///
  /// In en, this message translates to:
  /// **'llama-server'**
  String get systemLlama;

  /// No description provided for @systemModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get systemModel;

  /// No description provided for @systemContext.
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get systemContext;

  /// No description provided for @systemSlots.
  ///
  /// In en, this message translates to:
  /// **'Slots'**
  String get systemSlots;

  /// No description provided for @systemGeneration.
  ///
  /// In en, this message translates to:
  /// **'Generation'**
  String get systemGeneration;

  /// No description provided for @systemSince.
  ///
  /// In en, this message translates to:
  /// **'since {time}'**
  String systemSince(String time);

  /// No description provided for @systemTokens.
  ///
  /// In en, this message translates to:
  /// **'{tokens} tok'**
  String systemTokens(String tokens);

  /// No description provided for @systemSlotsBusy.
  ///
  /// In en, this message translates to:
  /// **'{busy} / {total} busy'**
  String systemSlotsBusy(int busy, int total);

  /// No description provided for @systemSlotsIdle.
  ///
  /// In en, this message translates to:
  /// **'{busy} / {total}'**
  String systemSlotsIdle(int busy, int total);

  /// No description provided for @systemTps.
  ///
  /// In en, this message translates to:
  /// **'{tps} tok/s'**
  String systemTps(String tps);

  /// No description provided for @systemStop.
  ///
  /// In en, this message translates to:
  /// **'Stop llama-server'**
  String get systemStop;

  /// No description provided for @systemStart.
  ///
  /// In en, this message translates to:
  /// **'Start llama-server'**
  String get systemStart;

  /// No description provided for @systemStopping.
  ///
  /// In en, this message translates to:
  /// **'Stopping…'**
  String get systemStopping;

  /// No description provided for @systemStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get systemStarting;

  /// No description provided for @systemGpus.
  ///
  /// In en, this message translates to:
  /// **'GPUs'**
  String get systemGpus;

  /// No description provided for @systemGpuSource.
  ///
  /// In en, this message translates to:
  /// **'nvidia-smi · {age}'**
  String systemGpuSource(String age);

  /// No description provided for @systemGpuCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 GPU} other{{count} GPUs}}'**
  String systemGpuCount(int count);

  /// No description provided for @systemTitle.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTitle;

  /// No description provided for @systemHermesShort.
  ///
  /// In en, this message translates to:
  /// **'Hermes'**
  String get systemHermesShort;

  /// No description provided for @systemStateRunning.
  ///
  /// In en, this message translates to:
  /// **'running'**
  String get systemStateRunning;

  /// No description provided for @systemStateLoading.
  ///
  /// In en, this message translates to:
  /// **'loading'**
  String get systemStateLoading;

  /// No description provided for @systemStateStarting.
  ///
  /// In en, this message translates to:
  /// **'starting'**
  String get systemStateStarting;

  /// No description provided for @systemStateStopping.
  ///
  /// In en, this message translates to:
  /// **'stopping'**
  String get systemStateStopping;

  /// No description provided for @systemStateStopped.
  ///
  /// In en, this message translates to:
  /// **'stopped'**
  String get systemStateStopped;

  /// No description provided for @systemStateFailed.
  ///
  /// In en, this message translates to:
  /// **'failed'**
  String get systemStateFailed;

  /// No description provided for @systemStateDown.
  ///
  /// In en, this message translates to:
  /// **'unreachable'**
  String get systemStateDown;

  /// No description provided for @systemStateUnknown.
  ///
  /// In en, this message translates to:
  /// **'unknown'**
  String get systemStateUnknown;

  /// No description provided for @systemStateOk.
  ///
  /// In en, this message translates to:
  /// **'ok'**
  String get systemStateOk;

  /// No description provided for @systemStateDegraded.
  ///
  /// In en, this message translates to:
  /// **'degraded'**
  String get systemStateDegraded;

  /// No description provided for @systemHelperMissing.
  ///
  /// In en, this message translates to:
  /// **'The server can\'t reach its system helper: no GPU data, and llama-server can\'t be stopped or started from here.'**
  String get systemHelperMissing;

  /// No description provided for @systemHelperProblem.
  ///
  /// In en, this message translates to:
  /// **'Part of the system view is missing: {reason}'**
  String systemHelperProblem(String reason);

  /// No description provided for @systemHeldQueue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Messages you send wait until llama-server is back.} =1{1 message waits until llama-server is back.} other{{count} messages wait until llama-server is back.}}'**
  String systemHeldQueue(int count);

  /// No description provided for @systemLoadingNote.
  ///
  /// In en, this message translates to:
  /// **'Waiting messages start once the model is loaded.'**
  String get systemLoadingNote;

  /// No description provided for @systemStopTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop llama-server?'**
  String get systemStopTitle;

  /// No description provided for @systemStopActive.
  ///
  /// In en, this message translates to:
  /// **'The active run will be stopped.'**
  String get systemStopActive;

  /// No description provided for @systemStopQueued.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 queued message waits until you start it again.} other{{count} queued messages wait until you start it again.}}'**
  String systemStopQueued(int count);

  /// No description provided for @systemStopBody.
  ///
  /// In en, this message translates to:
  /// **'Hermes keeps running, and you can start llama-server again from here.'**
  String get systemStopBody;

  /// No description provided for @systemStopConfirm.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get systemStopConfirm;

  /// No description provided for @systemRunStarted.
  ///
  /// In en, this message translates to:
  /// **'A run just started. Check the queue and try again.'**
  String get systemRunStarted;

  /// No description provided for @systemStopFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t stop llama-server: {reason}'**
  String systemStopFailed(String reason);

  /// No description provided for @systemStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start llama-server: {reason}'**
  String systemStartFailed(String reason);

  /// No description provided for @systemLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the system view: {reason}'**
  String systemLoadFailed(String reason);

  /// No description provided for @schedulesNew.
  ///
  /// In en, this message translates to:
  /// **'New schedule'**
  String get schedulesNew;

  /// No description provided for @schedulesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'A schedule sends a prompt to the agent at set times, in a new chat each time or always in the same one.'**
  String get schedulesEmptyBody;

  /// No description provided for @schedulesRunNow.
  ///
  /// In en, this message translates to:
  /// **'Run now'**
  String get schedulesRunNow;

  /// No description provided for @schedulesPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get schedulesPaused;

  /// No description provided for @schedulesNextRun.
  ///
  /// In en, this message translates to:
  /// **'Next run {when}'**
  String schedulesNextRun(String when);

  /// No description provided for @schedulesNextRunIn.
  ///
  /// In en, this message translates to:
  /// **'Next run in {wait} · {when}'**
  String schedulesNextRunIn(String wait, String when);

  /// No description provided for @schedulesLastRun.
  ///
  /// In en, this message translates to:
  /// **'Last run {when} · {status}'**
  String schedulesLastRun(String when, String status);

  /// No description provided for @schedulesNotRunYet.
  ///
  /// In en, this message translates to:
  /// **'Not run yet'**
  String get schedulesNotRunYet;

  /// No description provided for @schedulesStatusOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get schedulesStatusOk;

  /// No description provided for @schedulesStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get schedulesStatusFailed;

  /// No description provided for @schedulesStatusStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get schedulesStatusStopped;

  /// No description provided for @schedulesStatusRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get schedulesStatusRunning;

  /// No description provided for @schedulesStatusQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get schedulesStatusQueued;

  /// No description provided for @schedulesToday.
  ///
  /// In en, this message translates to:
  /// **'today {time}'**
  String schedulesToday(String time);

  /// No description provided for @schedulesTomorrow.
  ///
  /// In en, this message translates to:
  /// **'tomorrow {time}'**
  String schedulesTomorrow(String time);

  /// No description provided for @schedulesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load schedules: {reason}'**
  String schedulesLoadFailed(String reason);

  /// No description provided for @schedulesSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save: {reason}'**
  String schedulesSaveFailed(String reason);

  /// No description provided for @schedulesRunFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t run it: {reason}'**
  String schedulesRunFailed(String reason);

  /// No description provided for @schedulesRunQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued — the answer arrives in its chat.'**
  String get schedulesRunQueued;

  /// No description provided for @schedulesBriefWritten.
  ///
  /// In en, this message translates to:
  /// **'Morning brief written — it\'s on the dashboard.'**
  String get schedulesBriefWritten;

  /// No description provided for @schedulesEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Every day at {times}'**
  String schedulesEveryDay(String times);

  /// No description provided for @schedulesWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Weekdays at {time}'**
  String schedulesWeekdays(String time);

  /// No description provided for @schedulesWeekends.
  ///
  /// In en, this message translates to:
  /// **'Weekends at {time}'**
  String schedulesWeekends(String time);

  /// No description provided for @schedulesEveryWeek.
  ///
  /// In en, this message translates to:
  /// **'{day}s at {time}'**
  String schedulesEveryWeek(String day, String time);

  /// No description provided for @schedulesOnDays.
  ///
  /// In en, this message translates to:
  /// **'{days} at {time}'**
  String schedulesOnDays(String days, String time);

  /// No description provided for @schedulesListAnd.
  ///
  /// In en, this message translates to:
  /// **'{head} and {last}'**
  String schedulesListAnd(String head, String last);

  /// No description provided for @schedEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit schedule'**
  String get schedEditTitle;

  /// No description provided for @schedNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New schedule'**
  String get schedNewTitle;

  /// No description provided for @schedSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get schedSave;

  /// No description provided for @schedName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get schedName;

  /// No description provided for @schedRepeats.
  ///
  /// In en, this message translates to:
  /// **'Repeats'**
  String get schedRepeats;

  /// No description provided for @schedDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get schedDaily;

  /// No description provided for @schedWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get schedWeekly;

  /// No description provided for @schedCron.
  ///
  /// In en, this message translates to:
  /// **'Cron'**
  String get schedCron;

  /// No description provided for @schedAddTime.
  ///
  /// In en, this message translates to:
  /// **'Add time'**
  String get schedAddTime;

  /// No description provided for @schedRemoveTime.
  ///
  /// In en, this message translates to:
  /// **'Remove {time}'**
  String schedRemoveTime(String time);

  /// No description provided for @schedSameMinute.
  ///
  /// In en, this message translates to:
  /// **'Several times a day must share the minute past the hour (a cron limit). Use Cron for anything else.'**
  String get schedSameMinute;

  /// No description provided for @schedNoTime.
  ///
  /// In en, this message translates to:
  /// **'Add a time.'**
  String get schedNoTime;

  /// No description provided for @schedNoDay.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one day.'**
  String get schedNoDay;

  /// No description provided for @schedCronHelp.
  ///
  /// In en, this message translates to:
  /// **'minute · hour · day · month · weekday, in Budapest time'**
  String get schedCronHelp;

  /// No description provided for @schedCronInvalid.
  ///
  /// In en, this message translates to:
  /// **'Five fields: minute hour day month weekday.'**
  String get schedCronInvalid;

  /// No description provided for @schedPrompt.
  ///
  /// In en, this message translates to:
  /// **'Prompt'**
  String get schedPrompt;

  /// No description provided for @schedPostTo.
  ///
  /// In en, this message translates to:
  /// **'Post results to'**
  String get schedPostTo;

  /// No description provided for @schedNewChat.
  ///
  /// In en, this message translates to:
  /// **'New chat for each run'**
  String get schedNewChat;

  /// No description provided for @schedFixedChat.
  ///
  /// In en, this message translates to:
  /// **'Fixed chat'**
  String get schedFixedChat;

  /// No description provided for @schedPickChat.
  ///
  /// In en, this message translates to:
  /// **'Pick a chat'**
  String get schedPickChat;

  /// No description provided for @schedNoChats.
  ///
  /// In en, this message translates to:
  /// **'No chats yet. Start one first.'**
  String get schedNoChats;

  /// No description provided for @schedThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking'**
  String get schedThinking;

  /// No description provided for @schedThinkingSub.
  ///
  /// In en, this message translates to:
  /// **'Off is faster for short, routine prompts'**
  String get schedThinkingSub;

  /// No description provided for @schedDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete schedule'**
  String get schedDelete;

  /// No description provided for @schedDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”?'**
  String schedDeleteTitle(String name);

  /// No description provided for @schedDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Its past runs stay in their chats.'**
  String get schedDeleteBody;

  /// No description provided for @schedDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get schedDeleteConfirm;

  /// No description provided for @schedBriefNote.
  ///
  /// In en, this message translates to:
  /// **'The morning brief is written by the server without the model: uptime, package updates, open incidents, llama-server and the water level.'**
  String get schedBriefNote;

  /// No description provided for @schedMissing.
  ///
  /// In en, this message translates to:
  /// **'This schedule no longer exists.'**
  String get schedMissing;

  /// No description provided for @schedErrInvalidCron.
  ///
  /// In en, this message translates to:
  /// **'Not a valid cron expression.'**
  String get schedErrInvalidCron;

  /// No description provided for @schedErrTooFrequent.
  ///
  /// In en, this message translates to:
  /// **'A schedule may run at most every 10 minutes.'**
  String get schedErrTooFrequent;

  /// No description provided for @schedErrName.
  ///
  /// In en, this message translates to:
  /// **'Give it a name (at most 64 characters).'**
  String get schedErrName;

  /// No description provided for @schedErrPrompt.
  ///
  /// In en, this message translates to:
  /// **'Write a prompt.'**
  String get schedErrPrompt;

  /// No description provided for @schedErrChat.
  ///
  /// In en, this message translates to:
  /// **'Pick a chat that still exists.'**
  String get schedErrChat;

  /// No description provided for @dashBriefTitle.
  ///
  /// In en, this message translates to:
  /// **'Morning brief'**
  String get dashBriefTitle;

  /// No description provided for @dashBriefUptime.
  ///
  /// In en, this message translates to:
  /// **'Uptime'**
  String get dashBriefUptime;

  /// No description provided for @dashBriefUpdates.
  ///
  /// In en, this message translates to:
  /// **'Package updates'**
  String get dashBriefUpdates;

  /// No description provided for @dashBriefIncidents.
  ///
  /// In en, this message translates to:
  /// **'Open incidents'**
  String get dashBriefIncidents;

  /// No description provided for @dashBriefLastBoot.
  ///
  /// In en, this message translates to:
  /// **'Last boot'**
  String get dashBriefLastBoot;

  /// No description provided for @dashBriefMissing.
  ///
  /// In en, this message translates to:
  /// **'Not available this morning: {sources}'**
  String dashBriefMissing(String sources);

  /// No description provided for @notifyBriefTitle.
  ///
  /// In en, this message translates to:
  /// **'Morning brief · up {uptime}'**
  String notifyBriefTitle(String uptime);

  /// No description provided for @notifyBriefTitlePlain.
  ///
  /// In en, this message translates to:
  /// **'Morning brief'**
  String get notifyBriefTitlePlain;

  /// No description provided for @notifyBriefUpdates.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no updates} =1{1 update} other{{count} updates}}'**
  String notifyBriefUpdates(int count);

  /// No description provided for @notifyBriefIncidents.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no open incidents} =1{1 open incident} other{{count} open incidents}}'**
  String notifyBriefIncidents(int count);

  /// No description provided for @notifyBriefLlama.
  ///
  /// In en, this message translates to:
  /// **'llama-server {state}'**
  String notifyBriefLlama(String state);

  /// No description provided for @notifyBriefWater.
  ///
  /// In en, this message translates to:
  /// **'water {level} cm'**
  String notifyBriefWater(String level);

  /// No description provided for @obsRange24h.
  ///
  /// In en, this message translates to:
  /// **'24 h'**
  String get obsRange24h;

  /// No description provided for @obsRange7d.
  ///
  /// In en, this message translates to:
  /// **'7 d'**
  String get obsRange7d;

  /// No description provided for @obsRange30d.
  ///
  /// In en, this message translates to:
  /// **'30 d'**
  String get obsRange30d;

  /// No description provided for @obsGeneration.
  ///
  /// In en, this message translates to:
  /// **'Generation'**
  String get obsGeneration;

  /// No description provided for @obsPrefill.
  ///
  /// In en, this message translates to:
  /// **'Prefill'**
  String get obsPrefill;

  /// No description provided for @obsPrefillNote.
  ///
  /// In en, this message translates to:
  /// **'prompts ≥ {tokens} tok'**
  String obsPrefillNote(int tokens);

  /// No description provided for @obsQueue.
  ///
  /// In en, this message translates to:
  /// **'Queue length'**
  String get obsQueue;

  /// No description provided for @obsApprovalLatency.
  ///
  /// In en, this message translates to:
  /// **'Approval latency'**
  String get obsApprovalLatency;

  /// No description provided for @obsMedianPerHour.
  ///
  /// In en, this message translates to:
  /// **'median per hour'**
  String get obsMedianPerHour;

  /// No description provided for @obsMedianPer6h.
  ///
  /// In en, this message translates to:
  /// **'median per 6 h'**
  String get obsMedianPer6h;

  /// No description provided for @obsMedianPerDay.
  ///
  /// In en, this message translates to:
  /// **'median per day'**
  String get obsMedianPerDay;

  /// No description provided for @obsCacheHit.
  ///
  /// In en, this message translates to:
  /// **'Cache hit ratio'**
  String get obsCacheHit;

  /// No description provided for @obsTokensPerDay.
  ///
  /// In en, this message translates to:
  /// **'Tokens per day'**
  String get obsTokensPerDay;

  /// No description provided for @obsLastDays.
  ///
  /// In en, this message translates to:
  /// **'last {days} d'**
  String obsLastDays(int days);

  /// No description provided for @obsGpuTemp.
  ///
  /// In en, this message translates to:
  /// **'GPU temperature'**
  String get obsGpuTemp;

  /// No description provided for @obsGpuPower.
  ///
  /// In en, this message translates to:
  /// **'GPU power'**
  String get obsGpuPower;

  /// No description provided for @obsTokPerS.
  ///
  /// In en, this message translates to:
  /// **'{value} tok/s'**
  String obsTokPerS(String value);

  /// No description provided for @obsNoRuns.
  ///
  /// In en, this message translates to:
  /// **'No runs in this range'**
  String get obsNoRuns;

  /// No description provided for @obsNoApprovals.
  ///
  /// In en, this message translates to:
  /// **'No answered approvals'**
  String get obsNoApprovals;

  /// No description provided for @obsNoSamples.
  ///
  /// In en, this message translates to:
  /// **'No GPU samples yet'**
  String get obsNoSamples;

  /// No description provided for @obsSamplingFailed.
  ///
  /// In en, this message translates to:
  /// **'GPU sampling fails: {reason}'**
  String obsSamplingFailed(String reason);

  /// No description provided for @obsSamplingOff.
  ///
  /// In en, this message translates to:
  /// **'GPU sampling is off on the server'**
  String get obsSamplingOff;

  /// No description provided for @obsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the statistics: {reason}'**
  String obsLoadFailed(String reason);

  /// No description provided for @shareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share to Delve'**
  String get shareTitle;

  /// No description provided for @shareSendTo.
  ///
  /// In en, this message translates to:
  /// **'Send to'**
  String get shareSendTo;

  /// No description provided for @shareExisting.
  ///
  /// In en, this message translates to:
  /// **'Existing chats'**
  String get shareExisting;

  /// No description provided for @shareNewChatThinkingOn.
  ///
  /// In en, this message translates to:
  /// **'Thinking on · starts a new conversation'**
  String get shareNewChatThinkingOn;

  /// No description provided for @shareNewChatThinkingOff.
  ///
  /// In en, this message translates to:
  /// **'Thinking off · starts a new conversation'**
  String get shareNewChatThinkingOff;

  /// No description provided for @shareUnreadable.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 shared item could not be read} other{{count} shared items could not be read}}'**
  String shareUnreadable(int count);

  /// No description provided for @dashBriefLate.
  ///
  /// In en, this message translates to:
  /// **'{time} · {late} late'**
  String dashBriefLate(String time, String late);

  /// No description provided for @dashWatchesActive.
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String dashWatchesActive(int count);

  /// No description provided for @dashWatchesNext.
  ///
  /// In en, this message translates to:
  /// **'Next check {when}'**
  String dashWatchesNext(String when);

  /// No description provided for @dashWatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Watches'**
  String get dashWatchesTitle;

  /// No description provided for @linkOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the link — it\'s copied'**
  String get linkOpenFailed;

  /// No description provided for @moreWatches.
  ///
  /// In en, this message translates to:
  /// **'Watches'**
  String get moreWatches;

  /// No description provided for @moreWatchesSub.
  ///
  /// In en, this message translates to:
  /// **'Listings and tickets the agent checks for you'**
  String get moreWatchesSub;

  /// No description provided for @notifyBriefLate.
  ///
  /// In en, this message translates to:
  /// **'{late} late'**
  String notifyBriefLate(String late);

  /// No description provided for @notifyChannelWatches.
  ///
  /// In en, this message translates to:
  /// **'Watches'**
  String get notifyChannelWatches;

  /// No description provided for @notifyChannelWatchesDesc.
  ///
  /// In en, this message translates to:
  /// **'When a watch finds something new'**
  String get notifyChannelWatchesDesc;

  /// No description provided for @notifyOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get notifyOpenLink;

  /// No description provided for @notifyWatchAvailable.
  ///
  /// In en, this message translates to:
  /// **'Now available · {name}'**
  String notifyWatchAvailable(String name);

  /// No description provided for @notifyWatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Watch · {name}'**
  String notifyWatchTitle(String name);

  /// No description provided for @runFailedCutOff.
  ///
  /// In en, this message translates to:
  /// **'The answer was cut off: the agent ran out of room. Try a new chat or a shorter request.'**
  String get runFailedCutOff;

  /// No description provided for @settingsNotifyWatches.
  ///
  /// In en, this message translates to:
  /// **'Watch hits'**
  String get settingsNotifyWatches;

  /// No description provided for @settingsNotifyWatchesSub.
  ///
  /// In en, this message translates to:
  /// **'When a watch finds something new'**
  String get settingsNotifyWatchesSub;

  /// No description provided for @watchActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t change the watch: {reason}'**
  String watchActionFailed(String reason);

  /// No description provided for @watchChangeDraft.
  ///
  /// In en, this message translates to:
  /// **'Change the watch “{name}”: '**
  String watchChangeDraft(String name);

  /// No description provided for @watchChangeInChat.
  ///
  /// In en, this message translates to:
  /// **'Change in chat'**
  String get watchChangeInChat;

  /// No description provided for @watchCondition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get watchCondition;

  /// No description provided for @watchCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get watchCopyLink;

  /// No description provided for @watchDetailsOn.
  ///
  /// In en, this message translates to:
  /// **'On — opens each new listing'**
  String get watchDetailsOn;

  /// No description provided for @watchDetailsPages.
  ///
  /// In en, this message translates to:
  /// **'Details pages'**
  String get watchDetailsPages;

  /// No description provided for @watchErrorsInRow.
  ///
  /// In en, this message translates to:
  /// **'{count} errors in a row'**
  String watchErrorsInRow(int count);

  /// No description provided for @watchEveryHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every hour} other{Every {count} hours}}'**
  String watchEveryHours(int count);

  /// No description provided for @watchEveryMinutes.
  ///
  /// In en, this message translates to:
  /// **'Every {count} minutes'**
  String watchEveryMinutes(int count);

  /// No description provided for @watchExampleCinema.
  ///
  /// In en, this message translates to:
  /// **'Tell me when tickets for <film> are on sale at Cinema City.'**
  String get watchExampleCinema;

  /// No description provided for @watchExampleHardverapro.
  ///
  /// In en, this message translates to:
  /// **'Watch Hardverapró for RTX 4070 Supers under 180 000 Ft, not used for mining, three times a day.'**
  String get watchExampleHardverapro;

  /// No description provided for @watchFixDraft.
  ///
  /// In en, this message translates to:
  /// **'The watch “{name}” keeps failing ({error}). Check it and fix it.'**
  String watchFixDraft(String name, String error);

  /// No description provided for @watchFixInChat.
  ///
  /// In en, this message translates to:
  /// **'Fix in chat'**
  String get watchFixInChat;

  /// No description provided for @watchGone.
  ///
  /// In en, this message translates to:
  /// **'This watch is gone: it was deleted in a chat, or the desktop no longer has it.'**
  String get watchGone;

  /// No description provided for @watchHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what to watch, where, how often, and what counts.'**
  String get watchHint;

  /// No description provided for @watchHits.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Hits} other{Hits · {count}}}'**
  String watchHits(int count);

  /// No description provided for @watchHits24h.
  ///
  /// In en, this message translates to:
  /// **'{count} in the last 24 h'**
  String watchHits24h(int count);

  /// No description provided for @watchItemAvailable.
  ///
  /// In en, this message translates to:
  /// **'Now available'**
  String get watchItemAvailable;

  /// No description provided for @watchItemByFilters.
  ///
  /// In en, this message translates to:
  /// **'Matched by filters · no judge'**
  String get watchItemByFilters;

  /// No description provided for @watchItemCouldntJudge.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t judge'**
  String get watchItemCouldntJudge;

  /// No description provided for @watchItemOnHold.
  ///
  /// In en, this message translates to:
  /// **'On hold'**
  String get watchItemOnHold;

  /// No description provided for @watchItemWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for judge'**
  String get watchItemWaiting;

  /// No description provided for @watchKeywords.
  ///
  /// In en, this message translates to:
  /// **'Keywords'**
  String get watchKeywords;

  /// No description provided for @watchKeywordsAny.
  ///
  /// In en, this message translates to:
  /// **'any of {words}'**
  String watchKeywordsAny(String words);

  /// No description provided for @watchKeywordsNot.
  ///
  /// In en, this message translates to:
  /// **'not {words}'**
  String watchKeywordsNot(String words);

  /// No description provided for @watchLastCheck.
  ///
  /// In en, this message translates to:
  /// **'Last check'**
  String get watchLastCheck;

  /// No description provided for @watchListings.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 listing} other{{count} listings}}'**
  String watchListings(int count);

  /// No description provided for @watchLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get watchLoadMore;

  /// No description provided for @watchMatches.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 match} other{{count} matches}}'**
  String watchMatches(int count);

  /// No description provided for @watchNew.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new} other{{count} new}}'**
  String watchNew(int count);

  /// No description provided for @watchNextCheck.
  ///
  /// In en, this message translates to:
  /// **'Next check'**
  String get watchNextCheck;

  /// No description provided for @watchNextIn.
  ///
  /// In en, this message translates to:
  /// **'{when} · in {wait}'**
  String watchNextIn(String when, String wait);

  /// No description provided for @watchNextPaused.
  ///
  /// In en, this message translates to:
  /// **'— paused'**
  String get watchNextPaused;

  /// No description provided for @watchNoCondition.
  ///
  /// In en, this message translates to:
  /// **'No condition — filters only'**
  String get watchNoCondition;

  /// No description provided for @watchNoHits.
  ///
  /// In en, this message translates to:
  /// **'No hits yet.'**
  String get watchNoHits;

  /// No description provided for @watchNoHitsYet.
  ///
  /// In en, this message translates to:
  /// **'No hits yet'**
  String get watchNoHitsYet;

  /// No description provided for @watchOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get watchOff;

  /// No description provided for @watchOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get watchOn;

  /// No description provided for @watchOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get watchOpenLink;

  /// No description provided for @watchPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get watchPause;

  /// No description provided for @watchPending.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 listing waits for the judge} other{{count} listings wait for the judge}}'**
  String watchPending(int count);

  /// No description provided for @watchPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get watchPrice;

  /// No description provided for @watchRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected ({count})'**
  String watchRejected(int count);

  /// No description provided for @watchResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get watchResume;

  /// No description provided for @watchRunNow.
  ///
  /// In en, this message translates to:
  /// **'Run now'**
  String get watchRunNow;

  /// No description provided for @watchRunStarted.
  ///
  /// In en, this message translates to:
  /// **'Checking now — new hits show up here in a minute'**
  String get watchRunStarted;

  /// No description provided for @watchSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get watchSchedule;

  /// No description provided for @watchSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get watchSearch;

  /// No description provided for @watchSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get watchSource;

  /// No description provided for @watchSourcePage.
  ///
  /// In en, this message translates to:
  /// **'Web page'**
  String get watchSourcePage;

  /// No description provided for @watchStateActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get watchStateActive;

  /// No description provided for @watchStateError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get watchStateError;

  /// No description provided for @watchStatePaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get watchStatePaused;

  /// No description provided for @watchStateStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped after hit'**
  String get watchStateStopped;

  /// No description provided for @watchStateUnknown.
  ///
  /// In en, this message translates to:
  /// **'Setting up'**
  String get watchStateUnknown;

  /// No description provided for @watchStopAfterHit.
  ///
  /// In en, this message translates to:
  /// **'Stop after hit'**
  String get watchStopAfterHit;

  /// No description provided for @watchStoppedAfterHit.
  ///
  /// In en, this message translates to:
  /// **'Paused after its first hit · {when}'**
  String watchStoppedAfterHit(String when);

  /// No description provided for @watchYesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday {time}'**
  String watchYesterday(String time);

  /// No description provided for @watchesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Watches are made in a chat: describe what to watch, where, how often and what counts. They run on a schedule without the model.'**
  String get watchesEmptyBody;

  /// No description provided for @watchesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No watches yet'**
  String get watchesEmptyTitle;

  /// No description provided for @watchesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load watches: {reason}'**
  String watchesLoadFailed(String reason);

  /// No description provided for @watchesNew.
  ///
  /// In en, this message translates to:
  /// **'New watch'**
  String get watchesNew;

  /// No description provided for @watchesNote.
  ///
  /// In en, this message translates to:
  /// **'Watches run on a schedule without the model. New ones and changes are made in a chat.'**
  String get watchesNote;

  /// No description provided for @navTerminal.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get navTerminal;

  /// No description provided for @settingsTerminal.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get settingsTerminal;

  /// No description provided for @termTitle.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get termTitle;

  /// No description provided for @termSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set up once · the key never leaves this phone'**
  String get termSetupSubtitle;

  /// No description provided for @termStepKey.
  ///
  /// In en, this message translates to:
  /// **'This phone\'s key'**
  String get termStepKey;

  /// No description provided for @termStepKeyBody.
  ///
  /// In en, this message translates to:
  /// **'Delve generated a key for this phone. Add this line to ~/.ssh/authorized_keys on the desktop.'**
  String get termStepKeyBody;

  /// No description provided for @termKeyLine.
  ///
  /// In en, this message translates to:
  /// **'authorized_keys line'**
  String get termKeyLine;

  /// No description provided for @termKeyCommand.
  ///
  /// In en, this message translates to:
  /// **'Or run this on the desktop'**
  String get termKeyCommand;

  /// No description provided for @termStepHost.
  ///
  /// In en, this message translates to:
  /// **'Host and port'**
  String get termStepHost;

  /// No description provided for @termStepHostBody.
  ///
  /// In en, this message translates to:
  /// **'From the paired server. Change them if sshd listens elsewhere.'**
  String get termStepHostBody;

  /// No description provided for @termHost.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get termHost;

  /// No description provided for @termUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get termUser;

  /// No description provided for @termPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get termPort;

  /// No description provided for @termStepVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify the desktop'**
  String get termStepVerify;

  /// No description provided for @termStepVerifyBody.
  ///
  /// In en, this message translates to:
  /// **'After Connect, compare the host key fingerprint.'**
  String get termStepVerifyBody;

  /// No description provided for @termVerifyBody.
  ///
  /// In en, this message translates to:
  /// **'Compare this with the desktop\'s key. If one group differs, cancel.'**
  String get termVerifyBody;

  /// No description provided for @termVerifyCommand.
  ///
  /// In en, this message translates to:
  /// **'On the desktop'**
  String get termVerifyCommand;

  /// No description provided for @termTrust.
  ///
  /// In en, this message translates to:
  /// **'Trust and connect'**
  String get termTrust;

  /// No description provided for @termConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get termConnect;

  /// No description provided for @termConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get termConnecting;

  /// No description provided for @termReconnectingNow.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get termReconnectingNow;

  /// No description provided for @termDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied – is the line in authorized_keys?'**
  String get termDenied;

  /// No description provided for @termCheckModes.
  ///
  /// In en, this message translates to:
  /// **'~/.ssh is 0700 and authorized_keys is 0600'**
  String get termCheckModes;

  /// No description provided for @termCheckTailnet.
  ///
  /// In en, this message translates to:
  /// **'This phone is on the tailnet (Tailscale is on)'**
  String get termCheckTailnet;

  /// No description provided for @termCopyLine.
  ///
  /// In en, this message translates to:
  /// **'Copy the line'**
  String get termCopyLine;

  /// No description provided for @termTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get termTryAgain;

  /// No description provided for @termNotTrusted.
  ///
  /// In en, this message translates to:
  /// **'The desktop\'s key was not trusted. Connect again to check it.'**
  String get termNotTrusted;

  /// No description provided for @termHostChangedLine.
  ///
  /// In en, this message translates to:
  /// **'Host key changed – connection refused'**
  String get termHostChangedLine;

  /// No description provided for @termHostChangedTitle.
  ///
  /// In en, this message translates to:
  /// **'Host key changed'**
  String get termHostChangedTitle;

  /// No description provided for @termHostChangedBody.
  ///
  /// In en, this message translates to:
  /// **'The desktop answered with a different key than the one you trusted. Someone may be in between, or the desktop\'s keys were replaced.'**
  String get termHostChangedBody;

  /// No description provided for @termShowDetails.
  ///
  /// In en, this message translates to:
  /// **'Show details'**
  String get termShowDetails;

  /// No description provided for @termTrusted.
  ///
  /// In en, this message translates to:
  /// **'Trusted'**
  String get termTrusted;

  /// No description provided for @termReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get termReceived;

  /// No description provided for @termForgetVerify.
  ///
  /// In en, this message translates to:
  /// **'Forget and verify again'**
  String get termForgetVerify;

  /// No description provided for @termNextNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get termNextNow;

  /// No description provided for @termOfflineUser.
  ///
  /// In en, this message translates to:
  /// **'Disconnected – tap to reconnect'**
  String get termOfflineUser;

  /// No description provided for @termOfflineEnded.
  ///
  /// In en, this message translates to:
  /// **'Session ended – tap to start it again'**
  String get termOfflineEnded;

  /// No description provided for @termOfflineBackground.
  ///
  /// In en, this message translates to:
  /// **'Paused in the background – tap to reconnect'**
  String get termOfflineBackground;

  /// No description provided for @termStateConnected.
  ///
  /// In en, this message translates to:
  /// **'connected'**
  String get termStateConnected;

  /// No description provided for @termStateConnecting.
  ///
  /// In en, this message translates to:
  /// **'connecting'**
  String get termStateConnecting;

  /// No description provided for @termStateReconnecting.
  ///
  /// In en, this message translates to:
  /// **'reconnecting'**
  String get termStateReconnecting;

  /// No description provided for @termStateDisconnected.
  ///
  /// In en, this message translates to:
  /// **'disconnected'**
  String get termStateDisconnected;

  /// No description provided for @termStateRefused.
  ///
  /// In en, this message translates to:
  /// **'refused'**
  String get termStateRefused;

  /// No description provided for @termMenu.
  ///
  /// In en, this message translates to:
  /// **'Terminal menu'**
  String get termMenu;

  /// No description provided for @termMenuSettings.
  ///
  /// In en, this message translates to:
  /// **'Terminal settings'**
  String get termMenuSettings;

  /// No description provided for @termMenuDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get termMenuDisconnect;

  /// No description provided for @termMenuReconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get termMenuReconnect;

  /// No description provided for @termMenuCopyTrace.
  ///
  /// In en, this message translates to:
  /// **'Copy connection trace'**
  String get termMenuCopyTrace;

  /// No description provided for @termTraceCopied.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Copied 1 trace line} other{Copied {count} trace lines}}'**
  String termTraceCopied(int count);

  /// No description provided for @termKeyCtrl.
  ///
  /// In en, this message translates to:
  /// **'Control'**
  String get termKeyCtrl;

  /// No description provided for @termKeyAlt.
  ///
  /// In en, this message translates to:
  /// **'Alt'**
  String get termKeyAlt;

  /// No description provided for @termLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock the terminal'**
  String get termLockTitle;

  /// No description provided for @termLockBody.
  ///
  /// In en, this message translates to:
  /// **'Locked after 15 min of inactivity. Your session keeps running on the desktop.'**
  String get termLockBody;

  /// No description provided for @termUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get termUnlock;

  /// No description provided for @termUnlockReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock the Delve terminal'**
  String get termUnlockReason;

  /// No description provided for @termSettingsConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get termSettingsConnection;

  /// No description provided for @termBackground.
  ///
  /// In en, this message translates to:
  /// **'Keep connected in background'**
  String get termBackground;

  /// No description provided for @termBackgroundSub.
  ///
  /// In en, this message translates to:
  /// **'The tab in front stays connected while Delve is in the background, so it is ready at once when you come back. Uses a little more battery; a quiet notification shows it.'**
  String get termBackgroundSub;

  /// No description provided for @termBackgroundNoStart.
  ///
  /// In en, this message translates to:
  /// **'Android did not let the background connection start'**
  String get termBackgroundNoStart;

  /// No description provided for @termBackgroundBattery.
  ///
  /// In en, this message translates to:
  /// **'Allow Delve to run without battery limits, or Android may still cut the connection'**
  String get termBackgroundBattery;

  /// No description provided for @termHostPort.
  ///
  /// In en, this message translates to:
  /// **'Host & port'**
  String get termHostPort;

  /// No description provided for @termLockRow.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get termLockRow;

  /// No description provided for @termLockRowSub.
  ///
  /// In en, this message translates to:
  /// **'After 15 min of inactivity'**
  String get termLockRowSub;

  /// No description provided for @termDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get termDisplay;

  /// No description provided for @termFontSize.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get termFontSize;

  /// No description provided for @termFontSmaller.
  ///
  /// In en, this message translates to:
  /// **'Smaller'**
  String get termFontSmaller;

  /// No description provided for @termFontBigger.
  ///
  /// In en, this message translates to:
  /// **'Bigger'**
  String get termFontBigger;

  /// No description provided for @termPhoneKey.
  ///
  /// In en, this message translates to:
  /// **'This phone\'s key'**
  String get termPhoneKey;

  /// No description provided for @termShowLine.
  ///
  /// In en, this message translates to:
  /// **'Show the authorized_keys line'**
  String get termShowLine;

  /// No description provided for @termShowLineSub.
  ///
  /// In en, this message translates to:
  /// **'To add on the desktop'**
  String get termShowLineSub;

  /// No description provided for @termRegenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate key'**
  String get termRegenerate;

  /// No description provided for @termRegenerateSub.
  ///
  /// In en, this message translates to:
  /// **'The old line stops working'**
  String get termRegenerateSub;

  /// No description provided for @termRegenerateTitle.
  ///
  /// In en, this message translates to:
  /// **'Regenerate the key?'**
  String get termRegenerateTitle;

  /// No description provided for @termRegenerateBody.
  ///
  /// In en, this message translates to:
  /// **'The desktop refuses this phone until you add the new line to ~/.ssh/authorized_keys.'**
  String get termRegenerateBody;

  /// No description provided for @termRegenerateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get termRegenerateConfirm;

  /// No description provided for @termRegenerated.
  ///
  /// In en, this message translates to:
  /// **'New key made – add its line on the desktop'**
  String get termRegenerated;

  /// No description provided for @termHostKey.
  ///
  /// In en, this message translates to:
  /// **'Host key'**
  String get termHostKey;

  /// No description provided for @termHostKeyNone.
  ///
  /// In en, this message translates to:
  /// **'Not verified yet'**
  String get termHostKeyNone;

  /// No description provided for @termHostKeyTrustedUndated.
  ///
  /// In en, this message translates to:
  /// **'Trusted'**
  String get termHostKeyTrustedUndated;

  /// No description provided for @termForgetHostKey.
  ///
  /// In en, this message translates to:
  /// **'Forget host key'**
  String get termForgetHostKey;

  /// No description provided for @termForgetHostKeyBody.
  ///
  /// In en, this message translates to:
  /// **'The next connection shows the desktop\'s fingerprint again.'**
  String get termForgetHostKeyBody;

  /// No description provided for @termForgetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Forget'**
  String get termForgetConfirm;

  /// No description provided for @termSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get termSave;

  /// No description provided for @settingsTerminalSub.
  ///
  /// In en, this message translates to:
  /// **'Background connection off · port {port}'**
  String settingsTerminalSub(int port);

  /// No description provided for @settingsTerminalSubOn.
  ///
  /// In en, this message translates to:
  /// **'Background connection on · port {port}'**
  String settingsTerminalSubOn(int port);

  /// No description provided for @termCheckLine.
  ///
  /// In en, this message translates to:
  /// **'The line is in ~/.ssh/authorized_keys of {user}'**
  String termCheckLine(String user);

  /// No description provided for @termCheckPort.
  ///
  /// In en, this message translates to:
  /// **'sshd listens on {port} (sudo sshd -T | grep -i port)'**
  String termCheckPort(int port);

  /// No description provided for @termFailed.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach {target}: {detail}'**
  String termFailed(String target, String detail);

  /// No description provided for @termFontSizeValue.
  ///
  /// In en, this message translates to:
  /// **'{size} sp'**
  String termFontSizeValue(int size);

  /// No description provided for @termHostKeyTrusted.
  ///
  /// In en, this message translates to:
  /// **'Trusted since {date}'**
  String termHostKeyTrusted(String date);

  /// No description provided for @termKeyArmed.
  ///
  /// In en, this message translates to:
  /// **'{key}, armed'**
  String termKeyArmed(String key);

  /// No description provided for @termKeyLocked.
  ///
  /// In en, this message translates to:
  /// **'{key}, locked'**
  String termKeyLocked(String key);

  /// No description provided for @termNextIn.
  ///
  /// In en, this message translates to:
  /// **'next in {seconds} s'**
  String termNextIn(int seconds);

  /// No description provided for @termReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting · attempt {attempt}'**
  String termReconnecting(int attempt);

  /// No description provided for @termUnlockFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t unlock: {detail}'**
  String termUnlockFailed(String detail);

  /// No description provided for @termSelCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get termSelCopy;

  /// No description provided for @termSelSendToChat.
  ///
  /// In en, this message translates to:
  /// **'Send to chat'**
  String get termSelSendToChat;

  /// No description provided for @termSelCopied.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Copied 1 line} other{Copied {count} lines}}'**
  String termSelCopied(int count);

  /// No description provided for @termSelStart.
  ///
  /// In en, this message translates to:
  /// **'Selection start'**
  String get termSelStart;

  /// No description provided for @termSelEnd.
  ///
  /// In en, this message translates to:
  /// **'Selection end'**
  String get termSelEnd;

  /// No description provided for @termPinchChip.
  ///
  /// In en, this message translates to:
  /// **'{size} sp · {columns} × {rows}'**
  String termPinchChip(int size, int columns, int rows);

  /// No description provided for @termTabSemantics.
  ///
  /// In en, this message translates to:
  /// **'{name}, tab {index} of {count}, {state}'**
  String termTabSemantics(String name, int index, int count, String state);

  /// No description provided for @termTabTooltip.
  ///
  /// In en, this message translates to:
  /// **'{name} · {state} · {columns} × {rows}'**
  String termTabTooltip(String name, String state, int columns, int rows);

  /// No description provided for @termTabRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get termTabRename;

  /// No description provided for @termTabClose.
  ///
  /// In en, this message translates to:
  /// **'Close tab'**
  String get termTabClose;

  /// No description provided for @termTabKill.
  ///
  /// In en, this message translates to:
  /// **'Kill session…'**
  String get termTabKill;

  /// No description provided for @termNewTab.
  ///
  /// In en, this message translates to:
  /// **'New tab'**
  String get termNewTab;

  /// No description provided for @termMenuSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions on {host}'**
  String termMenuSessions(String host);

  /// No description provided for @termSessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sessions on {host}'**
  String termSessionsTitle(String host);

  /// No description provided for @termSessionsSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{tmux · 1 session · {open} open here} other{tmux · {count} sessions · {open} open here}}'**
  String termSessionsSummary(int count, int open);

  /// No description provided for @termSessionsNew.
  ///
  /// In en, this message translates to:
  /// **'New session'**
  String get termSessionsNew;

  /// No description provided for @termSessionsNewSub.
  ///
  /// In en, this message translates to:
  /// **'Starts tmux on the desktop and opens it here'**
  String get termSessionsNewSub;

  /// No description provided for @termSessionTag.
  ///
  /// In en, this message translates to:
  /// **'tab'**
  String get termSessionTag;

  /// No description provided for @termSessionAttachedHere.
  ///
  /// In en, this message translates to:
  /// **'Attached here'**
  String get termSessionAttachedHere;

  /// No description provided for @termSessionAttachedBoth.
  ///
  /// In en, this message translates to:
  /// **'Attached here and on the desktop'**
  String get termSessionAttachedBoth;

  /// No description provided for @termSessionAttachedDesktop.
  ///
  /// In en, this message translates to:
  /// **'Attached on the desktop'**
  String get termSessionAttachedDesktop;

  /// No description provided for @termSessionDetached.
  ///
  /// In en, this message translates to:
  /// **'Detached'**
  String get termSessionDetached;

  /// No description provided for @termSessionWindows.
  ///
  /// In en, this message translates to:
  /// **'{windows, plural, =1{1 window} other{{windows} windows}}'**
  String termSessionWindows(int windows);

  /// No description provided for @termSessionMeta.
  ///
  /// In en, this message translates to:
  /// **'{windows, plural, =1{1 window · created {age} ago} other{{windows} windows · created {age} ago}}'**
  String termSessionMeta(int windows, String age);

  /// No description provided for @termSessionOpen.
  ///
  /// In en, this message translates to:
  /// **'Open as tab'**
  String get termSessionOpen;

  /// No description provided for @termSessionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tmux sessions on the desktop.'**
  String get termSessionsEmpty;

  /// No description provided for @termSessionsFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach tmux on the desktop: {detail}'**
  String termSessionsFailed(String detail);

  /// No description provided for @termTmuxFailed.
  ///
  /// In en, this message translates to:
  /// **'tmux said: {detail}'**
  String termTmuxFailed(String detail);

  /// No description provided for @termSessionsButton.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get termSessionsButton;

  /// No description provided for @termRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename session'**
  String get termRenameTitle;

  /// No description provided for @termRenameLabel.
  ///
  /// In en, this message translates to:
  /// **'Session name'**
  String get termRenameLabel;

  /// No description provided for @termRenameHint.
  ///
  /// In en, this message translates to:
  /// **'Letters, digits, - and _ (up to 32)'**
  String get termRenameHint;

  /// No description provided for @termRenameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Only letters, digits, - and _ (up to 32)'**
  String get termRenameInvalid;

  /// No description provided for @termRenameSave.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get termRenameSave;

  /// No description provided for @termKillTitle.
  ///
  /// In en, this message translates to:
  /// **'Kill “{name}”?'**
  String termKillTitle(String name);

  /// No description provided for @termKillBody.
  ///
  /// In en, this message translates to:
  /// **'Every window in it, and whatever runs there, stops on the desktop. This can\'t be undone.'**
  String get termKillBody;

  /// No description provided for @termKill.
  ///
  /// In en, this message translates to:
  /// **'Kill'**
  String get termKill;

  /// No description provided for @termNoTabsTitle.
  ///
  /// In en, this message translates to:
  /// **'No tabs open'**
  String get termNoTabsTitle;

  /// No description provided for @termNoTabsBody.
  ///
  /// In en, this message translates to:
  /// **'Your tmux sessions keep running on the desktop. Open one here, or start a new one.'**
  String get termNoTabsBody;

  /// No description provided for @navFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get navFiles;

  /// No description provided for @filesQuickHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get filesQuickHome;

  /// No description provided for @filesQuickDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get filesQuickDownloads;

  /// No description provided for @filesQuickDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get filesQuickDocuments;

  /// No description provided for @filesItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{n} items}}'**
  String filesItems(int count, String n);

  /// No description provided for @filesShownHidden.
  ///
  /// In en, this message translates to:
  /// **'{shown} shown · {hidden} hidden'**
  String filesShownHidden(String shown, String hidden);

  /// No description provided for @filesUsedPct.
  ///
  /// In en, this message translates to:
  /// **'{pct} % used'**
  String filesUsedPct(int pct);

  /// No description provided for @filesLinkTo.
  ///
  /// In en, this message translates to:
  /// **'link → {target}'**
  String filesLinkTo(String target);

  /// No description provided for @filesBrokenLink.
  ///
  /// In en, this message translates to:
  /// **'broken link → {target}'**
  String filesBrokenLink(String target);

  /// No description provided for @filesDeniedRow.
  ///
  /// In en, this message translates to:
  /// **'Permission denied · {owner}'**
  String filesDeniedRow(String owner);

  /// No description provided for @filesSortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get filesSortName;

  /// No description provided for @filesSortSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get filesSortSize;

  /// No description provided for @filesSortDate.
  ///
  /// In en, this message translates to:
  /// **'Date modified'**
  String get filesSortDate;

  /// No description provided for @filesMenuHidden.
  ///
  /// In en, this message translates to:
  /// **'Show hidden files'**
  String get filesMenuHidden;

  /// No description provided for @filesMenuSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get filesMenuSortBy;

  /// No description provided for @filesMenuRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get filesMenuRefresh;

  /// No description provided for @filesActOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get filesActOpen;

  /// No description provided for @filesActDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get filesActDownload;

  /// No description provided for @filesActDownloadHint.
  ///
  /// In en, this message translates to:
  /// **'To {folder}'**
  String filesActDownloadHint(String folder);

  /// No description provided for @filesActPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get filesActPreview;

  /// No description provided for @filesActGoToTarget.
  ///
  /// In en, this message translates to:
  /// **'Go to target'**
  String get filesActGoToTarget;

  /// No description provided for @filesActCopyPath.
  ///
  /// In en, this message translates to:
  /// **'Copy path'**
  String get filesActCopyPath;

  /// No description provided for @filesPathCopied.
  ///
  /// In en, this message translates to:
  /// **'Path copied'**
  String get filesPathCopied;

  /// No description provided for @filesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'This folder is empty'**
  String get filesEmptyTitle;

  /// No description provided for @filesEmptyHidden.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hidden item} other{{count} hidden items}}'**
  String filesEmptyHidden(int count);

  /// No description provided for @filesDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get filesDeniedTitle;

  /// No description provided for @filesDeniedOwned.
  ///
  /// In en, this message translates to:
  /// **' belongs to {owner} ({mode}). Files never uses sudo.'**
  String filesDeniedOwned(String owner, String mode);

  /// No description provided for @filesDeniedPlain.
  ///
  /// In en, this message translates to:
  /// **' can\'t be opened as your user. Files never uses sudo.'**
  String get filesDeniedPlain;

  /// No description provided for @filesGoRoot.
  ///
  /// In en, this message translates to:
  /// **'Go to /'**
  String get filesGoRoot;

  /// No description provided for @filesGoHome.
  ///
  /// In en, this message translates to:
  /// **'Go to home folder'**
  String get filesGoHome;

  /// No description provided for @filesNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Folder not found'**
  String get filesNotFoundTitle;

  /// No description provided for @filesErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open this folder'**
  String get filesErrorTitle;

  /// No description provided for @filesRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get filesRetry;

  /// No description provided for @filesReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting · attempt {n}'**
  String filesReconnecting(int n);

  /// No description provided for @filesNextIn.
  ///
  /// In en, this message translates to:
  /// **'next in {s} s'**
  String filesNextIn(int s);

  /// No description provided for @filesNotSetUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up the terminal first'**
  String get filesNotSetUpTitle;

  /// No description provided for @filesNotSetUpBody.
  ///
  /// In en, this message translates to:
  /// **'Files uses the terminal\'s connection to your desktop: this phone\'s key, the host and the trusted host key.'**
  String get filesNotSetUpBody;

  /// No description provided for @filesOpenTerminal.
  ///
  /// In en, this message translates to:
  /// **'Open Terminal'**
  String get filesOpenTerminal;

  /// No description provided for @filesHostKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'The desktop\'s host key changed'**
  String get filesHostKeyTitle;

  /// No description provided for @filesHostKeyBody.
  ///
  /// In en, this message translates to:
  /// **'Files won\'t connect until the terminal trusts the desktop again. The Terminal tab shows the details.'**
  String get filesHostKeyBody;

  /// No description provided for @filesKeyDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'The desktop refused this phone\'s key'**
  String get filesKeyDeniedTitle;

  /// No description provided for @filesKeyDeniedBody.
  ///
  /// In en, this message translates to:
  /// **'Check that the key line is still in authorized_keys (Terminal settings show it).'**
  String get filesKeyDeniedBody;

  /// No description provided for @filesLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock Files'**
  String get filesLockTitle;

  /// No description provided for @filesLockBody.
  ///
  /// In en, this message translates to:
  /// **'Locked after 15 min of inactivity. One unlock opens Files and the Terminal.'**
  String get filesLockBody;

  /// No description provided for @filesUnlockReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock Delve Files'**
  String get filesUnlockReason;

  /// No description provided for @filesTransfers.
  ///
  /// In en, this message translates to:
  /// **'Transfers'**
  String get filesTransfers;

  /// No description provided for @filesTransferChip.
  ///
  /// In en, this message translates to:
  /// **'{n} of {total}'**
  String filesTransferChip(int n, int total);

  /// No description provided for @filesTransfersSummary.
  ///
  /// In en, this message translates to:
  /// **'{active} running · {done} done'**
  String filesTransfersSummary(int active, int done);

  /// No description provided for @filesClearFinished.
  ///
  /// In en, this message translates to:
  /// **'Clear finished'**
  String get filesClearFinished;

  /// No description provided for @filesTransferQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get filesTransferQueued;

  /// No description provided for @filesTransferDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get filesTransferDone;

  /// No description provided for @filesTransferFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get filesTransferFailed;

  /// No description provided for @filesTransferCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get filesTransferCancelled;

  /// No description provided for @filesTransferOf.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total}'**
  String filesTransferOf(String done, String total);

  /// No description provided for @filesTransferInDownloads.
  ///
  /// In en, this message translates to:
  /// **'in Downloads/Delve'**
  String get filesTransferInDownloads;

  /// No description provided for @filesTransferCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get filesTransferCancel;

  /// No description provided for @filesTransferRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get filesTransferRetry;

  /// No description provided for @filesOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get filesOpen;

  /// No description provided for @filesSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to {folder}'**
  String filesSaved(String folder);

  /// No description provided for @filesNoApp.
  ///
  /// In en, this message translates to:
  /// **'No app on this phone opens this file'**
  String get filesNoApp;

  /// No description provided for @filesDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t download {name}: {reason}'**
  String filesDownloadFailed(String name, String reason);

  /// No description provided for @filesDownloadQueued.
  ///
  /// In en, this message translates to:
  /// **'Downloading to {folder}'**
  String filesDownloadQueued(String folder);

  /// No description provided for @filesLineNumbers.
  ///
  /// In en, this message translates to:
  /// **'Line numbers'**
  String get filesLineNumbers;

  /// No description provided for @filesPreviewFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the file'**
  String get filesPreviewFailed;

  /// No description provided for @filesPreviewTooBig.
  ///
  /// In en, this message translates to:
  /// **'Too big to preview here'**
  String get filesPreviewTooBig;

  /// No description provided for @filesPreviewBinary.
  ///
  /// In en, this message translates to:
  /// **'Not a text file'**
  String get filesPreviewBinary;

  /// No description provided for @filesPreviewBinaryBody.
  ///
  /// In en, this message translates to:
  /// **'Download it to open it in another app.'**
  String get filesPreviewBinaryBody;

  /// No description provided for @filesPreviewCut.
  ///
  /// In en, this message translates to:
  /// **'Read-only · the first 1 MB'**
  String get filesPreviewCut;

  /// No description provided for @filesPreviewInfo.
  ///
  /// In en, this message translates to:
  /// **'{lines, plural, =1{Read-only · 1 line · UTF-8} other{Read-only · {lines} lines · UTF-8}}'**
  String filesPreviewInfo(int lines);

  /// No description provided for @filesPreviewPosition.
  ///
  /// In en, this message translates to:
  /// **'{index} / {count}'**
  String filesPreviewPosition(int index, int count);

  /// No description provided for @filesPdfPage.
  ///
  /// In en, this message translates to:
  /// **'Page {page} / {count}'**
  String filesPdfPage(int page, int count);

  /// No description provided for @filesPdfLocked.
  ///
  /// In en, this message translates to:
  /// **'Password-protected PDF'**
  String get filesPdfLocked;

  /// No description provided for @filesPdfLockedBody.
  ///
  /// In en, this message translates to:
  /// **'The phone\'s viewer can\'t open PDFs with a password. Download it and open it in another app.'**
  String get filesPdfLockedBody;

  /// No description provided for @filesPdfBroken.
  ///
  /// In en, this message translates to:
  /// **'Can\'t read this PDF'**
  String get filesPdfBroken;

  /// No description provided for @filesPdfBrokenBody.
  ///
  /// In en, this message translates to:
  /// **'It may be damaged, or not really a PDF. Download it to try another app.'**
  String get filesPdfBrokenBody;

  /// No description provided for @filesUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get filesUpload;

  /// No description provided for @filesUploadTo.
  ///
  /// In en, this message translates to:
  /// **'Upload to {folder}'**
  String filesUploadTo(String folder);

  /// No description provided for @filesUploadPhotosHint.
  ///
  /// In en, this message translates to:
  /// **'From the gallery'**
  String get filesUploadPhotosHint;

  /// No description provided for @filesUploadCameraHint.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get filesUploadCameraHint;

  /// No description provided for @filesUploadFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get filesUploadFiles;

  /// No description provided for @filesUploadFilesHint.
  ///
  /// In en, this message translates to:
  /// **'Phone storage, Drive…'**
  String get filesUploadFilesHint;

  /// No description provided for @filesUploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded to {folder}'**
  String filesUploaded(String folder);

  /// No description provided for @filesUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t upload: {reason}'**
  String filesUploadFailed(String reason);

  /// No description provided for @filesUploadFailedFile.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t upload {name}: {reason}'**
  String filesUploadFailedFile(String name, String reason);

  /// No description provided for @filesShowFolder.
  ///
  /// In en, this message translates to:
  /// **'Show folder'**
  String get filesShowFolder;

  /// No description provided for @filesNewFolder.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get filesNewFolder;

  /// No description provided for @filesCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get filesCreate;

  /// No description provided for @filesRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get filesRename;

  /// No description provided for @filesRenameAction.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get filesRenameAction;

  /// No description provided for @filesNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get filesNameEmpty;

  /// No description provided for @filesNameDots.
  ///
  /// In en, this message translates to:
  /// **'“.” and “..” can\'t be names'**
  String get filesNameDots;

  /// No description provided for @filesNameSlash.
  ///
  /// In en, this message translates to:
  /// **'A name can\'t contain /'**
  String get filesNameSlash;

  /// No description provided for @filesNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Too long: 255 bytes at most'**
  String get filesNameTooLong;

  /// No description provided for @filesNameTaken.
  ///
  /// In en, this message translates to:
  /// **'{name} already exists here'**
  String filesNameTaken(String name);

  /// No description provided for @filesWriteDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied (Files never uses sudo)'**
  String get filesWriteDenied;

  /// No description provided for @filesWriteOffline.
  ///
  /// In en, this message translates to:
  /// **'No connection to the desktop'**
  String get filesWriteOffline;

  /// No description provided for @filesFolder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get filesFolder;

  /// No description provided for @filesConflictTitle.
  ///
  /// In en, this message translates to:
  /// **' already exists here'**
  String get filesConflictTitle;

  /// No description provided for @filesConflictHere.
  ///
  /// In en, this message translates to:
  /// **'Here'**
  String get filesConflictHere;

  /// No description provided for @filesConflictIncoming.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get filesConflictIncoming;

  /// No description provided for @filesConflictSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get filesConflictSkip;

  /// No description provided for @filesConflictSkipHint.
  ///
  /// In en, this message translates to:
  /// **'Keep the one here, leave this one out'**
  String get filesConflictSkipHint;

  /// No description provided for @filesConflictReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get filesConflictReplace;

  /// No description provided for @filesConflictReplaceHint.
  ///
  /// In en, this message translates to:
  /// **'The one here goes to the desktop\'s trash'**
  String get filesConflictReplaceHint;

  /// No description provided for @filesConflictReplaceFolder.
  ///
  /// In en, this message translates to:
  /// **'A folder is never replaced'**
  String get filesConflictReplaceFolder;

  /// No description provided for @filesConflictKeepBoth.
  ///
  /// In en, this message translates to:
  /// **'Keep both'**
  String get filesConflictKeepBoth;

  /// No description provided for @filesConflictKeepBothHint.
  ///
  /// In en, this message translates to:
  /// **'Saves as {name}'**
  String filesConflictKeepBothHint(String name);

  /// No description provided for @filesConflictAll.
  ///
  /// In en, this message translates to:
  /// **'Apply to all {count} conflicts'**
  String filesConflictAll(int count);

  /// No description provided for @filesConflictCancelUpload.
  ///
  /// In en, this message translates to:
  /// **'Cancel upload'**
  String get filesConflictCancelUpload;

  /// No description provided for @filesActTrash.
  ///
  /// In en, this message translates to:
  /// **'Move to trash'**
  String get filesActTrash;

  /// No description provided for @filesActDeleteForever.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently…'**
  String get filesActDeleteForever;

  /// No description provided for @filesTrashed.
  ///
  /// In en, this message translates to:
  /// **'{name} moved to the trash'**
  String filesTrashed(String name);

  /// No description provided for @filesUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get filesUndo;

  /// No description provided for @filesTrashFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t move to the trash: {reason}'**
  String filesTrashFailed(String reason);

  /// No description provided for @filesDeleteForeverTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently?'**
  String get filesDeleteForeverTitle;

  /// No description provided for @filesDeleteForever.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get filesDeleteForever;

  /// No description provided for @filesNoTrashBody.
  ///
  /// In en, this message translates to:
  /// **'Only your home folder has a trash. Files outside it are deleted at once, and this can\'t be undone.'**
  String get filesNoTrashBody;

  /// No description provided for @filesNoTrashOtherFs.
  ///
  /// In en, this message translates to:
  /// **'This is on another filesystem than your home folder\'s trash, so it can\'t go there. It is deleted at once, and this can\'t be undone.'**
  String get filesNoTrashOtherFs;

  /// No description provided for @filesDeleted.
  ///
  /// In en, this message translates to:
  /// **'{name} deleted'**
  String filesDeleted(String name);

  /// No description provided for @filesDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete: {reason}'**
  String filesDeleteFailed(String reason);

  /// No description provided for @filesTrash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get filesTrash;

  /// No description provided for @filesTrashCount.
  ///
  /// In en, this message translates to:
  /// **'Trash ({count})'**
  String filesTrashCount(int count);

  /// No description provided for @trashShared.
  ///
  /// In en, this message translates to:
  /// **'shared with the desktop\'s file managers'**
  String get trashShared;

  /// No description provided for @trashNoneTitle.
  ///
  /// In en, this message translates to:
  /// **'The trash is empty'**
  String get trashNoneTitle;

  /// No description provided for @trashNoneBody.
  ///
  /// In en, this message translates to:
  /// **'The desktop\'s file managers use the same trash.'**
  String get trashNoneBody;

  /// No description provided for @trashErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the trash'**
  String get trashErrorTitle;

  /// No description provided for @trashDeletedAt.
  ///
  /// In en, this message translates to:
  /// **'Deleted {time}'**
  String trashDeletedAt(String time);

  /// No description provided for @trashRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get trashRestore;

  /// No description provided for @trashRestoreTo.
  ///
  /// In en, this message translates to:
  /// **'Restore to {folder}'**
  String trashRestoreTo(String folder);

  /// No description provided for @trashRestored.
  ///
  /// In en, this message translates to:
  /// **'{name} restored to {folder}'**
  String trashRestored(String name, String folder);

  /// No description provided for @trashRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t restore: {reason}'**
  String trashRestoreFailed(String reason);

  /// No description provided for @trashDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'It is deleted from the desktop\'s trash for good. This can\'t be undone.'**
  String get trashDeleteBody;

  /// No description provided for @trashEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty trash'**
  String get trashEmpty;

  /// No description provided for @trashEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Empty the trash?'**
  String get trashEmptyTitle;

  /// No description provided for @trashEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Everything in the desktop\'s trash is deleted for good, also what was deleted on the desktop. This can\'t be undone.'**
  String get trashEmptyBody;

  /// No description provided for @trashEmptySure.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{I understand this item will be gone for good} other{I understand these {count} items will be gone for good}}'**
  String trashEmptySure(int count);

  /// No description provided for @trashEmptied.
  ///
  /// In en, this message translates to:
  /// **'Trash emptied'**
  String get trashEmptied;

  /// No description provided for @saveTitle.
  ///
  /// In en, this message translates to:
  /// **'Save to desktop folder'**
  String get saveTitle;

  /// No description provided for @saveFiles.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file} other{{count} files}}'**
  String saveFiles(int count);

  /// No description provided for @saveHere.
  ///
  /// In en, this message translates to:
  /// **'Save here'**
  String get saveHere;

  /// No description provided for @shareSaveSection.
  ///
  /// In en, this message translates to:
  /// **'Save to the desktop'**
  String get shareSaveSection;

  /// No description provided for @shareSaveToDesktop.
  ///
  /// In en, this message translates to:
  /// **'Save to desktop folder'**
  String get shareSaveToDesktop;

  /// No description provided for @shareSaveNotSetUp.
  ///
  /// In en, this message translates to:
  /// **'Set up the terminal first'**
  String get shareSaveNotSetUp;

  /// No description provided for @shareSaveNoFiles.
  ///
  /// In en, this message translates to:
  /// **'Only photos and files can be saved'**
  String get shareSaveNoFiles;

  /// No description provided for @shareSaveChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder on the desktop'**
  String get shareSaveChoose;

  /// No description provided for @shareSaveLast.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder · last used {folder}'**
  String shareSaveLast(String folder);

  /// No description provided for @editorEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editorEdit;

  /// No description provided for @editorEditTooBig.
  ///
  /// In en, this message translates to:
  /// **'Over 1 MB – download it'**
  String get editorEditTooBig;

  /// No description provided for @editorSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get editorSave;

  /// No description provided for @editorSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get editorSaving;

  /// No description provided for @editorUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get editorUndo;

  /// No description provided for @editorRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get editorRedo;

  /// No description provided for @editorMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get editorMore;

  /// No description provided for @editorWrap.
  ///
  /// In en, this message translates to:
  /// **'Wrap lines'**
  String get editorWrap;

  /// No description provided for @editorFindLater.
  ///
  /// In en, this message translates to:
  /// **'Find · later'**
  String get editorFindLater;

  /// No description provided for @editorReload.
  ///
  /// In en, this message translates to:
  /// **'Reload from desktop'**
  String get editorReload;

  /// No description provided for @editorReloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reload: {reason}'**
  String editorReloadFailed(String reason);

  /// No description provided for @editorDiscardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard changes'**
  String get editorDiscardChanges;

  /// No description provided for @editorEdited.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get editorEdited;

  /// No description provided for @editorUnsaved.
  ///
  /// In en, this message translates to:
  /// **'{name}, unsaved changes'**
  String editorUnsaved(String name);

  /// No description provided for @editorStatusEditing.
  ///
  /// In en, this message translates to:
  /// **'Editing'**
  String get editorStatusEditing;

  /// No description provided for @editorStatusSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved {time}'**
  String editorStatusSaved(String time);

  /// No description provided for @editorStatusNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Not saved'**
  String get editorStatusNotSaved;

  /// No description provided for @editorStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline · Save is back when connected'**
  String get editorStatusOffline;

  /// No description provided for @editorPosition.
  ///
  /// In en, this message translates to:
  /// **'Ln {line}, Col {col}'**
  String editorPosition(int line, int col);

  /// No description provided for @editorLines.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 line} other{{count} lines}}'**
  String editorLines(int count);

  /// No description provided for @editorChanged.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 line changed} other{{count} lines changed}}'**
  String editorChanged(int count);

  /// No description provided for @editorSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to the desktop'**
  String get editorSaved;

  /// No description provided for @editorSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Not saved: {reason}'**
  String editorSaveFailed(String reason);

  /// No description provided for @editorBlockTooBig.
  ///
  /// In en, this message translates to:
  /// **'Over 1 MB: shown in part, not editable'**
  String get editorBlockTooBig;

  /// No description provided for @editorBlockNotText.
  ///
  /// In en, this message translates to:
  /// **'Not UTF-8 text: not editable'**
  String get editorBlockNotText;

  /// No description provided for @editorBlockReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read-only for {user}'**
  String editorBlockReadOnly(String user);

  /// No description provided for @editorInfoNotText.
  ///
  /// In en, this message translates to:
  /// **'{lines, plural, =1{Read-only · 1 line · not UTF-8} other{Read-only · {lines} lines · not UTF-8}}'**
  String editorInfoNotText(int lines);

  /// No description provided for @editorOpenInTerminal.
  ///
  /// In en, this message translates to:
  /// **'Open in terminal'**
  String get editorOpenInTerminal;

  /// No description provided for @editorDenied.
  ///
  /// In en, this message translates to:
  /// **'{folder} doesn\'t let {user} save here'**
  String editorDenied(String user, String folder);

  /// No description provided for @editorSaveCopy.
  ///
  /// In en, this message translates to:
  /// **'Save a copy to ~'**
  String get editorSaveCopy;

  /// No description provided for @editorCopyAll.
  ///
  /// In en, this message translates to:
  /// **'Copy all'**
  String get editorCopyAll;

  /// No description provided for @editorCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied the whole file'**
  String get editorCopied;

  /// No description provided for @editorCopySaved.
  ///
  /// In en, this message translates to:
  /// **'Copy saved as {path}'**
  String editorCopySaved(String path);

  /// No description provided for @editorConflictTitle.
  ///
  /// In en, this message translates to:
  /// **' changed on the desktop'**
  String get editorConflictTitle;

  /// No description provided for @editorConflictDesktop.
  ///
  /// In en, this message translates to:
  /// **'On the desktop'**
  String get editorConflictDesktop;

  /// No description provided for @editorConflictOpened.
  ///
  /// In en, this message translates to:
  /// **'When you opened it'**
  String get editorConflictOpened;

  /// No description provided for @editorConflictYours.
  ///
  /// In en, this message translates to:
  /// **'Your edit'**
  String get editorConflictYours;

  /// No description provided for @editorConflictDeleted.
  ///
  /// In en, this message translates to:
  /// **'deleted'**
  String get editorConflictDeleted;

  /// No description provided for @editorOverwrite.
  ///
  /// In en, this message translates to:
  /// **'Overwrite'**
  String get editorOverwrite;

  /// No description provided for @editorOverwriteHint.
  ///
  /// In en, this message translates to:
  /// **'Save your edit over the desktop\'s version'**
  String get editorOverwriteHint;

  /// No description provided for @editorReloadHint.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Load the desktop\'s version} =1{Load the desktop\'s version · 1 changed line lost} other{Load the desktop\'s version · {count} changed lines lost}}'**
  String editorReloadHint(int count);

  /// No description provided for @editorDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get editorDiscardTitle;

  /// No description provided for @editorDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 changed line in {name} is not saved to the desktop.} other{{count} changed lines in {name} are not saved to the desktop.}}'**
  String editorDiscardBody(int count, String name);

  /// No description provided for @editorDiscardAction.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get editorDiscardAction;

  /// No description provided for @editorKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get editorKeepEditing;

  /// No description provided for @editorDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get editorDone;

  /// No description provided for @editorLockedBody.
  ///
  /// In en, this message translates to:
  /// **'Your edit is kept. Unlock to go on.'**
  String get editorLockedBody;

  /// No description provided for @editorKeyTab.
  ///
  /// In en, this message translates to:
  /// **'Tab, 4 spaces'**
  String get editorKeyTab;

  /// No description provided for @editorKeyLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get editorKeyLeft;

  /// No description provided for @editorKeyRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get editorKeyRight;

  /// No description provided for @editorKeyUp.
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get editorKeyUp;

  /// No description provided for @editorKeyDown.
  ///
  /// In en, this message translates to:
  /// **'Down'**
  String get editorKeyDown;

  /// No description provided for @editorKeyHome.
  ///
  /// In en, this message translates to:
  /// **'Line start'**
  String get editorKeyHome;

  /// No description provided for @editorKeyEnd.
  ///
  /// In en, this message translates to:
  /// **'Line end'**
  String get editorKeyEnd;

  /// No description provided for @filesActCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get filesActCopy;

  /// No description provided for @filesActMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get filesActMove;

  /// No description provided for @filesActDownloadFolderHint.
  ///
  /// In en, this message translates to:
  /// **'To {folder}, with its folders'**
  String filesActDownloadFolderHint(String folder);

  /// No description provided for @filesSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String filesSelected(int count);

  /// No description provided for @filesSelectedOf.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} selected'**
  String filesSelectedOf(int count, int total);

  /// No description provided for @filesSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get filesSelectAll;

  /// No description provided for @filesCopyPaths.
  ///
  /// In en, this message translates to:
  /// **'Copy paths'**
  String get filesCopyPaths;

  /// No description provided for @filesPathsCopied.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Path copied} other{{count} paths copied}}'**
  String filesPathsCopied(int count);

  /// No description provided for @filesPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get filesPaste;

  /// No description provided for @filesPasteCopyTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Copy 1 item here} other{Copy {count} items here}}'**
  String filesPasteCopyTitle(int count);

  /// No description provided for @filesPasteMoveTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Move 1 item here} other{Move {count} items here}}'**
  String filesPasteMoveTitle(int count);

  /// No description provided for @filesPasteFrom.
  ///
  /// In en, this message translates to:
  /// **'from {folder}'**
  String filesPasteFrom(String folder);

  /// No description provided for @filesPasteSameFolder.
  ///
  /// In en, this message translates to:
  /// **'Already in this folder – open another one'**
  String get filesPasteSameFolder;

  /// No description provided for @filesPasteIntoItself.
  ///
  /// In en, this message translates to:
  /// **'Can\'t go into itself – open another folder'**
  String get filesPasteIntoItself;

  /// No description provided for @filesPasteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t paste: {reason}'**
  String filesPasteFailed(String reason);

  /// No description provided for @filesConflictCancelPaste.
  ///
  /// In en, this message translates to:
  /// **'Cancel paste'**
  String get filesConflictCancelPaste;

  /// No description provided for @filesMovedHere.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Moved 1 item here} other{Moved {count} items here}}'**
  String filesMovedHere(int count);

  /// No description provided for @filesMoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t move {name}: {reason}'**
  String filesMoveFailed(String name, String reason);

  /// No description provided for @filesCopiedTo.
  ///
  /// In en, this message translates to:
  /// **'Copied to {folder}'**
  String filesCopiedTo(String folder);

  /// No description provided for @filesMovedTo.
  ///
  /// In en, this message translates to:
  /// **'Moved to {folder}'**
  String filesMovedTo(String folder);

  /// No description provided for @filesMovedSourceKept.
  ///
  /// In en, this message translates to:
  /// **'Copied to {folder}, but the original stayed: {reason}'**
  String filesMovedSourceKept(String folder, String reason);

  /// No description provided for @filesCopyFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t copy {name}: {reason}'**
  String filesCopyFailed(String name, String reason);

  /// No description provided for @filesTrashedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item moved to the trash} other{{count} items moved to the trash}}'**
  String filesTrashedCount(int count);

  /// No description provided for @filesTrashFailedName.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t move {name} to the trash: {reason}'**
  String filesTrashFailedName(String name, String reason);

  /// No description provided for @filesDeletedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item deleted} other{{count} items deleted}}'**
  String filesDeletedCount(int count);

  /// No description provided for @filesDeleteFailedName.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete {name}: {reason}'**
  String filesDeleteFailedName(String name, String reason);

  /// No description provided for @filesTransferReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get filesTransferReading;

  /// No description provided for @filesTransferFound.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file found} other{{count} files found}}'**
  String filesTransferFound(int count);

  /// No description provided for @filesTransferFiles.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} files'**
  String filesTransferFiles(int done, int total);

  /// No description provided for @filesTransferFilesDone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file} other{{count} files}}'**
  String filesTransferFilesDone(int count);

  /// No description provided for @filesTransferUnreadable.
  ///
  /// In en, this message translates to:
  /// **'{count} unreadable'**
  String filesTransferUnreadable(int count);

  /// No description provided for @filesTransferLeftOut.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 link left out} other{{count} links left out}}'**
  String filesTransferLeftOut(int count);

  /// No description provided for @filesNoticeDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading {name}'**
  String filesNoticeDownloading(String name);

  /// No description provided for @filesNoticeUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading {name}'**
  String filesNoticeUploading(String name);

  /// No description provided for @filesNoticeCopying.
  ///
  /// In en, this message translates to:
  /// **'Copying {name}'**
  String filesNoticeCopying(String name);

  /// No description provided for @filesNoticeMoving.
  ///
  /// In en, this message translates to:
  /// **'Moving {name}'**
  String filesNoticeMoving(String name);

  /// No description provided for @filesNoticeWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the desktop'**
  String get filesNoticeWaiting;

  /// No description provided for @filesNoticeQueued.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 transfer queued} other{{count} transfers queued}}'**
  String filesNoticeQueued(int count);

  /// No description provided for @filesNoticeCancelAll.
  ///
  /// In en, this message translates to:
  /// **'Cancel all'**
  String get filesNoticeCancelAll;

  /// No description provided for @filesNoticeFinished.
  ///
  /// In en, this message translates to:
  /// **'Transfers finished'**
  String get filesNoticeFinished;

  /// No description provided for @filesNoticeAllFailed.
  ///
  /// In en, this message translates to:
  /// **'Transfers failed'**
  String get filesNoticeAllFailed;

  /// No description provided for @filesNoticeDone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 transfer done} other{{count} transfers done}}'**
  String filesNoticeDone(int count);

  /// No description provided for @filesNoticeFailed.
  ///
  /// In en, this message translates to:
  /// **'{count} failed'**
  String filesNoticeFailed(int count);

  /// No description provided for @filesNoticeItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String filesNoticeItems(int count);

  /// No description provided for @chatsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get chatsFilterAll;

  /// No description provided for @chatsFilterAgent.
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get chatsFilterAgent;

  /// No description provided for @chatsFilterGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get chatsFilterGeneral;

  /// No description provided for @chatsFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Show {kind} chats'**
  String chatsFilterLabel(String kind);

  /// No description provided for @generalMarker.
  ///
  /// In en, this message translates to:
  /// **'General · {model}'**
  String generalMarker(String model);

  /// No description provided for @chatsGeneralEmpty.
  ///
  /// In en, this message translates to:
  /// **'No General chats yet'**
  String get chatsGeneralEmpty;

  /// No description provided for @chatsGeneralWorks.
  ///
  /// In en, this message translates to:
  /// **'General chats work as usual.'**
  String get chatsGeneralWorks;

  /// No description provided for @newChatAgent.
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get newChatAgent;

  /// No description provided for @newChatAgentSub.
  ///
  /// In en, this message translates to:
  /// **'Local model on your desktop\nTools, files and memory'**
  String get newChatAgentSub;

  /// No description provided for @newChatGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get newChatGeneral;

  /// No description provided for @newChatGeneralSub.
  ///
  /// In en, this message translates to:
  /// **'Cloud models via OpenRouter\nStraight from this phone'**
  String get newChatGeneralSub;

  /// No description provided for @generalIntroVia.
  ///
  /// In en, this message translates to:
  /// **'via OpenRouter · straight from this phone'**
  String get generalIntroVia;

  /// No description provided for @generalIntroShield.
  ///
  /// In en, this message translates to:
  /// **'Zero data retention · nothing from your desktop'**
  String get generalIntroShield;

  /// No description provided for @generalNoKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat with cloud models'**
  String get generalNoKeyTitle;

  /// No description provided for @generalNoKeyBody.
  ///
  /// In en, this message translates to:
  /// **'Add an OpenRouter key to chat with cloud models straight from this phone.\nNothing from your desktop is sent.'**
  String get generalNoKeyBody;

  /// No description provided for @generalAddKey.
  ///
  /// In en, this message translates to:
  /// **'Add an OpenRouter key'**
  String get generalAddKey;

  /// No description provided for @generalComposerHint.
  ///
  /// In en, this message translates to:
  /// **'Message {model}…'**
  String generalComposerHint(String model);

  /// No description provided for @generalPickModel.
  ///
  /// In en, this message translates to:
  /// **'Pick a model'**
  String get generalPickModel;

  /// No description provided for @generalModelChipSemantics.
  ///
  /// In en, this message translates to:
  /// **'Model {model}, context {percent} percent, change model'**
  String generalModelChipSemantics(String model, int percent);

  /// No description provided for @generalModelChipEmpty.
  ///
  /// In en, this message translates to:
  /// **'Model {model}, change model'**
  String generalModelChipEmpty(String model);

  /// No description provided for @generalMenu.
  ///
  /// In en, this message translates to:
  /// **'Chat options'**
  String get generalMenu;

  /// No description provided for @generalMenuEffort.
  ///
  /// In en, this message translates to:
  /// **'Thinking effort'**
  String get generalMenuEffort;

  /// No description provided for @generalMenuRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get generalMenuRename;

  /// No description provided for @generalMenuArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get generalMenuArchive;

  /// No description provided for @generalMenuDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get generalMenuDelete;

  /// No description provided for @generalRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename chat'**
  String get generalRenameTitle;

  /// No description provided for @generalRenameSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get generalRenameSave;

  /// No description provided for @generalDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this chat?'**
  String get generalDeleteTitle;

  /// No description provided for @generalDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Its messages and images are removed from this phone. This can\'t be undone.'**
  String get generalDeleteBody;

  /// No description provided for @generalDeleted.
  ///
  /// In en, this message translates to:
  /// **'Chat deleted'**
  String get generalDeleted;

  /// No description provided for @generalSwitched.
  ///
  /// In en, this message translates to:
  /// **'Switched to {model} · {time}'**
  String generalSwitched(String model, String time);

  /// No description provided for @generalWriting.
  ///
  /// In en, this message translates to:
  /// **'writing'**
  String get generalWriting;

  /// No description provided for @generalStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get generalStopped;

  /// No description provided for @generalFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get generalFailed;

  /// No description provided for @generalTokens.
  ///
  /// In en, this message translates to:
  /// **'{count} tok'**
  String generalTokens(String count);

  /// No description provided for @generalAlwaysThinks.
  ///
  /// In en, this message translates to:
  /// **'{model} always thinks'**
  String generalAlwaysThinks(String model);

  /// No description provided for @generalThinkingEffort.
  ///
  /// In en, this message translates to:
  /// **'Thinking · {effort}'**
  String generalThinkingEffort(String effort);

  /// No description provided for @generalEffortTitle.
  ///
  /// In en, this message translates to:
  /// **'Thinking effort'**
  String get generalEffortTitle;

  /// No description provided for @generalEffortSub.
  ///
  /// In en, this message translates to:
  /// **'for {model} · applies to your next message'**
  String generalEffortSub(String model);

  /// No description provided for @generalEffortDefault.
  ///
  /// In en, this message translates to:
  /// **'Model default ({effort})'**
  String generalEffortDefault(String effort);

  /// No description provided for @generalEffortDefaultPlain.
  ///
  /// In en, this message translates to:
  /// **'Model default'**
  String get generalEffortDefaultPlain;

  /// No description provided for @generalEffortHint.
  ///
  /// In en, this message translates to:
  /// **'Long-press for the effort'**
  String get generalEffortHint;

  /// No description provided for @effortMinimal.
  ///
  /// In en, this message translates to:
  /// **'Minimal'**
  String get effortMinimal;

  /// No description provided for @effortLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get effortLow;

  /// No description provided for @effortMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get effortMedium;

  /// No description provided for @effortHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get effortHigh;

  /// No description provided for @effortXhigh.
  ///
  /// In en, this message translates to:
  /// **'Extra high'**
  String get effortXhigh;

  /// No description provided for @effortMax.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get effortMax;

  /// No description provided for @generalErrKey.
  ///
  /// In en, this message translates to:
  /// **'OpenRouter rejected the key'**
  String get generalErrKey;

  /// No description provided for @generalErrLimit.
  ///
  /// In en, this message translates to:
  /// **'Key limit reached'**
  String get generalErrLimit;

  /// No description provided for @generalErrNoProvider.
  ///
  /// In en, this message translates to:
  /// **'No zero-retention provider for this model'**
  String get generalErrNoProvider;

  /// No description provided for @generalErrRate.
  ///
  /// In en, this message translates to:
  /// **'Rate limited — try again in {seconds} s'**
  String generalErrRate(int seconds);

  /// No description provided for @generalErrRateNow.
  ///
  /// In en, this message translates to:
  /// **'Rate limited — try again'**
  String get generalErrRateNow;

  /// No description provided for @generalErrNetwork.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t reach OpenRouter'**
  String get generalErrNetwork;

  /// No description provided for @generalErrBadRequest.
  ///
  /// In en, this message translates to:
  /// **'OpenRouter refused the request'**
  String get generalErrBadRequest;

  /// No description provided for @generalErrUpstream.
  ///
  /// In en, this message translates to:
  /// **'The model’s provider failed'**
  String get generalErrUpstream;

  /// No description provided for @generalErrUnknown.
  ///
  /// In en, this message translates to:
  /// **'The answer failed'**
  String get generalErrUnknown;

  /// No description provided for @generalOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get generalOpenSettings;

  /// No description provided for @generalPickAnother.
  ///
  /// In en, this message translates to:
  /// **'Pick another model'**
  String get generalPickAnother;

  /// No description provided for @generalNoImages.
  ///
  /// In en, this message translates to:
  /// **'{model} doesn’t read images — {count, plural, =1{1 earlier image won’t} other{{count} earlier images won’t}} be sent'**
  String generalNoImages(String model, int count);

  /// No description provided for @generalProviderWarning.
  ///
  /// In en, this message translates to:
  /// **'Served by {provider}, not on the zero-retention list. Nothing more is sent until you acknowledge it.'**
  String generalProviderWarning(String provider);

  /// No description provided for @generalAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get generalAcknowledge;

  /// No description provided for @generalNotSent.
  ///
  /// In en, this message translates to:
  /// **'Not sent: {reason}'**
  String generalNotSent(String reason);

  /// No description provided for @generalNoKeyShort.
  ///
  /// In en, this message translates to:
  /// **'No OpenRouter key'**
  String get generalNoKeyShort;

  /// No description provided for @generalModelsFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the models: {reason}'**
  String generalModelsFailed(String reason);

  /// No description provided for @pickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get pickerTitle;

  /// No description provided for @pickerSub.
  ///
  /// In en, this message translates to:
  /// **'for {chat} · per 1M tokens in / out'**
  String pickerSub(String chat);

  /// No description provided for @pickerSubDefault.
  ///
  /// In en, this message translates to:
  /// **'default for new chats · per 1M tokens in / out'**
  String get pickerSubDefault;

  /// No description provided for @pickerSearch.
  ///
  /// In en, this message translates to:
  /// **'Search {count} models'**
  String pickerSearch(int count);

  /// No description provided for @pickerFavourites.
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get pickerFavourites;

  /// No description provided for @pickerAll.
  ///
  /// In en, this message translates to:
  /// **'All models · A–Z'**
  String get pickerAll;

  /// No description provided for @pickerUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {ago} ago · pull to refresh'**
  String pickerUpdated(String ago);

  /// No description provided for @pickerNever.
  ///
  /// In en, this message translates to:
  /// **'Not loaded yet · pull to refresh'**
  String get pickerNever;

  /// No description provided for @pickerNoZdr.
  ///
  /// In en, this message translates to:
  /// **'No zero-retention provider'**
  String get pickerNoZdr;

  /// No description provided for @pickerNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No model matches “{query}”'**
  String pickerNoMatch(String query);

  /// No description provided for @pickerEmpty.
  ///
  /// In en, this message translates to:
  /// **'The model list isn\'t loaded yet.'**
  String get pickerEmpty;

  /// No description provided for @pickerLoad.
  ///
  /// In en, this message translates to:
  /// **'Load models'**
  String get pickerLoad;

  /// No description provided for @pickerAddFavourite.
  ///
  /// In en, this message translates to:
  /// **'Add {model} to favourites'**
  String pickerAddFavourite(String model);

  /// No description provided for @pickerRemoveFavourite.
  ///
  /// In en, this message translates to:
  /// **'Remove {model} from favourites'**
  String pickerRemoveFavourite(String model);

  /// No description provided for @pickerReadsImages.
  ///
  /// In en, this message translates to:
  /// **'Reads images'**
  String get pickerReadsImages;

  /// No description provided for @pickerThinks.
  ///
  /// In en, this message translates to:
  /// **'Can think'**
  String get pickerThinks;

  /// No description provided for @pickerAlwaysThinks.
  ///
  /// In en, this message translates to:
  /// **'Always thinks'**
  String get pickerAlwaysThinks;

  /// No description provided for @generalAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to message'**
  String get generalAddTitle;

  /// No description provided for @generalImagesOnly.
  ///
  /// In en, this message translates to:
  /// **'Only images can be added to a General chat'**
  String get generalImagesOnly;

  /// No description provided for @generalNoImageInput.
  ///
  /// In en, this message translates to:
  /// **'{model} doesn’t read images'**
  String generalNoImageInput(String model);

  /// No description provided for @generalSwitchModel.
  ///
  /// In en, this message translates to:
  /// **'Switch model'**
  String get generalSwitchModel;

  /// No description provided for @generalImage.
  ///
  /// In en, this message translates to:
  /// **'Image {index}'**
  String generalImage(int index);

  /// No description provided for @settingsGeneralSection.
  ///
  /// In en, this message translates to:
  /// **'General chat'**
  String get settingsGeneralSection;

  /// No description provided for @settingsGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneral;

  /// No description provided for @settingsGeneralNoKey.
  ///
  /// In en, this message translates to:
  /// **'OpenRouter · no key yet'**
  String get settingsGeneralNoKey;

  /// No description provided for @settingsGeneralSub.
  ///
  /// In en, this message translates to:
  /// **'OpenRouter · {model}'**
  String settingsGeneralSub(String model);

  /// No description provided for @generalSettingsKey.
  ///
  /// In en, this message translates to:
  /// **'OpenRouter key'**
  String get generalSettingsKey;

  /// No description provided for @generalKeyPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste an OpenRouter key'**
  String get generalKeyPaste;

  /// No description provided for @generalKeyPasteAction.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get generalKeyPasteAction;

  /// No description provided for @generalKeyHelper.
  ///
  /// In en, this message translates to:
  /// **'Create a separate key for this phone with a monthly limit at openrouter.ai/keys'**
  String get generalKeyHelper;

  /// No description provided for @generalKeySave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get generalKeySave;

  /// No description provided for @generalKeyReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get generalKeyReplace;

  /// No description provided for @generalKeyRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get generalKeyRemove;

  /// No description provided for @generalKeyRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove the key?'**
  String get generalKeyRemoveTitle;

  /// No description provided for @generalKeyRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'General chats stay on this phone. Nothing can be sent until you add a key again.'**
  String get generalKeyRemoveBody;

  /// No description provided for @generalKeyRejected.
  ///
  /// In en, this message translates to:
  /// **'OpenRouter rejected this key'**
  String get generalKeyRejected;

  /// No description provided for @generalKeyNotKey.
  ///
  /// In en, this message translates to:
  /// **'This doesn\'t look like an OpenRouter key'**
  String get generalKeyNotKey;

  /// No description provided for @generalKeySaved.
  ///
  /// In en, this message translates to:
  /// **'Key saved'**
  String get generalKeySaved;

  /// No description provided for @generalKeySavedUnchecked.
  ///
  /// In en, this message translates to:
  /// **'Key saved — OpenRouter couldn\'t be reached to check it'**
  String get generalKeySavedUnchecked;

  /// No description provided for @generalKeySpend.
  ///
  /// In en, this message translates to:
  /// **'{used} of {limit}'**
  String generalKeySpend(String used, String limit);

  /// No description provided for @generalKeySpendNoLimit.
  ///
  /// In en, this message translates to:
  /// **'{used} spent · no limit'**
  String generalKeySpendNoLimit(String used);

  /// No description provided for @generalKeyResets.
  ///
  /// In en, this message translates to:
  /// **'Resets {date}'**
  String generalKeyResets(String date);

  /// No description provided for @generalKeyPeriodMonthly.
  ///
  /// In en, this message translates to:
  /// **'this month'**
  String get generalKeyPeriodMonthly;

  /// No description provided for @generalKeyPeriodWeekly.
  ///
  /// In en, this message translates to:
  /// **'this week'**
  String get generalKeyPeriodWeekly;

  /// No description provided for @generalKeyPeriodDaily.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get generalKeyPeriodDaily;

  /// No description provided for @generalKeyNoReset.
  ///
  /// In en, this message translates to:
  /// **'This key\'s limit never resets. A monthly limit keeps a leaked key cheap: set one at openrouter.ai/keys.'**
  String get generalKeyNoReset;

  /// No description provided for @generalKeyInfoFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the key\'s limits: {reason}'**
  String generalKeyInfoFailed(String reason);

  /// No description provided for @generalSettingsModels.
  ///
  /// In en, this message translates to:
  /// **'Models'**
  String get generalSettingsModels;

  /// No description provided for @generalDefaultModel.
  ///
  /// In en, this message translates to:
  /// **'Default model'**
  String get generalDefaultModel;

  /// No description provided for @generalShowTokens.
  ///
  /// In en, this message translates to:
  /// **'Show tokens under answers'**
  String get generalShowTokens;

  /// No description provided for @generalShowTokensSub.
  ///
  /// In en, this message translates to:
  /// **'Output tokens next to the model and cost'**
  String get generalShowTokensSub;

  /// No description provided for @generalPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Requests go straight from this phone to OpenRouter. Zero data retention and no training are required on every request. Nothing from your desktop is sent.'**
  String get generalPrivacyNote;

  /// No description provided for @generalMenuUsage.
  ///
  /// In en, this message translates to:
  /// **'Usage'**
  String get generalMenuUsage;

  /// No description provided for @generalUsageCost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get generalUsageCost;

  /// No description provided for @generalUsageAnswersTile.
  ///
  /// In en, this message translates to:
  /// **'Answers'**
  String get generalUsageAnswersTile;

  /// No description provided for @generalUsageContext.
  ///
  /// In en, this message translates to:
  /// **'Context of the last answer'**
  String get generalUsageContext;

  /// No description provided for @generalUsageByModel.
  ///
  /// In en, this message translates to:
  /// **'By model'**
  String get generalUsageByModel;

  /// No description provided for @generalUsageNoAnswers.
  ///
  /// In en, this message translates to:
  /// **'No answers yet.'**
  String get generalUsageNoAnswers;

  /// No description provided for @generalUsageAnswers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 answer} other{{count} answers}}'**
  String generalUsageAnswers(int count);

  /// No description provided for @generalUsageResets.
  ///
  /// In en, this message translates to:
  /// **'resets {date}'**
  String generalUsageResets(String date);

  /// No description provided for @generalFavAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get generalFavAdd;

  /// No description provided for @generalFavEmpty.
  ///
  /// In en, this message translates to:
  /// **'No favourites. Add one here or star a model in the picker.'**
  String get generalFavEmpty;

  /// No description provided for @generalFavRemoved.
  ///
  /// In en, this message translates to:
  /// **'{model} removed from favourites'**
  String generalFavRemoved(String model);

  /// No description provided for @pickerSubFavourite.
  ///
  /// In en, this message translates to:
  /// **'add to favourites · per 1M tokens in / out'**
  String get pickerSubFavourite;

  /// No description provided for @generalSettingsPrompt.
  ///
  /// In en, this message translates to:
  /// **'System prompt'**
  String get generalSettingsPrompt;

  /// No description provided for @generalPromptHint.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get generalPromptHint;

  /// No description provided for @generalPromptHelper.
  ///
  /// In en, this message translates to:
  /// **'Sent with every General message. Empty by default.'**
  String get generalPromptHelper;

  /// No description provided for @generalSettingsChats.
  ///
  /// In en, this message translates to:
  /// **'Chats on this phone'**
  String get generalSettingsChats;

  /// No description provided for @generalExport.
  ///
  /// In en, this message translates to:
  /// **'Export chats'**
  String get generalExport;

  /// No description provided for @generalExportSub.
  ///
  /// In en, this message translates to:
  /// **'One .zip with chats, images and settings · never the key'**
  String get generalExportSub;

  /// No description provided for @generalExportDone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Exported 1 chat to {folder}} other{Exported {count} chats to {folder}}}'**
  String generalExportDone(int count, String folder);

  /// No description provided for @generalExportShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get generalExportShare;

  /// No description provided for @generalExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t export: {error}'**
  String generalExportFailed(String error);

  /// No description provided for @generalImport.
  ///
  /// In en, this message translates to:
  /// **'Import chats'**
  String get generalImport;

  /// No description provided for @generalImportSub.
  ///
  /// In en, this message translates to:
  /// **'Adds the chats of a Delve export · the newer version of a chat wins'**
  String get generalImportSub;

  /// No description provided for @generalImportChats.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Imported 1 chat} other{Imported {count} chats}}'**
  String generalImportChats(int count);

  /// No description provided for @generalImportImages.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 image} other{{count} images}}'**
  String generalImportImages(int count);

  /// No description provided for @generalImportResult.
  ///
  /// In en, this message translates to:
  /// **'{chats} — {created} new, {updated} updated, {images}'**
  String generalImportResult(
    String chats,
    int created,
    int updated,
    String images,
  );

  /// No description provided for @generalImportOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get generalImportOk;

  /// No description provided for @generalImportNotExport.
  ///
  /// In en, this message translates to:
  /// **'This file isn\'t a Delve export'**
  String get generalImportNotExport;

  /// No description provided for @generalImportTooNew.
  ///
  /// In en, this message translates to:
  /// **'This export is from a newer version of Delve. Update the app to import it.'**
  String get generalImportTooNew;

  /// No description provided for @generalImportDamaged.
  ///
  /// In en, this message translates to:
  /// **'This export is damaged — nothing was imported.'**
  String get generalImportDamaged;

  /// No description provided for @generalImportPickAnother.
  ///
  /// In en, this message translates to:
  /// **'Pick another file'**
  String get generalImportPickAnother;

  /// No description provided for @generalImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t import: {error}'**
  String generalImportFailed(String error);

  /// No description provided for @systemStateSwitching.
  ///
  /// In en, this message translates to:
  /// **'switching'**
  String get systemStateSwitching;

  /// No description provided for @modelLoadsOnStart.
  ///
  /// In en, this message translates to:
  /// **'loads on Start'**
  String get modelLoadsOnStart;

  /// No description provided for @modelPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Local models'**
  String get modelPickerTitle;

  /// No description provided for @modelPickerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One model is loaded at a time.'**
  String get modelPickerSubtitle;

  /// No description provided for @modelPickerStopped.
  ///
  /// In en, this message translates to:
  /// **'llama-server is stopped. Start loads the model you pick.'**
  String get modelPickerStopped;

  /// No description provided for @modelPickerFooter.
  ///
  /// In en, this message translates to:
  /// **'Presets live on the desktop in {path}.'**
  String modelPickerFooter(String path);

  /// No description provided for @modelReasonContext.
  ///
  /// In en, this message translates to:
  /// **'Needs 65,536 tok of context for the agent'**
  String get modelReasonContext;

  /// No description provided for @modelReasonMissing.
  ///
  /// In en, this message translates to:
  /// **'Model file not found'**
  String get modelReasonMissing;

  /// No description provided for @modelReasonProjector.
  ///
  /// In en, this message translates to:
  /// **'Image projector file not found'**
  String get modelReasonProjector;

  /// No description provided for @modelReasonNoModel.
  ///
  /// In en, this message translates to:
  /// **'The preset names no model file'**
  String get modelReasonNoModel;

  /// No description provided for @modelReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Can\'t be loaded'**
  String get modelReasonOther;

  /// No description provided for @modelCapImages.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get modelCapImages;

  /// No description provided for @modelCapTextOnly.
  ///
  /// In en, this message translates to:
  /// **'Text only'**
  String get modelCapTextOnly;

  /// No description provided for @modelCapThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking'**
  String get modelCapThinking;

  /// No description provided for @modelCapAlways.
  ///
  /// In en, this message translates to:
  /// **'Always thinks'**
  String get modelCapAlways;

  /// No description provided for @modelCapNoThinking.
  ///
  /// In en, this message translates to:
  /// **'No thinking'**
  String get modelCapNoThinking;

  /// No description provided for @modelLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading {model}…'**
  String modelLoading(String model);

  /// No description provided for @modelStartedFrom.
  ///
  /// In en, this message translates to:
  /// **'Started from {device} · {time}'**
  String modelStartedFrom(String device, String time);

  /// No description provided for @modelSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch to {model}?'**
  String modelSwitchTitle(String model);

  /// No description provided for @modelSwitchBody.
  ///
  /// In en, this message translates to:
  /// **'Loading takes about a minute. Messages you send meanwhile wait.'**
  String get modelSwitchBody;

  /// No description provided for @modelSwitchRunChat.
  ///
  /// In en, this message translates to:
  /// **'in “{chat}”'**
  String modelSwitchRunChat(String chat);

  /// No description provided for @modelSwitchQueued.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 queued message runs on the new model.} other{{count} queued messages run on the new model.}}'**
  String modelSwitchQueued(int count);

  /// No description provided for @modelSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get modelSwitch;

  /// No description provided for @modelStopAndSwitch.
  ///
  /// In en, this message translates to:
  /// **'Stop run and switch'**
  String get modelStopAndSwitch;

  /// No description provided for @modelQueueWaits.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 message waits for the new model.} other{{count} messages wait for the new model.}}'**
  String modelQueueWaits(int count);

  /// No description provided for @modelFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load {model}. Back on {previous}.'**
  String modelFailed(String model, String previous);

  /// No description provided for @modelFailedAlone.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load {model}.'**
  String modelFailedAlone(String model);

  /// No description provided for @modelFailedDown.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load {model} and couldn\'t go back to {previous}. llama-server is down.'**
  String modelFailedDown(String model, String previous);

  /// No description provided for @modelFailedDownAlone.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load {model}. llama-server is down.'**
  String modelFailedDownAlone(String model);

  /// No description provided for @modelFailedShort.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load {model} · back on {previous}'**
  String modelFailedShort(String model, String previous);

  /// No description provided for @modelFailedDownShort.
  ///
  /// In en, this message translates to:
  /// **'Switch failed — llama-server is down'**
  String get modelFailedDownShort;

  /// No description provided for @modelExitedAfter.
  ///
  /// In en, this message translates to:
  /// **'llama-server exited after {time}'**
  String modelExitedAfter(String time);

  /// No description provided for @modelNotReadyAfter.
  ///
  /// In en, this message translates to:
  /// **'Not ready after {time}'**
  String modelNotReadyAfter(String time);

  /// No description provided for @modelDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get modelDismiss;

  /// No description provided for @modelDismissFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t dismiss: {reason}'**
  String modelDismissFailed(String reason);

  /// No description provided for @modelNotUsable.
  ///
  /// In en, this message translates to:
  /// **'That model can\'t be loaded.'**
  String get modelNotUsable;

  /// No description provided for @modelSwitchInProgress.
  ///
  /// In en, this message translates to:
  /// **'A model switch is already in progress.'**
  String get modelSwitchInProgress;

  /// No description provided for @modelUnknown.
  ///
  /// In en, this message translates to:
  /// **'That preset is no longer on the desktop.'**
  String get modelUnknown;

  /// No description provided for @modelSwitchFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t switch the model: {reason}'**
  String modelSwitchFailed(String reason);
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
