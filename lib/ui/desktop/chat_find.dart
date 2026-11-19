import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../widgets/page_scaffolds.dart';

/// The items of a chat (oldest first) whose text holds [query], newest
/// first; nothing for an empty query.
List<int> findMatches(String query, List<String> texts) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  return [
    for (var i = texts.length - 1; i >= 0; i--)
      if (texts[i].toLowerCase().contains(q)) i,
  ];
}

/// Search in the open chat (Ctrl+F, L2b2): open or not, the query, which
/// match is current (0: the newest). The screen counts the matches in its
/// build ([findMatches]); [seek] goes up whenever the current match should
/// be scrolled to.
class ChatFind extends ChangeNotifier {
  bool _open = false;
  String _query = '';
  int _at = 0;
  int _seek = 0;

  bool get open => _open;
  String get query => _query;
  int get seek => _seek;

  /// The current match among [count]: 0 is the newest.
  int position(int count) => count == 0 ? 0 : _at.clamp(0, count - 1);

  void show() {
    if (_open) {
      _seek++;
    } else {
      _open = true;
    }
    notifyListeners();
  }

  void close() {
    _open = false;
    _query = '';
    _at = 0;
    notifyListeners();
  }

  void search(String query) {
    _query = query;
    _at = 0;
    _seek++;
    notifyListeners();
  }

  /// The next older match (Enter, ↓).
  void older(int count) => _move(count, 1);

  /// The next newer match (Shift+Enter, ↑).
  void newer(int count) => _move(count, -1);

  void _move(int count, int by) {
    if (count == 0) return;
    _at = (position(count) + by) % count;
    _seek++;
    notifyListeners();
  }
}

/// Keeps a [ChatFind]'s current match in view: one [GlobalKey] per item
/// (by the item's own key), scrolled to after the frame that built it.
class FindScroller {
  final Map<Key, GlobalKey> _keys = {};
  int _done = 0;

  GlobalKey keyOf(Key item) => _keys.putIfAbsent(item, GlobalKey.new);

  /// Called from build: when [find] asks for a new seek, the item keyed
  /// [current] is scrolled to the middle once it is laid out.
  void follow(ChatFind find, Key? current) {
    if (find.seek == _done || current == null) return;
    _done = find.seek;
    final key = keyOf(current);
    var tries = 0;
    void go(Duration _) {
      final ctx = key.currentContext;
      if (ctx == null) {
        // the list builds everything while searching: one more frame
        if (++tries < 4) {
          WidgetsBinding.instance
            ..addPostFrameCallback(go)
            ..scheduleFrame();
        }
        return;
      }
      unawaited(
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.5,
          duration: DelveTokens.short,
          curve: DelveTokens.standard,
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback(go);
  }
}

/// A chat item while searching: the current match framed in accent (2 px,
/// radius 12, over the item – nothing moves).
class FindMark extends StatelessWidget {
  const FindMark({super.key, required this.current, required this.child});

  final bool current;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    foregroundDecoration: current
        ? BoxDecoration(
            border: Border.all(color: context.colors.primary, width: 2),
            borderRadius: BorderRadius.circular(12),
          )
        : null,
    child: child,
  );
}

/// The search bar over a chat (Ctrl+F): a 36 px field, “i / n”, newer /
/// older, close. Enter goes to the next older match, Shift+Enter to the
/// newer one, Esc closes.
class ChatFindBar extends StatefulWidget {
  const ChatFindBar({super.key, required this.find, required this.count});

  final ChatFind find;
  final int count;

  @override
  State<ChatFindBar> createState() => _ChatFindBarState();
}

class _ChatFindBarState extends State<ChatFindBar> {
  late final TextEditingController _text = TextEditingController(
    text: widget.find.query,
  );
  final FocusNode _focus = FocusNode(debugLabel: 'chat.find');
  int _seen = -1;

  @override
  void initState() {
    super.initState();
    _focusSoon();
  }

  @override
  void didUpdateWidget(ChatFindBar old) {
    super.didUpdateWidget(old);
    // Ctrl+F again: back into the field, the query selected
    if (widget.find.seek != _seen && !_focus.hasFocus) _focusSoon();
  }

  void _focusSoon() {
    _seen = widget.find.seek;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focus.requestFocus();
      _text.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _text.text.length,
      );
    });
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final d = context.delve;
    final find = widget.find;
    final count = widget.count;
    final hasQuery = find.query.trim().isNotEmpty;
    final label = !hasQuery
        ? ''
        : count == 0
        ? l.desktopFindNone
        : l.desktopFindCount(find.position(count) + 1, count);
    Widget button(Key key, IconData icon, String tip, VoidCallback? onTap) =>
        IconButton(
          key: key,
          tooltip: tip,
          onPressed: onTap,
          icon: SymbolIcon(icon, size: DelveDesktop.iconButtonIcon),
        );
    return Padding(
      key: const Key('chat.findBar'),
      padding: const EdgeInsets.fromLTRB(
        DelveTokens.space4,
        DelveTokens.space2,
        DelveTokens.space4,
        DelveTokens.space1,
      ),
      child: Row(
        children: [
          Expanded(
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.enter): () =>
                    find.older(count),
                const SingleActivator(LogicalKeyboardKey.numpadEnter): () =>
                    find.older(count),
                const SingleActivator(
                  LogicalKeyboardKey.enter,
                  shift: true,
                ): () =>
                    find.newer(count),
                const SingleActivator(LogicalKeyboardKey.escape): find.close,
              },
              child: SizedBox(
                height: 36,
                child: TextField(
                  key: const Key('chat.findField'),
                  controller: _text,
                  focusNode: _focus,
                  onChanged: find.search,
                  style: context.text.bodyMedium,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: l.desktopFindHint,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    prefixIcon: const SymbolIcon(DelveIcons.search, size: 16),
                    prefixIconConstraints: const BoxConstraints(minWidth: 32),
                    suffixText: label,
                    suffixStyle: DelveText.monoSmall.copyWith(
                      color: count == 0 && hasQuery ? d.warnFg : d.textMuted,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        DelveDesktop.buttonRadius,
                      ),
                    ),
                    filled: true,
                    fillColor: cs.surfaceContainerLow,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: DelveTokens.space1),
          button(
            const Key('chat.find.newer'),
            DelveIcons.expandLess,
            l.desktopFindNewer,
            count > 1 ? () => find.newer(count) : null,
          ),
          button(
            const Key('chat.find.older'),
            DelveIcons.expandMore,
            l.desktopFindOlder,
            count > 1 ? () => find.older(count) : null,
          ),
          button(
            const Key('chat.find.close'),
            DelveIcons.close,
            l.desktopFindClose,
            find.close,
          ),
        ],
      ),
    );
  }
}
