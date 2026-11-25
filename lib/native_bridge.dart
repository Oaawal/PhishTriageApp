import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'lookup_screen.dart';
import 'message_scanner_screen.dart';
import 'report_screen.dart';

/// Talks to the Android side (MainActivity.kt) over the "phishtriage/native" channel.
/// On iOS and web every call is a safe no-op.
class NativeBridge {
  static const _channel = MethodChannel('phishtriage/native');
  static GlobalKey<NavigatorState>? _navigator;

  static bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Listen for text shared to the app and taps on call-warning notifications.
  static void init(GlobalKey<NavigatorState> navigator) {
    _navigator = navigator;
    if (!isAndroid) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'sharedText' && call.arguments is String) {
        _openScanner(call.arguments as String);
      } else if (call.method == 'open' && call.arguments is Map) {
        _openFromNotification(Map<String, dynamic>.from(call.arguments as Map));
      }
    });
  }

  /// Handle a share or notification tap that launched the app. Call once the home screen is shown.
  static Future<void> consumeLaunchActions() async {
    if (!isAndroid) return;
    try {
      final text = await _channel.invokeMethod<String>('getSharedText');
      if (text != null && text.trim().isNotEmpty) _openScanner(text);
      final open = await _channel.invokeMethod<Map>('getPendingOpen');
      if (open != null) _openFromNotification(Map<String, dynamic>.from(open));
    } on PlatformException {
      // ignore: nothing to open
    } on MissingPluginException {
      // ignore: running in tests
    }
  }

  static void _openScanner(String text) {
    _navigator?.currentState?.push(MaterialPageRoute(
      builder: (_) => MessageScannerScreen(prefilledMessage: text, autoScan: true),
    ));
  }

  static void _openFromNotification(Map<String, dynamic> data) {
    final number = '${data['number'] ?? ''}';
    if (number.isEmpty) return;
    _navigator?.currentState?.push(MaterialPageRoute(
      builder: (_) => data['action'] == 'report'
          ? ReportScreen(prefilledNumber: number, prefilledChannel: 'call')
          : LookupScreen(prefilledNumber: number),
    ));
  }

  // ---------------- Call protection ----------------

  static Future<Map<String, dynamic>> callProtectionStatus() async {
    if (!isAndroid) return {'supported': false};
    try {
      final s = await _channel.invokeMethod<Map>('getCallProtectionStatus');
      return Map<String, dynamic>.from(s ?? {});
    } on Exception {
      return {'supported': false};
    }
  }

  /// Shows Android's "Set PhishTriage as your caller ID & spam app" dialog. Returns true if granted.
  static Future<bool> requestCallScreening() async {
    if (!isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('requestCallScreeningRole') ?? false;
    } on Exception {
      return false;
    }
  }

  static Future<void> requestNotificationPermission() async {
    if (!isAndroid) return;
    try {
      await _channel.invokeMethod('requestNotificationPermission');
    } on Exception {
      // ignore
    }
  }

  static Future<void> setBlockHighRisk(bool value) async {
    if (!isAndroid) return;
    await _channel.invokeMethod('setBlockHighRisk', value);
  }

  static Future<void> updateBlocklist(String json) async {
    if (!isAndroid) return;
    try {
      await _channel.invokeMethod('updateBlocklist', json);
    } on Exception {
      // ignore: the app keeps its own copy too
    }
  }

  static Future<List<Map<String, dynamic>>> recentCalls() async {
    if (!isAndroid) return [];
    try {
      final raw = await _channel.invokeMethod<String>('getRecentCalls') ?? '[]';
      return (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on Exception {
      return [];
    }
  }

  static Future<void> clearRecentCalls() async {
    if (!isAndroid) return;
    await _channel.invokeMethod('clearRecentCalls');
  }
}
