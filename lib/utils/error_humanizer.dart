import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Categorized, presentation-ready view of a thrown exception.
///
/// We parse [DioException] (and a few common Dart core exceptions) into a
/// short user-facing title, a longer "what to try" body, an icon, and a
/// suggested next action when one applies (re-pair, check connection,
/// etc.). The original exception text is preserved as [rawDetails] so a
/// "Show details" disclosure can show it for power users / bug reports.
///
/// Why we don't just use `e.toString()`: Dio's default error messages are
/// stack-traces-as-strings — hostile to end users. Our humanizer maps
/// the typical failure modes (network, cert, 401, timeout) to phrasing
/// that says what to *do*, not what went wrong internally.
class HumanError {
  final String title;
  final String body;
  final IconData icon;
  final HumanErrorAction? action;
  final String rawDetails;

  const HumanError({
    required this.title,
    required this.body,
    required this.icon,
    required this.rawDetails,
    this.action,
  });
}

enum HumanErrorAction {
  /// Token rejected — user should re-pair or remove the server. Surfaced
  /// as a button labelled "Open settings".
  rePair,

  /// Token doesn't have the scope for this action. Operator must
  /// regenerate with broader scopes.
  rescope,

  /// Generic "try again later" — server overloaded, rate-limited, or
  /// transient network. Surfaced as a "Retry" button (caller wires it).
  retry,

  /// Endpoint missing — backend likely on an older watchlog. Surfaced
  /// as advisory text only; no action button (operator-only fix).
  upgradeBackend,
}

/// Convert any [Object] into a [HumanError]. Recognizes [DioException]
/// shapes and the standard Dart timeout / socket exceptions; everything
/// else falls back to a generic "Unexpected error" with the raw text in
/// details.
HumanError humanize(Object error) {
  final raw = error.toString();

  if (error is DioException) {
    return _humanizeDio(error, raw);
  }

  // Network exceptions can come bare (Future.wait unwraps), e.g.
  // SocketException or HttpException. Detect by string match — Dart
  // doesn't expose them through a stable hierarchy.
  if (raw.contains('SocketException') ||
      raw.contains('Failed host lookup')) {
    return HumanError(
      title: 'Cannot reach server',
      body: 'Check your internet connection or verify the server is online.',
      icon: Icons.wifi_off_outlined,
      action: HumanErrorAction.retry,
      rawDetails: raw,
    );
  }
  if (raw.contains('TimeoutException') || raw.contains('timeout')) {
    return HumanError(
      title: 'Request timed out',
      body: 'The server took too long to respond. Try again in a moment.',
      icon: Icons.timer_off_outlined,
      action: HumanErrorAction.retry,
      rawDetails: raw,
    );
  }

  return HumanError(
    title: 'Unexpected error',
    body: 'Something went wrong. Tap "Show details" to see the raw error.',
    icon: Icons.error_outline,
    action: HumanErrorAction.retry,
    rawDetails: raw,
  );
}

HumanError _humanizeDio(DioException e, String raw) {
  // Connection-layer failures (no response received yet)
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return HumanError(
        title: 'Request timed out',
        body: 'The server took too long to respond. Check that the daemon '
            'is running and reachable.',
        icon: Icons.timer_off_outlined,
        action: HumanErrorAction.retry,
        rawDetails: raw,
      );
    case DioExceptionType.connectionError:
      return HumanError(
        title: 'Cannot reach server',
        body: 'No connection to the server. Check your internet, or '
            'whether the watchlog daemon is up and the URL is correct.',
        icon: Icons.cloud_off_outlined,
        action: HumanErrorAction.retry,
        rawDetails: raw,
      );
    case DioExceptionType.badCertificate:
      return HumanError(
        title: 'Certificate problem',
        body: 'The server\'s TLS certificate is invalid or expired. The '
            'app refuses to send your token over an insecure connection.',
        icon: Icons.gpp_bad_outlined,
        rawDetails: raw,
      );
    case DioExceptionType.cancel:
      return HumanError(
        title: 'Request cancelled',
        body: 'The request was cancelled.',
        icon: Icons.cancel_outlined,
        rawDetails: raw,
      );
    case DioExceptionType.unknown:
      // Falls through to status-code parsing below if there's a response,
      // otherwise bare message.
      if (e.response == null) {
        return HumanError(
          title: 'Network error',
          body: e.message?.isNotEmpty == true
              ? e.message!
              : 'Request failed before reaching the server.',
          icon: Icons.signal_wifi_bad_outlined,
          action: HumanErrorAction.retry,
          rawDetails: raw,
        );
      }
      break;
    case DioExceptionType.badResponse:
      // Handled below by status-code branching.
      break;
  }

  final status = e.response?.statusCode;
  switch (status) {
    case 400:
      return HumanError(
        title: 'Bad request',
        body: 'The server rejected the request shape. This usually means '
            'the app and server are on incompatible versions.',
        icon: Icons.report_outlined,
        action: HumanErrorAction.upgradeBackend,
        rawDetails: raw,
      );
    case 401:
      return HumanError(
        title: 'Token rejected',
        body: 'Your device token is invalid or has been revoked. Re-pair '
            'this server from Settings.',
        icon: Icons.lock_outlined,
        action: HumanErrorAction.rePair,
        rawDetails: raw,
      );
    case 403:
      return HumanError(
        title: 'Permission denied',
        body: 'Your token doesn\'t include the scope this action needs. '
            'Re-pair with broader scopes on the server (watchlog api qr).',
        icon: Icons.no_accounts_outlined,
        action: HumanErrorAction.rescope,
        rawDetails: raw,
      );
    case 404:
      return HumanError(
        title: 'Not found',
        body: 'The server doesn\'t expose this endpoint. The watchlog '
            'backend may need to be upgraded.',
        icon: Icons.search_off_outlined,
        action: HumanErrorAction.upgradeBackend,
        rawDetails: raw,
      );
    case 429:
      return HumanError(
        title: 'Too many requests',
        body: 'Rate limit hit. Wait a minute, then try again.',
        icon: Icons.hourglass_empty,
        action: HumanErrorAction.retry,
        rawDetails: raw,
      );
    case 503:
      return HumanError(
        title: 'No data yet',
        body: 'The server hasn\'t completed a watchlog run yet, so there '
            'is no heartbeat to show. Tap "Run now" to trigger one.',
        icon: Icons.hourglass_top_outlined,
        rawDetails: raw,
      );
    case null:
      return HumanError(
        title: 'Network error',
        body: e.message ?? 'Request failed.',
        icon: Icons.signal_wifi_bad_outlined,
        action: HumanErrorAction.retry,
        rawDetails: raw,
      );
    default:
      if (status >= 500) {
        return HumanError(
          title: 'Server error',
          body: 'The watchlog daemon returned $status. Check the server '
              'logs (journalctl -u watchlog-api).',
          icon: Icons.dns_outlined,
          action: HumanErrorAction.retry,
          rawDetails: raw,
        );
      }
      return HumanError(
        title: 'Request failed (HTTP $status)',
        body: 'The server returned an unexpected status. Tap "Show details" '
            'for the raw response.',
        icon: Icons.error_outline,
        action: HumanErrorAction.retry,
        rawDetails: raw,
      );
  }
}

/// Quick one-liner for snackbars when there's no room for a full
/// [HumanError]. Always falls back to "Failed" if humanizing produces an
/// empty title for some reason.
String shortMessage(Object error) {
  final h = humanize(error);
  return h.title.isNotEmpty ? h.title : 'Failed';
}
