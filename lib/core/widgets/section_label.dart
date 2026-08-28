import 'package:flutter/material.dart';
import '../themes/app_colors.dart';

/// Header de sección con icono + texto bold.
///
/// Usado para dividir formularios y pantallas en bloques semánticos.
/// Reemplaza el patrón ad-hoc `Row[Icon, SizedBox, Text]`.
///
/// Ejemplo:
/// ```dart
/// SectionLabel(
///   icon: Icons.person_outline_rounded,
///   text: 'Datos del Cliente',
/// )
/// ```
class SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Widget? trailing;

  const SectionLabel({
    super.key,
    required this.icon,
    required this.text,
    this.color = AppColors.primary,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
