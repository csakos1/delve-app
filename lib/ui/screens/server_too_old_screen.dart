import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/protocol.dart';
import '../../app/session.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../widgets/page_scaffolds.dart';

/// 20c — blocking: the server's contract is older than the app needs.
class ServerTooOldScreen extends ConsumerStatefulWidget {
  const ServerTooOldScreen({super.key});

  @override
  ConsumerState<ServerTooOldScreen> createState() => _ServerTooOldState();
}

class _ServerTooOldState extends ConsumerState<ServerTooOldScreen> {
  bool _checking = false;
  String? _note;

  Future<void> _check() async {
    setState(() {
      _checking = true;
      _note = null;
    });
    final err = await ref.read(sessionProvider.notifier).checkServer();
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    final s = ref.read(sessionProvider);
    setState(() {
      _checking = false;
      _note = err != null
          ? l.pairUnreachable
          : s is SessionServerTooOld
          ? l.tooOldStillOld(s.meta.apiRevision)
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider);
    if (session is! SessionServerTooOld) return const Scaffold();
    final app = ref.watch(appInfoProvider).value?.version ?? '';
    final warn = context.delve.warnFg;
    final mono = DelveText.mono.copyWith(color: context.colors.onSurface);

    Widget row(String label, String value, {Color? color}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: DelveTokens.space2),
      child: Row(
        children: [
          Text(
            label,
            style: context.text.bodyLarge!.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: DelveTokens.space4),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: color == null ? mono : mono.copyWith(color: color),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DelveTokens.space6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: SymbolIcon(
                    DelveIcons.updateServer,
                    size: 40,
                    color: warn,
                  ),
                ),
                const SizedBox(height: DelveTokens.space5),
                Semantics(
                  header: true,
                  child: Text(l.tooOldTitle, style: context.text.headlineSmall),
                ),
                const SizedBox(height: DelveTokens.space3),
                Text(
                  l.tooOldBody(app, kMinApiRevision),
                  style: context.text.bodyLarge!.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: DelveTokens.space5),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(DelveTokens.rlg),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DelveTokens.space4,
                      vertical: DelveTokens.space3,
                    ),
                    child: Column(
                      children: [
                        row(
                          l.tooOldThisApp,
                          l.tooOldNeeds(app, kMinApiRevision),
                        ),
                        row(
                          l.tooOldServer,
                          l.tooOldServerValue(
                            session.meta.serverVersion,
                            session.meta.apiRevision,
                          ),
                          color: warn,
                        ),
                        row(l.tooOldServerUrl, session.credentials.server.host),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: DelveTokens.space6),
                FilledButton.icon(
                  onPressed: _checking ? null : _check,
                  icon: const SymbolIcon(
                    DelveIcons.refresh,
                    size: DelveTokens.iconMd,
                  ),
                  label: Text(l.settingsCheckAgain),
                ),
                if (_note != null) ...[
                  const SizedBox(height: DelveTokens.space3),
                  Text(
                    _note!,
                    textAlign: TextAlign.center,
                    style: context.text.bodyMedium!.copyWith(color: warn),
                  ),
                ],
                const SizedBox(height: DelveTokens.space2),
                TextButton(
                  onPressed: _checking
                      ? null
                      : () => ref.read(sessionProvider.notifier).unpair(),
                  child: Text(l.tooOldPairOther),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
