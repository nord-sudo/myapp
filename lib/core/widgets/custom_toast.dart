import 'package:flutter/material.dart';
import '../themes/app_colors.dart';

/// Toast / SnackBar premium reutilizable en toda la app.
///
/// Patrón:
/// - Floating, radius 10
/// - Fondo según tipo semántico
/// - Icono a la izquierda del mensaje
///
/// Ejemplo:
/// ```dart
/// CustomToast.show(context, 'Cliente guardado', type: ToastType.success);
/// CustomToast.show(context, 'Error de conexión', type: ToastType.error);
/// ```
class CustomToast {
  CustomToast._();

  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.success,
    IconData? icon,
  }) {
    final (color, defaultIcon) = _resolve(type);
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(icon ?? defaultIcon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static (Color, IconData) _resolve(ToastType t) {
    switch (t) {
      case ToastType.success:
        return (AppColors.success, Icons.check_circle_rounded);
      case ToastType.error:
        return (AppColors.danger, Icons.error_rounded);
      case ToastType.warning:
        return (AppColors.warning, Icons.warning_rounded);
      case ToastType.info:
        return (AppColors.primary, Icons.info_rounded);
    }
  }
}

enum ToastType { success, error, warning, info }
