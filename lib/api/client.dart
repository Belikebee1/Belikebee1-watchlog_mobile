import 'package:dio/dio.dart';

import 'models.dart';

/// The plaintext API token + display name returned by a successful pairing
/// exchange. The token is shown only once by the server and must be stored
/// immediately in secure storage.
class PairResult {
  final String token;
  final String name;
  final String deviceId;
  final List<String> scopes;
  const PairResult({
    required this.token,
    required this.name,
    required this.deviceId,
    required this.scopes,
  });
}

/// Exchange a pairing code for a per-device API token.
///
/// This is a STATIC helper because it runs without authentication —
/// there's no token yet. It hits POST /api/v1/pair on the server URL
/// embedded in the QR (or typed by the user). On success the returned
/// [PairResult] contains the plaintext token; on 401 returns null;
/// any other failure throws.
Future<PairResult?> pairWithCode({
  required String baseUrl,
  required String code,
  required String? deviceLabel,
  required String platform,
}) async {
  final cleanedUrl =
      baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
  final dio = Dio(BaseOptions(
    baseUrl: cleanedUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Accept': 'application/json'},
    validateStatus: (s) => s != null && s < 500,
  ));
  final resp = await dio.post<Map<String, dynamic>>(
    '/api/v1/pair',
    data: {
      'code': code.trim().toUpperCase(),
      if (deviceLabel != null && deviceLabel.isNotEmpty) 'device_label': deviceLabel,
      'platform': platform,
    },
  );
  if (resp.statusCode == 401) return null;
  if (resp.statusCode == 429) {
    throw DioException(
      requestOptions: resp.requestOptions,
      response: resp,
      message: 'Too many attempts — wait a minute before retrying.',
    );
  }
  if (resp.statusCode != 200 || resp.data == null) {
    throw DioException(
      requestOptions: resp.requestOptions,
      response: resp,
      message: 'Unexpected response: HTTP ${resp.statusCode}',
    );
  }
  final data = resp.data!;
  return PairResult(
    token: data['token'] as String,
    name: (data['name'] as String?) ?? '',
    deviceId: (data['device_id'] as String?) ?? '',
    scopes: ((data['scopes'] as List<dynamic>?) ?? [])
        .map((e) => e.toString())
        .toList(),
  );
}

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

  /// List action shortcuts the operator has enabled (restart/reboot/logs).
  Future<List<dynamic>> listActions() async {
    final resp = await _dio.get<Map<String, dynamic>>('/api/v1/actions');
    _ensureOk(resp);
    return (resp.data?['actions'] as List?) ?? [];
  }

  Future<ActionResult> restartService(String service) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/api/v1/actions/restart-service',
      data: {'service': service},
    );
    _ensureOk(resp);
    return ActionResult.fromJson(resp.data!);
  }

  Future<ActionResult> rebootHost() async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/api/v1/actions/reboot',
    );
    _ensureOk(resp);
    return ActionResult.fromJson(resp.data!);
  }

  Future<ActionResult> tailLogs(String service, {int lines = 100}) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/api/v1/actions/logs',
      data: {'service': service, 'lines': lines},
    );
    _ensureOk(resp);
    return ActionResult.fromJson(resp.data!);
  }

  /// Fetch human-readable explainers for every check + the severity legend.
  /// Static metadata, bilingual (en/pl). Safe to cache aggressively —
  /// updates ride along with the watchlog backend version.
  Future<Map<String, dynamic>> fetchChecksInfo() async {
    final resp = await _dio.get<Map<String, dynamic>>('/api/v1/checks/info');
    _ensureOk(resp);
    return resp.data!;
  }

  /// Fetch host metadata: hostname, OS, kernel, RAM/disk totals, uptime,
  /// IPs. Static-ish — refreshed on every status screen entry rather
  /// than polled, since these only change when the box reboots or you
  /// resize the VM.
  Future<Map<String, dynamic>> fetchHostInfo() async {
    final resp = await _dio.get<Map<String, dynamic>>('/api/v1/host');
    _ensureOk(resp);
    return resp.data!;
  }

  /// List the last ~90 days of archived runs as one-line summaries.
  /// Each entry includes the worst severity seen that day so the
  /// mobile history browser can color-code the calendar without
  /// fetching every day individually.
  Future<Map<String, dynamic>> listReports() async {
    final resp = await _dio.get<Map<String, dynamic>>('/api/v1/reports');
    _ensureOk(resp);
    return resp.data!;
  }

  /// Full archive of every run for a single day (YYYY-MM-DD). Returns
  /// a list of {ran_at, results} objects in chronological order.
  Future<List<dynamic>> fetchReportForDay(String date) async {
    final resp = await _dio.get<dynamic>('/api/v1/reports/$date');
    _ensureOk(resp);
    final data = resp.data;
    return data is List ? data : [];
  }

  /// Fetch the notification preferences associated with this device's
  /// API token. The server identifies the calling token from the
  /// Bearer header.
  Future<Map<String, dynamic>> fetchNotificationPreferences() async {
    final resp =
        await _dio.get<Map<String, dynamic>>('/api/v1/push/preferences');
    _ensureOk(resp);
    return resp.data!;
  }

  /// Update notification preferences. PATCH semantics — pass only
  /// fields the user actually changed; omit the rest.
  Future<Map<String, dynamic>> updateNotificationPreferences(
      Map<String, dynamic> partial) async {
    final resp = await _dio.patch<Map<String, dynamic>>(
      '/api/v1/push/preferences',
      data: partial,
    );
    _ensureOk(resp);
    return resp.data!;
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
