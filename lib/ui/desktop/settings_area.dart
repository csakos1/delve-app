import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../screens/settings_screen.dart';
import 'areas.dart';
import 'list_area.dart';

/// The section a Settings [location] shows: `?section=`, or the section a
/// sub-page belongs to (Connection log: Server; Terminal, General chat).
@visibleForTesting
SettingsSection selectedSettingsSection(String location) {
  final uri = Uri.parse(location);
  return switch (uri.path) {
    Routes.connectionLog => SettingsSection.server,
    Routes.terminalSettings => SettingsSection.terminal,
    Routes.generalSettings => SettingsSection.general,
    _ => SettingsSection.of(uri.queryParameters['section']),
  };
}

/// Settings in the desktop layout (27W-11a): the sections in the list
/// column, one section (or one of its sub-pages) in the content; no
/// inspector.
class SettingsArea extends StatelessWidget {
  const SettingsArea({
    super.key,
    required this.location,
    required this.content,
  });

  final String location;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    final section = selectedSettingsSection(location);
    return ListArea(
      area: DesktopArea.settings.name,
      selected: section.name,
      list: SettingsNav(section: section),
      content: content,
    );
  }
}
