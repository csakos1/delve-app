import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/layout.dart';
import '../../app/router.dart';
import '../../l10n/app_localizations.dart';
import '../../terminal/ssh_link.dart';
import '../../terminal/terminal_service.dart';
import '../../terminal/terminal_tabs.dart';
import '../../theme/delve_theme.dart';
import '../desktop/desktop_row.dart';
import '../format.dart';
import 'page_scaffolds.dart';
import 'status_ui.dart';
import 'terminal_ui.dart';

/// 22a tab bar: one tab per tmux session (T3). Tap = switch; long press and
/// let go = the tab's menu; long press and drag = move it. [trailing]: `+`
/// and `⋯`, pinned right; the tabs scroll under a fade.
class TerminalTabBar extends StatefulWidget {
  const TerminalTabBar({
    super.key,
    required this.tabs,
    required this.active,
    this.onSelect,
    this.onMenu,
    this.onMove,
    this.trailing = const [],
  });

  final List<TerminalTab> tabs;
  final int active;
  final ValueChanged<int>? onSelect;

  /// Long press without a move: the tab's index and where it is on screen.
  final void Function(int index, Rect at)? onMenu;

  /// A drag: from an index to the final index. null: no reordering (the
  /// lock screen).
  final void Function(int from, int to)? onMove;
  final List<Widget> trailing;

  @override
  State<TerminalTabBar> createState() => _TerminalTabBarState();
}

class _TerminalTabBarState extends State<TerminalTabBar> {
  /// Where each tab was built (not a GlobalKey: the drag shows the same
  /// widget in its proxy).
  final _places = <int, BuildContext>{};
  int? _dragFrom;
  Rect? _dragRect;

  Rect? _rectOf(int index) {
    final place = _places[widget.tabs[index].id];
    if (place == null || !place.mounted) return null;
    final box = place.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _started(int index) {
    // where the tab is before the drag takes it off the bar
    _dragFrom = index;
    _dragRect = _rectOf(index);
    unawaited(HapticFeedback.selectionClick());
  }

  void _ended(int insert) {
    final from = _dragFrom;
    final rect = _dragRect;
    _dragFrom = null;
    _dragRect = null;
    // let go where it was (the insert index counts the dragged tab, so one
    // more when it came back from the right): the menu, not a move
    if (from == null ||
        rect == null ||
        (insert != from && insert != from + 1)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onMenu?.call(from, rect);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tabs = widget.tabs;
    _places.removeWhere((id, _) => !tabs.any((t) => t.id == id));

    Widget tab(int i) => Builder(
      builder: (place) {
        _places[tabs[i].id] = place;
        return _Tab(
          tab: tabs[i],
          index: i,
          count: tabs.length,
          active: i == widget.active,
          onTap: widget.onSelect == null ? null : () => widget.onSelect!(i),
        );
      },
    );

    final onMove = widget.onMove;
    final list = onMove == null
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [for (var i = 0; i < tabs.length; i++) tab(i)],
            ),
          )
        : ReorderableListView.builder(
            key: const Key('terminal.tabs'),
            scrollDirection: Axis.horizontal,
            buildDefaultDragHandles: false,
            itemCount: tabs.length,
            onReorderStart: _started,
            onReorderEnd: _ended,
            onReorder: (from, to) => onMove(from, to > from ? to - 1 : to),
            proxyDecorator: (child, _, _) => Material(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(DelveTokens.rsm),
              child: child,
            ),
            itemBuilder: (context, i) => ReorderableDelayedDragStartListener(
              key: ValueKey(tabs[i].id),
              index: i,
              child: tab(i),
            ),
          );

    return SizedBox(
      height: DelveTokens.terminalTabBar,
      child: Row(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: list),
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  width: DelveTokens.terminalTabFade,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [cs.surface.withAlpha(0), cs.surface],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...widget.trailing,
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.tab,
    required this.index,
    required this.count,
    required this.active,
    this.onTap,
  });

  final TerminalTab tab;
  final int index;
  final int count;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final phase = tab.connection.phase;
    return Semantics(
      selected: active,
      button: onTap != null,
      label: l.termTabSemantics(
        tab.session,
        index + 1,
        count,
        connectionWord(l, phase),
      ),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          key: ValueKey('terminal.tab.${tab.session}'),
          height: DelveTokens.terminalTabBar,
          constraints: const BoxConstraints(
            minWidth: DelveTokens.terminalTabMinWidth,
          ),
          child: Stack(
            alignment: AlignmentDirectional.centerStart,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 14, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConnectionDot(phase: phase),
                    const SizedBox(width: 7),
                    Text(
                      tab.session,
                      style: DelveText.mono.copyWith(
                        color: active ? cs.onSurface : cs.onSurfaceVariant,
                        fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (active)
                Positioned(
                  key: const Key('terminal.tab.underline'),
                  left: 10,
                  right: 12,
                  bottom: 0,
                  height: DelveTokens.railWidth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(1),
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

/// The tab's long-press tooltip (design 22): name · state · columns × rows.
String tabTooltip(AppLocalizations l, TerminalTab tab) {
  final c = tab.connection;
  final t = c.terminal;
  return l.termTabTooltip(
    tab.session,
    connectionWord(l, c.phase),
    t.viewWidth,
    t.viewHeight,
  );
}

/// The tab's menu under it: the tooltip line, Rename, Close tab, Kill
/// session… (design 22). In the desktop layout the desktop's context menu
/// (27W-14d) with the same three (L2d3, N533).
Future<void> showTabMenu(
  BuildContext context, {
  required TerminalService service,
  required TerminalTab tab,
  required Rect at,
}) async {
  final l = AppLocalizations.of(context);
  final d = context.delve;
  if (DesktopLayout.of(context)) {
    void run(String choice) =>
        unawaited(_tabChoice(context, service, tab, choice));
    await showDesktopMenu(context, at.bottomLeft, [
      DesktopMenuItem(
        key: const Key('terminal.tabMenu.rename'),
        icon: DelveIcons.rename,
        label: l.termTabRename,
        onSelected: () => run('rename'),
      ),
      DesktopMenuItem(
        key: const Key('terminal.tabMenu.close'),
        icon: DelveIcons.tabClose,
        label: l.termTabClose,
        onSelected: () => run('close'),
      ),
      DesktopMenuItem(
        key: const Key('terminal.tabMenu.kill'),
        icon: DelveIcons.kill,
        label: l.termTabKill,
        destructive: true,
        onSelected: () => run('kill'),
      ),
    ]);
    return;
  }
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final choice = await showMenu<String>(
    context: context,
    position: RelativeRect.fromRect(
      Rect.fromLTWH(at.left, at.bottom, at.width, 0),
      Offset.zero & overlay.size,
    ),
    items: [
      PopupMenuItem(
        enabled: false,
        height: DelveTokens.terminalStateLine,
        child: Text(
          tabTooltip(l, tab),
          style: DelveText.monoSmall.copyWith(color: d.textMuted),
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem(
        key: const Key('terminal.tabMenu.rename'),
        value: 'rename',
        child: _MenuRow(icon: DelveIcons.rename, text: l.termTabRename),
      ),
      PopupMenuItem(
        key: const Key('terminal.tabMenu.close'),
        value: 'close',
        child: _MenuRow(icon: DelveIcons.tabClose, text: l.termTabClose),
      ),
      PopupMenuItem(
        key: const Key('terminal.tabMenu.kill'),
        value: 'kill',
        child: _MenuRow(
          icon: DelveIcons.kill,
          text: l.termTabKill,
          color: d.alertFg,
        ),
      ),
    ],
  );
  if (choice == null || !context.mounted) return;
  await _tabChoice(context, service, tab, choice);
}

/// What the tab's menu does.
Future<void> _tabChoice(
  BuildContext context,
  TerminalService service,
  TerminalTab tab,
  String choice,
) async {
  switch (choice) {
    case 'rename':
      final name = await askSessionName(context, tab.session);
      if (name == null || !context.mounted) return;
      await _tmux(context, () => service.renameSession(tab.session, name));
    case 'close':
      await service.closeTab(tab);
    case 'kill':
      final yes = await confirmKillSession(context, tab.session);
      if (!yes || !context.mounted) return;
      await _tmux(context, () => service.killSession(tab.session));
  }
}

/// Runs a tmux command; a failure shows in a snackbar.
Future<void> _tmux(BuildContext context, Future<void> Function() run) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    await run();
  } on Object catch (e) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(tmuxProblemText(l, e))));
  }
}

/// What went wrong with a tmux command or the session list, for the user.
String tmuxProblemText(AppLocalizations l, Object e) => switch (e) {
  TmuxCommandFailed(:final detail) => l.termTmuxFailed(detail),
  SshFailure(:final detail) => l.termSessionsFailed(detail),
  _ => l.termSessionsFailed('$e'),
};

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SymbolIcon(
        icon,
        size: DelveTokens.iconMd,
        color: color ?? context.colors.onSurfaceVariant,
      ),
      const SizedBox(width: DelveTokens.space3),
      Flexible(
        child: Text(text, style: TextStyle(color: color)),
      ),
    ],
  );
}

/// A new name for a session: null when cancelled. Only names tmux keeps as
/// they are ([cleanSessionName]).
Future<String?> askSessionName(BuildContext context, String current) =>
    showDialog<String>(
      context: context,
      builder: (_) => _RenameDialog(current: current),
    );

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.current});

  final String current;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _field = TextEditingController(text: widget.current)
    ..selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.current.length,
    );

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  /// Read when pressed, not when built (T2a: a closure built with the old
  /// text sent the old value).
  void _save() {
    final name = cleanSessionName(_field.text);
    if (name == null || name == widget.current) return;
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = _field.text;
    final name = cleanSessionName(text);
    final bad = text.trim().isNotEmpty && name == null;
    return AlertDialog(
      key: const Key('terminal.rename.dialog'),
      title: Text(l.termRenameTitle),
      content: TextField(
        key: const Key('terminal.rename.field'),
        controller: _field,
        autofocus: true,
        autocorrect: false,
        style: DelveText.mono,
        decoration: InputDecoration(
          labelText: l.termRenameLabel,
          helperText: bad ? null : l.termRenameHint,
          errorText: bad ? l.termRenameInvalid : null,
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('terminal.rename.save'),
          onPressed: name == null || name == widget.current ? null : _save,
          child: Text(l.termRenameSave),
        ),
      ],
    );
  }
}

/// 22g2: what a kill ends; true = kill.
Future<bool> confirmKillSession(BuildContext context, String name) async {
  final l = AppLocalizations.of(context);
  final d = context.delve;
  final yes = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      key: const Key('terminal.kill.dialog'),
      title: Text(l.termKillTitle(name)),
      content: Text(l.termKillBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('terminal.kill.confirm'),
          style: FilledButton.styleFrom(
            backgroundColor: d.alertFg,
            foregroundColor: context.colors.surface,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l.termKill),
        ),
      ],
    ),
  );
  return yes ?? false;
}

/// 22g1: the tmux sessions on the desktop. [onSettings]: the gear (the
/// sheet closes first).
Future<void> showTerminalSessions(
  BuildContext context, {
  required TerminalService service,
  required VoidCallback onSettings,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) =>
      TerminalSessionsSheet(service: service, onSettings: onSettings),
);

class TerminalSessionsSheet extends StatefulWidget {
  const TerminalSessionsSheet({
    super.key,
    required this.service,
    required this.onSettings,
  });

  final TerminalService service;
  final VoidCallback onSettings;

  @override
  State<TerminalSessionsSheet> createState() => _TerminalSessionsSheetState();
}

class _TerminalSessionsSheetState extends State<TerminalSessionsSheet> {
  List<TmuxSession>? _sessions;
  Object? _problem;
  bool _loading = true;

  TerminalService get _service => widget.service;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  /// [keepProblem]: after a failed command, its message stays.
  Future<void> _load({bool keepProblem = false}) async {
    if (!_loading) setState(() => _loading = true);
    try {
      final list = await _service.listSessions();
      if (!mounted) return;
      setState(() {
        _sessions = list;
        _loading = false;
        if (!keepProblem) _problem = null;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _problem = e;
        _loading = false;
      });
    }
  }

  /// A tmux command, then the list again; a failure shows above the list.
  Future<void> _act(Future<void> Function() run) async {
    setState(() => _problem = null);
    try {
      await run();
    } on Object catch (e) {
      if (mounted) setState(() => _problem = e);
    }
    if (mounted) await _load(keepProblem: true);
  }

  void _open(TmuxSession s) {
    _service.openSession(s);
    Navigator.of(context).pop();
  }

  void _new() {
    unawaited(_service.newTab());
    Navigator.of(context).pop();
  }

  Future<void> _rename(TmuxSession s) async {
    final name = await askSessionName(context, s.name);
    if (name == null || !mounted) return;
    await _act(() => _service.renameSession(s.name, name));
  }

  Future<void> _kill(TmuxSession s) async {
    if (!await confirmKillSession(context, s.name) || !mounted) return;
    await _act(() => _service.killSession(s.name));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = context.delve;
    final host = _service.config.host.split('.').first;
    return ListenableBuilder(
      listenable: Listenable.merge([
        _service,
        for (final t in _service.tabs) t.connection,
      ]),
      builder: (context, _) {
        final sessions = _sessions;
        final open = sessions == null
            ? 0
            : sessions.where((s) => _tabOf(s.name) != null).length;
        return Column(
          key: const Key('terminal.sessions'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DelveTokens.space5,
                DelveTokens.space2,
                DelveTokens.space2,
                DelveTokens.space2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.termSessionsTitle(host),
                          style: context.text.titleLarge,
                        ),
                        if (sessions != null)
                          Text(
                            l.termSessionsSummary(sessions.length, open),
                            style: context.text.labelMedium!.copyWith(
                              color: d.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('terminal.sessions.settings'),
                    tooltip: l.termMenuSettings,
                    icon: const SymbolIcon(DelveIcons.settings),
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onSettings();
                    },
                  ),
                ],
              ),
            ),
            if (_loading)
              const LinearProgressIndicator(minHeight: 2)
            else
              const SizedBox(height: 2),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: DelveTokens.space4),
                children: [
                  _NewSessionRow(onTap: _new),
                  if (_problem case final p?)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        DelveTokens.space4,
                        DelveTokens.space2,
                        DelveTokens.space4,
                        DelveTokens.space2,
                      ),
                      child: StatusBanner(
                        key: const Key('terminal.sessions.problem'),
                        kind: StatusKind.alert,
                        icon: DelveIcons.warning,
                        text: tmuxProblemText(l, p),
                        actionLabel: l.retry,
                        onAction: () => unawaited(_load()),
                      ),
                    ),
                  if (sessions != null && sessions.isEmpty)
                    const _NoSessions()
                  else if (sessions != null)
                    for (final s in sessions)
                      _SessionRow(
                        session: s,
                        status: _status(l, s),
                        open: _tabOf(s.name) != null,
                        onOpen: () => _open(s),
                        onRename: () => unawaited(_rename(s)),
                        onKill: () => unawaited(_kill(s)),
                      ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  TerminalTab? _tabOf(String name) {
    for (final t in _service.tabs) {
      if (t.session == name) return t;
    }
    return null;
  }

  String _status(AppLocalizations l, TmuxSession s) =>
      tmuxSessionStatus(l, _service, s);
}

/// Attached here (a live tab) and/or on the desktop (the other clients).
String tmuxSessionStatus(
  AppLocalizations l,
  TerminalService service,
  TmuxSession s,
) {
  final here = service.tabs
      .where((t) => t.session == s.name && t.connection.live)
      .length;
  final elsewhere = s.attached - here > 0;
  return switch ((here > 0, elsewhere)) {
    (true, true) => l.termSessionAttachedBoth,
    (true, false) => l.termSessionAttachedHere,
    (false, true) => l.termSessionAttachedDesktop,
    (false, false) => l.termSessionDetached,
  };
}

/// The desktop's list column of the Terminal area (27W-12): New session
/// first, then the machine's tmux sessions as 52 px rows – the one in front
/// selected, a tag on those open in a tab; a click opens (or brings
/// forward) its tab, right-click has Rename and Kill. The list is read
/// again when the tabs change and from the header's refresh.
class TerminalSessionsPane extends StatefulWidget {
  const TerminalSessionsPane({super.key, required this.service});

  final TerminalService service;

  @override
  State<TerminalSessionsPane> createState() => _TerminalSessionsPaneState();
}

class _TerminalSessionsPaneState extends State<TerminalSessionsPane> {
  List<TmuxSession>? _sessions;
  Object? _problem;
  bool _loading = false;

  /// The tabs' sessions the list was read for.
  String _seen = '';

  TerminalService get _service => widget.service;

  @override
  void initState() {
    super.initState();
    _service.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _changed();
    });
  }

  @override
  void dispose() {
    _service.removeListener(_changed);
    super.dispose();
  }

  /// A tab opened, closed or renamed: the list again (not on every redraw
  /// of a connection).
  void _changed() {
    if (!_service.ready) return;
    final now = [for (final t in _service.tabs) t.session].join('\u0000');
    if (now == _seen && _sessions != null) {
      setState(() {}); // the selection follows the tab in front
      return;
    }
    _seen = now;
    unawaited(_load());
  }

  Future<void> _load({bool keepProblem = false}) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final list = await _service.listSessions();
      if (!mounted) return;
      setState(() {
        _sessions = list;
        _loading = false;
        if (!keepProblem) _problem = null;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _problem = e;
        _loading = false;
      });
    }
  }

  Future<void> _act(Future<void> Function() run) async {
    setState(() => _problem = null);
    try {
      await run();
    } on Object catch (e) {
      if (mounted) setState(() => _problem = e);
    }
    if (mounted) await _load(keepProblem: true);
  }

  Future<void> _rename(TmuxSession s) async {
    final name = await askSessionName(context, s.name);
    if (name == null || !mounted) return;
    await _act(() => _service.renameSession(s.name, name));
  }

  Future<void> _kill(TmuxSession s) async {
    if (!await confirmKillSession(context, s.name) || !mounted) return;
    await _act(() => _service.killSession(s.name));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final d = context.delve;
    final sessions = _sessions;
    final front = _service.current?.session;
    final open = {for (final t in _service.tabs) t.session};
    return TopLevelPage(
      key: const Key('terminal.sessionsPane'),
      title: l.navTerminal,
      background: cs.surfaceContainerLow,
      actions: [
        IconButton(
          key: const Key('terminal.sessions.refresh'),
          tooltip: l.desktopRefresh,
          onPressed: () => unawaited(_load()),
          icon: const SymbolIcon(
            DelveIcons.refresh,
            size: DelveDesktop.iconButtonIcon,
          ),
        ),
        IconButton(
          key: const Key('terminal.sessions.settings'),
          tooltip: l.termMenuSettings,
          onPressed: () => context.open(Routes.terminalSettings),
          icon: const SymbolIcon(
            DelveIcons.settings,
            size: DelveDesktop.iconButtonIcon,
          ),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.only(bottom: DelveTokens.space4),
        children: [
          if (_loading)
            const LinearProgressIndicator(minHeight: 2)
          else
            const SizedBox(height: 2),
          DesktopRowFrame(
            key: const Key('terminal.sessions.new'),
            onTap: () => unawaited(_service.newTab()),
            child: Row(
              children: [
                SymbolIcon(DelveIcons.add, size: 16, color: cs.primary),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.termSessionsNew,
                        style: DelveDesktopText.rowTitle.copyWith(
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.termSessionsNewSub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DelveDesktopText.rowSecondary.copyWith(
                          color: d.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_problem case final p?)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: StatusBanner(
                key: const Key('terminal.sessions.problem'),
                kind: StatusKind.alert,
                icon: DelveIcons.warning,
                text: tmuxProblemText(l, p),
                actionLabel: l.retry,
                onAction: () => unawaited(_load()),
              ),
            ),
          if (sessions != null && sessions.isEmpty)
            const _NoSessions()
          else if (sessions != null)
            for (final s in sessions)
              DesktopRowFrame(
                key: ValueKey('terminal.session.${s.name}'),
                selected: s.name == front,
                onTap: () => _service.openSession(s),
                menu: [
                  DesktopMenuItem(
                    key: const Key('terminal.sessionMenu.rename'),
                    icon: DelveIcons.rename,
                    label: l.termTabRename,
                    onSelected: () => unawaited(_rename(s)),
                  ),
                  DesktopMenuItem(
                    key: const Key('terminal.sessionMenu.kill'),
                    icon: DelveIcons.kill,
                    label: l.termKill,
                    destructive: true,
                    onSelected: () => unawaited(_kill(s)),
                  ),
                ],
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: SymbolIcon(
                        open.contains(s.name)
                            ? DelveIcons.tab
                            : DelveIcons.terminal,
                        size: 16,
                        color: s.name == front
                            ? cs.onSurface
                            : cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            s.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DelveText.mono.copyWith(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            [
                              tmuxSessionStatus(l, _service, s),
                              l.termSessionWindows(s.windows),
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DelveDesktopText.rowSecondary.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _NewSessionRow extends StatelessWidget {
  const _NewSessionRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    return InkWell(
      key: const Key('terminal.sessions.new'),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: DelveTokens.terminalSessionRow,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
          child: Row(
            children: [
              SymbolIcon(DelveIcons.add, color: cs.primary),
              const SizedBox(width: DelveTokens.space5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l.termSessionsNew, style: context.text.titleSmall),
                    Text(
                      l.termSessionsNewSub,
                      style: context.text.bodySmall!.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({
    required this.session,
    required this.status,
    required this.open,
    required this.onOpen,
    required this.onRename,
    required this.onKill,
  });

  final TmuxSession session;
  final String status;

  /// A tab shows it here.
  final bool open;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onKill;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final d = context.delve;
    final s = session;
    final created = s.created;
    final meta = created == null
        ? l.termSessionWindows(s.windows)
        : l.termSessionMeta(
            s.windows,
            agoText(DateTime.now().difference(created)),
          );
    return InkWell(
      key: ValueKey('terminal.session.${s.name}'),
      onTap: onOpen,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: DelveTokens.terminalSessionRow,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 4, 8),
          child: Row(
            children: [
              SymbolIcon(
                open ? DelveIcons.tab : DelveIcons.terminal,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: DelveTokens.space5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: DelveTokens.space2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          s.name,
                          style: DelveText.mono.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (open)
                          _TabTag(
                            key: ValueKey('terminal.session.${s.name}.tag'),
                          ),
                      ],
                    ),
                    Text(
                      status,
                      style: context.text.bodySmall!.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      meta,
                      style: context.text.bodySmall!.copyWith(
                        color: d.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (!open)
                TextButton(
                  key: ValueKey('terminal.session.${s.name}.open'),
                  onPressed: onOpen,
                  child: Text(l.termSessionOpen),
                ),
              PopupMenuButton<String>(
                key: ValueKey('terminal.session.${s.name}.menu'),
                icon: const SymbolIcon(DelveIcons.moreVert),
                onSelected: (v) {
                  switch (v) {
                    case 'open':
                      onOpen();
                    case 'rename':
                      onRename();
                    default:
                      onKill();
                  }
                },
                itemBuilder: (_) => [
                  if (!open)
                    PopupMenuItem(
                      value: 'open',
                      child: _MenuRow(
                        icon: DelveIcons.tab,
                        text: l.termSessionOpen,
                      ),
                    ),
                  PopupMenuItem(
                    key: const Key('terminal.sessionMenu.rename'),
                    value: 'rename',
                    child: _MenuRow(
                      icon: DelveIcons.rename,
                      text: l.termTabRename,
                    ),
                  ),
                  PopupMenuItem(
                    key: const Key('terminal.sessionMenu.kill'),
                    value: 'kill',
                    child: _MenuRow(
                      icon: DelveIcons.kill,
                      text: l.termTabKill,
                      color: d.alertFg,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The “tab” tag next to a session open here.
class _TabTag extends StatelessWidget {
  const _TabTag({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(DelveTokens.rxs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SymbolIcon(DelveIcons.check, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            AppLocalizations.of(context).termSessionTag,
            style: context.text.labelSmall!.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoSessions extends StatelessWidget {
  const _NoSessions();

  @override
  Widget build(BuildContext context) {
    final d = context.delve;
    return Padding(
      key: const Key('terminal.sessions.empty'),
      padding: const EdgeInsets.all(DelveTokens.space6),
      child: Column(
        children: [
          SymbolIcon(DelveIcons.terminal, size: 40, color: d.textMuted),
          const SizedBox(height: DelveTokens.space3),
          Text(
            AppLocalizations.of(context).termSessionsEmpty,
            textAlign: TextAlign.center,
            style: context.text.bodyMedium!.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
