import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

const kDbUrl =
    'https://smartshell-ad097-default-rtdb.asia-southeast1.firebasedatabase.app';

FirebaseDatabase get rtdb =>
    FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: kDbUrl);
