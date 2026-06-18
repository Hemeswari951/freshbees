import 'package:flutter/material.dart';
import 'screens/main_scaffold.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ThiraaApp());
}

class ThiraaApp extends StatelessWidget {
  const ThiraaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thiraa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
      ),
      // App opens to SplashScreen first, which then transitions to home.
      home: const SplashScreen(),
    );
  }
}