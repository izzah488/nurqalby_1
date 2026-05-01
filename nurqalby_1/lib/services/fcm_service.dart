import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    await _messaging.requestPermission();

    String? token = await _messaging.getToken();
    print("🔥 FCM TOKEN: $token");

    // 🔹 Foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 Foreground: ${message.notification?.title}");
    });

    // 🔹 When notification tapped (background → open app)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNavigation(message, navigatorKey);
    });

    // 🔹 When app terminated → opened via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNavigation(initialMessage, navigatorKey);
    }
  }

  static void _handleNavigation(
      RemoteMessage message,
      GlobalKey<NavigatorState> navigatorKey,
      ) {
    final data = message.data;

    if (data['type'] == 'dua') {
      navigatorKey.currentState?.pushNamed('/dua-detail', arguments: data);
    }
  }
}
