import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../api/models/models.dart';
import '../../app/chat_list.dart';
import '../../app/system.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../format.dart';
import 'page_scaffolds.dart';
import 'status_ui.dart';

/// What the failed-switch banners offer to copy.
const String kLlamaJournalCommand = 'journalctl --user -u llama-server -n 50';

/// How far the Model row's fill runs into its card's padding, so that the
/// label stays on the card's text edge.
const double _rowBleed = DelveTokens.space2;

/// A size on disk as the picker writes it: `14.3 GB` (decimal, like `ls -h
/// --si` and the model pages).
String modelSizeText(int bytes) => '${(bytes / 1e9).toStringAsFixed(1)} GB';

/// A preset's facts in mono: `98,304 tok · 14.3 GB`, with its id in front
/// for the confirmation ([withName]).
String presetFacts(AppLocalizations l, LlamaModel m, {bool withName = false}) =>
    [
      if (withName) m.name,
      if (m.ctx case final ctx?) l.systemTokens(tokenCount(ctx)),
      if (m.sizeBytes case final bytes?) modelSizeText(bytes),
    ].join(' · ');

/// Why a preset cannot be loaded, as the desktop's helper names it.
String modelReasonText(AppLocalizations l, String? reason) => switch (reason) {
  'context_below_64k' || 'no_context' => l.modelReasonContext,
  'model_missing' => l.modelReasonMissing,
  'mmproj_missing' => l.modelReasonProjector,
  'no_model' => l.modelReasonNoModel,
  _ => l.modelReasonOther,
};

/// Why a switch failed: `llama-server exited after 0:31`, `Not ready after
/// 3:00`; null when the desktop did not say.
String? switchReasonText(AppLocalizations l, LlamaSwitch sw) {
  final s = sw.elapsedS;
  if (s == null) return null;
  final time = countdownText(Duration(seconds: s));
  return switch (sw.error) {
    'timeout' => l.modelNotReadyAfter(time),
    'exited' => l.modelExitedAfter(time),
    _ => null,
  };
}

/// 25a/25b: the Model row of the System cards. The row itself is the control
/// that opens the picker: a filled 48 dp row among plain key-value rows.
/// Stopped: it names the preset that Start loads. During a switch: outlined,
/// not tappable, naming the model that loads.
class ModelRow extends ConsumerWidget {
  const ModelRow({super.key, required this.info});
  final SystemInfo info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final off = context.delve.textDisabled;
    final ll = info.llama;
    final busy = ref.watch(systemProvider.select((v) => v.busy));
    final enabled = !ll.switching && busy == null && info.helper.ok;
    final onStart = !ll.switching && info.canStart;
    final radius = BorderRadius.circular(DelveTokens.rmd);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DelveTokens.space1),
      child: LayoutBuilder(
        builder: (context, box) => OverflowBox(
          fit: OverflowBoxFit.deferToChild,
          minWidth: box.maxWidth + 2 * _rowBleed,
          maxWidth: box.maxWidth + 2 * _rowBleed,
          child: Semantics(
            button: true,
            enabled: enabled,
            child: Material(
              key: const Key('system.model'),
              color: enabled ? cs.surfaceContainerHigh : Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: radius,
                side: enabled
                    ? BorderSide.none
                    : BorderSide(
                        color: cs.outlineVariant,
                        width: DelveTokens.hairline,
                      ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: enabled ? () => changeModel(context, ref) : null,
                splashFactory: NoSplash.splashFactory,
                highlightColor: cs.surfaceContainerHighest,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: DelveTokens.touchTarget,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(_rowBleed, 6, 6, 6),
                    child: Row(
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.systemModel,
                              style: context.text.bodyLarge!.copyWith(
                                color: enabled ? cs.onSurfaceVariant : off,
                              ),
                            ),
                            if (onStart)
                              Text(
                                l.modelLoadsOnStart,
                                key: const Key('system.model.onStart'),
                                style: context.text.labelSmall!.copyWith(
                                  color: context.delve.textMuted,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: DelveTokens.space3),
                        Expanded(
                          child: Text(
                            ll.modelLine ?? l.settingsUnknown,
                            key: const Key('system.model.value'),
                            textAlign: TextAlign.end,
                            style: DelveText.monoSmall.copyWith(
                              color: enabled ? cs.onSurface : off,
                            ),
                          ),
                        ),
                        const SizedBox(width: DelveTokens.space2),
                        SymbolIcon(
                          DelveIcons.unfoldMore,
                          size: DelveTokens.iconMd,
                          color: enabled ? cs.onSurfaceVariant : off,
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
    );
  }
}

/// Opens the picker and carries out the choice: with a confirmation while
/// llama-server runs, without one while it is stopped (the pick then only
/// changes what Start loads).
Future<void> changeModel(BuildContext context, WidgetRef ref) async {
  final first = ref.read(systemProvider).info;
  if (first == null) return;
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final controller = ref.read(systemProvider.notifier);
  final container = ProviderScope.containerOf(context, listen: false);
  // the chat whose run a switch would stop, as the Chats list knows it
  final chats = ref.read(chatListProvider(false)).value ?? const [];
  String? runningChat;
  for (final c in chats) {
    if (c.activeRuns > 0) {
      final title = c.conversation.title?.trim();
      runningChat = title == null || title.isEmpty ? null : title;
      break;
    }
  }

  final name = await showLocalModels(context, first);
  if (name == null) return;
  final info = container.read(systemProvider).info ?? first;
  final target = info.llama.presetNamed(name);
  if (target == null || target.active || info.llama.switching) return;

  void say(String text) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> reload() async {
    try {
      await controller.refresh();
    } on Object {
      // the snackbar already says what happened
    }
  }

  var force = false;
  if (!info.canStart) {
    final stops = info.queue.active > 0;
    if (!context.mounted) return;
    final ok = await confirmSwitchModel(
      context,
      info,
      target,
      stopsRun: stops,
      chat: runningChat,
    );
    if (!ok) return;
    force = stops;
  }
  for (;;) {
    try {
      await controller.switchModel(target.name, force: force);
      return;
    } on ApiRequestError catch (e) {
      if (e.code == 'run_active' && !force && context.mounted) {
        // a run started after the dialog was shown: ask again, saying so
        final ok = await confirmSwitchModel(
          context,
          info,
          target,
          stopsRun: true,
          chat: runningChat,
        );
        if (!ok) {
          await reload();
          return;
        }
        force = true;
        continue;
      }
      final text = switch (e.code) {
        'already_active' => null,
        'run_active' => l.systemRunStarted,
        'model_not_usable' => l.modelNotUsable,
        'switch_in_progress' => l.modelSwitchInProgress,
        'unknown_model' => l.modelUnknown,
        _ => l.modelSwitchFailed(apiErrorText(l, e)),
      };
      if (text != null) say(text);
      if (e.status == 409 || e.status == 404) await reload();
      return;
    } on Object catch (e) {
      say(l.modelSwitchFailed(apiErrorText(l, e)));
      return;
    }
  }
}

/// 25d: asks before a switch. Repeats the target's preset id, context and
/// size; says what happens to the active run ([stopsRun], in [chat]) and to
/// the queued messages.
Future<bool> confirmSwitchModel(
  BuildContext context,
  SystemInfo info,
  LlamaModel target, {
  required bool stopsRun,
  String? chat,
}) async {
  final l = AppLocalizations.of(context);
  final queued = info.queue.queued;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) {
      final cs = context.colors;
      return AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SymbolIcon(
              DelveIcons.modelSwitch,
              color: stopsRun ? context.delve.alertFg : cs.onSurfaceVariant,
            ),
            const SizedBox(height: DelveTokens.space4),
            Text(l.modelSwitchTitle(modelText(target.model, target.quant))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                presetFacts(l, target, withName: true),
                key: const Key('model.confirm.facts'),
                style: DelveText.monoSmall.copyWith(
                  color: context.delve.textMuted,
                ),
              ),
              const SizedBox(height: DelveTokens.space3),
              Text(l.modelSwitchBody),
              if (stopsRun) ...[
                const SizedBox(height: DelveTokens.space3),
                _Consequence(
                  key: const Key('model.confirm.run'),
                  icon: DelveIcons.stopped,
                  color: context.delve.alertFg,
                  filled: true,
                  text: l.systemStopActive,
                  note: chat == null ? null : l.modelSwitchRunChat(chat),
                ),
              ],
              if (queued > 0) ...[
                const SizedBox(height: DelveTokens.space2),
                _Consequence(
                  key: const Key('model.confirm.queued'),
                  icon: DelveIcons.scheduleSend,
                  color: cs.onSurfaceVariant,
                  text: l.modelSwitchQueued(queued),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            key: const Key('model.confirm.ok'),
            style: stopsRun
                ? FilledButton.styleFrom(
                    backgroundColor: context.delve.alertFg,
                    foregroundColor: cs.onError,
                  )
                : null,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(stopsRun ? l.modelStopAndSwitch : l.modelSwitch),
          ),
        ],
      );
    },
  );
  return ok ?? false;
}

/// One consequence line of the confirmation: icon 20 + text, an optional
/// muted note below.
class _Consequence extends StatelessWidget {
  const _Consequence({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
    this.note,
    this.filled = false,
  });

  final IconData icon;
  final Color color;
  final String text;
  final String? note;
  final bool filled;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SymbolIcon(icon, size: DelveTokens.iconMd, filled: filled, color: color),
      const SizedBox(width: DelveTokens.space2),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: context.text.bodyMedium!.copyWith(
                color: context.colors.onSurface,
              ),
            ),
            if (note case final n?)
              Text(
                n,
                style: context.text.bodySmall!.copyWith(
                  color: context.delve.textMuted,
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

/// 25c: the sheet "Local models". Returns the picked preset's id; null when
/// it was closed or the loaded one was tapped.
Future<String?> showLocalModels(BuildContext context, SystemInfo info) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: context.colors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DelveTokens.rxl),
        ),
      ),
      builder: (_) => LocalModelsSheet(info: info),
    );

/// The presets in the desktop's order, those that cannot be loaded last. It
/// follows the system view while it is open.
class LocalModelsSheet extends ConsumerWidget {
  const LocalModelsSheet({super.key, required this.info});

  /// What the sheet was opened with (shown until a newer view arrives).
  final SystemInfo info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final muted = context.delve.textMuted;
    final live = ref.watch(systemProvider.select((v) => v.info)) ?? info;
    final models = live.llama.models ?? const <LlamaModel>[];
    final rows = [
      for (final m in models)
        if (m.usable) m,
      for (final m in models)
        if (!m.usable) m,
    ];
    final footer = l.modelPickerFooter('\u0000').split('\u0000');
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DelveTokens.space5,
              0,
              DelveTokens.space2,
              DelveTokens.space2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.modelPickerTitle, style: context.text.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        live.canStart
                            ? l.modelPickerStopped
                            : l.modelPickerSubtitle,
                        key: const Key('model.picker.subtitle'),
                        style: context.text.labelMedium!.copyWith(color: muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('model.picker.close'),
                  tooltip: l.close,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const SymbolIcon(DelveIcons.close),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
                for (final m in rows)
                  LocalModelRow(
                    model: m,
                    onTap: m.usable
                        ? () => Navigator.of(
                            context,
                          ).pop(m.active ? null : m.name)
                        : null,
                  ),
              ],
            ),
          ),
          Divider(
            height: DelveTokens.hairline,
            thickness: DelveTokens.hairline,
            color: cs.outlineVariant,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DelveTokens.space5,
              DelveTokens.space3,
              DelveTokens.space5,
              DelveTokens.space4,
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: footer.first),
                  TextSpan(
                    text: '~/.config/delve/llama',
                    style: DelveText.monoSmall.copyWith(color: muted),
                  ),
                  if (footer.length > 1) TextSpan(text: footer.last),
                ],
              ),
              style: context.text.bodySmall!.copyWith(color: muted),
            ),
          ),
        ],
      ),
    );
  }
}

/// One preset in the picker: name and quantization, context and size with
/// the two capability markers, then its note or - when it cannot be loaded -
/// the reason. The loaded one is tinted and checked.
class LocalModelRow extends StatelessWidget {
  const LocalModelRow({super.key, required this.model, this.onTap});
  final LlamaModel model;

  /// null: the preset cannot be loaded.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final muted = context.delve.textMuted;
    final off = context.delve.textDisabled;
    final m = model;
    final usable = m.usable;
    // a preset without a readable model shows its id
    final unnamed = m.model == m.name && m.quant == null;
    final title = m.quant == null ? m.model : '${m.model} · ${m.quant}';
    final facts = presetFacts(l, m);
    final note = m.note?.trim() ?? '';
    return Semantics(
      selected: m.active,
      enabled: usable,
      child: Material(
        key: Key('model.row.${m.name}'),
        color: m.active ? cs.primaryContainer : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashFactory: NoSplash.splashFactory,
          highlightColor: cs.surfaceContainerHighest,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DelveTokens.space5,
                vertical: DelveTokens.space2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style:
                              (unnamed
                                      ? DelveText.mono.copyWith(
                                          fontWeight: FontWeight.w500,
                                        )
                                      : context.text.titleSmall!)
                                  .copyWith(color: usable ? cs.onSurface : off),
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: DelveTokens.space3,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (facts.isNotEmpty)
                              Text(
                                facts,
                                style: DelveText.monoSmall.copyWith(
                                  color: usable ? cs.onSurfaceVariant : off,
                                ),
                              ),
                            CapabilityMarkers(model: m),
                          ],
                        ),
                        if (!usable)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                SymbolIcon(
                                  DelveIcons.block,
                                  size: 14,
                                  color: muted,
                                ),
                                const SizedBox(width: DelveTokens.space1),
                                Expanded(
                                  child: Text(
                                    modelReasonText(l, m.reason),
                                    style: context.text.bodySmall!.copyWith(
                                      color: muted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (note.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              note,
                              style: context.text.bodySmall!.copyWith(
                                color: muted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (m.active) ...[
                    const SizedBox(width: DelveTokens.space3),
                    SymbolIcon(
                      DelveIcons.check,
                      key: Key('model.row.${m.name}.check'),
                      size: 22,
                      color: cs.onPrimaryContainer,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The two capability markers of a preset, always in this order: image
/// input, thinking. Icon 16 + word; what a model lacks is muted, not an
/// error.
class CapabilityMarkers extends StatelessWidget {
  const CapabilityMarkers({super.key, required this.model});
  final LlamaModel model;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final has = context.colors.onSurfaceVariant;
    final lacks = context.delve.textMuted;
    final off = context.delve.textDisabled;
    Color tone(bool present) => !model.usable
        ? off
        : present
        ? has
        : lacks;
    Widget marker(
      IconData icon,
      String label,
      Color color, {
      bool filled = false,
    }) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SymbolIcon(
          icon,
          size: DelveTokens.iconSm,
          filled: filled,
          color: color,
        ),
        const SizedBox(width: DelveTokens.space1),
        Text(label, style: context.text.labelMedium!.copyWith(color: color)),
      ],
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (model.vision)
          marker(DelveIcons.image, l.modelCapImages, tone(true))
        else
          marker(DelveIcons.imageGone, l.modelCapTextOnly, tone(false)),
        const SizedBox(width: DelveTokens.space3),
        switch (model.thinking) {
          'always' => marker(
            DelveIcons.thinking,
            l.modelCapAlways,
            tone(true),
            filled: true,
          ),
          'none' => marker(
            DelveIcons.thinking,
            l.modelCapNoThinking,
            tone(false),
          ),
          _ => marker(DelveIcons.thinking, l.modelCapThinking, tone(true)),
        },
      ],
    );
  }
}

/// 25e: the word that stands for the state while a model loads - `sync` +
/// "switching" in the info colour. The icon turns once per 1.2 s; it stands
/// still with reduced motion.
class SwitchingWord extends StatefulWidget {
  const SwitchingWord({super.key});

  @override
  State<SwitchingWord> createState() => _SwitchingWordState();
}

class _SwitchingWordState extends State<SwitchingWord>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _turn.stop();
    } else if (!_turn.isAnimating) {
      unawaited(_turn.repeat());
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final fg = context.delve.infoFg;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RotationTransition(
          turns: _turn,
          child: SymbolIcon(
            DelveIcons.sync,
            size: DelveTokens.iconSm,
            color: fg,
          ),
        ),
        const SizedBox(width: DelveTokens.space1),
        Text(
          l.systemStateSwitching,
          key: const Key('system.llama.status'),
          softWrap: false,
          style: DelveText.mono.copyWith(
            color: fg,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// 25e: "Loading ‹model›…" with the time since the desktop started the
/// switch (every device shows the same), the neutral indeterminate bar and,
/// on the System screen ([showStarter]), who started it. Never a percent.
class SwitchingBlock extends StatefulWidget {
  const SwitchingBlock({
    super.key,
    required this.info,
    this.showStarter = false,
  });

  final SystemInfo info;
  final bool showStarter;

  @override
  State<SwitchingBlock> createState() => _SwitchingBlockState();
}

class _SwitchingBlockState extends State<SwitchingBlock> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final ll = widget.info.llama;
    final sw = ll.switchState;
    if (sw == null) return const SizedBox.shrink();
    final now = DateTime.now();
    final at = sw.at;
    final by = sw.by;
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: DelveTokens.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  l.modelLoading(ll.presetText(sw.to) ?? sw.to),
                  key: const Key('system.switch.line'),
                  style: context.text.bodyMedium!.copyWith(color: cs.onSurface),
                ),
              ),
              if (at != null) ...[
                const SizedBox(width: DelveTokens.space3),
                Padding(
                  // on the first line's baseline (14/20 beside 11.5/16)
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    countdownText(now.difference(at)),
                    key: const Key('system.switch.elapsed'),
                    style: DelveText.monoSmall.copyWith(
                      color: cs.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: DelveTokens.space2),
          ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: cs.surfaceContainerHighest,
              color: cs.onSurfaceVariant,
            ),
          ),
          if (widget.showStarter && by != null && at != null) ...[
            const SizedBox(height: DelveTokens.space2),
            Text(
              l.modelStartedFrom(by, clockTime(at, now)),
              key: const Key('system.switch.starter'),
              style: context.text.labelMedium!.copyWith(
                color: context.delve.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 25f: a switch that failed, above the System cards. `failed`: the previous
/// model is back - it stays until Dismiss or the next switch (the desktop
/// keeps it). `down`: going back failed too - no Dismiss; it leaves when
/// llama-server runs again (Start is on the card below).
class SwitchFailedBanner extends ConsumerWidget {
  const SwitchFailedBanner({super.key, required this.info});
  final SystemInfo info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ll = info.llama;
    final sw = ll.switchState;
    if (sw == null || sw.state == 'switching') return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final d = context.delve;
    final busy = ref.watch(systemProvider.select((v) => v.busy));
    final down = sw.state == 'down';
    final to = ll.presetText(sw.to) ?? sw.to;
    final from = ll.presetText(sw.from);
    final title = switch ((down, from)) {
      (false, final f?) => l.modelFailed(to, f),
      (false, null) => l.modelFailedAlone(to),
      (true, final f?) => l.modelFailedDown(to, f),
      (true, null) => l.modelFailedDownAlone(to),
    };
    final why = switchReasonText(l, sw);
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: d.alertBg,
          border: Border.all(color: d.alertBorder, width: DelveTokens.hairline),
          borderRadius: BorderRadius.circular(DelveTokens.rmd),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, 12, 8, down ? 12 : 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SymbolIcon(
                DelveIcons.error,
                size: DelveTokens.iconMd,
                filled: true,
                color: d.alertFg,
              ),
              const SizedBox(width: DelveTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        title,
                        key: const Key('system.switch.failed'),
                        style: context.text.titleSmall!.copyWith(
                          color: context.colors.onSurface,
                        ),
                      ),
                    ),
                    if (why != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2, right: 6),
                        child: Text(
                          why,
                          key: const Key('system.switch.why'),
                          style: context.text.bodySmall!.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: CommandWell(command: kLlamaJournalCommand),
                    ),
                    if (!down)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          key: const Key('system.switch.dismiss'),
                          style: TextButton.styleFrom(
                            foregroundColor: d.alertFg,
                            minimumSize: const Size(0, 40),
                          ),
                          onPressed: busy == null
                              ? () => _dismiss(context, ref)
                              : null,
                          child: Text(l.modelDismiss),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _dismiss(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(systemProvider.notifier).dismissSwitch();
    } on Object catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l.modelDismissFailed(apiErrorText(l, e)))),
      );
    }
  }
}

/// A command to copy: mono on the recess, a copy button at the end.
class CommandWell extends StatelessWidget {
  const CommandWell({super.key, required this.command});
  final String command;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(top: DelveTokens.space2),
      padding: const EdgeInsets.fromLTRB(DelveTokens.space3, 2, 2, 2),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(DelveTokens.rsm),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              command,
              style: DelveText.monoSmall.copyWith(
                color: context.colors.onSurface,
              ),
            ),
          ),
          SizedBox.square(
            dimension: 40,
            child: IconButton(
              key: const Key('system.switch.copy'),
              tooltip: l.copy,
              padding: EdgeInsets.zero,
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await Clipboard.setData(ClipboardData(text: command));
                messenger
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(l.copied)));
              },
              icon: const SymbolIcon(DelveIcons.copy, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

/// A one-line note inside the dashboard's System card (min h 32): icon 16 +
/// small text, a chevron when it leads somewhere.
class SwitchLine extends StatelessWidget {
  const SwitchLine({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
    this.filled = false,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String text;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: DelveTokens.chip),
      child: Row(
        children: [
          SymbolIcon(
            icon,
            size: DelveTokens.iconSm,
            filled: filled,
            color: color,
          ),
          const SizedBox(width: DelveTokens.space2),
          Expanded(
            child: Text(
              text,
              style: context.text.bodySmall!.copyWith(
                color: context.colors.onSurface,
              ),
            ),
          ),
          if (onTap != null)
            SymbolIcon(
              DelveIcons.chevronRight,
              size: DelveTokens.iconMd,
              color: context.delve.textMuted,
            ),
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DelveTokens.rsm),
      child: row,
    );
  }
}

/// The dashboard's line for a failed switch ("Couldn't load ‹new› · back on
/// ‹quant›") or a llama-server that is down after one; nothing otherwise.
class SwitchFailedLine extends StatelessWidget {
  const SwitchFailedLine({super.key, required this.info, this.onTap});
  final SystemInfo info;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ll = info.llama;
    final sw = ll.switchState;
    if (sw == null || sw.state == 'switching') return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final back = ll.presetNamed(sw.from);
    final to = ll.presetText(sw.to) ?? sw.to;
    final text = switch (sw.state) {
      'down' => l.modelFailedDownShort,
      _ when sw.from == null => l.modelFailedAlone(to),
      _ => l.modelFailedShort(to, back?.quant ?? back?.model ?? sw.from!),
    };
    return SwitchLine(
      key: const Key('dashboard.switch.failed'),
      icon: DelveIcons.error,
      color: context.delve.alertFg,
      filled: true,
      text: text,
      onTap: onTap,
    );
  }
}

/// "2 messages wait for the new model." while a switch runs; an info banner
/// on the System screen. Hidden without queued messages.
class SwitchQueueBanner extends StatelessWidget {
  const SwitchQueueBanner({super.key, required this.info});
  final SystemInfo info;

  @override
  Widget build(BuildContext context) => StatusBanner(
    key: const Key('system.switch.queue'),
    kind: StatusKind.info,
    icon: DelveIcons.scheduleSend,
    text: AppLocalizations.of(context).modelQueueWaits(info.queue.queued),
  );
}
