import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/pairing.dart';
import '../../app/pairing_input.dart';
import '../../app/session.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/status_ui.dart';

/// 01 Pairing — server URL + one-time code (01a–e).
class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key});

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  final _url = TextEditingController();
  final _code = TextEditingController();
  final _codeFocus = FocusNode();
  Timer? _ticker;
  int _wait = 0; // seconds left of a rate limit

  @override
  void initState() {
    super.initState();
    _url.addListener(_changed);
    _code.addListener(_changed);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _url.dispose();
    _code.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  void _startCountdown(Duration wait) {
    _ticker?.cancel();
    setState(() => _wait = wait.inSeconds);
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _wait--);
      if (_wait <= 0) {
        t.cancel();
        ref.read(pairingProvider.notifier).clearRateLimit();
      }
    });
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    unawaited(ref.read(pairingProvider.notifier).submit(_url.text, _code.text));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    ref.listen(pairingProvider, (prev, next) {
      final p = next.problem;
      if (p is PairingRateLimited && prev?.problem != p) {
        _startCountdown(p.wait);
      }
    });
    final pairing = ref.watch(pairingProvider);
    final problem = pairing.problem;
    final reason = switch (ref.watch(sessionProvider)) {
      SessionUnpaired(:final reason) => reason,
      _ => null,
    };

    final urlError = switch (problem) {
      PairingBadUrl(problem: ServerUrlProblem.invalid) => l.pairUrlInvalid,
      PairingBadUrl(problem: ServerUrlProblem.notHttps) => l.pairUrlNotHttps,
      PairingBadUrl(problem: ServerUrlProblem.notTailnet) =>
        l.pairUrlNotTailnet,
      _ => null,
    };
    final codeError = problem is PairingBadCode ? l.pairCodeInvalid : null;
    final waiting = _wait > 0;
    final canPair =
        !pairing.busy &&
        !waiting &&
        _url.text.trim().isNotEmpty &&
        pairingDigits(_code.text) != null;

    final banner = switch (problem) {
      PairingRateLimited() when waiting => StatusBanner(
        kind: StatusKind.warn,
        icon: DelveIcons.hourglass,
        text: l.pairRateLimited(_wait),
      ),
      PairingUnreachable() => StatusBanner(
        kind: StatusKind.alert,
        icon: DelveIcons.offline,
        text: l.pairUnreachable,
        actionLabel: l.retry,
        onAction: canPair ? _submit : null,
      ),
      PairingServerError(:final status) => StatusBanner(
        kind: StatusKind.alert,
        icon: DelveIcons.error,
        text: l.pairFailed(l.pairFailedServer(status)),
      ),
      PairingNotDelve() => StatusBanner(
        kind: StatusKind.alert,
        icon: DelveIcons.error,
        text: l.pairFailed(l.pairFailedNotDelve),
      ),
      _ => switch (reason) {
        UnpairReason.unpaired => StatusBanner(
          kind: StatusKind.info,
          icon: DelveIcons.info,
          text: l.pairNoteUnpaired,
        ),
        UnpairReason.unpairedLocally => StatusBanner(
          kind: StatusKind.warn,
          icon: DelveIcons.unpair,
          text: l.pairNoteUnpairedLocally,
        ),
        UnpairReason.revoked => StatusBanner(
          kind: StatusKind.warn,
          icon: DelveIcons.unpair,
          text: l.pairNoteRevoked,
        ),
        null => null,
      },
    };

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            DelveTokens.space6,
            DelveTokens.space8,
            DelveTokens.space6,
            DelveTokens.space6,
          ),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.appTitle, style: context.text.displaySmall),
                const SizedBox(height: 40),
                Semantics(
                  header: true,
                  child: Text(l.pairTitle, style: context.text.headlineSmall),
                ),
                const SizedBox(height: DelveTokens.space3),
                Text(
                  l.pairIntro,
                  style: context.text.bodyLarge!.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: DelveTokens.space5),
                if (banner != null) ...[
                  banner,
                  const SizedBox(height: DelveTokens.space5),
                ],
                TextField(
                  key: const Key('pair.url'),
                  controller: _url,
                  enabled: !pairing.busy,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: context.text.bodyLarge,
                  onSubmitted: (_) => _codeFocus.requestFocus(),
                  decoration: InputDecoration(
                    labelText: l.pairServerUrl,
                    hintText: l.pairServerUrlHint,
                    helperText: urlError == null ? l.pairServerUrlHelper : null,
                    errorText: urlError,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                ),
                const SizedBox(height: DelveTokens.space5),
                TextField(
                  key: const Key('pair.code'),
                  controller: _code,
                  focusNode: _codeFocus,
                  enabled: !pairing.busy,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: const [PairingCodeFormatter()],
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  style: DelveText.mono.copyWith(
                    fontSize: context.text.bodyLarge!.fontSize,
                    color: context.colors.onSurface,
                  ),
                  onSubmitted: (_) {
                    if (canPair) _submit();
                  },
                  decoration: InputDecoration(
                    labelText: l.pairCode,
                    hintText: '0000-0000',
                    helperText: codeError == null ? l.pairCodeHelper : null,
                    error: codeError == null
                        ? null
                        : Row(
                            children: [
                              SymbolIcon(
                                DelveIcons.error,
                                size: DelveTokens.iconSm,
                                filled: true,
                                color: context.colors.error,
                              ),
                              const SizedBox(width: DelveTokens.space1),
                              Text(
                                codeError,
                                style: context.text.bodySmall!.copyWith(
                                  color: context.colors.error,
                                ),
                              ),
                            ],
                          ),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                ),
                const SizedBox(height: DelveTokens.space6),
                FilledButton(
                  key: const Key('pair.submit'),
                  onPressed: canPair ? _submit : null,
                  child: pairing.busy
                      ? SizedBox.square(
                          dimension: DelveTokens.iconMd,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.delve.textDisabled,
                          ),
                        )
                      : Text(waiting ? l.pairButtonWait(_wait) : l.pairButton),
                ),
                const SizedBox(height: DelveTokens.space4),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SymbolIcon(
                      DelveIcons.lock,
                      size: DelveTokens.iconSm,
                      color: context.delve.textMuted,
                    ),
                    const SizedBox(width: DelveTokens.space2),
                    Text(
                      l.pairFootnote,
                      style: context.text.bodyMedium!.copyWith(
                        color: context.delve.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
