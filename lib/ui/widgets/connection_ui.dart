import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../sync/connection_status.dart';
import 'page_scaffolds.dart';
import 'status_ui.dart';

/// How a connection state reads on screen (Settings, connection log, and the
/// offline banner of the chat list in A4).
class ConnectionView {
  const ConnectionView(this.kind, this.icon, this.chip, this.text);

  final StatusKind kind;
  final IconData icon;

  /// One word for a status chip.
  final String chip;

  /// A sentence.
  final String text;

  static ConnectionView of(AppLocalizations l, ConnectionStatus s) {
    String problem() => switch (s.problem) {
      ConnectionProblem.unreachable || null => l.connUnreachable,
      ConnectionProblem.rejected => l.connRejected,
      ConnectionProblem.helloTimeout => l.connHelloTimeout,
      ConnectionProblem.silent => l.connSilent,
      ConnectionProblem.closed => l.connClosed,
      ConnectionProblem.resyncFailed => l.connResyncFailed,
    };
    return switch (s.phase) {
      ConnectionPhase.live when s.resyncing => ConnectionView(
        StatusKind.ok,
        DelveIcons.sync,
        l.chipLive,
        l.connReloading,
      ),
      ConnectionPhase.live => ConnectionView(
        StatusKind.ok,
        DelveIcons.ok,
        l.chipLive,
        s.since == null
            ? l.connLive
            : l.connLiveSince(DateFormat('HH:mm').format(s.since!.toLocal())),
      ),
      ConnectionPhase.connecting ||
      ConnectionPhase.awaitingHello => ConnectionView(
        StatusKind.info,
        DelveIcons.sync,
        l.chipConnecting,
        s.attempt == 0
            ? l.connConnecting
            : l.connRetrying(problem(), s.attempt),
      ),
      ConnectionPhase.backoff => ConnectionView(
        StatusKind.warn,
        s.problem == ConnectionProblem.unreachable
            ? DelveIcons.cloudOff
            : DelveIcons.syncProblem,
        l.chipRetrying,
        l.connRetrying(problem(), s.attempt),
      ),
      ConnectionPhase.offline => ConnectionView(
        StatusKind.info,
        DelveIcons.offline,
        l.chipOffline,
        s.since == null ? l.connOffline : l.connPaused,
      ),
      ConnectionPhase.authFailed => ConnectionView(
        StatusKind.alert,
        DelveIcons.keyOff,
        l.chipRefused,
        l.connAuthFailed,
      ),
    };
  }
}
