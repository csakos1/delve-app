import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models/models.dart';
import 'session.dart';

/// The Observability ranges (design 15 chips).
enum StatsRange {
  day('24h'),
  week('7d'),
  month('30d');

  const StatsRange(this.query);

  /// The `range` query parameter of `GET /stats`.
  final String query;
}

/// What the Observability screen shows. In memory only, like the system
/// view: it is computed by the server on every ask.
@immutable
class ObservabilityView {
  const ObservabilityView({
    this.range = StatsRange.day,
    this.stats,
    this.error,
    this.loading = false,
  });

  final StatsRange range;

  /// The last answer; while another range loads it stays until replaced.
  final Stats? stats;

  /// The last load failed.
  final Object? error;
  final bool loading;

  ObservabilityView copyWith({
    StatsRange? range,
    Stats? stats,
    Object? error,
    bool clearError = false,
    bool? loading,
  }) => ObservabilityView(
    range: range ?? this.range,
    stats: stats ?? this.stats,
    error: clearError ? null : error ?? this.error,
    loading: loading ?? this.loading,
  );
}

class ObservabilityController extends Notifier<ObservabilityView> {
  int _generation = 0;

  @override
  ObservabilityView build() {
    ref.watch(apiProvider); // another server starts empty
    return const ObservabilityView();
  }

  /// Switches the range and loads it.
  Future<void> select(StatsRange range) async {
    if (range == state.range && state.stats?.range == range.query) return;
    state = state.copyWith(range: range);
    await refresh();
  }

  /// Loads the current range; a failure is kept in [ObservabilityView.error]
  /// and rethrown. An answer for a range the user has left is dropped.
  Future<void> refresh() async {
    final api = ref.read(apiProvider);
    if (api == null) return;
    final gen = ++_generation;
    final range = state.range;
    state = state.copyWith(loading: true);
    try {
      final stats = await api.stats(range.query);
      if (!ref.mounted || gen != _generation) return;
      state = state.copyWith(stats: stats, clearError: true, loading: false);
    } on Object catch (e) {
      if (ref.mounted && gen == _generation) {
        state = state.copyWith(error: e, loading: false);
      }
      rethrow;
    }
  }
}

final observabilityProvider =
    NotifierProvider<ObservabilityController, ObservabilityView>(
      ObservabilityController.new,
    );
