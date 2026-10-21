import 'dart:convert';

/// A push from the backend (FCM data message, delve-backend `push.py`). Every
/// value arrives as a string; anything malformed parses to null and is
/// ignored.
sealed class PushMessage {
  const PushMessage();

  static PushMessage? parse(Map<String, Object?> data) {
    String? s(String key) {
      final v = data[key];
      return v is String ? v : null;
    }

    DateTime? t(String key) {
      final v = s(key);
      return v == null || v.isEmpty ? null : DateTime.tryParse(v);
    }

    switch (s('kind')) {
      case 'approval':
        final requestId = s('request_id');
        final conversationId = s('conversation_id');
        final command = s('command');
        final status = s('status');
        if (requestId == null ||
            conversationId == null ||
            command == null ||
            status == null) {
          return null;
        }
        return ApprovalPush(
          requestId: requestId,
          conversationId: conversationId,
          title: s('title') ?? '',
          actionClass: s('action_class') ?? 'other',
          command: command,
          status: status,
          hermesDeadline: t('hermes_deadline'),
          expiresAt: t('expires_at'),
        );
      case 'approval_resolved':
        final requestId = s('request_id');
        if (requestId == null) return null;
        return ApprovalResolvedPush(
          requestId: requestId,
          status: s('status') ?? '',
        );
      case 'card' when s('type') == 'brief':
        final cardId = s('card_id');
        if (cardId == null) return null;
        return BriefPush(
          cardId: cardId,
          uptimeS: int.tryParse(s('uptime_s') ?? ''),
          updatesCount: int.tryParse(s('updates_count') ?? ''),
          openIncidents: int.tryParse(s('open_incidents') ?? ''),
          llamaState: switch (s('llama_state')) {
            null || '' => null,
            final v => v,
          },
          levelCm: double.tryParse(s('level_cm') ?? ''),
        );
      case 'card':
        final cardId = s('card_id');
        final level = double.tryParse(s('level_cm') ?? '');
        final station = s('station');
        if (cardId == null ||
            s('type') != 'water' ||
            level == null ||
            station == null ||
            station.isEmpty) {
          return null;
        }
        return WaterPush(
          cardId: cardId,
          station: station,
          levelCm: level,
          lakeAvgCm: double.tryParse(s('lake_avg_cm') ?? ''),
          trendCm: double.tryParse(s('trend_cm_24h') ?? ''),
        );
      case 'run_done':
        final conversationId = s('conversation_id');
        final runId = s('run_id');
        if (conversationId == null || runId == null) return null;
        return RunDonePush(
          conversationId: conversationId,
          runId: runId,
          title: s('title') ?? '',
          status: s('status') ?? 'completed',
          preview: s('preview') ?? '',
        );
      default:
        return null;
    }
  }
}

final class ApprovalPush extends PushMessage {
  const ApprovalPush({
    required this.requestId,
    required this.conversationId,
    required this.title,
    required this.actionClass,
    required this.command,
    required this.status,
    this.hermesDeadline,
    this.expiresAt,
  });

  final String requestId;
  final String conversationId;
  final String title;
  final String actionClass;

  /// The start of the command (the backend sends at most 80 characters).
  final String command;

  /// `pending` or `expired_in_hermes`.
  final String status;
  final DateTime? hermesDeadline;
  final DateTime? expiresAt;

  bool get stoppedWaiting => status == 'expired_in_hermes';
}

final class ApprovalResolvedPush extends PushMessage {
  const ApprovalResolvedPush({required this.requestId, required this.status});
  final String requestId;
  final String status;
}

final class RunDonePush extends PushMessage {
  const RunDonePush({
    required this.conversationId,
    required this.runId,
    required this.title,
    required this.status,
    required this.preview,
  });

  final String conversationId;
  final String runId;
  final String title;
  final String status;
  final String preview;

  bool get failed => status == 'failed';
}

/// A new scheduled water reading (`card`, type `water`).
final class WaterPush extends PushMessage {
  const WaterPush({
    required this.cardId,
    required this.station,
    required this.levelCm,
    this.lakeAvgCm,
    this.trendCm,
  });

  final String cardId;
  final String station;
  final double levelCm;
  final double? lakeAvgCm;

  /// Change at the station over 24 h, cm.
  final double? trendCm;
}

/// A new morning brief (`card`, type `brief`, B4); empty fields are null.
final class BriefPush extends PushMessage {
  const BriefPush({
    required this.cardId,
    this.uptimeS,
    this.updatesCount,
    this.openIncidents,
    this.llamaState,
    this.levelCm,
  });

  final String cardId;
  final int? uptimeS;
  final int? updatesCount;
  final int? openIncidents;
  final String? llamaState;

  /// Siófok's level, cm.
  final double? levelCm;
}

/// Notification id for a key (request id, run id): FNV-1a, positive 31 bit.
/// Stable across isolates and app starts, so the background handler can
/// replace or remove what another isolate showed.
int notificationId(String key) {
  var h = 0x811c9dc5;
  for (final b in utf8.encode(key)) {
    h ^= b;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h & 0x7fffffff;
}

/// What a tap or an action carries back: the notification's payload.
class PushTarget {
  const PushTarget({required this.kind, this.conversationId, this.requestId});

  static PushTarget? decode(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final j = jsonDecode(payload);
      if (j is! Map<String, Object?>) return null;
      final kind = j['kind'];
      final conv = j['conversation_id'];
      final req = j['request_id'];
      if (kind is! String) return null;
      // a chat's notification needs its chat; a card's opens the dashboard
      if (kind != 'card' && conv is! String) return null;
      return PushTarget(
        kind: kind,
        conversationId: conv is String ? conv : null,
        requestId: req is String ? req : null,
      );
    } on FormatException {
      return null;
    }
  }

  /// `approval`, `run_done` or `card`.
  final String kind;

  /// null for a card.
  final String? conversationId;
  final String? requestId;

  String encode() => jsonEncode({
    'kind': kind,
    'conversation_id': ?conversationId,
    'request_id': ?requestId,
  });
}
