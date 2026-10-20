import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../widgets/page_scaffolds.dart';

/// 01 Pairing — server URL + one-time code. Built in A2.
class PairingScreen extends StatelessWidget {
  const PairingScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: TopLevelPage(
      title: AppLocalizations.of(context).pairingTitle,
      child: const NotBuiltYet(icon: DelveIcons.link, step: 'A2'),
    ),
  );
}
