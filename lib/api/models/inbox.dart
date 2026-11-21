import 'package:flutter/foundation.dart';

import 'approval.dart';
import 'news.dart';
import 'schedule.dart';
import 'system_info.dart';
import 'watch.dart';

/// The kinds of an Inbox item (`inbox_item.kind`, API 23).
abstract final class InboxKind {
  /// An approval the agent waits for.
  static const approval = 'approval';

  /// One the agent stopped waiting for, still approvable.
  static const lateApproval = 'late_approval';

  /// A listing a watcher's judge (or its filters) accepted.
  static const watchHit = 'watch_hit';

  /// A story scored 9, not read yet.
  static const mustRead = 'must_read';

  /// A News feed that failed 3 rounds in a row.
  static const feedFailing = 'feed_failing';

  /// A model switch that failed.
  static const switchFailed = 'switch_failed';

  /// A schedule whose last run failed, or that was missed.
  static const scheduleFailed = 'schedule_failed';
}

/// `inbox_item` shape (`GET /inbox`, I0): one thing that needs the reader.
/// [id] is `<kind>:<ref>`; [title] its gist (the command, the listing, the
/// headline, the feed's address, the model that did not load, the
/// schedule's name), [source] where it comes from (the chat, the watcher,
/// the publisher, the topic, the model before, the error). The thing itself
/// is under its own key – [approval], [hit], [story], [feed], [llamaSwitch]
/// (`switch`), [schedule] – and the others are null. [doneAt] is set on the
/// items cleared today (`done`).
@immutable
class InboxItem {
  const InboxItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.doneable,
    this.at,
    this.source,
    this.approval,
    this.hit,
    this.story,
    this.feed,
    this.llamaSwitch,
    this.schedule,
    this.doneAt,
  });

  factory InboxItem.fromJson(Map<String, Object?> json) {
    T? part<T>(String key, T Function(Map<String, Object?>) parse) {
      final v = json[key] as Map<String, Object?>?;
      return v == null ? null : parse(v);
    }

    DateTime? date(String key) => switch (json[key]) {
      final String s => DateTime.parse(s),
      _ => null,
    };

    return InboxItem(
      id: json['id']! as String,
      kind: json['kind']! as String,
      at: date('at'),
      title: json['title'] as String? ?? '',
      source: json['source'] as String?,
      doneable: json['doneable'] as bool? ?? false,
      approval: part('approval', Approval.fromJson),
      hit: part('hit', WatchItem.fromJson),
      story: part('story', NewsItem.fromJson),
      feed: part('feed', NewsSource.fromJson),
      llamaSwitch: part('switch', LlamaSwitch.fromJson),
      schedule: part('schedule', Schedule.fromJson),
      doneAt: date('done_at'),
    );
  }

  final String id;
  final String kind;

  /// When it entered: the request, the verdict, the scoring, the last
  /// failed round, the switch, the failed run or the missed time.
  final DateTime? at;
  final String title;
  final String? source;

  /// The reader can clear it (an approval is answered instead).
  final bool doneable;
  final Approval? approval;
  final WatchItem? hit;
  final NewsItem? story;
  final NewsSource? feed;
  final LlamaSwitch? llamaSwitch;
  final Schedule? schedule;

  /// When it was cleared (only in [Inbox.done]).
  final DateTime? doneAt;

  /// The kind of an item [id] (`watch_hit:17` → `watch_hit`).
  static String kindOf(String id) {
    final at = id.indexOf(':');
    return at < 0 ? id : id.substring(0, at);
  }

  /// What an item [id] is about: the approval's request id, the listing's
  /// or the story's id, the feed's or the schedule's id.
  static String subjectOf(String id) {
    final at = id.indexOf(':');
    return at < 0 ? '' : id.substring(at + 1);
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind,
    'at': at?.toIso8601String(),
    'title': title,
    'source': source,
    'doneable': doneable,
    'approval': approval?.toJson(),
    'hit': hit?.toJson(),
    'story': story?.toJson(),
    'feed': feed?.toJson(),
    'switch': llamaSwitch?.toJson(),
    'schedule': schedule?.toJson(),
    if (doneAt case final cleared?) 'done_at': cleared.toIso8601String(),
  };
}

/// `inbox` shape (`GET /inbox`, `POST /inbox/done`, `POST /inbox/undo`):
/// the open [items] newest first, what was cleared today ([done], the
/// latest first, each with its `doneAt`), and the counts – [open] is the
/// number of [items], [approvals] how many of them can be answered.
@immutable
class Inbox {
  const Inbox({
    this.items = const [],
    this.done = const [],
    this.open = 0,
    this.approvals = 0,
    this.updatedAt,
  });

  factory Inbox.fromJson(Map<String, Object?> json) {
    List<InboxItem> list(String key) => [
      for (final i in (json[key] as List<Object?>?) ?? const <Object?>[])
        InboxItem.fromJson(i! as Map<String, Object?>),
    ];
    final items = list('data');
    return Inbox(
      items: items,
      done: list('done'),
      open: json['open'] as int? ?? items.length,
      approvals: json['approvals'] as int? ?? 0,
      updatedAt: switch (json['updated_at']) {
        final String s => DateTime.parse(s),
        _ => null,
      },
    );
  }

  final List<InboxItem> items;
  final List<InboxItem> done;
  final int open;
  final int approvals;
  final DateTime? updatedAt;

  Map<String, Object?> toJson() => {
    'data': [for (final i in items) i.toJson()],
    'done': [for (final i in done) i.toJson()],
    'open': open,
    'approvals': approvals,
    'updated_at': updatedAt?.toIso8601String(),
  };
}

/// What an item means on screen.
extension InboxItemX on InboxItem {
  bool get isApproval =>
      kind == InboxKind.approval || kind == InboxKind.lateApproval;

  /// A notice: something failed (a feed, a model switch, a schedule).
  bool get isNotice =>
      kind == InboxKind.feedFailing ||
      kind == InboxKind.switchFailed ||
      kind == InboxKind.scheduleFailed;

  /// See [InboxItem.subjectOf].
  String get subject => InboxItem.subjectOf(id);
}
