import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/router.dart';
import '../app/session.dart';
import 'share_channel.dart';

/// Opens Share to Delve when another app shares something: at once while
/// paired, otherwise once the phone is paired (the share waits).
class ShareHost extends ConsumerStatefulWidget {
  const ShareHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ShareHost> createState() => _ShareHostState();
}

class _ShareHostState extends ConsumerState<ShareHost> {
  /// A navigation to the screen is scheduled or done for the waiting share.
  bool _opening = false;

  void _open() {
    if (!mounted) return;
    final router = ref.read(routerProvider);
    final at =
        router.routerDelegate.currentConfiguration.lastOrNull?.matchedLocation;
    // already there: the screen takes the new share itself (a push does
    // not change the URL, so the top match tells, not the URI)
    if (at == Routes.share) return;
    if (at == null || Routes.gates.contains(at)) {
      router.go(Routes.share);
    } else {
      router.push(Routes.share);
    }
  }

  @override
  Widget build(BuildContext context) {
    final waiting = ref.watch(pendingShareProvider) != null;
    final paired = ref.watch(sessionProvider.select((s) => s is SessionPaired));
    if (!waiting) _opening = false;
    if (waiting && paired && !_opening) {
      _opening = true;
      // no navigation during a build; this rebuild has already scheduled the
      // frame the callback runs after
      WidgetsBinding.instance.addPostFrameCallback((_) => _open());
    }
    return widget.child;
  }
}
