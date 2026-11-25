import 'package:flutter/material.dart';

import 'api_client.dart';
import 'blocklist_service.dart';
import 'native_bridge.dart';
import 'splash_screen.dart';

/// Used to open screens from outside the widget tree (shared text, call notifications).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Start waking the server while the splash screen shows.
  ApiClient.warmUp();
  NativeBridge.init(navigatorKey);
  // Keep the offline list of reported numbers fresh (for call protection).
  BlocklistService.refresh();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PhishTriage',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF008751)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
