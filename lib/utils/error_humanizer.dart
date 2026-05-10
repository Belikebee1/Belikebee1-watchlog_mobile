import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../l10n/strings.dart';

/// Categorized, presentation-ready view of a thrown exception.
///
/// We parse [DioException] (and a few common Dart core exceptions) into a
/// short user-facing title, a longer "what to try" body, an icon, and a
/// suggested next action when one applies (re-pair, check connection,
/// etc.). The original exception text is preserved as [rawDetails] so a
/// "Show details" disclosure can show it for power users / bug reports.
///
/// All strings come through the i18n catalogue, so the same exception
/// renders in PL or EN depending on the user's locale.
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
  /// Token rejected — user should re-pair or remove the server.
  rePair,

  /// Token doesn't have the scope for this action.
  rescope,

  /// Generic "try again later" — server overloaded, rate-limited, or
  /// transient network.
  retry,

  /// Endpoint missing — backend likely on an older watchlog.
  upgradeBackend,
}

/// Convert any [Object] into a [HumanError], localized via [context].
HumanError humanize(BuildContext context, Object error) {
  final raw = error.toString();

  if (error is DioException) {
    return _humanizeDio(context, error, raw);
  }

  if (raw.contains('SocketException') ||
      raw.contains('Failed host lookup')) {
    return HumanError(
      title: tr(context, S.errCannotReachTitle),
      body: tr(context, S.errCannotReachBody),
      icon: Icons.wifi_off_outlined,
      action: HumanErrorAction.retry,
      rawDetails: raw,
    );
  }
  if (raw.contains('TimeoutException') || raw.contains('timeout')) {
    return HumanError(
      title: tr(context, S.errTimeoutTitle),
      body: tr(context, S.errTimeoutBody),
      icon: Icons.timer_off_outlined,
      action: HumanErrorAction.retry,
      rawDetails: raw,
    );
  }

  return HumanError(
    title: tr(context, S.errUnknownTitle),
    body: tr(context, S.errUnknownBody),
    icon: Icons.error_outline,
    action: HumanErrorAction.retry,
    rawDetails: raw,
  );
}

HumanError _humanizeDio(
    BuildContext context, DioException e, String raw) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return HumanError(
        title: tr(context, S.errTimeoutTitle),
        body: tr(context, S.errTimeoutBody),
        icon: Icons.timer_off_outlined,
        action: HumanErrorAction.retry,
        rawDetails: raw,
      );
    case DioExceptionType.connectionError:
      return HumanError(
        title: tr(context, S.errCannotReachTitle),
        body: tr(context, S.errCannotReachBody),
        icon: Icons.cloud_off_outlined,
        action: HumanErrorAction.retry,
        rawDetails: raw,
      );
    case DioExceptionType.badCertificate:
      return HumanError(
        title: tr(context, S.errCertTitle),
        body: tr(context, S.errCertBody),
        icon: Icons.gpp_bad_outlined,
        rawDetails: raw,
      );
    case DioExceptionType.cancel:
      return HumanError(
        title: tr(context, S.errCancelledTitle),
        body: tr(context, S.errCancelledBody),
        icon: Icons.cancel_outlined,
        rawDetails: raw,
      );
    case DioExceptionType.unknown:
      if (e.response == null) {
        return HumanError(
          title: tr(context, S.errNetworkTitle),
          body: e.message?.isNotEmpty == true
              ? e.message!
              : tr(context, S.errNetworkBody),
          icon: Icons.signal_wifi_bad_outlined,
          action: HumanErrorAction.retry,
          rawDetails: raw,
        );
      }
      break;
    case DioExceptionType.badResponse:
      break;
  }

  final status = e.response?.statusCode;
  switch (status) {
    case 400:
      return HumanError(
        title: tr(context, S.errBadRequestTitle),
        body: tr(context, S.errBadRequestBody),
        icon: Icons.report_outlined,
        action: HumanErrorAction.upgradeBackend,
        rawDetails: raw,
      );
    case 401:
      return HumanError(
        title: tr(context, S.errTokenRejectedTitle),
        body: tr(context, S.errTokenRejectedBody),
        icon: Icons.lock_outlined,
        action: HumanErrorAction.rePair,
        rawDetails: raw,
      );
    case 403:
      return HumanError(
        title: tr(context, S.errPermissionTitle),
        body: tr(context, S.errPermissionBody),
        icon: Icons.no_accounts_outlined,
        action: HumanErrorAction.rescope,
        rawDetails: raw,
      );
    case 404:
      return HumanError(
        title: tr(context, S.errNotFoundTitle),
        body: tr(context, S.errNotFoundBody),
        icon: Icons.search_off_outlined,
        action: HumanErrorAction.upgradeBackend,
        rawDetails: raw,
      );
    case 429:
      return HumanError(
        title: tr(context, S.errRateLimitTitle),
        body: tr(context, S.errRateLimitBody),
        icon: Icons.hourglass_empty,
        action: HumanErrorAction.retry,
        rawDetails: raw,
      );
    case 503:
      return HumanError(
        title: tr(context, S.errNoDataTitle),
        body: tr(context, S.errNoDataBody),
        icon: Icons.hourglass_top_outlined,
        rawDetails: raw,
      );
    case null:
      return HumanError(
        title: tr(context, S.errNetworkTitle),
        body: e.message ?? tr(context, S.errNetworkBody),
        icon: Icons.signal_wifi_bad_outlined,
        action: HumanErrorAction.retry,
        rawDetails: raw,
      );
    default:
      if (status >= 500) {
        return HumanError(
          title: tr(context, S.errServerTitle),
          body: tr(context, S.errServerBody),
          icon: Icons.dns_outlined,
          action: HumanErrorAction.retry,
          rawDetails: raw,
        );
      }
      return HumanError(
        title:
            tr(context, S.errRequestFailedHttp, subs: {'status': '$status'}),
        body: tr(context, S.errRequestFailedBody),
        icon: Icons.error_outline,
        action: HumanErrorAction.retry,
        rawDetails: raw,
      );
  }
}

/// Quick one-liner for snackbars when there's no room for a full
/// [HumanError].
String shortMessage(BuildContext context, Object error) {
  final h = humanize(context, error);
  return h.title.isNotEmpty ? h.title : 'Failed';
}
