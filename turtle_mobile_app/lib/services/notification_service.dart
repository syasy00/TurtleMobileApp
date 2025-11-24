import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

// Background handler must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need to use other Firebase services here, initialize them first
  // await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

class NotificationService {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> init() async {
    // 1. Request Permissions
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Initialize Local Notifications (for foreground display)
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings, 
        iOS: iosSettings
      ),
      onDidReceiveNotificationResponse: (response) {
        // Handle notification tap logic here
        if (response.payload != null) {
          // Navigate to specific screen based on payload
        }
      },
    );

    // 3. Get Device Token (Send this to your server/database)
    final fcmToken = await _firebaseMessaging.getToken();
    if (kDebugMode) {
      print("FCM Token: $fcmToken");
    }

    // 4. Handle Background Messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final android = message.notification?.android;

      // If notification exists, show it locally
      if (notification != null && android != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel', // id
              'High Importance Notifications', // title
              channelDescription: 'This channel is used for important notifications.',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: DarwinNotificationDetails(),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });
  }
}