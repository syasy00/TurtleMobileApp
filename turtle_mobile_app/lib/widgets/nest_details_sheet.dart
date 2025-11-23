// lib/widgets/nest_details_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NestFormResult {
  final String name;
  final String location;
  final double temp;
  final double humidity;
  final bool fanOn;
  final bool misterOn;
  final bool bulbOn;
  NestFormResult({
    required this.name,
    required this.location,
    required this.temp,
    required this.humidity,
    required this.fanOn,
    required this.misterOn,
    required this.bulbOn,
  });
}

class NestDetailsSheet extends StatefulWidget {
  final String? suggestedName;
  const NestDetailsSheet({super.key, this.suggestedName});

  @override
  State<NestDetailsSheet> createState() => _NestDetailsSheetState();
}

class _NestDetailsSheetState extends State<NestDetailsSheet> {
  final _nameCtl = TextEditingController();
  final _locCtl  = TextEditingController(text: "Unassigned");
  final _tempCtl = TextEditingController(text: "31.2");
  final _humCtl  = TextEditingController(text: "66");

  bool fanOn = false;
  bool misterOn = true;
  bool bulbOn = true;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameCtl.text = widget.suggestedName ?? "Smart Shell";
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _locCtl.dispose();
    _tempCtl.dispose();
    _humCtl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_submitting) return;
    setState(() => _submitting = true);

    final name = _nameCtl.text.trim().isEmpty ? "Smart Shell" : _nameCtl.text.trim();
    final loc  = _locCtl.text.trim();
    final t    = double.tryParse(_tempCtl.text.trim()) ?? 31.2;
    final h    = double.tryParse(_humCtl.text.trim())  ?? 66;

    // Pop the sheet immediately and return the form result to the caller.
    Navigator.pop(
      context,
      NestFormResult(
        name: name,
        location: loc,
        temp: t,
        humidity: h,
        fanOn: fanOn,
        misterOn: misterOn,
        bulbOn: bulbOn,
      ),
    );
  }

  InputDecoration _deco(String hint, IconData icon, {List<TextInputFormatter>? fmt}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF2F3F5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    );
  }

  Widget _switchRow(IconData icon, String label, bool value, ValueChanged<bool> onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            onChanged: onChanged,
            activeColor: const Color(0xFF39CCA9),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        child: SingleChildScrollView(
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

              TextField(controller: _nameCtl, textInputAction: TextInputAction.next, decoration: _deco("Name", Icons.eco_rounded)),
              const SizedBox(height: 10),
              TextField(controller: _locCtl,  textInputAction: TextInputAction.next, decoration: _deco("Location", Icons.place_rounded)),
              const SizedBox(height: 10),

              Row(children: [
                Expanded(child: TextField(
                  controller: _tempCtl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _deco("Temperature °C", Icons.thermostat_rounded),
                )),
                const SizedBox(width: 10),
                Expanded(child: TextField(
                  controller: _humCtl,
                  keyboardType: TextInputType.number,
                  decoration: _deco("Humidity %", Icons.water_drop_rounded),
                )),
              ]),
              const SizedBox(height: 10),

              _switchRow(Icons.air_rounded, "Fan",    fanOn,    (v) => setState(() => fanOn = v)),
              const SizedBox(height: 10),
              _switchRow(Icons.water_rounded, "Mister", misterOn, (v) => setState(() => misterOn = v)),
              const SizedBox(height: 10),
              _switchRow(Icons.lightbulb_outline_rounded, "Bulb", bulbOn, (v) => setState(() => bulbOn = v)),
              const SizedBox(height: 16),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1EE9C0),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: _submitting
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text("Create Nest", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ],
          ),
        ),
      ),
    );
  }
}
