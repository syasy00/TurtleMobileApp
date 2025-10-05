import 'package:firebase_database/firebase_database.dart';

class SensorData {
  final double temperature;
  final double humidity;
  final DateTime timestamp;

  SensorData({required this.temperature, required this.humidity, required this.timestamp});

final DatabaseReference _db = FirebaseDatabase.instance.reference();

  Future<void> updateSensorData(double temp, double humidity) async {
    await _db.child('sensorData').set({
      'temperature': temp,
      'humidity': humidity,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}