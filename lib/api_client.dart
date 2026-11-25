import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

/// Error with a message that is safe to show to users.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Single place for all calls to the PhishTriage API.
///
/// * Sends an anonymous install ID (X-Device-Id) so the server can tell
///   different users apart for rate limiting and duplicate reports.
/// * Long timeout plus one retry, because a sleeping server can take up
///   to a minute to wake up.
class ApiClient {
  static const _deviceKey = 'device_id';
  static const _timeout = Duration(seconds: 45);
  static String? _deviceId;

  static Future<String> deviceId() async {
    if (_deviceId != null) return _deviceId!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_deviceKey);
    if (id == null) {
      final rnd = Random.secure();
      id = List.generate(32, (_) => rnd.nextInt(16).toRadixString(16)).join();
      await prefs.setString(_deviceKey, id);
    }
    _deviceId = id;
    return id;
  }

  static Future<Map<String, String>> _headers() async => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Device-Id': await deviceId(),
      };

  static Uri _uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse(AppConfig.apiBaseUrl);
    return base.replace(
      path: '${base.path}$path'.replaceAll('//', '/'),
      queryParameters: (query == null || query.isEmpty) ? null : query,
    );
  }

  /// Fire-and-forget request so a sleeping server starts waking up early.
  static void warmUp() {
    http.get(_uri('/health')).timeout(_timeout).catchError((_) => http.Response('', 0));
  }

  static Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send(() async => http.get(_uri(path, query), headers: await _headers()));

  static Future<dynamic> post(String path, {Object? body, Map<String, String>? query}) =>
      _send(() async => http.post(
            _uri(path, query),
            headers: await _headers(),
            body: body == null ? null : jsonEncode(body),
          ));

  static Future<dynamic> _send(Future<http.Response> Function() request) async {
    http.Response? response;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        response = await request().timeout(_timeout);
        break;
      } on TimeoutException {
        if (attempt == 1) {
          throw ApiException('The server is taking too long. Please try again in a minute.');
        }
      } on http.ClientException {
        // package:http wraps socket errors (no internet, DNS) in ClientException.
        if (attempt == 1) {
          throw ApiException('No internet connection, or the server cannot be reached.');
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    final res = response!;
    dynamic data;
    try {
      data = res.body.isEmpty ? null : jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      data = null;
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return data;

    if (res.statusCode == 429) {
      throw ApiException('Too many requests. Please wait a minute and try again.', statusCode: 429);
    }
    final detail = data is Map ? data['detail'] : null;
    if (detail is String && detail.isNotEmpty) {
      throw ApiException(detail, statusCode: res.statusCode);
    }
    if (detail is List && detail.isNotEmpty) {
      throw ApiException('Please check the details you entered.', statusCode: res.statusCode);
    }
    throw ApiException('Something went wrong (error ${res.statusCode}). Please try again.',
        statusCode: res.statusCode);
  }
}
