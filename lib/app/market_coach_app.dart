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
          seedColor: const Color(0xFF12A28C),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0D131A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D131A),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF0D131A),
          indicatorColor: const Color(0xFF1C2733),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          iconTheme: MaterialStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(MaterialState.selected)
                  ? Colors.white
                  : Colors.white70,
            ),
          ),
          labelTextStyle: MaterialStateProperty.resolveWith(
            (states) => const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF111925),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        textTheme: Typography.whiteMountainView.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      home: const RootShell(),
    );
  }
}
