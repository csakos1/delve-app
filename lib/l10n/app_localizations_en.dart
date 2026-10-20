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
  String get pairingTitle => 'Pair with your server';

  @override
  String get notBuiltYet => 'Not built yet';

  @override
  String get back => 'Back';
}
