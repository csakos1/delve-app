import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/platform.dart';
import '../../l10n/app_localizations.dart';
import '../../terminal/desktop_clipboard.dart';
import '../../terminal/terminal_providers.dart';
import '../../terminal/terminal_service.dart';
import '../../theme/delve_theme.dart';
import 'page_scaffolds.dart';

/// Why a transfer failed, for a snackbar.
String clipboardFailureText(AppLocalizations l, ClipboardFailure f) =>
    switch (f.kind) {
      ClipboardFailureKind.noSetup => l.clipNoSetup,
      ClipboardFailureKind.phoneEmpty => l.clipPhoneEmpty,
      ClipboardFailureKind.tooLarge => l.clipTooLarge(f.detail),
      ClipboardFailureKind.unreachable => l.clipUnreachable(f.detail),
      ClipboardFailureKind.noSession => l.clipNoSession,
      ClipboardFailureKind.noTool => l.clipNoTool,
      ClipboardFailureKind.desktopEmpty => l.clipDesktopEmpty,
      ClipboardFailureKind.notText => l.clipNotText,
      ClipboardFailureKind.failed => l.clipFailed(f.detail),
    };

/// One transfer, with its outcome in a snackbar.
Future<void> runClipboard(
  BuildContext context,
  WidgetRef ref,
  ClipboardDirection direction,
) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  String text;
  try {
    final done = await ref.read(clipboardSyncProvider.notifier).run(direction);
    if (done == null) return;
    final count = done.text.runes.length;
    text = direction == ClipboardDirection.toDesktop
        ? l.clipSent(count)
        : l.clipGot(count);
  } on ClipboardFailure catch (f) {
    text = clipboardFailureText(l, f);
  }
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

/// "To desktop" and "From desktop", side by side; both rest while one runs.
class ClipboardButtons extends ConsumerWidget {
  const ClipboardButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final busy = ref.watch(clipboardSyncProvider.select((v) => v.busy));
    Widget button(
      ClipboardDirection direction,
      IconData icon,
      String label,
      String working,
    ) => Expanded(
      child: SizedBox(
        height: DelveTokens.button,
        child: OutlinedButton.icon(
          key: Key('clipboard.${direction.name}'),
          onPressed: busy == null
              ? () => unawaited(runClipboard(context, ref, direction))
              : null,
          icon: SymbolIcon(icon, size: DelveTokens.iconMd),
          // a narrow phone: the label shrinks before it wraps
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(busy == direction ? working : label),
          ),
        ),
      ),
    );
    return Row(
      children: [
        button(
          ClipboardDirection.toDesktop,
          DelveIcons.computer,
          l.clipToDesktop,
          l.clipSending,
        ),
        const SizedBox(width: DelveTokens.space2),
        button(
          ClipboardDirection.toPhone,
          DelveIcons.device,
          l.clipFromDesktop,
          l.clipGetting,
        ),
      ],
    );
  }
}

/// The Dashboard's quick row: the two buttons, once the terminal is set up
/// (they use its connection); nothing before that.
class ClipboardQuickRow extends ConsumerStatefulWidget {
  const ClipboardQuickRow({super.key});

  @override
  ConsumerState<ClipboardQuickRow> createState() => _ClipboardQuickRowState();
}

class _ClipboardQuickRowState extends ConsumerState<ClipboardQuickRow> {
  late final TerminalService _service = ref.read(terminalServiceProvider);

  @override
  void initState() {
    super.initState();
    unawaited(_service.load());
  }

  @override
  Widget build(BuildContext context) {
    // over SSH like the terminal: hidden without the desktop tools (Linux)
    final tools = ref.watch(desktopToolsProvider);
    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) {
        if (!tools || !_service.ready || !_service.config.verified) {
          return const SizedBox.shrink();
        }
        return const Padding(
          key: Key('dashboard.clipboard'),
          padding: EdgeInsets.only(bottom: DelveTokens.space4),
          child: ClipboardButtons(),
        );
      },
    );
  }
}
