import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../terminal/terminal_providers.dart';
import '../widgets/terminal_tabs_ui.dart';
import 'areas.dart';
import 'list_area.dart';

/// The Terminal area in the desktop layout (27W-12; only with Settings →
/// Desktop tools on): the machine's tmux sessions in the list column, the
/// tabs and the terminal in the content; no inspector.
class TerminalArea extends ConsumerWidget {
  const TerminalArea({super.key, required this.content});

  final Widget content;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListArea(
    area: DesktopArea.terminal.name,
    // the content is never empty (the tab in front, or "no tabs")
    selected: 'terminal',
    list: TerminalSessionsPane(service: ref.watch(terminalServiceProvider)),
    content: content,
  );
}
