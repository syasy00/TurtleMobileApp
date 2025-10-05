// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web not configured.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError('macOS not configured.');
      case TargetPlatform.windows:
        throw UnsupportedError('Windows not configured.');
      case TargetPlatform.linux:
        throw UnsupportedError('Linux not configured.');
      default:
        throw UnsupportedError('Unsupported platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAulGpL5DEiScuICjZMTBlyMjLQLcMfbq4',
    appId: '1:558606073661:android:2bf394ce9b4b4f8742cf54',
    messagingSenderId: '558606073661',
    projectId: 'smartshell-ad097',
    storageBucket: 'smartshell-ad097.firebasestorage.app',
    databaseURL:
        'https://smartshell-ad097-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCWQPaiPPApzzaqPs6-Q0QWBAfjowkfKi8',
    appId: '1:558606073661:ios:c9bdd71fcd5b2ffe42cf54',
    messagingSenderId: '558606073661',
    projectId: 'smartshell-ad097',
    storageBucket: 'smartshell-ad097.firebasestorage.app',
    iosBundleId: 'com.example.turtleMobileApp',
    databaseURL:
        'https://smartshell-ad097-default-rtdb.asia-southeast1.firebasedatabase.app',
  );
}
