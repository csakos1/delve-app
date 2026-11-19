import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../screens/news_screen.dart';
import '../screens/news_settings_screen.dart';
import '../screens/news_story_screen.dart';
import '../widgets/news_ui.dart';
import 'areas.dart';
import 'list_area.dart';

/// The story a News [location] shows (null: none).
@visibleForTesting
int? selectedStory(String location) {
  final segments = Uri.parse(location).pathSegments;
  if (segments.length == 4 &&
      segments[0] == 'more' &&
      segments[1] == 'news' &&
      segments[2] == 'story') {
    return int.tryParse(segments[3]);
  }
  return null;
}

/// News in the desktop layout (27W-5a): the list (chips, sections, the open
/// story selected) in a 360 list column, the reading view in the content,
/// the Story inspector (topic, sources, Open original, feedback). The list
/// keeps its filter while stories open; `?topic=` (Open topic) and
/// `?view=weekly` (the Dashboard's Last week) set it.
class NewsArea extends StatelessWidget {
  const NewsArea({super.key, required this.location, required this.content});

  final String location;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.parse(location);
    final id = selectedStory(location);
    return ListArea(
      area: DesktopArea.news.name,
      listDefault: DelveDesktop.listDefaultNews,
      selected: id?.toString(),
      list: NewsScreen(
        weekly: uri.queryParameters['view'] == 'weekly',
        topic: uri.queryParameters['topic'],
        selected: id,
      ),
      content: content,
      inspector: id == null
          ? null
          : NewsStoryInspector(key: ValueKey('inspector.story.$id'), id: id),
    );
  }
}

/// The content of News while no story is open.
class NewsPlaceholder extends StatelessWidget {
  const NewsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListPlaceholder(
      key: const Key('news.placeholder'),
      icon: NewsIcons.news,
      title: l.desktopNewsEmpty,
      hint: l.desktopNewsEmptySub,
    );
  }
}

/// News settings in the desktop layout (27W-5e): the sections in the list
/// column, one section (or a feed) in the content, a topic's description
/// editor in the inspector (`?topic=`).
class NewsSettingsArea extends StatelessWidget {
  const NewsSettingsArea({
    super.key,
    required this.location,
    required this.content,
  });

  final String location;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.parse(location);
    // a feed's page belongs to the Feeds section
    final section = uri.path.startsWith('${Routes.news}/feed/')
        ? NewsSettingsSection.feeds
        : NewsSettingsSection.of(uri.queryParameters['section']);
    final topic = uri.queryParameters['topic'];
    return ListArea(
      area: DesktopArea.news.name,
      listDefault: DelveDesktop.listDefaultNews,
      selected: section.name,
      list: NewsSettingsNav(section: section),
      content: content,
      inspector: section == NewsSettingsSection.topics && topic != null
          ? NewsTopicInspector(
              key: ValueKey('inspector.topic.$topic'),
              topic: topic,
            )
          : null,
    );
  }
}
