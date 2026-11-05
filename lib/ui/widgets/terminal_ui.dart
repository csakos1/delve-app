import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xterm/xterm.dart';

import '../../l10n/app_localizations.dart';
import '../../terminal/phone_key.dart';
import '../../terminal/sticky_keys.dart';
import '../../terminal/terminal_connection.dart';
import '../../terminal/terminal_theme.dart';
import '../../theme/delve_theme.dart';
import 'page_scaffolds.dart';

/// The word for a connection state (tab semantics, tooltips).
String connectionWord(AppLocalizations l, TermPhase phase) => switch (phase) {
  TermPhase.live => l.termStateConnected,
  TermPhase.connecting || TermPhase.verifying => l.termStateConnecting,
  TermPhase.reconnecting => l.termStateReconnecting,
  TermPhase.refused => l.termStateRefused,
  _ => l.termStateDisconnected,
};

/// Shape and colour (design 22): filled ok = connected, warn ring =
/// connecting, outline ring = disconnected, alert square = refused.
class ConnectionDot extends StatelessWidget {
  const ConnectionDot({super.key, required this.phase});

  final TermPhase phase;

  @override
  Widget build(BuildContext context) {
    final d = context.delve;
    final ring = switch (phase) {
      TermPhase.connecting ||
      TermPhase.verifying ||
      TermPhase.reconnecting => d.warnFg,
      TermPhase.live || TermPhase.refused => null,
      _ => context.colors.outline,
    };
    if (ring != null) {
      return Container(
        key: const Key('terminal.dot.ring'),
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ring, width: 1.5),
        ),
      );
    }
    final refused = phase == TermPhase.refused;
    return Container(
      key: Key(refused ? 'terminal.dot.refused' : 'terminal.dot.live'),
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: refused ? d.alertFg : d.okFg,
        shape: refused ? BoxShape.rectangle : BoxShape.circle,
      ),
    );
  }
}

/// 22c: the line under the tab bar. Nothing while connected.
class TerminalStateLine extends StatelessWidget {
  const TerminalStateLine({super.key, required this.connection});

  final TerminalConnection connection;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = connection;
    final d = context.delve;
    final cs = context.colors;
    final target = c.target;
    final where = target == null
        ? ''
        : '${target.user}@${target.host.split('.').first}:${target.port}';

    Widget line({
      required Key key,
      required Color background,
      required IconData icon,
      required Color iconColor,
      required String text,
      Widget? right,
      Color? border,
      VoidCallback? onTap,
      double height = DelveTokens.terminalStateLine,
    }) {
      final row = Container(
        key: key,
        height: height,
        padding: const EdgeInsets.fromLTRB(14, 0, 12, 0),
        decoration: BoxDecoration(
          color: background,
          border: border == null
              ? null
              : Border(bottom: BorderSide(color: border)),
        ),
        child: Row(
          children: [
            SymbolIcon(
              icon,
              size: onTap == null ? DelveTokens.iconSm : DelveTokens.iconMd,
              filled: true,
              color: iconColor,
            ),
            const SizedBox(width: DelveTokens.space2),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    (onTap == null
                            ? context.text.labelMedium
                            : context.text.labelLarge)!
                        .copyWith(color: onTap == null ? iconColor : null),
              ),
            ),
            ?right,
          ],
        ),
      );
      return onTap == null ? row : InkWell(onTap: onTap, child: row);
    }

    final Widget child = switch (c.phase) {
      TermPhase.connecting || TermPhase.verifying => line(
        key: const Key('terminal.state.connecting'),
        background: cs.surfaceContainerLow,
        icon: DelveIcons.progress,
        iconColor: cs.onSurfaceVariant,
        text: l.termConnecting,
        right: Text(
          where,
          style: DelveText.monoSmall.copyWith(color: cs.onSurfaceVariant),
        ),
      ),
      // the first try right after a drop or coming back (T4): it runs now,
      // nothing to count down, and nothing to warn about yet
      TermPhase.reconnecting when c.attempt <= 1 => line(
        key: const Key('terminal.state.reconnecting'),
        background: cs.surfaceContainerLow,
        icon: DelveIcons.progress,
        iconColor: cs.onSurfaceVariant,
        text: l.termReconnectingNow,
        right: Text(
          where,
          style: DelveText.monoSmall.copyWith(color: cs.onSurfaceVariant),
        ),
      ),
      TermPhase.reconnecting => line(
        key: const Key('terminal.state.reconnecting'),
        background: d.warnBg,
        border: d.warnBorder,
        icon: DelveIcons.sync,
        iconColor: d.warnFg,
        text: l.termReconnecting(c.attempt),
        right: c.retryAt == null ? null : _NextIn(at: c.retryAt!),
      ),
      TermPhase.refused => line(
        key: const Key('terminal.state.refused'),
        background: d.alertBg,
        icon: DelveIcons.gppBad,
        iconColor: d.alertFg,
        text: l.termHostChangedLine,
      ),
      TermPhase.offline ||
      TermPhase.failed ||
      TermPhase.idle ||
      TermPhase.denied => line(
        key: const Key('terminal.state.offline'),
        background: d.infoBg,
        icon: DelveIcons.unpair,
        iconColor: d.infoFg,
        height: DelveTokens.terminalStateLineTappable,
        text: switch (c.offlineReason) {
          OfflineReason.sessionEnded when c.phase == TermPhase.offline =>
            l.termOfflineEnded,
          OfflineReason.background when c.phase == TermPhase.offline =>
            l.termOfflineBackground,
          _ => l.termOfflineUser,
        },
        right: SymbolIcon(DelveIcons.refresh, color: cs.onSurface),
        onTap: c.retryNow,
      ),
      TermPhase.live => const SizedBox(
        key: Key('terminal.state.none'),
        width: double.infinity,
      ),
    };
    return AnimatedSize(
      duration: DelveTokens.short,
      curve: DelveTokens.shortCurve,
      alignment: Alignment.topCenter,
      child: child,
    );
  }
}

/// "next in 4 s", ticking.
class _NextIn extends StatefulWidget {
  const _NextIn({required this.at});

  final DateTime at;

  @override
  State<_NextIn> createState() => _NextInState();
}

class _NextInState extends State<_NextIn> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final left = widget.at.difference(DateTime.now()).inMilliseconds;
    final s = (left / 1000).ceil().clamp(0, 999);
    return Text(
      s == 0 ? l.termNextNow : l.termNextIn(s),
      style: DelveText.monoSmall.copyWith(color: context.delve.warnFg),
    );
  }
}

/// 22c2: the stop panel in the recess when the host key changed. No retry.
class HostKeyChangedPanel extends StatelessWidget {
  const HostKeyChangedPanel({super.key, required this.connection});

  final TerminalConnection connection;

  Future<void> _details(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final c = connection;
    final forget = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.termHostChangedTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.termHostChangedBody, style: ctx.text.bodyMedium),
              if (c.refusedPinned case final p?) ...[
                const SizedBox(height: DelveTokens.space4),
                _FingerprintText(
                  label: l.termTrusted,
                  type: p.type,
                  fingerprint: p.fingerprint,
                ),
              ],
              if (c.refusedKey case final k?) ...[
                const SizedBox(height: DelveTokens.space3),
                _FingerprintText(
                  label: l.termReceived,
                  type: k.type,
                  fingerprint: k.fingerprint,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          OutlinedButton(
            key: const Key('terminal.forgetVerify'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ctx.delve.alertFg,
              side: BorderSide(color: ctx.delve.alertBorder),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.termForgetVerify),
          ),
        ],
      ),
    );
    if (forget ?? false) await c.forgetAndVerify();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = context.delve;
    return ColoredBox(
      key: const Key('terminal.refused'),
      color: delveTerminalTheme.background,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DelveTokens.space6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SymbolIcon(
                DelveIcons.gppBad,
                size: 40,
                filled: true,
                color: d.alertFg,
              ),
              const SizedBox(height: DelveTokens.space3),
              Text(
                l.termHostChangedTitle,
                style: context.text.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DelveTokens.space2),
              Text(
                l.termHostChangedBody,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium!.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: DelveTokens.space5),
              OutlinedButton.icon(
                key: const Key('terminal.showDetails'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: d.alertFg,
                  side: BorderSide(color: d.alertBorder),
                ),
                onPressed: () => unawaited(_details(context)),
                icon: const SymbolIcon(
                  DelveIcons.policy,
                  size: DelveTokens.iconMd,
                ),
                label: Text(l.termShowDetails),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FingerprintText extends StatelessWidget {
  const _FingerprintText({
    required this.label,
    required this.type,
    required this.fingerprint,
  });

  final String label;
  final String type;
  final String fingerprint;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '${label.toUpperCase()} · ${hostKeyTypeLabel(type)}',
        style: context.text.labelSmall!.copyWith(
          color: context.delve.textMuted,
        ),
      ),
      const SizedBox(height: DelveTokens.space1),
      SelectableText(fingerprint, style: DelveText.monoSmall),
    ],
  );
}

/// The extra key row (design 22): two pages, swiped sideways – page 1 Tab
/// Esc Ctrl Alt, the arrows and `| ~ / -`; page 2 Home End PgUp PgDn F1 F2
/// F3 F5 F10 Ins Del ⌫. Two dots show the page while swiping; the row
/// remembers its page ([page], [onPage]). Ctrl/Alt are sticky; the keys
/// never take the focus, so the keyboard stays open.
class ExtraKeys extends StatefulWidget {
  const ExtraKeys({
    super.key,
    required this.connection,
    this.page = 0,
    this.onPage,
  });

  final TerminalConnection connection;

  /// The page shown first.
  final int page;

  /// The page swiped to.
  final ValueChanged<int>? onPage;

  @override
  State<ExtraKeys> createState() => _ExtraKeysState();
}

class _ExtraKeysState extends State<ExtraKeys> {
  late final PageController _pages = PageController(
    initialPage: widget.page.clamp(0, 1),
  );
  bool _swiping = false;
  int _shown = 0;

  @override
  void initState() {
    super.initState();
    _shown = widget.page.clamp(0, 1);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    final swiping = switch (n) {
      ScrollStartNotification() || ScrollUpdateNotification() => true,
      ScrollEndNotification() => false,
      _ => _swiping,
    };
    if (swiping != _swiping) setState(() => _swiping = swiping);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final keys = widget.connection.keys;
    final term = widget.connection.terminal;
    void key(TerminalKey k) {
      unawaited(HapticFeedback.selectionClick());
      term.keyInput(k);
    }

    void char(String c) {
      unawaited(HapticFeedback.selectionClick());
      term.textInput(c);
      keys.consumed();
    }

    final cs = context.colors;
    return ListenableBuilder(
      listenable: keys,
      builder: (context, _) => DecoratedBox(
        key: const Key('terminal.extraKeys'),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          border: Border(
            top: BorderSide(
              color: cs.outlineVariant,
              width: DelveTokens.hairline,
            ),
          ),
        ),
        child: Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: PageView(
                key: const Key('terminal.extraKeys.pages'),
                controller: _pages,
                onPageChanged: (p) {
                  setState(() => _shown = p);
                  widget.onPage?.call(p);
                },
                children: [
                  Row(
                    children: [
                      // Tab first, at the thumb (T2b phone test)
                      _Key('Tab', () => key(TerminalKey.tab)),
                      _Key('Esc', () => key(TerminalKey.escape)),
                      _Key(
                        'Ctrl',
                        keys.tapCtrl,
                        sticky: keys.ctrl,
                        semantics: l.termKeyCtrl,
                      ),
                      _Key(
                        'Alt',
                        keys.tapAlt,
                        sticky: keys.alt,
                        semantics: l.termKeyAlt,
                      ),
                      _Key.icon(
                        DelveIcons.arrowBack,
                        () => key(TerminalKey.arrowLeft),
                      ),
                      _Key.icon(
                        DelveIcons.arrowDown,
                        () => key(TerminalKey.arrowDown),
                      ),
                      _Key.icon(
                        DelveIcons.arrowUp,
                        () => key(TerminalKey.arrowUp),
                      ),
                      _Key.icon(
                        DelveIcons.arrowForward,
                        () => key(TerminalKey.arrowRight),
                      ),
                      _Key('|', () => char('|'), big: true),
                      _Key('~', () => char('~'), big: true),
                      _Key('/', () => char('/'), big: true),
                      _Key('-', () => char('-'), big: true),
                    ],
                  ),
                  Row(
                    children: [
                      _Key('Home', () => key(TerminalKey.home)),
                      _Key('End', () => key(TerminalKey.end)),
                      _Key('PgUp', () => key(TerminalKey.pageUp)),
                      _Key('PgDn', () => key(TerminalKey.pageDown)),
                      _Key('F1', () => key(TerminalKey.f1)),
                      _Key('F2', () => key(TerminalKey.f2)),
                      _Key('F3', () => key(TerminalKey.f3)),
                      _Key('F5', () => key(TerminalKey.f5)),
                      _Key('F10', () => key(TerminalKey.f10)),
                      _Key('Ins', () => key(TerminalKey.insert)),
                      _Key('Del', () => key(TerminalKey.delete)),
                      _Key.icon(
                        DelveIcons.backspace,
                        () => key(TerminalKey.backspace),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // the page, while swiping (design 22-0: page dots)
            Positioned(
              left: 0,
              right: 0,
              bottom: DelveTokens.space1,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  key: const Key('terminal.extraKeys.dots'),
                  opacity: _swiping ? 1 : 0,
                  duration: DelveTokens.short,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 2; i++)
                        Container(
                          width: DelveTokens.space1,
                          height: DelveTokens.space1,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == _shown ? cs.onSurface : cs.outline,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key(
    this.label,
    this.onTap, {
    this.sticky,
    this.big = false,
    this.semantics,
  }) : icon = null;

  const _Key.icon(this.icon, this.onTap)
    : label = null,
      sticky = null,
      big = false,
      semantics = null;

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final StickyState? sticky;
  final bool big;
  final String? semantics;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final s = sticky ?? StickyState.off;
    final color = switch (s) {
      StickyState.off => cs.onSurface,
      StickyState.armed => cs.primary,
      StickyState.locked => cs.onPrimary,
    };
    final name = semantics;
    return Expanded(
      child: Semantics(
        button: true,
        label: name == null
            ? null
            : switch (s) {
                StickyState.off => name,
                StickyState.armed => l.termKeyArmed(name),
                StickyState.locked => l.termKeyLocked(name),
              },
        excludeSemantics: name != null,
        child: InkWell(
          key: ValueKey('terminal.key.${label ?? icon!.codePoint}'),
          canRequestFocus: false,
          onTap: onTap,
          child: Center(
            child: Container(
              height: DelveTokens.chip,
              constraints: const BoxConstraints(minWidth: 30),
              padding: const EdgeInsets.symmetric(horizontal: 2),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: s == StickyState.locked ? cs.primary : null,
                borderRadius: BorderRadius.circular(DelveTokens.chip),
                border: s == StickyState.armed
                    ? Border.all(color: cs.primary, width: 1.5)
                    : null,
              ),
              child: icon != null
                  ? SymbolIcon(icon!, size: 18, color: color)
                  : Text(
                      label!,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      style: DelveText.mono.copyWith(
                        color: color,
                        fontSize: big ? 15 : null,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Setup step marker state (design 22d).
enum SetupStepState { current, done, upcoming }

/// One step of the setup stepper: 24 dp marker, rail, title, content.
class SetupStep extends StatelessWidget {
  const SetupStep({
    super.key,
    required this.number,
    required this.state,
    required this.title,
    required this.children,
    this.last = false,
  });

  final int number;
  final SetupStepState state;
  final String title;
  final List<Widget> children;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final marker = switch (state) {
      SetupStepState.current => Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
        child: Text(
          '$number',
          style: context.text.labelMedium!.copyWith(color: cs.onPrimary),
        ),
      ),
      SetupStepState.done => Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: SymbolIcon(
          DelveIcons.check,
          size: DelveTokens.iconSm,
          color: cs.onPrimaryContainer,
        ),
      ),
      SetupStepState.upcoming => Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: cs.outline, width: 1.5),
        ),
        child: Text(
          '$number',
          style: context.text.labelMedium!.copyWith(color: cs.onSurfaceVariant),
        ),
      ),
    };
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              marker,
              if (!last)
                Expanded(
                  child: Container(
                    width: DelveTokens.railWidth,
                    margin: const EdgeInsets.symmetric(
                      vertical: DelveTokens.space1,
                    ),
                    color: cs.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: DelveTokens.space4),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : DelveTokens.space5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 24,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: context.text.titleSmall!.copyWith(
                          color: state == SetupStepState.upcoming
                              ? cs.onSurfaceVariant
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: DelveTokens.space2),
                  ...children,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A key line or a command in a recess, never truncated, with Copy.
class KeyWell extends StatelessWidget {
  const KeyWell({
    super.key,
    required this.label,
    required this.text,
    required this.onCopy,
  });

  final String label;
  final String text;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 36,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelSmall!.copyWith(
                    color: context.delve.textMuted,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onCopy,
                icon: const SymbolIcon(DelveIcons.copy, size: 18),
                label: Text(l.copy),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(DelveTokens.rsm),
          ),
          // the base64 is one long word: the paragraph breaks it anywhere
          child: SelectableText(text, style: DelveText.monoSmall),
        ),
      ],
    );
  }
}

/// 22e1: the desktop's host key in groups of four, to compare by eye.
class FingerprintBlock extends StatelessWidget {
  const FingerprintBlock({
    super.key,
    required this.type,
    required this.fingerprint,
    required this.onTrust,
    required this.onCancel,
  });

  final String type;
  final String fingerprint;
  final VoidCallback onTrust;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final groups = fingerprintGroups(fingerprint);
    return Column(
      key: const Key('terminal.fingerprint'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.termVerifyBody,
          style: context.text.bodyMedium!.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: DelveTokens.space3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(DelveTokens.rmd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${hostKeyTypeLabel(type)} · SHA256',
                style: context.text.labelSmall!.copyWith(
                  color: context.delve.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: DelveTokens.space2),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  for (final g in groups)
                    Text(
                      g,
                      style: DelveText.mono.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: DelveTokens.space2),
              SelectableText(
                fingerprint,
                style: DelveText.monoSmall.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: DelveTokens.space3),
        KeyWell(
          label: l.termVerifyCommand,
          text: 'ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub',
          onCopy: () => unawaited(
            Clipboard.setData(
              const ClipboardData(
                text: 'ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub',
              ),
            ),
          ),
        ),
        const SizedBox(height: DelveTokens.space3),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: DelveTokens.space2,
          children: [
            TextButton(onPressed: onCancel, child: Text(l.cancel)),
            FilledButton.icon(
              key: const Key('terminal.trust'),
              onPressed: onTrust,
              icon: const SymbolIcon(
                DelveIcons.verified,
                size: DelveTokens.iconMd,
              ),
              label: Text(l.termTrust),
            ),
          ],
        ),
      ],
    );
  }
}
