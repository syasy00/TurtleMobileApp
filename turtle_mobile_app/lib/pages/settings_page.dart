import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:turtle_mobile_app/pages/auth/auth_screen.dart';

import '../core/db.dart';
import 'edit_profile_page.dart';

class SettingsPage extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged; // parent actually flips app theme

  const SettingsPage({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final String uid;
  late final DatabaseReference _prefsRef;

  bool _dark = false;
  bool _pauseNotifications = false;

  @override
  void initState() {
    super.initState();
    _dark = widget.isDarkMode;
    uid = FirebaseAuth.instance.currentUser!.uid;
    _prefsRef = rtdb.ref('users/$uid/prefs');
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final snap = await _prefsRef.get();
    final m = (snap.value as Map?) ?? {};
    setState(() {
      _dark = (m['darkMode'] ?? _dark) as bool;
      _pauseNotifications = (m['alertsPaused'] ?? false) as bool;
    });
  }

  Future<void> _saveDark(bool v) async {
    setState(() => _dark = v);
    await _prefsRef.update({'darkMode': v});
    widget.onThemeChanged(v); // notify parent so the whole app re-themes
  }

  Future<void> _savePause(bool v) async {
    setState(() => _pauseNotifications = v);
    await _prefsRef.update({'alertsPaused': v});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(v ? 'Notifications paused' : 'Notifications resumed')),
    );
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final name = (user.displayName ?? '').trim();
    final email = user.email ?? '';

    final dark = _dark;
    final Color bg      = dark ? const Color(0xFF101113) : const Color(0xFFF6F7F9);
    final Color card    = dark ? const Color(0xFF1C1E22) : Colors.white;
    final Color border  = dark ? const Color(0xFF2A2E34) : const Color(0xFFE8EDF5);
    final Color text    = dark ? Colors.white : const Color(0xFF1E2430);
    final Color subtle  = dark ? Colors.white70 : const Color(0xFF6B7280);

    Widget tile({
      required IconData icon,
      required String title,
      String? subtitle,
      Widget? trailing,
      VoidCallback? onTap,
    }) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(dark ? .35 : .06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: ListTile(
          leading: Icon(icon, color: subtle),
          title: Text(title, style: TextStyle(color: text, fontWeight: FontWeight.w700)),
          subtitle: subtitle == null ? null : Text(subtitle, style: TextStyle(color: subtle)),
          trailing: trailing ?? Icon(Icons.chevron_right, color: subtle),
          onTap: onTap,
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        title: Text('Settings', style: TextStyle(color: text, fontWeight: FontWeight.w800)),
        iconTheme: IconThemeData(color: text), // <-- makes back icon visible in dark mode
        leading: BackButton(color: text),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // Profile card
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfilePage(isDarkMode: dark), // <-- pass theme
                  ),
                );
                if (updated == true && mounted) setState(() {});
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: dark ? Colors.white10 : const Color(0xFFECEFF4),
                    child: Text(
                      (name.isEmpty ? (email.isNotEmpty ? email[0] : 'U') : name[0]).toUpperCase(),
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: text),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty ? 'Your profile' : name,
                          style: TextStyle(color: text, fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(email, style: TextStyle(color: subtle)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: subtle),
                ],
              ),
            ),
          ),

          // Toggles / items
          tile(
            icon: Icons.notifications_off_outlined,
            title: 'Pause notifications',
            trailing: Switch(value: _pauseNotifications, onChanged: _savePause),
          ),
          tile(
            icon: Icons.tune_rounded,
            title: 'General settings',
            onTap: () => ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('General settings tapped'))),
          ),
          tile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark mode',
            trailing: Switch(value: _dark, onChanged: _saveDark),
          ),
          tile(
            icon: Icons.language_outlined,
            title: 'Language',
            subtitle: 'English',
            onTap: () => ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Language picker TBD'))),
          ),
          tile(icon: Icons.contact_page_outlined, title: 'My Contact', subtitle: email),

          const SizedBox(height: 8),
          tile(icon: Icons.help_outline, title: 'FAQ'),
          tile(icon: Icons.description_outlined, title: 'Terms of service'),
          tile(icon: Icons.policy_outlined, title: 'User policy'),

          const SizedBox(height: 18),

          // Logout button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded, color: Colors.red),
                label: const Text('Log Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: card,
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: BorderSide(color: border),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
