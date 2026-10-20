import 'package:flutter/material.dart';

import 'delve_colors.dart';
import 'delve_text.dart';
import 'delve_tokens.dart';

export 'delve_colors.dart';
export 'delve_text.dart';
export 'delve_tokens.dart';

extension DelveThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  DelveColors get delve => Theme.of(this).extension<DelveColors>()!;
}

/// Direction C "Depth", without glow: depth is lightness (five surface levels),
/// one accent at a time, neutral shadows only on floating layers.
ThemeData buildDelveTheme() {
  const cs = delveColorScheme;
  const dc = DelveColors.dark;
  final text = delveTextTheme.apply(
    bodyColor: cs.onSurface,
    displayColor: cs.onSurface,
  );
  final r12 = BorderRadius.circular(DelveTokens.rmd);
  final buttonShape = RoundedRectangleBorder(borderRadius: r12);
  const buttonSize = Size(64, DelveTokens.button);
  const buttonPadding = EdgeInsets.symmetric(horizontal: DelveTokens.space5);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: cs,
    textTheme: text,
    fontFamily: DelveFonts.text,
    scaffoldBackgroundColor: cs.surface,
    canvasColor: cs.surface,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    splashFactory: InkRipple.splashFactory, // no sparkle
    extensions: const <ThemeExtension<dynamic>>[dc],
    iconTheme: IconThemeData(color: cs.onSurface, size: DelveTokens.iconLg),
    dividerTheme: DividerThemeData(
      color: cs.outlineVariant,
      thickness: DelveTokens.hairline,
      space: DelveTokens.hairline,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: cs.surfaceContainer,
      foregroundColor: cs.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: text.titleLarge,
      toolbarHeight: DelveTokens.topBar,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: DelveTokens.bottomNav,
      backgroundColor: cs.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: cs.primaryContainer,
      indicatorShape: const StadiumBorder(),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          size: DelveTokens.iconLg,
          color: s.contains(WidgetState.selected)
              ? cs.primary
              : cs.onSurfaceVariant,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => text.labelMedium!.copyWith(
          color: s.contains(WidgetState.selected)
              ? cs.onSurface
              : cs.onSurfaceVariant,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        disabledBackgroundColor: cs.onSurface.withValues(
          alpha: DelveTokens.disabledContainer,
        ),
        disabledForegroundColor: dc.textDisabled,
        minimumSize: buttonSize,
        padding: buttonPadding,
        shape: buttonShape,
        textStyle: text.labelLarge,
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: cs.onSurface,
        side: BorderSide(color: cs.outline),
        minimumSize: buttonSize,
        padding: buttonPadding,
        shape: buttonShape,
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: cs.primary,
        minimumSize: const Size(
          DelveTokens.touchTarget,
          DelveTokens.touchTarget,
        ),
        padding: const EdgeInsets.symmetric(horizontal: DelveTokens.space3),
        shape: buttonShape,
        textStyle: text.labelLarge,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      elevation: DelveTokens.materialElevation1,
      focusElevation: DelveTokens.materialElevation1,
      hoverElevation: DelveTokens.materialElevation1,
      highlightElevation: DelveTokens.materialElevation1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DelveTokens.rlg),
      ),
      extendedTextStyle: text.labelLarge,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: cs.surfaceContainerHighest,
      selectedColor: cs.primaryContainer,
      labelStyle: text.labelMedium,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 10),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? cs.onPrimary : cs.outline,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? cs.primary
            : cs.surfaceContainerHighest,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) =>
            s.contains(WidgetState.selected) ? Colors.transparent : cs.outline,
      ),
      trackOutlineWidth: const WidgetStatePropertyAll<double>(2),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: r12,
        borderSide: BorderSide(color: cs.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: r12,
        borderSide: BorderSide(color: cs.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: r12,
        borderSide: BorderSide(color: cs.primary, width: DelveTokens.focusRing),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: r12,
        borderSide: BorderSide(color: cs.error, width: DelveTokens.focusRing),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: r12,
        borderSide: BorderSide(color: cs.error, width: DelveTokens.focusRing),
      ),
      labelStyle: text.labelMedium!.copyWith(color: cs.onSurfaceVariant),
      floatingLabelStyle: text.labelMedium!.copyWith(color: cs.primary),
      hintStyle: text.bodyLarge!.copyWith(color: dc.textMuted),
      helperStyle: text.bodySmall!.copyWith(color: dc.textMuted),
      errorStyle: text.bodySmall!.copyWith(color: cs.error),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: cs.primary,
      linearTrackColor: cs.surfaceContainerHighest,
      linearMinHeight: 2,
      circularTrackColor: cs.surfaceContainerHighest,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: cs.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: cs.surfaceContainerHigh,
      modalBarrierColor: dc.scrim,
      elevation: 0, // sits on the scrim
      modalElevation: 0,
      showDragHandle: true,
      dragHandleColor: cs.outline,
      dragHandleSize: const Size(32, 4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DelveTokens.rxl),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: cs.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DelveTokens.rxl),
      ),
      titleTextStyle: text.titleLarge,
      contentTextStyle: text.bodyMedium!.copyWith(color: cs.onSurfaceVariant),
      barrierColor: dc.scrim,
    ),
    cardTheme: CardThemeData(
      color: cs.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DelveTokens.rlg),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: cs.surfaceContainerHighest,
      contentTextStyle: text.bodyMedium!.copyWith(color: cs.onSurface),
      actionTextColor: cs.primary,
      behavior: SnackBarBehavior.floating,
      elevation: DelveTokens.materialElevation2,
      shape: RoundedRectangleBorder(borderRadius: r12),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: cs.onSurfaceVariant,
      titleTextStyle: text.bodyLarge,
      subtitleTextStyle: text.bodyMedium!.copyWith(color: cs.onSurfaceVariant),
      minVerticalPadding: DelveTokens.space2,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: DelveTokens.space4,
      ),
    ),
  );
}
