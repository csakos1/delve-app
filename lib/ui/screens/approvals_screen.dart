import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../widgets/page_scaffolds.dart';

/// 11 Approvals — pending, expired in agent, history. Built in A5.
class ApprovalsScreen extends StatelessWidget {
  const ApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) => TopLevelPage(
    title: AppLocalizations.of(context).navApprovals,
    child: const NotBuiltYet(icon: DelveIcons.approvals, step: 'A5'),
  );
}
