import 'package:flutter/material.dart';
import '../themes/app_colors.dart';

/// Card blanca con bordes redondeados y sombra suave del Design System.
///
/// Envuelve un [Container] blanco con `AppColors.softShadow` (4% black, blur 12).
/// Acepta un [child] arbitrario y un [onTap] opcional para hacerlo interactivo.
///
/// Ejemplo:
/// ```dart
/// SoftCard(
///   padding: EdgeInsets.all(16),
///   child: Text('Cartera Total'),
/// )
/// ```
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;
  final Color? borderColor;
  final double borderWidth;
  final Gradient? gradient;
  final Color? color;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.radius = 16,
    this.borderColor,
    this.borderWidth = 0,
    this.gradient,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final container = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppColors.cardBackground) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
        boxShadow: gradient == null ? AppColors.softShadow : null,
      ),
      child: child,
    );

    if (onTap == null) return container;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: container,
      ),
    );
  }
}

/// Hero card con gradient verde primario. Usar para saldos totales,
/// balances principales, y tarjetas de resumen de alto impacto.
class GradientHeroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final List<Color>? colors;
  final double radius;
  final VoidCallback? onTap;

  const GradientHeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.colors,
    this.radius = 22,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gradientColors = colors ?? [AppColors.primary, AppColors.accent.withOpacity(0.85)];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
