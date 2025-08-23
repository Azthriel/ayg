import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'es_AR',
    symbol: '\$',
    decimalDigits: 2,
  );

  static final NumberFormat _compactFormatter = NumberFormat.currency(
    locale: 'es_AR', 
    symbol: '\$',
    decimalDigits: 0,
  );

  /// Formatea un monto como moneda argentina con separadores de miles
  /// Ejemplo: 1234567.50 → "$1.234.567,50"
  static String formatCurrency(double amount) {
    return _formatter.format(amount);
  }

  /// Formatea un monto como moneda argentina sin decimales cuando son .00
  /// Ejemplo: 1234567.00 → "$1.234.567", 1234567.50 → "$1.234.567,50"
  static String formatCurrencyCompact(double amount) {
    if (amount == amount.roundToDouble()) {
      return _compactFormatter.format(amount);
    }
    return _formatter.format(amount);
  }

  /// Formatea un monto con separadores de miles sin símbolo de moneda
  /// Ejemplo: 1234567.50 → "1.234.567,50"
  static String formatNumber(double amount) {
    final formatter = NumberFormat('#,##0.00', 'es_AR');
    return formatter.format(amount);
  }

  /// Formatea un monto con separadores de miles sin decimales cuando son .00
  /// Ejemplo: 1234567.00 → "1.234.567", 1234567.50 → "1.234.567,50"
  static String formatNumberCompact(double amount) {
    if (amount == amount.roundToDouble()) {
      final formatter = NumberFormat('#,##0', 'es_AR');
      return formatter.format(amount);
    }
    final formatter = NumberFormat('#,##0.00', 'es_AR');
    return formatter.format(amount);
  }
}
