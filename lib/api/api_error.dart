import 'dart:io';

import 'package:dio/dio.dart';

/// Everything the REST client can fail with. Screens switch on the type;
/// none of these carry secrets (no token, no request body).
sealed class ApiError implements Exception {
  const ApiError();

  /// Maps a dio failure to an [ApiError].
  static ApiError fromDio(DioException e) {
    final res = e.response;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return ApiUnreachable(e.requestOptions.uri.host, 'timeout');
      case DioExceptionType.connectionError:
        return ApiUnreachable(e.requestOptions.uri.host, _cause(e.error));
      case DioExceptionType.badCertificate:
        return const ApiBadResponse('the server certificate was rejected');
      case DioExceptionType.cancel:
        return const ApiCancelled();
      case DioExceptionType.badResponse:
        if (res != null) return fromResponse(res);
        return const ApiBadResponse('empty response');
      case DioExceptionType.unknown:
        final err = e.error;
        if (err is SocketException || err is HandshakeException) {
          return ApiUnreachable(e.requestOptions.uri.host, _cause(err));
        }
        if (err is ApiError) return err;
        return ApiBadResponse(err?.runtimeType.toString() ?? 'unknown error');
    }
  }

  /// Maps a non-2xx response (`{"detail": {"code", "message"}}` from the backend).
  static ApiError fromResponse(Response<Object?> res) {
    final status = res.statusCode ?? 0;
    String? code;
    String? message;
    final body = res.data;
    if (body is Map<Object?, Object?> &&
        body['detail'] is Map<Object?, Object?>) {
      final detail = body['detail']! as Map<Object?, Object?>;
      code = detail['code'] is String ? detail['code'] as String : null;
      message = detail['message'] is String
          ? detail['message'] as String
          : null;
    }
    if (status == 401) return const ApiUnauthorized();
    if (status == 429) {
      final header = res.headers.value('retry-after');
      final secs = int.tryParse(header ?? '') ?? 60;
      return ApiRateLimited(Duration(seconds: secs < 1 ? 1 : secs), code: code);
    }
    return ApiRequestError(status, code: code, message: message);
  }

  static String _cause(Object? err) => switch (err) {
    SocketException(:final osError?) => osError.message,
    SocketException(:final message) => message,
    HandshakeException() => 'TLS handshake failed',
    null => 'connection failed',
    _ => err.runtimeType.toString(),
  };
}

/// No answer: DNS, refused, timeout or TLS. Over a tailnet this almost always
/// means Tailscale is off on the phone or the desktop is down.
final class ApiUnreachable extends ApiError {
  const ApiUnreachable(this.host, this.cause);
  final String host;
  final String cause;

  @override
  String toString() => 'ApiUnreachable($host: $cause)';
}

/// The device token is missing, wrong or revoked.
final class ApiUnauthorized extends ApiError {
  const ApiUnauthorized();

  @override
  String toString() => 'ApiUnauthorized';
}

final class ApiRateLimited extends ApiError {
  const ApiRateLimited(this.retryAfter, {this.code});
  final Duration retryAfter;
  final String? code;

  @override
  String toString() => 'ApiRateLimited(${retryAfter.inSeconds} s)';
}

/// Any other 4xx/5xx; [code] is the backend's machine-readable code
/// (e.g. `invalid_code`), when it sent one.
final class ApiRequestError extends ApiError {
  const ApiRequestError(this.status, {this.code, this.message});
  final int status;
  final String? code;
  final String? message;

  @override
  String toString() => 'ApiRequestError($status, $code)';
}

/// The answer was not what the contract says (or TLS was refused).
final class ApiBadResponse extends ApiError {
  const ApiBadResponse(this.detail);
  final String detail;

  @override
  String toString() => 'ApiBadResponse($detail)';
}

final class ApiCancelled extends ApiError {
  const ApiCancelled();

  @override
  String toString() => 'ApiCancelled';
}
