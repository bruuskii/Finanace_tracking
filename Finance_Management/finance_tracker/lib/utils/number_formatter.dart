import 'package:intl/intl.dart';

import 'package:provider/provider.dart';
import 'package:flutter/widgets.dart';
import '../providers/currency_provider.dart';

class NumberFormatter {
  static final _numberFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '',
    decimalDigits: 2,
  );
  static final _compactFormat = NumberFormat.compact();

  static String formatCurrency(double value, [BuildContext? context]) {
    if (context != null) {
      final currencyProvider = Provider.of<CurrencyProvider>(context, listen: true);
      return currencyProvider.formatAmount(value);
    }
    return '\$${_numberFormat.format(value)}';
  }

  static String formatCompact(double value, [BuildContext? context]) {
    if (context != null) {
      final currencyProvider = Provider.of<CurrencyProvider>(context, listen: true);
      final convertedValue = currencyProvider.convert(value);
      return currencyProvider.currentCurrency == 'USD'
          ? '\$${_compactFormat.format(convertedValue)}'
          : '${_compactFormat.format(convertedValue)} ${currencyProvider.currencySymbol}';
    }
    return '\$${_compactFormat.format(value)}';
  }
}
