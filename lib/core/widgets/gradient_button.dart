import 'package:flutter/material.dart';
import '../themes/app_colors.dart';

/// Botón CTA premium con gradient verde del Design System.
///
/// Variantes:
/// - [variant]: `primary` (Forest Green) | `success` | `danger` | `warning`
///
/// Ejemplo:
/// ```dart
/// GradientButton(
///   text: 'Iniciar Sesión',
///   isLoading: state.isLoading,
///   onPressed: _submit,
/// )
/// ```
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final GradientButtonVariant variant;
  final double height;
  final double borderRadius;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = GradientButtonVariant.primary,
    this.height = 52,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _resolveColors(variant);
    final shadowColor = _resolveShadow(variant);

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white70,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  List<Color> _resolveColors(GradientButtonVariant v) {
    switch (v) {
      case GradientButtonVariant.primary:
        return [AppColors.primary, AppColors.primary.withOpacity(0.85)];
      case GradientButtonVariant.success:
        return [AppColors.success, AppColors.success.withOpacity(0.85)];
      case GradientButtonVariant.danger:
        return [AppColors.danger, AppColors.danger.withOpacity(0.85)];
      case GradientButtonVariant.warning:
        return [AppColors.warning, AppColors.warning.withOpacity(0.85)];
    }
  }

  Color _resolveShadow(GradientButtonVariant v) {
    switch (v) {
      case GradientButtonVariant.primary:
        return AppColors.primary;
      case GradientButtonVariant.success:
        return AppColors.success;
      case GradientButtonVariant.danger:
        return AppColors.danger;
      case GradientButtonVariant.warning:
        return AppColors.warning;
    }
  }
}

enum GradientButtonVariant { primary, success, danger, warning }
