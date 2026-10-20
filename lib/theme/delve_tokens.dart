import 'package:flutter/widgets.dart';

/// Spacing, radius, size, motion and elevation tokens (dp / ms).
///
/// Source: the Delve design system (Direction C "Depth", no glow),
/// `test/fixtures/design/delve_tokens.json`. `test/theme_test.dart` checks
/// these values against that file.
abstract final class DelveTokens {
  // spacing
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;

  // radius
  static const double rxs = 6;
  static const double rsm = 8;
  static const double rmd = 12;
  static const double rlg = 16;
  static const double rxl = 24;

  // borders
  static const double hairline = 1;
  static const double focusRing = 2;
  static const double railWidth = 2;

  // sizes
  static const double touchTarget = 48;
  static const double topBar = 56;
  static const double usageLine = 28;
  static const double bottomNav = 72;
  static const double listRow = 76;
  static const double composerMin = 98;
  static const double button = 48;
  static const double chip = 32;
  static const double sendButton = 44;

  // icons
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;

  // motion
  static const Duration fast = Duration(milliseconds: 100);
  static const Duration short = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration long = Duration(milliseconds: 350);
  static const Duration caption = Duration(milliseconds: 2000);
  static const Duration progress = Duration(milliseconds: 1800);
  static const Curve fastCurve = Curves.easeOut;
  static const Curve shortCurve = Curves.easeOutCubic;
  static const Curve standard = Curves.easeInOutCubic;
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;

  // state-layer opacities
  static const double stateHover = 0.08;
  static const double stateFocus = 0.10;
  static const double statePressed = 0.10;
  static const double stateDragged = 0.16;
  static const double disabledContainer = 0.12;
  static const double disabledContent = 0.38;

  /// Floating composer, extended FAB, swipe-revealed row.
  static const List<BoxShadow> elevation1 = <BoxShadow>[
    BoxShadow(color: Color(0x59000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  /// Bottom sheet, dialog, menu, snackbar.
  static const List<BoxShadow> elevation2 = <BoxShadow>[
    BoxShadow(color: Color(0x73000000), blurRadius: 24, offset: Offset(0, 8)),
  ];

  /// Material `elevation` equivalents (surface tint is off).
  static const double materialElevation1 = 3;
  static const double materialElevation2 = 6;
}
