import 'package:flutter/material.dart';
import '../themes/app_colors.dart';

/// Badge / chip de estado reutilizable.
///
/// Acepta un [color] semántico (`AppColors.success`, `warning`, `danger`, `primary`)
/// y un [label] en mayúsculas. Renderiza un pill con fondo al 12% del color y
/// texto del color puro.
///
/// Ejemplo:
/// ```dart
/// StatusBadge(label: 'EN MORA', color: AppColors.danger, filled: true)
/// ```
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.filled = false,
    this.fontSize = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bg = filled ? color : color.withOpacity(0.12);
    final fg = filled ? Colors.white : color;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: fg,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mapea un status de préstamo a un badge estandarizado.
class LoanStatusBadge extends StatelessWidget {
  final String status; // 'active' | 'overdue' | 'paid' | 'partial'
  final bool filled;
  final double fontSize;

  const LoanStatusBadge({
    super.key,
    required this.status,
    this.filled = false,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    final config = _resolve(status);
    return StatusBadge(
      label: config.label,
      color: config.color,
      filled: filled,
      fontSize: fontSize,
      icon: config.icon,
    );
  }

  static _BadgeConfig _resolve(String s) {
    switch (s) {
      case 'active':
        return const _BadgeConfig(
          label: 'ACTIVO',
          color: AppColors.primary,
          icon: Icons.play_circle_rounded,
        );
      case 'overdue':
        return const _BadgeConfig(
          label: 'EN MORA',
          color: AppColors.danger,
          icon: Icons.warning_rounded,
        );
      case 'paid':
        return const _BadgeConfig(
          label: 'PAGADO',
          color: AppColors.success,
          icon: Icons.check_circle_rounded,
        );
      case 'partial':
        return const _BadgeConfig(
          label: 'PARCIAL',
          color: AppColors.warning,
          icon: Icons.schedule_rounded,
        );
      case 'pending':
        return const _BadgeConfig(
          label: 'PENDIENTE',
          color: AppColors.textMuted,
          icon: Icons.schedule_rounded,
        );
      default:
        return _BadgeConfig(
          label: s.toUpperCase(),
          color: AppColors.textMuted,
          icon: Icons.help_outline_rounded,
        );
    }
  }
}

/// Mapea un status de cliente (`al_dia` | `en_mora`) a badge.
class ClientStatusBadge extends StatelessWidget {
  final String status;
  const ClientStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == 'al_dia' ? AppColors.success : AppColors.danger;
    return StatusBadge(
      label: status == 'al_dia' ? 'Al día' : 'En mora',
      color: color,
      fontSize: 10,
    );
  }
}

class _BadgeConfig {
  final String label;
  final Color color;
  final IconData icon;
  const _BadgeConfig({required this.label, required this.color, required this.icon});
}
