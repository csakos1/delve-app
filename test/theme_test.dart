import 'dart:convert';
import 'dart:io';

import 'package:delve/theme/delve_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The theme must match the design tokens exported from the design system
/// (test/fixtures/design/delve_tokens.json — refresh it from the design
/// artifact when the design changes).
void main() {
  final tokens =
      jsonDecode(
            File('test/fixtures/design/delve_tokens.json').readAsStringSync(),
          )
          as Map<String, Object?>;
  Map<String, Object?> obj(Object? v) => v! as Map<String, Object?>;
  final color = obj(tokens['color']);

  int argb(String v) =>
      v == 'transparent' ? 0x00000000 : int.parse(v.substring(2), radix: 16);

  test('ColorScheme roles match the design', () {
    const cs = delveColorScheme;
    final roles = <String, Object>{
      'brightness': cs.brightness,
      'primary': cs.primary,
      'onPrimary': cs.onPrimary,
      'primaryContainer': cs.primaryContainer,
      'onPrimaryContainer': cs.onPrimaryContainer,
      'secondary': cs.secondary,
      'onSecondary': cs.onSecondary,
      'secondaryContainer': cs.secondaryContainer,
      'onSecondaryContainer': cs.onSecondaryContainer,
      'tertiary': cs.tertiary,
      'onTertiary': cs.onTertiary,
      'tertiaryContainer': cs.tertiaryContainer,
      'onTertiaryContainer': cs.onTertiaryContainer,
      'error': cs.error,
      'onError': cs.onError,
      'errorContainer': cs.errorContainer,
      'onErrorContainer': cs.onErrorContainer,
      'surface': cs.surface,
      'onSurface': cs.onSurface,
      'onSurfaceVariant': cs.onSurfaceVariant,
      'surfaceDim': cs.surfaceDim,
      'surfaceBright': cs.surfaceBright,
      'surfaceContainerLowest': cs.surfaceContainerLowest,
      'surfaceContainerLow': cs.surfaceContainerLow,
      'surfaceContainer': cs.surfaceContainer,
      'surfaceContainerHigh': cs.surfaceContainerHigh,
      'surfaceContainerHighest': cs.surfaceContainerHighest,
      'outline': cs.outline,
      'outlineVariant': cs.outlineVariant,
      'shadow': cs.shadow,
      'scrim': cs.scrim,
      'inverseSurface': cs.inverseSurface,
      'onInverseSurface': cs.onInverseSurface,
      'inversePrimary': cs.inversePrimary,
      'surfaceTint': cs.surfaceTint,
    };
    final design = obj(color['flutterColorScheme']);
    expect(roles.keys.toSet(), design.keys.toSet());
    for (final e in design.entries) {
      if (e.key == 'brightness') {
        expect(cs.brightness, Brightness.dark);
        continue;
      }
      expect(
        (roles[e.key]! as Color).toARGB32(),
        argb(e.value! as String),
        reason: e.key,
      );
    }
  });

  test('DelveColors match the design', () {
    final design = obj(color['flutterDelveColorsExtension']);
    final ours = DelveColors.dark.toMap();
    expect(ours.keys.toList(), design.keys.toList());
    for (final e in design.entries) {
      expect(ours[e.key]!.toARGB32(), argb(e.value! as String), reason: e.key);
    }
  });

  test('text roles match the design', () {
    final typo = obj(tokens['typography']);
    final families = obj(typo['flutterFamilyNames']);
    final tt = delveTextTheme;
    final roles = <String, TextStyle?>{
      'displaySmall': tt.displaySmall,
      'headlineMedium': tt.headlineMedium,
      'headlineSmall': tt.headlineSmall,
      'titleLarge': tt.titleLarge,
      'titleMedium': tt.titleMedium,
      'titleSmall': tt.titleSmall,
      'bodyLarge': tt.bodyLarge,
      'bodyMedium': tt.bodyMedium,
      'bodySmall': tt.bodySmall,
      'labelLarge': tt.labelLarge,
      'labelMedium': tt.labelMedium,
      'labelSmall': tt.labelSmall,
      'mono': DelveText.mono,
      'monoSmall': DelveText.monoSmall,
    };
    final styles = (typo['styles']! as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(styles.map((s) => s['role']).toSet(), roles.keys.toSet());
    for (final s in styles) {
      final role = s['role']! as String;
      final style = roles[role]!;
      final size = (s['sizeSp']! as num).toDouble();
      final line = (s['lineHeight']! as num).toDouble();
      expect(style.fontFamily, families[s['family']], reason: role);
      expect(style.fontSize, size, reason: role);
      expect(style.height! * size, closeTo(line, 0.01), reason: role);
      expect(
        style.fontWeight,
        FontWeight.values[(s['weight']! as int) ~/ 100 - 1],
        reason: role,
      );
      expect(
        style.letterSpacing,
        (s['letterSpacing']! as num).toDouble(),
        reason: role,
      );
      if (style.fontFamily == DelveFonts.display) {
        expect(style.fontFamilyFallback, [DelveFonts.text], reason: role);
      }
    }
  });

  test('spacing, radius, sizes and motion match the design', () {
    final spacing = obj(tokens['spacing']);
    expect(spacing, {
      'space-1': DelveTokens.space1,
      'space-2': DelveTokens.space2,
      'space-3': DelveTokens.space3,
      'space-4': DelveTokens.space4,
      'space-5': DelveTokens.space5,
      'space-6': DelveTokens.space6,
      'space-8': DelveTokens.space8,
    });
    final radius = obj(tokens['radius']);
    expect(radius['radius-xs'], DelveTokens.rxs);
    expect(radius['radius-sm'], DelveTokens.rsm);
    expect(radius['radius-md'], DelveTokens.rmd);
    expect(radius['radius-lg'], DelveTokens.rlg);
    expect(radius['radius-xl'], DelveTokens.rxl);
    expect(obj(tokens['sizes']), {
      'touch-target': DelveTokens.touchTarget,
      'top-bar': DelveTokens.topBar,
      'usage-line': DelveTokens.usageLine,
      'bottom-nav': DelveTokens.bottomNav,
      'list-row': DelveTokens.listRow,
      'composer-min': DelveTokens.composerMin,
      'button': DelveTokens.button,
      'chip': DelveTokens.chip,
      'send-button': DelveTokens.sendButton,
    });
    final motion = {
      for (final m
          in (tokens['motion']! as List<Object?>).cast<Map<String, Object?>>())
        m['name']: m['ms'],
    };
    expect(motion, {
      'motion-fast': DelveTokens.fast.inMilliseconds,
      'motion-short': DelveTokens.short.inMilliseconds,
      'motion-medium': DelveTokens.medium.inMilliseconds,
      'motion-long': DelveTokens.long.inMilliseconds,
      'motion-caption': DelveTokens.caption.inMilliseconds,
      'motion-progress': DelveTokens.progress.inMilliseconds,
    });
  });

  test('no glow: shadows are neutral black, surface tint is off', () {
    for (final s in [...DelveTokens.elevation1, ...DelveTokens.elevation2]) {
      expect(s.color.toARGB32() & 0x00FFFFFF, 0, reason: 'coloured shadow');
      expect(s.spreadRadius, 0);
    }
    expect(DelveTokens.elevation1.length, 1);
    expect(DelveTokens.elevation2.length, 1);
    final theme = buildDelveTheme();
    expect(theme.colorScheme.surfaceTint.toARGB32(), 0);
    expect(theme.appBarTheme.surfaceTintColor?.toARGB32(), 0);
    expect(theme.extension<DelveColors>(), isNotNull);
    expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
  });
}
