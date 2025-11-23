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
  bool isBulbOn = false;

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

  // ---------- RTDB helpers (unchanged) ----------
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
      final bulb = (_pick(ctrls, ['bulb', 'Bulb', 'light', 'Light']) ?? isBulbOn) == true;

      lastUpdatedMs =
          _pick(m, ['updatedAt', 'UpdatedAt', 'createdAt', 'CreatedAt']) as int?;

      setState(() {
        currentTemp = t;
        currentHumidity = h;
        isFanOn = fan;
        isMisterOn = mister;
        isBulbOn = bulb;
      });
    });
  }

  Future<void> _loadDeviceStates() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isFanOn = prefs.getBool('${widget.nestName}_fan') ?? false;
      isMisterOn = prefs.getBool('${widget.nestName}_mister') ?? false;
      isBulbOn = prefs.getBool('${widget.nestName}_bulb') ?? false;
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

  void _toggleFan()   { final v = !isFanOn;   setState(()=>isFanOn=v);   _saveDeviceState('fan', v);   _writeControlToRtdb('fan', v); }
  void _toggleMister(){ final v = !isMisterOn;setState(()=>isMisterOn=v);_saveDeviceState('mister', v);_writeControlToRtdb('mister', v); }
  void _toggleBulb()  { final v = !isBulbOn;  setState(()=>isBulbOn=v);  _saveDeviceState('bulb', v);  _writeControlToRtdb('bulb', v); }

  bool get tempInRange => currentTemp >= 29 && currentTemp <= 32;
  bool get humidityInRange => currentHumidity >= 65 && currentHumidity <= 75;

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final dark = widget.isDarkMode;
    final colors = _Palette.of(dark);

    return Scaffold(
      backgroundColor: colors.bg, // gradient behind SafeArea
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors.bgGradient,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: colors.accent,
            onRefresh: () async => _nestRef.child('updatedAt').set(ServerValue.timestamp),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      _roundBtn(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => Navigator.pop(context),
                        bg: colors.card,
                        fg: colors.onCard.withOpacity(.9),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.nestName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700, color: colors.textPrimary),
                        ),
                      ),
                      if (lastUpdatedMs != null) ...[
                        const SizedBox(width: 8),
                        _chip(
                          _friendlyUpdated(lastUpdatedMs!),
                          fg: colors.textSecondary,
                          bg: colors.card,
                          dense: true,
                          icon: Icons.schedule_rounded,
                        )
                      ]
                    ],
                  ),

                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10, runSpacing: 10,
                    children: [
                      _chip(
                        tempInRange ? "Temp OK" : "Temp out of range",
                        bg: tempInRange ? colors.okBg : colors.warnBg,
                        fg: tempInRange ? colors.okFg : colors.warnFg,
                        icon: tempInRange ? Icons.check_circle_rounded : Icons.error_rounded,
                      ),
                      _chip(
                        humidityInRange ? "Humidity OK" : "Humidity out of range",
                        bg: humidityInRange ? colors.okBg : colors.warnBg,
                        fg: humidityInRange ? colors.okFg : colors.warnFg,
                        icon: humidityInRange ? Icons.water_drop_rounded : Icons.water_damage_rounded,
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  _glassCard(
                    colors: colors,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _heroGauge(colors),
                        const SizedBox(height: 10),
                        Text(
                          "Target range: 29–32°C • 65–75%",
                          style: TextStyle(fontSize: 12, color: colors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),
                  _glassCard(
                    colors: colors,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Temperature Trend",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 180,
                          child: LineChart(
                            LineChartData(
                              minY: 10,
                              maxY: 40,
                              backgroundColor: Colors.transparent,
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (_) => FlLine(
                                  strokeWidth: 0.4, color: colors.grid),
                              ),
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    reservedSize: 30,
                                    showTitles: true,
                                    interval: 5,
                                    getTitlesWidget: (v, _) => Text(
                                      v.toInt().toString(),
                                      style: TextStyle(fontSize: 10, color: colors.textTertiary),
                                    ),
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, _) {
                                      const labels = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"];
                                      final i = value.toInt();
                                      return i >= 0 && i < labels.length
                                          ? Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Text(labels[i],
                                                  style: TextStyle(fontSize: 10, color: colors.textTertiary)),
                                            )
                                          : const SizedBox.shrink();
                                    },
                                  ),
                                ),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: tempSpots,
                                  isCurved: true,
                                  barWidth: 3,
                                  color: colors.accent,
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [colors.accent.withOpacity(.25), Colors.transparent],
                                    ),
                                  ),
                                  dotData: FlDotData(show: true, getDotPainter: (p, d, b, i) {
                                    return FlDotCirclePainter(radius: 2.8, color: colors.accent, strokeColor: colors.card, strokeWidth: 2);
                                  }),
                                ),
                              ],
                              borderData: FlBorderData(
                                show: true,
                                border: Border.all(width: 0.6, color: colors.border),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text("Devices",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _deviceToggle(
                          title: "Fan",
                          icon: Icons.air_rounded,
                          on: isFanOn,
                          onTap: _toggleFan,
                          colors: colors,
                          activeColor: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _deviceToggle(
                          title: "Mister",
                          icon: Icons.water_drop_rounded,
                          on: isMisterOn,
                          onTap: _toggleMister,
                          colors: colors,
                          activeColor: Colors.pinkAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _deviceToggle(
                          title: "Bulb",
                          icon: Icons.lightbulb_rounded,
                          on: isBulbOn,
                          onTap: _toggleBulb,
                          colors: colors,
                          activeColor: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Pieces ----------

  Widget _heroGauge(_Palette colors) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 10, end: currentTemp),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          height: 260,
          child: SfRadialGauge(
            axes: [
              RadialAxis(
                minimum: 10, maximum: 40, startAngle: 150, endAngle: 30,
                showTicks: false,
                interval: 5,
                axisLabelStyle: GaugeTextStyle(
                    fontSize: 11, color: colors.textTertiary, fontWeight: FontWeight.w600),
                axisLineStyle: AxisLineStyle(
                  thickness: 0.18,
                  thicknessUnit: GaugeSizeUnit.factor,
                  color: colors.card,
                  cornerStyle: CornerStyle.bothCurve,
                ),
                ranges: [
                  GaugeRange(
                    startValue: 10, endValue: value,
                    startWidth: 0.18, endWidth: 0.18, sizeUnit: GaugeSizeUnit.factor,
                    gradient: SweepGradient(colors: [colors.accent, colors.accent2]),
                  ),
                ],
                annotations: [
                  GaugeAnnotation(
                    angle: 90,
                    positionFactor: 0.05,
                    widget: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("${value.toStringAsFixed(1)}°C",
                            style: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.w800, color: colors.textPrimary)),
                        const SizedBox(height: 6),
                        _smallHumidityRing(colors),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _smallHumidityRing(_Palette colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.water_drop, size: 16, color: colors.accent2),
          const SizedBox(width: 6),
          Text("${currentHumidity.toStringAsFixed(0)}%",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary)),
        ],
      ),
    );
  }

  Widget _deviceToggle({
    required String title,
    required IconData icon,
    required bool on,
    required VoidCallback onTap,
    required _Palette colors,
    required Color activeColor,
  }) {
    final bgOn  = colors.accent.withOpacity(.12);
    final fgOn  = activeColor;
    final bgOff = colors.card;
    final fgOff = colors.onCard;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: on ? bgOn : bgOff,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border, width: 0.8),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(colors.isDark ? 0.25 : 0.06),
          blurRadius: 12,
          offset: const Offset(0, 6),
        )],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: on ? fgOn : fgOff),
            const SizedBox(height: 10),
            Text(title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: on ? fgOn : colors.textPrimary)),
            const SizedBox(height: 2),
            Text(on ? "Tap to turn off" : "Tap to turn on",
                style: TextStyle(fontSize: 11, color: colors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _roundBtn({required IconData icon, required VoidCallback onTap, required Color bg, required Color fg}) {
    return Material(
      color: bg, borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, color: fg, size: 22),
        ),
      ),
    );
  }

  Widget _chip(String text, {required Color bg, required Color fg, IconData? icon, bool dense = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 10 : 12, vertical: dense ? 6 : 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999), border: Border.all(color: bg.withOpacity(.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
        ],
        Text(text, style: TextStyle(fontSize: dense ? 11 : 12, fontWeight: FontWeight.w700, color: fg)),
      ]),
    );
  }

  Widget _glassCard({required _Palette colors, required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border, width: 0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(colors.isDark ? .35 : .08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
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

// ---------- Theme palette ----------

class _Palette {
  final bool isDark;
  final Color bg;
  final List<Color> bgGradient;
  final Color card;
  final Color onCard;
  final Color border;
  final Color grid;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color accent;
  final Color accent2;
  final Color okBg, okFg, warnBg, warnFg;

  _Palette._({
    required this.isDark,
    required this.bg,
    required this.bgGradient,
    required this.card,
    required this.onCard,
    required this.border,
    required this.grid,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.accent2,
    required this.okBg,
    required this.okFg,
    required this.warnBg,
    required this.warnFg,
  });

  static _Palette of(bool dark) {
    if (dark) {
      return _Palette._(
        isDark: true,
        bg: const Color(0xFF0E0F12),
        bgGradient: const [Color(0xFF0E0F12), Color(0xFF12141A)],
        card: const Color(0xFF1B1E24),
        onCard: const Color(0xFFEDEDED),
        border: const Color(0xFF2A2E36),
        grid: const Color(0xFF2B2F38),
        textPrimary: Colors.white,
        textSecondary: Colors.white70,
        textTertiary: Colors.white54,
        accent: const Color(0xFF7C7BFF),
        accent2: const Color(0xFF5AE0FF),
        okBg: const Color(0xFF153D2A),
        okFg: const Color(0xFF6BFFB0),
        warnBg: const Color(0xFF3C1A1E),
        warnFg: const Color(0xFFFF8A8A),
      );
    } else {
      return _Palette._(
        isDark: false,
        bg: const Color(0xFFF5F7FA),
        bgGradient: const [Color(0xFFF5F7FA), Color(0xFFF2F4F8)],
        card: Colors.white,
        onCard: const Color(0xFF232B3A),
        border: const Color(0xFFE8EDF5),
        grid: const Color(0xFFE8EDF5),
        textPrimary: const Color(0xFF1E2430),
        textSecondary: const Color(0xFF6B7280),
        textTertiary: const Color(0xFF9CA3AF),
        accent: const Color(0xFF6D5DF6),
        accent2: const Color(0xFF22C1DC),
        okBg: const Color(0xFFE7FFF4),
        okFg: const Color(0xFF0B8F5A),
        warnBg: const Color(0xFFFFEEF0),
        warnFg: const Color(0xFFD63A48),
      );
    }
  }
}

class _DataPoint {
  final String time;
  final double temp;
  final int humidity;
  const _DataPoint({required this.time, required this.temp, required this.humidity});
}
