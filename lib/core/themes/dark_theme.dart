import 'package:flutter/material.dart';

class DarkTheme {
  static ThemeData get theme {
    return ThemeData.dark().copyWith(
      primaryColor: const Color(0xFF1B4D3E),
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardTheme: CardThemeData(
        elevation: 2,
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
