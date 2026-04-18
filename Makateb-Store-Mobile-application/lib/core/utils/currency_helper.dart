import 'package:intl/intl.dart';

/// Currency constants for Jordanian Dinar (JOD)
///
/// Equivalent to Vue's currency constants.
class CurrencyConstants {
  CurrencyConstants._();

  /// Currency symbol
  static const String symbol = 'JD';

  /// Currency code (ISO 4217)
  static const String code = 'JOD';

  /// Currency locale
  static const String locale = 'ar-JO';
}

/// FormatPriceOptions - Options for price formatting
///
/// Configuration options for formatting prices.
/// Equivalent to Vue's formatPrice options parameter.
class FormatPriceOptions {
  /// Whether to show currency symbol
  final bool showSymbol;

  /// Number of decimal places
  final int decimals;

  /// Locale for formatting (currently unused in basic format)
  final String locale;

  const FormatPriceOptions({
    this.showSymbol = true,
    this.decimals = 2,
    this.locale = 'en-US',
  });
}

/// CurrencyHelper - Currency utility for Jordanian Dinar (JOD)
///
/// Equivalent to Vue's currency.js utility file.
/// Provides functions for formatting prices with currency symbols.
class CurrencyHelper {
  CurrencyHelper._();

  /// Format price with Jordanian Dinar symbol
  ///
  /// Equivalent to Vue's formatPrice() function.
  ///
  /// [price] - The price to format (number or string)
  /// [options] - Formatting options
  /// Returns formatted price string
  ///
  /// Example:
  /// ```dart
  /// CurrencyHelper.formatPrice(99.99); // "99.99 JD"
  /// CurrencyHelper.formatPrice(99.99, FormatPriceOptions(showSymbol: false)); // "99.99"
  /// CurrencyHelper.formatPrice(99.99, FormatPriceOptions(decimals: 0)); // "100 JD"
  /// ```
  static String formatPrice(
    dynamic price, [
    FormatPriceOptions? options,
  ]) {
    // Handle null/undefined
    if (price == null) {
      return _formatWithSymbol('0.00', options?.showSymbol ?? true);
    }

    // Parse price
    double numPrice;
    if (price is String) {
      numPrice = double.tryParse(price) ?? 0.0;
    } else if (price is num) {
      numPrice = price.toDouble();
    } else {
      return _formatWithSymbol('0.00', options?.showSymbol ?? true);
    }

    // Check if NaN
    if (numPrice.isNaN) {
      return _formatWithSymbol('0.00', options?.showSymbol ?? true);
    }

    // Format with decimals
    final decimals = options?.decimals ?? 2;
    final formatted = numPrice.toStringAsFixed(decimals);

    // Return with or without symbol
    return _formatWithSymbol(formatted, options?.showSymbol ?? true);
  }

  /// Format price with currency symbol using NumberFormat
  ///
  /// Equivalent to Vue's formatPriceIntl() function.
  ///
  /// [price] - The price to format (number or string)
  /// Returns formatted price string using Intl.NumberFormat
  ///
  /// Example:
  /// ```dart
  /// CurrencyHelper.formatPriceIntl(99.99); // "JOD 99.99" or "99.99 JD" depending on locale
  /// ```
  static String formatPriceIntl(dynamic price) {
    // Handle null/undefined
    if (price == null) {
      return '0.00 ${CurrencyConstants.symbol}';
    }

    // Parse price
    double numPrice;
    if (price is String) {
      numPrice = double.tryParse(price) ?? 0.0;
    } else if (price is num) {
      numPrice = price.toDouble();
    } else {
      return '0.00 ${CurrencyConstants.symbol}';
    }

    // Check if NaN
    if (numPrice.isNaN) {
      return '0.00 ${CurrencyConstants.symbol}';
    }

    try {
      // Use NumberFormat for international formatting
      final formatter = NumberFormat.currency(
        symbol: CurrencyConstants.symbol,
        decimalDigits: 2,
        locale: 'en_US', // Use en_US for consistent formatting
      );
      return formatter.format(numPrice);
    } catch (e) {
      // Fallback to basic formatPrice if Intl fails
      return formatPrice(price);
    }
  }

  /// Format price for display (simple format: "XX.XX JD")
  ///
  /// Equivalent to Vue's formatPriceDisplay() function.
  ///
  /// [price] - The price to format (number or string)
  /// Returns formatted price string with symbol
  ///
  /// Example:
  /// ```dart
  /// CurrencyHelper.formatPriceDisplay(99.99); // "99.99 JD"
  /// ```
  static String formatPriceDisplay(dynamic price) {
    return formatPrice(price, const FormatPriceOptions(showSymbol: true));
  }

  /// Get currency symbol
  ///
  /// Equivalent to Vue's getCurrencySymbol() function.
  ///
  /// Returns currency symbol string
  ///
  /// Example:
  /// ```dart
  /// CurrencyHelper.getCurrencySymbol(); // "JD"
  /// ```
  static String getCurrencySymbol() {
    return CurrencyConstants.symbol;
  }

  /// Get currency code
  ///
  /// Equivalent to Vue's getCurrencyCode() function.
  ///
  /// Returns currency code string
  ///
  /// Example:
  /// ```dart
  /// CurrencyHelper.getCurrencyCode(); // "JOD"
  /// ```
  static String getCurrencyCode() {
    return CurrencyConstants.code;
  }

  /// Helper method to format with symbol
  static String _formatWithSymbol(String formatted, bool showSymbol) {
    if (showSymbol) {
      return '$formatted ${CurrencyConstants.symbol}';
    }
    return formatted;
  }
}



