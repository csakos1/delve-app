import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../general/general_database.dart';
import '../../general/general_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../chat/chat_items.dart';
import '../chat/markdown.dart';
import '../chat/thinking_block.dart';
import '../chat/usage.dart' show DashedRing, contextWarnPct;
import '../format.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/status_ui.dart';
import 'general_format.dart';

// The General chat's own pieces (design 24). Everything else is the agent
// chat's (bubble, Markdown, thinking block, composer).

/// The model chip in the General chat's top bar: the context ring of the
/// last answer, the model's short name and ▾; warn colours above 75 %; a
/// dashed ring and “Pick a model” without a model. Opens the model picker;
/// a long press opens the chat's Usage sheet ([onLongPress]).
class ModelChip extends StatelessWidget {
  const ModelChip({
    super.key,
    required this.name,
    required this.pct,
    required this.onTap,
    this.onLongPress,
  });

  /// The short name; null: no usable model.
  final String? name;

  /// The context fill of the last answer (null before it).
  final double? pct;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  static const int maxChars = 14;

  static String clip(String name) =>
      name.length <= maxChars ? name : '${name.substring(0, maxChars - 1)}…';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final d = context.delve;
    final name = this.name;
    final pct = this.pct;
    final warn = pct != null && pct >= contextWarnPct;
    final percent = (pct ?? 0).round();

    final Color bg;
    final BorderSide side;
    final Color fg;
    final Widget lead;
    final String label;
    if (name == null) {
      bg = Colors.transparent;
      side = BorderSide(color: cs.outline);
      fg = cs.onSurfaceVariant;
      lead = CustomPaint(
        key: const Key('modelChip.empty'),
        size: const Size.square(18),
        painter: DashedRing(color: cs.outline, stroke: 2.5),
      );
      label = l.generalPickModel;
    } else if (warn) {
      bg = d.warnBg;
      side = BorderSide(color: d.warnBorder);
      fg = d.warnFg;
      lead = SymbolIcon(
        DelveIcons.warning,
        key: const Key('modelChip.warn'),
        size: DelveTokens.iconSm,
        filled: true,
        color: d.warnFg,
      );
      label = '${clip(name)} $percent%';
    } else {
      bg = cs.surfaceContainerHigh;
      side = BorderSide.none;
      fg = cs.onSurface;
      lead = SizedBox.square(
        dimension: 18,
        child: CircularProgressIndicator(
          value: ((pct ?? 0) / 100).clamp(0.0, 1.0),
          strokeWidth: 2.5,
          color: cs.onSurfaceVariant,
          backgroundColor: cs.surfaceContainerHighest,
        ),
      );
      label = clip(name);
    }
    final semantics = name == null
        ? l.generalPickModel
        : pct == null
        ? l.generalModelChipEmpty(name)
        : l.generalModelChipSemantics(name, percent);

    return Semantics(
      button: true,
      label: semantics,
      excludeSemantics: true,
      child: SizedBox(
        height: DelveTokens.touchTarget,
        child: Center(
          child: Material(
            color: bg,
            shape: StadiumBorder(side: side),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: const Key('general.modelChip'),
              onTap: onTap,
              onLongPress: onLongPress,
              child: SizedBox(
                height: 32,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 6, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      lead,
                      const SizedBox(width: 6),
                      Text(
                        label,
                        key: const Key('modelChip.label'),
                        maxLines: 1,
                        style: context.text.labelMedium!.copyWith(
                          color: fg,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 2),
                      SymbolIcon(
                        DelveIcons.expandMore,
                        size: 18,
                        color: warn ? fg : cs.onSurfaceVariant,
                      ),
                    ],
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

/// The General composer's Thinking pill. ON: accent fill; OFF: outline.
/// [locked] (the model always thinks): primaryContainer with a lock, not a
/// switch – a tap explains it. Long press picks the effort ([onLongPress]).
class GeneralThinkingPill extends StatefulWidget {
  const GeneralThinkingPill({
    super.key,
    required this.on,
    required this.locked,
    required this.label,
    required this.lockedTip,
    this.onChanged,
    this.onLongPress,
  });

  final bool on;
  final bool locked;

  /// “Thinking” or “Thinking · High”.
  final String label;

  /// “GLM 5.3 always thinks”.
  final String lockedTip;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onLongPress;

  @override
  State<GeneralThinkingPill> createState() => _GeneralThinkingPillState();
}

class _GeneralThinkingPillState extends State<GeneralThinkingPill> {
  final _tip = GlobalKey<TooltipState>();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final Color fg;
    final Color bg;
    final BorderSide side;
    if (widget.locked) {
      fg = cs.onPrimaryContainer;
      bg = cs.primaryContainer;
      side = BorderSide.none;
    } else if (widget.on) {
      fg = cs.onPrimary;
      bg = cs.primary;
      side = BorderSide.none;
    } else {
      fg = cs.onSurfaceVariant;
      bg = Colors.transparent;
      side = BorderSide(color: cs.outline);
    }
    final onChanged = widget.onChanged;
    final pill = AnimatedContainer(
      duration: DelveTokens.short,
      curve: DelveTokens.shortCurve,
      height: 32,
      decoration: ShapeDecoration(
        color: bg,
        shape: StadiumBorder(side: side),
      ),
      child: Material(
        type: MaterialType.transparency,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('general.thinking'),
          onTap: widget.locked
              ? () => _tip.currentState?.ensureTooltipVisible()
              : onChanged == null
              ? null
              : () => onChanged(!widget.on),
          onLongPress: widget.onLongPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: DelveTokens.space3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SymbolIcon(
                  DelveIcons.thinking,
                  size: 18,
                  filled: widget.on || widget.locked,
                  color: fg,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  key: const Key('general.thinking.label'),
                  style: context.text.labelLarge!.copyWith(color: fg),
                ),
                if (widget.locked) ...[
                  const SizedBox(width: DelveTokens.space1),
                  SymbolIcon(
                    DelveIcons.lock,
                    key: const Key('general.thinking.lock'),
                    size: 14,
                    color: fg,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    return Semantics(
      toggled: widget.locked ? null : widget.on,
      label: widget.locked ? widget.lockedTip : widget.label,
      hint: widget.onLongPress == null ? null : l.generalEffortHint,
      excludeSemantics: true,
      child: SizedBox(
        height: DelveTokens.touchTarget,
        child: Center(
          child: widget.locked
              ? Tooltip(
                  key: _tip,
                  message: widget.lockedTip,
                  triggerMode: TooltipTriggerMode.manual,
                  child: pill,
                )
              : pill,
        ),
      ),
    );
  }
}

/// What the effort sheet returns: the chosen effort, null for the model's
/// default.
typedef EffortChoice = ({String? effort});

/// The thinking effort of the next message: the model's default or one of
/// its efforts (strongest first). Null: dismissed.
Future<EffortChoice?> showEffortSheet(
  BuildContext context, {
  required String model,
  required List<String> efforts,
  required String? defaultEffort,
  required String? current,
}) => showModalBottomSheet<EffortChoice>(
  context: context,
  showDragHandle: true,
  backgroundColor: context.colors.surfaceContainerHigh,
  builder: (context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final selected = current != null && efforts.contains(current)
        ? current
        : null;
    Widget row(String? effort, String label) {
      final on = effort == selected;
      return ListTile(
        key: Key('effort.${effort ?? 'default'}'),
        tileColor: on ? cs.primaryContainer : null,
        title: Text(
          label,
          style: context.text.bodyLarge!.copyWith(
            color: on ? cs.onPrimaryContainer : null,
          ),
        ),
        trailing: on
            ? SymbolIcon(
                DelveIcons.check,
                size: 22,
                color: cs.onPrimaryContainer,
              )
            : null,
        onTap: () => Navigator.of(context).pop((effort: effort)),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DelveTokens.space6,
                0,
                DelveTokens.space6,
                DelveTokens.space3,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.generalEffortTitle, style: context.text.titleLarge),
                  Text(
                    l.generalEffortSub(model),
                    style: context.text.labelMedium!.copyWith(
                      color: context.delve.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            row(
              null,
              defaultEffort == null
                  ? l.generalEffortDefaultPlain
                  : l.generalEffortDefault(effortLabel(l, defaultEffort)),
            ),
            for (final e in efforts) row(e, effortLabel(l, e)),
            const SizedBox(height: DelveTokens.space2),
          ],
        ),
      ),
    );
  },
);

/// “Switched to GLM 5.3 · 21:12”, centred between two hairlines.
class SwitchMarker extends StatelessWidget {
  const SwitchMarker({super.key, required this.model, required this.at});

  final String model;
  final DateTime at;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final muted = context.delve.textMuted;
    Widget rule() => Expanded(
      child: Container(height: DelveTokens.hairline, color: cs.outlineVariant),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DelveTokens.space1),
      child: Row(
        children: [
          rule(),
          const SizedBox(width: DelveTokens.space3),
          SymbolIcon(DelveIcons.modelSwitch, size: 14, color: muted),
          const SizedBox(width: DelveTokens.space1),
          Text(
            l.generalSwitched(model, clockTime(at, DateTime.now())),
            key: const Key('general.switch'),
            style: context.text.labelSmall!.copyWith(color: muted),
          ),
          const SizedBox(width: DelveTokens.space3),
          rule(),
        ],
      ),
    );
  }
}

/// A user message: its images (tiles, right-aligned) above the bubble.
class GeneralUserMessage extends StatelessWidget {
  const GeneralUserMessage({
    super.key,
    required this.text,
    required this.images,
    required this.onOpenImage,
  });

  final String text;
  final List<GeneralImageRef> images;
  final void Function(GeneralImageRef) onOpenImage;

  @override
  Widget build(BuildContext context) {
    final tile = images.length == 1 ? 200.0 : 112.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (images.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
              bottom: text.isEmpty ? 0 : DelveTokens.space2,
            ),
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: DelveTokens.space2,
              runSpacing: DelveTokens.space2,
              children: [
                for (final (i, img) in images.indexed)
                  GeneralImageTile(
                    key: ValueKey('general.img.${img.id}'),
                    image: img,
                    index: i + 1,
                    size: tile,
                    onTap: () => onOpenImage(img),
                  ),
              ],
            ),
          ),
        if (text.isNotEmpty) UserBubble(text: text),
      ],
    );
  }
}

/// One image of a General message, from the phone's database.
class GeneralImageTile extends ConsumerWidget {
  const GeneralImageTile({
    super.key,
    required this.image,
    required this.index,
    required this.size,
    this.onTap,
  });

  final GeneralImageRef image;
  final int index;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final bytes = ref.watch(generalImageBytesProvider(image.id));
    final body = switch (bytes) {
      AsyncData(:final value) => Image.memory(
        value,
        fit: BoxFit.cover,
        width: size,
        height: size,
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _broken(context),
      ),
      AsyncError() => _broken(context),
      _ => const SizedBox.shrink(),
    };
    return Semantics(
      image: true,
      button: onTap != null,
      label: l.generalImage(index),
      child: Material(
        color: cs.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DelveTokens.rmd),
          side: BorderSide(
            color: cs.outlineVariant,
            width: DelveTokens.hairline,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox.square(dimension: size, child: body),
        ),
      ),
    );
  }

  Widget _broken(BuildContext context) => Center(
    child: SymbolIcon(
      DelveIcons.imageGone,
      size: 22,
      color: context.delve.textMuted,
    ),
  );
}

/// A General image full screen (pinch to zoom).
class GeneralImageViewer extends ConsumerWidget {
  const GeneralImageViewer({super.key, required this.image});

  final GeneralImageRef image;

  static Future<void> open(BuildContext context, GeneralImageRef image) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => GeneralImageViewer(image: image),
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bytes = ref.watch(generalImageBytesProvider(image.id));
    return Scaffold(
      backgroundColor: context.colors.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: context.colors.surfaceContainer,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          icon: const SymbolIcon(DelveIcons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(byteSize(image.size), style: context.text.titleMedium),
      ),
      body: Center(
        child: switch (bytes) {
          AsyncData(:final value) => InteractiveViewer(
            maxScale: 6,
            child: Image.memory(value, gaplessPlayback: true),
          ),
          AsyncError() => SymbolIcon(
            DelveIcons.imageGone,
            color: context.delve.textMuted,
          ),
          _ => const CircularProgressIndicator(),
        },
      ),
    );
  }
}

/// What a failed answer offers (the screen does it).
enum GeneralErrorAction { openSettings, retry, pickModel }

/// A failed General answer: role colours, icon, title, the reason with the
/// HTTP code, and its actions (design 24, error banners). 429 counts down
/// before Retry.
class GeneralErrorBanner extends StatelessWidget {
  const GeneralErrorBanner({
    super.key,
    required this.code,
    required this.message,
    required this.failedAt,
    required this.onAction,
    this.retryAfterS,
  });

  final String? code;
  final String? message;
  final int? retryAfterS;

  /// When the answer failed (the 429 countdown starts there).
  final DateTime failedAt;
  final void Function(GeneralErrorAction) onAction;

  static int? httpStatus(String? code) => switch (code) {
    'unauthorized' => 401,
    'key_limit' => 402,
    'no_provider' => 404,
    'bad_request' => 400,
    'rate_limited' => 429,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final (kind, icon, title, actions) = switch (code) {
      'unauthorized' => (
        StatusKind.alert,
        DelveIcons.keyOff,
        l.generalErrKey,
        const [GeneralErrorAction.openSettings],
      ),
      'key_limit' => (
        StatusKind.alert,
        DelveIcons.wallet,
        l.generalErrLimit,
        const [GeneralErrorAction.openSettings, GeneralErrorAction.retry],
      ),
      'no_provider' => (
        StatusKind.alert,
        DelveIcons.shield,
        l.generalErrNoProvider,
        const [GeneralErrorAction.pickModel],
      ),
      'rate_limited' => (
        StatusKind.warn,
        DelveIcons.hourglass,
        l.generalErrRateNow,
        const [GeneralErrorAction.retry],
      ),
      'network' => (
        StatusKind.alert,
        DelveIcons.offline,
        l.generalErrNetwork,
        const [GeneralErrorAction.retry],
      ),
      'bad_request' => (
        StatusKind.alert,
        DelveIcons.error,
        l.generalErrBadRequest,
        const [GeneralErrorAction.retry, GeneralErrorAction.pickModel],
      ),
      'upstream' => (
        StatusKind.alert,
        DelveIcons.error,
        l.generalErrUpstream,
        const [GeneralErrorAction.retry],
      ),
      _ => (
        StatusKind.alert,
        DelveIcons.error,
        l.generalErrUnknown,
        const [GeneralErrorAction.retry],
      ),
    };
    final status = httpStatus(code);
    final msg = message;
    final reason = [
      if (msg != null && msg.isNotEmpty) msg,
      if (status != null) 'HTTP $status',
    ].join(' · ');
    final wait = code == 'rate_limited' ? retryAfterS : null;
    if (wait != null && wait > 0) {
      return _Countdown(
        until: failedAt.add(Duration(seconds: wait)),
        total: wait,
        builder: (left) => _body(
          context,
          kind: kind,
          lead: left > 0
              ? _ring(context, left / wait)
              : _icon(context, kind, icon),
          title: left > 0 ? l.generalErrRate(left) : title,
          reason: reason,
          actions: actions,
          enabled: left <= 0,
        ),
      );
    }
    return _body(
      context,
      kind: kind,
      lead: _icon(context, kind, icon),
      title: title,
      reason: reason,
      actions: actions,
      enabled: true,
    );
  }

  Widget _icon(BuildContext context, StatusKind kind, IconData icon) =>
      SymbolIcon(
        icon,
        size: DelveTokens.iconMd,
        filled: true,
        color: context.status(kind).fg,
      );

  Widget _ring(BuildContext context, double left) => SizedBox.square(
    key: const Key('general.error.countdown'),
    dimension: DelveTokens.iconMd,
    child: CircularProgressIndicator(
      value: left.clamp(0.0, 1.0),
      strokeWidth: 2.5,
      color: context.delve.warnFg,
      backgroundColor: context.delve.warnBorder,
    ),
  );

  Widget _body(
    BuildContext context, {
    required StatusKind kind,
    required Widget lead,
    required String title,
    required String reason,
    required List<GeneralErrorAction> actions,
    required bool enabled,
  }) {
    final l = AppLocalizations.of(context);
    final c = context.status(kind);
    String label(GeneralErrorAction a) => switch (a) {
      GeneralErrorAction.openSettings => l.generalOpenSettings,
      GeneralErrorAction.retry => l.retry,
      GeneralErrorAction.pickModel => l.generalPickAnother,
    };
    return Container(
      key: Key('general.error.${code ?? 'unknown'}'),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 8),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border.all(color: c.border, width: DelveTokens.hairline),
        borderRadius: BorderRadius.circular(DelveTokens.rmd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.only(top: 1), child: lead),
              const SizedBox(width: DelveTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      key: const Key('general.error.title'),
                      style: context.text.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (reason.isNotEmpty)
                      Text(
                        reason,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall!.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              alignment: WrapAlignment.end,
              children: [
                for (final a in actions)
                  TextButton(
                    key: Key('general.error.${a.name}'),
                    onPressed: a == GeneralErrorAction.retry && !enabled
                        ? null
                        : () => onAction(a),
                    style: TextButton.styleFrom(
                      foregroundColor: c.fg,
                      minimumSize: const Size(0, 36),
                    ),
                    child: Text(label(a)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Seconds left until [until], ticking.
class _Countdown extends StatefulWidget {
  const _Countdown({
    required this.until,
    required this.total,
    required this.builder,
  });

  final DateTime until;
  final int total;
  final Widget Function(int left) builder;

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  Timer? _timer;

  int get _left {
    final ms = widget.until.difference(DateTime.now()).inMilliseconds;
    return ms <= 0 ? 0 : (ms / 1000).ceil();
  }

  @override
  void initState() {
    super.initState();
    if (_left > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        setState(() {});
        if (_left <= 0) t.cancel();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_left);
}

/// One answer: the thought row, Markdown full width (no bubble, no rail),
/// then the footer: done (model · cost · tokens, copy), writing (accent
/// dot, clock), stopped. A failed answer shows the error banner after what
/// arrived.
class GeneralAnswer extends StatelessWidget {
  const GeneralAnswer({
    super.key,
    required this.message,
    required this.modelName,
    required this.showTokens,
    required this.onErrorAction,
  });

  final GeneralMessageRow message;
  final String modelName;
  final bool showTokens;
  final void Function(GeneralErrorAction) onErrorAction;

  @override
  Widget build(BuildContext context) {
    final m = message;
    final streaming = m.status == 'streaming';
    final failed = m.status == 'failed';
    final reasoning = m.reasoning?.trim() ?? '';
    final text = m.content;
    final thinkingNow =
        streaming && text.trim().isEmpty && reasoning.isNotEmpty;
    return Column(
      key: ValueKey('general.answer.${m.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (reasoning.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: DelveTokens.space2),
            child: ThinkingBlock(
              key: ValueKey('thinking.${m.id}'),
              live: thinkingNow,
              since: m.createdAt,
              reasoning: thinkingNow ? null : m.reasoning,
            ),
          ),
        if (text.trim().isNotEmpty)
          GestureDetector(
            onLongPress: () => _copy(context, text),
            child: DelveMarkdown(data: text),
          ),
        if (failed)
          Padding(
            padding: EdgeInsets.only(
              top: text.trim().isEmpty ? 0 : DelveTokens.space2,
            ),
            child: GeneralErrorBanner(
              code: m.errorCode,
              message: m.errorMessage,
              retryAfterS: m.retryAfterS,
              failedAt: m.createdAt,
              onAction: onErrorAction,
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: DelveTokens.space1),
            child: streaming
                ? _WritingFooter(model: modelName, since: m.createdAt)
                : _footer(context),
          ),
      ],
    );
  }

  static void _copy(BuildContext context, String text) {
    unawaited(Clipboard.setData(ClipboardData(text: text)));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).chatCopied)),
      );
  }

  Widget _footer(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = context.delve;
    final m = message;
    final stopped = m.status == 'stopped';
    final cost = m.costUsd;
    final parts = [
      if (stopped) l.generalStopped,
      modelName,
      if (cost != null && cost >= kCostHiddenBelow) usdText(cost),
      if (showTokens && m.tokensOut != null)
        l.generalTokens(tokenCount(m.tokensOut!)),
    ];
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 24),
      child: Row(
        children: [
          if (stopped) ...[
            SymbolIcon(
              DelveIcons.stopped,
              key: const Key('general.footer.stopped'),
              size: 14,
              filled: true,
              color: d.infoFg,
            ),
            const SizedBox(width: DelveTokens.space1),
          ],
          Flexible(
            child: Text(
              parts.join(' · '),
              key: const Key('general.footer'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall!.copyWith(color: d.textMuted),
            ),
          ),
          if (m.content.trim().isNotEmpty)
            SizedBox(
              width: 36,
              height: 32,
              child: IconButton(
                key: const Key('general.footer.copy'),
                tooltip: l.copy,
                padding: EdgeInsets.zero,
                iconSize: 16,
                onPressed: () => _copy(context, m.content),
                icon: SymbolIcon(DelveIcons.copy, size: 16, color: d.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

/// “GLM 5.3 · writing · 0:09” with the 6 dp accent dot; ticks every second.
class _WritingFooter extends StatefulWidget {
  const _WritingFooter({required this.model, required this.since});

  final String model;
  final DateTime since;

  @override
  State<_WritingFooter> createState() => _WritingFooterState();
}

class _WritingFooterState extends State<_WritingFooter> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final accent = context.colors.primary;
    final clock = countdownText(DateTime.now().difference(widget.since));
    return SizedBox(
      height: 24,
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '${widget.model} · ${l.generalWriting} · $clock',
              key: const Key('general.footer.writing'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall!.copyWith(color: accent),
            ),
          ),
        ],
      ),
    );
  }
}

/// A General chat in the Chats list: the agent row's title and time; the
/// third line is the marker (`cloud` + “General · GLM 5.3” in info) and the
/// chat's cost in muted mono.
class GeneralListRow extends StatelessWidget {
  const GeneralListRow({
    super.key,
    required this.chat,
    required this.modelName,
    required this.onTap,
  });

  final GeneralChatRow chat;
  final String modelName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final d = context.delve;
    final title = chat.title?.trim();
    return Material(
      color: cs.surface,
      child: InkWell(
        onTap: onTap,
        highlightColor: cs.surfaceContainerLow,
        child: Container(
          constraints: const BoxConstraints(minHeight: DelveTokens.listRow),
          margin: const EdgeInsets.only(left: DelveTokens.space4),
          padding: const EdgeInsets.fromLTRB(
            0,
            DelveTokens.space3,
            DelveTokens.space4,
            DelveTokens.space3,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: cs.outlineVariant,
                width: DelveTokens.hairline,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title == null || title.isEmpty ? l.newChat : title,
                      key: const Key('chats.title'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall!.copyWith(
                        fontSize: 16,
                        height: 22 / 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: DelveTokens.space3),
                  Text(
                    listTime(chat.updatedAt, DateTime.now()),
                    key: const Key('chats.time'),
                    style: context.text.labelMedium!.copyWith(
                      color: d.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DelveTokens.space2),
              Row(
                key: const Key('chats.marker.general'),
                children: [
                  SymbolIcon(DelveIcons.cloud, size: 14, color: d.infoFg),
                  const SizedBox(width: DelveTokens.space1),
                  Flexible(
                    child: Text(
                      l.generalMarker(modelName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelSmall!.copyWith(color: d.infoFg),
                    ),
                  ),
                  if (chat.costUsd >= kCostHiddenBelow)
                    Text(
                      ' · ${usdText(chat.costUsd)}',
                      key: const Key('chats.cost'),
                      style: DelveText.monoSmall.copyWith(color: d.textMuted),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Which chats the Chats list shows.
enum ChatsFilter { all, agent, general }

ChatsFilter chatsFilterOf(String? raw) => ChatsFilter.values.firstWhere(
  (f) => f.name == raw,
  orElse: () => ChatsFilter.all,
);

/// All · Agent · General under the Chats header (once a key is saved).
class ChatsFilterChips extends StatelessWidget {
  const ChatsFilterChips({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ChatsFilter value;
  final ValueChanged<ChatsFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SizedBox(
      height: 48,
      child: ListView(
        key: const Key('chats.filters'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DelveTokens.space4),
        children: [
          for (final (f, icon, label) in [
            (ChatsFilter.all, null, l.chatsFilterAll),
            (ChatsFilter.agent, DelveIcons.computer, l.chatsFilterAgent),
            (ChatsFilter.general, DelveIcons.cloud, l.chatsFilterGeneral),
          ]) ...[
            if (f != ChatsFilter.all) const SizedBox(width: DelveTokens.space2),
            Center(
              child: _FilterChip(
                key: Key('chats.filter.${f.name}'),
                selected: value == f,
                icon: icon,
                label: label,
                semantics: l.chatsFilterLabel(label),
                onTap: () => onChanged(f),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    super.key,
    required this.selected,
    required this.icon,
    required this.label,
    required this.semantics,
    required this.onTap,
  });

  final bool selected;
  final IconData? icon;
  final String label;
  final String semantics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final fg = selected ? cs.onPrimaryContainer : cs.onSurfaceVariant;
    final lead = selected ? DelveIcons.check : icon;
    return Semantics(
      selected: selected,
      button: true,
      label: semantics,
      excludeSemantics: true,
      child: Material(
        color: selected ? cs.primaryContainer : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DelveTokens.rsm),
          side: selected
              ? BorderSide.none
              : BorderSide(color: cs.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 32,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                lead == null ? DelveTokens.space4 : DelveTokens.space2,
                0,
                DelveTokens.space4,
                0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (lead != null) ...[
                    SymbolIcon(lead, size: 18, color: fg),
                    const SizedBox(width: DelveTokens.space2),
                  ],
                  Text(
                    label,
                    style: context.text.labelLarge!.copyWith(
                      color: selected ? fg : cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The kind of a new chat.
enum ChatKind { agent, general }

/// The remembered kind (Agent when nothing was chosen yet).
ChatKind chatKindOf(String? raw) =>
    raw == ChatKind.general.name ? ChatKind.general : ChatKind.agent;

/// New chat: Agent / General, a 2-segment control under the top bar.
class ChatKindSwitch extends StatelessWidget {
  const ChatKindSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ChatKind value;
  final ValueChanged<ChatKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    Widget segment(ChatKind kind, IconData icon, String title, String sub) {
      final on = value == kind;
      final fg = on ? cs.onPrimaryContainer : cs.onSurface;
      final subFg = on ? cs.onPrimaryContainer : cs.onSurfaceVariant;
      return Expanded(
        child: Semantics(
          selected: on,
          button: true,
          label: title,
          child: Material(
            color: on ? cs.primaryContainer : Colors.transparent,
            child: InkWell(
              key: Key('newChat.kind.${kind.name}'),
              onTap: () => onChanged(kind),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 72),
                child: Padding(
                  padding: const EdgeInsets.all(DelveTokens.space3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SymbolIcon(
                        on ? DelveIcons.check : icon,
                        size: DelveTokens.iconMd,
                        color: fg,
                      ),
                      const SizedBox(width: DelveTokens.space2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: context.text.labelLarge!.copyWith(
                                color: fg,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              sub,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.labelSmall!.copyWith(
                                color: subFg,
                              ),
                            ),
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
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DelveTokens.space4,
        DelveTokens.space3,
        DelveTokens.space4,
        0,
      ),
      child: Container(
        key: const Key('newChat.kind'),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline, width: DelveTokens.hairline),
          borderRadius: BorderRadius.circular(DelveTokens.rlg),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              segment(
                ChatKind.agent,
                DelveIcons.computer,
                l.newChatAgent,
                l.newChatAgentSub,
              ),
              Container(width: DelveTokens.hairline, color: cs.outline),
              segment(
                ChatKind.general,
                DelveIcons.cloud,
                l.newChatGeneral,
                l.newChatGeneralSub,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
