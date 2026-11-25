import 'package:flutter/material.dart';

import 'api_client.dart';
import 'splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Start waking the server while the splash screen shows.
  ApiClient.warmUp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PhishTriage',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF008751)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
