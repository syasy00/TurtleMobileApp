// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'core/firebase_bootstrap.dart';
import 'core/db.dart'; // 👈 use rtdb here
import 'theme/ app_colors.dart';
import 'pages/auth/auth_screen.dart';
import 'pages/nest_selector_page.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Background Handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you ever need to show a notification here, also ensure Firebase is initialized.
  print("🔥 BACKGROUND MSG RECEIVED: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.ensure();

  // Setup Notification Channel
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupNotifications();
  }

  Future<void> _setupNotifications() async {
    final messaging = FirebaseMessaging.instance;

    // 1. Ask permission
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('🔔 PERMISSION STATUS: ${settings.authorizationStatus}');

    // 2. Local notifications init
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await flutterLocalNotificationsPlugin.initialize(initSettings);

    // 3. Foreground FCM listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("🔥 FOREGROUND MSG RECEIVED!");
      print("   Title: ${message.notification?.title}");
      print("   Body: ${message.notification?.body}");

      final notification = message.notification;
      final android = message.notification?.android;

      if (notification != null && android != null) {
        print("   ✅ Showing Local Banner now...");
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              icon: '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      } else {
        print("   ❌ Notification or Android data was NULL");
      }
    });

    // 4. Save FCM token to *regional* RTDB
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) return;

      final token = await messaging.getToken();
      print("🔑 FCM TOKEN: $token");
      if (token != null) {
        await rtdb
            .ref("users/${user.uid}/fcmToken")
            .set(token); // 👈 use rtdb, not FirebaseDatabase.instance
        print("✅ FCM Token Saved to RTDB (asia-southeast1)");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartShell',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: AppColors.bgBottom,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final user = snap.data;
          if (user == null) {
            return const AuthScreen();
          }
          return const NestSelectorPage();
        },
      ),
    );
  }
}
