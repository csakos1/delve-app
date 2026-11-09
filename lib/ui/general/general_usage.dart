import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../general/general_database.dart';
import '../../general/general_key_store.dart';
import '../../general/general_providers.dart';
import '../../general/openrouter_client.dart';
import '../../general/openrouter_errors.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../chat/usage.dart' show ContextBar, contextWarnPct;
import '../format.dart';
import '../widgets/page_scaffolds.dart';
import 'general_format.dart';

/// Opens the General Usage sheet (24f) of [chatId].
Future<void> showGeneralUsageSheet(
  BuildContext context, {
  required String chatId,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => GeneralUsageSheet(chatId: chatId),
);

/// 24f Usage of a General chat: the agent's Usage sheet without the
/// desktop numbers – Input · Output · Cost · Answers, the context of the
/// last answer, the answers by model and the key's spend this period.
class GeneralUsageSheet extends ConsumerWidget {
  const GeneralUsageSheet({super.key, required this.chatId});

  final String chatId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final d = context.delve;
    final chat = ref.watch(generalChatProvider(chatId)).value;
    final byModel =
        ref.watch(generalUsageByModelProvider(chatId)).value ??
        const <GeneralModelUsage>[];
    final models = ref.watch(generalModelsProvider).value ?? const [];
    final names = {for (final m in models) m.id: m};
    final title = chat?.title?.trim();
    final answers = byModel.fold<int>(0, (n, u) => n + u.answers);
    final pct = chat == null ? null : generalContextPct(chat);
    final contextLine = chat == null ? null : generalContextText(chat);
    final warn = (pct ?? 0) >= contextWarnPct;
    final contextMax = chat?.lastContextLength;

    final children = <Widget>[
      Row(
        children: [
          Expanded(
            child: Text(l.usageTitle, style: context.text.headlineSmall),
          ),
          IconButton(
            key: const Key('generalUsage.close'),
            tooltip: l.close,
            onPressed: () => Navigator.of(context).pop(),
            icon: const SymbolIcon(DelveIcons.close),
          ),
        ],
      ),
      Text(
        title == null || title.isEmpty ? l.newChat : title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: context.text.bodyMedium!.copyWith(color: cs.onSurfaceVariant),
      ),
      const SizedBox(height: DelveTokens.space4),
      Row(
        children: [
          Expanded(
            child: _Tile(
              key: const Key('generalUsage.input'),
              label: l.usageInput,
              value: tokenCount(chat?.tokensIn ?? 0),
            ),
          ),
          const SizedBox(width: DelveTokens.space3),
          Expanded(
            child: _Tile(
              key: const Key('generalUsage.output'),
              label: l.usageOutput,
              value: tokenCount(chat?.tokensOut ?? 0),
            ),
          ),
        ],
      ),
      const SizedBox(height: DelveTokens.space3),
      Row(
        children: [
          Expanded(
            child: _Tile(
              key: const Key('generalUsage.cost'),
              label: l.generalUsageCost,
              value: usdText(chat?.costUsd ?? 0),
            ),
          ),
          const SizedBox(width: DelveTokens.space3),
          Expanded(
            child: _Tile(
              key: const Key('generalUsage.answers'),
              label: l.generalUsageAnswersTile,
              value: tokenCount(answers),
            ),
          ),
        ],
      ),
      const SizedBox(height: DelveTokens.space6),
      Row(
        children: [
          Expanded(
            child: Text(l.generalUsageContext, style: context.text.titleSmall),
          ),
          Text(
            contextLine ?? l.usageNoContext,
            key: const Key('generalUsage.context'),
            style: DelveText.monoSmall.copyWith(
              color: warn ? d.warnFg : cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
      const SizedBox(height: DelveTokens.space3),
      ContextBar(pct: pct, height: 6),
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
            contextMax == null ? '' : tokenCount(contextMax),
            style: DelveText.monoSmall.copyWith(color: d.textMuted),
          ),
        ],
      ),
      const SizedBox(height: DelveTokens.space6),
      Text(l.generalUsageByModel, style: context.text.titleSmall),
      const SizedBox(height: DelveTokens.space2),
      const Divider(height: 1),
      if (byModel.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: DelveTokens.space4),
          child: Text(
            l.generalUsageNoAnswers,
            style: context.text.bodyMedium!.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      for (final u in byModel) ...[
        _ModelUsageRow(usage: u, model: names[u.modelId]),
        const Divider(height: 1),
      ],
      const SizedBox(height: DelveTokens.space4),
      const _KeyCard(),
    ];

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: ListView(
        key: const Key('generalUsage.sheet'),
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
}

/// A total in a surface-4 tile: label over the value (as the agent sheet).
class _Tile extends StatelessWidget {
  const _Tile({super.key, required this.label, required this.value});

  final String label;
  final String value;

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
              value,
              style: DelveText.mono.copyWith(fontSize: 22, height: 1.2),
            ),
          ),
        ],
      ),
    );
  }
}

/// One model of the chat: its short name and cost, then its id and
/// “in · out · answers”.
class _ModelUsageRow extends StatelessWidget {
  const _ModelUsageRow({required this.usage, required this.model});

  final GeneralModelUsage usage;
  final OrModelRow? model;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final muted = context.delve.textMuted;
    final u = usage;
    final counts = [
      l.usageIn(tokenCount(u.tokensIn)),
      l.usageOut(tokenCount(u.tokensOut)),
      l.generalUsageAnswers(u.answers),
    ].join(' · ');
    return Padding(
      key: ValueKey('generalUsage.model.${u.modelId}'),
      padding: const EdgeInsets.symmetric(vertical: DelveTokens.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  modelShortName(u.modelId, model),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleSmall,
                ),
              ),
              const SizedBox(width: DelveTokens.space3),
              Text(
                usdText(u.costUsd),
                style: DelveText.mono.copyWith(color: cs.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  u.modelId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DelveText.monoSmall.copyWith(color: muted),
                ),
              ),
              const SizedBox(width: DelveTokens.space3),
              Text(
                counts,
                style: DelveText.monoSmall.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The key's spend this period (surface-2, radius 12): the masked key, the
/// spend line with the reset day, and a 4 dp bar against the limit.
class _KeyCard extends ConsumerWidget {
  const _KeyCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final d = context.delve;
    final key = ref.watch(generalKeyProvider).value;
    if (key == null) return const SizedBox.shrink();
    final info = ref.watch(generalKeyInfoProvider);

    final Widget body = switch (info) {
      AsyncData(value: final KeyInfo i) => _spend(context, l, i),
      AsyncError(:final error) => Text(
        l.generalKeyInfoFailed(
          error is GeneralFailure ? error.message : '$error',
        ),
        style: context.text.bodySmall!.copyWith(color: d.textMuted),
      ),
      AsyncData() => const SizedBox.shrink(),
      _ => const LinearProgressIndicator(),
    };

    return Container(
      key: const Key('generalUsage.key'),
      padding: const EdgeInsets.all(DelveTokens.space4),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(DelveTokens.rmd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SymbolIcon(
                DelveIcons.key,
                size: DelveTokens.iconMd,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: DelveTokens.space2),
              Expanded(
                child: Text(
                  maskKey(key),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DelveText.mono,
                ),
              ),
            ],
          ),
          const SizedBox(height: DelveTokens.space2),
          body,
        ],
      ),
    );
  }

  Widget _spend(BuildContext context, AppLocalizations l, KeyInfo i) {
    final cs = context.colors;
    final d = context.delve;
    final limit = i.limit;
    final used = keySpent(i);
    final resets = i.resetsAt;
    final line = [
      keySpendText(l, i),
      if (resets != null)
        l.generalUsageResets(DateFormat('d MMM').format(resets.toLocal())),
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          line,
          key: const Key('generalUsage.key.line'),
          style: context.text.bodyMedium!.copyWith(
            color: cs.onSurfaceVariant,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (limit != null && limit > 0) ...[
          const SizedBox(height: DelveTokens.space2),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              key: const Key('generalUsage.key.bar'),
              value: (used / limit).clamp(0.0, 1.0),
              minHeight: 4,
              color: used >= limit ? d.alertFg : cs.primary,
              backgroundColor: cs.surfaceContainerHighest,
            ),
          ),
        ],
      ],
    );
  }
}
