// lib/nest_selector.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'core/db.dart';
import 'dashboard_page.dart';
import 'onboarding_sceen.dart';

class NestSelectorPage extends StatefulWidget {
  const NestSelectorPage({super.key});
  @override
  State<NestSelectorPage> createState() => _NestSelectorPageState();
}

class _NestSelectorPageState extends State<NestSelectorPage> {
  bool isDarkMode = false;
  Map<String, dynamic>? selectedNest;

  List<Map<String, dynamic>> nests = [];
  String selectedFilter = "All Smart Shells";

  bool _pairingLoading = false;
  String? _pairingError;

  List<String> get filters {
    final names = nests.map((n) => n['name'] as String).toSet().toList();
    return ["All Smart Shells", ...names];
  }

  double get averageTemp => nests.isEmpty
      ? 0.0
      : nests.map((n) => (n['temp'] as num).toDouble()).reduce((a, b) => a + b) /
          nests.length;

  double get averageHumidity => nests.isEmpty
      ? 0.0
      : nests
          .map((n) => (n['humidity'] as num).toDouble())
          .reduce((a, b) => a + b) /
          nests.length;

  @override
  void initState() {
    super.initState();
    _listenToNests();
  }

  dynamic _pick(Map m, List<String> keys) {
    for (final k in keys) {
      if (m.containsKey(k)) return m[k];
    }
    return null;
  }

  void _listenToNests() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    final ref = rtdb.ref('nests/$uid');
    ref.onValue.listen((event) {
      final raw = event.snapshot.value;
      if (raw is! Map) {
        setState(() => nests = []);
        return;
      }
      final data = Map<String, dynamic>.from(raw as Map);
      final List<Map<String, dynamic>> loaded = [];
      data.forEach((key, value) {
        if (value is! Map) return;
        final map = Map<String, dynamic>.from(value as Map);
        final name = (_pick(map, ['name', 'Name']) ?? key).toString();
        final location = (_pick(map, ['location', 'Location']) ?? '').toString();
        final tNum = (_pick(map, ['temperature', 'Temperature']) ?? 0) as num;
        final hNum = (_pick(map, ['humidity', 'Humidity']) ?? 0) as num;

        loaded.add({
          'id': key,
          'name': name,
          'location': location,
          'temp': tNum.toDouble(),
          'humidity': hNum.toDouble(),
          'gif': 'assets/turtle1.gif',
        });
      });
      setState(() => nests = loaded);
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (route) => false,
    );
  }

  // -------- Pairing sheet (enhanced) --------
  void _showPairingForm() {
    final codeCtrl = TextEditingController();
    final isDark = isDarkMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 24, offset: const Offset(0, -6))],
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: StatefulBuilder(
              builder: (_, setSheetState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 44, height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text("Enter Pairing Code",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                        )),
                    const SizedBox(height: 6),
                    Text(
                      "Find this on the device screen or sticker. Example:\nABCD-1234",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: codeCtrl,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(24),
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9-]')),
                        UpperCaseTextFormatter(),
                      ],
                      decoration: InputDecoration(
                        hintText: "ABCD-1234",
                        filled: true,
                        fillColor: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF2F3F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.key_rounded),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: "Paste",
                              icon: const Icon(Icons.content_paste_rounded),
                              onPressed: () async {
                                final d = await Clipboard.getData('text/plain');
                                if (d?.text != null) {
                                  setSheetState(() => codeCtrl.text = d!.text!.trim().toUpperCase());
                                }
                              },
                            ),
                            IconButton(
                              tooltip: "Clear",
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () => setSheetState(() => codeCtrl.clear()),
                            ),
                            IconButton(
                              tooltip: "Scan QR",
                              icon: const Icon(Icons.qr_code_scanner_rounded),
                              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("QR scanner not implemented yet")),
                              ),
                            ),
                          ],
                        ),
                      ),
                      onSubmitted: (_) => _handleSubmitCode(codeCtrl.text.trim(), setSheetState),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _pairingLoading ? null : () => _handleSubmitCode(codeCtrl.text.trim(), setSheetState),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1EE9C0),
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: const StadiumBorder(),
                        ),
                        child: _pairingLoading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text("Pair Nest", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                    if (_pairingError != null) ...[
                      const SizedBox(height: 8),
                      Text(_pairingError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSubmitCode(String code, StateSetter setSheetState) async {
    if (code.isEmpty) {
      setSheetState(() => _pairingError = "Please enter your pairing code.");
      return;
    }
    setSheetState(() {
      _pairingError = null;
      _pairingLoading = true;
    });

    try {
      try {
        await _submitPairingCode(code).timeout(const Duration(seconds: 4));
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 250));

      if (!mounted) return;
      setSheetState(() => _pairingLoading = false);
      Navigator.pop(context);

      final suggested = "Smart Shell ${code.split('-').first.toUpperCase()}";
      _showNestDetailsForm(suggestedName: suggested);
    } catch (e) {
      if (!mounted) return;
      setSheetState(() {
        _pairingLoading = false;
        _pairingError = "Couldn’t send request: $e";
      });
    }
  }

  Future<void> _submitPairingCode(String code) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await rtdb.ref('pairRequests/$uid').set({
      'pendingCode': code,
      'requestedAt': ServerValue.timestamp,
    });
  }

  // -------- Details sheet (now includes Bulb) --------
  void _showNestDetailsForm({String? suggestedName}) {
    final isDark = isDarkMode;

    final nameCtl = TextEditingController(text: suggestedName ?? "Smart Shell");
    final locCtl  = TextEditingController(text: "Unassigned");
    final tempCtl = TextEditingController(text: "31.2");
    final humCtl  = TextEditingController(text: "66");

    bool fanOn = false;
    bool misterOn = false;
    bool bulbOn = false; // NEW
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 24, offset: const Offset(0, -6))],
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                InputDecoration deco(String hint, IconData icon) => InputDecoration(
                  hintText: hint,
                  prefixIcon: Icon(icon),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF2F3F5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                );

                Widget switchRow(IconData icon, String label, bool value, ValueChanged<bool> onChanged) {
                  return Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF2F3F5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      children: [
                        Icon(icon),
                        const SizedBox(width: 8),
                        Text(label),
                        const Spacer(),
                        Switch(
                          value: value,
                          onChanged: (v) => setSheetState(() => onChanged(v)),
                          activeColor: const Color(0xFF39CCA9),
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 44, height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text("Nest Details",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
                      const SizedBox(height: 14),

                      TextField(controller: nameCtl, textInputAction: TextInputAction.next, decoration: deco("Name", Icons.eco_rounded)),
                      const SizedBox(height: 10),
                      TextField(controller: locCtl,  textInputAction: TextInputAction.next, decoration: deco("Location", Icons.place_rounded)),
                      const SizedBox(height: 10),

                      Row(children: [
                        Expanded(child: TextField(
                          controller: tempCtl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: deco("Temperature °C", Icons.thermostat_rounded),
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(
                          controller: humCtl,
                          keyboardType: TextInputType.number,
                          decoration: deco("Humidity %", Icons.water_drop_rounded),
                        )),
                      ]),
                      const SizedBox(height: 10),

                      switchRow(Icons.air_rounded, "Fan",    fanOn,    (v) => fanOn = v),
                      const SizedBox(height: 10),
                      switchRow(Icons.water_rounded, "Mister", misterOn, (v) => misterOn = v),
                      const SizedBox(height: 10),
                      switchRow(Icons.lightbulb_outline_rounded, "Bulb", bulbOn, (v) => bulbOn = v), // NEW
                      const SizedBox(height: 16),

                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: saving ? null : () async {
                            setSheetState(() => saving = true);
                            final name = nameCtl.text.trim().isEmpty ? "Smart Shell" : nameCtl.text.trim();
                            final loc  = locCtl.text.trim();
                            final t    = double.tryParse(tempCtl.text.trim()) ?? 31.2;
                            final h    = double.tryParse(humCtl.text.trim())  ?? 66;

                            final id = await _createNestFromForm(
                              name: name,
                              location: loc,
                              temp: t,
                              humidity: h,
                              fanOn: fanOn,
                              misterOn: misterOn,
                              bulbOn: bulbOn, // NEW
                            );

                            if (!mounted) return;
                            Navigator.pop(context); // close details

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SmartHubTemperaturePage(
                                  nestId: id,
                                  nestName: name,
                                  temperature: t,
                                  humidity: h,
                                  isDarkMode: isDarkMode,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1EE9C0),
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: const StadiumBorder(),
                          ),
                          child: saving
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text("Create Nest", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<String> _createNestFromForm({
    required String name,
    required String location,
    required double temp,
    required double humidity,
    required bool fanOn,
    required bool misterOn,
    required bool bulbOn, // NEW
  }) async {
    final localId = 'local-${DateTime.now().millisecondsSinceEpoch}';
    _addLocalNestCard(id: localId, name: name, temp: temp, humidity: humidity);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return localId;

      final ref = rtdb.ref('nests/$uid').push();
      await ref.set({
        'name': name,
        'location': location,
        'temperature': temp,
        'humidity': humidity,
        'controls': {'fan': fanOn, 'mister': misterOn, 'bulb': bulbOn}, // NEW
        'createdAt': ServerValue.timestamp,
      });

      final realId = ref.key;
      if (realId != null) {
        final ix = nests.indexWhere((n) => n['id'] == localId);
        if (ix >= 0) setState(() => nests[ix]['id'] = realId);
        return realId;
      }
    } catch (_) {}
    return localId;
  }

  // ---- UI helpers / cards ----
  void _addLocalNestCard({
    required String id,
    required String name,
    required double temp,
    required double humidity,
  }) {
    final card = {
      'id': id,
      'name': name,
      'location': 'Unassigned',
      'temp': temp,
      'humidity': humidity,
      'gif': 'assets/turtle1.gif',
    };
    final ix = nests.indexWhere((n) => n['id'] == id);
    setState(() {
      if (ix >= 0) {
        nests[ix] = card;
      } else {
        nests = [...nests, card];
      }
    });
  }

  Widget _nestCard(Map<String, dynamic> nest) {
    final isSelected = selectedNest == nest;
    final tileColor = isSelected
        ? (isDarkMode ? Colors.teal.shade700 : Colors.tealAccent.shade100)
        : (isDarkMode ? const Color(0xFF2C2C2E) : Colors.white);

    final textColor = isSelected || !isDarkMode ? Colors.black : Colors.white;
    final subTextColor = isSelected || !isDarkMode ? Colors.black54 : Colors.white70;

    return GestureDetector(
      onTap: () {
        if (isSelected) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SmartHubTemperaturePage(
                nestId: nest['id'] as String,
                nestName: nest['name'] as String,
                temperature: (nest['temp'] as num).toDouble(),
                humidity: (nest['humidity'] as num).toDouble(),
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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(alignment: Alignment.topRight, child: Icon(Icons.wifi, color: subTextColor)),
            const SizedBox(height: 10),
            Center(
              child: Container(
                height: 70, width: 70,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: subTextColor, width: 2)),
                child: ClipOval(child: Image.asset(nest['gif'] as String, fit: BoxFit.cover)),
              ),
            ),
            const SizedBox(height: 10),
            Text(nest['name'] as String, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
            Text(nest['location'] as String, style: TextStyle(fontSize: 11, color: subTextColor)),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${(nest['temp'] as num).toString()}°C",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                Icon(Icons.arrow_forward_ios, size: 13, color: subTextColor),
              ],
            ),
            if (isSelected) const SizedBox(height: 4),
            if (isSelected) Text("Tap again to open", style: TextStyle(fontSize: 10, color: subTextColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddTile() {
    return GestureDetector(
      onTap: _showPairingForm,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDarkMode ? Colors.white24 : Colors.grey.shade300),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: const Center(child: Icon(Icons.add, size: 36, color: Colors.grey)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double currentTemp = selectedNest?['temp'] ?? averageTemp;
    final double currentHumidity = selectedNest?['humidity'] ?? averageHumidity;
    final filteredNests =
        selectedFilter == "All Smart Shells" ? nests : nests.where((n) => n['name'] == selectedFilter).toList();

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFF4F5F7),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Manage Home", style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey, fontSize: 13)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text("Hey, Syusyi",
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)),
                            const SizedBox(width: 6),
                            const Text("👋", style: TextStyle(fontSize: 20)),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        IconButton(icon: Icon(Icons.logout, color: isDarkMode ? Colors.white : Colors.black54), onPressed: _logout),
                        Switch(
                          value: isDarkMode,
                          onChanged: (value) => setState(() => isDarkMode = value),
                          activeColor: const Color.fromARGB(255, 57, 204, 169),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Row(children: [
                          const Icon(Icons.thermostat, color: Colors.teal, size: 24),
                          const SizedBox(width: 6),
                          Text("${currentTemp.toStringAsFixed(1)}°C",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDarkMode ? Colors.white : Colors.black)),
                        ]),
                        Row(children: [
                          const Icon(Icons.water_drop, color: Colors.blue, size: 24),
                          const SizedBox(width: 6),
                          Text("${currentHumidity.toStringAsFixed(0)}%",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDarkMode ? Colors.white : Colors.black)),
                        ]),
                      ]),
                      const SizedBox(height: 10),
                      Text("Smart Shell Status Overview",
                          style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.grey[300] : Colors.grey[600])),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final filter = filters[index];
                      final isSel = filter == selectedFilter;
                      return GestureDetector(
                        onTap: () => setState(() => selectedFilter = filter),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? (isDarkMode ? Colors.white : Colors.black) : (isDarkMode ? Colors.grey.shade800 : Colors.grey[200]),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              color: isSel ? (isDarkMode ? Colors.black : Colors.white) : (isDarkMode ? Colors.white70 : Colors.black87),
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Your Smart Shells", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 0.75,
                    children: [
                      ...filteredNests.map(_nestCard).toList(),
                      _buildAddTile(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Uppercase formatter
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase(), selection: newValue.selection, composing: TextRange.empty);
  }
}
