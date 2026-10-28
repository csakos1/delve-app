import 'package:freezed_annotation/freezed_annotation.dart';

part 'watch.freezed.dart';
part 'watch.g.dart';

/// `watch` shape (`GET /watches`, `watch.updated`, W2): something the agent
/// set up in a chat, checked on a schedule without the model; new listings
/// that pass its filters are judged against [criteria] (or are hits at once).
@freezed
abstract class Watch with _$Watch {
  const factory Watch({
    required String slug,
    required String name,

    /// `hardverapro` | `cinemacity` | `page`.
    required String source,
    required String url,

    /// The condition the judge reads, as the user means it; null = filters
    /// only.
    String? criteria,
    @Default(<String>[]) List<String> include,
    @Default(<String>[]) List<String> any,
    @Default(<String>[]) List<String> exclude,
    int? minPrice,
    int? maxPrice,
    required bool fetchDetails,
    required bool stopAfterHit,

    /// A 5-field cron (`15 8,13,19 * * *`) or `every 480m`.
    required String schedule,

    /// `active` | `paused` | `unknown` (no cron job yet) | `deleted`.
    required String state,
    String? jobId,
    DateTime? nextRunAt,
    DateTime? lastCheckAt,

    /// `ok` | `error`.
    String? lastStatus,
    String? lastErrorCode,
    String? lastError,
    int? lastItems,
    int? lastMatched,
    @Default(0) int errorsInRow,
    @Default(0) int hits,
    @JsonKey(name: 'hits_24h') @Default(0) int hits24h,
    @Default(0) int pending,
    @Default(0) int rejected,
    DateTime? lastHitAt,

    /// Paused itself after its first hit (`stop_after_hit`).
    DateTime? stoppedAt,
    required DateTime definedAt,
    required DateTime updatedAt,
  }) = _Watch;

  factory Watch.fromJson(Map<String, Object?> json) => _$WatchFromJson(json);
}

/// `watch_item` shape: one listing a watch has seen and kept.
@freezed
abstract class WatchItem with _$WatchItem {
  const factory WatchItem({
    required int id,
    required String slug,
    required String itemId,
    required String title,
    required String url,
    String? price,
    int? priceValue,
    String? location,
    String? posted,
    String? excerpt,

    /// On hold (Hardverapró "jegelve").
    @Default(false) bool reserved,

    /// `match` | `mechanical` (hits) | `reject` | `pending` | `error`.
    required String verdict,

    /// The judge's one sentence (match, reject).
    String? reason,
    required DateTime seenAt,
    DateTime? judgedAt,
    DateTime? notifiedAt,

    /// Was on hold, then free again.
    DateTime? availableAt,
  }) = _WatchItem;

  factory WatchItem.fromJson(Map<String, Object?> json) =>
      _$WatchItemFromJson(json);
}

/// What a watch and its items mean on screen.
extension WatchX on Watch {
  bool get failing => lastStatus == 'error';
  bool get paused => state == 'paused';

  /// Paused by itself after the first hit (not by the user).
  bool get stoppedAfterHit => paused && stopAfterHit && stoppedAt != null;
}

extension WatchItemX on WatchItem {
  bool get isHit => verdict == 'match' || verdict == 'mechanical';
  bool get availableAgain => availableAt != null && !reserved;
}
