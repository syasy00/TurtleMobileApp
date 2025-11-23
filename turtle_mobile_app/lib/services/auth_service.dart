import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  // ----- Sign In / Sign Up -----
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Set displayName = "First Last" if provided
    final display = [firstName, lastName]
        .where((s) => s != null && s!.trim().isNotEmpty)
        .map((s) => s!.trim())
        .join(' ')
        .trim();

    if (display.isNotEmpty) {
      await cred.user?.updateDisplayName(display);
      await cred.user?.reload(); // ensure currentUser reflects new name
    }
  }

  // ----- Remember-me helpers -----
  static const _kSavedEmail = 'saved_email';

  Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSavedEmail, email);
  }

  Future<void> clearSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSavedEmail);
  }

  Future<String?> loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kSavedEmail);
  }
}
