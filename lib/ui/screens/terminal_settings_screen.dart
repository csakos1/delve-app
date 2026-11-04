import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../terminal/secrets.dart';
import '../../terminal/terminal_providers.dart';
import '../../terminal/terminal_service.dart';
import '../../terminal/terminal_theme.dart';
import '../../theme/delve_theme.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/terminal_ui.dart';

/// 22h Terminal settings: from More → Settings → Terminal and from the
/// Terminal tab's ⋯ (back returns to the opener).
class TerminalSettingsScreen extends ConsumerStatefulWidget {
  const TerminalSettingsScreen({super.key});

  @override
  ConsumerState<TerminalSettingsScreen> createState() =>
      _TerminalSettingsScreenState();
}

class _TerminalSettingsScreenState
    extends ConsumerState<TerminalSettingsScreen> {
  late final TerminalService _service = ref.read(terminalServiceProvider);

  @override
  void initState() {
    super.initState();
    unawaited(_service.load());
  }

  void _snack(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _editTarget() async {
    final next = await showDialog<TerminalConfig>(
      context: context,
      builder: (_) => _TargetDialog(config: _service.config),
    );
    if (next != null) await _service.changeTarget(next);
  }

  Future<void> _showLine() async {
    final key = _service.key;
    if (key == null) return;
    final l = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            DelveTokens.space4,
            DelveTokens.space2,
            DelveTokens.space4,
            DelveTokens.space6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.termPhoneKey, style: ctx.text.titleLarge),
              const SizedBox(height: DelveTokens.space3),
              KeyWell(
                label: l.termKeyLine,
                text: key.authorizedKeysLine,
                onCopy: () => _copy(ctx, key.authorizedKeysLine),
              ),
              const SizedBox(height: DelveTokens.space3),
              KeyWell(
                label: l.termKeyCommand,
                text: key.installCommand,
                onCopy: () => _copy(ctx, key.installCommand),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext ctx, String text) async {
    final l = AppLocalizations.of(ctx);
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: text));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l.copied)));
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String action,
    required Key key,
  }) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            key: key,
            style: FilledButton.styleFrom(
              backgroundColor: ctx.delve.alertFg,
              foregroundColor: ctx.colors.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _regenerate() async {
    final l = AppLocalizations.of(context);
    final ok = await _confirm(
      title: l.termRegenerateTitle,
      body: l.termRegenerateBody,
      action: l.termRegenerateConfirm,
      key: const Key('terminalSettings.regenerate.confirm'),
    );
    if (!ok) return;
    await _service.regenerateKey();
    if (mounted) _snack(l.termRegenerated);
  }

  Future<void> _forget() async {
    final l = AppLocalizations.of(context);
    final ok = await _confirm(
      title: l.termForgetHostKey,
      body: l.termForgetHostKeyBody,
      action: l.termForgetConfirm,
      key: const Key('terminalSettings.forget.confirm'),
    );
    if (!ok) return;
    await _service.forgetHostKey();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SubPage(
      title: l.termTitle,
      child: ListenableBuilder(
        listenable: _service,
        builder: (context, _) {
          final s = _service;
          if (!s.ready) {
            return const Center(child: CircularProgressIndicator());
          }
          final config = s.config;
          final pinned = s.pinned;
          final mono = DelveText.mono.copyWith(
            color: context.colors.onSurfaceVariant,
          );
          final alert = context.delve.alertFg;
          return ListView(
            key: const Key('terminalSettings.list'),
            padding: const EdgeInsets.only(bottom: DelveTokens.space8),
            children: [
              _Section(l.termSettingsConnection),
              SwitchListTile(
                key: const Key('terminalSettings.background'),
                secondary: const SymbolIcon(DelveIcons.sync),
                title: Text(l.termBackground),
                subtitle: Text(l.termBackgroundLater),
                value: false,
                onChanged: null,
              ),
              _Row(
                key: const Key('terminalSettings.target'),
                icon: DelveIcons.server,
                title: l.termHostPort,
                subtitle: '${config.user}@${config.hostPort}',
                subtitleStyle: mono,
                onTap: _editTarget,
              ),
              _Row(
                icon: DelveIcons.lock,
                title: l.termLockRow,
                subtitle: l.termLockRowSub,
              ),
              _Section(l.termDisplay),
              _FontSize(service: s),
              _Section(l.termPhoneKey),
              _Row(
                key: const Key('terminalSettings.showLine'),
                icon: DelveIcons.key,
                title: l.termShowLine,
                subtitle: l.termShowLineSub,
                onTap: _showLine,
              ),
              _Row(
                key: const Key('terminalSettings.regenerate'),
                icon: DelveIcons.refresh,
                iconColor: alert,
                title: l.termRegenerate,
                titleColor: alert,
                subtitle: l.termRegenerateSub,
                onTap: _regenerate,
              ),
              _Section(l.termHostKey),
              _Row(
                key: const Key('terminalSettings.hostKey'),
                icon: DelveIcons.verified,
                title: pinned == null
                    ? l.termHostKeyNone
                    : pinned.trustedAt == null
                    ? l.termHostKeyTrustedUndated
                    : l.termHostKeyTrusted(
                        DateFormat('d MMM y').format(pinned.trustedAt!),
                      ),
                subtitle: pinned?.fingerprint ?? config.hostPort,
                subtitleStyle: DelveText.monoSmall.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              if (pinned != null)
                _Row(
                  key: const Key('terminalSettings.forget'),
                  icon: DelveIcons.gppBad,
                  iconColor: alert,
                  title: l.termForgetHostKey,
                  titleColor: alert,
                  subtitle: l.termForgetHostKeyBody,
                  onTap: _forget,
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Font size stepper with a live sample in the terminal palette.
class _FontSize extends StatelessWidget {
  const _FontSize({required this.service});

  final TerminalService service;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final size = service.fontSize;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DelveTokens.space4,
        vertical: DelveTokens.space3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SymbolIcon(
                DelveIcons.textSize,
                color: context.colors.onSurfaceVariant,
              ),
              const SizedBox(width: DelveTokens.space6),
              Expanded(
                child: Text(l.termFontSize, style: context.text.bodyLarge),
              ),
              IconButton.outlined(
                key: const Key('terminalSettings.fontDown'),
                tooltip: l.termFontSmaller,
                onPressed: size <= kTerminalFontMin
                    ? null
                    : () => unawaited(service.setFontSize(size - 1)),
                icon: const SymbolIcon(DelveIcons.remove, size: 20),
              ),
              SizedBox(
                width: 64,
                child: Text(
                  l.termFontSizeValue(size.round()),
                  key: const Key('terminalSettings.fontValue'),
                  textAlign: TextAlign.center,
                  style: DelveText.mono,
                ),
              ),
              IconButton.outlined(
                key: const Key('terminalSettings.fontUp'),
                tooltip: l.termFontBigger,
                onPressed: size >= kTerminalFontMax
                    ? null
                    : () => unawaited(service.setFontSize(size + 1)),
                icon: const SymbolIcon(DelveIcons.add, size: 20),
              ),
            ],
          ),
          const SizedBox(height: DelveTokens.space3),
          Container(
            padding: const EdgeInsets.all(DelveTokens.space3),
            decoration: BoxDecoration(
              color: delveTerminalTheme.background,
              borderRadius: BorderRadius.circular(DelveTokens.rsm),
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'csakos@archlinux ',
                    style: TextStyle(color: delveTerminalTheme.green),
                  ),
                  TextSpan(
                    text: '~ % ',
                    style: TextStyle(color: delveTerminalTheme.blue),
                  ),
                  TextSpan(
                    text: 'tmux ls',
                    style: TextStyle(color: delveTerminalTheme.foreground),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.clip,
              softWrap: false,
              style: DelveText.mono.copyWith(
                fontSize: size,
                height: kTerminalLineHeight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetDialog extends StatefulWidget {
  const _TargetDialog({required this.config});

  final TerminalConfig config;

  @override
  State<_TargetDialog> createState() => _TargetDialogState();
}

class _TargetDialogState extends State<_TargetDialog> {
  late final _host = TextEditingController(text: widget.config.host);
  late final _user = TextEditingController(text: widget.config.user);
  late final _port = TextEditingController(text: '${widget.config.port}');

  @override
  void dispose() {
    _host.dispose();
    _user.dispose();
    _port.dispose();
    super.dispose();
  }

  TerminalConfig? get _result {
    final port = int.tryParse(_port.text.trim());
    if (port == null || port <= 0 || port > 65535) return null;
    final c = widget.config.copyWith(
      host: _host.text.trim(),
      user: _user.text.trim(),
      port: port,
    );
    return c.complete ? c : null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final result = _result;
    return AlertDialog(
      title: Text(l.termHostPort),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('terminalSettings.dialog.host'),
            controller: _host,
            style: DelveText.mono,
            autocorrect: false,
            decoration: InputDecoration(labelText: l.termHost),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: DelveTokens.space3),
          TextField(
            key: const Key('terminalSettings.dialog.user'),
            controller: _user,
            style: DelveText.mono,
            autocorrect: false,
            decoration: InputDecoration(labelText: l.termUser),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: DelveTokens.space3),
          TextField(
            key: const Key('terminalSettings.dialog.port'),
            controller: _port,
            style: DelveText.mono,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l.termPort),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('terminalSettings.dialog.save'),
          onPressed: result == null
              ? null
              // read at press time: the text may have changed since this build
              : () => Navigator.of(context).pop(_result),
          child: Text(l.termSave),
        ),
      ],
    );
  }
}

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

class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.subtitleStyle,
    this.iconColor,
    this.titleColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final TextStyle? subtitleStyle;
  final Color? iconColor;
  final Color? titleColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
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
                Text(
                  title,
                  style: context.text.bodyLarge!.copyWith(color: titleColor),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style:
                        subtitleStyle ??
                        context.text.bodyMedium!.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null)
            SymbolIcon(
              DelveIcons.chevronRight,
              color: context.colors.onSurfaceVariant,
            ),
        ],
      ),
    );
    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }
}
