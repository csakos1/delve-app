import 'package:flutter/material.dart';

/// Material colour roles of the dark (and only) theme.
const ColorScheme delveColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF5FD4EA),
  onPrimary: Color(0xFF062A32),
  primaryContainer: Color(0xFF163A42),
  onPrimaryContainer: Color(0xFFBDEEF8),
  secondary: Color(0xFFADB1B6),
  onSecondary: Color(0xFF1A1B1D),
  secondaryContainer: Color(0xFF323438),
  onSecondaryContainer: Color(0xFFECEEF0),
  tertiary: Color(0xFFECB553),
  onTertiary: Color(0xFF2A1D04),
  tertiaryContainer: Color(0xFF2E2614),
  onTertiaryContainer: Color(0xFFF7D79A),
  error: Color(0xFFF2736C),
  onError: Color(0xFF3A0B09),
  errorContainer: Color(0xFF33201F),
  onErrorContainer: Color(0xFFFFD9D6),
  surface: Color(0xFF111213),
  onSurface: Color(0xFFECEEF0),
  onSurfaceVariant: Color(0xFFADB1B6),
  surfaceDim: Color(0xFF111213),
  surfaceBright: Color(0xFF323438),
  surfaceContainerLowest: Color(0xFF0C0D0E),
  surfaceContainerLow: Color(0xFF18191B),
  surfaceContainer: Color(0xFF202124),
  surfaceContainerHigh: Color(0xFF28292D),
  surfaceContainerHighest: Color(0xFF323438),
  outline: Color(0xFF7A7D83),
  outlineVariant: Color(0xFF34363A),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFFECEEF0),
  onInverseSurface: Color(0xFF1D1E20),
  inversePrimary: Color(0xFF006879),
  surfaceTint: Colors.transparent,
);

/// Status, code and extra text colours that have no [ColorScheme] role.
@immutable
class DelveColors extends ThemeExtension<DelveColors> {
  const DelveColors({
    required this.textMuted,
    required this.textDisabled,
    required this.okFg,
    required this.okBg,
    required this.okBorder,
    required this.warnFg,
    required this.warnBg,
    required this.warnBorder,
    required this.alertFg,
    required this.alertBg,
    required this.alertBorder,
    required this.infoFg,
    required this.infoBg,
    required this.infoBorder,
    required this.codeBg,
    required this.codeFg,
    required this.codeComment,
    required this.codeKeyword,
    required this.codeString,
    required this.codeNumber,
    required this.scrim,
  });

  static const DelveColors dark = DelveColors(
    textMuted: Color(0xFF9A9EA4),
    textDisabled: Color(0xFF5C5F65),
    okFg: Color(0xFF72D28F),
    okBg: Color(0xFF1B2A20),
    okBorder: Color(0xFF2F5A3C),
    warnFg: Color(0xFFECB553),
    warnBg: Color(0xFF2E2614),
    warnBorder: Color(0xFF6B5221),
    alertFg: Color(0xFFF2736C),
    alertBg: Color(0xFF33201F),
    alertBorder: Color(0xFF6E322F),
    infoFg: Color(0xFFB0B4B9),
    infoBg: Color(0xFF25272A),
    infoBorder: Color(0xFF45484D),
    codeBg: Color(0xFF18191B),
    codeFg: Color(0xFFD9DCE0),
    codeComment: Color(0xFF9A9EA4),
    codeKeyword: Color(0xFF7FD8EC),
    codeString: Color(0xFFA8D38A),
    codeNumber: Color(0xFFE9B872),
    scrim: Color(0xA3000000),
  );

  final Color textMuted;
  final Color textDisabled;
  final Color okFg;
  final Color okBg;
  final Color okBorder;
  final Color warnFg;
  final Color warnBg;
  final Color warnBorder;
  final Color alertFg;
  final Color alertBg;
  final Color alertBorder;
  final Color infoFg;
  final Color infoBg;
  final Color infoBorder;
  final Color codeBg;
  final Color codeFg;
  final Color codeComment;
  final Color codeKeyword;
  final Color codeString;
  final Color codeNumber;
  final Color scrim;

  /// Name → colour, in the key order of the design tokens file.
  Map<String, Color> toMap() => <String, Color>{
    'textMuted': textMuted,
    'textDisabled': textDisabled,
    'okFg': okFg,
    'okBg': okBg,
    'okBorder': okBorder,
    'warnFg': warnFg,
    'warnBg': warnBg,
    'warnBorder': warnBorder,
    'alertFg': alertFg,
    'alertBg': alertBg,
    'alertBorder': alertBorder,
    'infoFg': infoFg,
    'infoBg': infoBg,
    'infoBorder': infoBorder,
    'codeBg': codeBg,
    'codeFg': codeFg,
    'codeComment': codeComment,
    'codeKeyword': codeKeyword,
    'codeString': codeString,
    'codeNumber': codeNumber,
    'scrim': scrim,
  };

  @override
  DelveColors copyWith({
    Color? textMuted,
    Color? textDisabled,
    Color? okFg,
    Color? okBg,
    Color? okBorder,
    Color? warnFg,
    Color? warnBg,
    Color? warnBorder,
    Color? alertFg,
    Color? alertBg,
    Color? alertBorder,
    Color? infoFg,
    Color? infoBg,
    Color? infoBorder,
    Color? codeBg,
    Color? codeFg,
    Color? codeComment,
    Color? codeKeyword,
    Color? codeString,
    Color? codeNumber,
    Color? scrim,
  }) => DelveColors(
    textMuted: textMuted ?? this.textMuted,
    textDisabled: textDisabled ?? this.textDisabled,
    okFg: okFg ?? this.okFg,
    okBg: okBg ?? this.okBg,
    okBorder: okBorder ?? this.okBorder,
    warnFg: warnFg ?? this.warnFg,
    warnBg: warnBg ?? this.warnBg,
    warnBorder: warnBorder ?? this.warnBorder,
    alertFg: alertFg ?? this.alertFg,
    alertBg: alertBg ?? this.alertBg,
    alertBorder: alertBorder ?? this.alertBorder,
    infoFg: infoFg ?? this.infoFg,
    infoBg: infoBg ?? this.infoBg,
    infoBorder: infoBorder ?? this.infoBorder,
    codeBg: codeBg ?? this.codeBg,
    codeFg: codeFg ?? this.codeFg,
    codeComment: codeComment ?? this.codeComment,
    codeKeyword: codeKeyword ?? this.codeKeyword,
    codeString: codeString ?? this.codeString,
    codeNumber: codeNumber ?? this.codeNumber,
    scrim: scrim ?? this.scrim,
  );

  @override
  DelveColors lerp(ThemeExtension<DelveColors>? other, double t) {
    if (other is! DelveColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return DelveColors(
      textMuted: l(textMuted, other.textMuted),
      textDisabled: l(textDisabled, other.textDisabled),
      okFg: l(okFg, other.okFg),
      okBg: l(okBg, other.okBg),
      okBorder: l(okBorder, other.okBorder),
      warnFg: l(warnFg, other.warnFg),
      warnBg: l(warnBg, other.warnBg),
      warnBorder: l(warnBorder, other.warnBorder),
      alertFg: l(alertFg, other.alertFg),
      alertBg: l(alertBg, other.alertBg),
      alertBorder: l(alertBorder, other.alertBorder),
      infoFg: l(infoFg, other.infoFg),
      infoBg: l(infoBg, other.infoBg),
      infoBorder: l(infoBorder, other.infoBorder),
      codeBg: l(codeBg, other.codeBg),
      codeFg: l(codeFg, other.codeFg),
      codeComment: l(codeComment, other.codeComment),
      codeKeyword: l(codeKeyword, other.codeKeyword),
      codeString: l(codeString, other.codeString),
      codeNumber: l(codeNumber, other.codeNumber),
      scrim: l(scrim, other.scrim),
    );
  }
}
