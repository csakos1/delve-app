import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../widgets/page_scaffolds.dart';

/// The floating composer: a surface-1 container (radius 24, elevation-1) with
/// the message field on top and a row of [+], the Thinking pill and
/// Send / Stop below. Send shows whenever there is text (a message
/// typed during a run is queued); otherwise Stop while a run is active.
class Composer extends StatefulWidget {
  const Composer({
    super.key,
    required this.onSend,
    this.onStop,
    this.queued = 0,
    this.leading = const [],
    this.caption,
  });

  /// Returns once the message is queued; the field clears then.
  final Future<void> Function(String text) onSend;

  /// Non-null while a run of this chat is active.
  final VoidCallback? onStop;

  /// Queued runs of this chat ("N more messages queued").
  final int queued;

  /// Controls after [+] (the Thinking pill).
  final List<Widget> leading;

  /// A short note under the row ("Applies to your next message"); fades.
  final String? caption;

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.onSend(text);
      _controller.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final d = context.delve;
    final hasText = _controller.text.trim().isNotEmpty;
    final stop = !hasText && widget.onStop != null;

    final Widget action;
    if (stop) {
      action = _RoundButton(
        key: const Key('composer.stop'),
        semantics: l.composerStop,
        icon: DelveIcons.stop,
        filledIcon: true,
        onPressed: widget.onStop,
      );
    } else {
      action = _RoundButton(
        key: const Key('composer.send'),
        semantics: l.composerSend,
        icon: DelveIcons.send,
        onPressed: hasText && !_sending ? _send : null,
      );
    }

    // edge-to-edge (main.dart): keep clear of the system navigation bar; with
    // the keyboard open the inset is 0 (the keyboard already pushes us up)
    return Padding(
      padding: EdgeInsets.fromLTRB(
        DelveTokens.space3,
        0,
        DelveTokens.space3,
        DelveTokens.space2 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.queued > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DelveTokens.space3,
                0,
                DelveTokens.space3,
                DelveTokens.space2,
              ),
              child: Row(
                children: [
                  SymbolIcon(
                    DelveIcons.scheduleSend,
                    size: DelveTokens.iconSm,
                    color: d.textMuted,
                  ),
                  const SizedBox(width: DelveTokens.space2),
                  Expanded(
                    child: Text(
                      l.composerQueued(widget.queued),
                      key: const Key('composer.queued'),
                      style: context.text.labelMedium!.copyWith(
                        color: d.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            constraints: const BoxConstraints(
              minHeight: DelveTokens.composerMin,
            ),
            padding: const EdgeInsets.all(DelveTokens.space2),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              border: Border.all(
                color: cs.outlineVariant,
                width: DelveTokens.hairline,
              ),
              borderRadius: BorderRadius.circular(DelveTokens.rxl),
              boxShadow: DelveTokens.elevation1,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const Key('composer.field'),
                  controller: _controller,
                  minLines: 1,
                  maxLines: 6,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  style: context.text.bodyLarge,
                  decoration: InputDecoration(
                    hintText: l.composerHint,
                    hintStyle: context.text.bodyLarge!.copyWith(
                      color: d.textMuted,
                    ),
                    filled: false,
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                  ),
                ),
                Row(
                  children: [
                    _RoundButton(
                      key: const Key('composer.add'),
                      semantics: l.composerAttach,
                      icon: DelveIcons.add,
                      tonal: true,
                      // attachments arrive with B6
                      onPressed: null,
                    ),
                    for (final w in widget.leading) ...[
                      const SizedBox(width: DelveTokens.space2),
                      w,
                    ],
                    const Spacer(),
                    AnimatedSwitcher(duration: DelveTokens.fast, child: action),
                  ],
                ),
                AnimatedSize(
                  duration: DelveTokens.short,
                  alignment: Alignment.topLeft,
                  child: widget.caption == null
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(
                            left: DelveTokens.touchTarget + DelveTokens.space3,
                            bottom: DelveTokens.space1,
                          ),
                          child: Text(
                            widget.caption!,
                            key: const Key('composer.caption'),
                            style: context.text.labelSmall!.copyWith(
                              color: d.textMuted,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 44 dp circle in a 48 dp hit box.
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    super.key,
    required this.semantics,
    required this.icon,
    required this.onPressed,
    this.filledIcon = false,
    this.tonal = false,
  });

  final String semantics;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool filledIcon;

  /// surface-3 instead of accent.
  final bool tonal;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final d = context.delve;
    final enabled = onPressed != null;
    final Color bg;
    final Color fg;
    if (tonal) {
      bg = cs.surfaceContainerHigh;
      fg = enabled ? cs.onSurface : d.textDisabled;
    } else if (enabled) {
      bg = cs.primary;
      fg = cs.onPrimary;
    } else {
      bg = cs.surfaceContainerHigh;
      fg = d.textDisabled;
    }
    return Semantics(
      button: true,
      enabled: enabled,
      label: semantics,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: DelveTokens.touchTarget,
        child: Center(
          child: Material(
            color: bg,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: SizedBox.square(
                dimension: DelveTokens.sendButton,
                child: Center(
                  child: SymbolIcon(
                    icon,
                    size: 22,
                    filled: filledIcon,
                    color: fg,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Thinking on/off for this conversation (h 32, radius full, 48 dp hit
/// box). ON: accent fill; OFF: 1 dp outline. Null [onChanged] disables it
/// (no server).
class ThinkingPill extends StatelessWidget {
  const ThinkingPill({super.key, required this.on, required this.onChanged});

  final bool on;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final d = context.delve;
    final enabled = onChanged != null;
    final Color fg;
    final Color bg;
    final BorderSide side;
    if (!enabled) {
      fg = d.textDisabled;
      bg = Colors.transparent;
      side = BorderSide(color: cs.outlineVariant);
    } else if (on) {
      fg = cs.onPrimary;
      bg = cs.primary;
      side = BorderSide.none;
    } else {
      fg = cs.onSurfaceVariant;
      bg = Colors.transparent;
      side = BorderSide(color: cs.outline);
    }
    return Semantics(
      toggled: on,
      enabled: enabled,
      label: l.composerThinking,
      excludeSemantics: true,
      child: SizedBox(
        height: DelveTokens.touchTarget,
        child: Center(
          child: AnimatedContainer(
            duration: DelveTokens.short,
            curve: Curves.easeOutCubic,
            height: 32,
            decoration: ShapeDecoration(
              color: bg,
              shape: StadiumBorder(side: side),
            ),
            child: Material(
              type: MaterialType.transparency,
              shape: const StadiumBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: const Key('composer.thinking'),
                onTap: enabled ? () => onChanged!(!on) : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DelveTokens.space3,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SymbolIcon(
                        DelveIcons.thinking,
                        size: 18,
                        filled: on,
                        color: fg,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l.composerThinking,
                        style: context.text.labelLarge!.copyWith(color: fg),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
