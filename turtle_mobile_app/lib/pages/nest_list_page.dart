import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/nest.dart';
import '../services/nest_services.dart';
import '../widgets/pairing_code_sheet.dart';
import '../widgets/nest_details_sheet.dart' show NestDetailsSheet, NestFormResult;
import '../widgets/bottom_bar.dart';
import '../dashboard_page.dart';

import '../widgets/home_header.dart';
import '../widgets/overview_card.dart';
import '../widgets/account_menu_button.dart';

class NestListPage extends StatefulWidget {
  final bool isDarkMode;
  const NestListPage({super.key, required this.isDarkMode});

  @override
  State<NestListPage> createState() => _NestListPageState();
}

class _NestListPageState extends State<NestListPage> {
  final _svc = NestService();
  List<Nest> nests = [];

  bool _isDark = false;
  String _firstName = 'there';
  int _tabIndex = 0;

  double get averageTemp =>
      nests.isEmpty ? 0.0 : nests.map((n) => n.temp).reduce((a, b) => a + b) / nests.length;
  double get averageHumidity =>
      nests.isEmpty ? 0.0 : nests.map((n) => n.humidity).reduce((a, b) => a + b) / nests.length;

  @override
  void initState() {
    super.initState();
    _isDark = widget.isDarkMode;
    _loadFirstName();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _svc.listenUserNests(uid).listen((data) {
        if (!mounted) return;
        setState(() => nests = data);
      });
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _loadFirstName() async {
    var user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    user = FirebaseAuth.instance.currentUser;

    String? full = user?.displayName;
    if (full == null || full.trim().isEmpty) {
      for (final p in user?.providerData ?? const []) {
        if ((p.displayName ?? '').trim().isNotEmpty) {
          full = p.displayName!.trim();
          break;
        }
      }
    }
    String? first;
    if (full != null && full.trim().isNotEmpty) {
      final parts = full.trim().split(RegExp(r'\s+'));
      if (parts.isNotEmpty) first = parts.first.trim();
    }
    first ??= user?.email?.split('@').first;
    if (!mounted) return;
    setState(() => _firstName = (first == null || first.isEmpty)
        ? 'there'
        : first[0].toUpperCase() + first.substring(1));
  }

  Future<void> _openPairingSheet() async {
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PairingCodeSheet(
        onSubmit: (code) async {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid == null) throw "Not authenticated";
          await _svc.submitPairRequest(uid, code);
        },
      ),
    );

    if (!mounted || code == null) return;
    final suggested = "Smart Shell ${code.split('-').first.toUpperCase()}";
    await _openDetailsSheet(suggestedName: suggested);
  }

  Future<void> _openDetailsSheet({String? suggestedName}) async {
    final result = await showModalBottomSheet<NestFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NestDetailsSheet(suggestedName: suggestedName),
    );
    if (!mounted || result == null) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _svc.createNest(
      uid: uid,
      name: result.name,
      location: result.location,
      temp: result.temp,
      humidity: result.humidity,
      fanOn: result.fanOn,
      misterOn: result.misterOn,
      bulbOn: result.bulbOn,
    );
  }

  Widget _tile(Nest n) {
    return Material(
      color: _isDark ? const Color(0xFF2C2C2E) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: CircleAvatar(
          backgroundColor: _isDark ? Colors.white10 : const Color(0xFFF2F3F5),
          child: const Icon(Icons.pets),
        ),
        title: Text(n.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: _isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
        subtitle: Text(n.location.isEmpty ? 'Unassigned' : n.location,
            style: TextStyle(color: _isDark ? Colors.white70 : Colors.black54)),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("${n.temp.toStringAsFixed(1)}°C",
                style: TextStyle(color: _isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text("${n.humidity.toStringAsFixed(0)}%", style: TextStyle(color: _isDark ? Colors.white70 : Colors.black54, fontSize: 12)),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SmartHubTemperaturePage(
              nestId: n.id,
              nestName: n.name,
              temperature: n.temp,
              humidity: n.humidity,
              isDarkMode: _isDark,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageBg = _isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF4F5F7);

    return ColoredBox(
      color: pageBg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              // Shared header WITH back button here
              HomeHeader(
                isDark: _isDark,
                firstName: _firstName,
                onBack: () {
                  if (Navigator.of(context).canPop()) Navigator.of(context).pop();
                },
                onManageAccount: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Open Manage Account')),
                  );
                },
                onToggleTheme: () => setState(() => _isDark = !_isDark),
                onLogout: _logout,
              ),
              const SizedBox(height: 16),

              // Shared overview card
              OverviewCard(isDark: _isDark, avgTemp: averageTemp, avgHumidity: averageHumidity),
              const SizedBox(height: 20),

              const Text("Your Smart Shells", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              if (nests.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _isDark ? const Color(0xFF2C2C2E) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 36, color: _isDark ? Colors.white38 : Colors.black26),
                      const SizedBox(height: 8),
                      Text("No Smart Shells yet",
                          style: TextStyle(color: _isDark ? Colors.white70 : Colors.black54)),
                      const SizedBox(height: 4),
                      const Text("Tap + to add your first device", style: TextStyle(fontSize: 12)),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: nests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _tile(nests[i]),
                ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _openPairingSheet,
          child: const Icon(Icons.add),
        ),
        bottomNavigationBar: FancyBottomBar(
          currentIndex: _tabIndex,
          isDark: _isDark,
          items: const [
            FancyItem(icon: Icons.home_outlined, label: 'Home'),
            FancyItem(icon: Icons.auto_awesome_outlined, label: 'AI'),
            FancyItem(icon: Icons.more_horiz, label: ''),
          ],
          onTap: (i) => setState(() => _tabIndex = i),
        ),
      ),
    );
  }
}
