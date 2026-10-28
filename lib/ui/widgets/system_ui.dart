import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../api/models/models.dart';
import '../../api/protocol.dart';
import '../../app/system.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../format.dart';
import 'page_scaffolds.dart';
import 'status_ui.dart';

/// Surface-1 card (radius 16, 16 dp padding), as on the dashboard.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(DelveTokens.space4),
    decoration: BoxDecoration(
      color: context.colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(DelveTokens.rlg),
    ),
    child: child,
  );
}

/// Card title with an optional muted note on the right ("checked 23:58").
class CardHeader extends StatelessWidget {
  const CardHeader({super.key, required this.title, this.note});
  final String title;
  final String? note;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: DelveTokens.space2),
    child: LayoutBuilder(
      builder: (context, box) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(title, style: context.text.titleLarge)),
          if (note case final n?) ...[
            const SizedBox(width: DelveTokens.space2),
            // No flex here: a loose Flexible would leave its unused share
            // empty after the note, so the note would not reach the edge.
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: box.maxWidth / 2),
              child: Text(
                n,
                textAlign: TextAlign.end,
                style: context.text.bodyMedium!.copyWith(
                  color: context.delve.textMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

/// One label/value line: the label secondary on the left, the value (mono
/// text or a widget) on the right.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    this.value,
    this.trailing,
    this.valueColor,
  }) : assert(value != null || trailing != null);

  final String label;
  final String? value;
  final Widget? trailing;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: DelveTokens.chip),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: DelveTokens.space1),
      child: LayoutBuilder(
        builder: (context, box) => Row(
          children: [
            // The label keeps its natural width (at most half the row) and
            // the value gets everything right of it, so the value always
            // ends on the right edge.
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: box.maxWidth / 2),
              child: Text(
                label,
                style: context.text.bodyLarge!.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: DelveTokens.space3),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child:
                    trailing ??
                    Text(
                      value!,
                      textAlign: TextAlign.end,
                      style: DelveText.mono.copyWith(
                        color: valueColor ?? context.colors.onSurface,
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The state of llama-server as coloured text: running is ok (a service,
/// not a run), loading and its kin warn, stopped and unknown info, failed and
/// unreachable alert.
StatusText llamaStatus(AppLocalizations l, String status) {
  final (kind, label) = switch (status) {
    'running' => (StatusKind.ok, l.systemStateRunning),
    'loading' => (StatusKind.warn, l.systemStateLoading),
    'starting' => (StatusKind.warn, l.systemStateStarting),
    'stopping' => (StatusKind.warn, l.systemStateStopping),
    'stopped' => (StatusKind.info, l.systemStateStopped),
    'failed' => (StatusKind.alert, l.systemStateFailed),
    'down' => (StatusKind.alert, l.systemStateDown),
    _ => (StatusKind.info, l.systemStateUnknown),
  };
  return StatusText(
    key: const Key('system.llama.status'),
    kind: kind,
    label: label,
  );
}

/// The state of Hermes as coloured text: ok, degraded (warn), down, unknown.
StatusText hermesStatus(AppLocalizations l, String status) {
  final (kind, label) = switch (status) {
    'ok' => (StatusKind.ok, l.systemStateOk),
    'degraded' => (StatusKind.warn, l.systemStateDegraded),
    'down' => (StatusKind.alert, l.systemStateDown),
    _ => (StatusKind.info, l.systemStateUnknown),
  };
  return StatusText(
    key: const Key('system.hermes.status'),
    kind: kind,
    label: label,
  );
}

/// One GPU: name and figures on a line, the memory bar below.
class GpuRow extends StatelessWidget {
  const GpuRow({super.key, required this.gpu, this.showPower = true});
  final GpuInfo gpu;
  final bool showPower;

  @override
  Widget build(BuildContext context) {
    final used = gpu.memUsedMib;
    final total = gpu.memTotalMib;
    final parts = [
      if (gpu.tempC case final t?) '${t.round()} °C',
      if (showPower && gpu.powerW != null) '${gpu.powerW!.round()} W',
      if (used != null && total != null)
        '${gbText(used)} / ${gbText(total, total: true)} GB',
    ];
    final fill = used != null && total != null && total > 0
        ? (used / total).clamp(0.0, 1.0)
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DelveTokens.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, box) => Row(
              children: [
                // Same split as InfoRow: the name at most half, the figures
                // the rest, ending on the right edge.
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: box.maxWidth / 2),
                  child: Text(
                    gpuName(gpu.name),
                    style: context.text.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: DelveTokens.space3),
                Expanded(
                  child: Text(
                    parts.join(' · '),
                    key: Key('gpu.${gpu.index}.figures'),
                    textAlign: TextAlign.end,
                    style: DelveText.mono.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (fill != null) ...[
            const SizedBox(height: DelveTokens.space2),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: context.colors.surfaceContainerHighest),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: fill,
                      child: ColoredBox(color: context.colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Stop (outlined, alert) or Start (filled, accent) llama-server; disabled
/// while one is on its way or without the helper.
class LlamaButton extends ConsumerWidget {
  const LlamaButton({super.key, required this.info});
  final SystemInfo info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final busy = ref.watch(systemProvider.select((v) => v.busy));
    final transitioning =
        info.llama.status == 'starting' || info.llama.status == 'stopping';
    final enabled = busy == null && info.helper.ok && !transitioning;
    if (info.canStart) {
      return SizedBox(
        height: DelveTokens.button,
        child: FilledButton.icon(
          key: const Key('system.llama.start'),
          onPressed: enabled
              ? () => runLlamaAction(context, ref, LlamaAction.start, info)
              : null,
          icon: const SymbolIcon(
            DelveIcons.play,
            size: DelveTokens.iconMd,
            filled: true,
          ),
          label: Text(
            busy == LlamaAction.start ? l.systemStarting : l.systemStart,
          ),
        ),
      );
    }
    return SizedBox(
      height: DelveTokens.button,
      child: OutlinedButton.icon(
        key: const Key('system.llama.stop'),
        style: OutlinedButton.styleFrom(
          foregroundColor: context.delve.alertFg,
          side: BorderSide(
            color: enabled
                ? context.delve.alertBorder
                : context.colors.outlineVariant,
          ),
        ),
        onPressed: enabled
            ? () => runLlamaAction(context, ref, LlamaAction.stop, info)
            : null,
        icon: const SymbolIcon(DelveIcons.power, size: DelveTokens.iconMd),
        label: Text(busy == LlamaAction.stop ? l.systemStopping : l.systemStop),
      ),
    );
  }
}

/// 13b: asks before stopping; says what happens to the active run and the
/// queued messages (they wait - N48).
Future<bool> confirmStopLlama(BuildContext context, SystemInfo info) async {
  final l = AppLocalizations.of(context);
  final lines = [
    if (info.queue.active > 0) l.systemStopActive,
    if (info.queue.queued > 0) l.systemStopQueued(info.queue.queued),
    l.systemStopBody,
  ];
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SymbolIcon(DelveIcons.power, color: context.delve.alertFg),
          const SizedBox(height: DelveTokens.space4),
          Text(l.systemStopTitle),
        ],
      ),
      content: Text(lines.join(' '), key: const Key('system.stop.body')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('system.stop.confirm'),
          style: FilledButton.styleFrom(
            backgroundColor: context.delve.alertFg,
            foregroundColor: context.colors.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l.systemStopConfirm),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Stop (after the dialog) or start llama-server; failures go to a snackbar.
/// A run that started after the dialog opened answers 409: say so, reload.
Future<void> runLlamaAction(
  BuildContext context,
  WidgetRef ref,
  LlamaAction action,
  SystemInfo info,
) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final controller = ref.read(systemProvider.notifier);
  if (action == LlamaAction.stop && !await confirmStopLlama(context, info)) {
    return;
  }
  try {
    await controller.llama(action, force: info.queue.active > 0);
  } on ApiRequestError catch (e) {
    final text = e.status == 409 && e.code == 'run_active'
        ? l.systemRunStarted
        : _failed(l, action, apiErrorText(l, e));
    messenger.showSnackBar(SnackBar(content: Text(text)));
    if (e.status == 409) {
      try {
        await controller.refresh();
      } on Object {
        // the snackbar already says what to do
      }
    }
  } on Object catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text(_failed(l, action, apiErrorText(l, e)))),
    );
  }
}

String _failed(AppLocalizations l, LlamaAction action, String reason) =>
    action == LlamaAction.stop
    ? l.systemStopFailed(reason)
    : l.systemStartFailed(reason);
