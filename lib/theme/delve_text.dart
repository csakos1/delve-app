import 'package:flutter/material.dart';

/// Font family names as declared in `pubspec.yaml`.
abstract final class DelveFonts {
  static const String display = 'Jost';
  static const String text = 'Inter';
  static const String mono = 'JetBrainsMono';

  /// Jost has no Greek (Σ); every Jost style falls back to Inter.
  static const List<String> displayFallback = <String>[text];
}

TextStyle _jost(double size, double height, FontWeight weight, double ls) =>
    TextStyle(
      fontFamily: DelveFonts.display,
      fontFamilyFallback: DelveFonts.displayFallback,
      fontSize: size,
      height: height,
      fontWeight: weight,
      letterSpacing: ls,
    );

TextStyle _inter(double size, double height, FontWeight weight, double ls) =>
    TextStyle(
      fontFamily: DelveFonts.text,
      fontSize: size,
      height: height,
      fontWeight: weight,
      letterSpacing: ls,
    );

/// Material text roles (sizes in sp, height = line / size).
final TextTheme delveTextTheme = TextTheme(
  displaySmall: _jost(40, 44 / 40, FontWeight.w300, 0),
  headlineMedium: _jost(28, 36 / 28, FontWeight.w400, 0),
  headlineSmall: _jost(24, 32 / 24, FontWeight.w400, 0),
  titleLarge: _jost(20, 26 / 20, FontWeight.w500, 0),
  titleMedium: _jost(17, 24 / 17, FontWeight.w500, 0.1),
  titleSmall: _inter(14, 20 / 14, FontWeight.w600, 0.1),
  bodyLarge: _inter(15, 22 / 15, FontWeight.w400, 0),
  bodyMedium: _inter(14, 20 / 14, FontWeight.w400, 0),
  bodySmall: _inter(12, 17 / 12, FontWeight.w400, 0.1),
  labelLarge: _inter(14, 20 / 14, FontWeight.w600, 0.1),
  labelMedium: _inter(12, 16 / 12, FontWeight.w500, 0.2),
  labelSmall: _inter(11, 14 / 11, FontWeight.w500, 0.3),
);

/// Monospace roles with no [TextTheme] slot: "monospace means machine".
abstract final class DelveText {
  /// Commands, paths, IDs, code blocks.
  static const TextStyle mono = TextStyle(
    fontFamily: DelveFonts.mono,
    fontSize: 13,
    height: 19 / 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  /// Usage line (Σ …), token counts, log output, durations.
  static const TextStyle monoSmall = TextStyle(
    fontFamily: DelveFonts.mono,
    fontSize: 11.5,
    height: 16 / 11.5,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
}
