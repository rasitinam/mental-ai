import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/local_prefs.dart';

/// The channel every notification is posted to — must match the
/// `channel_id` the backend puts in the FCM payload
/// (`backend/crates/push/src/lib.rs`) and the manifest's default-channel
/// meta-data, or a backgrounded/terminated notification is silently
/// dropped instead of shown.
const _channelId = 'mental_ai_messages';

final pushServiceProvider = Provider<PushService>((ref) => PushService(ref));

/// Wires up FCM: asks for permission once a session exists, registers the
/// device's token with the backend, keeps it fresh across token rotation,
/// shows a system notification while the app is foregrounded (Android
/// doesn't do this automatically for a "notification"-type FCM message —
/// that's the one case backgrounded/terminated delivery doesn't need any
/// of this code for), and routes a tap straight to the DM thread it's
/// about.
///
/// Deliberately does nothing on web: FCM there needs its own service
/// worker and VAPID key, a separate project this app doesn't have yet —
/// see `main.dart`, which only calls [init] on non-web platforms.
class PushService {
  final Ref _ref;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  PushService(this._ref);

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await Firebase.initializeApp();
    await _initLocalNotifications();

    FirebaseMessaging.onMessage.listen(_showForeground);
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _openThread(m.data));
    final openedFromTerminated = await FirebaseMessaging.instance.getInitialMessage();
    if (openedFromTerminated != null) _openThread(openedFromTerminated.data);

    FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);

    // Covers login, register, and switching accounts on the same device —
    // whatever the path, a session appearing is the one moment this
    // should (re-)ask for permission and register the current token.
    _ref.listen(sessionTokenProvider, (previous, next) {
      if (next != null && previous != next) _requestPermissionAndRegister();
    });

    if (_ref.read(sessionTokenProvider) != null) {
      await _requestPermissionAndRegister();
    }
  }

  Future<void> _initLocalNotifications() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      'Mesajlar',
      description: 'Yeni mesaj istekleri ve mesajlar',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _localNotifications.initialize(
      const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null) return;
        _openThread(jsonDecode(payload) as Map<String, dynamic>);
      },
    );
  }

  Future<void> _requestPermissionAndRegister() async {
    final settings = await FirebaseMessaging.instance.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _registerToken(token);
  }

  Future<void> _registerToken(String token) async {
    if (_ref.read(sessionTokenProvider) == null) return;
    try {
      await _ref.read(apiClientProvider).put('/profile/push-token', data: {
        'token': token,
        'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      });
    } catch (_) {
      // Best-effort: a failed registration just means this device won't
      // get pushes until the next token refresh or app launch retries it.
    }
  }

  /// Called right before the session is cleared (see `settings_screen.dart`
  /// — must run while the auth token is still valid) so a signed-out
  /// device stops receiving notifications for the account it just left.
  Future<void> unregister() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    try {
      await _ref.read(apiClientProvider).delete('/profile/push-token', data: {'token': token});
    } catch (_) {
      // Best-effort, same as registration.
    }
  }

  void _showForeground(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Mesajlar',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _openThread(Map<String, dynamic> data) {
    final threadId = data['thread_id'] as String?;
    if (threadId != null) {
      _ref.read(appRouterProvider).push('/dm/$threadId');
      return;
    }

    // The daily check-in nudge (`scheduler::spawn_checkin_nudge_job` on the
    // backend) carries no thread — tapping it goes straight to the mood
    // form it's reminding someone about.
    if (data['type'] == 'checkin_nudge') {
      _ref.read(appRouterProvider).push('/mood');
    }

    // "Bende de oldu" on one of this person's own stories: their stories
    // list is where the new count shows up.
    if (data['type'] == 'story_metoo') {
      _ref.read(appRouterProvider).go('/settings/my-stories');
    }

  }
}
