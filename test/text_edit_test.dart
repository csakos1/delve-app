import 'package:delve/files/text_edit.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

TextEditingValue at(String text, int offset) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: offset),
);

void main() {
  group('lines', () {
    test('starts, line at an offset, line and column', () {
      expect(lineStarts('ab\ncd\n'), [0, 3, 6]);
      expect(lineAt([0, 3, 6], 0), 0);
      expect(lineAt([0, 3, 6], 2), 0);
      expect(lineAt([0, 3, 6], 3), 1);
      expect(lineAt([0, 3, 6], 6), 2);
      expect(lineCol('ab\ncd\n', 4), (1, 1));
      expect(lineCol('ab', 99), (0, 2));
    });

    test('counted lines: a final newline starts none', () {
      expect(countedLines(''), 0);
      expect(countedLines('a'), 1);
      expect(countedLines('a\nb\n'), 2);
      expect(countedLines('a\nb'), 2);
      expect(countedLines('\n'), 1);
      expect(countedLines('a\n\n'), 2);
    });

    test('the widest line: tabs eight, wide characters two', () {
      expect(widestLine('ab\nabcd\n'), 4);
      expect(widestLine('\tx'), 9);
      expect(widestLine('日本'), 4);
      expect(widestLine(''), 0);
    });
  });

  group('diff', () {
    test('the same text: nothing changed', () {
      final d = diffLines('a\nb\n', 'a\nb\n');
      expect(d.changed, isEmpty);
      expect(d.count, 0);
    });

    test('one line changed, one added, one removed', () {
      var d = diffLines('a\nb\nc\n', 'a\nB\nc\n');
      expect(d.changed, {1});
      expect(d.count, 1);
      d = diffLines('a\nb\n', 'a\nnew\nb\n');
      expect(d.changed, {1});
      expect(d.count, 1);
      d = diffLines('a\nb\nc\n', 'a\nc\n');
      expect(d.changed, isEmpty);
      expect(d.count, 1);
    });

    test('lines moved in the middle are matched', () {
      final d = diffLines('a\nx\ny\nz\nb', 'a\ny\nz\nq\nb');
      expect(d.changed, {3});
      expect(d.count, 1);
    });

    test('a middle too large: all of it changed', () {
      final before = List.generate(1200, (i) => 'a$i').join('\n');
      final after = List.generate(1200, (i) => 'b$i').join('\n');
      final d = diffLines(before, after);
      expect(d.changed.length, 1200);
      expect(d.count, 1200);
    });
  });

  group('the key row', () {
    test('Tab: four spaces over the selection', () {
      expect(insertTab(at('ab', 1)).text, 'a    b');
      expect(insertTab(at('ab', 1)).selection.baseOffset, 5);
      final sel = insertTab(
        const TextEditingValue(
          text: 'abcd',
          selection: TextSelection(baseOffset: 1, extentOffset: 3),
        ),
      );
      expect(sel.text, 'a    d');
    });

    test('arrows, Home, End; up and down keep the column', () {
      const text = 'abcdef\nxy\nlonger line';
      expect(moveCaret(at(text, 2), CaretMove.left).selection.baseOffset, 1);
      expect(moveCaret(at(text, 0), CaretMove.left).selection.baseOffset, 0);
      expect(moveCaret(at(text, 2), CaretMove.right).selection.baseOffset, 3);
      // line 0 col 5 → line 1 is shorter: its end (offset 9)
      expect(moveCaret(at(text, 5), CaretMove.down).selection.baseOffset, 9);
      // line 1 col 1 → line 2 col 1
      expect(moveCaret(at(text, 8), CaretMove.down).selection.baseOffset, 11);
      expect(moveCaret(at(text, 8), CaretMove.up).selection.baseOffset, 1);
      expect(moveCaret(at(text, 1), CaretMove.up).selection.baseOffset, 0);
      expect(
        moveCaret(at(text, 12), CaretMove.down).selection.baseOffset,
        text.length,
      );
      expect(moveCaret(at(text, 8), CaretMove.home).selection.baseOffset, 7);
      expect(moveCaret(at(text, 8), CaretMove.end).selection.baseOffset, 9);
    });

    test('a selection collapses; a surrogate pair is one step', () {
      const sel = TextEditingValue(
        text: 'abcd',
        selection: TextSelection(baseOffset: 3, extentOffset: 1),
      );
      expect(moveCaret(sel, CaretMove.left).selection.baseOffset, 1);
      expect(moveCaret(sel, CaretMove.right).selection.baseOffset, 3);
      const emoji = 'a😀b';
      expect(moveCaret(at(emoji, 1), CaretMove.right).selection.baseOffset, 3);
      expect(moveCaret(at(emoji, 3), CaretMove.left).selection.baseOffset, 1);
    });
  });
}
