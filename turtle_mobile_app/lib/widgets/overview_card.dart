// lib/widgets/overview_card.dart
import 'package:flutter/material.dart';

class OverviewCard extends StatelessWidget {
  final bool isDark;
  final double avgTemp;
  final double avgHumidity;

  const OverviewCard({
    super.key,
    required this.isDark,
    required this.avgTemp,
    required this.avgHumidity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            const Icon(Icons.thermostat, color: Colors.teal, size: 24),
            const SizedBox(width: 6),
            Text("${avgTemp.toStringAsFixed(1)}°C",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : Colors.black)),
          ]),
          Row(children: [
            const Icon(Icons.water_drop, color: Colors.blue, size: 24),
            const SizedBox(width: 6),
            Text("${avgHumidity.toStringAsFixed(0)}%",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : Colors.black)),
          ]),
        ]),
        const SizedBox(height: 10),
        Text("Smart Shell Status Overview",
            style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[300] : Colors.grey[600])),
      ]),
    );
  }
}
