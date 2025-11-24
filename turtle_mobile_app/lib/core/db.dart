// core/db.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

/// IMPORTANT: this MUST be the asia-southeast1 URL (the one from the log)
const kDbUrl =
    'https://smartshell-ad097-default-rtdb.asia-southeast1.firebasedatabase.app';

/// Always use this instead of FirebaseDatabase.instance
FirebaseDatabase get rtdb => FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: kDbUrl,
    );
