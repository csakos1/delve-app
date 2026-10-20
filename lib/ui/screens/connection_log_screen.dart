import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/db/database.dart';
import '../../l10n/app_localizations.dart';
import '../../sync/connection_status.dart';
import '../../sync/sync_providers.dart';
import '../../theme/delve_theme.dart';
import '../widgets/connection_ui.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/status_ui.dart';

/// Settings → Connection log: the current state, and what the WebSocket did
/// (newest first, the last 500 entries, kept across restarts).
class ConnectionLogScreen extends ConsumerWidget {
  const ConnectionLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final status =
        ref.watch(connectionStatusProvider).value ?? ConnectionStatus.initial;
    final entries =
        ref.watch(connectionLogProvider).value ?? const <ConnectionLogRow>[];
    final view = ConnectionView.of(l, status);
    final canRetry =
        status.phase == ConnectionPhase.backoff ||
        status.phase == ConnectionPhase.offline;

    return SubPage(
      title: l.logTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DelveTokens.space4,
              DelveTokens.space2,
              DelveTokens.space4,
              DelveTokens.space3,
            ),
            child: StatusBanner(
              key: const Key('log.status'),
              kind: view.kind,
              icon: view.icon,
              text: view.text,
              actionLabel: canRetry ? l.logReconnectNow : null,
              onAction: canRetry
                  ? () => ref.read(syncEngineProvider)?.reconnectNow()
                  : null,
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Text(
                      l.logEmpty,
                      style: context.text.bodyMedium!.copyWith(
                        color: context.delve.textMuted,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: DelveTokens.space8),
                    itemCount: entries.length,
                    itemBuilder: (context, i) => _Entry(entries[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry(this.row);

  final ConnectionLogRow row;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final kind = LogKind.parse(row.kind);
    final (StatusKind tone, IconData icon, String label) = switch (kind) {
      LogKind.connected => (StatusKind.ok, DelveIcons.ok, l.logKindConnected),
      LogKind.resync => (StatusKind.ok, DelveIcons.sync, l.logKindResync),
      LogKind.connecting => (
        StatusKind.info,
        DelveIcons.sync,
        l.logKindConnecting,
      ),
      LogKind.resumed => (StatusKind.info, DelveIcons.sync, l.logKindResumed),
      LogKind.paused => (StatusKind.info, DelveIcons.offline, l.logKindPaused),
      LogKind.closed => (
        StatusKind.warn,
        DelveIcons.syncProblem,
        l.logKindClosed,
      ),
      LogKind.backoff => (
        StatusKind.warn,
        DelveIcons.hourglass,
        l.logKindBackoff,
      ),
      LogKind.failed => (StatusKind.warn, DelveIcons.cloudOff, l.logKindFailed),
      LogKind.authFailed => (
        StatusKind.alert,
        DelveIcons.keyOff,
        l.logKindAuthFailed,
      ),
      LogKind.serverError => (
        StatusKind.alert,
        DelveIcons.error,
        l.logKindServerError,
      ),
      LogKind.protocol => (
        StatusKind.alert,
        DelveIcons.error,
        l.logKindProtocol,
      ),
      LogKind.outbox => (StatusKind.info, DelveIcons.history, l.logKindOutbox),
      LogKind.hermes => (StatusKind.info, DelveIcons.agent, l.logKindHermes),
      null => (StatusKind.info, DelveIcons.info, row.kind),
    };
    final at = row.at.toLocal();
    final now = DateTime.now();
    final sameDay =
        at.year == now.year && at.month == now.month && at.day == now.day;
    final time = DateFormat(sameDay ? 'HH:mm:ss' : 'd MMM HH:mm').format(at);
    final muted = context.colors.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DelveTokens.space4,
        vertical: DelveTokens.space2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              time,
              style: DelveText.monoSmall.copyWith(color: muted),
            ),
          ),
          SymbolIcon(
            icon,
            size: DelveTokens.iconSm,
            filled: true,
            color: context.status(tone).fg,
          ),
          const SizedBox(width: DelveTokens.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.text.bodyMedium),
                if (row.detail != null && row.detail!.isNotEmpty)
                  Text(
                    row.detail!,
                    style: DelveText.monoSmall.copyWith(color: muted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
