import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../mirror/mirror_controller.dart';
import '../../mirror/mirror_platform.dart';
import '../../theme/delve_theme.dart';
import '../format.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/status_ui.dart';
import '../widgets/system_ui.dart';

/// More → Mirroring (DA2b): this phone's notifications on the desktop. The
/// listener and its settings live on the Android side (MirrorPlatform); this
/// page shows whether it may and does run, the main switch, and a switch per
/// app that has posted a notification so far (nothing is chosen at first).
class MirrorScreen extends ConsumerStatefulWidget {
  const MirrorScreen({super.key});

  @override
  ConsumerState<MirrorScreen> createState() => _MirrorScreenState();
}

class _MirrorScreenState extends ConsumerState<MirrorScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // back from the system settings: the access may have changed
    _lifecycle = AppLifecycleListener(onResume: _refresh);
    unawaited(ref.read(mirrorProvider.notifier).refresh());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _refresh() {
    unawaited(ref.read(mirrorProvider.notifier).refresh());
    ref.invalidate(mirrorDeskProvider);
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _openAccess() async {
    final l = AppLocalizations.of(context);
    final opened = await ref.read(mirrorProvider.notifier).openAccess();
    if (!opened) _snack(l.mirrorSettingsFailed);
  }

  Future<void> _toggle(bool on) async {
    final l = AppLocalizations.of(context);
    final done = await ref.read(mirrorProvider.notifier).setEnabled(on: on);
    if (!done) _snack(l.mirrorEnableFailed);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final view = ref.watch(mirrorProvider);
    final s = view.state;
    return SubPage(
      title: l.mirrorTitle,
      actions: [
        IconButton(
          key: const Key('mirror.refresh'),
          tooltip: l.mirrorRefresh,
          icon: const SymbolIcon(DelveIcons.refresh),
          onPressed: _refresh,
        ),
      ],
      child: !view.loaded
          ? const Center(child: CircularProgressIndicator())
          : s == null
          ? Padding(
              padding: const EdgeInsets.all(DelveTokens.space4),
              child: Align(
                alignment: Alignment.topCenter,
                child: StatusBanner(
                  key: const Key('mirror.unavailable'),
                  kind: StatusKind.info,
                  icon: DelveIcons.info,
                  text: l.mirrorUnavailable,
                ),
              ),
            )
          : _list(context, l, s),
    );
  }

  Widget _list(BuildContext context, AppLocalizations l, MirrorState s) {
    final muted = context.text.bodyMedium!.copyWith(
      color: context.delve.textMuted,
    );
    final alert = context.delve.alertFg;
    final now = DateTime.now();
    const side = EdgeInsets.symmetric(horizontal: DelveTokens.space4);
    return ListView(
      key: const Key('mirror.list'),
      padding: const EdgeInsets.only(
        top: DelveTokens.space4,
        bottom: DelveTokens.space8,
      ),
      children: [
        Padding(
          padding: side,
          child: Text(l.mirrorHint, style: muted),
        ),
        const SizedBox(height: DelveTokens.space4),
        if (!s.granted) ...[
          Padding(
            padding: side,
            child: StatusBanner(
              key: const Key('mirror.noAccess'),
              kind: StatusKind.warn,
              icon: DelveIcons.warning,
              text: l.mirrorNoAccess,
              actionLabel: l.mirrorOpenSettings,
              onAction: () => unawaited(_openAccess()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DelveTokens.space4,
              DelveTokens.space2,
              DelveTokens.space4,
              DelveTokens.space2,
            ),
            child: Text(l.mirrorRestrictedHelp, style: muted),
          ),
        ],
        SwitchListTile(
          key: const Key('mirror.enabled'),
          secondary: const SymbolIcon(DelveIcons.notifications),
          title: Text(l.mirrorEnabled),
          subtitle: Text(l.mirrorEnabledSub),
          value: s.enabled,
          // without the access there is nothing to turn on; off always works
          onChanged: s.granted || s.enabled
              ? (on) => unawaited(_toggle(on))
              : null,
        ),
        if (s.enabled && !s.batteryExempt)
          InkWell(
            key: const Key('mirror.battery'),
            onTap: () => unawaited(
              ref.read(mirrorProvider.notifier).requestBatteryExempt(),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DelveTokens.space4,
                vertical: DelveTokens.space3,
              ),
              child: Row(
                children: [
                  SymbolIcon(DelveIcons.warning, color: alert),
                  const SizedBox(width: DelveTokens.space6),
                  Expanded(
                    child: Text(
                      l.mirrorBattery,
                      style: context.text.bodyLarge!.copyWith(color: alert),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DelveTokens.space4,
            DelveTokens.space2,
            DelveTokens.space4,
            0,
          ),
          child: SurfaceCard(
            key: const Key('mirror.status'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CardHeader(title: l.mirrorStatusTitle),
                InfoRow(
                  label: l.mirrorAccess,
                  trailing: s.granted
                      ? StatusText(kind: StatusKind.ok, label: l.mirrorAllowed)
                      : StatusText(
                          kind: StatusKind.alert,
                          label: l.mirrorNotAllowed,
                        ),
                ),
                if (s.granted)
                  InfoRow(
                    label: l.mirrorListener,
                    trailing: s.connected
                        ? StatusText(
                            kind: StatusKind.ok,
                            label: l.mirrorListenerOn,
                          )
                        : StatusText(
                            kind: StatusKind.warn,
                            label: l.mirrorListenerOff,
                          ),
                  ),
                InfoRow(
                  label: l.mirrorDesk,
                  trailing: switch (ref.watch(mirrorDeskProvider)) {
                    AsyncData(:final value) when value.desk.connected =>
                      StatusText(
                        key: const Key('mirror.desk'),
                        kind: StatusKind.ok,
                        label: l.mirrorDeskConnected,
                      ),
                    AsyncData() => StatusText(
                      key: const Key('mirror.desk'),
                      kind: StatusKind.warn,
                      label: l.mirrorDeskAway,
                    ),
                    AsyncError() => StatusText(
                      key: const Key('mirror.desk'),
                      kind: StatusKind.info,
                      label: l.mirrorDeskUnknown,
                    ),
                    _ => const StatusText(kind: StatusKind.info, label: '…'),
                  },
                ),
                switch ((s.failure, s.failAt, s.okAt)) {
                  (final failure?, final at?, _) => InfoRow(
                    key: const Key('mirror.last'),
                    label: l.mirrorLastSent,
                    value: l.mirrorLastFailed(failure, clockTime(at, now)),
                    valueColor: alert,
                  ),
                  (_, _, final at?) => InfoRow(
                    key: const Key('mirror.last'),
                    label: l.mirrorLastSent,
                    value: clockTime(at, now),
                  ),
                  _ => InfoRow(
                    key: const Key('mirror.last'),
                    label: l.mirrorLastSent,
                    value: l.mirrorNothingYet,
                  ),
                },
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DelveTokens.space4,
            DelveTokens.space6,
            DelveTokens.space4,
            DelveTokens.space2,
          ),
          child: Semantics(
            header: true,
            child: Text(
              l.mirrorApps.toUpperCase(),
              style: context.text.labelMedium!.copyWith(
                color: context.colors.primary,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        if (s.apps.isEmpty)
          Padding(
            padding: side,
            child: Text(
              l.mirrorNoApps,
              key: const Key('mirror.noApps'),
              style: muted,
            ),
          ),
        for (final app in s.apps)
          SwitchListTile(
            key: Key('mirror.app.${app.package}'),
            title: Text(app.label),
            subtitle: Text(switch (app.last) {
              final at? => l.mirrorAppLast(listTime(at, now)),
              null => app.package,
            }),
            value: app.selected,
            onChanged: (on) => unawaited(
              ref
                  .read(mirrorProvider.notifier)
                  .setSelected(app.package, on: on),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DelveTokens.space4,
            DelveTokens.space6,
            DelveTokens.space4,
            0,
          ),
          child: Text(l.mirrorCodesNote, style: muted),
        ),
      ],
    );
  }
}
