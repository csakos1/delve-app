import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/layout.dart';
import '../../attachments/composer_attachments.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../desktop/pane_focus.dart' show PaneEntry;
import '../widgets/page_scaffolds.dart';
import 'attachments.dart';

/// The floating composer: a surface-1 container (radius 24, elevation-1) with
/// the attachment chips and the message field on top and a row of [+], the
/// Thinking pill and Send / Stop below. Send shows whenever there is text or
/// an uploaded attachment (a message typed during a run is queued);
/// otherwise Stop while a run is active.
class Composer extends StatefulWidget {
  const Composer({
    super.key,
    required this.onSend,
    this.onStop,
    this.queued = 0,
    this.leading = const [],
    this.caption,
    this.attachments,
    this.onAdd,
    this.attachmentsAllowed = true,
    this.controller,
    this.hintText,
    this.sendBlocked = false,
    this.onPaste,
    this.autofocus = false,
  });

  /// The field's placeholder (General: “Message GLM 5.3…”); null: the
  /// agent's.
  final String? hintText;

  /// Nothing can be sent now (General: an answer is streaming, or a
  /// provider warning waits); Stop still shows while [onStop] is set.
  final bool sendBlocked;

  /// Returns once the message is queued; the field clears then (the caller
  /// clears [attachments]).
  final Future<void> Function(String text) onSend;

  /// The photos and files of the next message; null: none can be added.
  final ComposerAttachments? attachments;

  /// "+": asks where the next attachment comes from; null disables it.
  final VoidCallback? onAdd;

  /// Attachments are only sent over a live connection (decision 334).
  final bool attachmentsAllowed;

  /// Non-null while a run of this chat is active.
  final VoidCallback? onStop;

  /// Queued runs of this chat ("N more messages queued").
  final int queued;

  /// Controls after [+] (the Thinking pill).
  final List<Widget> leading;

  /// A short note under the row ("Applies to your next message"); fades.
  final String? caption;

  /// The message field's text, when the caller fills it (a shared link);
  /// otherwise the composer keeps its own.
  final TextEditingController? controller;

  /// The desktop's Ctrl+V in the field: true when it attached what the
  /// clipboard holds (an image, files); otherwise the field pastes the text.
  final Future<bool> Function()? onPaste;

  /// The field takes the focus when the composer appears (the desktop's new
  /// chat, Ctrl+N).
  final bool autofocus;

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  TextEditingController? _own;
  final FocusNode _focus = FocusNode(debugLabel: 'composer');
  bool _sending = false;

  TextEditingController get _controller => widget.controller ?? _own!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) _own = TextEditingController();
    _controller.addListener(_changed);
    widget.attachments?.addListener(_changed);
    // Enter from the desktop's list comes here (L2d2)
    PaneEntry.register(this, _focus);
    // a requested focus, not `autofocus`: the desktop shell holds the focus
    // already, and autofocus only takes an empty scope
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(Composer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attachments != widget.attachments) {
      oldWidget.attachments?.removeListener(_changed);
      widget.attachments?.addListener(_changed);
    }
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _own)?.removeListener(_changed);
      if (widget.controller == null) {
        _own ??= TextEditingController();
      } else {
        _own?.dispose();
        _own = null;
      }
      _controller.addListener(_changed);
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    PaneEntry.unregister(this);
    widget.attachments?.removeListener(_changed);
    widget.controller?.removeListener(_changed);
    _own?.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Text or uploaded attachments, nothing still uploading or failed, and
  /// attachments only while connected.
  bool get _canSend {
    final a = widget.attachments;
    final hasText = _controller.text.trim().isNotEmpty;
    if (a == null || a.isEmpty) return hasText;
    return !a.busy && !a.hasFailed && widget.attachmentsAllowed;
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (!_canSend || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.onSend(text);
      _controller.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Ctrl+V: what the clipboard holds is attached, or the text pasted.
  Future<void> _paste() async {
    final attached = await widget.onPaste?.call() ?? false;
    if (attached || !mounted) return;
    final focus = FocusManager.instance.primaryFocus?.context;
    if (focus == null || !focus.mounted) return;
    Actions.maybeInvoke(
      focus,
      const PasteTextIntent(SelectionChangedCause.keyboard),
    );
  }

  /// The desktop (L2b): Enter sends, Shift+Enter is a new line (the phone's
  /// Enter stays a new line; Send is the button); Ctrl+V attaches an image
  /// or files from the clipboard (L2b2).
  Widget _desktopKeys(BuildContext context, Widget field) {
    if (!DesktopLayout.of(context)) return field;
    void send() => unawaited(_send());
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): send,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): send,
        if (widget.onPaste != null)
          const SingleActivator(LogicalKeyboardKey.keyV, control: true): () =>
              unawaited(_paste()),
      },
      child: field,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    final d = context.delve;
    // the desktop's density (design 27): radius 20, “+” 32, send / stop 34,
    // 14 above the pane's bottom edge; the reading column is the margin
    final desktop = DesktopLayout.of(context);
    final attachments = widget.attachments;
    final hasContent =
        _controller.text.trim().isNotEmpty ||
        (attachments != null && !attachments.isEmpty);
    final stop = (!hasContent || widget.sendBlocked) && widget.onStop != null;
    final blocked =
        attachments != null &&
        !attachments.isEmpty &&
        !widget.attachmentsAllowed;
    final caption = blocked ? l.attachNeedsConnection : widget.caption;

    final Widget action;
    if (stop) {
      action = _RoundButton(
        key: const Key('composer.stop'),
        semantics: l.composerStop,
        icon: DelveIcons.stop,
        filledIcon: true,
        onPressed: widget.onStop,
        size: desktop ? DelveDesktop.composerSend : null,
      );
    } else {
      action = _RoundButton(
        key: const Key('composer.send'),
        semantics: l.composerSend,
        icon: DelveIcons.send,
        onPressed: _canSend && !_sending && !widget.sendBlocked ? _send : null,
        size: desktop ? DelveDesktop.composerSend : null,
      );
    }

    // edge-to-edge (main.dart): keep clear of the system navigation bar; with
    // the keyboard open the inset is 0 (the keyboard already pushes us up)
    return Padding(
      padding: desktop
          ? const EdgeInsets.only(bottom: DelveDesktop.composerBottom)
          : EdgeInsets.fromLTRB(
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
            // the desktop (L2b2): as high as its content – no empty half
            constraints: BoxConstraints(
              minHeight: desktop ? 0 : DelveTokens.composerMin,
            ),
            padding: desktop
                ? const EdgeInsets.fromLTRB(6, 4, 6, 6)
                : const EdgeInsets.all(DelveTokens.space2),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              border: Border.all(
                color: cs.outlineVariant,
                width: DelveTokens.hairline,
              ),
              borderRadius: BorderRadius.circular(
                desktop ? DelveDesktop.composerRadius : DelveTokens.rxl,
              ),
              boxShadow: DelveTokens.elevation1,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (attachments != null)
                  DraftAttachmentStrip(controller: attachments),
                _desktopKeys(
                  context,
                  TextField(
                    key: const Key('composer.field'),
                    controller: _controller,
                    focusNode: _focus,
                    minLines: 1,
                    maxLines: 6,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    style: context.text.bodyLarge,
                    decoration: InputDecoration(
                      hintText: widget.hintText ?? l.composerHint,
                      hintStyle: context.text.bodyLarge!.copyWith(
                        color: d.textMuted,
                      ),
                      filled: false,
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: desktop
                          ? const EdgeInsets.fromLTRB(10, 8, 10, 6)
                          : const EdgeInsets.fromLTRB(10, 6, 10, 8),
                    ),
                  ),
                ),
                Row(
                  // the desktop: “+”, the pill and send sit on the bottom
                  // line
                  crossAxisAlignment: desktop
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.center,
                  children: [
                    _RoundButton(
                      key: const Key('composer.add'),
                      semantics: l.composerAttach,
                      icon: DelveIcons.add,
                      tonal: true,
                      onPressed: widget.onAdd,
                      size: desktop ? DelveDesktop.composerAdd : null,
                      tooltip: desktop ? l.desktopComposerAttach : null,
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
                  child: caption == null
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: EdgeInsets.only(
                            left:
                                (desktop
                                    ? DelveDesktop.composerAdd
                                    : DelveTokens.touchTarget) +
                                DelveTokens.space3,
                            bottom: DelveTokens.space1,
                          ),
                          child: Text(
                            caption,
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

/// 44 dp circle in a 48 dp hit box; on the desktop a [size] circle that is
/// its own hit box.
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    super.key,
    required this.semantics,
    required this.icon,
    required this.onPressed,
    this.filledIcon = false,
    this.tonal = false,
    this.size,
    this.tooltip,
  });

  final String semantics;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool filledIcon;

  /// surface-3 instead of accent.
  final bool tonal;

  /// The desktop's circle (32 for “+”, 34 for send / stop); null: the
  /// phone's 44 in 48.
  final double? size;

  /// The desktop's tooltip (with the key).
  final String? tooltip;

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
    final size = this.size;
    final button = Semantics(
      button: true,
      enabled: enabled,
      label: semantics,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size ?? DelveTokens.touchTarget,
        child: Center(
          child: Material(
            color: bg,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: SizedBox.square(
                dimension: size ?? DelveTokens.sendButton,
                child: Center(
                  child: SymbolIcon(
                    icon,
                    size: size == null ? 22 : 18,
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
    final tip = tooltip;
    return tip == null ? button : Tooltip(message: tip, child: button);
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
    // the desktop: a 28 pill that is its own hit box
    final desktop = DesktopLayout.of(context);
    return Semantics(
      toggled: on,
      enabled: enabled,
      label: l.composerThinking,
      excludeSemantics: true,
      child: SizedBox(
        height: desktop ? DelveDesktop.thinkingPill : DelveTokens.touchTarget,
        child: Center(
          child: AnimatedContainer(
            duration: DelveTokens.short,
            curve: Curves.easeOutCubic,
            height: desktop ? DelveDesktop.thinkingPill : 32,
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
                        size: desktop ? 16 : 18,
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
