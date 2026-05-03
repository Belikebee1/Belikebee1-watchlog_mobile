import 'package:dio/dio.dart';

import 'models.dart';

/// Thin wrapper over Dio with auth + base URL injection.
class WatchlogApi {
  final Dio _dio;
  final String baseUrl;
  final String token;

  WatchlogApi({required this.baseUrl, required this.token})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          validateStatus: (s) => s != null && s < 500,
        ));

  /// Verifies the token by hitting /api/v1/status.
  /// Returns true if 200, false if 401. Throws on other errors.
  Future<bool> verifyToken() async {
    final resp = await _dio.get<dynamic>('/api/v1/status');
    if (resp.statusCode == 401) return false;
    if (resp.statusCode == 503) return true; // valid token, just no data yet
    return resp.statusCode == 200;
  }

  Future<Status> getStatus() async {
    final resp = await _dio.get<Map<String, dynamic>>('/api/v1/status');
    _ensureOk(resp);
    return Status.fromJson(resp.data!);
  }

  Future<StateData> getState() async {
    final resp = await _dio.get<Map<String, dynamic>>('/api/v1/state');
    _ensureOk(resp);
    return StateData.fromJson(resp.data!);
  }

  Future<void> snooze(String check, int hours) async {
    final resp = await _dio.post<dynamic>(
      '/api/v1/state/snooze',
      data: {'check': check, 'hours': hours},
    );
    _ensureOk(resp);
  }

  Future<void> ignore(String check) async {
    final resp = await _dio.post<dynamic>(
      '/api/v1/state/ignore',
      data: {'check': check},
    );
    _ensureOk(resp);
  }

  Future<void> unsnooze(String check) async {
    final resp = await _dio.delete<dynamic>(
      '/api/v1/state/snooze/${Uri.encodeComponent(check)}',
    );
    _ensureOk(resp);
  }

  Future<void> unignore(String check) async {
    final resp = await _dio.delete<dynamic>(
      '/api/v1/state/ignore/${Uri.encodeComponent(check)}',
    );
    _ensureOk(resp);
  }

  Future<ActionResult> runWatchlog() async {
    final resp = await _dio.post<Map<String, dynamic>>('/api/v1/runs');
    _ensureOk(resp);
    return ActionResult.fromJson(resp.data!);
  }

  Future<ActionResult> applySecurityUpdates() async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/api/v1/actions/apply-security',
    );
    _ensureOk(resp);
    return ActionResult.fromJson(resp.data!);
  }

  Future<void> registerPushToken({
    required String token,
    required String platform,
    String? deviceLabel,
  }) async {
    final resp = await _dio.post<dynamic>(
      '/api/v1/push/register',
      data: {
        'token': token,
        'platform': platform,
        if (deviceLabel != null) 'device_label': deviceLabel,
      },
    );
    _ensureOk(resp);
  }

  Future<void> unregisterPushToken(String token) async {
    final resp = await _dio.delete<dynamic>(
      '/api/v1/push/register/${Uri.encodeComponent(token)}',
    );
    _ensureOk(resp);
  }

  void _ensureOk(Response resp) {
    if (resp.statusCode == null || resp.statusCode! >= 400) {
      throw DioException(
        requestOptions: resp.requestOptions,
        response: resp,
        message: 'HTTP ${resp.statusCode}',
      );
    }
  }
}
