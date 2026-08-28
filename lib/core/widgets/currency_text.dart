import 'package:flutter/material.dart';
import '../themes/app_colors.dart';
import '../utils/currency_formatter.dart';

/// Texto monetario formateado con el color y peso semántico.
///
/// Patrón consistente: tamaño grande (default 22), bold, color configurable.
/// Usar [CurrencyText] en lugar de `Text(CurrencyFormatter.formatDOP(...))`
/// para asegurar consistencia visual.
///
/// Ejemplo:
/// ```dart
/// CurrencyText(amount: 1500.00, color: AppColors.success, size: 22)
/// ```
class CurrencyText extends StatelessWidget {
  final double amount;
  final Color color;
  final double size;
  final FontWeight weight;
  final String? prefix;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const CurrencyText({
    super.key,
    required this.amount,
    this.color = AppColors.textPrimary,
    this.size = 22,
    this.weight = FontWeight.bold,
    this.prefix,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  /// Texto financiero en color "success" (verde emerald).
  const CurrencyText.success(this.amount, {super.key, this.size = 22})
      : color = AppColors.success,
        weight = FontWeight.bold,
        prefix = null,
        textAlign = null,
        maxLines = null,
        overflow = null;

  /// Texto financiero en color "danger" (rojo).
  const CurrencyText.danger(this.amount, {super.key, this.size = 22})
      : color = AppColors.danger,
        weight = FontWeight.bold,
        prefix = null,
        textAlign = null,
        maxLines = null,
        overflow = null;

  @override
  Widget build(BuildContext context) {
    return Text(
      prefix != null
          ? '$prefix ${CurrencyFormatter.formatDOP(amount)}'
          : CurrencyFormatter.formatDOP(amount),
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: -0.3,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
