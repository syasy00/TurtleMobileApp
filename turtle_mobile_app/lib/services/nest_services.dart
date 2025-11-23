import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../core/db.dart';
import '../models/nest.dart';

class NestService {
  Stream<List<Nest>> listenUserNests(String uid) {
    final ref = rtdb.ref('nests/$uid');
    return ref.onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is! Map) return <Nest>[];
      final data = Map<String, dynamic>.from(raw as Map);
      final list = <Nest>[];
      data.forEach((key, value) {
        if (value is Map) {
          list.add(Nest.fromMap(key, Map<String, dynamic>.from(value)));
        }
      });
      return list;
    });
  }

  Future<void> submitPairRequest(String uid, String code) async {
    await rtdb.ref('pairRequests/$uid').set({
      'pendingCode': code,
      'requestedAt': ServerValue.timestamp,
    });
  }

  /// Creates a nest in RTDB and returns the generated key (or localId fallback).
  Future<String> createNest({
    required String uid,
    required String name,
    required String location,
    required double temp,
    required double humidity,
    required bool fanOn,
    required bool misterOn,
    required bool bulbOn,
  }) async {
    final ref = rtdb.ref('nests/$uid').push();
    await ref.set({
      'name': name,
      'location': location,
      'temperature': temp,
      'humidity': humidity,
      'controls': {'fan': fanOn, 'mister': misterOn, 'bulb': bulbOn},
      'createdAt': ServerValue.timestamp,
    });
    return ref.key ?? 'local-${DateTime.now().millisecondsSinceEpoch}';
  }
}
