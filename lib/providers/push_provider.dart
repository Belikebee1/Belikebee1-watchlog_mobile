import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';

/// Manages FCM token lifecycle:
///   - request notification permission (iOS prompt)
///   - fetch token
///   - register it with the backend after sign in
///   - re-register on token refresh
///   - display foreground notifications via flutter_local_notifications
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

    // Local notifications setup (we render foreground messages ourselves;
    // background ones are rendered by the OS automatically).
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

    // Android channel matching what the backend names in AndroidConfig
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

    // Foreground messages: render via local notifications
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Token refresh: re-register with backend
    messaging.onTokenRefresh.listen(_onTokenRefresh);

    // Get initial token + register
    final token = await messaging.getToken();
    if (token != null) {
      await _registerToken(token);
    }
  }

  Future<void> _onTokenRefresh(String token) async {
    debugPrint('FCM token refreshed: ${token.substring(0, 16)}...');
    await _registerToken(token);
  }

  Future<void> _registerToken(String token) async {
    if (token == _currentToken) return;
    final api = _ref.read(apiProvider);
    if (api == null) {
      debugPrint('FCM: not signed in yet, skipping register');
      _currentToken = token;
      return;
    }
    try {
      await api.registerPushToken(
        token: token,
        platform: Platform.isAndroid ? 'android' : 'ios',
      );
      _currentToken = token;
      debugPrint('FCM token registered with backend');
    } catch (e) {
      debugPrint('FCM register failed: $e');
    }
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

  /// Called after the user signs in — re-register the token if we have it.
  Future<void> onSignIn() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _registerToken(token);
    }
  }

  /// Called on sign-out — drop the token from the backend so they stop
  /// receiving alerts.
  Future<void> onSignOut() async {
    if (_currentToken == null) return;
    final api = _ref.read(apiProvider);
    if (api == null) return;
    try {
      await api.unregisterPushToken(_currentToken!);
    } catch (_) {}
    _currentToken = null;
  }
}

final pushServiceProvider = Provider<PushService>((ref) => PushService(ref));
