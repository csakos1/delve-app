import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/events.dart';
import '../api/models/models.dart';
import '../api/rest_client.dart';
import '../sync/sync_providers.dart';
import 'session.dart';

/// The schedule list (B4, design 14a). Kept in memory like the system view:
/// loaded over REST when the screen opens, kept current by
/// `schedule.updated` / `schedule.deleted`.
@immutable
class SchedulesView {
  const SchedulesView({this.items, this.error});

  /// The brief first, then the prompts by creation (null before the first
  /// answer).
  final List<Schedule>? items;

  /// The last refresh failed (an older [items] may still be shown).
  final Object? error;

  Schedule? byId(String id) {
    for (final s in items ?? const <Schedule>[]) {
      if (s.id == id) return s;
    }
    return null;
  }

  Schedule? get brief {
    for (final s in items ?? const <Schedule>[]) {
      if (s.kind == 'brief') return s;
    }
    return null;
  }
}

class SchedulesController extends Notifier<SchedulesView> {
  @override
  SchedulesView build() {
    final engine = ref.watch(syncEngineProvider);
    ref.watch(apiProvider); // another server starts empty
    if (engine != null) {
      final sub = engine.scheduleChanges.listen((change) {
        if (!ref.mounted) return;
        switch (change) {
          case ScheduleUpdated(:final schedule):
            _put(schedule);
          case ScheduleDeleted(:final id):
            _remove(id);
        }
      });
      ref.onDispose(sub.cancel);
    }
    return const SchedulesView();
  }

  DelveApi? get _api => ref.read(apiProvider);

  /// Brief first, then by creation time (as the server lists them).
  static List<Schedule> _sorted(Iterable<Schedule> items) =>
      items.toList()..sort((a, b) {
        if ((a.kind == 'brief') != (b.kind == 'brief')) {
          return a.kind == 'brief' ? -1 : 1;
        }
        final c = a.createdAt.compareTo(b.createdAt);
        return c != 0 ? c : a.id.compareTo(b.id);
      });

  void _put(Schedule s) {
    final items = state.items;
    if (items == null) return; // the first load brings it
    state = SchedulesView(
      items: _sorted([...items.where((i) => i.id != s.id), s]),
      error: state.error,
    );
  }

  void _remove(String id) {
    final items = state.items;
    if (items == null) return;
    state = SchedulesView(
      items: [...items.where((i) => i.id != id)],
      error: state.error,
    );
  }

  /// Reloads the list; a failure is kept in [SchedulesView.error] and
  /// rethrown.
  Future<void> refresh() async {
    final api = _api;
    if (api == null) return;
    try {
      final items = await api.schedules();
      if (ref.mounted) state = SchedulesView(items: _sorted(items));
    } on Object catch (e) {
      if (ref.mounted) state = SchedulesView(items: state.items, error: e);
      rethrow;
    }
  }

  /// The server's answer replaces the stored copy; errors are rethrown.
  Future<Schedule> create(ScheduleDraft draft) async {
    final s = await _api!.createSchedule(draft);
    if (ref.mounted) {
      state = SchedulesView(items: _sorted([...?state.items, s]));
    }
    return s;
  }

  Future<Schedule> change(String id, Map<String, Object?> fields) async {
    final s = await _api!.patchSchedule(id, fields);
    if (ref.mounted) _put(s);
    return s;
  }

  Future<void> delete(String id) async {
    await _api!.deleteSchedule(id);
    if (ref.mounted) _remove(id);
  }

  Future<ScheduleRun> runNow(String id) async {
    final r = await _api!.runSchedule(id);
    if (ref.mounted) _put(r.schedule);
    return r;
  }
}

final schedulesProvider = NotifierProvider<SchedulesController, SchedulesView>(
  SchedulesController.new,
);
