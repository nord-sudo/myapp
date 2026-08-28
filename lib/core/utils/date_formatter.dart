class AppDateFormatter {
  static final List<String> _monthsShort = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
  ];

  /// Formats any date input (String, DateTime, int epoch) safely into clean Spanish format.
  /// Example outputs:
  /// - Full format (default): "19 Ago 2026"
  /// - Short format (short: true): "19/08/2026"
  static String formatDate(dynamic val, {bool short = false}) {
    if (val == null) return '—';
    final str = val.toString().trim();
    if (str.isEmpty || str == 'null' || str == 'undefined') return '—';

    DateTime? dt;

    if (val is DateTime) {
      dt = val;
    } else if (val is int) {
      dt = DateTime.fromMillisecondsSinceEpoch(val);
    } else {
      dt = DateTime.tryParse(str);
      if (dt == null && str.length >= 10) {
        final dateOnly = str.contains('T') ? str.split('T')[0] : str.substring(0, 10);
        dt = DateTime.tryParse(dateOnly);
      }
    }

    if (dt != null) {
      final day = dt.day.toString().padLeft(2, '0');
      final monthInt = dt.month;
      final year = dt.year;

      if (short) {
        final monthStr = monthInt.toString().padLeft(2, '0');
        return '$day/$monthStr/$year';
      } else {
        final monthName = (monthInt >= 1 && monthInt <= 12)
            ? _monthsShort[monthInt - 1]
            : monthInt.toString().padLeft(2, '0');
        return '$day $monthName $year';
      }
    }

    // Manual string parsing fallback if DateTime parsing completely failed
    try {
      final cleanStr = str.contains('T') ? str.split('T')[0] : (str.length >= 10 ? str.substring(0, 10) : str);
      final parts = cleanStr.split('-');
      if (parts.length == 3) {
        final year = parts[0];
        final monthInt = int.tryParse(parts[1]) ?? 1;
        final day = parts[2].padLeft(2, '0');
        if (short) {
          return '$day/${parts[1].padLeft(2, '0')}/$year';
        }
        final monthName = (monthInt >= 1 && monthInt <= 12) ? _monthsShort[monthInt - 1] : parts[1];
        return '$day $monthName $year';
      }
    } catch (_) {}

    // Never return raw ISO timestamps with T00:00...
    if (str.contains('T')) {
      return str.split('T')[0];
    }

    return str;
  }
}
