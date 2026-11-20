import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../api/models/models.dart';
import '../../app/approvals.dart';
import '../../app/chat_list.dart';
import '../../app/news.dart';
import '../../app/platform.dart';
import '../../app/router.dart';
import '../../data/db/database.dart' show ChatListItem;
import '../../general/general_database.dart' show GeneralChatRow;
import '../../general/general_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../sync/sync_providers.dart';
import '../../theme/delve_theme.dart';
import '../screens/settings_screen.dart' show settingsSections;
import '../widgets/chat_row.dart' show ChatRow;
import '../widgets/news_ui.dart' show NewsIcons;
import '../widgets/page_scaffolds.dart';
import 'approvals_card.dart' show answerableNow;
import 'areas.dart';
import 'desktop_page.dart';
import 'desktop_shell.dart' show newChatLocation;
import 'dock.dart';
import 'panes.dart';
import 'shortcut_sheet.dart';
import 'status_bar.dart' show clockText;

/// The palette's groups, in the order they show (Components “Layers”):
/// empty – Now · Go to · Recent chats · Actions; typing – Now · Chats ·
/// News · Pages · Actions.
enum PaletteGroup { now, goTo, recent, chats, news, pages, actions }

/// One result row of the palette.
class PaletteEntry {
  const PaletteEntry({
    required this.id,
    required this.group,
    required this.icon,
    required this.title,
    required this.run,
    this.detail,
    this.meta,
    this.metaColor,
    this.iconColor,
    this.filledIcon = false,
    this.mono = false,
    this.keys,
    this.terms = const [],
  });

  /// Unique in the palette: its row's key is `palette.<id>`.
  final String id;
  final PaletteGroup group;
  final IconData icon;
  final String title;

  /// Muted, after the title (a chat's kind, a story's publisher).
  final String? detail;

  /// Right-aligned state (an approval's countdown, a run's clock).
  final String? meta;
  final Color? metaColor;
  final Color? iconColor;
  final bool filledIcon;

  /// The title is a command.
  final bool mono;

  /// A key cap at the end.
  final String? keys;

  /// Other text a query may match (not marked).
  final List<String> terms;

  /// What the row does; the palette is closed first.
  final VoidCallback run;
}

const Map<String, String> _plain = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a', //
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', //
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', //
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o', 'ő': 'o', //
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ű': 'u', //
  'ç': 'c', 'ñ': 'n', 'ý': 'y',
};

/// [s] in lower case without accents, one character for one: a match's
/// place in it is its place in [s] ("Vízállás" finds "vizallas").
String foldForSearch(String s) {
  final b = StringBuffer();
  for (final c in s.split('')) {
    final lower = c.toLowerCase();
    final one = lower.length == 1 ? lower : c;
    b.write(_plain[one] ?? one);
  }
  return b.toString();
}

/// The words of a query, folded.
List<String> paletteWords(String query) => foldForSearch(
  query.trim(),
).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

/// [e] has every word in its title or its terms.
bool paletteMatches(PaletteEntry e, List<String> words) {
  final title = foldForSearch(e.title);
  final terms = [for (final t in e.terms) foldForSearch(t)];
  return words.every(
    (w) => title.contains(w) || terms.any((t) => t.contains(w)),
  );
}

/// 0: the title starts with the first word; 1: the title has them all;
/// 2: the rest.
int paletteRank(PaletteEntry e, List<String> words) {
  final title = foldForSearch(e.title);
  if (words.isNotEmpty && title.startsWith(words.first)) return 0;
  return words.every(title.contains) ? 1 : 2;
}

/// Where the words are in [title] (start, end), sorted, not overlapping.
List<(int, int)> paletteMarks(String title, List<String> words) {
  final folded = foldForSearch(title);
  final marks = <(int, int)>[];
  for (final w in words) {
    final at = folded.indexOf(w);
    if (at >= 0) marks.add((at, at + w.length));
  }
  marks.sort((a, b) => a.$1.compareTo(b.$1));
  final merged = <(int, int)>[];
  for (final m in marks) {
    if (merged.isNotEmpty && m.$1 <= merged.last.$2) {
      final last = merged.removeLast();
      merged.add((last.$1, math.max(last.$2, m.$2)));
    } else {
      merged.add(m);
    }
  }
  return merged;
}

/// The command palette (Ctrl+K, 27W-14a / 14b): 660 wide, 84 from the top,
/// on the 64 % scrim. Esc, Ctrl+K or a click outside closes it; ↑ / ↓ move,
/// Enter runs the selected row. [location] is the router's: Go to brings an
/// area back where it was left. An approval is opened from here, never
/// answered.
Future<void> showCommandPalette(
  BuildContext context, {
  required String location,
}) async {
  if (_CommandPaletteState.live > 0) return;
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: AppLocalizations.of(context).close,
    barrierColor: Colors.black.withValues(alpha: 0.64),
    transitionDuration: DelveDesktop.hover,
    pageBuilder: (dialog, _, _) =>
        CommandPalette(shell: context, location: location),
    transitionBuilder: (context, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

class CommandPalette extends ConsumerStatefulWidget {
  const CommandPalette({
    super.key,
    required this.shell,
    required this.location,
  });

  /// The desktop shell's context: rows navigate with it.
  final BuildContext shell;
  final String location;

  @override
  ConsumerState<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends ConsumerState<CommandPalette> {
  /// Palettes on screen: Ctrl+K and Search open one only.
  static int live = 0;

  final _query = TextEditingController();
  final _scroll = ScrollController();
  int _selected = 0;
  List<PaletteEntry> _shown = const [];
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    live++;
    _query.addListener(() => setState(() => _selected = 0));
    // the stories are kept in memory: load them once if nothing did yet
    final news = ref.read(newsProvider);
    if (news.sections == null) {
      unawaited(
        ref
            .read(newsProvider.notifier)
            .refreshSections()
            .catchError((Object _) {}),
      );
    }
  }

  @override
  void dispose() {
    live--;
    _tick?.cancel();
    _query.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// A countdown or a run's clock: once a second while one shows.
  void _ticking(bool on) {
    if (on && _tick == null) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!on && _tick != null) {
      _tick!.cancel();
      _tick = null;
    }
  }

  void _run(PaletteEntry e) {
    Navigator.of(context).pop();
    e.run();
  }

  void _move(int by) {
    if (_shown.isEmpty) return;
    setState(() => _selected = (_selected + by).clamp(0, _shown.length - 1));
    _reveal();
  }

  /// The selected row scrolled into view (rows 38, eyebrows 26).
  void _reveal() {
    if (!_scroll.hasClients) return;
    var top = 0.0;
    PaletteGroup? group;
    for (var i = 0; i < _shown.length; i++) {
      if (_shown[i].group != group) {
        group = _shown[i].group;
        top += DelveDesktop.paletteEyebrow;
      }
      if (i == _selected) break;
      top += DelveDesktop.paletteRow;
    }
    final view = _scroll.position.viewportDimension;
    final at = _scroll.offset;
    const pad = DelveTokens.space1;
    if (top < at) {
      _scroll.jumpTo(math.max(0, top - DelveDesktop.paletteEyebrow));
    } else if (top + DelveDesktop.paletteRow + pad > at + view) {
      _scroll.jumpTo(
        math.min(
          _scroll.position.maxScrollExtent,
          top + DelveDesktop.paletteRow + pad - view,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final window = MediaQuery.sizeOf(context);
    final words = paletteWords(_query.text);
    final entries = _entries(l, words);
    _shown = entries;
    if (_selected >= entries.length) {
      _selected = math.max(0, entries.length - 1);
    }
    final width = math.min(DelveDesktop.paletteWidth, window.width - 32);
    final maxHeight = math.max(
      200.0,
      window.height - DelveDesktop.paletteTop - DelveTokens.space6,
    );

    final rows = <Widget>[];
    PaletteGroup? group;
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      if (e.group != group) {
        group = e.group;
        rows.add(_Eyebrow(_groupTitle(l, group)));
      }
      rows.add(
        _Row(
          entry: e,
          words: words,
          selected: i == _selected,
          onHover: () {
            if (_selected != i) setState(() => _selected = i);
          },
          onTap: () => _run(e),
        ),
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: DelveDesktop.paletteTop),
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.arrowDown): () => _move(1),
            const SingleActivator(LogicalKeyboardKey.arrowUp): () => _move(-1),
            const SingleActivator(LogicalKeyboardKey.enter): () {
              if (_shown.isNotEmpty) _run(_shown[_selected]);
            },
            const SingleActivator(LogicalKeyboardKey.numpadEnter): () {
              if (_shown.isNotEmpty) _run(_shown[_selected]);
            },
            const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
                Navigator.of(context).pop(),
          },
          child: Material(
            key: const Key('palette'),
            color: cs.surfaceContainerHigh,
            elevation: 2,
            shadowColor: Colors.black,
            borderRadius: BorderRadius.circular(DelveDesktop.paletteRadius),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: width,
                minWidth: width,
                maxHeight: maxHeight,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Field(controller: _query, hint: l.paletteHint),
                  Container(
                    height: DelveTokens.hairline,
                    color: cs.outlineVariant,
                  ),
                  Flexible(
                    child: entries.isEmpty
                        ? Padding(
                            key: const Key('palette.empty'),
                            padding: const EdgeInsets.all(DelveTokens.space4),
                            child: Text(
                              l.paletteEmpty(_query.text.trim()),
                              style: context.text.bodyMedium!.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          )
                        : ListView(
                            key: const Key('palette.results'),
                            controller: _scroll,
                            shrinkWrap: true,
                            padding: const EdgeInsets.fromLTRB(6, 2, 6, 6),
                            children: rows,
                          ),
                  ),
                  _Foot(l: l),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _groupTitle(AppLocalizations l, PaletteGroup g) => switch (g) {
    PaletteGroup.now => l.paletteNow,
    PaletteGroup.goTo => l.paletteGoTo,
    PaletteGroup.recent => l.paletteRecent,
    PaletteGroup.chats => l.paletteChats,
    PaletteGroup.news => l.newsTitle,
    PaletteGroup.pages => l.palettePages,
    PaletteGroup.actions => l.paletteActions,
  };

  /// What the palette shows for [words] (none: the empty palette).
  List<PaletteEntry> _entries(AppLocalizations l, List<String> words) {
    final typing = words.isNotEmpty;
    final now = _now(l);
    _ticking(now.isNotEmpty);
    List<PaletteEntry> pick(List<PaletteEntry> all, {int? limit}) {
      if (!typing) return limit == null ? all : all.take(limit).toList();
      final hits = [
        for (final e in all)
          if (paletteMatches(e, words)) e,
      ];
      // a stable sort: the rank first, then the group's own order
      final ranked = [
        for (var i = 0; i < hits.length; i++) (paletteRank(hits[i], words), i),
      ]..sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
      final sorted = [for (final r in ranked) hits[r.$2]];
      return limit == null ? sorted : sorted.take(limit).toList();
    }

    if (!typing) {
      return [
        ...now,
        ..._areas(l, PaletteGroup.goTo),
        ..._chats(
          l,
          PaletteGroup.recent,
          archived: false,
        ).take(DelveDesktop.paletteRecent),
        ..._actions(l),
      ];
    }
    return [
      ...pick(now),
      ...pick(_chats(l, PaletteGroup.chats, archived: true), limit: 8),
      ...pick(_news(l), limit: 6),
      ...pick(_pages(l), limit: 8),
      ...pick(_actions(l)),
    ];
  }

  void _go(String location) => widget.shell.go(location);

  /// Now: the approvals that can be answered (newest first) and the live
  /// runs – opened, never answered.
  List<PaletteEntry> _now(AppLocalizations l) {
    final d = context.delve;
    final cs = context.colors;
    final now = DateTime.now();
    final inbox = ref.watch(approvalInboxProvider).value;
    final runs = ref.watch(liveRunsProvider);
    final titles = _agentTitles(l);
    return [
      for (final i in answerableNow(inbox, now))
        _approval(l, i, now, d.warnFg, d.infoFg),
      for (final r
          in runs.values.toList()
            ..sort((a, b) => a.startedAt.compareTo(b.startedAt)))
        PaletteEntry(
          id: 'run.${r.runId}',
          group: PaletteGroup.now,
          icon: DelveIcons.progress,
          iconColor: cs.primary,
          title: titles[r.conversationId] ?? l.newChat,
          meta: l.paletteRun(clockText(now.difference(r.startedAt))),
          metaColor: cs.primary,
          run: () => _go(Routes.chat(r.conversationId)),
        ),
    ];
  }

  PaletteEntry _approval(
    AppLocalizations l,
    InboxApproval i,
    DateTime now,
    Color warn,
    Color info,
  ) {
    final a = i.approval;
    final pending = a.status == 'pending';
    return PaletteEntry(
      id: 'approval.${a.requestId}',
      group: PaletteGroup.now,
      icon: pending ? DelveIcons.approvals : DelveIcons.timerOff,
      filledIcon: pending,
      iconColor: pending ? warn : info,
      title: a.command,
      mono: true,
      detail: i.chatTitle,
      meta: pending
          ? l.paletteApprovalWaits(clockText(a.hermesDeadline.difference(now)))
          : l.paletteApprovalLate(
              DateFormat('HH:mm').format(a.expiresAt.toLocal()),
            ),
      metaColor: pending ? warn : info,
      terms: [?i.chatTitle],
      run: () => _go(Routes.approval(a.requestId)),
    );
  }

  /// The agent chats' titles by id (the live runs name their chat).
  Map<String, String> _agentTitles(AppLocalizations l) => {
    for (final item
        in ref.watch(chatListProvider(false)).value ?? const <ChatListItem>[])
      item.conversation.id: ChatRow.titleOf(item, l.newChat),
  };

  /// The areas (Terminal and Files with the tools on), each as it was
  /// left; Observability and About me have no other key.
  List<PaletteEntry> _areas(AppLocalizations l, PaletteGroup group) {
    final tools = ref.watch(desktopToolsProvider);
    final places = ref.read(desktopPlacesProvider);
    return [
      for (final a in DesktopArea.values)
        if (!a.tool || tools)
          PaletteEntry(
            id: 'area.${a.name}',
            group: group,
            icon: a.icon,
            title: a.title(l),
            keys: a.keys(l),
            run: () => _go(places.target(a, widget.location)),
          ),
    ];
  }

  /// Agent and General chats, the latest first ([archived]: the archive
  /// too, marked).
  List<PaletteEntry> _chats(
    AppLocalizations l,
    PaletteGroup group, {
    required bool archived,
  }) {
    final rows = <(DateTime, PaletteEntry)>[];
    void agent(List<ChatListItem>? items, {required bool gone}) {
      for (final item in items ?? const <ChatListItem>[]) {
        final c = item.conversation;
        rows.add((
          c.updatedAt,
          PaletteEntry(
            id: 'chat.c.${c.id}',
            group: group,
            icon: DelveIcons.forum,
            title: ChatRow.titleOf(item, l.newChat),
            detail: gone ? l.paletteArchived : null,
            terms: [?item.lastText, ?item.firstUserText],
            run: () => _go(Routes.chat(c.id)),
          ),
        ));
      }
    }

    void general(List<GeneralChatRow>? items, {required bool gone}) {
      for (final g in items ?? const <GeneralChatRow>[]) {
        final title = g.title?.trim();
        rows.add((
          g.updatedAt,
          PaletteEntry(
            id: 'chat.g.${g.id}',
            group: group,
            icon: DelveIcons.cloud,
            title: title == null || title.isEmpty
                ? (g.preview ?? l.newChat)
                : title,
            detail: gone ? l.paletteArchived : l.chatsFilterGeneral,
            terms: [?g.preview],
            run: () => _go(Routes.generalChat(g.id)),
          ),
        ));
      }
    }

    agent(ref.watch(chatListProvider(false)).value, gone: false);
    general(ref.watch(generalChatsProvider(false)).value, gone: false);
    if (archived) {
      agent(ref.watch(chatListProvider(true)).value, gone: true);
      general(ref.watch(generalChatsProvider(true)).value, gone: true);
    }
    rows.sort((a, b) => b.$1.compareTo(a.$1));
    return [for (final r in rows) r.$2];
  }

  /// The stories the app holds (the Dashboard block, the sections and
  /// every story it opened), each once.
  List<PaletteEntry> _news(AppLocalizations l) {
    final news = ref.watch(newsProvider);
    final seen = <int>{};
    final out = <PaletteEntry>[];
    void add(NewsItem item) {
      if (!seen.add(item.id)) return;
      final s = news.current(item);
      out.add(
        PaletteEntry(
          id: 'news.${s.id}',
          group: PaletteGroup.news,
          icon: NewsIcons.news,
          title: s.title,
          detail: [
            news.topicName(s.topic),
            ?s.publisher,
          ].where((t) => t.isNotEmpty).join(' · '),
          terms: [?s.publisher, ?s.why, news.topicName(s.topic)],
          run: () => _go(Routes.newsStory(s.id)),
        ),
      );
    }

    for (final s in news.sections ?? const <NewsSection>[]) {
      s.top.forEach(add);
    }
    news.digest?.top.forEach(add);
    news.latest.values.forEach(add);
    return out;
  }

  /// Every place a key or the rail reaches, and the pages under them.
  List<PaletteEntry> _pages(AppLocalizations l) {
    final tools = ref.watch(desktopToolsProvider);
    final sections = settingsSections(
      caps: ref.watch(platformCapsProvider),
      tools: tools,
      desktop: true,
    );
    return [
      ..._areas(l, PaletteGroup.pages),
      for (final s in sections)
        PaletteEntry(
          id: 'page.settings.${s.name}',
          group: PaletteGroup.pages,
          icon: s.icon,
          title: l.paletteSettingsPage(s.title(l)),
          run: () => _go(Routes.settingsAt(s.name)),
        ),
      PaletteEntry(
        id: 'page.newsSettings',
        group: PaletteGroup.pages,
        icon: DelveIcons.settings,
        title: l.newsSettingsTitle,
        run: () => _go(Routes.newsSettings),
      ),
      PaletteEntry(
        id: 'page.archived',
        group: PaletteGroup.pages,
        icon: DelveIcons.archive,
        title: l.moreArchived,
        run: () => _go(Routes.archived),
      ),
      PaletteEntry(
        id: 'page.log',
        group: PaletteGroup.pages,
        icon: DelveIcons.log,
        title: l.logTitle,
        run: () => _go(Routes.connectionLog),
      ),
      if (tools)
        PaletteEntry(
          id: 'page.clipboard',
          group: PaletteGroup.pages,
          icon: DelveIcons.paste,
          title: l.moreClipboard,
          run: () => _go(Routes.clipboard),
        ),
    ];
  }

  /// What a key does, for those who look for it here.
  List<PaletteEntry> _actions(AppLocalizations l) {
    final area = DesktopArea.of(widget.location)?.name;
    final tools = ref.watch(desktopToolsProvider);
    final refresh = ref.read(pageCommandSlotProvider).current;
    final shell = widget.shell;
    double width() => MediaQuery.sizeOf(shell).width;
    return [
      PaletteEntry(
        id: 'action.newAgent',
        group: PaletteGroup.actions,
        icon: DelveIcons.edit,
        title: l.paletteNewAgent,
        keys: DesktopKeys.newChat,
        run: () => _go(newChatLocation('agent')),
      ),
      PaletteEntry(
        id: 'action.newGeneral',
        group: PaletteGroup.actions,
        icon: DelveIcons.cloud,
        title: l.paletteNewGeneral,
        keys: DesktopKeys.newGeneral,
        run: () => _go(newChatLocation('general')),
      ),
      if (refresh != null)
        PaletteEntry(
          id: 'action.refresh',
          group: PaletteGroup.actions,
          icon: DelveIcons.refresh,
          title: l.paletteRefresh,
          keys: DesktopKeys.refresh,
          run: refresh.refresh,
        ),
      if (area != null) ...[
        PaletteEntry(
          id: 'action.list',
          group: PaletteGroup.actions,
          icon: DelveIcons.panes,
          title: l.shortcutsList,
          keys: DesktopKeys.list,
          run: () => ref
              .read(paneLayoutsProvider.notifier)
              .toggleList(
                area,
                overlay: width() < DelveDesktop.listOverlayBelow,
              ),
        ),
        PaletteEntry(
          id: 'action.inspector',
          group: PaletteGroup.actions,
          icon: DelveIcons.inspector,
          title: l.shortcutsInspector,
          keys: DesktopKeys.inspector,
          run: () => ref
              .read(paneLayoutsProvider.notifier)
              .toggleInspector(
                area,
                overlay: width() < DelveDesktop.inspectorOverlayBelow,
              ),
        ),
      ],
      if (tools)
        PaletteEntry(
          id: 'action.dock',
          group: PaletteGroup.actions,
          icon: DelveIcons.dockToBottom,
          title: l.shortcutsDockToggle,
          keys: DesktopKeys.dock,
          run: () {
            if (area == DesktopArea.terminal.name) {
              dockTerminal(shell, ref);
              return;
            }
            final dock = ref.read(dockProvider.notifier);
            if (ref.read(dockProvider).open) {
              dock.hide();
            } else {
              dock.show(focus: true);
            }
          },
        ),
      PaletteEntry(
        id: 'action.shortcuts',
        group: PaletteGroup.actions,
        icon: DelveIcons.keyboard,
        title: l.shortcutsTitle,
        keys: DesktopKeys.sheet,
        run: () => unawaited(showShortcutSheet(shell)),
      ),
    ];
  }
}

/// The 52 px field row: `search` 20 and the query at 15 / 22.
class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return SizedBox(
      height: DelveDesktop.paletteField,
      child: Row(
        children: [
          const SizedBox(width: 16),
          SymbolIcon(DelveIcons.search, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              key: const Key('palette.field'),
              controller: controller,
              autofocus: true,
              style: context.text.bodyLarge!.copyWith(
                fontSize: 15,
                height: 22 / 15,
              ),
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isCollapsed: true,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: DelveDesktop.paletteEyebrow,
    child: Padding(
      padding: const EdgeInsets.only(left: 10, top: 9),
      child: Text(
        title.toUpperCase(),
        style: context.text.labelSmall!.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.7,
          color: context.delve.textMuted,
        ),
      ),
    ),
  );
}

/// A result row: 38 high, radius 8, selected `surface-4`; the query's words
/// marked in the title on `accent-container`.
class _Row extends StatelessWidget {
  const _Row({
    required this.entry,
    required this.words,
    required this.selected,
    required this.onHover,
    required this.onTap,
  });

  final PaletteEntry entry;
  final List<String> words;
  final bool selected;
  final VoidCallback onHover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final e = entry;
    final base = e.mono
        ? DelveText.mono.copyWith(
            fontSize: 12.5,
            height: 18 / 12.5,
            color: cs.onSurface,
          )
        : context.text.bodyMedium!.copyWith(
            fontSize: 13.5,
            height: 18 / 13.5,
            color: cs.onSurface,
          );
    final marks = paletteMarks(e.title, words);
    final spans = <TextSpan>[];
    var at = 0;
    for (final (start, end) in marks) {
      if (start > at) spans.add(TextSpan(text: e.title.substring(at, start)));
      spans.add(
        TextSpan(
          text: e.title.substring(start, end),
          style: TextStyle(
            backgroundColor: cs.primaryContainer,
            color: cs.onPrimaryContainer,
          ),
        ),
      );
      at = end;
    }
    if (at < e.title.length) spans.add(TextSpan(text: e.title.substring(at)));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onHover: (_) => onHover(),
      child: GestureDetector(
        key: ValueKey('palette.${e.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: DelveDesktop.paletteRow,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? cs.surfaceContainerHighest : null,
            borderRadius: BorderRadius.circular(DelveDesktop.rowRadius),
          ),
          child: Row(
            children: [
              SymbolIcon(
                e.icon,
                size: 18,
                filled: e.filledIcon,
                color: e.iconColor ?? cs.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Flexible(
                flex: 3,
                child: Text.rich(
                  TextSpan(style: base, children: spans),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (e.detail case final detail? when detail.isNotEmpty) ...[
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall!.copyWith(
                      fontSize: 12,
                      color: context.delve.textMuted,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (e.meta case final meta?) ...[
                const SizedBox(width: 10),
                Text(
                  meta,
                  style: context.text.labelMedium!.copyWith(
                    color: e.metaColor ?? cs.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
              if (e.keys case final keys?) ...[
                const SizedBox(width: 10),
                KeyCap(keys),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The 36 px foot: the palette's own keys.
class _Foot extends StatelessWidget {
  const _Foot({required this.l});

  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final style = context.text.labelMedium!.copyWith(
      color: context.delve.textMuted,
    );
    Widget key(String keys, String what) => Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          KeyCap(keys),
          const SizedBox(width: 6),
          Text(what, style: style),
        ],
      ),
    );
    return Container(
      height: DelveDesktop.paletteFoot,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          key(DesktopKeys.move, l.paletteMove),
          key(DesktopKeys.enter, l.paletteOpen),
          key(DesktopKeys.esc, l.close),
        ],
      ),
    );
  }
}
