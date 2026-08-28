import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'es_DO',
    symbol: 'RD\$ ',
    decimalDigits: 2,
  );

  static String format(dynamic amount) {
    if (amount == null) return 'RD\$ 0.00';
    double value = 0.0;
    if (amount is double) value = amount;
    else if (amount is int) value = amount.toDouble();
    else if (amount is String) value = double.tryParse(amount) ?? 0.0;
    else if (amount is num) value = amount.toDouble();
    return _formatter.format(value);
  }
}

class DateFormatter {
  static String format(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      DateTime dt;
      if (dateStr is DateTime) dt = dateStr;
      else dt = DateTime.parse(dateStr.toString());
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return dateStr.toString();
    }
  }
}
