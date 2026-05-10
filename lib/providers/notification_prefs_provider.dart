import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_prefs.dart';
import 'auth_provider.dart';

/// Fetches /api/v1/push/preferences for a specific server. Returns
/// [NotificationPreferences.defaults] when the server has no per-device
/// prefs stored (older watchlog or unpaired token), so the UI always
/// has something coherent to render.
final notificationPrefsProvider =
    FutureProvider.family<NotificationPreferences, String>((ref, serverId) async {
  final api = ref.watch(serverApiProvider(serverId));
  if (api == null) return NotificationPreferences.defaults;
  try {
    final raw = await api.fetchNotificationPreferences();
    return NotificationPreferences.fromJson(raw);
  } catch (_) {
    return NotificationPreferences.defaults;
  }
});
