import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:turtle_mobile_app/widgets/notifications_page.dart';
import '../models/ai_message.dart';
import '../pages/nest_selector_page.dart';
import '../widgets/bottom_bar.dart'; // FancyBottomBar
import '../core/db.dart'; // your rtdb export

class AiPage extends StatefulWidget {
  final String nestId;
  final String nestName;
  final bool isDarkMode;
  final double currentTemp;
  final double currentHumidity;

  const AiPage({
    super.key,
    required this.nestId,
    required this.nestName,
    required this.isDarkMode,
    required this.currentTemp,
    required this.currentHumidity,
  });

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  late final _AiBrain brain;
  late final DatabaseReference base;
  final TextEditingController _ctrl = TextEditingController();
  List<_AiSuggestion> suggestions = [];
  List<AiMessage> chat = [];

  // Bottom bar state (AI tab selected on this page)
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    brain = _AiBrain();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    base = rtdb.ref('nests/$uid/${widget.nestId}');
    _refresh();
  }

  Future<void> _refresh() async {
    final s = await brain.generateSuggestions(
      tempC: widget.currentTemp,
      humidity: widget.currentHumidity,
    );
    setState(() => suggestions = s);
  }

  Future<void> _applyAction(_AiAction a) async {
    switch (a.type) {
      case _AiActionType.setFan:
        await base.child('controls/fan').set(a.boolValue);
        break;
      case _AiActionType.setMister:
        await base.child('controls/mister').set(a.boolValue);
        break;
      case _AiActionType.setBulb:
        await base.child('controls/bulb').set(a.boolValue);
        break;
      case _AiActionType.setTargets:
        await base.update({
          'targetTempMin': a.rangeMin,
          'targetTempMax': a.rangeMax,
          'targetHumidityMin': a.hRangeMin,
          'targetHumidityMax': a.hRangeMax,
        });
        break;
    }
    await base.child('updatedAt').set(ServerValue.timestamp);
    if (mounted) _refresh();
  }

  void _onSend() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => chat.add(AiMessage.fromUser(text)));
    _ctrl.clear();

    final parsed = brain.parseCommand(text);
    if (parsed == null) {
      setState(() => chat.add(AiMessage.fromBot(
          "Sorry, I didn’t get that. Try: “make it cooler”, “raise humidity to 70%”, or “turn bulb off”.")));
      return;
    }
    setState(() => chat.add(AiMessage.fromBot(parsed.readable)));
    _applyAction(parsed.action);
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDarkMode;
    final c = _Palette.of(dark);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: c.accent,
          onRefresh: _refresh,
          child: Column(
            children: [
              // header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    Text("AI",
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: c.text)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                          color: c.card,
                          borderRadius: BorderRadius.circular(999)),
                      child: Text(widget.nestName,
                          style: TextStyle(color: c.subtle)),
                    )
                  ],
                ),
              ),

              // quick actions
              SizedBox(
                height: 48,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  children: [
                    _pill("Cool me now", c, Icons.ac_unit, () {
                      _applyAction(_AiAction.setFan(true));
                    }),
                    _pill("Raise humidity", c, Icons.water_drop, () {
                      _applyAction(_AiAction.setMister(true));
                    }),
                    _pill("Balance both", c, Icons.auto_mode, () async {
                      final a = brain.balanceAction(
                          widget.currentTemp, widget.currentHumidity);
                      await _applyAction(a);
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // suggestions + chat
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  children: [
                    _sectionTitle("Smart suggestions", c),
                    ...suggestions.map((s) =>
                        _suggestionTile(s, c, () => _applyAction(s.action))),
                    const SizedBox(height: 8),
                    _sectionTitle("Ask AI", c),
                    ...chat.map((m) => _chatBubble(m, c)),
                    const SizedBox(height: 80),
                  ],
                ),
              ),

              // composer
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                decoration: BoxDecoration(
                    color: c.bg,
                    boxShadow: [
                      BoxShadow(
                          blurRadius: 10,
                          color: Colors.black.withOpacity(dark ? .4 : .08))
                    ]),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                            color: c.card,
                            borderRadius: BorderRadius.circular(16)),
                        child: TextField(
                          controller: _ctrl,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Ask AI to adjust…",
                          ),
                          onSubmitted: (_) => _onSend(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _onSend,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text("Send"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: FancyBottomBar(
  currentIndex: _currentIndex,   // 1 on AI page
  isDark: widget.isDarkMode,
items: const [
  FancyItem(icon: Icons.home_outlined, label: 'Home'),
  FancyItem(icon: Icons.auto_awesome_outlined, label: 'AI'),
  FancyItem(icon: Icons.notifications_outlined, label: 'Alerts'),
],

  onTap: (i) {
    setState(() => _currentIndex = i);
    if (i == 0) {
      // Home → go back to the selector/dashboard
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const NestSelectorPage()),
        (route) => false,
      );
    } else if (i == 2) {
      // Notifications for THIS shell
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NotificationsPage(
            isDarkMode: widget.isDarkMode,
            nestId: widget.nestId,
          ),
        ),
      );
    }
    // i == 1 is the current AI tab – no action
  },
),

    );  
  }

  // --- UI bits ---
  Widget _pill(String text, _Palette c, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: c.border)),
          child: Row(children: [
            Icon(icon, size: 16, color: c.accent),
            const SizedBox(width: 8),
            Text(text, style: TextStyle(color: c.text))
          ]),
        ),
      ),
    );
  }

  Widget _sectionTitle(String t, _Palette c) => Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 6),
      child: Text(t,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w800, color: c.text)));

  Widget _suggestionTile(
      _AiSuggestion s, _Palette c, VoidCallback onApply) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border)),
      child: Row(
        children: [
          Icon(s.icon, color: c.accent),
          const SizedBox(width: 12),
          Expanded(
              child: Text(s.title,
                  style:
                      TextStyle(fontWeight: FontWeight.w700, color: c.text))),
          TextButton(onPressed: onApply, child: const Text("Apply")),
        ],
      ),
    );
  }

  Widget _chatBubble(AiMessage m, _Palette c) {
    final isUser = m.isUser;
    final align =
        isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bg = isUser ? c.accent : c.card;
    final fg = isUser ? Colors.white : c.text;
    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: isUser ? Colors.transparent : c.border)),
        child: Text(m.text, style: TextStyle(color: fg)),
      ),
    );
  }
}

// ---------- tiny “AI brain” ----------
class _AiBrain {
  static const double tMin = 29, tMax = 32;
  static const double hMin = 65, hMax = 75;

  Future<List<_AiSuggestion>> generateSuggestions(
      {required double tempC, required double humidity}) async {
    final items = <_AiSuggestion>[];

    // 1) Set-point recommendation
    final target = _recommendTemp(tempC);
    items.add(_AiSuggestion(
      title:
          "Set target to ${target.toStringAsFixed(1)}°C for comfort & energy",
      icon: Icons.thermostat_auto,
      action: _AiAction.setTargets(
          tempMin: target - 0.5,
          tempMax: target + 0.5,
          humMin: hMin,
          humMax: hMax),
    ));

    // 2) Predictive alert
    final driftPerHour =
        0.6 * (tempC > tMax ? 1 : tempC < tMin ? -1 : 0);
    if (driftPerHour > 0 && tempC >= 31.5) {
      items.add(_AiSuggestion(
        title: "Likely to exceed 32°C soon • pre-cool now (Fan on)",
        icon: Icons.trending_up,
        action: _AiAction.setFan(true),
      ));
    }

    // 3) Humidity balance
    if (humidity < hMin) {
      items.add(_AiSuggestion(
        title: "Raise humidity to ~${hMin.toInt()}% (turn Mister on)",
        icon: Icons.water_drop,
        action: _AiAction.setMister(true),
      ));
    } else if (humidity > hMax) {
      items.add(_AiSuggestion(
        title: "Humidity high • turn Mister off",
        icon: Icons.water_damage_outlined,
        action: _AiAction.setMister(false),
      ));
    }

    return items;
  }

  _AiAction balanceAction(double t, double h) {
    if (t > tMax) return _AiAction.setFan(true);
    if (h < hMin) return _AiAction.setMister(true);
    return _AiAction.setFan(false);
  }

  double _recommendTemp(double t) {
    final mid = (tMin + tMax) / 2; // 30.5
    final blend = 0.6;
    return (blend * mid) + ((1 - blend) * t).clamp(tMin, tMax);
  }

  _ParsedCommand? parseCommand(String text) {
    final s = text.toLowerCase();
    if (s.contains("cool") ||
        s.contains("lower temp") ||
        s.contains("too hot")) {
      return _ParsedCommand(
          "Turning fan on to cool.", _AiAction.setFan(true));
    }
    if (s.contains("warmer") || s.contains("too cold")) {
      return _ParsedCommand(
          "Turning fan off to warm up.", _AiAction.setFan(false));
    }
    final humUp = RegExp(r'(humidity|humidit)[^\d]{0,5}(\d{2})');
    final m = humUp.firstMatch(s);
    if (s.contains("raise humidity") || m != null) {
      final to = m != null ? int.parse(m.group(2)!) : 70;
      return _ParsedCommand(
          "Raising humidity towards ~$to%.", _AiAction.setMister(true));
    }
    if (s.contains("bulb on"))
      return _ParsedCommand("Turning bulb on.", _AiAction.setBulb(true));
    if (s.contains("bulb off"))
      return _ParsedCommand("Turning bulb off.", _AiAction.setBulb(false));
    if (s.contains("mister off"))
      return _ParsedCommand("Turning mister off.", _AiAction.setMister(false));
    if (s.contains("mister on"))
      return _ParsedCommand("Turning mister on.", _AiAction.setMister(true));
    return null;
  }
}

class _ParsedCommand {
  final String readable;
  final _AiAction action;
  _ParsedCommand(this.readable, this.action);
}

class _AiSuggestion {
  final String title;
  final IconData icon;
  final _AiAction action;
  _AiSuggestion(
      {required this.title, required this.icon, required this.action});
}

enum _AiActionType { setFan, setMister, setBulb, setTargets }

class _AiAction {
  final _AiActionType type;
  final bool boolValue;
  final double rangeMin, rangeMax, hRangeMin, hRangeMax;

  _AiAction._(this.type,
      {this.boolValue = false,
      this.rangeMin = 0,
      this.rangeMax = 0,
      this.hRangeMin = 0,
      this.hRangeMax = 0});

  factory _AiAction.setFan(bool on) =>
      _AiAction._(_AiActionType.setFan, boolValue: on);
  factory _AiAction.setMister(bool on) =>
      _AiAction._(_AiActionType.setMister, boolValue: on);
  factory _AiAction.setBulb(bool on) =>
      _AiAction._(_AiActionType.setBulb, boolValue: on);
  factory _AiAction.setTargets(
          {required double tempMin,
          required double tempMax,
          required double humMin,
          required double humMax}) =>
      _AiAction._(_AiActionType.setTargets,
          rangeMin: tempMin,
          rangeMax: tempMax,
          hRangeMin: humMin,
          hRangeMax: humMax);
}

// tiny palette just for this page
class _Palette {
  final bool dark;
  final Color bg, card, border, accent, text, subtle;
  _Palette._(this.dark, this.bg, this.card, this.border, this.accent,
      this.text, this.subtle);
  static _Palette of(bool dark) => dark
      ? _Palette._(
          true,
          const Color(0xFF0E0F12),
          const Color(0xFF1B1E24),
          const Color(0xFF2A2E36),
          const Color(0xFF7C7BFF),
          Colors.white,
          Colors.white70)
      : _Palette._(
          false,
          const Color(0xFFF5F7FA),
          Colors.white,
          const Color(0xFFE8EDF5),
          const Color(0xFF6D5DF6),
          const Color(0xFF1E2430),
          const Color(0xFF6B7280));
}
