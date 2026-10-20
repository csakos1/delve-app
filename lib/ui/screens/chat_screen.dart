import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../widgets/page_scaffolds.dart';

/// 03–10 Chat (detail, no bottom nav). [conversationId] is null for a new
/// chat. Built in A4–A6.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key, required this.conversationId});

  final String? conversationId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SubPage(
      title: conversationId == null ? l.newChat : l.chatTitle,
      child: const NotBuiltYet(icon: DelveIcons.chats, step: 'A4'),
    );
  }
}
