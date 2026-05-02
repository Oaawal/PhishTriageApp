import 'package:shared_preferences/shared_preferences.dart';

class RecentNumbers {
  static const String _key = 'recent_numbers';
  static const int _maxItems = 5;

  static Future<List<String>> getRecent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<void> addNumber(String number) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recent = prefs.getStringList(_key) ?? [];

    recent.remove(number);
    recent.insert(0, number);

    if (recent.length > _maxItems) {
      recent = recent.sublist(0, _maxItems);
    }

    await prefs.setStringList(_key, recent);
  }

  static Future<void> clearRecent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}