import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xterm/xterm.dart';

import '../../app/router.dart';
import '../../l10n/app_localizations.dart';
import '../../share/share_channel.dart';
import '../../terminal/secrets.dart';
import '../../terminal/terminal_connection.dart';
import '../../terminal/terminal_lock.dart';
import '../../terminal/terminal_providers.dart';
import '../../terminal/terminal_service.dart';
import '../../terminal/terminal_theme.dart';
import '../../theme/delve_theme.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/status_ui.dart';
import '../widgets/terminal_scroll.dart';
import '../widgets/terminal_selection.dart';
import '../widgets/terminal_ui.dart';

/// 22 Terminal tab: setup (22d/22e), the session with its state line (22a,
/// 22c), the biometric lock (22f). One tab in T2a; tabs come in T3.
class TerminalScreen extends ConsumerStatefulWidget {
  const TerminalScreen({super.key});

  @override
  ConsumerState<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends ConsumerState<TerminalScreen>
    with WidgetsBindingObserver {
  late final TerminalService _service = ref.read(terminalServiceProvider);
  final _focus = FocusNode(debugLabel: 'terminal');
  final _viewKey = GlobalKey<TerminalViewState>();
  final _bodyKey = GlobalKey(debugLabel: 'terminal.body');
  final _scroll = ScrollController();

  /// Space between the terminal body's bottom and the screen's bottom (the
  /// bottom navigation): the keyboard overlaps the body only by the rest.
  double _gap = 0;

  /// The keyboard overlap the terminal is laid out for. The keyboard slides
  /// in over ~250 ms and the inset changes every frame; following it would
  /// resize the pty every frame (T1), waiting for the end left the rows
  /// lagging ~0.7 s behind (T2a). So the layout jumps to where the keyboard
  /// will end, at its first frame: 0 when it starts to close, the height it
  /// had last time when it starts to open. A height not seen before is
  /// taken when the inset stops changing.
  double _layout = 0;
  double _live = 0;
  Timer? _settle;

  /// Leaving the app closes the keyboard, coming back opens it again: two
  /// resizes and two tmux redraws for nothing, each a visible jump (T2a
  /// phone test). While the app is away the layout stays as it was; on
  /// return it waits (up to [_thawAfter]) for the keyboard to come back.
  bool _frozen = false;
  Timer? _thaw;
  static const _thawAfter = Duration(milliseconds: 800);

  bool _visible = true;
  bool _imeUp = false;
  bool _restoreIme = false;
  bool _promptLock = true;
  bool _unlocking = false;
  String? _unlockProblem;

  /// Where the long press that started the selection went down.
  Offset? _pressAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_service.start());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible != _visible) {
      _visible = visible;
      if (visible) _promptLock = true;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final connection = _service.connection;
    switch (state) {
      case AppLifecycleState.resumed:
        connection.setForeground(foreground: true);
        if (!mounted) return;
        setState(() => _promptLock = true);
        final restore = _restoreIme && _visible;
        if (restore) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _showKeyboard());
        }
        _restoreIme = false;
        _thaw?.cancel();
        _thaw = Timer(restore ? _thawAfter : Duration.zero, _unfreeze);
      case AppLifecycleState.inactive:
        _restoreIme = _restoreIme || _imeUp;
        _freeze();
      case AppLifecycleState.hidden || AppLifecycleState.paused:
        _freeze();
        connection.setForeground(foreground: false);
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settle?.cancel();
    _thaw?.cancel();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _showKeyboard() {
    if (!mounted) return;
    _focus.requestFocus();
    _viewKey.currentState?.requestKeyboard();
  }

  /// A tap on the terminal: ends a selection; otherwise a click for tmux
  /// (pane focus, a program that wants the mouse) and the keyboard.
  void _tap(Offset global) {
    final c = _service.connection;
    if (c.hasSelection) {
      c.clearSelection();
      return;
    }
    final view = _viewKey.currentState;
    if (view != null) {
      final render = view.renderTerminal;
      final at = render.globalToLocal(global);
      render
        ..mouseEvent(
          TerminalMouseButton.left,
          TerminalMouseButtonState.down,
          at,
        )
        ..mouseEvent(TerminalMouseButton.left, TerminalMouseButtonState.up, at);
    }
    _showKeyboard();
  }

  /// A long press selects the word under the finger (22j3): no keyboard,
  /// nothing for tmux.
  void _selectStart(Offset global) {
    _pressAt = global;
    final c = _service.connection;
    if (selectWordAt(_viewKey.currentState, c.selection, global)) {
      unawaited(Feedback.forLongPress(context));
    }
  }

  void _selectMove(Offset global) {
    final from = _pressAt;
    if (from == null) return;
    selectWordAt(
      _viewKey.currentState,
      _service.connection.selection,
      from,
      global,
    );
  }

  Future<void> _copySelection() async {
    final c = _service.connection;
    final text = c.selectedText();
    c.clearSelection();
    if (text == null) return;
    final l = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l.termSelCopied('\n'.allMatches(text).length + 1)),
        ),
      );
  }

  /// To the Share to Delve screen's chat picker (17): the selection as a
  /// fenced code block, the cursor on an empty line above it, not sent.
  void _sendSelection() {
    final c = _service.connection;
    final text = c.selectedText();
    c.clearSelection();
    if (text == null) return;
    ref
        .read(pendingShareProvider.notifier)
        .offer(SharedPayload(text: '\n```\n$text\n```', caretAtStart: true));
  }

  /// The keyboard's overlap with the body this frame → [_layout]. Called
  /// from build: [_layout] is used by the same build.
  void _trackInset(double live, String slot) {
    final prev = _live;
    if (live == prev) return;
    _live = live;
    if (_frozen) {
      // the keyboard is back where the layout already is: nothing to do
      if (live > 0 && (live - _layout).abs() < 1) {
        _frozen = false;
        _thaw?.cancel();
      }
      return;
    }
    if (live > prev) {
      // opening (or growing): straight to its end, when it is known
      final known = _service.imeHeight(slot);
      if (prev == 0 && known != null && known > live) _layout = known;
    } else {
      // closing: straight to the bottom
      _layout = 0;
    }
    _settle?.cancel();
    _settle = Timer(_service.connection.timing.resizeSettle, () {
      if (!mounted) return;
      final end = _live;
      if (end > 0) _service.rememberImeHeight(slot, end);
      if (_layout != end) setState(() => _layout = end);
    });
  }

  void _freeze() {
    _frozen = true;
    _thaw?.cancel();
    _settle?.cancel();
  }

  /// Back, and the keyboard did not return (or was not open): the layout
  /// follows what is there now.
  void _unfreeze() {
    if (!mounted || !_frozen) return;
    setState(() {
      _frozen = false;
      _layout = _live;
    });
  }

  static String _slot(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.portrait
      ? 'portrait'
      : 'landscape';

  void _measureGap() {
    if (!mounted) return;
    final box = _bodyKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final bottom = box.localToGlobal(Offset(0, box.size.height)).dy;
    final gap = math.max(0, MediaQuery.sizeOf(context).height - bottom);
    if ((gap - _gap).abs() > 0.5) setState(() => _gap = gap.toDouble());
  }

  Future<void> _unlock() async {
    if (_unlocking) return;
    final l = AppLocalizations.of(context);
    setState(() {
      _unlocking = true;
      _unlockProblem = null;
    });
    final out = await _service.unlock(l.termUnlockReason);
    if (!mounted) return;
    setState(() {
      _unlocking = false;
      _unlockProblem = out.result == UnlockResult.failed
          ? l.termUnlockFailed(out.detail ?? '')
          : null;
    });
    if (!_service.lock.locked) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showKeyboard());
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = _service;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: ListenableBuilder(
        listenable: Listenable.merge([service, service.connection]),
        builder: (context, _) {
          final c = service.connection;
          if (!service.ready) {
            return const Center(child: CircularProgressIndicator());
          }
          final setupDone =
              service.config.verified || c.phase == TermPhase.live;
          if (!setupDone ||
              c.phase == TermPhase.denied ||
              c.phase == TermPhase.verifying) {
            return _Setup(service: service);
          }
          if (service.lock.locked) {
            if (_promptLock && _visible && !_unlocking) {
              _promptLock = false;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) unawaited(_unlock());
              });
            }
            return _Locked(
              service: service,
              busy: _unlocking,
              problem: _unlockProblem,
              onUnlock: _unlock,
            );
          }
          return _session(context, service);
        },
      ),
    );
  }

  Widget _session(BuildContext context, TerminalService service) {
    final c = service.connection;
    final live = math
        .max(0, MediaQuery.viewInsetsOf(context).bottom - _gap)
        .toDouble();
    _trackInset(live, _slot(context));
    _imeUp = live > 0 && _focus.hasFocus;
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureGap());
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TerminalTabBar(
            sessions: const [kFirstSession],
            active: 0,
            phase: c.phase,
            trailing: _Menu(service: service),
          ),
          TerminalStateLine(connection: c),
          Expanded(
            // the terminal's colour under everything: while the keyboard
            // moves, the strip between the rows and the extra keys is not
            // the page's lighter surface (T2a)
            child: ColoredBox(
              key: const Key('terminal.body'),
              color: delveTerminalTheme.background,
              child: LayoutBuilder(
                // a remembered keyboard taller than this window (split
                // screen) must not push the rows below zero
                builder: (context, box) => Stack(
                  key: _bodyKey,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      bottom:
                          math.min(
                            _layout,
                            math.max(
                              0.0,
                              box.maxHeight - 2 * DelveTokens.terminalExtraKeys,
                            ),
                          ) +
                          DelveTokens.terminalExtraKeys,
                      child: c.phase == TermPhase.refused
                          ? HostKeyChangedPanel(connection: c)
                          : _view(service),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: live,
                      height: DelveTokens.terminalExtraKeys,
                      child: ExtraKeys(connection: c),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _view(TerminalService service) {
    final c = service.connection;
    return ColoredBox(
      color: delveTerminalTheme.background,
      child: AnimatedOpacity(
        // the last screen stays, dimmed, while not connected (22c)
        opacity: c.live ? 1 : 0.5,
        duration: DelveTokens.short,
        child: Stack(
          children: [
            Positioned.fill(
              child: TerminalScrollLayer(
                key: const Key('terminal.scroll'),
                connection: c,
                viewKey: _viewKey,
                scrollController: _scroll,
                onTap: _tap,
                onLongPressStart: _selectStart,
                onLongPressMove: _selectMove,
                // every touch is the layer's: xterm's own long press opened
                // the keyboard and clicked into tmux (T2a phone test)
                child: IgnorePointer(
                  child: TerminalView(
                    c.terminal,
                    key: _viewKey,
                    controller: c.selection,
                    focusNode: _focus,
                    scrollController: _scroll,
                    theme: delveTerminalViewTheme,
                    textStyle: delveTerminalStyle(service.fontSize),
                    padding: const EdgeInsets.all(DelveTokens.terminalPadding),
                    autofocus: true,
                    deleteDetection: true,
                    // the scroll layer sends the wheel (xterm's own report
                    // is Shift+wheel, and arrow keys would page the shell
                    // history)
                    simulateScroll: false,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: TerminalSelectionLayer(
                connection: c,
                viewKey: _viewKey,
                scrollController: _scroll,
                onCopy: () => unawaited(_copySelection()),
                onSendToChat: _sendSelection,
                textStyle: delveTerminalStyle(service.fontSize),
                focusNode: _focus,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ⋯ in the tab bar: settings, disconnect / reconnect. A plain menu, so the
/// choice does not depend on the button staying mounted while it is open.
class _Menu extends StatelessWidget {
  const _Menu({required this.service});

  final TerminalService service;

  Future<void> _open(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final c = service.connection;
    final router = GoRouter.of(context);
    final box = context.findRenderObject()! as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(Offset.zero, ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    final choice = await showMenu<String>(
      context: context,
      position: position,
      items: [
        PopupMenuItem(value: 'settings', child: Text(l.termMenuSettings)),
        if (c.live)
          PopupMenuItem(value: 'disconnect', child: Text(l.termMenuDisconnect))
        else if (c.phase != TermPhase.refused)
          PopupMenuItem(value: 'reconnect', child: Text(l.termMenuReconnect)),
      ],
    );
    switch (choice) {
      case 'settings':
        unawaited(router.push(Routes.terminalSettings));
      case 'disconnect':
        unawaited(c.disconnect());
      case 'reconnect':
        c.retryNow();
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
    key: const Key('terminal.menu'),
    tooltip: AppLocalizations.of(context).termMenu,
    icon: const SymbolIcon(DelveIcons.more),
    onPressed: () => unawaited(_open(context)),
  );
}

/// 22f: nothing of the session is drawn while locked.
class _Locked extends StatelessWidget {
  const _Locked({
    required this.service,
    required this.busy,
    required this.problem,
    required this.onUnlock,
  });

  final TerminalService service;
  final bool busy;
  final String? problem;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Opacity(
            opacity: DelveTokens.disabledContent,
            child: TerminalTabBar(
              sessions: const [kFirstSession],
              active: 0,
              phase: service.connection.phase,
            ),
          ),
          Expanded(
            child: ColoredBox(
              key: const Key('terminal.locked'),
              color: delveTerminalTheme.background,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(DelveTokens.space6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SymbolIcon(
                        DelveIcons.fingerprint,
                        size: 48,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(height: DelveTokens.space4),
                      Text(
                        l.termLockTitle,
                        style: context.text.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: DelveTokens.space2),
                      Text(
                        l.termLockBody,
                        textAlign: TextAlign.center,
                        style: context.text.bodyMedium!.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      if (problem != null) ...[
                        const SizedBox(height: DelveTokens.space3),
                        Text(
                          problem!,
                          textAlign: TextAlign.center,
                          style: context.text.bodySmall!.copyWith(
                            color: context.delve.alertFg,
                          ),
                        ),
                      ],
                      const SizedBox(height: DelveTokens.space5),
                      FilledButton.tonalIcon(
                        key: const Key('terminal.unlock'),
                        onPressed: busy ? null : onUnlock,
                        icon: const SymbolIcon(
                          DelveIcons.fingerprint,
                          size: DelveTokens.iconMd,
                        ),
                        label: Text(l.termUnlock),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 22d / 22e: the phone's key, host and port, the host key to verify.
class _Setup extends StatefulWidget {
  const _Setup({required this.service});

  final TerminalService service;

  @override
  State<_Setup> createState() => _SetupState();
}

class _SetupState extends State<_Setup> {
  late final TextEditingController _host;
  late final TextEditingController _user;
  late final TextEditingController _port;
  final _scroll = ScrollController();
  TermPhase? _lastPhase;

  @override
  void initState() {
    super.initState();
    final config = widget.service.config;
    _host = TextEditingController(text: config.host);
    _user = TextEditingController(text: config.user);
    _port = TextEditingController(text: '${config.port}');
  }

  @override
  void dispose() {
    _host.dispose();
    _user.dispose();
    _port.dispose();
    _scroll.dispose();
    super.dispose();
  }

  TerminalConfig? get _config {
    final port = int.tryParse(_port.text.trim());
    final config = TerminalConfig(
      host: _host.text.trim(),
      user: _user.text.trim(),
      port: port ?? 0,
    );
    return config.complete && port != null && port < 65536 ? config : null;
  }

  void _connect() {
    final config = _config;
    if (config == null) return;
    FocusScope.of(context).unfocus();
    unawaited(widget.service.connectWith(config));
  }

  Future<void> _copy(String text) async {
    final l = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l.copied)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final service = widget.service;
    final c = service.connection;
    final key = service.key!;
    final phase = c.phase;
    final busy = phase == TermPhase.connecting;
    final verifying = phase == TermPhase.verifying;
    final question = c.question;

    // a problem shows at the top: bring it into view (Trust and Connect sit
    // at the bottom of the page)
    if (phase != _lastPhase) {
      _lastPhase = phase;
      final problem =
          phase == TermPhase.denied ||
          phase == TermPhase.failed ||
          (phase == TermPhase.idle && c.detail != null);
      if (problem) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_scroll.hasClients) return;
          unawaited(
            _scroll.animateTo(
              0,
              duration: DelveTokens.medium,
              curve: DelveTokens.standard,
            ),
          );
        });
      }
    }

    return TopLevelPage(
      title: l.termTitle,
      child: ListView(
        key: const Key('terminal.setup'),
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(
          DelveTokens.space4,
          0,
          DelveTokens.space4,
          DelveTokens.space8,
        ),
        children: [
          Text(
            l.termSetupSubtitle,
            style: context.text.labelMedium!.copyWith(
              color: context.delve.textMuted,
            ),
          ),
          const SizedBox(height: DelveTokens.space4),
          if (phase == TermPhase.denied) ...[
            _Denied(
              user: service.config.user,
              port: service.config.port,
              onCopy: () => _copy(key.authorizedKeysLine),
              onRetry: _connect,
            ),
            const SizedBox(height: DelveTokens.space4),
          ],
          if (phase == TermPhase.failed) ...[
            StatusBanner(
              key: const Key('terminal.failed'),
              kind: StatusKind.alert,
              icon: DelveIcons.cloudOff,
              text: l.termFailed(
                '${service.config.user}@${service.config.hostPort}',
                c.detail ?? '',
              ),
            ),
            const SizedBox(height: DelveTokens.space4),
          ],
          if (phase == TermPhase.idle && c.detail != null) ...[
            StatusBanner(
              kind: StatusKind.info,
              icon: DelveIcons.info,
              text: l.termNotTrusted,
            ),
            const SizedBox(height: DelveTokens.space4),
          ],
          SetupStep(
            number: 1,
            state: verifying ? SetupStepState.done : SetupStepState.current,
            title: l.termStepKey,
            children: [
              Text(l.termStepKeyBody, style: _body(context)),
              const SizedBox(height: DelveTokens.space3),
              KeyWell(
                key: const Key('terminal.keyLine'),
                label: l.termKeyLine,
                text: key.authorizedKeysLine,
                onCopy: () => _copy(key.authorizedKeysLine),
              ),
              const SizedBox(height: DelveTokens.space3),
              KeyWell(
                key: const Key('terminal.keyCommand'),
                label: l.termKeyCommand,
                text: key.installCommand,
                onCopy: () => _copy(key.installCommand),
              ),
            ],
          ),
          SetupStep(
            number: 2,
            state: verifying ? SetupStepState.done : SetupStepState.current,
            title: l.termStepHost,
            children: [
              Text(l.termStepHostBody, style: _body(context)),
              const SizedBox(height: DelveTokens.space3),
              TextField(
                key: const Key('terminal.host'),
                controller: _host,
                enabled: !busy && !verifying,
                style: DelveText.mono,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: InputDecoration(labelText: l.termHost),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: DelveTokens.space3),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      key: const Key('terminal.user'),
                      controller: _user,
                      enabled: !busy && !verifying,
                      style: DelveText.mono,
                      autocorrect: false,
                      decoration: InputDecoration(labelText: l.termUser),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: DelveTokens.space3),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      key: const Key('terminal.port'),
                      controller: _port,
                      enabled: !busy && !verifying,
                      style: DelveText.mono,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: l.termPort),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SetupStep(
            number: 3,
            state: verifying ? SetupStepState.current : SetupStepState.upcoming,
            title: l.termStepVerify,
            last: true,
            children: [
              if (verifying && question != null)
                FingerprintBlock(
                  type: question.type,
                  fingerprint: question.fingerprint,
                  onTrust: () => c.answerHostKey(trust: true),
                  onCancel: () => c.answerHostKey(trust: false),
                )
              else
                Text(l.termStepVerifyBody, style: _body(context)),
            ],
          ),
          if (!verifying) ...[
            const SizedBox(height: DelveTokens.space4),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                key: const Key('terminal.connect'),
                onPressed: busy || _config == null ? null : _connect,
                icon: busy
                    ? const SizedBox.square(
                        dimension: DelveTokens.iconMd,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const SymbolIcon(
                        DelveIcons.link,
                        size: DelveTokens.iconMd,
                      ),
                label: Text(busy ? l.termConnecting : l.termConnect),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static TextStyle _body(BuildContext context) =>
      context.text.bodyMedium!.copyWith(color: context.colors.onSurfaceVariant);
}

/// 22e2: the key was refused.
class _Denied extends StatelessWidget {
  const _Denied({
    required this.user,
    required this.port,
    required this.onCopy,
    required this.onRetry,
  });

  final String user;
  final int port;
  final VoidCallback onCopy;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final checks = [
      l.termCheckLine(user),
      l.termCheckModes,
      l.termCheckPort(port),
      l.termCheckTailnet,
    ];
    return Column(
      key: const Key('terminal.denied'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatusBanner(
          kind: StatusKind.alert,
          icon: DelveIcons.keyOff,
          text: l.termDenied,
        ),
        const SizedBox(height: DelveTokens.space3),
        for (final (i, check) in checks.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: DelveTokens.space1),
            child: Text(
              '${i + 1}. $check',
              style: context.text.bodySmall!.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        const SizedBox(height: DelveTokens.space2),
        Wrap(
          spacing: DelveTokens.space2,
          runSpacing: DelveTokens.space2,
          children: [
            FilledButton.tonal(onPressed: onCopy, child: Text(l.termCopyLine)),
            FilledButton(
              key: const Key('terminal.retry'),
              onPressed: onRetry,
              child: Text(l.termTryAgain),
            ),
          ],
        ),
      ],
    );
  }
}
