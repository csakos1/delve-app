import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../api/models/models.dart';
import '../../app/layout.dart';
import '../../app/news.dart';
import '../../app/platform.dart';
import '../../app/router.dart';
import '../../app/session.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/delve_theme.dart';
import '../desktop/desktop_page.dart';
import '../desktop/list_area.dart' show SectionRow;
import '../desktop/panes.dart' show InspectorFrame;
import '../format.dart';
import '../widgets/news_ui.dart';
import '../widgets/page_scaffolds.dart';
import '../widgets/status_ui.dart';

/// How many feeds the page lists before “Show all N”.
const int _feedsShown = 8;

/// The backend's limit for a topic's description (`DESCRIPTION_CHARS`).
const int kNewsDescriptionChars = 1500;

/// D3-e News settings (from the News page's gear and the Dashboard's failing
/// feeds row): the topics (drag, the glyph in the topic's colour, the
/// switch; a tap opens the description), the feeds (failing first; a tap
/// opens the feed), the digest time and the must-read push with its daily
/// limit.
class NewsSettingsScreen extends ConsumerStatefulWidget {
  const NewsSettingsScreen({super.key, this.section});

  /// The desktop (27W-5e): the one section shown (`topics`, `feeds`,
  /// `push`); the list column has the sections. Null on the phone: all.
  final String? section;

  @override
  ConsumerState<NewsSettingsScreen> createState() => _NewsSettingsScreenState();
}

class _NewsSettingsScreenState extends ConsumerState<NewsSettingsScreen> {
  /// Switches flipped but not yet confirmed (`topic.<id>`, `source.<id>`,
  /// `push`, `push_max`, `digest_at`).
  final Map<String, Object> _pending = {};
  bool _allFeeds = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_refresh(quiet: true));
    });
  }

  NewsConfigController get _config => ref.read(newsConfigProvider.notifier);

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _refresh({bool quiet = false}) async {
    final l = AppLocalizations.of(context);
    try {
      await _config.refresh();
    } on Object catch (e) {
      if (!quiet) _snack(l.newsSettingsLoadFailed(apiErrorText(l, e)));
    }
  }

  /// Runs [save] with [key] pending; a failure is reported.
  Future<void> _save(
    String key,
    Object value,
    Future<void> Function() save,
  ) async {
    final l = AppLocalizations.of(context);
    setState(() => _pending[key] = value);
    try {
      await save();
    } on Object catch (e) {
      _snack(l.newsSettingsSaveFailed(apiErrorText(l, e)));
    } finally {
      if (mounted) setState(() => _pending.remove(key));
    }
  }

  Future<void> _move(int from, int to) async {
    final l = AppLocalizations.of(context);
    try {
      await _config.moveTopic(from, to);
    } on Object catch (e) {
      _snack(l.newsSettingsSaveFailed(apiErrorText(l, e)));
    }
  }

  Future<void> _pickDigest(String current) async {
    final parts = current.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts.first) ?? 7,
        minute: int.tryParse(parts.last) ?? 0,
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    String two(int n) => n.toString().padLeft(2, '0');
    final value = '${two(picked.hour)}:${two(picked.minute)}';
    if (value == current) return;
    await _save('digest_at', value, () => _config.setSettings(digestAt: value));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final config = ref.watch(newsConfigProvider);
    final Widget body;
    if (!config.loaded) {
      final error = config.error;
      body = error == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.fromLTRB(
                DelveTokens.space4,
                UnderBarFade.height,
                DelveTokens.space4,
                0,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: StatusBanner(
                  key: const Key('newsSettings.error'),
                  kind: StatusKind.alert,
                  icon: DelveIcons.error,
                  text: l.newsSettingsLoadFailed(apiErrorText(l, error)),
                  actionLabel: l.retry,
                  onAction: _refresh,
                ),
              ),
            );
    } else {
      body = RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          key: const Key('newsSettings'),
          padding: const EdgeInsets.only(
            top: UnderBarFade.height,
            bottom: DelveTokens.space8,
          ),
          children: [
            ..._topics(l, config),
            ..._feeds(l, config),
            ..._digestAndPush(l, config.settings!),
          ],
        ),
      );
    }
    if (DesktopLayout.of(context)) return _desktop(context, l, config);
    return Scaffold(
      appBar: PageColourBar(title: l.newsSettingsTitle),
      body: UnderBarFade(child: body),
    );
  }

  /// The desktop: one section as a 680 px page under its header; a topic's
  /// description opens in the inspector (27W-5e).
  Widget _desktop(BuildContext context, AppLocalizations l, NewsConfig c) {
    final section = NewsSettingsSection.of(widget.section);
    final error = c.error;
    final Widget body;
    if (!c.loaded) {
      body = error == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(DelveDesktop.contentGutter),
              child: Align(
                alignment: Alignment.topCenter,
                child: StatusBanner(
                  key: const Key('newsSettings.error'),
                  kind: StatusKind.alert,
                  icon: DelveIcons.error,
                  text: l.newsSettingsLoadFailed(apiErrorText(l, error)),
                  actionLabel: l.retry,
                  onAction: _refresh,
                ),
              ),
            );
    } else {
      body = DesktopPageBody(
        key: const Key('newsSettings'),
        maxWidth: DelveDesktop.detailColumn,
        children: switch (section) {
          NewsSettingsSection.topics => _topics(l, c),
          NewsSettingsSection.feeds => _feeds(l, c),
          NewsSettingsSection.push => _digestAndPush(l, c.settings!),
        },
      );
    }
    return DesktopPage(
      title: section.title(l),
      inspectorToggle: true,
      child: body,
    );
  }

  List<Widget> _topics(AppLocalizations l, NewsConfig config) {
    final topics = config.topics!;
    return [
      _Section(l.newsSetTopics, note: l.newsSetTopicsNote),
      ReorderableListView(
        key: const Key('newsSettings.topics'),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        onReorder: (from, to) => unawaited(_move(from, to)),
        children: [
          for (final (i, t) in topics.indexed)
            _TopicRow(
              key: ValueKey('newsSettings.topic.${t.id}'),
              index: i,
              topic: t,
              on: (_pending['topic.${t.id}'] as bool?) ?? t.enabled,
              busy: _pending.containsKey('topic.${t.id}'),
              onSwitch: (v) => unawaited(
                _save(
                  'topic.${t.id}',
                  v,
                  () => _config.setTopicEnabled(t.id, v),
                ),
              ),
              onTap: () => DesktopLayout.of(context)
                  ? context.open(Routes.newsSettingsAt('topics', topic: t.id))
                  : unawaited(showNewsTopicEditor(context, t)),
            ),
        ],
      ),
    ];
  }

  List<Widget> _feeds(AppLocalizations l, NewsConfig config) {
    final feeds = config.feeds;
    final failing = config.failing;
    final shown = _allFeeds || feeds.length <= _feedsShown
        ? feeds
        : feeds.take(_feedsShown).toList();
    final muted = context.delve.textMuted;
    return [
      _Section(
        l.newsSetFeeds,
        note: failing == 0
            ? '${feeds.length}'
            : l.newsFeedsFailingNote(feeds.length, failing),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(
          DelveTokens.space4,
          0,
          DelveTokens.space4,
          DelveTokens.space1,
        ),
        child: Text(
          l.newsFeedsHint,
          style: context.text.bodySmall!.copyWith(color: muted),
        ),
      ),
      for (final s in shown)
        _FeedRow(
          key: Key('newsSettings.feed.${s.id}'),
          source: s,
          topicName: _topicName(config, s.topic),
          on: (_pending['source.${s.id}'] as bool?) ?? s.enabled,
          busy: _pending.containsKey('source.${s.id}'),
          onSwitch: (v) => unawaited(
            _save('source.${s.id}', v, () => _config.setSourceEnabled(s.id, v)),
          ),
          onTap: () => context.open(Routes.newsFeed(s.id)),
        ),
      if (shown.length < feeds.length)
        InkWell(
          key: const Key('newsSettings.feeds.all'),
          onTap: () => setState(() => _allFeeds = true),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: DelveTokens.space4),
            child: Row(
              children: [
                Text(
                  l.newsShowAll(feeds.length),
                  style: context.text.labelLarge!.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: DelveTokens.space1),
                SymbolIcon(NewsIcons.expand, size: 20, color: muted),
              ],
            ),
          ),
        ),
    ];
  }

  List<Widget> _digestAndPush(AppLocalizations l, NewsSettings settings) {
    final digest = (_pending['digest_at'] as String?) ?? settings.digestAt;
    final push = (_pending['push'] as bool?) ?? settings.push;
    final max = (_pending['push_max'] as int?) ?? settings.pushMax;
    final pushBusy = _pending.containsKey('push');
    final maxBusy = _pending.containsKey('push_max');
    // where this device gets pushes (the phone; the desktop since L3)
    final phoneOff =
        ref.watch(platformCapsProvider).notifications &&
        ref.watch(deviceInfoProvider).value?.notify.news == false;
    return [
      _Section(l.newsSetDigestPush),
      _Row(
        key: const Key('newsSettings.digest'),
        icon: NewsIcons.queued,
        title: l.newsDigestTime,
        subtitle: l.newsDigestTimeSub,
        onTap: _pending.containsKey('digest_at')
            ? null
            : () => unawaited(_pickDigest(settings.digestAt)),
        trailing: Text(
          digest,
          style: DelveText.mono.copyWith(color: context.colors.onSurface),
        ),
      ),
      _Row(
        icon: DelveIcons.notifications,
        title: l.newsMustReadPush,
        subtitle: l.newsMustReadPushSub(digest),
        onTap: pushBusy
            ? null
            : () => unawaited(
                _save('push', !push, () => _config.setSettings(push: !push)),
              ),
        trailing: Switch(
          key: const Key('newsSettings.push'),
          value: push,
          onChanged: pushBusy
              ? null
              : (v) => unawaited(
                  _save('push', v, () => _config.setSettings(push: v)),
                ),
        ),
      ),
      _Row(
        icon: NewsIcons.tune,
        title: l.newsPushMax,
        subtitle: l.newsPushMaxSub,
        trailing: _Stepper(
          value: max,
          min: 0,
          max: 5,
          enabled: !maxBusy,
          onChanged: (v) => unawaited(
            _save('push_max', v, () => _config.setSettings(pushMax: v)),
          ),
        ),
      ),
      if (phoneOff && push)
        Padding(
          key: const Key('newsSettings.phoneOff'),
          padding: const EdgeInsets.fromLTRB(
            DelveTokens.space4,
            DelveTokens.space1,
            DelveTokens.space4,
            0,
          ),
          child: Text(
            l.newsPushPhoneOff,
            style: context.text.bodySmall!.copyWith(
              color: context.delve.textMuted,
            ),
          ),
        ),
    ];
  }
}

/// The topic's name from the settings (also for a topic that is off).
String _topicName(NewsConfig config, String? id) =>
    config.topic(id)?.name ?? const NewsView().topicName(id);

/// Section eyebrow (accent, upper case) with a muted note on the right.
class _Section extends StatelessWidget {
  const _Section(this.label, {this.note});
  final String label;
  final String? note;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      DelveTokens.space4,
      DelveTokens.space6,
      DelveTokens.space4,
      DelveTokens.space2,
    ),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              label.toUpperCase(),
              style: context.text.labelMedium!.copyWith(
                color: context.colors.primary,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        if (note case final n?)
          Flexible(
            child: Text(
              n,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelMedium!.copyWith(
                color: context.delve.textMuted,
              ),
            ),
          ),
      ],
    ),
  );
}

/// A settings row: 24 dp icon, title, subtitle, trailing.
class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DelveTokens.space4,
        vertical: DelveTokens.space3,
      ),
      child: Row(
        children: [
          SymbolIcon(icon, color: context.colors.onSurfaceVariant),
          const SizedBox(width: DelveTokens.space6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.bodyLarge),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: context.text.bodyMedium!.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: DelveTokens.space2),
          trailing,
        ],
      ),
    ),
  );
}

/// A topic: drag handle, its glyph in its colour (disabled when off), the
/// name and its counts, the switch; a tap opens the description.
class _TopicRow extends StatelessWidget {
  const _TopicRow({
    super.key,
    required this.index,
    required this.topic,
    required this.on,
    required this.busy,
    required this.onSwitch,
    required this.onTap,
  });

  final int index;
  final NewsTopic topic;
  final bool on;
  final bool busy;
  final ValueChanged<bool> onSwitch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final style = TopicStyle.of(topic.id);
    final muted = context.delve.textMuted;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('newsSettings.topic.open.${topic.id}'),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.fromLTRB(4, 6, DelveTokens.space4, 6),
          child: Row(
            children: [
              ReorderableDragStartListener(
                key: Key('newsSettings.topic.drag.${topic.id}'),
                index: index,
                child: Tooltip(
                  message: l.newsTopicDrag(topic.name),
                  child: SizedBox.square(
                    dimension: DelveTokens.touchTarget,
                    child: Center(
                      child: SymbolIcon(
                        DelveIcons.dragIndicator,
                        size: 22,
                        color: muted,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: DelveTokens.space2),
              SymbolIcon(
                style.glyph,
                size: 22,
                color: on ? style.color : context.delve.textDisabled,
              ),
              const SizedBox(width: 6 + DelveTokens.space2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      topic.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodyLarge!.copyWith(
                        color: on ? null : muted,
                      ),
                    ),
                    Text(
                      '${l.newsTopicSources(topic.sources)} · '
                      '${l.newsTopicStories(topic.items24h)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall!.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DelveTokens.space2),
              Switch(
                key: Key('newsSettings.topic.switch.${topic.id}'),
                value: on,
                onChanged: busy ? null : onSwitch,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// D3-e2: a topic's description in a sheet (the tile, the name, its counts,
/// the switch; “What you care about”; Cancel / Save). Saves on the server
/// and closes; a failure stays in the sheet.
Future<void> showNewsTopicEditor(BuildContext context, NewsTopic topic) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _TopicEditor(topic: topic),
    );

/// The desktop's Topic inspector (27W-5e): the description editor of
/// [topic] (the phone's sheet); Save and Cancel go back to the topics.
class NewsTopicInspector extends ConsumerWidget {
  const NewsTopicInspector({super.key, required this.topic});

  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = ref.watch(newsConfigProvider).topic(topic);
    return InspectorFrame(
      key: const Key('inspector.topic'),
      label: l.newsTopicTab,
      child: t == null
          ? const SizedBox.shrink()
          : _TopicEditor(key: ValueKey(t.id), topic: t, embedded: true),
    );
  }
}

class _TopicEditor extends ConsumerStatefulWidget {
  const _TopicEditor({super.key, required this.topic, this.embedded = false});
  final NewsTopic topic;

  /// In the desktop's inspector: done goes back to the topics.
  final bool embedded;

  @override
  ConsumerState<_TopicEditor> createState() => _TopicEditorState();
}

class _TopicEditorState extends ConsumerState<_TopicEditor> {
  late final TextEditingController _text = TextEditingController(
    text: widget.topic.description,
  );
  late bool _on = widget.topic.enabled;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final t = widget.topic;
    final description = _text.text.trim();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(newsConfigProvider.notifier)
          .saveTopic(
            t.id,
            description: description == t.description ? null : description,
            enabled: _on == t.enabled ? null : _on,
          );
      if (mounted) _done();
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = l.newsSettingsSaveFailed(apiErrorText(l, e));
        });
      }
    }
  }

  /// Closes the sheet, or the inspector's editor.
  void _done() => widget.embedded
      ? context.open(Routes.newsSettingsAt('topics'))
      : Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = widget.topic;
    final style = TopicStyle.of(t.id);
    final muted = context.delve.textMuted;
    return Padding(
      key: const Key('newsSettings.editor'),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: widget.embedded
            ? const EdgeInsets.fromLTRB(12, 4, 12, 12)
            : const EdgeInsets.fromLTRB(
                DelveTokens.space5,
                DelveTokens.space2,
                DelveTokens.space5,
                DelveTokens.space5,
              ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: style.tile,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: SymbolIcon(style.glyph, size: 20, color: style.color),
                ),
                const SizedBox(width: DelveTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleLarge,
                      ),
                      Text(
                        '${l.newsTopicSources(t.sources)} · '
                        '${l.newsTopicStories(t.items24h)}',
                        style: context.text.labelMedium!.copyWith(color: muted),
                      ),
                    ],
                  ),
                ),
                Switch(
                  key: const Key('newsSettings.editor.switch'),
                  value: _on,
                  onChanged: _saving ? null : (v) => setState(() => _on = v),
                ),
              ],
            ),
            const SizedBox(height: DelveTokens.space4),
            TextField(
              key: const Key('newsSettings.editor.text'),
              controller: _text,
              enabled: !_saving,
              minLines: 4,
              maxLines: 10,
              maxLength: kNewsDescriptionChars,
              buildCounter:
                  (
                    _, {
                    required currentLength,
                    required isFocused,
                    required maxLength,
                  }) => null,
              style: context.text.bodyLarge,
              decoration: InputDecoration(
                labelText: l.newsTopicEditorLabel,
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: DelveTokens.space2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    l.newsTopicEditorNote,
                    style: context.text.bodySmall!.copyWith(color: muted),
                  ),
                ),
                const SizedBox(width: DelveTokens.space3),
                Text(
                  '${_text.text.length} / $kNewsDescriptionChars',
                  key: const Key('newsSettings.editor.count'),
                  style: DelveText.monoSmall.copyWith(color: muted),
                ),
              ],
            ),
            if (_error case final e?) ...[
              const SizedBox(height: DelveTokens.space2),
              Text(
                e,
                key: const Key('newsSettings.editor.error'),
                style: context.text.bodySmall!.copyWith(
                  color: context.delve.alertFg,
                ),
              ),
            ],
            const SizedBox(height: DelveTokens.space4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  key: const Key('newsSettings.editor.cancel'),
                  onPressed: _saving ? null : _done,
                  child: Text(l.cancel),
                ),
                const SizedBox(width: DelveTokens.space2),
                FilledButton(
                  key: const Key('newsSettings.editor.save'),
                  onPressed: _saving ? null : () => unawaited(_save()),
                  child: Text(l.newsTopicSave),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A feed's address without the scheme (`www.sail-world.com/rss`).
String newsFeedAddress(String url) =>
    url.replaceFirst(RegExp('^https?://'), '');

/// RSS, Google News or Releases.
String _kind(AppLocalizations l, NewsSource s) {
  if (s.kind == 'release') return l.newsFeedKindReleases;
  if (newsHost(s.url) == 'news.google.com') return l.newsFeedKindGoogle;
  return l.newsFeedKindFeed;
}

/// A time near now: `HH:mm` today, `EEE HH:mm` within the week, else the
/// date with the time.
String _when(DateTime at, DateTime now) => now.difference(at).inDays < 6
    ? clockTime(at, now)
    : DateFormat('d MMM HH:mm').format(at.toLocal());

/// The status of a feed's last round: icon, colour, word.
(IconData, Color, String) _status(BuildContext context, NewsSource s) {
  final l = AppLocalizations.of(context);
  final d = context.delve;
  return switch (s.lastStatus) {
    'ok' => (DelveIcons.ok, d.okFg, l.newsFeedStatusOk),
    'not_modified' => (DelveIcons.check, d.infoFg, l.newsFeedStatusNotModified),
    'skipped' => (DelveIcons.onHold, d.infoFg, l.newsFeedStatusSkipped),
    'error' => (DelveIcons.error, d.alertFg, l.newsFeedStatusError),
    _ => (DelveIcons.schedule, d.textMuted, l.newsFeedStatusNever),
  };
}

/// What went wrong after “error”: “HTTP 404 · 5 in a row”.
String _errorDetail(AppLocalizations l, NewsSource s) => [
  if (s.lastHttp case final h?) 'HTTP $h' else ?s.lastErrorCode,
  if (s.errorsInRow > 0) l.newsFeedInRow(s.errorsInRow),
].join(' · ');

/// A feed: its address, the status of its last round with the topic, kind
/// and time, the switch; a tap opens the feed.
class _FeedRow extends StatelessWidget {
  const _FeedRow({
    super.key,
    required this.source,
    required this.topicName,
    required this.on,
    required this.busy,
    required this.onSwitch,
    required this.onTap,
  });

  final NewsSource source;
  final String topicName;
  final bool on;
  final bool busy;
  final ValueChanged<bool> onSwitch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = source;
    final now = DateTime.now();
    final muted = context.delve.textMuted;
    final meta = context.text.labelMedium!.copyWith(color: muted);
    final (icon, color, word) = _status(context, s);
    final detail = s.lastStatus == 'error' ? _errorDetail(l, s) : '';
    final checked = s.lastAt;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(
          horizontal: DelveTokens.space4,
          vertical: DelveTokens.space2,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    newsFeedAddress(s.url),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DelveText.mono.copyWith(
                      color: on ? context.colors.onSurface : muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(
                      children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: SymbolIcon(
                            icon,
                            size: 14,
                            filled: true,
                            color: color,
                          ),
                        ),
                        TextSpan(
                          text: ' $word',
                          style: meta.copyWith(color: color),
                        ),
                        if (detail.isNotEmpty)
                          TextSpan(text: ' · $detail', style: meta),
                        TextSpan(
                          text: [
                            '',
                            topicName,
                            _kind(l, s),
                            if (checked != null)
                              l.newsFeedChecked(_when(checked, now)),
                          ].join(' · '),
                          style: meta,
                        ),
                      ],
                    ),
                    key: Key('newsSettings.feed.status.${s.id}'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: DelveTokens.space2),
            Switch(
              key: Key('newsSettings.feed.switch.${s.id}'),
              value: on,
              onChanged: busy ? null : onSwitch,
            ),
          ],
        ),
      ),
    );
  }
}

/// The 0-5 stepper (h 40, 1 dp outline, radius 12): − value +.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.enabled,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget button(Key key, IconData icon, String tip, int? to) => SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        key: key,
        tooltip: tip,
        padding: EdgeInsets.zero,
        iconSize: 20,
        onPressed: enabled && to != null ? () => onChanged(to) : null,
        icon: SymbolIcon(icon, size: 20),
      ),
    );
    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: context.colors.outline),
        borderRadius: BorderRadius.circular(DelveTokens.rmd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(
            const Key('newsSettings.pushMax.less'),
            DelveIcons.remove,
            l.newsPushFewer,
            value > min ? value - 1 : null,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 28),
            child: Text(
              '$value',
              key: const Key('newsSettings.pushMax.value'),
              textAlign: TextAlign.center,
              style: DelveText.mono.copyWith(color: context.colors.onSurface),
            ),
          ),
          button(
            const Key('newsSettings.pushMax.more'),
            DelveIcons.add,
            l.newsPushMoreTooltip,
            value < max ? value + 1 : null,
          ),
        ],
      ),
    );
  }
}

/// D3-e3 a feed: the failing banner, the address (copyable), its last
/// answer, its topic and kind, “Collect from this feed”, Delete feed. There
/// is no “Check now”.
class NewsFeedScreen extends ConsumerStatefulWidget {
  const NewsFeedScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends ConsumerState<NewsFeedScreen> {
  bool? _pendingOn;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !ref.read(newsConfigProvider).loaded) {
        unawaited(
          ref.read(newsConfigProvider.notifier).refresh().catchError((_) {}),
        );
      }
    });
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _setOn(bool v) async {
    final l = AppLocalizations.of(context);
    setState(() => _pendingOn = v);
    try {
      await ref
          .read(newsConfigProvider.notifier)
          .setSourceEnabled(widget.id, v);
    } on Object catch (e) {
      _snack(l.newsSettingsSaveFailed(apiErrorText(l, e)));
    } finally {
      if (mounted) setState(() => _pendingOn = null);
    }
  }

  Future<void> _delete(NewsSource s) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.newsFeedDeleteTitle),
        content: Text(l.newsFeedDeleteBody(newsFeedAddress(s.url))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            key: const Key('newsFeed.delete.confirm'),
            style: TextButton.styleFrom(foregroundColor: ctx.delve.alertFg),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.newsFeedDeleteConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _deleting = true);
    try {
      await ref.read(newsConfigProvider.notifier).deleteSource(s.id);
      if (!mounted) return;
      context.pop();
      messenger.showSnackBar(SnackBar(content: Text(l.newsFeedDeleted)));
    } on Object catch (e) {
      if (mounted) setState(() => _deleting = false);
      _snack(l.newsSettingsSaveFailed(apiErrorText(l, e)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final config = ref.watch(newsConfigProvider);
    final s = config.source(widget.id);
    final Widget body;
    if (s == null) {
      final error = config.error;
      body = !config.loaded && error == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.fromLTRB(
                DelveTokens.space4,
                UnderBarFade.height,
                DelveTokens.space4,
                0,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: StatusBanner(
                  kind: error == null ? StatusKind.info : StatusKind.alert,
                  icon: error == null ? DelveIcons.info : DelveIcons.error,
                  text: error == null
                      ? l.newsFeedGone
                      : l.newsSettingsLoadFailed(apiErrorText(l, error)),
                ),
              ),
            );
    } else {
      body = _detail(context, l, config, s);
    }
    return Scaffold(
      appBar: PageColourBar(title: l.newsFeedTitle),
      body: UnderBarFade(child: body),
    );
  }

  Widget _detail(
    BuildContext context,
    AppLocalizations l,
    NewsConfig config,
    NewsSource s,
  ) {
    final now = DateTime.now();
    final muted = context.delve.textMuted;
    final (icon, color, word) = _status(context, s);
    final failed = s.lastStatus == 'error' && s.errorsInRow > 0;
    final on = _pendingOn ?? s.enabled;
    final answer = switch (s.lastStatus) {
      'ok' => [
        if (s.lastHttp case final h?) 'HTTP $h',
        l.newsFeedAnswerItems(s.lastItems ?? 0, s.lastNew ?? 0),
      ].join(' · '),
      'error' => [
        if (s.lastHttp case final h?) 'HTTP $h',
        ?(s.lastError ?? s.lastErrorCode),
      ].join(' · '),
      'not_modified' => 'HTTP ${s.lastHttp ?? 304}',
      'skipped' => s.lastErrorCode ?? '',
      _ => '',
    };
    final lastItem = s.lastItemAt;
    final checked = s.lastAt;
    return ListView(
      key: const Key('newsFeed'),
      padding: const EdgeInsets.fromLTRB(
        DelveTokens.space4,
        UnderBarFade.height,
        DelveTokens.space4,
        DelveTokens.space8,
      ),
      children: [
        if (failed)
          Padding(
            padding: const EdgeInsets.only(bottom: DelveTokens.space4),
            child: StatusBanner(
              key: const Key('newsFeed.failing'),
              kind: StatusKind.info,
              icon: NewsIcons.failingFeeds,
              text: l.newsFeedFailedRounds(s.errorsInRow),
            ),
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(
            DelveTokens.space3,
            DelveTokens.space1,
            DelveTokens.space1,
            DelveTokens.space1,
          ),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(DelveTokens.rmd),
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  s.url,
                  key: const Key('newsFeed.address'),
                  style: DelveText.mono.copyWith(
                    color: context.colors.onSurface,
                  ),
                ),
              ),
              IconButton(
                key: const Key('newsFeed.copy'),
                tooltip: l.newsFeedCopyAddress,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: s.url));
                  _snack(l.newsFeedAddressCopied);
                },
                icon: SymbolIcon(DelveIcons.copy, size: 20, color: muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: DelveTokens.space4),
        _Detail(
          label: l.newsFeedRowStatus,
          child: Text.rich(
            TextSpan(
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: SymbolIcon(icon, size: 16, filled: true, color: color),
                ),
                TextSpan(
                  text: ' $word',
                  style: TextStyle(color: color),
                ),
              ],
            ),
            style: context.text.bodyMedium,
          ),
        ),
        _Detail(
          label: l.newsFeedRowAnswer,
          child: Text(
            answer.isEmpty ? '—' : answer,
            key: const Key('newsFeed.answer'),
            style: DelveText.mono.copyWith(color: context.colors.onSurface),
          ),
        ),
        _Detail(
          label: l.newsFeedRowErrors,
          child: Text('${s.errorsInRow}', style: context.text.bodyMedium),
        ),
        _Detail(
          label: l.newsFeedRowChecked,
          child: Text(
            checked == null ? l.newsFeedNone : _when(checked, now),
            style: context.text.bodyMedium,
          ),
        ),
        _Detail(
          label: l.newsFeedRowLastStory,
          child: Text(
            lastItem == null ? l.newsFeedNone : _when(lastItem, now),
            key: const Key('newsFeed.lastStory'),
            style: context.text.bodyMedium,
          ),
        ),
        _Detail(
          label: l.newsFeedRowTopic,
          child: Align(
            alignment: Alignment.centerLeft,
            child: TopicLabel(
              topic: s.topic,
              name: _topicName(config, s.topic),
            ),
          ),
        ),
        _Detail(
          label: l.newsFeedRowKind,
          child: Text(_kind(l, s), style: context.text.bodyMedium),
        ),
        const SizedBox(height: DelveTokens.space2),
        SwitchListTile(
          key: const Key('newsFeed.collect'),
          contentPadding: EdgeInsets.zero,
          title: Text(l.newsFeedCollect, style: context.text.bodyLarge),
          value: on,
          onChanged: _pendingOn != null ? null : (v) => unawaited(_setOn(v)),
        ),
        const SizedBox(height: DelveTokens.space4),
        OutlinedButton.icon(
          key: const Key('newsFeed.delete'),
          style: OutlinedButton.styleFrom(
            foregroundColor: context.delve.alertFg,
            side: BorderSide(color: context.delve.alertBorder),
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: _deleting ? null : () => unawaited(_delete(s)),
          icon: const SymbolIcon(DelveIcons.delete, size: 20),
          label: Text(l.newsFeedDelete),
        ),
        const SizedBox(height: DelveTokens.space2),
        Text(
          l.newsFeedDeleteNote,
          style: context.text.bodySmall!.copyWith(color: muted),
        ),
      ],
    );
  }
}

/// Key (112 dp) and value, a rule under it.
class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 40),
    padding: const EdgeInsets.symmetric(vertical: DelveTokens.space2),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: context.colors.outlineVariant)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: context.text.bodyMedium!.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: DelveTokens.space3),
        Expanded(child: child),
      ],
    ),
  );
}

/// The desktop's News settings sections (the list column, 27W-5e).
enum NewsSettingsSection {
  topics,
  feeds,
  push;

  /// The section of a location's `section` (topics when unknown).
  static NewsSettingsSection of(String? name) =>
      values.firstWhere((s) => s.name == name, orElse: () => topics);

  String title(AppLocalizations l) => switch (this) {
    topics => l.newsSetTopics,
    feeds => l.newsSetFeeds,
    push => l.newsSetDigestPush,
  };

  IconData get icon => switch (this) {
    topics => NewsIcons.news,
    feeds => NewsIcons.failingFeeds,
    push => DelveIcons.notifications,
  };
}

/// The desktop's list column of News settings: back to News, then the
/// sections as 32 px rows.
class NewsSettingsNav extends StatelessWidget {
  const NewsSettingsNav({super.key, required this.section});

  final NewsSettingsSection section;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = context.colors;
    return Material(
      key: const Key('newsSettings.nav'),
      color: cs.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: DelveDesktop.paneHeader,
            child: Padding(
              padding: const EdgeInsets.only(left: 6, right: 10),
              child: Row(
                children: [
                  IconButton(
                    key: const Key('newsSettings.back'),
                    tooltip: l.newsTitle,
                    onPressed: () => context.open(Routes.news),
                    icon: const SymbolIcon(
                      DelveIcons.arrowBack,
                      size: DelveDesktop.iconButtonIcon,
                    ),
                  ),
                  const SizedBox(width: DelveTokens.space1),
                  Expanded(
                    child: Text(
                      l.newsSettingsTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DelveDesktopText.paneTitle.copyWith(
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (final s in NewsSettingsSection.values)
            SectionRow(
              key: Key('newsSettings.nav.${s.name}'),
              icon: s.icon,
              label: s.title(l),
              selected: s == section,
              onTap: () => context.open(Routes.newsSettingsAt(s.name)),
            ),
        ],
      ),
    );
  }
}
