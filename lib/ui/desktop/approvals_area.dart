import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/approvals.dart';
import '../../l10n/app_localizations.dart';
import '../screens/approvals_screen.dart';
import '../widgets/page_scaffolds.dart';
import 'areas.dart';
import 'chat_inspector.dart';
import 'list_area.dart';

/// The approval an Approvals [location] shows (null: none).
@visibleForTesting
String? selectedApproval(String location) {
  final s = Uri.parse(location).pathSegments;
  if (s.length == 3 && s[0] == 'chats' && s[1] == 'approvals') return s[2];
  return null;
}

/// Approvals in the desktop layout (27W-3): the whole history in the list
/// column, the open approval in the content, its run in the inspector.
class ApprovalsArea extends StatelessWidget {
  const ApprovalsArea({
    super.key,
    required this.location,
    required this.content,
  });

  final String location;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    final id = selectedApproval(location);
    return ListArea(
      area: DesktopArea.approvals.name,
      selected: id,
      list: ApprovalsScreen(selected: id),
      content: content,
      inspector: id == null
          ? null
          : ApprovalRunInspector(
              key: ValueKey('inspector.approval.$id'),
              id: id,
            ),
    );
  }
}

/// The open approval's run: the chat inspector (Run · Usage) of the chat it
/// came from.
class ApprovalRunInspector extends ConsumerWidget {
  const ApprovalRunInspector({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = ref.watch(approvalInboxProvider).value;
    String? conversation;
    for (final list in [inbox?.pending, inbox?.expired, inbox?.recent]) {
      for (final i in list ?? const <InboxApproval>[]) {
        if (i.approval.requestId == id) {
          conversation = i.approval.conversationId;
        }
      }
    }
    if (conversation == null) return const SizedBox.shrink();
    return ChatInspector(conversationId: conversation);
  }
}

/// The content of Approvals while none is open.
class ApprovalsPlaceholder extends StatelessWidget {
  const ApprovalsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListPlaceholder(
      key: const Key('approvals.placeholder'),
      icon: DelveIcons.approvals,
      title: l.desktopApprovalsEmpty,
      hint: l.desktopApprovalsEmptySub,
    );
  }
}
