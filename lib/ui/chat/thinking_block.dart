import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../format.dart';
import '../widgets/page_scaffolds.dart';
import 'tool_step_card.dart' show formatDuration;

/// The thinking block of a Thinking run (05, 06).
///
/// Live: "Thinking… m:ss · N tok" with a 2 dp progress line (no glow).
/// Done: a 28 dp "Thought for 23 s" row that opens the reasoning (12 lines,
/// then "Show all"). The reasoning arrives after the run (`reasoning.final`);
/// until then the row does not open.
class ThinkingBlock extends StatefulWidget {
  const ThinkingBlock({
    super.key,
    required this.live,
    this.since,
    this.tokens = 0,
    this.seconds,
    this.reasoning,
  });

  /// The model is thinking right now.
  final bool live;

  /// Live: when the run started (the clock counts from here).
  final DateTime? since;

  /// Live: tokens the run added so far (0: not shown).
  final int tokens;

  /// Done: how long it thought, if known.
  final double? seconds;

  /// Done: the reasoning text, if it arrived.
  final String? reasoning;

  /// Lines shown before "Show all".
  static const int previewLines = 12;

  @override
  State<ThinkingBlock> createState() => _ThinkingBlockState();
}

class _ThinkingBlockState extends State<ThinkingBlock> {
  Timer? _tick;
  bool _open = false;
  bool _all = false;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(ThinkingBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.live != widget.live) _syncTimer();
  }

  void _syncTimer() {
    _tick?.cancel();
    _tick = widget.live
        ? Timer.periodic(const Duration(seconds: 1), (_) {
            if (mounted) setState(() {});
          })
        : null;
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.live ? _buildLive(context) : _buildDone(context);

  Widget _buildLive(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final since = widget.since;
    final elapsed = since == null
        ? Duration.zero
        : DateTime.now().difference(since);
    final meta = [
      countdownText(elapsed),
      if (widget.tokens > 0) l.thinkingTokens(tokenCount(widget.tokens)),
    ].join(' · ');
    return Column(
      key: const Key('thinking.live'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SymbolIcon(
              DelveIcons.thinking,
              size: DelveTokens.iconSm,
              filled: true,
              color: cs.primary,
            ),
            const SizedBox(width: 6),
            Text(
              l.thinkingNow,
              style: context.text.labelMedium!.copyWith(color: cs.primary),
            ),
            const SizedBox(width: DelveTokens.space2),
            Flexible(
              child: Text(
                meta,
                key: const Key('thinking.meta'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DelveText.monoSmall.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
        const SizedBox(height: DelveTokens.space2),
        const LinearProgressIndicator(),
      ],
    );
  }

  Widget _buildDone(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final d = context.delve;
    final seconds = widget.seconds;
    final label = seconds == null
        ? l.thinkingThought
        : l.thinkingThoughtFor(formatDuration(seconds));
    final reasoning = widget.reasoning?.trim();
    final canOpen = reasoning != null && reasoning.isNotEmpty;

    final header = InkWell(
      key: const Key('thinking.toggle'),
      onTap: canOpen
          ? () => setState(() {
              _open = !_open;
              if (!_open) _all = false;
            })
          : null,
      borderRadius: BorderRadius.circular(DelveTokens.rxs),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 28),
        child: Row(
          children: [
            SymbolIcon(
              DelveIcons.thinking,
              size: DelveTokens.iconSm,
              color: d.textMuted,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                key: const Key('thinking.label'),
                style: context.text.labelMedium!.copyWith(color: d.textMuted),
              ),
            ),
            if (canOpen) ...[
              const SizedBox(width: DelveTokens.space1),
              SymbolIcon(
                _open ? DelveIcons.expandLess : DelveIcons.expandMore,
                size: 18,
                color: d.textMuted,
              ),
            ],
          ],
        ),
      ),
    );

    final Widget child;
    if (!_open || !canOpen) {
      child = Align(alignment: Alignment.centerLeft, child: header);
    } else {
      final lines = '\n'.allMatches(reasoning).length + 1;
      final maxLines = _all ? null : ThinkingBlock.previewLines;
      child = Container(
        padding: const EdgeInsets.fromLTRB(
          DelveTokens.space3,
          DelveTokens.space1,
          DelveTokens.space1,
          DelveTokens.space2 + 2,
        ),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          border: Border.all(
            color: cs.outlineVariant,
            width: DelveTokens.hairline,
          ),
          borderRadius: BorderRadius.circular(DelveTokens.rmd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            Padding(
              padding: const EdgeInsets.only(right: DelveTokens.space2),
              child: Text(
                reasoning,
                key: const Key('thinking.body'),
                maxLines: maxLines,
                overflow: maxLines == null ? null : TextOverflow.ellipsis,
                style: context.text.bodySmall!.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            if (!_all && lines > ThinkingBlock.previewLines)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _all = true),
                  child: Text(l.thinkingShowAll),
                ),
              ),
          ],
        ),
      );
    }
    return AnimatedSize(
      duration: DelveTokens.medium,
      curve: DelveTokens.standard,
      alignment: Alignment.topCenter,
      child: child,
    );
  }
}
