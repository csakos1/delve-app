import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../terminal/desktop_clipboard.dart';
import '../../terminal/terminal_providers.dart';
import '../../terminal/terminal_service.dart';
import '../../theme/delve_theme.dart';
import '../widgets/clipboard_ui.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/status_ui.dart';
import '../widgets/system_ui.dart';

/// More → Clipboard (DA1): this phone's clipboard to the desktop and the
/// desktop's here, and the text that went last (kept in memory only).
class ClipboardScreen extends ConsumerStatefulWidget {
  const ClipboardScreen({super.key});

  @override
  ConsumerState<ClipboardScreen> createState() => _ClipboardScreenState();
}

class _ClipboardScreenState extends ConsumerState<ClipboardScreen> {
  late final TerminalService _service = ref.read(terminalServiceProvider);

  @override
  void initState() {
    super.initState();
    unawaited(_service.load());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final last = ref.watch(clipboardSyncProvider.select((v) => v.last));
    final muted = context.text.bodyMedium!.copyWith(
      color: context.delve.textMuted,
    );
    final at = last == null ? '' : DateFormat('HH:mm').format(last.at);
    final note = switch (last?.direction) {
      null => null,
      ClipboardDirection.toDesktop => l.clipLastSent(at),
      ClipboardDirection.toPhone => l.clipLastGot(at),
    };
    return SubPage(
      title: l.moreClipboard,
      child: ListView(
        padding: const EdgeInsets.all(DelveTokens.space4),
        children: [
          ListenableBuilder(
            listenable: _service,
            builder: (context, _) => !_service.ready || _service.config.verified
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(bottom: DelveTokens.space4),
                    child: StatusBanner(
                      key: const Key('clipboard.noSetup'),
                      kind: StatusKind.info,
                      icon: DelveIcons.terminal,
                      text: l.clipNoSetup,
                    ),
                  ),
          ),
          Text(l.clipHint, style: muted),
          const SizedBox(height: DelveTokens.space4),
          const ClipboardButtons(),
          const SizedBox(height: DelveTokens.space6),
          SurfaceCard(
            key: const Key('clipboard.last'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CardHeader(title: l.clipLastTitle, note: note),
                if (last == null)
                  Text(l.clipNothingYet, style: muted)
                else
                  Text(
                    last.text,
                    key: const Key('clipboard.last.text'),
                    style: DelveText.mono,
                    maxLines: 12,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
