import 'package:flutter/material.dart';

import '../screens/persona_screen.dart';
import 'areas.dart';
import 'list_area.dart';

/// The item an About me [location] shows (`?item=`; null: the overview).
@visibleForTesting
String? selectedPersonaItem(String location) =>
    Uri.parse(location).queryParameters['item'];

/// About me in the desktop layout (27W-10): the core's sections, the topic
/// files and what is sent in the list column, one of them in the content
/// (a section or a file in its editor); no inspector.
class AboutArea extends StatelessWidget {
  const AboutArea({super.key, required this.location, required this.content});

  final String location;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    final item = selectedPersonaItem(location);
    return ListArea(
      area: DesktopArea.about.name,
      selected: item ?? 'overview',
      list: PersonaNav(item: item),
      content: content,
    );
  }
}
