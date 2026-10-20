import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/router.dart';
import '../l10n/app_localizations.dart';
import '../ui/format.dart';
import 'push_controller.dart';
import 'push_message.dart';
import 'push_providers.dart';

/// Keeps push alive while the app runs and acts on notification taps: opens
/// the chat, and reports the answer given with Allow once.
class PushHost extends ConsumerStatefulWidget {
  const PushHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PushHost> createState() => _PushHostState();
}

class _PushHostState extends ConsumerState<PushHost> {
  late final AppLifecycleListener _lifecycle;
  StreamSubscription<PushEvent>? _sub;
  PushController? _controller;

  @override
  void initState() {
    super.initState();
    // back from the system settings: the permission may have changed
    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(_controller?.refreshPermission()),
    );
  }

  void _attach(PushController? controller) {
    if (identical(controller, _controller)) return;
    unawaited(_sub?.cancel());
    _controller = controller;
    _sub = controller?.events.listen(_onEvent);
  }

  void _onEvent(PushEvent event) {
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    final router = ref.read(routerProvider);
    final messenger = ScaffoldMessenger.maybeOf(context);
    // a chat's notification opens the chat, a card's the dashboard
    String place(PushTarget t) => switch (t.conversationId) {
      final id? => Routes.chat(id),
      null => Routes.dashboard,
    };
    switch (event) {
      case PushOpen(:final target):
        router.go(place(target));
      case PushAnswered(:final target, :final approval):
        router.go(place(target));
        final late =
            approval.status == 'late_approved' ||
            approval.status == 'followup_started';
        messenger?.showSnackBar(
          SnackBar(
            content: Text(
              late
                  ? l.approvalsLateStarted
                  : approval.status == 'denied'
                  ? l.approvalDenied
                  : l.approvalApproved,
            ),
          ),
        );
      case PushAnswerFailed(:final error):
        router.go(Routes.approvals);
        messenger?.showSnackBar(
          SnackBar(content: Text(l.approvalFailed(apiErrorText(l, error)))),
        );
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    unawaited(_sub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _attach(ref.watch(pushControllerProvider));
    return widget.child;
  }
}
