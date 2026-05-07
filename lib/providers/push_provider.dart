import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/client.dart';
import '../models/server.dart';
import 'auth_provider.dart';

/// Manages the FCM token lifecycle across all configured servers:
///   - request notification permission (iOS prompt)
///   - fetch token
///   - register the same token on every configured server
///   - re-register on token refresh
///   - register against a newly added server
///   - unregister against a removed server
///   - render foreground notifications via flutter_local_notifications
class PushService {
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  final Ref _ref;
  String? _currentToken;

  PushService(this._ref);

  Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;

    // iOS: ask for permission. Android: granted by default on most versions.
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _local.initialize(const InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    ));

    const channel = AndroidNotificationChannel(
      'watchlog_alerts',
      'watchlog alerts',
      description: 'Server health and security alerts from watchlog',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    messaging.onTokenRefresh.listen(_onTokenRefresh);

    final token = await messaging.getToken();
    if (token != null) {
      _currentToken = token;
      await _registerOnAllServers(token);
    }
  }

  Future<void> _onTokenRefresh(String token) async {
    debugPrint('FCM token refreshed: ${token.substring(0, 16)}...');
    _currentToken = token;
    await _registerOnAllServers(token);
  }

  Future<void> _registerOnAllServers(String token) async {
    final servers = _ref.read(serversProvider).servers;
    if (servers.isEmpty) {
      debugPrint('FCM: no servers configured, skipping register');
      return;
    }
    for (final s in servers) {
      await _registerOnServer(s, token);
    }
  }

  Future<void> _registerOnServer(Server s, String token) async {
    try {
      final api = WatchlogApi(baseUrl: s.baseUrl, token: s.token);
      await api.registerPushToken(
        token: token,
        platform: Platform.isAndroid ? 'android' : 'ios',
        deviceLabel: null,
      );
      debugPrint('FCM token registered on ${s.name}');
    } catch (e) {
      debugPrint('FCM register failed on ${s.name}: $e');
    }
  }

  Future<void> _unregisterOnServer(Server s, String token) async {
    try {
      final api = WatchlogApi(baseUrl: s.baseUrl, token: s.token);
      await api.unregisterPushToken(token);
    } catch (_) {}
  }

  Future<void> _onForegroundMessage(RemoteMessage msg) async {
    final notif = msg.notification;
    if (notif == null) return;
    await _local.show(
      msg.messageId.hashCode,
      notif.title ?? 'watchlog',
      notif.body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'watchlog_alerts',
          'watchlog alerts',
          channelDescription: 'Server health and security alerts from watchlog',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Called after a server is added — register the current FCM token on it.
  Future<void> onServerAdded(Server s) async {
    final token =
        _currentToken ?? await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    _currentToken = token;
    await _registerOnServer(s, token);
  }

  /// Called before a server is removed — drop our FCM token from it so it
  /// stops sending pushes to this device.
  Future<void> onServerRemoved(Server s) async {
    final token = _currentToken;
    if (token == null) return;
    await _unregisterOnServer(s, token);
  }

  /// Called on global sign-out (all servers removed) — unregister token from
  /// every server we know about, then forget it locally.
  Future<void> onSignOutAll() async {
    final token = _currentToken;
    if (token == null) return;
    for (final s in _ref.read(serversProvider).servers) {
      await _unregisterOnServer(s, token);
    }
    _currentToken = null;
  }
}

final pushServiceProvider = Provider<PushService>((ref) => PushService(ref));
