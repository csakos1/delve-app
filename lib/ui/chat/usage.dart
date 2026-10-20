import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/models/models.dart';
import '../../api/rest_client.dart';
import '../../app/session.dart';
import '../../data/db/database.dart';
import '../../l10n/app_localizations.dart';
import '../../sync/live_runs.dart';
import '../../theme/delve_theme.dart';
import '../format.dart';
import '../widgets/page_scaffolds.dart';
import 'tool_step_card.dart' show formatDuration;

/// The context fill above which the context chip turns warn (as the backend's
/// `warn`).
const double contextWarnPct = 75;

/// Prefill speed is only meaningful for prompts at least this long
/// (decision 160: fixed overhead dominates small prefills).
const int prefillMinTokens = 500;

/// Usage of one conversation (Usage sheet): the newest 200 runs.
final conversationUsageProvider = FutureProvider.autoDispose
    .family<ConversationUsage, String>((ref, id) async {
      final api = ref.watch(apiProvider);
      if (api == null) throw StateError('not paired');
      return api.usage(id, limit: 200);
    });

/// What the context chip shows: the stored conversation's context, or the
/// live run's latest sample while it runs (the totals stay for the sheet).
class UsageNumbers {
  const UsageNumbers({required this.total, this.tokens, this.max, this.pct});

  factory UsageNumbers.of(ConversationRow c, LiveContext? live) {
    if (live != null && live.tokens != null) {
      return UsageNumbers(
        total: c.tokensTotal,
        tokens: live.tokens,
        max: live.max ?? c.contextMax,
        pct: live.pct,
      );
    }
    return UsageNumbers(
      total: c.tokensTotal,
      tokens: c.contextTokens,
      max: c.contextMax,
      pct: c.contextPct,
    );
  }

  final int total;
  final int? tokens;
  final int? max;
  final double? pct;

  bool get warn => (pct ?? 0) >= contextWarnPct;
}

/// The context chip in the chat top bar (option B): an 18 dp ring and the
/// percent on surface-3; above 75 % a warning icon on warn colours; a dashed
/// ring and "—" before anything was measured. Opens the Usage sheet; the
/// token totals live there.
class ContextChip extends StatelessWidget {
  const ContextChip({super.key, required this.numbers, required this.onTap});

  final UsageNumbers numbers;
  final VoidCallback onTap;

  static const double ringSize = 18;
  static const double ringStroke = 2.5;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final d = context.delve;
    final pct = numbers.pct;
    final empty = pct == null;
    final fill = pct ?? 0;
    final percent = fill.round();
    final warn = numbers.warn;

    final Color fg;
    final Color bg;
    final BorderSide side;
    final Widget lead;
    if (empty) {
      fg = d.textMuted;
      bg = cs.surfaceContainerHigh;
      side = BorderSide.none;
      lead = CustomPaint(
        key: const Key('contextChip.empty'),
        size: const Size.square(ringSize),
        painter: _DashedRing(color: cs.outline, stroke: ringStroke),
      );
    } else if (warn) {
      fg = d.warnFg;
      bg = d.warnBg;
      side = BorderSide(color: d.warnBorder);
      lead = SymbolIcon(
        DelveIcons.warning,
        key: const Key('contextChip.warn'),
        size: DelveTokens.iconSm,
        filled: true,
        color: d.warnFg,
      );
    } else {
      fg = cs.onSurfaceVariant;
      bg = cs.surfaceContainerHigh;
      side = BorderSide.none;
      lead = TweenAnimationBuilder<double>(
        tween: Tween(end: (fill / 100).clamp(0.0, 1.0)),
        duration: DelveTokens.medium,
        curve: Curves.linear,
        builder: (context, value, _) => SizedBox.square(
          dimension: ringSize,
          child: CircularProgressIndicator(
            value: value,
            strokeWidth: ringStroke,
            color: cs.onSurfaceVariant,
            backgroundColor: cs.surfaceContainerHighest,
          ),
        ),
      );
    }
    final label = empty ? l.usageNoContext : '$percent%';
    final semantics = empty
        ? l.contextChipEmpty
        : warn
        ? l.contextChipWarn(percent)
        : l.contextChipSemantics(percent);

    return Semantics(
      button: true,
      label: semantics,
      excludeSemantics: true,
      child: GestureDetector(
        // the 48 dp tall hit box around the 32 dp chip
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: DelveTokens.touchTarget,
          child: Center(
            child: Material(
              color: bg,
              shape: StadiumBorder(side: side),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: const Key('chat.contextChip'),
                onTap: onTap,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 64),
                  child: SizedBox(
                    height: 32,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          lead,
                          const SizedBox(width: 6),
                          Text(
                            label,
                            key: const Key('contextChip.label'),
                            style: context.text.labelMedium!.copyWith(
                              color: fg,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The empty ring: a dashed outline circle.
class _DashedRing extends CustomPainter {
  const _DashedRing({required this.color, required this.stroke});

  final Color color;
  final double stroke;

  static const int dashes = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    const sweep = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect, i * sweep, sweep * 0.55, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedRing old) =>
      old.color != color || old.stroke != stroke;
}

/// Context fill bar: track surface-4, fill accent (warn above 75 %), a
/// 1 × 6 dp outline tick at 75 %.
class ContextBar extends StatelessWidget {
  const ContextBar({super.key, required this.pct, required this.height});

  final double? pct;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final d = context.delve;
    final value = ((pct ?? 0) / 100).clamp(0.0, 1.0);
    final warn = (pct ?? 0) >= contextWarnPct;
    return SizedBox(
      height: 6 > height ? 6 : height,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: height,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
              Container(
                key: const Key('contextBar.fill'),
                width: w * value,
                height: height,
                decoration: BoxDecoration(
                  color: warn ? d.warnFg : cs.primary,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
              Positioned(
                left: w * contextWarnPct / 100,
                top: 0,
                bottom: 0,
                child: Container(width: 1, color: cs.outline),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Opens the Usage sheet (10) of [conversationId].
Future<void> showUsageSheet(
  BuildContext context, {
  required String conversationId,
  required String title,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => UsageSheet(conversationId: conversationId, title: title),
);

/// 10 Usage: totals (input, output, cache read, total), the context fill
/// and the runs newest first with prefill, generation and first-token time.
class UsageSheet extends ConsumerWidget {
  const UsageSheet({
    super.key,
    required this.conversationId,
    required this.title,
  });

  final String conversationId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final usage = ref.watch(conversationUsageProvider(conversationId));
    final data = usage.value;

    final children = <Widget>[
      Row(
        children: [
          Expanded(
            child: Text(l.usageTitle, style: context.text.headlineSmall),
          ),
          IconButton(
            key: const Key('usage.close'),
            tooltip: l.close,
            onPressed: () => Navigator.of(context).pop(),
            icon: const SymbolIcon(DelveIcons.close),
          ),
        ],
      ),
      Text(
        data == null ? title : '$title · ${l.usageRunCount(data.runs.length)}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: context.text.bodyMedium!.copyWith(color: cs.onSurfaceVariant),
      ),
      const SizedBox(height: DelveTokens.space4),
    ];

    if (data == null) {
      if (usage.hasError) {
        children.add(
          Row(
            key: const Key('usage.error'),
            children: [
              Expanded(
                child: Text(
                  l.usageLoadFailed(apiErrorText(l, usage.error!)),
                  style: context.text.bodyMedium,
                ),
              ),
              TextButton(
                onPressed: () =>
                    ref.invalidate(conversationUsageProvider(conversationId)),
                child: Text(l.runRetry),
              ),
            ],
          ),
        );
      } else {
        children.add(const LinearProgressIndicator());
      }
    } else {
      children.addAll(_content(context, l, data));
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: ListView(
        key: const Key('usage.sheet'),
        shrinkWrap: true,
        padding: EdgeInsets.fromLTRB(
          DelveTokens.space6,
          0,
          DelveTokens.space6,
          DelveTokens.space6 + MediaQuery.paddingOf(context).bottom,
        ),
        children: children,
      ),
    );
  }

  List<Widget> _content(
    BuildContext context,
    AppLocalizations l,
    ConversationUsage data,
  ) {
    final cs = context.colors;
    final d = context.delve;
    final t = data.totals;
    final c = data.context;
    // newest first; the run number counts from the oldest
    final runs = [
      for (final (i, r) in data.runs.indexed) (n: i + 1, run: r),
    ].reversed.toList();
    return [
      Row(
        children: [
          Expanded(
            child: _Tile(label: l.usageInput, value: t.inputTokens),
          ),
          const SizedBox(width: DelveTokens.space3),
          Expanded(
            child: _Tile(label: l.usageOutput, value: t.outputTokens),
          ),
        ],
      ),
      const SizedBox(height: DelveTokens.space3),
      Row(
        children: [
          Expanded(
            child: _Tile(label: l.usageCacheRead, value: t.cacheReadTokens),
          ),
          const SizedBox(width: DelveTokens.space3),
          Expanded(
            child: _Tile(label: l.usageTotal, value: t.totalTokens),
          ),
        ],
      ),
      const SizedBox(height: DelveTokens.space6),
      Row(
        children: [
          Expanded(child: Text(l.usageContext, style: context.text.titleSmall)),
          Text(
            contextText(c.tokens, c.max, c.pct) ?? l.usageNoContext,
            key: const Key('usage.context'),
            style: DelveText.monoSmall.copyWith(
              color: c.warn ? d.warnFg : cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
      const SizedBox(height: DelveTokens.space3),
      ContextBar(pct: c.pct, height: 6),
      const SizedBox(height: DelveTokens.space1),
      Row(
        children: [
          Text('0', style: DelveText.monoSmall.copyWith(color: d.textMuted)),
          const Spacer(),
          Text(
            l.usageWarnMark,
            style: context.text.labelSmall!.copyWith(color: d.textMuted),
          ),
          const Spacer(),
          Text(
            c.max == null ? '' : tokenCount(c.max!),
            style: DelveText.monoSmall.copyWith(color: d.textMuted),
          ),
        ],
      ),
      const SizedBox(height: DelveTokens.space6),
      Row(
        children: [
          Expanded(child: Text(l.usageRuns, style: context.text.titleSmall)),
          Text(
            l.usageNewestFirst,
            style: context.text.labelMedium!.copyWith(color: d.textMuted),
          ),
        ],
      ),
      const SizedBox(height: DelveTokens.space2),
      const Divider(height: 1),
      if (runs.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: DelveTokens.space4),
          child: Text(
            l.usageNoRuns,
            style: context.text.bodyMedium!.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      for (final r in runs) ...[
        RunUsageRow(number: r.n, run: r.run),
        const Divider(height: 1),
      ],
      const SizedBox(height: DelveTokens.space4),
      Text(
        l.usagePrefillNote,
        style: context.text.bodySmall!.copyWith(color: d.textMuted),
      ),
    ];
  }
}

/// A total in a surface-4 tile: label over the number.
class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DelveTokens.space4,
        vertical: DelveTokens.space3,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(DelveTokens.rmd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.text.labelMedium!.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DelveTokens.space1),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              tokenCount(value),
              style: DelveText.mono.copyWith(fontSize: 22, height: 1.2),
            ),
          ),
        ],
      ),
    );
  }
}

/// The three speeds of a run, as the sheet writes them ("—" when unknown).
({String prefill, String generation, String firstToken}) runSpeeds(Run run) {
  final p = run.perf ?? const <String, Object?>{};
  final prompt = p['prompt_tokens'];
  final prefill = p['prefill_tps'];
  final gen = p['gen_tps'];
  final first = p['first_delta_s'];
  const none = '—';
  return (
    prefill: prompt is num && prompt >= prefillMinTokens && prefill is num
        ? '${prefill.round()} tok/s'
        : none,
    generation: gen is num ? '${gen.toStringAsFixed(1)} tok/s' : none,
    firstToken: first is num ? formatDuration(first.toDouble()) : none,
  );
}

/// One run in the sheet: time, "Run N" (with its state when not completed),
/// input and output tokens; then prefill, generation and first token.
class RunUsageRow extends StatelessWidget {
  const RunUsageRow({super.key, required this.number, required this.run});

  final int number;
  final Run run;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final d = context.delve;
    final open = openRunStatuses.contains(run.status);
    final state = switch (run.status) {
      'completed' => null,
      'failed' => l.usageRunFailed,
      'cancelled' => l.usageRunStopped,
      'queued' => l.usageRunQueued,
      _ => l.usageRunRunning,
    };
    final u = run.usage ?? const <String, Object?>{};
    final input = u['input_tokens'];
    final output = u['output_tokens'];
    final io = [
      if (input is num) l.usageIn(tokenCount(input)),
      if (output is num) l.usageOut(tokenCount(output)),
    ].join(' · ');
    final speeds = runSpeeds(run);
    final at = run.startedAt ?? run.queuedAt;

    Widget metric(String label, String value) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.text.labelSmall!.copyWith(color: d.textMuted),
        ),
        Text(value, style: DelveText.monoSmall.copyWith(color: cs.onSurface)),
      ],
    );

    return Padding(
      key: ValueKey('usage.run.${run.runId}'),
      padding: const EdgeInsets.symmetric(vertical: DelveTokens.space3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              clockTime(at, DateTime.now()),
              style: DelveText.monoSmall.copyWith(color: d.textMuted),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: DelveTokens.space2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (open) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          state == null
                              ? l.usageRun(number)
                              : l.usageRunState(number, state),
                          style: context.text.titleSmall,
                        ),
                      ],
                    ),
                    if (io.isNotEmpty)
                      Text(
                        io,
                        style: DelveText.monoSmall.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: DelveTokens.space1),
                Row(
                  children: [
                    Expanded(child: metric(l.usagePrefill, speeds.prefill)),
                    Expanded(
                      child: metric(l.usageGeneration, speeds.generation),
                    ),
                    Expanded(
                      child: metric(l.usageFirstToken, speeds.firstToken),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
