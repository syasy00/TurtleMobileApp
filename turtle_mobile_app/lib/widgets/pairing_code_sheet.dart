// lib/widgets/pairing_code_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PairingCodeSheet extends StatefulWidget {
  /// Do the RTDB write in this callback. If it completes, the sheet will close.
  final Future<void> Function(String code) onSubmit;
  const PairingCodeSheet({super.key, required this.onSubmit});

  @override
  State<PairingCodeSheet> createState() => _PairingCodeSheetState();
}

class _PairingCodeSheetState extends State<PairingCodeSheet> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _error = "Please enter your pairing code.");
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.onSubmit(code).timeout(const Duration(seconds: 6));
      if (!mounted) return;
      Navigator.pop(context, code); // close and return code
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = "Couldn’t send request: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    InputDecoration deco() => InputDecoration(
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
                    _codeCtrl.text = d!.text!.trim().toUpperCase();
                  }
                },
              ),
              IconButton(
                tooltip: "Clear",
                icon: const Icon(Icons.clear_rounded),
                onPressed: () => _codeCtrl.clear(),
              ),
            ],
          ),
        );

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
            Text(
              "Enter Pairing Code",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Find this on the OLED screen. Example:\nABCD-1234",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeCtrl,
              autofocus: true,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                LengthLimitingTextInputFormatter(24),
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9-]')),
                _UpperCaseTextFormatter(),
              ],
              decoration: deco(),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1EE9C0),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
                child: _loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Pair Nest", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}
