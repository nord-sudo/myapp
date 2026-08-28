class CedulaValidator {
  /// Validates a Dominican Cédula.
  /// Accepts 11 digits (with or without hyphens).
  static bool validate(String cedula) {
    final clean = cedula.replaceAll(RegExp(r'[^0-9]'), '');
    return clean.length == 11;
  }

  /// Strict Dominican Cédula Modulo 11 check digit verification.
  static bool isStrictModulo11(String cedula) {
    final clean = cedula.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length != 11) return false;

    final digits = clean.split('').map(int.parse).toList();
    final checkDigit = digits.removeLast();
    int sum = 0;
    const multipliers = [1, 2, 1, 2, 1, 2, 1, 2, 1, 2];

    for (int i = 0; i < 10; i++) {
      int prod = digits[i] * multipliers[i];
      if (prod >= 10) {
        prod = (prod % 10) + 1;
      }
      sum += prod;
    }

    int remainder = sum % 10;
    int result = (remainder == 0) ? 0 : 10 - remainder;
    return result == checkDigit;
  }
}

class PhoneValidator {
  static bool validate(String phone) {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return clean.length >= 10;
  }
}

class EmailValidator {
  static bool validate(String email) {
    if (email.isEmpty) return true;
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
