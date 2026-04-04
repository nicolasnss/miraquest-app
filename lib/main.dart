import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const MiraQuestApp());
}

class MiraQuestApp extends StatelessWidget {
  const MiraQuestApp({super.key});

  static const Color _primary = Color(0xFF1A237E);
  static const Color _accent = Color(0xFF00E676);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.light(
      primary: _primary,
      secondary: _accent,
      surface: Colors.white,
    );

    return MaterialApp(
      title: 'MIRAQuest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: _primary,
        colorScheme: colorScheme.copyWith(
          primary: _primary,
          secondary: _accent,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          titleTextStyle: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        textTheme: GoogleFonts.outfitTextTheme(),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: _accent,
          foregroundColor: Color(0xFF1A237E),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
