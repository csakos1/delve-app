import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/page_scaffolds.dart';

/// 02 Chats — the list arrives in A4.
class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: TopLevelPage(
        title: l.navChats,
        child: const NotBuiltYet(icon: DelveIcons.chats, step: 'A4'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.newChat),
        icon: const SymbolIcon(DelveIcons.edit),
        label: Text(l.newChat),
      ),
    );
  }
}
