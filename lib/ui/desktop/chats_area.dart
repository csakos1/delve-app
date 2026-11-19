import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../screens/chats_screen.dart';
import '../widgets/page_scaffolds.dart';
import 'areas.dart';
import 'chat_inspector.dart';
import 'panes.dart';

/// The chat a Chats [location] shows: `c:<id>` (agent), `g:<id>` (General),
/// `new`, or null (nothing selected).
@visibleForTesting
String? selectedChat(String location) {
  final path = Uri.parse(location).path;
  if (path == Routes.newChat) return 'new';
  final segments = Uri.parse(path).pathSegments;
  if (segments.length == 3 && segments.first == 'chats') {
    return switch (segments[1]) {
      'c' => 'c:${segments[2]}',
      'g' => 'g:${segments[2]}',
      _ => null,
    };
  }
  return null;
}

/// Chats in the desktop layout (L2a, L2b): the chat list in the list
/// column, the chat in the content, an agent chat's run and Usage in the
/// inspector. Below 900 the list is an overlay: open while no
/// chat is selected, closed once one is.
class ChatsArea extends ConsumerStatefulWidget {
  const ChatsArea({super.key, required this.location, required this.content});

  final String location;
  final Widget content;

  @override
  ConsumerState<ChatsArea> createState() => _ChatsAreaState();
}

class _ChatsAreaState extends ConsumerState<ChatsArea> {
  static final String _area = DesktopArea.chats.name;

  @override
  void didUpdateWidget(ChatsArea old) {
    super.didUpdateWidget(old);
    final was = selectedChat(old.location);
    final now = selectedChat(widget.location);
    if (was == now) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final layouts = ref.read(paneLayoutsProvider.notifier);
      if (now == null) {
        layouts.openListOverlay(_area);
      } else {
        layouts.closeListOverlay(_area);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = selectedChat(widget.location);
    // an agent chat has an inspector (its run and Usage); General chats,
    // a new chat and the empty pane have none
    final agentChat = selected != null && selected.startsWith('c:')
        ? selected.substring(2)
        : null;
    return DesktopPanes(
      area: _area,
      list: ChatsScreen(selected: selected),
      content: widget.content,
      inspector: agentChat == null
          ? null
          : ChatInspector(
              key: ValueKey('inspector.$agentChat'),
              conversationId: agentChat,
            ),
    );
  }
}

/// The content while no chat is selected.
class ChatsPlaceholder extends StatelessWidget {
  const ChatsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    return Center(
      key: const Key('chats.placeholder'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SymbolIcon(
            DelveIcons.forum,
            size: 30,
            color: context.delve.textDisabled,
          ),
          const SizedBox(height: DelveTokens.space3),
          Text(l.desktopChatsEmpty, style: context.text.titleMedium),
          const SizedBox(height: DelveTokens.space1),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.desktopChatsEmptySub,
                style: context.text.bodyMedium!.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: DelveTokens.space2),
              KeyCap(l.desktopKeyNewChat),
            ],
          ),
        ],
      ),
    );
  }
}
