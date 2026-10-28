import 'package:flutter/material.dart';

import '../../theme/delve_theme.dart';
import 'page_scaffolds.dart';

/// The four status families of the design (status is never colour alone:
/// every use pairs the colour with an icon and a word).
enum StatusKind { ok, warn, alert, info }

extension StatusColors on BuildContext {
  ({Color fg, Color bg, Color border}) status(StatusKind kind) {
    final d = delve;
    return switch (kind) {
      StatusKind.ok => (fg: d.okFg, bg: d.okBg, border: d.okBorder),
      StatusKind.warn => (fg: d.warnFg, bg: d.warnBg, border: d.warnBorder),
      StatusKind.alert => (fg: d.alertFg, bg: d.alertBg, border: d.alertBorder),
      StatusKind.info => (fg: d.infoFg, bg: d.infoBg, border: d.infoBorder),
    };
  }
}

/// Banner: radius 12, 1 dp status border on the status background, a filled
/// 20 dp icon in the status colour, body text, an optional small action.
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.kind,
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final StatusKind kind;
  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.status(kind);
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.bg,
          border: Border.all(color: c.border, width: DelveTokens.hairline),
          borderRadius: BorderRadius.circular(DelveTokens.rmd),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            DelveTokens.space4,
            DelveTokens.space3,
            actionLabel == null ? DelveTokens.space4 : DelveTokens.space2,
            DelveTokens.space3,
          ),
          child: Row(
            children: [
              SymbolIcon(
                icon,
                size: DelveTokens.iconMd,
                filled: true,
                color: c.fg,
              ),
              const SizedBox(width: DelveTokens.space3),
              Expanded(child: Text(text, style: context.text.bodyLarge)),
              if (actionLabel != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(foregroundColor: c.fg),
                  child: Text(actionLabel!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A status word in its status colour, without a chip: for rows whose value
/// is a state (system: Hermes, llama-server). Mono, like the values beside
/// it; still a word, so the state is never told by colour alone.
class StatusText extends StatelessWidget {
  const StatusText({
    super.key,
    required this.kind,
    required this.label,
    this.icon,
  });

  final StatusKind kind;
  final String label;

  /// Optional 16 dp filled icon in the same colour (design 21c markers).
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = context.status(kind).fg;
    final text = Text(
      label,
      softWrap: false,
      style: DelveText.mono.copyWith(color: fg, fontWeight: FontWeight.w500),
    );
    final i = icon;
    if (i == null) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SymbolIcon(i, size: DelveTokens.iconSm, filled: true, color: fg),
        const SizedBox(width: DelveTokens.space1),
        text,
      ],
    );
  }
}

/// Status chip: h 22, radius 6, status bg/fg/border, filled 15 dp icon + word.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.kind,
    required this.icon,
    required this.label,
  });

  final StatusKind kind;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.status(kind);
    return Container(
      constraints: const BoxConstraints(minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border.all(color: c.border, width: DelveTokens.hairline),
        borderRadius: BorderRadius.circular(DelveTokens.rxs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SymbolIcon(icon, size: 15, filled: true, color: c.fg),
          const SizedBox(width: DelveTokens.space1),
          Text(label, style: context.text.labelMedium!.copyWith(color: c.fg)),
        ],
      ),
    );
  }
}
