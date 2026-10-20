import 'package:dio/dio.dart';

import 'api_error.dart';
import 'models/models.dart';
import 'protocol.dart';

/// REST client for one server. Every failure is an [ApiError]; a 401 on an
/// authenticated call also triggers [onUnauthorized] (the session drops the
/// token and goes back to pairing).
class DelveApi {
  DelveApi({
    required this.server,
    this.token,
    this.onUnauthorized,
    HttpClientAdapter? adapter,
    Duration connectTimeout = const Duration(seconds: 8),
    Duration receiveTimeout = const Duration(seconds: 20),
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: server.toString(),
           connectTimeout: connectTimeout,
           receiveTimeout: receiveTimeout,
           sendTimeout: receiveTimeout,
           responseType: ResponseType.json,
           headers: {if (token != null) 'Authorization': 'Bearer $token'},
           validateStatus: (s) => s != null && s >= 200 && s < 300,
         ),
       ) {
    if (adapter != null) _dio.httpClientAdapter = adapter;
  }

  /// Server origin, e.g. `https://archlinux.example.ts.net`.
  final Uri server;
  final String? token;
  final void Function()? onUnauthorized;
  final Dio _dio;

  void close() => _dio.close(force: true);

  Future<Map<String, Object?>> _json(
    (String, String) route, {
    Map<String, String> params = const {},
    Object? body,
  }) async {
    try {
      final res = await _dio.request<Object?>(
        ApiRoutes.path(route.$2, params),
        data: body,
        options: Options(method: route.$1),
      );
      final data = res.data;
      if (res.statusCode == 204 || data == null || data == '') {
        return const <String, Object?>{};
      }
      if (data is Map<String, Object?>) return data;
      if (data is Map<Object?, Object?>) return Map<String, Object?>.from(data);
      throw const ApiBadResponse('expected a JSON object');
    } on DioException catch (e) {
      final err = ApiError.fromDio(e);
      if (err is ApiUnauthorized && token != null) onUnauthorized?.call();
      throw err;
    }
  }

  T _parse<T>(Map<String, Object?> json, T Function(Map<String, Object?>) f) {
    try {
      return f(json);
    } on Object catch (e) {
      throw ApiBadResponse('unexpected response: ${e.runtimeType}');
    }
  }

  /// No auth: version and contract revision. Also the reachability probe.
  Future<ServerMeta> meta() async =>
      _parse(await _json(ApiRoutes.meta), ServerMeta.fromJson);

  /// No auth: trades a one-time code for a device token.
  Future<RegisteredDevice> register(
    String code, {
    String? name,
    String? appVersion,
  }) async => _parse(
    await _json(
      ApiRoutes.register,
      body: {'code': code, 'name': ?name, 'app_version': ?appVersion},
    ),
    RegisteredDevice.fromJson,
  );

  Future<ServerStatus> status() async =>
      _parse(await _json(ApiRoutes.status), ServerStatus.fromJson);

  Future<DeviceInfo> deviceMe() async =>
      _parse(await _json(ApiRoutes.deviceMe), DeviceInfo.fromJson);

  /// Revokes this device's token on the server.
  Future<void> unpair() async {
    await _json(ApiRoutes.unpair);
  }
}
