import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../screens/watch_detail_screen.dart';
import '../screens/watches_screen.dart';
import '../widgets/page_scaffolds.dart';
import 'areas.dart';
import 'list_area.dart';

/// The watch a Watches [location] shows (null: none).
@visibleForTesting
String? selectedWatch(String location) {
  final segments = Uri.parse(location).pathSegments;
  if (segments.length == 3 &&
      segments[0] == 'more' &&
      segments[1] == 'watches') {
    return segments[2];
  }
  return null;
}

/// The listing a Watches [location] selects (`?hit=`; null: none).
@visibleForTesting
int? selectedHit(String location) =>
    int.tryParse(Uri.parse(location).queryParameters['hit'] ?? '');

/// Watches in the desktop layout (27W-9a / 9b): the watches in the list
/// column, the open watch with its listings in tabs in the content, the
/// selected listing in the Hit inspector (none without one).
class WatchesArea extends StatelessWidget {
  const WatchesArea({super.key, required this.location, required this.content});

  final String location;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    final slug = selectedWatch(location);
    final hit = slug == null ? null : selectedHit(location);
    return ListArea(
      area: DesktopArea.watches.name,
      selected: slug,
      list: WatchesScreen(selected: slug),
      content: content,
      inspector: slug == null || hit == null
          ? null
          : WatchHitInspector(
              key: ValueKey('inspector.hit.$slug.$hit'),
              slug: slug,
              id: hit,
            ),
    );
  }
}

/// The content of Watches while no watch is open.
class WatchesPlaceholder extends StatelessWidget {
  const WatchesPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListPlaceholder(
      key: const Key('watches.placeholder'),
      icon: DelveIcons.watches,
      title: l.desktopWatchesEmpty,
      hint: l.desktopWatchesEmptySub,
    );
  }
}
