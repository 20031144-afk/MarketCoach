import 'package:flutter/material.dart';

import 'root_shell.dart';

class MarketCoachApp extends StatelessWidget {
  const MarketCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MarketCoach',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF06B6D4), // Vibrant Cyan
          primary: const Color(0xFF06B6D4), // Cyan
          secondary: const Color(0xFF8B5CF6), // Purple
          tertiary: const Color(0xFF10B981), // Green
          brightness: Brightness.dark,
          surface: const Color(0xFF0F172A),
          background: const Color(0xFF020617),
        ),
        scaffoldBackgroundColor: const Color(0xFF020617),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF0F172A).withOpacity(0.8),
          indicatorColor: const Color(0xFF06B6D4).withOpacity(0.2),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          iconTheme: MaterialStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(MaterialState.selected)
                  ? const Color(0xFF06B6D4)
                  : Colors.white54,
              size: 24,
            ),
          ),
          labelTextStyle: MaterialStateProperty.resolveWith(
            (states) => TextStyle(
              color: states.contains(MaterialState.selected)
                  ? const Color(0xFF06B6D4)
                  : Colors.white54,
              fontWeight: states.contains(MaterialState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E293B).withOpacity(0.6),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -1,
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ),
      home: const RootShell(),
    );
  }
}
