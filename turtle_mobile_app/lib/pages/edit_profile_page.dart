import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfilePage extends StatefulWidget {
  final bool isDarkMode;
  const EditProfilePage({super.key, required this.isDarkMode});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = FirebaseAuth.instance.currentUser!;
    _nameCtrl.text = u.displayName ?? '';
    _emailCtrl.text = u.email ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final u = FirebaseAuth.instance.currentUser!;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Name cannot be empty.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await u.updateDisplayName(name);
      await u.reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated.')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Update failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDarkMode;

    // Palette
    final Color bg      = dark ? const Color(0xFF101113) : const Color(0xFFF6F7F9);
    final Color card    = dark ? const Color(0xFF1C1E22) : Colors.white;
    final Color border  = dark ? const Color(0xFF2A2E34) : const Color(0xFFE0E5EE);
    final Color text    = dark ? Colors.white : const Color(0xFF111827);
    final Color subtle  = dark ? Colors.white70 : const Color(0xFF6B7280);
    final Color hint    = dark ? Colors.white54 : const Color(0xFF9CA3AF);
    final Color cta     = const Color(0xFFB7FF3A);

    InputDecoration deco({
      required String label,
      String? hintText,
      bool disabled = false,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: TextStyle(color: subtle, fontWeight: FontWeight.w600),
        floatingLabelStyle: TextStyle(color: subtle, fontWeight: FontWeight.w700),
        hintStyle: TextStyle(color: hint),
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border.withOpacity(.7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: subtle),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: text),
        title: Text('Edit Profile',
            style: TextStyle(color: text, fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const SizedBox(height: 8),
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: dark ? Colors.white10 : const Color(0xFFECEFF4),
                  child: Text(
                    (_nameCtrl.text.isEmpty ? 'U' : _nameCtrl.text[0]).toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 32,
                      color: text,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: cta,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(.2), blurRadius: 6)
                      ],
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: 18, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Full name
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            textInputAction: TextInputAction.done,
            style: TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.w600),
            cursorColor: text.withOpacity(.9),
            decoration: deco(label: 'Full name', hintText: 'Enter your full name'),
          ),
          const SizedBox(height: 12),

          // Email (read-only)
          TextField(
            controller: _emailCtrl,
            enabled: false,
            style: TextStyle(color: subtle, fontSize: 15, fontWeight: FontWeight.w600),
            decoration: deco(label: 'Email', disabled: true),
          ),

          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: cta,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              child: _saving
                  ? const CircularProgressIndicator()
                  : const Text('Save Changes'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Delete account flow TBD'))),
              style: OutlinedButton.styleFrom(
                foregroundColor: subtle,
                side: BorderSide(color: border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              child: const Text('Delete Account'),
            ),
          ),
        ],
      ),
    );
  }
}
