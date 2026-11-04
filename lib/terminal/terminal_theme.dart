import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:xterm/xterm.dart';

import '../theme/delve_text.dart';

/// Design 22 · `delve_tokens.json` → `terminal.flutterTerminalTheme`.
/// Background is the recess (surface-lowest); the cursor is the only accent.
/// The selection is translucent because xterm 4.0.0 paints it over the
/// glyphs.
const delveTerminalTheme = TerminalTheme(
  background: Color(0xFF0C0D0E),
  foreground: Color(0xFFD9DCE0),
  cursor: Color(0xFF5FD4EA),
  selection: Color(0x405FD4EA),
  black: Color(0xFF28292D),
  red: Color(0xFFEA6E66),
  green: Color(0xFF67C483),
  yellow: Color(0xFFE0AB4C),
  blue: Color(0xFF7AA2E3),
  magenta: Color(0xFFC28BD8),
  cyan: Color(0xFF4FBDD2),
  white: Color(0xFFADB1B6),
  brightBlack: Color(0xFF7F838A),
  brightRed: Color(0xFFF5958E),
  brightGreen: Color(0xFF98DEAB),
  brightYellow: Color(0xFFE9DC94),
  brightBlue: Color(0xFFA9C4F2),
  brightMagenta: Color(0xFFDDB6EC),
  brightCyan: Color(0xFF8FE1F0),
  brightWhite: Color(0xFFECEEF0),
  searchHitBackground: Color(0xFFA9853F),
  searchHitBackgroundCurrent: Color(0xFFECB553),
  searchHitForeground: Color(0xFF0C0D0E),
);

/// What the terminal view gets: [delveTerminalTheme] without its own
/// selection colour. The selection is drawn reversed – each cell in its
/// text colour, the text in the cell's background – over the view (T2b, as
/// in Termux and Linux terminals), so xterm paints none.
final delveTerminalViewTheme = TerminalTheme(
  background: delveTerminalTheme.background,
  foreground: delveTerminalTheme.foreground,
  // the cursor too is drawn over the view, centred on the text
  // ([terminalCursorHeight])
  cursor: const Color(0x00000000),
  selection: const Color(0x00000000),
  black: delveTerminalTheme.black,
  red: delveTerminalTheme.red,
  green: delveTerminalTheme.green,
  yellow: delveTerminalTheme.yellow,
  blue: delveTerminalTheme.blue,
  magenta: delveTerminalTheme.magenta,
  cyan: delveTerminalTheme.cyan,
  white: delveTerminalTheme.white,
  brightBlack: delveTerminalTheme.brightBlack,
  brightRed: delveTerminalTheme.brightRed,
  brightGreen: delveTerminalTheme.brightGreen,
  brightYellow: delveTerminalTheme.brightYellow,
  brightBlue: delveTerminalTheme.brightBlue,
  brightMagenta: delveTerminalTheme.brightMagenta,
  brightCyan: delveTerminalTheme.brightCyan,
  brightWhite: delveTerminalTheme.brightWhite,
  searchHitBackground: delveTerminalTheme.searchHitBackground,
  searchHitBackgroundCurrent: delveTerminalTheme.searchHitBackgroundCurrent,
  searchHitForeground: delveTerminalTheme.searchHitForeground,
);

/// The 256 colours of a cell's palette index, as xterm 4.0.0 resolves them
/// (its PaletteBuilder, index 15 included, which it maps to white).
List<Color> terminalPalette(TerminalTheme t) {
  final named = [
    t.black,
    t.red,
    t.green,
    t.yellow,
    t.blue,
    t.magenta,
    t.cyan,
    t.white,
    t.brightBlack,
    t.brightRed,
    t.brightGreen,
    t.brightYellow,
    t.brightBlue,
    t.brightMagenta,
    t.brightCyan,
    t.white,
  ];
  const steps = [0, 95, 135, 175, 215, 255];
  return List<Color>.generate(256, (i) {
    if (i < 16) return named[i];
    if (i < 232) {
      final n = i - 16;
      return Color.fromARGB(
        0xFF,
        steps[n ~/ 36],
        steps[n ~/ 6 % 6],
        steps[n % 6],
      );
    }
    final v = 8 + (i - 232) * 10;
    return Color.fromARGB(0xFF, v, v, v);
  }, growable: false);
}

/// The colour a cell colour (xterm's encoding) shows in: [fallback] for the
/// default colour.
Color terminalColor(int cell, List<Color> palette, Color fallback) {
  switch (cell & CellColor.typeMask) {
    case CellColor.normal:
      return fallback;
    case CellColor.named:
    case CellColor.palette:
      return palette[cell & CellColor.valueMask];
    default:
      return Color((cell & CellColor.valueMask) | 0xFF000000);
  }
}

/// Line height of terminal rows (13 sp → 15.6 dp rows).
const kTerminalLineHeight = 1.2;

/// JetBrains Mono's capital height, a fraction of the font size (its
/// `OS/2` table: 730 of 1000 units).
const kTerminalCapHeight = 0.73;

/// The block cursor's height: from the top of the cell down to as far below
/// the middle of the capitals as the cell's top is above it.
///
/// xterm fills the whole cell, and the line height's extra room falls mostly
/// below the text, so its cursor reached further down than up – it looked
/// low beside the text and touched the row under it (T2b phone test).
/// [baseline] is the text's baseline from the cell's top, [fontSize] in the
/// same units.
double terminalCursorHeight({
  required double lineHeight,
  required double baseline,
  required double fontSize,
}) {
  final middle = baseline - kTerminalCapHeight * fontSize / 2;
  if (middle <= 0) return lineHeight;
  return math.min(lineHeight, 2 * middle);
}

/// Terminal text: JetBrains Mono at [fontSize] sp.
TerminalStyle delveTerminalStyle(double fontSize) => TerminalStyle(
  fontSize: fontSize,
  height: kTerminalLineHeight,
  fontFamily: DelveFonts.mono,
  fontFamilyFallback: const ['monospace'],
);
