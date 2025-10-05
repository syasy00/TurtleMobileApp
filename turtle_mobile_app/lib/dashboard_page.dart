// lib/models/dashboard_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../core/db.dart';

class SmartHubTemperaturePage extends StatefulWidget {
  final String nestId;
  final String nestName;
  final double temperature; // fallback
  final double humidity;    // fallback
  final bool isDarkMode;

  const SmartHubTemperaturePage({
    super.key,
    required this.nestId,
    required this.nestName,
    required this.temperature,
    required this.humidity,
    required this.isDarkMode,
  });

  @override
  State<SmartHubTemperaturePage> createState() => _SmartHubTemperaturePageState();
}

class _SmartHubTemperaturePageState extends State<SmartHubTemperaturePage> {
  bool isFanOn = false;
  bool isMisterOn = false;
  bool isBulbOn = false; // NEW

  double currentTemp = 0;
  double currentHumidity = 0;
  int? lastUpdatedMs;

  late final DatabaseReference _nestRef;
  StreamSubscription<DatabaseEvent>? _sub;

  final List<_DataPoint> _fallbackPoints = const [
    _DataPoint(time: "Mon", temp: 29.5, humidity: 60),
    _DataPoint(time: "Tue", temp: 30.0, humidity: 62),
    _DataPoint(time: "Wed", temp: 30.8, humidity: 65),
    _DataPoint(time: "Thu", temp: 31.4, humidity: 67),
    _DataPoint(time: "Fri", temp: 31.8, humidity: 68),
    _DataPoint(time: "Sat", temp: 32.0, humidity: 69),
    _DataPoint(time: "Sun", temp: 32.2, humidity: 70),
  ];

  List<_DataPoint> history = [];

  List<FlSpot> get tempSpots =>
      history.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.temp)).toList();

  @override
  void initState() {
    super.initState();
    currentTemp = widget.temperature;
    currentHumidity = widget.humidity;
    history = _fallbackPoints.toList();
    _initRtdb();
    _loadDeviceStates();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  dynamic _pick(Map m, List<String> keys) {
    for (final k in keys) {
      if (m.containsKey(k)) return m[k];
    }
    return null;
  }

  Future<void> _initRtdb() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _nestRef = rtdb.ref('nests/$uid/${widget.nestId}');
    _sub = _nestRef.onValue.listen((event) {
      final val = event.snapshot.value;
      final Map<String, dynamic> m =
          (val is Map) ? Map<String, dynamic>.from(val as Map) : {};

      final tAny = _pick(m, ['temperature', 'Temperature']) ?? currentTemp;
      final hAny = _pick(m, ['humidity', 'Humidity']) ?? currentHumidity;
      final t = (tAny as num).toDouble();
      final h = (hAny as num).toDouble();

      final rawCtrls = _pick(m, ['controls', 'Controls']);
      final Map<String, dynamic> ctrls =
          (rawCtrls is Map) ? Map<String, dynamic>.from(rawCtrls as Map) : {};

      final fan = (_pick(ctrls, ['fan', 'Fan']) ?? isFanOn) == true;
      final misterVal = _pick(ctrls, ['mister', 'Mister', 'Humidifier']);
      final mister = (misterVal ?? isMisterOn) == true;
      final bulb = (_pick(ctrls, ['bulb', 'Bulb', 'light', 'Light']) ?? isBulbOn) == true; // NEW

      lastUpdatedMs =
          _pick(m, ['updatedAt', 'UpdatedAt', 'createdAt', 'CreatedAt']) as int?;

      setState(() {
        currentTemp = t;
        currentHumidity = h;
        isFanOn = fan;
        isMisterOn = mister;
        isBulbOn = bulb; // NEW
      });
    });
  }

  Future<void> _loadDeviceStates() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isFanOn = prefs.getBool('${widget.nestName}_fan') ?? false;
      isMisterOn = prefs.getBool('${widget.nestName}_mister') ?? false;
      isBulbOn = prefs.getBool('${widget.nestName}_bulb') ?? false; // NEW
    });
  }

  Future<void> _saveDeviceState(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${widget.nestName}_$key', value);
  }

  Future<void> _writeControlToRtdb(String key, bool value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final base = rtdb.ref('nests/$uid/${widget.nestId}');
    await base.child('controls/$key').set(value);
    // Write a couple of aliases for compatibility with older data:
    if (key == 'fan') {
      await base.child('Controls/Fan').set(value);
    } else if (key == 'mister') {
      await base.child('Controls/Humidifier').set(value);
    } else if (key == 'bulb') {
      await base.child('Controls/Bulb').set(value);
      await base.child('Controls/Light').set(value);
    }
    await base.child('updatedAt').set(ServerValue.timestamp);
  }

  void _toggleFan() {
    final next = !isFanOn;
    setState(() => isFanOn = next);
    _saveDeviceState('fan', next);
    _writeControlToRtdb('fan', next);
  }

  void _toggleMister() {
    final next = !isMisterOn;
    setState(() => isMisterOn = next);
    _saveDeviceState('mister', next);
    _writeControlToRtdb('mister', next);
  }

  void _toggleBulb() { // NEW
    final next = !isBulbOn;
    setState(() => isBulbOn = next);
    _saveDeviceState('bulb', next);
    _writeControlToRtdb('bulb', next);
  }

  bool get tempInRange => currentTemp >= 29 && currentTemp <= 32;
  bool get humidityInRange => currentHumidity >= 65 && currentHumidity <= 75;

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : Colors.black;
    final bgColor = widget.isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFF9F9FB);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _nestRef.child('updatedAt').set(ServerValue.timestamp),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: widget.isDarkMode ? Colors.white : Colors.black87),
                          onPressed: () => Navigator.pop(context),
                          tooltip: 'Back',
                        ),
                        Text(widget.nestName,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textColor)),
                      ],
                    ),
                    if (lastUpdatedMs != null)
                      Text(_friendlyUpdated(lastUpdatedMs!),
                          style: TextStyle(fontSize: 11, color: widget.isDarkMode ? Colors.white60 : Colors.grey)),
                  ],
                ),

                const SizedBox(height: 16),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    _chip(
                      tempInRange ? "Temp OK" : "Temp Out of Range",
                      tempInRange ? (widget.isDarkMode ? Colors.greenAccent : Colors.green.shade100)
                                   : (widget.isDarkMode ? Colors.redAccent : Colors.red.shade100),
                      widget.isDarkMode ? Colors.black : Colors.black87,
                    ),
                    _chip(
                      humidityInRange ? "Humidity OK" : "Humidity Out of Range",
                      humidityInRange ? (widget.isDarkMode ? Colors.greenAccent : Colors.green.shade100)
                                      : (widget.isDarkMode ? Colors.redAccent : Colors.red.shade100),
                      widget.isDarkMode ? Colors.black : Colors.black87,
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 10, end: currentTemp),
                    duration: const Duration(milliseconds: 900),
                    builder: (context, animatedTemp, child) {
                      return SfRadialGauge(
                        axes: [
                          RadialAxis(
                            minimum: 10, maximum: 40, startAngle: 150, endAngle: 30,
                            showTicks: false, showLabels: true, labelsPosition: ElementsPosition.outside,
                            axisLabelStyle: GaugeTextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.bold),
                            axisLineStyle: const AxisLineStyle(
                              thickness: 0.2, thicknessUnit: GaugeSizeUnit.factor, cornerStyle: CornerStyle.bothCurve,
                            ),
                            ranges: [
                              GaugeRange(
                                startValue: 10, endValue: animatedTemp, color: Colors.redAccent,
                                startWidth: 0.2, endWidth: 0.2, sizeUnit: GaugeSizeUnit.factor,
                              ),
                            ],
                            annotations: [
                              GaugeAnnotation(
                                angle: 90, positionFactor: 0.1,
                                widget: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text("${animatedTemp.toStringAsFixed(1)}°C",
                                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                                    const SizedBox(height: 4),
                                    Text("Humidity: ${currentHumidity.toStringAsFixed(0)}%",
                                        style: TextStyle(fontSize: 12, color: widget.isDarkMode ? Colors.white60 : Colors.grey)),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),
                Text("Temperature Trend",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 160,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              const labels = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"];
                              final i = value.toInt();
                              return i >= 0 && i < labels.length
                                  ? Text(labels[i], style: TextStyle(fontSize: 10, color: textColor))
                                  : const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: tempSpots,
                          isCurved: true,
                          barWidth: 2,
                          color: Colors.redAccent,
                          dotData: FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Text("Devices", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _deviceCard(
                      title: "Fan",
                      icon: Icons.air,
                      active: isFanOn,
                      activeColor: Colors.orange,
                      bgActive: Colors.orangeAccent.withOpacity(0.2),
                      onTap: _toggleFan,
                      isDark: widget.isDarkMode,
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _deviceCard(
                      title: "Mister",
                      icon: Icons.water,
                      active: isMisterOn,
                      activeColor: Colors.redAccent,
                      bgActive: Colors.redAccent,
                      onTap: _toggleMister,
                      isDark: widget.isDarkMode,
                      invertOnActive: true,
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _deviceCard( // NEW Bulb
                      title: "Bulb",
                      icon: Icons.lightbulb_outline,
                      active: isBulbOn,
                      activeColor: Colors.amber.shade700,
                      bgActive: Colors.amber.shade200,
                      onTap: _toggleBulb,
                      isDark: widget.isDarkMode,
                    )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _deviceCard({
    required String title,
    required IconData icon,
    required bool active,
    required Color activeColor,
    required Color bgActive,
    required VoidCallback onTap,
    required bool isDark,
    bool invertOnActive = false,
  }) {
    final bg = active ? bgActive : (isDark ? Colors.grey[850]! : Colors.white);
    final fg = active
        ? (invertOnActive ? Colors.white : activeColor)
        : (invertOnActive ? Colors.redAccent : (isDark ? Colors.white : Colors.black87));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Icon(icon, color: fg, size: 28),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: fg)),
            Text("Tap to ${active ? "turn off" : "turn on"}",
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w600)),
    );
  }

  String _friendlyUpdated(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}";
  }
}

class _DataPoint {
  final String time;
  final double temp;
  final int humidity;
  const _DataPoint({required this.time, required this.temp, required this.humidity});
}
