import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../widgets/page_scaffolds.dart';

/// 12 Dashboard — after the MVP (decision 178).
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => TopLevelPage(
    title: AppLocalizations.of(context).navDashboard,
    child: const NotBuiltYet(icon: DelveIcons.dashboard, step: 'B'),
  );
}
