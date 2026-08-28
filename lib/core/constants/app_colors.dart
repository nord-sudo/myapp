import 'package:flutter/material.dart';

class AppColors {
  // Primary & Background (Forest Green & Clean Off-White)
  static const Color primary = Color(0xFF19352C); // Deep Forest Green
  static const Color accent = Color(0xFF19352C); // Deep Forest Green Primary Accent
  static const Color background = Color(0xFFF7F7F5); // Clean Warm Grey/Off-White
  static const Color cardBackground = Colors.white;

  // Status & Financial Indicators
  static const Color success = Color(0xFF10B981); // Emerald Green (Cobrado / Al día)
  static const Color warning = Color(0xFFF59E0B); // Amber (Pendiente)
  static const Color danger = Color(0xFFEF4444); // Crimson Red (Mora)

  // Text colors
  static const Color textPrimary = Color(0xFF1F1F1D);
  static const Color textSecondary = Color(0xFF777773);
  static const Color textMuted = Color(0xFFA3A39E);

  // Card & Container Shadows
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}
