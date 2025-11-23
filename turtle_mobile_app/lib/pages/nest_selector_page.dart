import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:turtle_mobile_app/dashboard_page.dart';
import 'package:turtle_mobile_app/pages/settings_page.dart';
import 'package:turtle_mobile_app/widgets/notifications_page.dart';

import 'auth/auth_screen.dart';
import 'nest_list_page.dart';
import '../models/nest.dart';
import '../services/nest_services.dart';
import '../widgets/bottom_bar.dart';
import '../widgets/pairing_code_sheet.dart';
import '../widgets/nest_details_sheet.dart';
import '../widgets/home_header.dart';
import '../widgets/overview_card.dart';
import '../widgets/account_menu_button.dart';
import '../widgets/ai_page.dart'; // <-- Import AI page
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme_prefs.dart';

class NestSelectorPage extends StatefulWidget {
  const NestSelectorPage({super.key});
  @override
  State<NestSelectorPage> createState() => _NestSelectorPageState();
}

class _NestSelectorPageState extends State<NestSelectorPage> {
  final _svc = NestService();

  bool isDarkMode = false;
  Nest? selectedNest;
  List<Nest> nests = [];

  String _firstName = 'there';
  int _tabIndex = 0;

  double get averageTemp => nests.isEmpty
      ? 0.0
      : nests.map((n) => n.temp).reduce((a, b) => a + b) / nests.length;
  double get averageHumidity => nests.isEmpty
      ? 0.0
      : nests.map((n) => n.humidity).reduce((a, b) => a + b) / nests.length;

  @override
  void initState() {
    super.initState();
    _initTheme(); // <-- load persisted theme
    _loadFirstName();
    _listenToNests();
  }

  Future<void> _initTheme() async {
    final saved = await ThemePrefs.load();
    if (!mounted) return;
    setState(() => isDarkMode = saved);
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Future<void> _loadFirstName() async {
    var user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    user = FirebaseAuth.instance.currentUser;

    String? fullName = user?.displayName;

    if (fullName == null || fullName.trim().isEmpty) {
      for (final p in user?.providerData ?? const []) {
        final dn = (p.displayName ?? '').trim();
        if (dn.isNotEmpty) {
          fullName = dn;
          break;
        }
      }
    }

    String? first;
    if (fullName != null && fullName.trim().isNotEmpty) {
      final parts = fullName.trim().split(RegExp(r'\s+'));
      if (parts.isNotEmpty) first = parts.first.trim();
    }
    first ??= user?.email?.split('@').first;

    if (!mounted) return;
    setState(() => _firstName =
        (first == null || first.isEmpty) ? 'there' : _capitalize(first));
  }

  void _listenToNests() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _svc.listenUserNests(uid).listen((data) {
      if (!mounted) return;
      setState(() => nests = data);
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
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
    _openDetailsSheet(suggestedName: suggested);
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
    final localId = 'local-${DateTime.now().millisecondsSinceEpoch}';

    setState(() {
      nests = [
        ...nests,
        Nest(
          id: localId,
          name: result.name,
          location: result.location,
          temp: result.temp,
          humidity: result.humidity,
        )
      ];
    });

    if (uid == null) return;
    final realId = await _svc.createNest(
      uid: uid,
      name: result.name,
      location: result.location,
      temp: result.temp,
      humidity: result.humidity,
      fanOn: result.fanOn,
      misterOn: result.misterOn,
      bulbOn: result.bulbOn,
    );

    final ix = nests.indexWhere((n) => n.id == localId);
    if (ix >= 0 && mounted) {
      setState(() {
        nests[ix] = Nest(
          id: realId,
          name: result.name,
          location: result.location,
          temp: result.temp,
          humidity: result.humidity,
        );
      });
    }
  }

  Widget _nestCard(Nest nest) {
    final isSelected = selectedNest?.id == nest.id;
    final tileColor = isSelected
        ? (isDarkMode ? Colors.teal.shade700 : Colors.tealAccent.shade100)
        : (isDarkMode ? const Color(0xFF2C2C2E) : Colors.white);

    final textColor = isSelected || !isDarkMode ? Colors.black : Colors.white;
    final subTextColor =
        isSelected || !isDarkMode ? Colors.black54 : Colors.white70;

    return GestureDetector(
      onTap: () {
        if (isSelected) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SmartHubTemperaturePage(
                nestId: nest.id,
                nestName: nest.name,
                temperature: nest.temp,
                humidity: nest.humidity,
                isDarkMode: isDarkMode,
              ),
            ),
          );
        } else {
          setState(() => selectedNest = nest);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 6))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
                alignment: Alignment.topRight,
                child: Icon(Icons.wifi, color: subTextColor)),
            const SizedBox(height: 10),
            Center(
              child: Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: subTextColor, width: 2)),
                child:
                    ClipOval(child: Image.asset(nest.gif, fit: BoxFit.cover)),
              ),
            ),
            const SizedBox(height: 10),
            Text(nest.name,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: textColor)),
            Text(nest.location,
                style: TextStyle(fontSize: 11, color: subTextColor)),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${nest.temp.toString()}°C",
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textColor)),
                Icon(Icons.arrow_forward_ios, size: 13, color: subTextColor),
              ],
            ),
            if (isSelected) const SizedBox(height: 4),
            if (isSelected)
              Text("Tap again to open",
                  style: TextStyle(fontSize: 10, color: subTextColor)),
          ],
        ),
      ),
    );
  }

  void _openAi() {
    if (nests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a Smart Shell first')),
      );
      return;
    }

    final target = selectedNest ?? nests.first;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiPage(
          nestId: target.id,
          nestName: target.name,
          isDarkMode: isDarkMode,
          currentTemp: target.temp,
          currentHumidity: target.humidity,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Nest> displayNests =
        nests.length <= 3 ? nests : nests.sublist(0, 3);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: Scaffold(
        backgroundColor:
            isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFF4F5F7),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeHeader(
                  isDark: isDarkMode,
                  firstName: _firstName,
                  onManageAccount: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettingsPage(
                          isDarkMode: isDarkMode,
                          onThemeChanged: (v) => setState(() => isDarkMode = v),
                        ),
                      ),
                    );
                  },
                  onToggleTheme: () async {
                    final next = !isDarkMode;
                    setState(() => isDarkMode = next);
                    await ThemePrefs.save(next); // <-- persist
                  },
                  onLogout: _logout,
                  onBack: null,
                ),
                const SizedBox(height: 16),
                OverviewCard(
                  isDark: isDarkMode,
                  avgTemp: selectedNest?.temp ?? averageTemp,
                  avgHumidity: selectedNest?.humidity ?? averageHumidity,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text("Your Smart Shells",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    if (nests.length > 3)
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    NestListPage(isDarkMode: isDarkMode)),
                          );
                        },
                        child: const Text("See more"),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 0.75,
                    children: [
                      ...displayNests.map(_nestCard),
                      _AddTile(
                          onTap: _openPairingSheet, isDarkMode: isDarkMode),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: FancyBottomBar(
          currentIndex: _tabIndex,
          isDark: isDarkMode,
          items: const [
            FancyItem(icon: Icons.home_outlined, label: 'Home'),
            FancyItem(icon: Icons.auto_awesome_outlined, label: 'AI'),
            FancyItem(icon: Icons.notifications_outlined, label: 'Alerts'),
          ],
          onTap: (i) {
            setState(() => _tabIndex = i);

            if (i == 1) {
              _openAi();
            } else if (i == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NotificationsPage(
                    isDarkMode: isDarkMode,
                    nestId: selectedNest?.id,
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDarkMode;
  const _AddTile({required this.onTap, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isDarkMode ? Colors.white24 : Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ],
        ),
        child:
            const Center(child: Icon(Icons.add, size: 36, color: Colors.grey)),
      ),
    );
  }
}
