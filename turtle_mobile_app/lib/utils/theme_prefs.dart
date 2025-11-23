import 'package:shared_preferences/shared_preferences.dart';

class ThemePrefs {
  static const _kDark = 'dark_mode_on';

  static Future<bool> load() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kDark) ?? false;
  }

  static Future<void> save(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kDark, value);
  }
}
