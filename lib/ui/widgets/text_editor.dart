import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../files/text_edit.dart';
import '../../l10n/app_localizations.dart';
import '../../terminal/terminal_theme.dart';
import '../../theme/delve_theme.dart';
import 'files_ui.dart';
import 'page_scaffolds.dart';

/// The edit well (23n): a mono text field with line numbers, the current
/// line, bars on the lines that differ from the opened version, and no
/// wrap (a horizontal scroll) unless [wrap].
///
/// Without wrap every line is exactly one line high (a forced strut), so
/// the gutter is the line index × the height. With wrap the gutter waits
/// for a layout of the text at the well's width (continuation rows get no
/// number).
class TextEditorWell extends StatefulWidget {
  const TextEditorWell({
    super.key,
    required this.controller,
    required this.undo,
    required this.focus,
    required this.changed,
    this.lineNumbers = true,
    this.wrap = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final UndoHistoryController undo;
  final FocusNode focus;

  /// Lines (0-based) that differ from the opened version.
  final Set<int> changed;
  final bool lineNumbers;
  final bool wrap;
  final ValueChanged<String>? onChanged;

  @override
  State<TextEditorWell> createState() => _TextEditorWellState();
}

class _TextEditorWellState extends State<TextEditorWell> {
  final _v = ScrollController();
  final _h = ScrollController();

  /// The field keeps its element when Wrap lines moves it in or out of the
  /// horizontal scroll: its undo history and focus stay.
  final _fieldKey = GlobalKey();
  String _text = '';
  List<int> _starts = const [0];
  int _widest = 0;
  int _line = 0;

  /// Wrap: each line's top in the field, measured at [_wrapWidth] for
  /// [_wrapText] (null: not measured yet).
  List<double>? _tops;
  double _wrapHeight = 0;
  double? _wrapWidth;
  String? _wrapText;
  Timer? _measure;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    _read();
  }

  @override
  void didUpdateWidget(TextEditorWell old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
      _read();
    }
  }

  @override
  void dispose() {
    _measure?.cancel();
    widget.controller.removeListener(_changed);
    _v.dispose();
    _h.dispose();
    super.dispose();
  }

  void _read() {
    final v = widget.controller.value;
    if (v.text != _text) {
      _text = v.text;
      _starts = lineStarts(_text);
      _widest = widestLine(_text);
    }
    final at = v.selection.isValid ? v.selection.extentOffset : 0;
    _line = lineAt(_starts, at.clamp(0, _text.length));
  }

  void _changed() {
    final text = _text;
    final line = _line;
    _read();
    if (!identical(text, _text) || line != _line) setState(() {});
  }

  /// Wrap: line tops for [text] at [width], measured after a pause in
  /// typing (a 1 MB layout per key would stall the keyboard).
  void _scheduleWrap(String text, double width, TextStyle style) {
    if (_wrapText == text && _wrapWidth == width) return;
    _measure?.cancel();
    final scaler = MediaQuery.textScalerOf(context);
    _measure = Timer(
      _tops == null ? Duration.zero : const Duration(milliseconds: 150),
      () {
        if (!mounted) return;
        final tp = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
          strutStyle: StrutStyle.fromTextStyle(style, forceStrutHeight: true),
        )..layout(maxWidth: width);
        final starts = lineStarts(text);
        final tops = [
          for (final s in starts)
            tp.getOffsetForCaret(TextPosition(offset: s), Rect.zero).dy,
        ];
        final height = tp.height;
        tp.dispose();
        setState(() {
          _tops = tops;
          _wrapHeight = height;
          _wrapText = text;
          _wrapWidth = width;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final d = context.delve;
    final scaler = MediaQuery.textScalerOf(context);
    final style = DelveText.mono.copyWith(
      color: d.codeFg,
      height: FilesTokens.editorLineHeight,
    );
    final lh = scaler.scale(style.fontSize!) * FilesTokens.editorLineHeight;
    final advance = _advance(style, scaler);
    final digits = math.max(3, '${_starts.length}'.length);
    final gutterW = widget.lineNumbers
        ? math.max(
            scaler.scale(FilesTokens.previewGutter),
            digits * advance + FilesTokens.editorGutterPadding + 4,
          )
        : 0.0;
    return Container(
      key: const Key('editor.well'),
      margin: const EdgeInsets.fromLTRB(
        FilesTokens.editorWellInset,
        0,
        FilesTokens.editorWellInset,
        FilesTokens.editorWellInset,
      ),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(DelveTokens.rmd),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final areaW = math.max(0.0, box.maxWidth - 4 - gutterW);
          final textW = widget.wrap
              ? areaW
              : math.max(areaW, (_widest + 2) * advance);
          List<double>? tops;
          double height;
          if (widget.wrap) {
            _scheduleWrap(_text, textW, style);
            final fresh = _tops != null && _tops!.length == _starts.length;
            tops = fresh ? _tops : null;
            height = fresh ? _wrapHeight : _starts.length * lh;
          } else {
            height = _starts.length * lh;
          }
          double topOf(int i) => tops == null ? i * lh : tops[i];
          double bottomOf(int i) =>
              i + 1 < _starts.length ? topOf(i + 1) : height;
          final field = KeyedSubtree(
            key: _fieldKey,
            child: Theme(
              data: Theme.of(context).copyWith(
                textSelectionTheme: TextSelectionThemeData(
                  cursorColor: cs.primary,
                  selectionColor: delveTerminalTheme.selection,
                  selectionHandleColor: cs.primary,
                ),
              ),
              child: TextField(
                key: const Key('editor.field'),
                controller: widget.controller,
                focusNode: widget.focus,
                undoController: widget.undo,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                autocorrect: false,
                enableSuggestions: false,
                enableIMEPersonalizedLearning: false,
                smartDashesType: SmartDashesType.disabled,
                smartQuotesType: SmartQuotesType.disabled,
                style: style,
                strutStyle: StrutStyle.fromTextStyle(
                  style,
                  forceStrutHeight: true,
                ),
                cursorColor: cs.primary,
                cursorWidth: FilesTokens.editorCaret,
                scrollPadding: EdgeInsets.all(lh * 2),
                decoration: const InputDecoration.collapsed(hintText: null),
                onChanged: widget.onChanged,
              ),
            ),
          );
          final line = _line.clamp(0, _starts.length - 1);
          final content = Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: topOf(line),
                height: bottomOf(line) - topOf(line),
                child: ColoredBox(
                  key: const Key('editor.currentLine'),
                  color: cs.surfaceContainerLow,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.lineNumbers)
                    CustomPaint(
                      key: const Key('editor.gutter'),
                      size: Size(gutterW, height),
                      painter: _GutterPainter(
                        scroll: _v,
                        viewport: box.maxHeight,
                        lines: _starts.length,
                        current: line,
                        changed: widget.changed,
                        top: topOf,
                        lineHeight: lh,
                        number: style.copyWith(color: d.textMuted),
                        currentNumber: style.copyWith(color: cs.onSurface),
                        bar: cs.onSurfaceVariant,
                        scaler: scaler,
                      ),
                    ),
                  Expanded(
                    child: widget.wrap
                        ? field
                        : SingleChildScrollView(
                            key: const Key('editor.hscroll'),
                            controller: _h,
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(width: textW, child: field),
                          ),
                  ),
                ],
              ),
            ],
          );
          return Scrollbar(
            controller: _v,
            child: SingleChildScrollView(
              key: const Key('editor.scroll'),
              controller: _v,
              padding: const EdgeInsets.fromLTRB(4, 8, 0, 8),
              child: content,
            ),
          );
        },
      ),
    );
  }

  static double _advance(TextStyle style, TextScaler scaler) {
    final tp = TextPainter(
      text: TextSpan(text: 'MMMMMMMMMM', style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final w = tp.width / 10;
    tp.dispose();
    return w;
  }
}

/// The numbers of the lines in view (only those: a 20 000-line file has
/// 20 000 numbers), the current one brighter, and the changed-line bars at
/// the gutter's right edge.
class _GutterPainter extends CustomPainter {
  _GutterPainter({
    required this.scroll,
    required this.viewport,
    required this.lines,
    required this.current,
    required this.changed,
    required this.top,
    required this.lineHeight,
    required this.number,
    required this.currentNumber,
    required this.bar,
    required this.scaler,
  }) : super(repaint: scroll);

  final ScrollController scroll;
  final double viewport;
  final int lines;
  final int current;
  final Set<int> changed;
  final double Function(int) top;
  final double lineHeight;
  final TextStyle number;
  final TextStyle currentNumber;
  final Color bar;
  final TextScaler scaler;

  @override
  void paint(Canvas canvas, Size size) {
    final offset = scroll.hasClients ? scroll.offset : 0.0;
    final from = offset - 8 - lineHeight;
    final to = offset + viewport + lineHeight;
    final right = size.width - FilesTokens.editorGutterPadding;
    final barPaint = Paint()..color = bar;
    // the first line in view (tops grow with the index)
    var lo = 0;
    var hi = lines - 1;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (top(mid) + lineHeight < from) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    for (var i = lo; i < lines; i++) {
      final y = top(i);
      if (y > to) break;
      final tp = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: i == current ? currentNumber : number,
        ),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        strutStyle: StrutStyle.fromTextStyle(number, forceStrutHeight: true),
      )..layout();
      tp.paint(canvas, Offset(right - tp.width, y));
      tp.dispose();
      if (changed.contains(i)) {
        canvas.drawRect(
          Rect.fromLTWH(
            size.width - FilesTokens.editorChangedBar - 2,
            y + 2,
            FilesTokens.editorChangedBar,
            lineHeight - 4,
          ),
          barPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GutterPainter old) =>
      old.lines != lines ||
      old.current != current ||
      !identical(old.changed, changed) ||
      old.viewport != viewport ||
      old.lineHeight != lineHeight ||
      old.number != number ||
      old.top != top;
}

/// The keys the phone's keyboard lacks (23n): Tab, the arrows, Home, End,
/// Undo, Redo. Shown above the keyboard while it is open.
enum EditorKey { tab, left, down, up, right, home, end, undo, redo }

class EditorKeys extends StatelessWidget {
  const EditorKeys({
    super.key,
    required this.onKey,
    required this.canUndo,
    required this.canRedo,
  });

  final ValueChanged<EditorKey> onKey;
  final bool canUndo;
  final bool canRedo;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    Widget key(
      EditorKey k, {
      String? label,
      IconData? icon,
      required String semantics,
      bool enabled = true,
    }) => Expanded(
      child: Semantics(
        button: true,
        enabled: enabled,
        label: semantics,
        excludeSemantics: true,
        child: InkWell(
          key: Key('editor.key.${k.name}'),
          canRequestFocus: false,
          onTap: enabled
              ? () {
                  unawaited(HapticFeedback.selectionClick());
                  onKey(k);
                }
              : null,
          child: Center(
            child: label != null
                ? Text(
                    label,
                    style: DelveText.mono.copyWith(
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  )
                : SymbolIcon(
                    icon!,
                    size: k == EditorKey.undo || k == EditorKey.redo ? 20 : 18,
                    color: enabled ? cs.onSurface : context.delve.textDisabled,
                  ),
          ),
        ),
      ),
    );
    return Container(
      key: const Key('editor.keys'),
      height: FilesTokens.editorKeyRow,
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          key(EditorKey.tab, label: 'Tab', semantics: l.editorKeyTab),
          key(EditorKey.left, icon: FileIcons.left, semantics: l.editorKeyLeft),
          key(EditorKey.down, icon: FileIcons.down, semantics: l.editorKeyDown),
          key(EditorKey.up, icon: FileIcons.up, semantics: l.editorKeyUp),
          key(
            EditorKey.right,
            icon: FileIcons.right,
            semantics: l.editorKeyRight,
          ),
          key(EditorKey.home, label: 'Home', semantics: l.editorKeyHome),
          key(EditorKey.end, label: 'End', semantics: l.editorKeyEnd),
          key(
            EditorKey.undo,
            icon: FileIcons.undo,
            semantics: l.editorUndo,
            enabled: canUndo,
          ),
          key(
            EditorKey.redo,
            icon: FileIcons.redo,
            semantics: l.editorRedo,
            enabled: canRedo,
          ),
        ],
      ),
    );
  }
}

/// [k] on [c] (the undo and redo keys go to the field's history instead).
void applyEditorKey(TextEditingController c, EditorKey k) {
  final v = c.value;
  c.value = switch (k) {
    EditorKey.tab => insertTab(v),
    EditorKey.left => moveCaret(v, CaretMove.left),
    EditorKey.right => moveCaret(v, CaretMove.right),
    EditorKey.up => moveCaret(v, CaretMove.up),
    EditorKey.down => moveCaret(v, CaretMove.down),
    EditorKey.home => moveCaret(v, CaretMove.home),
    EditorKey.end => moveCaret(v, CaretMove.end),
    EditorKey.undo || EditorKey.redo => v,
  };
}
