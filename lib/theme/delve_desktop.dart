import 'package:flutter/material.dart';

import 'delve_colors.dart';
import 'delve_text.dart';
import 'delve_tokens.dart';

/// Window classes of the desktop layout (design 27 Workbench). One rule
/// makes them: the content pane is never narrower than
/// [DelveDesktop.contentMin]; the list gives up width first, then the
/// inspector becomes an overlay, then the list too.
enum DelveWindowClass {
  /// Below 720: the phone layout.
  phone,

  /// 720 – 899: list and inspector are overlays.
  compact,

  /// 900 – 1231: the inspector is an overlay.
  medium,

  /// 1232 – 1339: the list narrows while the inspector is open.
  half,

  /// 1340 – 1919.
  regular,

  /// 1920 and wider.
  wide,
}

/// Desktop layout constants (dp at text scale 1.0). Source: the design
/// system's `delve_tokens.json → desktop` (round 11b, "27 Desktop –
/// Workbench"); `test/desktop_test.dart` checks them against
/// `test/fixtures/design/delve_desktop_tokens.json`. Nothing here changes a
/// phone value.
abstract final class DelveDesktop {
  static const double windowMinWidth = 720;
  static const double windowMinHeight = 560;

  // breakpoints (window width)
  static const double listOverlayBelow = 900;
  static const double inspectorOverlayBelow = 1232;
  static const double listNarrowBelow = 1340;
  static const double dashboardOneColumnBelow = 820;
  static const double dashboardTwoColumnsBelow = 1100;
  static const double statusBarDropRunBelow = 1100;
  static const double wide = 1920;

  // panes
  static const double railWidth = 52;
  static const double listMin = 240;
  static const double listDefault = 300;
  static const double listDefaultNews = 360;
  static const double listDefaultWide = 340;
  static const double listMax = 420;
  static const double contentMin = 600;
  static const double readingColumn = 720;
  static const double readingColumnWide = 760;
  static const double detailColumn = 680;
  static const double inspectorMin = 300;
  static const double inspectorDefault = 340;
  static const double inspectorMax = 480;
  static const double paneHeader = 48;

  /// The Dashboard's page header (title 24 / 30 and the date).
  static const double pageHeader = 66;
  static const double contentGutter = 20;
  static const double dashboardMaxWidth = 1840;
  static const double dashboardGap = 16;
  static const double statusBarHeight = 24;
  static const double dividerGrab = 6;
  static const double dividerLine = 2;
  static const Duration dividerHoverDelay = Duration(milliseconds: 150);

  // status bar
  static const double statusBarPadding = 12;
  static const double statusBarGap = 14;
  static const double statusBarDot = 7;
  static const double statusBarIcon = 13;

  // rail
  static const double railItemWidth = 40;
  static const double railItemHeight = 34;
  static const double railItemRadius = 10;
  static const double railIcon = 20;
  static const double railItemGap = 2;
  static const double railDividerWidth = 24;
  static const double railDividerMargin = 6;
  static const double railMarkSlot = 34;
  static const double railMark = 20;

  /// The mark's air (L2b2: the 34 slot sat it against the window's top and
  /// the first item) and its optical nudge to the right.
  static const double railMarkTop = 14;
  static const double railMarkBottom = 12;
  static const double railMarkNudge = 1.5;
  static const double railDot = 8;

  // density
  static const double rowTwoLine = 52;
  static const double rowOneLine = 32;
  static const double rowRadius = 8;
  static const double buttonHeight = 32;
  static const double buttonRadius = 8;
  static const double iconButton = 28;
  static const double iconButtonRadius = 6;
  static const double iconButtonIcon = 18;
  static const double cardRadius = 14;
  static const double menuRadius = 10;
  static const double dialogRadius = 16;
  static const double dialogWidth = 460;
  static const double popoverRadius = 12;

  /// The General model picker as a popover (27W-14f).
  static const double modelPickerWidth = 380;
  static const double modelPickerHeight = 520;

  /// The General effort popover (L2d3): its title block and its rows.
  static const double effortWidth = 280;
  static const double effortHead = 70;
  static const double effortRow = 36;

  /// A text preview in a dialog (About me: what a chat starts with).
  static const double previewDialogWidth = 680;

  /// The schedule editor's chat picker, a popover on its button.
  static const double chatPickerWidth = 360;
  static const double chatPickerHeight = 420;
  static const double keyCapHeight = 18;
  static const double keyCapRadius = 4;
  static const double tooltipRadius = 6;

  /// The rail's tooltip: 8 px to the right of the rail.
  static const double railTooltipGap = 8;

  // the command palette (Ctrl+K, 27W-14a / 14b)
  static const double paletteWidth = 660;
  static const double paletteTop = 84;
  static const double paletteRadius = 16;
  static const double paletteField = 52;
  static const double paletteRow = 38;
  static const double paletteEyebrow = 26;
  static const double paletteFoot = 36;

  /// Recent chats in the empty palette.
  static const int paletteRecent = 5;

  // the shortcut sheet (?, 27W-14c)
  static const double shortcutSheetWidth = 940;
  static const double shortcutRow = 28;

  /// The local models picker as a popover (System, Dashboard, status bar).
  static const double localModelsWidth = 400;
  static const double localModelsHeight = 520;

  // the Dashboard's “Needs approval” card (`approvalsCard`)
  static const double approvalsHeader = 28;
  static const double approvalsRowPadding = 12;
  static const double approvalsColumnGap = 20;
  static const double approvalsRight = 372;
  static const double approvalsRightCompact = 300;
  static const int approvalsMaxRows = 3;
  static const double approvalsShowAll = 36;
  static const double approvalsWellRadius = 8;

  /// Below this card width the row is one column (as on the phone).
  static const double approvalsTwoColumnsFrom = 640;
  static const Duration outcomeHold = Duration(milliseconds: 1500);
  static const Duration rowCollapse = Duration(milliseconds: 250);
  static const double buttonSmall = 28;

  // composer (Components “Density”)
  static const double composerRadius = 20;
  static const double composerAdd = 32;
  static const double composerSend = 34;
  static const double thinkingPill = 28;
  static const double composerBottom = 14;

  // the dock panel (Components “Panes”, “Dock panel”, 27W-2i)
  static const double dockMin = 160;
  static const double dockDefault = 262;

  /// The dock's highest, a share of the content pane's height.
  static const double dockMaxShare = 0.6;
  static const double dockTabRow = 34;
  static const double dockHandleWidth = 36;
  static const double dockHandleHeight = 4;
  static const double dockIcon = 16;

  /// JetBrains Mono 12.5 / 16 in the dock (13 / 17 in the Terminal area).
  static const double dockFontSize = 12.5;
  static const EdgeInsets dockPadding = EdgeInsets.symmetric(
    vertical: 6,
    horizontal: 10,
  );

  // Files (Components “Areas”, 27W-13)
  static const double filesRow = 32;
  static const double filesHeaderRow = 30;
  static const double filesSizeColumn = 104;
  static const double filesDateColumn = 132;
  static const double filesFoot = 28;
  static const double filesTransfersMax = 240;
  static const double filesPasteBarMax = 560;
  static const double trashFolderColumn = 220;

  /// The inspector's preview waits this long after a selection (J / K
  /// through a folder does not fetch every file).
  static const Duration filesPreviewDelay = Duration(milliseconds: 180);

  // motion
  static const Duration hover = Duration(milliseconds: 100);
  static const Duration tooltipDelay = Duration(milliseconds: 500);

  static DelveWindowClass classOf(double width) {
    if (width < windowMinWidth) return DelveWindowClass.phone;
    if (width < listOverlayBelow) return DelveWindowClass.compact;
    if (width < inspectorOverlayBelow) return DelveWindowClass.medium;
    if (width < listNarrowBelow) return DelveWindowClass.half;
    if (width < wide) return DelveWindowClass.regular;
    return DelveWindowClass.wide;
  }

  /// The width of a docked list column: the remembered one; while an
  /// inspector is docked below [listNarrowBelow] the minimum (half of a
  /// 2560 monitor: 52 + 240 + 638 + 340), and wider no more than leaves the
  /// content its [contentMin].
  static double listWidth(
    double window, {
    required double remembered,
    required bool inspectorDocked,
    double inspector = inspectorDefault,
  }) {
    if (!inspectorDocked) return remembered;
    if (window < listNarrowBelow) return listMin;
    final room = window - railWidth - inspector - contentMin;
    return room.clamp(listMin, remembered).toDouble();
  }

  /// Hover: one surface step up from the surface the element sits on.
  static Color hoverOn(ColorScheme cs, Color surface) {
    final steps = <Color>[
      cs.surface,
      cs.surfaceContainerLow,
      cs.surfaceContainer,
      cs.surfaceContainerHigh,
      cs.surfaceContainerHighest,
    ];
    final i = steps.indexOf(surface);
    return i < 0 || i == steps.length - 1 ? steps.last : steps[i + 1];
  }
}

/// Desktop-only text styles. The phone [TextTheme] is untouched: message
/// text, [DelveText.mono] and [DelveText.monoSmall] are used as they are.
abstract final class DelveDesktopText {
  static const TextStyle paneTitle = TextStyle(
    fontFamily: DelveFonts.display,
    fontFamilyFallback: DelveFonts.displayFallback,
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );
  static const TextStyle rowTitle = TextStyle(
    fontFamily: DelveFonts.text,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );
  static const TextStyle rowSecondary = TextStyle(
    fontFamily: DelveFonts.text,
    fontSize: 12.5,
    height: 17 / 12.5,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
  static const TextStyle meta = TextStyle(
    fontFamily: DelveFonts.text,
    fontSize: 11.5,
    height: 16 / 11.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );
  static const TextStyle control = TextStyle(
    fontFamily: DelveFonts.text,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  /// The Dashboard's title (Jost 24 / 30).
  static const TextStyle pageTitle = TextStyle(
    fontFamily: DelveFonts.display,
    fontFamilyFallback: DelveFonts.displayFallback,
    fontSize: 24,
    height: 30 / 24,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle keyCap = TextStyle(
    fontFamily: DelveFonts.mono,
    fontSize: 10.5,
    height: 16 / 10.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );
}

/// [base] (the phone theme) with desktop control sizes: colours, text roles
/// and extensions stay; heights, radii and paddings of controls change, hover
/// is a surface step, there is no ripple and scrollbars always show.
ThemeData delveDesktopTheme(ThemeData base) {
  final cs = base.colorScheme;
  final dc = base.extension<DelveColors>()!;
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(DelveDesktop.buttonRadius),
  );
  const size = Size(48, DelveDesktop.buttonHeight);
  const pad = EdgeInsets.symmetric(horizontal: 12);
  final r8 = BorderRadius.circular(DelveDesktop.buttonRadius);
  return base.copyWith(
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.compact,
    splashFactory: NoSplash.splashFactory,
    filledButtonTheme: FilledButtonThemeData(
      style: base.filledButtonTheme.style!.copyWith(
        minimumSize: const WidgetStatePropertyAll<Size>(size),
        padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(pad),
        shape: WidgetStatePropertyAll<OutlinedBorder>(shape),
        textStyle: const WidgetStatePropertyAll<TextStyle>(
          DelveDesktopText.control,
        ),
        overlayColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.pressed)
              ? Colors.black.withValues(alpha: 0.12)
              : s.contains(WidgetState.hovered)
              ? Colors.white.withValues(alpha: DelveTokens.stateHover)
              : null,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: base.outlinedButtonTheme.style!.copyWith(
        minimumSize: const WidgetStatePropertyAll<Size>(size),
        padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(pad),
        shape: WidgetStatePropertyAll<OutlinedBorder>(shape),
        textStyle: const WidgetStatePropertyAll<TextStyle>(
          DelveDesktopText.control,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: base.textButtonTheme.style!.copyWith(
        minimumSize: const WidgetStatePropertyAll<Size>(
          Size(32, DelveDesktop.buttonHeight),
        ),
        padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
          EdgeInsets.symmetric(horizontal: 8),
        ),
        shape: WidgetStatePropertyAll<OutlinedBorder>(shape),
        textStyle: const WidgetStatePropertyAll<TextStyle>(
          DelveDesktopText.control,
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size.square(DelveDesktop.iconButton),
        padding: EdgeInsets.zero,
        iconSize: DelveDesktop.iconButtonIcon,
        foregroundColor: cs.onSurfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DelveDesktop.iconButtonRadius),
        ),
      ),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      border: OutlineInputBorder(
        borderRadius: r8,
        borderSide: BorderSide(color: cs.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: r8,
        borderSide: BorderSide(color: cs.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: r8,
        borderSide: BorderSide(color: cs.primary, width: DelveTokens.focusRing),
      ),
    ),
    cardTheme: base.cardTheme.copyWith(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DelveDesktop.cardRadius),
      ),
    ),
    dialogTheme: base.dialogTheme.copyWith(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DelveDesktop.dialogRadius),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: cs.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      elevation: DelveTokens.materialElevation2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DelveDesktop.menuRadius),
      ),
      textStyle: base.textTheme.bodyMedium!.copyWith(fontSize: 13),
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: DelveDesktop.tooltipDelay,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(DelveDesktop.tooltipRadius),
        boxShadow: DelveTokens.elevation2,
      ),
      textStyle: base.textTheme.labelMedium!.copyWith(color: cs.onSurface),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbVisibility: const WidgetStatePropertyAll<bool>(true),
      thickness: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.hovered) ? 8 : 6,
      ),
      radius: const Radius.circular(3),
      crossAxisMargin: 3,
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.hovered)
            ? cs.outline
            : cs.surfaceContainerHighest,
      ),
    ),
    listTileTheme: base.listTileTheme.copyWith(
      dense: true,
      minVerticalPadding: 4,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
    ),
    snackBarTheme: base.snackBarTheme.copyWith(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DelveDesktop.menuRadius),
      ),
    ),
    extensions: <ThemeExtension<dynamic>>[dc],
  );
}
