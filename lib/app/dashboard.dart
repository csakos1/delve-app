import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/rest_client.dart';
import '../data/db/database.dart';
import '../data/db/store.dart';
import 'providers.dart';
import 'session.dart';

/// Days the water chart covers (design 12: a week, today on the right).
const int kWaterDays = 7;

/// A `water` card's payload, read leniently (plan 5.2).
class WaterReading {
  const WaterReading({
    required this.station,
    required this.levelCm,
    required this.at,
    required this.cardTs,
    this.lakeAvgCm,
    this.trendCm,
    this.lakeTrendCm,
  });

  /// null when the card is not a usable water reading.
  static WaterReading? of(CardRow card) {
    final p = card.payload;
    final station = p['station'];
    final level = p['level_cm'];
    if (card.type != 'water' || station is! String || level is! num) {
      return null;
    }
    double? n(String key) => switch (p[key]) {
      final num v => v.toDouble(),
      _ => null,
    };
    final measured = p['measured_at'];
    return WaterReading(
      station: station,
      levelCm: level.toDouble(),
      at: (measured is String ? DateTime.tryParse(measured) : null) ?? card.ts,
      cardTs: card.ts,
      lakeAvgCm: n('lake_avg_cm'),
      trendCm: n('trend_cm_24h'),
      lakeTrendCm: n('lake_avg_trend_cm_24h'),
    );
  }

  final String station;
  final double levelCm;

  /// When the gauge was read (`measured_at`, else the card's time).
  final DateTime at;

  /// When the card was published (the time the dashboard shows).
  final DateTime cardTs;
  final double? lakeAvgCm;

  /// Change over 24 h at the station, cm.
  final double? trendCm;
  final double? lakeTrendCm;
}

/// One day of the chart: the day's last reading, or nulls for a gap.
class WaterDay {
  const WaterDay(this.day, this.levelCm, this.lakeAvgCm);

  /// Local midnight.
  final DateTime day;
  final double? levelCm;
  final double? lakeAvgCm;
}

/// The last [days] local days ending today, each with its last reading.
List<WaterDay> waterDays(
  List<WaterReading> readings,
  DateTime now, {
  int days = kWaterDays,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final byDay = <DateTime, WaterReading>{};
  for (final r in readings) {
    final local = r.at.toLocal();
    final d = DateTime(local.year, local.month, local.day);
    final prev = byDay[d];
    if (prev == null || !r.at.isBefore(prev.at)) byDay[d] = r;
  }
  final out = <WaterDay>[];
  for (var i = days - 1; i >= 0; i--) {
    final d = DateTime(today.year, today.month, today.day - i);
    final r = byDay[d];
    out.add(WaterDay(d, r?.levelCm, r?.lakeAvgCm));
  }
  return out;
}

/// The window the dashboard loads and watches: a day more than the chart, so
/// the first day's reading is there.
DateTime waterSince(DateTime now) =>
    DateTime(now.year, now.month, now.day - kWaterDays);

/// Scheduled water readings (the cron script), oldest first. The agent's own
/// water cards (published on request in a chat) stay out of the chart.
final waterReadingsProvider = StreamProvider.autoDispose<List<WaterReading>>((
  ref,
) {
  final db = ref.watch(databaseProvider);
  return db
      .watchCards(
        type: 'water',
        origin: 'script',
        since: waterSince(DateTime.now()),
      )
      .map((rows) => [for (final r in rows) ?WaterReading.of(r)]);
});

/// Loads the dashboard's cards over REST into the database (the screen shows
/// the database). Live cards arrive as `card.new` meanwhile.
class DashboardService {
  const DashboardService(this.api, this.db);
  final DelveApi api;
  final AppDatabase db;

  Future<void> refresh({DateTime? now}) async {
    final cards = await api.cards(
      type: 'water',
      since: waterSince(now ?? DateTime.now()),
      limit: 200,
    );
    await db.transaction(() async {
      for (final c in cards) {
        await db.putCard(c);
      }
    });
  }
}

final dashboardServiceProvider = Provider.autoDispose<DashboardService?>((ref) {
  final api = ref.watch(apiProvider);
  if (api == null) return null;
  return DashboardService(api, ref.watch(databaseProvider));
});
