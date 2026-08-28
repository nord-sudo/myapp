class AppConfig {
  /// App Name & Branding configuration variable
  static String appName = 'Prestamistas Pro RD';
  static String appShortName = 'Prestamistas Pro';
  static String companyName = 'Plataforma Financiera RD';
  static String currencySymbol = 'RD\$';
  static String currencyCode = 'DOP';
  static String defaultCountry = 'República Dominicana';
  static String defaultCity = 'Santo Domingo';
  static String supportPhone = '809-555-0000';
  static String supportEmail = 'soporte@prestamistas.com';

  /// API Backend Server Configuration
  static String apiBaseUrl = 'https://mulberry-antiques-hunter.ngrok-free.dev/public/api';
}

class ApiConstants {
  static String get baseUrl => AppConfig.apiBaseUrl;
}