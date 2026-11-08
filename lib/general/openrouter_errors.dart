import 'dart:io';

/// What a General request can fail with. [code] is stored on a failed
/// answer; none of these carry the key or the request body.
sealed class GeneralFailure implements Exception {
  const GeneralFailure(this.message);

  /// OpenRouter's (or the network's) own words, for the details line.
  final String message;

  String get code;

  /// Built from a stored answer ([code] + [message]).
  static GeneralFailure fromCode(
    String code,
    String message, {
    int? retryAfterS,
  }) => switch (code) {
    'unauthorized' => GeneralUnauthorized(message),
    'key_limit' => GeneralKeyLimit(message),
    'no_provider' => GeneralNoProvider(message),
    'bad_request' => GeneralBadRequest(message),
    'rate_limited' => GeneralRateLimited(
      message,
      retryAfter: retryAfterS == null ? null : Duration(seconds: retryAfterS),
    ),
    'network' => GeneralNetwork(message),
    'no_key' => const GeneralNoKey(),
    'provider_warning' => const GeneralWarningPending(),
    _ => GeneralUpstream(message),
  };

  /// An HTTP error status with OpenRouter's body
  /// (`{"error": {"message", "code", "metadata"}}`).
  static GeneralFailure fromStatus(
    int status,
    Object? body, {
    String? retryAfter,
  }) {
    final message = errorMessage(body) ?? 'HTTP $status';
    return switch (status) {
      401 => GeneralUnauthorized(message),
      402 => GeneralKeyLimit(message),
      404 => GeneralNoProvider(message),
      400 || 413 || 422 => GeneralBadRequest(message),
      429 => GeneralRateLimited(message, retryAfter: _seconds(retryAfter)),
      _ => GeneralUpstream(message),
    };
  }

  /// `error.message` of an OpenRouter error body or stream chunk.
  static String? errorMessage(Object? body) {
    if (body is Map<String, Object?>) {
      final err = body['error'];
      if (err is Map<String, Object?> && err['message'] is String) {
        return err['message']! as String;
      }
      if (body['message'] is String) return body['message']! as String;
    }
    return null;
  }

  static Duration? _seconds(String? header) {
    final s = int.tryParse(header?.trim() ?? '');
    return s == null || s < 0 ? null : Duration(seconds: s);
  }

  static GeneralFailure network(Object error) => GeneralNetwork(switch (error) {
    SocketException(:final osError?) => osError.message,
    SocketException(:final message) => message,
    HandshakeException(:final message) => message,
    _ => error.toString(),
  });

  @override
  String toString() => '$runtimeType($message)';
}

/// 401: the key is wrong or was deleted.
class GeneralUnauthorized extends GeneralFailure {
  const GeneralUnauthorized(super.message);
  @override
  String get code => 'unauthorized';
}

/// 402: the key's limit or the account's credit is used up.
class GeneralKeyLimit extends GeneralFailure {
  const GeneralKeyLimit(super.message);
  @override
  String get code => 'key_limit';
}

/// 404: no provider left after the zero-retention / data rules.
class GeneralNoProvider extends GeneralFailure {
  const GeneralNoProvider(super.message);
  @override
  String get code => 'no_provider';
}

/// 400: e.g. “Reasoning is mandatory …”, an unknown model id.
class GeneralBadRequest extends GeneralFailure {
  const GeneralBadRequest(super.message);
  @override
  String get code => 'bad_request';
}

/// 429, with `Retry-After` when OpenRouter sends it.
class GeneralRateLimited extends GeneralFailure {
  const GeneralRateLimited(super.message, {this.retryAfter});
  final Duration? retryAfter;
  @override
  String get code => 'rate_limited';
}

/// 5xx, a broken stream or an error object inside the stream.
class GeneralUpstream extends GeneralFailure {
  const GeneralUpstream(super.message);
  @override
  String get code => 'upstream';
}

/// No connection to OpenRouter.
class GeneralNetwork extends GeneralFailure {
  const GeneralNetwork(super.message);
  @override
  String get code => 'network';
}

/// No key saved.
class GeneralNoKey extends GeneralFailure {
  const GeneralNoKey() : super('No OpenRouter key');
  @override
  String get code => 'no_key';
}

/// The last answer came from a provider outside the zero-retention list and
/// the user has not acknowledged it yet: nothing more is sent.
class GeneralWarningPending extends GeneralFailure {
  const GeneralWarningPending()
    : super('Acknowledge the provider warning first');
  @override
  String get code => 'provider_warning';
}

/// The model cannot be used here (not in the list, or no strict
/// zero-retention provider).
class GeneralModelUnavailable extends GeneralFailure {
  const GeneralModelUnavailable(super.message);
  @override
  String get code => 'no_provider';
}
