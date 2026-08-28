import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String formatDOP(dynamic amount) {
    if (amount == null) return '0,00 RD\$';
    final double value = (amount is String) ? (double.tryParse(amount) ?? 0.0) : (amount as num).toDouble();
    
    // Format e.g. 20000.0 -> 20.000,00 RD$
    final formatter = NumberFormat('#,##0.00', 'de_DE');
    return '${formatter.format(value)} RD\$';
  }

  static String format(dynamic amount) => formatDOP(amount);

  static String formatCedula(String cedula) {
    final clean = cedula.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 11) {
      return '${clean.substring(0, 3)}-${clean.substring(3, 10)}-${clean.substring(10)}';
    }
    return cedula;
  }
}

