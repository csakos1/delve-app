import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';

/// A popover under [anchor] (design 27 “Layers”): `surface-3`, radius 12,
/// elevation-2, no scrim; Esc or a click outside closes it. [size] is its
/// box; it keeps 8 px from the anchor and stays inside the window. Returns
/// what the content pops with.
Future<T?> showDesktopPopover<T>(
  BuildContext anchor, {
  required Size size,
  required WidgetBuilder builder,
}) {
  final box = anchor.findRenderObject()! as RenderBox;
  final at = box.localToGlobal(Offset.zero) & box.size;
  final l = AppLocalizations.of(anchor);
  return showGeneralDialog<T>(
    context: anchor,
    barrierDismissible: true,
    barrierLabel: l.close,
    barrierColor: Colors.transparent,
    transitionDuration: DelveDesktop.hover,
    pageBuilder: (context, _, _) {
      final window = MediaQuery.sizeOf(context);
      const gap = 8.0;
      const edge = 8.0;
      // under the anchor, its right edges aligned; inside the window
      final left = math.max(
        edge,
        math.min(at.right - size.width, window.width - size.width - edge),
      );
      final below = at.bottom + gap;
      final top = below + size.height <= window.height - edge
          ? below
          : math.max(edge, at.top - gap - size.height);
      final height = math.min(size.height, window.height - top - edge);
      return Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            width: size.width,
            height: height,
            child: Material(
              key: const Key('desktop.popover'),
              color: context.colors.surfaceContainerHigh,
              elevation: 2,
              shadowColor: Colors.black,
              borderRadius: BorderRadius.circular(DelveDesktop.popoverRadius),
              clipBehavior: Clip.antiAlias,
              child: LayerMark(child: Builder(builder: builder)),
            ),
          ),
        ],
      );
    },
    transitionBuilder: (context, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

/// The desktop's confirmation dialog (27W-14h): centred, 460 wide,
/// `surface-3`, radius 16, padding 20, on the 64 % scrim; Cancel and the
/// action right-aligned, the action focused (Enter); [destructive] makes it
/// the alert filled button – the only place it exists. True: confirmed.
Future<bool> showDesktopConfirm(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
  bool destructive = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.64),
    builder: (context) {
      final l = AppLocalizations.of(context);
      final cs = context.colors;
      final d = context.delve;
      return Dialog(
        key: const Key('desktop.confirm'),
        backgroundColor: cs.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DelveDesktop.dialogRadius),
        ),
        child: SizedBox(
          width: DelveDesktop.dialogWidth,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: context.text.titleMedium),
                const SizedBox(height: DelveTokens.space2),
                Text(
                  body,
                  style: context.text.bodyMedium!.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      key: const Key('desktop.confirm.cancel'),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(l.cancel),
                    ),
                    const SizedBox(width: DelveTokens.space2),
                    FilledButton(
                      key: const Key('desktop.confirm.ok'),
                      autofocus: true,
                      style: destructive
                          ? FilledButton.styleFrom(
                              backgroundColor: d.alertFg,
                              foregroundColor: cs.surface,
                            )
                          : null,
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(action),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  return ok ?? false;
}

/// A dialog with content of its own (27 “Layers”: dialog) – what is a
/// bottom sheet on the phone and has no control to hang under (a file's
/// details, a preview): centred, [width] wide, `surface-3`, radius 16, on
/// the 64 % scrim; Esc or a click outside closes it. Returns what the
/// content pops with.
Future<T?> showDesktopDialog<T>(
  BuildContext context, {
  double width = DelveDesktop.dialogWidth,
  required WidgetBuilder builder,
}) => showDialog<T>(
  context: context,
  barrierColor: Colors.black.withValues(alpha: 0.64),
  builder: (context) => Dialog(
    key: const Key('desktop.dialog'),
    backgroundColor: context.colors.surfaceContainerHigh,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(DelveDesktop.dialogRadius),
    ),
    clipBehavior: Clip.antiAlias,
    child: SizedBox(
      width: width,
      // the focus comes in, so Esc closes it whatever it holds
      child: Focus(autofocus: true, child: Builder(builder: builder)),
    ),
  ),
);

/// A layer drawn over the shell that leaves the focus where it was (a
/// context menu, a popover): while one is on screen the shell's pane keys –
/// Esc, Enter, F6, Shift+F10 – stand back, and Esc is the layer's (L2d2).
/// Counted while mounted, so a layer gone with its tree is gone here too.
class LayerMark extends StatefulWidget {
  const LayerMark({super.key, required this.child});

  final Widget child;

  /// Marked layers on screen.
  static int open = 0;

  @override
  State<LayerMark> createState() => _LayerMarkState();
}

class _LayerMarkState extends State<LayerMark> {
  @override
  void initState() {
    super.initState();
    LayerMark.open++;
  }

  @override
  void dispose() {
    LayerMark.open--;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
