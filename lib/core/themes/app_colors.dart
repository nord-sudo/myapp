import 'package:flutter/material.dart';

class AppColors {
  // Primary Branding & Background (Dark Forest Green & Clean Off-White)
  static const Color primary = Color(0xFF163A2B); // Dark Forest Green Header
  static const Color primaryDark = Color(0xFF0F291E);
  static const Color primaryLight = Color(0xFF1E4D3A);
  
  static const Color accent = Color(0xFF00B67A); // Emerald / Mint Action Green
  static const Color background = Color(0xFFF6F8F7); // Clean Soft Background
  static const Color cardBackground = Colors.white;
  static const Color cardBorder = Color(0xFFE2E8F0);

  // Gradients
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF163A2B), Color(0xFF1F4E3D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF00B67A), Color(0xFF059669)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Status & Financial Indicators
  static const Color success = Color(0xFF00B67A); // Emerald Green (Activo / Cobrado)
  static const Color successBg = Color(0xFFE6F8F0);
  
  static const Color info = Color(0xFF2563EB);
  static const Color infoBg = Color(0xFFEFF6FF);

  static const Color warning = Color(0xFFEAB308); // Amber (Pendiente)
  static const Color warningBg = Color(0xFFFEF3C7);

  static const Color danger = Color(0xFFEF4444); // Crimson Red (Vencido / Mora)
  static const Color dangerBg = Color(0xFFFEE2E2);

  static const Color inactive = Color(0xFF64748B); // Cool Slate Grey (Inactivo)
  static const Color inactiveBg = Color(0xFFF1F5F9);

  // Text colors
  static const Color textPrimary = Color(0xFF1C2A24);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Card & Container Shadows
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}


