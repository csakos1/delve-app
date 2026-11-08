import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/router.dart';
import '../app/session.dart';
import 'files_providers.dart';
import 'transfer_notice.dart';

/// The transfers notification's Open (F3b): goes to the Files tab, which
/// then shows the Transfers sheet – at once while paired, otherwise once
/// the phone is paired. Also when the app was started from the
/// notification. It only listens to the notification: the Files and
/// terminal services are made when first used (the terminal takes the
/// paired host as its default, known only after the session loaded).
class TransfersHost extends ConsumerStatefulWidget {
  const TransfersHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<TransfersHost> createState() => _TransfersHostState();
}

class _TransfersHostState extends ConsumerState<TransfersHost> {
  late final TransferNotice _notice = ref.read(transferNoticeProvider);
  StreamSubscription<TransferNoticeAction>? _actions;

  /// A navigation to the Files tab is wanted.
  bool _pending = false;

  @override
  void initState() {
    super.initState();
    _actions = _notice.actions.listen((a) {
      if (a == TransferNoticeAction.open) _want();
    });
    unawaited(
      _notice.takeOpen().then((open) {
        if (open) _want();
      }),
    );
  }

  @override
  void dispose() {
    unawaited(_actions?.cancel());
    super.dispose();
  }

  void _want() {
    if (!mounted) return;
    ref.read(transfersWantedProvider).value = true;
    setState(() => _pending = true);
  }

  void _open() {
    if (!mounted) return;
    final router = ref.read(routerProvider);
    final at =
        router.routerDelegate.currentConfiguration.lastOrNull?.matchedLocation;
    // on the tab already: it shows the sheet itself
    if (at == Routes.files) return;
    router.go(Routes.files);
  }

  @override
  Widget build(BuildContext context) {
    final paired = ref.watch(sessionProvider.select((s) => s is SessionPaired));
    if (_pending && paired) {
      _pending = false;
      // no navigation during a build
      WidgetsBinding.instance.addPostFrameCallback((_) => _open());
    }
    return widget.child;
  }
}
