import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/platform.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../widgets/page_scaffolds.dart';
import 'areas.dart';
import 'panes.dart';

/// The desktop's keys as their key caps show them (Components “Shortcuts”).
/// On macOS Ctrl will be ⌘ – one place to change.
abstract final class DesktopKeys {
  static const palette = 'Ctrl+K';
  static const sheet = '?';
  static const newChat = 'Ctrl+N';
  static const newGeneral = 'Ctrl+Shift+N';
  static const settings = 'Ctrl+,';
  static const list = 'Ctrl+B';
  static const inspector = 'Ctrl+I';
  static const nextTab = 'Ctrl+]';
  static const usage = 'Ctrl+U';
  static const find = 'Ctrl+F';
  static const refresh = 'Ctrl+R';
  static const archive = 'E';
  static const undo = 'Ctrl+Z';
  static const esc = 'Esc';
  static const dock = 'Ctrl+`';
  static const dockBack = 'Shift+Esc';
  static const enter = 'Enter';
  static const newLine = 'Shift+Enter';
  static const attach = 'Ctrl+O';
  static const paste = 'Ctrl+V';
  static const stop = 'Ctrl+.';
  static const thinking = 'Ctrl+T';
  static const allow = 'Ctrl+Enter';
  static const deny = 'Ctrl+⌫';
  static const save = 'Ctrl+S';
  static const up = 'Backspace';
  static const selectAll = 'Ctrl+A';
  static const copy = 'Ctrl+C';
  static const cut = 'Ctrl+X';
  static const rename = 'F2';
  static const trash = 'Del';
  static const delete = 'Shift+Del';
  static const move = '↑ ↓';
}

/// One line of the shortcut sheet: what it does and its keys (each its
/// own key cap).
class ShortcutLine {
  const ShortcutLine(this.label, this.keys);

  final String label;
  final List<String> keys;
}

/// A titled group of lines.
class ShortcutGroup {
  const ShortcutGroup(this.title, this.lines);

  final String title;
  final List<ShortcutLine> lines;
}

/// The sheet's three columns (27W-14c): only keys that work now – Terminal
/// and Files with the desktop tools on.
List<List<ShortcutGroup>> shortcutColumns(
  AppLocalizations l, {
  required bool tools,
}) {
  final areas = [
    for (final a in DesktopArea.values)
      if (a.digit != null && (!a.tool || tools))
        ShortcutLine(a.title(l), [l.desktopKeyArea(a.digit!)]),
  ];
  return [
    [
      ShortcutGroup(l.shortcutsGo, [
        ShortcutLine(l.shortcutsPalette, const [DesktopKeys.palette]),
        ...areas,
        ShortcutLine(l.moreSettings, const [DesktopKeys.settings]),
        ShortcutLine(l.shortcutsSheet, const [DesktopKeys.sheet]),
      ]),
    ],
    [
      ShortcutGroup(l.shortcutsPanes, [
        ShortcutLine(l.shortcutsList, const [DesktopKeys.list]),
        ShortcutLine(l.shortcutsInspector, const [DesktopKeys.inspector]),
        ShortcutLine(l.shortcutsNextTab, const [DesktopKeys.nextTab]),
        ShortcutLine(l.shortcutsUsage, const [DesktopKeys.usage]),
        ShortcutLine(l.shortcutsFind, const [DesktopKeys.find]),
        ShortcutLine(l.shortcutsRefresh, const [DesktopKeys.refresh]),
        ShortcutLine(l.shortcutsRows, const ['J', 'K', '↓', '↑']),
        ShortcutLine(l.shortcutsArchive, const [DesktopKeys.archive]),
        ShortcutLine(l.shortcutsUndo, const [DesktopKeys.undo]),
        ShortcutLine(l.shortcutsOverlay, const [DesktopKeys.esc]),
      ]),
      if (tools)
        ShortcutGroup(l.shortcutsDock, [
          ShortcutLine(l.shortcutsDockToggle, const [DesktopKeys.dock]),
          ShortcutLine(l.shortcutsDockBack, const [DesktopKeys.dockBack]),
        ]),
    ],
    [
      ShortcutGroup(l.shortcutsChat, [
        ShortcutLine(l.shortcutsSend, const [DesktopKeys.enter]),
        ShortcutLine(l.shortcutsNewLine, const [DesktopKeys.newLine]),
        ShortcutLine(l.paletteNewAgent, const [DesktopKeys.newChat]),
        ShortcutLine(l.paletteNewGeneral, const [DesktopKeys.newGeneral]),
        ShortcutLine(l.shortcutsAttach, const [DesktopKeys.attach]),
        ShortcutLine(l.shortcutsPasteImage, const [DesktopKeys.paste]),
        ShortcutLine(l.shortcutsStop, const [DesktopKeys.stop]),
        ShortcutLine(l.shortcutsThinking, const [DesktopKeys.thinking]),
      ]),
      ShortcutGroup(l.shortcutsApprovals, [
        ShortcutLine(l.shortcutsAllow, const [DesktopKeys.allow]),
        ShortcutLine(l.shortcutsDeny, const [DesktopKeys.deny]),
      ]),
      ShortcutGroup(l.shortcutsEditors, [
        ShortcutLine(l.shortcutsSave, const [DesktopKeys.save]),
        ShortcutLine(l.shortcutsCancel, const [DesktopKeys.esc]),
      ]),
      if (tools)
        ShortcutGroup(l.navFiles, [
          ShortcutLine(l.shortcutsOpen, const [DesktopKeys.enter]),
          ShortcutLine(l.shortcutsFolderUp, const [DesktopKeys.up]),
          ShortcutLine(l.shortcutsSelectAll, const [DesktopKeys.selectAll]),
          ShortcutLine(l.shortcutsClip, const [
            DesktopKeys.copy,
            DesktopKeys.cut,
            DesktopKeys.paste,
          ]),
          ShortcutLine(l.shortcutsRename, const [DesktopKeys.rename]),
          ShortcutLine(l.shortcutsTrash, const [DesktopKeys.trash]),
          ShortcutLine(l.shortcutsDelete, const [DesktopKeys.delete]),
          ShortcutLine(l.shortcutsUpload, const [DesktopKeys.attach]),
        ]),
    ],
  ];
}

/// Sheets on screen: ? opens one only.
int _sheetsLive = 0;

/// The shortcut sheet (?, 27W-14c): a 940 px dialog on the scrim, three
/// columns of 28 px rows with the key caps right-aligned; Esc or a click
/// outside closes it.
Future<void> showShortcutSheet(BuildContext context) async {
  if (_sheetsLive > 0) return;
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.64),
    builder: (_) => const _Counted(child: ShortcutSheet()),
  );
}

/// Counts [child] in [_sheetsLive] while it is mounted; takes the focus
/// (the sheet has no field or button that would), so Esc and ? close it.
class _Counted extends StatefulWidget {
  const _Counted({required this.child});

  final Widget child;

  @override
  State<_Counted> createState() => _CountedState();
}

class _CountedState extends State<_Counted> {
  @override
  void initState() {
    super.initState();
    _sheetsLive++;
  }

  @override
  void dispose() {
    _sheetsLive--;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.escape): () =>
          Navigator.of(context).pop(),
      const CharacterActivator('?'): () => Navigator.of(context).pop(),
    },
    child: Focus(autofocus: true, child: widget.child),
  );
}

class ShortcutSheet extends ConsumerWidget {
  const ShortcutSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final window = MediaQuery.sizeOf(context);
    final columns = shortcutColumns(l, tools: ref.watch(desktopToolsProvider));
    return Dialog(
      key: const Key('shortcuts'),
      backgroundColor: cs.surfaceContainerHigh,
      insetPadding: const EdgeInsets.all(DelveTokens.space4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DelveDesktop.dialogRadius),
      ),
      child: SizedBox(
        key: const Key('shortcuts.box'),
        width: math.min(DelveDesktop.shortcutSheetWidth, window.width - 48),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 12, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.shortcutsTitle,
                      style: context.text.titleMedium,
                    ),
                  ),
                  IconButton(
                    key: const Key('shortcuts.close'),
                    tooltip: l.close,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const SymbolIcon(
                      DelveIcons.close,
                      size: DelveDesktop.iconButtonIcon,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DelveTokens.space2),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < columns.length; i++) ...[
                        if (i > 0) const SizedBox(width: 28),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [for (final g in columns[i]) _Group(g)],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group(this.group);

  final ShortcutGroup group;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              group.title.toUpperCase(),
              style: context.text.labelSmall!.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.7,
                color: context.delve.textMuted,
              ),
            ),
          ),
          for (final line in group.lines)
            SizedBox(
              height: DelveDesktop.shortcutRow,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      line.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodyMedium!.copyWith(fontSize: 13),
                    ),
                  ),
                  for (var i = 0; i < line.keys.length; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    KeyCap(line.keys[i]),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
