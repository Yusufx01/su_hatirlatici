import 'package:flutter/material.dart';

import 'ui/home/home_screen.dart';

class WaterReminderApp extends StatefulWidget {
  const WaterReminderApp({super.key});

  @override
  State<WaterReminderApp> createState() => _WaterReminderAppState();
}

class _WaterReminderAppState extends State<WaterReminderApp> {
  bool _isDarkTheme = false;

  void _toggleTheme() {
    setState(() => _isDarkTheme = !_isDarkTheme);
  }

  @override
  Widget build(BuildContext context) {
    final lightTheme = ThemeData.light().copyWith(
      scaffoldBackgroundColor: Colors.grey[100],
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1FA2FF)),
    );
    final darkTheme = ThemeData.dark().copyWith(
      scaffoldBackgroundColor: Colors.grey[900],
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3BC9DB),
        brightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Su Hatırlatıcı',
      theme: _isDarkTheme ? darkTheme : lightTheme,
      home: HomeScreen(
        isDarkTheme: _isDarkTheme,
        toggleTheme: _toggleTheme,
      ),
    );
  }
}
