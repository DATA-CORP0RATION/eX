import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';

void main() {
  runApp(const ExploreCIApp());
}

class ExploreCIApp extends StatelessWidget {
  const ExploreCIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ExploreCI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      home: const SplashScreen(),
    );
  }
}
