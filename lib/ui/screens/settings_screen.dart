import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../api/api_error.dart';
import '../../api/models/models.dart';
import '../../app/router.dart';
import '../../app/session.dart';
import '../../l10n/app_localizations.dart';
import '../../sync/connection_status.dart';
import '../../sync/sync_providers.dart';
import '../../theme/delve_theme.dart';
import '../widgets/connection_ui.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/status_ui.dart';

/// 16 Settings — server and connection, this device, thinking route,
/// versions, unpair. (Notification switches arrive with FCM after the MVP.)
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final creds = ref.watch(sessionProvider).credentials;
    if (creds == null) return const Scaffold();
    final status = ref.watch(serverStatusProvider);
    final device = ref.watch(deviceInfoProvider);
    final app = ref.watch(appInfoProvider).value;
    final mono = DelveText.mono.copyWith(
      color: context.colors.onSurfaceVariant,
    );

    String failed(Object e) =>
        l.settingsLoadFailed(e is ApiUnreachable ? l.pairUnreachable : '$e');

    String? statusText(String Function(ServerStatus s) f) => switch (status) {
      AsyncData(:final value) => f(value),
      AsyncError(:final error) => failed(error),
      _ => null,
    };

    return SubPage(
      title: l.moreSettings,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(serverStatusProvider);
          ref.invalidate(deviceInfoProvider);
          try {
            await ref.read(serverStatusProvider.future);
          } on Object {
            // shown in the rows
          }
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: DelveTokens.space8),
          children: [
            _Section(l.settingsServer),
            _Item(
              icon: DelveIcons.server,
              title: l.settingsServerUrl,
              subtitle: creds.server.toString(),
              subtitleStyle: mono,
              trailing: IconButton(
                tooltip: l.copy,
                icon: const SymbolIcon(DelveIcons.copy),
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: creds.server.toString()),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(l.copied)));
                  }
                },
              ),
            ),
            const _ConnectionRow(),
            _Section(l.settingsThisDevice),
            _Item(
              icon: DelveIcons.device,
              title: device.value?.name ?? creds.deviceName,
              subtitle: switch (device) {
                AsyncData(:final value) => l.settingsPairedSeen(
                  DateFormat('d MMM y').format(value.createdAt.toLocal()),
                  _seen(l, value.lastSeenAt),
                ),
                AsyncError(:final error) => failed(error),
                _ => null,
              },
            ),
            _Section(l.settingsThinkingRoute),
            _ThinkingRoute(status: status, failed: failed),
            _Section(l.settingsVersions),
            _Item(
              icon: DelveIcons.app,
              title: l.settingsApp,
              subtitle: app?.toString(),
              subtitleStyle: mono,
            ),
            _Item(
              icon: DelveIcons.server,
              title: l.settingsServerVersion,
              subtitle: statusText(
                (s) => s.revision == null
                    ? s.serverVersion
                    : '${s.serverVersion} · revision ${_short(s.revision!)}',
              ),
              subtitleStyle: mono,
            ),
            _Item(
              icon: DelveIcons.api,
              title: l.settingsApiRevision,
              subtitle: statusText((s) => '${s.apiRevision}'),
              subtitleStyle: mono,
            ),
            _Item(
              icon: DelveIcons.agent,
              title: l.settingsHermes,
              subtitle: statusText(
                (s) => s.hermes == 'down'
                    ? '${s.hermesVersion ?? l.settingsUnknown} · ${l.settingsHermesDown}'
                    : s.hermesVersion ?? l.settingsUnknown,
              ),
              subtitleStyle: mono,
            ),
            const SizedBox(height: DelveTokens.space6),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DelveTokens.space4,
              ),
              child: OutlinedButton.icon(
                key: const Key('settings.unpair'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.delve.alertFg,
                  side: BorderSide(color: context.delve.alertBorder),
                ),
                icon: const SymbolIcon(
                  DelveIcons.unpair,
                  size: DelveTokens.iconMd,
                ),
                label: Text(l.settingsUnpair),
                onPressed: () => _confirmUnpair(context, ref),
              ),
            ),
            const SizedBox(height: DelveTokens.space3),
            Text(
              l.settingsUnpairNote,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium!.copyWith(
                color: context.delve.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _short(String sha) =>
      sha.length > 7 ? sha.substring(0, 7) : sha;

  static String _seen(AppLocalizations l, DateTime? at) {
    if (at == null) return l.settingsSeenNever;
    final ago = DateTime.now().difference(at);
    if (ago.inMinutes < 2) return l.settingsSeenNow;
    if (ago.inMinutes < 60) return l.settingsSeenMinutes(ago.inMinutes);
    return DateFormat('d MMM, HH:mm').format(at.toLocal());
  }

  Future<void> _confirmUnpair(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.unpairDialogTitle),
        content: Text(l.unpairDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            key: const Key('unpair.confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: context.delve.alertFg,
              foregroundColor: context.colors.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.unpairDialogConfirm),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(sessionProvider.notifier).unpair();
  }
}

class _ThinkingRoute extends ConsumerWidget {
  const _ThinkingRoute({required this.status, required this.failed});

  final AsyncValue<ServerStatus> status;
  final String Function(Object) failed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    String time(DateTime? at) => at == null
        ? l.settingsUnknown
        : DateFormat('HH:mm').format(at.toLocal());

    final (
      StatusKind kind,
      IconData icon,
      String chip,
      String? detail,
    ) = switch (status) {
      AsyncData(value: ServerStatus(thinkingRoute: final r?)) when r.ok => (
        StatusKind.ok,
        DelveIcons.ok,
        l.settingsRouteOk,
        l.settingsRouteOkDetail(time(r.at)),
      ),
      AsyncData(value: ServerStatus(thinkingRoute: final r?)) => (
        StatusKind.alert,
        DelveIcons.error,
        l.settingsRouteFailed,
        l.settingsRouteFailedDetail(time(r.at)),
      ),
      AsyncData() => (
        StatusKind.info,
        DelveIcons.info,
        l.settingsRouteNone,
        l.settingsRouteNoneDetail,
      ),
      AsyncError(:final error) => (
        StatusKind.info,
        DelveIcons.info,
        l.settingsUnknown,
        failed(error),
      ),
      _ => (StatusKind.info, DelveIcons.info, l.settingsUnknown, null),
    };
    final c = context.status(kind);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Item(
          icon: DelveIcons.thinking,
          iconColor: kind == StatusKind.alert ? c.fg : null,
          title: l.settingsStatus,
          subtitle: detail,
          subtitleStyle: kind == StatusKind.alert
              ? context.text.bodyMedium!.copyWith(color: c.fg)
              : null,
          trailing: StatusChip(kind: kind, icon: icon, label: chip),
        ),
        Padding(
          // the button's own 12 dp inset puts its label on the 16 dp edge
          padding: const EdgeInsets.only(left: DelveTokens.space1),
          child: TextButton(
            onPressed: status.isLoading
                ? null
                : () => ref.invalidate(serverStatusProvider),
            child: Text(l.settingsCheckAgain),
          ),
        ),
      ],
    );
  }
}

/// Connection state; opens the connection log.
class _ConnectionRow extends ConsumerWidget {
  const _ConnectionRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final status =
        ref.watch(connectionStatusProvider).value ?? ConnectionStatus.initial;
    final view = ConnectionView.of(l, status);
    return InkWell(
      key: const Key('settings.connection'),
      onTap: () => context.push(Routes.connectionLog),
      child: _Item(
        icon: DelveIcons.log,
        title: l.settingsConnection,
        subtitle: view.text,
        trailing: StatusChip(
          kind: view.kind,
          icon: view.icon,
          label: view.chip,
        ),
      ),
    );
  }
}

/// Section eyebrow: accent, upper case, spaced.
class _Section extends StatelessWidget {
  const _Section(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      DelveTokens.space4,
      DelveTokens.space6,
      DelveTokens.space4,
      DelveTokens.space2,
    ),
    child: Semantics(
      header: true,
      child: Text(
        label.toUpperCase(),
        style: context.text.labelMedium!.copyWith(
          color: context.colors.primary,
          letterSpacing: 1.2,
        ),
      ),
    ),
  );
}

/// Settings row: 24 dp leading icon, title, secondary subtitle, trailing.
class _Item extends StatelessWidget {
  const _Item({
    required this.icon,
    required this.title,
    this.subtitle,
    this.subtitleStyle,
    this.trailing,
    this.iconColor,
  });

  final IconData icon;
  final String title;

  /// null while loading.
  final String? subtitle;
  final TextStyle? subtitleStyle;
  final Widget? trailing;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: DelveTokens.space4,
      vertical: DelveTokens.space3,
    ),
    child: Row(
      children: [
        SymbolIcon(icon, color: iconColor ?? context.colors.onSurfaceVariant),
        const SizedBox(width: DelveTokens.space6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.text.bodyLarge),
              const SizedBox(height: 2),
              Text(
                subtitle ?? '…',
                style:
                    subtitleStyle ??
                    context.text.bodyMedium!.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: DelveTokens.space2),
          trailing!,
        ],
      ],
    ),
  );
}
