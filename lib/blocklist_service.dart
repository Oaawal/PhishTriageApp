import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'native_bridge.dart';

/// Keeps an offline copy of reported and official numbers.
///
/// Used by call protection (so warnings work instantly, even without data)
/// and as a fallback when a number lookup cannot reach the server.
class BlocklistService {
  static const _kData = 'blocklist_json';
  static const _kFetched = 'blocklist_fetched_at';
  static const refreshEvery = Duration(hours: 6);

  static Map<String, Map<String, dynamic>>? _reported;
  static Map<String, String>? _official;

  /// Download a fresh list if the saved one is older than [refreshEvery] (or [force]).
  static Future<int?> refresh({bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final last = DateTime.tryParse(prefs.getString(_kFetched) ?? '');
    if (!force && last != null && DateTime.now().difference(last) < refreshEvery) return null;
    try {
      final data = await ApiClient.get('/numbers/blocklist');
      final json = jsonEncode(data);
      await prefs.setString(_kData, json);
      await prefs.setString(_kFetched, DateTime.now().toIso8601String());
      _reported = null;
      _official = null;
      await NativeBridge.updateBlocklist(json);
      return (data as Map)['count'] as int?;
    } on ApiException {
      return null;
    }
  }

  static Future<DateTime?> lastUpdated() async {
    final prefs = await SharedPreferences.getInstance();
    return DateTime.tryParse(prefs.getString(_kFetched) ?? '');
  }

  static Future<void> _load() async {
    if (_reported != null) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kData);
    _reported = {};
    _official = {};
    if (raw == null) return;
    final data = jsonDecode(raw) as Map;
    for (final e in (data['numbers'] as List? ?? [])) {
      final m = Map<String, dynamic>.from(e as Map);
      _reported![m['n'] as String] = m;
    }
    for (final e in (data['official'] as List? ?? [])) {
      final m = Map<String, dynamic>.from(e as Map);
      _official![m['n'] as String] = '${m['o']}';
    }
  }

  /// Normalise like the server: +234XXXXXXXXXX.
  static String? normalize(String raw) {
    final d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('234') && d.length == 13) return '+$d';
    if (d.startsWith('0') && d.length == 11) return '+234${d.substring(1)}';
    if (d.length == 10 && '789'.contains(d[0])) return '+234$d';
    return null;
  }

  static Future<Map<String, dynamic>?> lookupOffline(String raw) async {
    final n = normalize(raw);
    if (n == null) return null;
    await _load();
    return _reported![n];
  }

  static Future<String?> officialOffline(String raw) async {
    final n = normalize(raw);
    if (n == null) return null;
    await _load();
    return _official![n];
  }

  static Future<int> count() async {
    await _load();
    return _reported!.length;
  }
}
