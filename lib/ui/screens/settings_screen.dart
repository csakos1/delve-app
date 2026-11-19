import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../api/api_error.dart';
import '../../api/models/models.dart';
import '../../app/layout.dart';
import '../../app/news.dart';
import '../../app/platform.dart';
import '../../app/router.dart';
import '../../app/session.dart';
import '../../general/general_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../push/push_controller.dart';
import '../../push/push_providers.dart';
import '../../sync/connection_status.dart';
import '../../sync/sync_providers.dart';
import '../../terminal/terminal_providers.dart';
import '../../terminal/terminal_service.dart';
import '../../theme/delve_theme.dart';
import '../desktop/desktop_page.dart';
import '../desktop/desktop_prefs.dart';
import '../desktop/list_area.dart' show SectionRow;
import '../format.dart';
import '../general/general_format.dart';
import '../widgets/connection_ui.dart';
import '../widgets/news_ui.dart' show NewsIcons;
import '../widgets/page_scaffolds.dart';
import '../widgets/status_ui.dart';

/// The sections of Settings, in their order (the phone's eyebrows; the
/// desktop's list column, 27W-11a).
enum SettingsSection {
  server,
  device,
  notifications,
  desktopTools,
  terminal,
  general,
  thinkingRoute,
  versions;

  /// A section by its name (`?section=`); unknown: Server.
  static SettingsSection of(String? name) => values.firstWhere(
    (s) => s.name == name,
    orElse: () => SettingsSection.server,
  );

  String title(AppLocalizations l) => switch (this) {
    server => l.settingsServer,
    device => l.settingsThisDevice,
    notifications => l.settingsNotifications,
    desktopTools => l.settingsDesktopTools,
    terminal => l.settingsTerminal,
    general => l.settingsGeneralSection,
    thinkingRoute => l.settingsThinkingRoute,
    versions => l.settingsVersions,
  };

  IconData get icon => switch (this) {
    server => DelveIcons.server,
    device => DelveIcons.device,
    notifications => DelveIcons.notifications,
    desktopTools => DelveIcons.desktop,
    terminal => DelveIcons.terminal,
    general => DelveIcons.cloud,
    thinkingRoute => DelveIcons.thinking,
    versions => DelveIcons.app,
  };
}

/// The sections this app shows: Notifications where it gets them, Desktop
/// tools where Terminal and Files are a choice (and in the desktop layout,
/// which has its own settings there), Terminal once the tools are on.
List<SettingsSection> settingsSections({
  required PlatformCaps caps,
  required bool tools,
  required bool desktop,
}) => [
  for (final s in SettingsSection.values)
    if (switch (s) {
      SettingsSection.notifications => caps.notifications,
      SettingsSection.desktopTools => !caps.desktopToolsByDefault || desktop,
      SettingsSection.terminal => tools,
      _ => true,
    })
      s,
];

/// 16 Settings — server and connection, this device, notifications,
/// thinking route, versions, unpair. On the desktop (27W-11a) one [section]
/// as a page of the content; the sections are in the list column.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, this.section});

  /// The desktop: the section shown (null: Server).
  final String? section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final creds = ref.watch(sessionProvider).credentials;
    if (creds == null) return const Scaffold();
    final status = ref.watch(serverStatusProvider);
    final device = ref.watch(deviceInfoProvider);
    final app = ref.watch(appInfoProvider).value;
    final caps = ref.watch(platformCapsProvider);
    final tools = ref.watch(desktopToolsProvider);
    final desktop = DesktopLayout.of(context);
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

    final unpair = [
      const SizedBox(height: DelveTokens.space6),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: DelveTokens.space4),
        child: _maybeLeft(
          desktop: desktop,
          child: OutlinedButton.icon(
            key: const Key('settings.unpair'),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.delve.alertFg,
              side: BorderSide(color: context.delve.alertBorder),
            ),
            icon: const SymbolIcon(DelveIcons.unpair, size: DelveTokens.iconMd),
            label: Text(l.settingsUnpair),
            onPressed: () => _confirmUnpair(context, ref),
          ),
        ),
      ),
      const SizedBox(height: DelveTokens.space3),
      Padding(
        padding: EdgeInsets.symmetric(
          horizontal: desktop ? DelveTokens.space4 : 0,
        ),
        child: Text(
          l.settingsUnpairNote,
          textAlign: desktop ? TextAlign.start : TextAlign.center,
          style: context.text.bodyMedium!.copyWith(
            color: context.delve.textMuted,
          ),
        ),
      ),
    ];

    List<Widget> rowsOf(SettingsSection s) => switch (s) {
      SettingsSection.server => [
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
      ],
      SettingsSection.device => [
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
        // the desktop: unpairing is about this device
        if (desktop) ...unpair,
      ],
      // the phone (FCM) and the desktop (the socket, L3)
      SettingsSection.notifications => [_Notifications(device: device)],
      SettingsSection.desktopTools => [
        if (!caps.desktopToolsByDefault)
          _Item(
            icon: DelveIcons.terminal,
            title: l.settingsDesktopToolsRow,
            subtitle: l.settingsDesktopToolsSub,
            trailing: Switch(
              key: const Key('settings.desktopTools'),
              value: tools,
              onChanged: (on) => unawaited(
                ref.read(desktopToolsProvider.notifier).set(on: on),
              ),
            ),
          ),
        if (desktop) const _DesktopPrefsRows(),
      ],
      SettingsSection.terminal => [const _TerminalRow()],
      SettingsSection.general => [const _GeneralRow()],
      SettingsSection.thinkingRoute => [
        _ThinkingRoute(status: status, failed: failed),
      ],
      SettingsSection.versions => [
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
      ],
    };

    void reload() {
      ref
        ..invalidate(serverStatusProvider)
        ..invalidate(deviceInfoProvider);
    }

    if (desktop) {
      final shown = SettingsSection.of(section);
      return DesktopPage(
        key: Key('settings.page.${shown.name}'),
        title: shown.title(l),
        actions: [
          DesktopRefreshButton(
            buttonKey: const Key('settings.refresh'),
            onPressed: reload,
          ),
        ],
        child: DesktopPageBody(
          maxWidth: DelveDesktop.detailColumn,
          top: DelveTokens.space2,
          children: rowsOf(shown),
        ),
      );
    }

    return SubPage(
      title: l.moreSettings,
      child: RefreshIndicator(
        onRefresh: () async {
          reload();
          try {
            await ref.read(serverStatusProvider.future);
          } on Object {
            // shown in the rows
          }
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: DelveTokens.space8),
          children: [
            for (final s in settingsSections(
              caps: caps,
              tools: tools,
              desktop: false,
            )) ...[_Section(s.title(l)), ...rowsOf(s)],
            ...unpair,
          ],
        ),
      ),
    );
  }

  /// The phone: the button across the page; the desktop: at its size.
  static Widget _maybeLeft({required bool desktop, required Widget child}) =>
      desktop ? Align(alignment: Alignment.centerLeft, child: child) : child;

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

/// Notification switches (design 16): stored on the server per device
/// (`PATCH /devices/me`). A banner says when this phone or the server cannot
/// push.
class _Notifications extends ConsumerStatefulWidget {
  const _Notifications({required this.device});

  final AsyncValue<DeviceInfo> device;

  @override
  ConsumerState<_Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends ConsumerState<_Notifications> {
  /// Switches flipped but not yet confirmed by the server.
  final Map<String, bool> _pending = {};

  Future<void> _set(String key, bool value) async {
    final api = ref.read(apiProvider);
    if (api == null) return;
    setState(() => _pending[key] = value);
    try {
      await api.patchDevice(
        approvals: key == 'approvals' ? value : null,
        runDone: key == 'run_done' ? value : null,
        water: key == 'water' ? value : null,
        brief: key == 'brief' ? value : null,
        watches: key == 'watches' ? value : null,
        system: key == 'system' ? value : null,
        news: key == 'news' ? value : null,
      );
      ref.invalidate(deviceInfoProvider);
      await ref.read(deviceInfoProvider.future);
    } on Object catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.settingsNotifySaveFailed(apiErrorText(l, e))),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _pending.remove(key));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final device = widget.device.value;
    final push = ref.watch(pushStateProvider).value ?? const PushState();
    final notify = device?.notify;
    // the daily limit when News settings were opened in this run
    final newsMax = ref.watch(
      newsConfigProvider.select((c) => c.settings?.pushMax),
    );

    final Widget? banner = switch ((push, device)) {
      (PushState(available: false), _) => StatusBanner(
        kind: StatusKind.info,
        icon: DelveIcons.notificationsOff,
        text: l.settingsNotifyNoApp,
      ),
      (_, DeviceInfo(push: false)) => StatusBanner(
        kind: StatusKind.info,
        icon: DelveIcons.notificationsOff,
        text: l.settingsNotifyNoServer,
      ),
      (PushState(permitted: false), _) => StatusBanner(
        key: const Key('settings.notify.permission'),
        kind: StatusKind.warn,
        icon: DelveIcons.notificationsOff,
        text: l.settingsNotifyPermissionOff,
        actionLabel: l.settingsNotifyAllow,
        onAction: () =>
            unawaited(ref.read(pushControllerProvider)?.requestPermission()),
      ),
      _ => null,
    };

    Widget row(
      String key,
      IconData icon,
      String title,
      String subtitle,
      bool? value,
    ) {
      final on = _pending[key] ?? value ?? false;
      final canChange = value != null && !_pending.containsKey(key);
      return InkWell(
        onTap: canChange ? () => unawaited(_set(key, !on)) : null,
        child: _Item(
          icon: icon,
          title: title,
          subtitle: subtitle,
          trailing: Switch(
            key: Key('settings.notify.$key'),
            value: on,
            onChanged: canChange ? (v) => unawaited(_set(key, v)) : null,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (banner != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DelveTokens.space4,
              0,
              DelveTokens.space4,
              DelveTokens.space2,
            ),
            child: banner,
          ),
        row(
          'approvals',
          DelveIcons.approvals,
          l.settingsNotifyApprovals,
          l.settingsNotifyApprovalsSub,
          notify?.approvals,
        ),
        row(
          'run_done',
          DelveIcons.ok,
          l.settingsNotifyRunDone,
          l.settingsNotifyRunDoneSub,
          notify?.runDone,
        ),
        row(
          'water',
          DelveIcons.water,
          l.settingsNotifyWater,
          l.settingsNotifyWaterSub,
          notify?.water,
        ),
        row(
          'brief',
          DelveIcons.brief,
          l.settingsNotifyBrief,
          l.settingsNotifyBriefSub,
          notify?.brief,
        ),
        row(
          'watches',
          DelveIcons.watches,
          l.settingsNotifyWatches,
          l.settingsNotifyWatchesSub,
          notify?.watches,
        ),
        row(
          'news',
          NewsIcons.news,
          l.settingsNotifyNews,
          newsMax == null
              ? l.settingsNotifyNewsSubPlain
              : l.settingsNotifyNewsSub(newsMax),
          notify?.news,
        ),
        row(
          'system',
          DelveIcons.modelSwitch,
          l.settingsNotifySystem,
          l.settingsNotifySystemSub,
          notify?.system,
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
      onTap: () => context.open(Routes.connectionLog),
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

/// 16 → 22h: the terminal's settings, with a live summary.
class _TerminalRow extends ConsumerStatefulWidget {
  const _TerminalRow();

  @override
  ConsumerState<_TerminalRow> createState() => _TerminalRowState();
}

class _TerminalRowState extends ConsumerState<_TerminalRow> {
  late final TerminalService _service = ref.read(terminalServiceProvider);

  @override
  void initState() {
    super.initState();
    unawaited(_service.load());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) => InkWell(
        key: const Key('settings.terminal'),
        onTap: () => context.open(Routes.terminalSettings),
        child: _Item(
          icon: DelveIcons.terminal,
          title: l.settingsTerminal,
          subtitle: !_service.ready
              ? null
              : _service.keepConnected
              ? l.settingsTerminalSubOn(_service.config.port)
              : l.settingsTerminalSub(_service.config.port),
          trailing: SymbolIcon(
            DelveIcons.chevronRight,
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// 16 → 24g: the General chat's key and default model.
class _GeneralRow extends ConsumerWidget {
  const _GeneralRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final hasKey = ref.watch(generalKeyProvider).value != null;
    final id = ref.watch(generalDefaultModelProvider);
    final models = ref.watch(generalModelsProvider).value ?? const [];
    final name = modelShortName(
      id,
      models.where((m) => m.id == id).firstOrNull,
    );
    return InkWell(
      key: const Key('settings.general'),
      onTap: () => context.open(Routes.generalSettings),
      child: _Item(
        icon: DelveIcons.cloud,
        title: l.settingsGeneral,
        subtitle: hasKey ? l.settingsGeneralSub(name) : l.settingsGeneralNoKey,
        trailing: SymbolIcon(
          DelveIcons.chevronRight,
          color: context.colors.onSurfaceVariant,
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

/// Settings → Desktop tools in the desktop layout (27W-11a): Remember pane
/// widths, Open the inspector by default, Text size.
class _DesktopPrefsRows extends ConsumerWidget {
  const _DesktopPrefsRows();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final prefs = ref.watch(desktopPrefsProvider);
    final ctl = ref.read(desktopPrefsProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Item(
          icon: DelveIcons.panes,
          title: l.settingsRememberPanes,
          subtitle: l.settingsRememberPanesSub,
          trailing: Switch(
            key: const Key('settings.rememberPanes'),
            value: prefs.rememberPanes,
            onChanged: (on) => ctl.setRememberPanes(on: on),
          ),
        ),
        _Item(
          icon: DelveIcons.inspector,
          title: l.settingsInspectorDefault,
          subtitle: l.settingsInspectorDefaultSub,
          trailing: Switch(
            key: const Key('settings.inspectorDefault'),
            value: prefs.inspectorByDefault,
            onChanged: (on) => ctl.setInspectorByDefault(on: on),
          ),
        ),
        _Item(
          icon: DelveIcons.textSize,
          title: l.settingsTextSize,
          subtitle: l.settingsTextSizeSub,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DelveTokens.space4 + DelveTokens.iconLg + DelveTokens.space6,
            0,
            DelveTokens.space4,
            DelveTokens.space3,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<DesktopTextScale>(
              key: const Key('settings.textSize'),
              showSelectedIcon: false,
              segments: [
                for (final s in DesktopTextScale.values)
                  ButtonSegment(
                    value: s,
                    label: Text(switch (s.factor) {
                      null => l.settingsTextSizeSystem,
                      final f => '${(f * 100).round()} %',
                    }, key: Key('settings.textSize.${s.name}')),
                  ),
              ],
              selected: {prefs.textScale},
              onSelectionChanged: (v) => ctl.setTextScale(v.single),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: context.colors.primaryContainer,
                selectedForegroundColor: context.colors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The desktop's list column of Settings (27W-11a): every section as a
/// 32 px row; the open one selected.
class SettingsNav extends ConsumerWidget {
  const SettingsNav({super.key, required this.section});

  final SettingsSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final sections = settingsSections(
      caps: ref.watch(platformCapsProvider),
      tools: ref.watch(desktopToolsProvider),
      desktop: true,
    );
    return TopLevelPage(
      key: const Key('settings.nav'),
      title: l.moreSettings,
      background: context.colors.surfaceContainerLow,
      child: ListView(
        padding: const EdgeInsets.only(top: 2, bottom: DelveTokens.space4),
        children: [
          for (final s in sections)
            SectionRow(
              key: Key('settings.nav.${s.name}'),
              label: s.title(l),
              icon: s.icon,
              selected: s == section,
              onTap: () => context.open(Routes.settingsAt(s.name)),
            ),
        ],
      ),
    );
  }
}
