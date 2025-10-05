// core/firebase_bootstrap.dart
import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

class FirebaseBootstrap {
  FirebaseBootstrap._();

  // Cache the in-flight/finished initialization so we never start it twice.
  static Future<FirebaseApp>? _cached;

  static Future<FirebaseApp> ensure() {
    _cached ??= _ensureImpl();
    return _cached!;
  }

  static Future<FirebaseApp> _ensureImpl() async {
    WidgetsFlutterBinding.ensureInitialized();

    if (Firebase.apps.isNotEmpty) {
      return Firebase.apps.first;
    }

    try {
      return await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (e) {
      // If another init beat us to it between the check and the await.
      if (e.code == 'duplicate-app') {
        return Firebase.apps.first;
      }
      rethrow;
    }
  }
}
