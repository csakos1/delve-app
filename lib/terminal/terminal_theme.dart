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

/// Line height of terminal rows (13 sp → 15.6 dp rows).
const kTerminalLineHeight = 1.2;

/// Terminal text: JetBrains Mono at [fontSize] sp.
TerminalStyle delveTerminalStyle(double fontSize) => TerminalStyle(
  fontSize: fontSize,
  height: kTerminalLineHeight,
  fontFamily: DelveFonts.mono,
  fontFamilyFallback: const ['monospace'],
);
