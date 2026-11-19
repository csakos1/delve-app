import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../screens/schedules_screen.dart';
import '../widgets/page_scaffolds.dart';
import 'areas.dart';
import 'list_area.dart';

/// What a Schedules [location] shows: the schedule open in the content (its
/// page or its editor) and whether the content is the editor.
@visibleForTesting
({String? id, bool editing}) selectedSchedule(String location) {
  final s = Uri.parse(location).pathSegments;
  if (s.length < 3 || s[0] != 'more' || s[1] != 'schedules') {
    return (id: null, editing: false);
  }
  if (s.length == 3 && s[2] == 'new') return (id: null, editing: true);
  if (s.length == 4 && s[2] == 'edit') return (id: s[3], editing: true);
  if (s.length == 3) return (id: s[2], editing: false);
  return (id: null, editing: false);
}

/// Schedules in the desktop layout (27W-7a / 7b): the schedules with their
/// switches in the list column, the open schedule's page in the content
/// (the editor replaces it), its runs in the Runs inspector.
class SchedulesArea extends StatelessWidget {
  const SchedulesArea({
    super.key,
    required this.location,
    required this.content,
  });

  final String location;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    final (:id, :editing) = selectedSchedule(location);
    return ListArea(
      area: DesktopArea.schedules.name,
      // a new schedule's editor counts as a selection: the list overlay
      // closes for it
      selected: id ?? (editing ? 'new' : null),
      list: SchedulesScreen(selected: id),
      content: content,
      inspector: id == null || editing
          ? null
          : ScheduleRunsInspector(key: ValueKey('inspector.runs.$id'), id: id),
    );
  }
}

/// The content of Schedules while none is open.
class SchedulesPlaceholder extends StatelessWidget {
  const SchedulesPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListPlaceholder(
      key: const Key('schedules.placeholder'),
      icon: DelveIcons.schedules,
      title: l.desktopSchedulesEmpty,
      hint: l.desktopSchedulesEmptySub,
    );
  }
}
