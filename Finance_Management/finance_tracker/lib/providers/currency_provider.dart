import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyProvider with ChangeNotifier {
  static const String _currencyKey = 'selected_currency';
  
  final _numberFormat = NumberFormat.currency(
    locale: 'fr_MA',
    symbol: '',
    decimalDigits: 2,
  );
  String _currentCurrency = 'MAD'; 
  double _conversionRate = 1.0;
  
  // Current exchange rate: 1 USD = ~10 MAD
  static const double USD_TO_MAD = 10.0;
  
  CurrencyProvider() {
    _loadSavedCurrency();
  }

  String get currentCurrency => _currentCurrency;
  double get conversionRate => _conversionRate;
  
  String get currencySymbol => _currentCurrency == 'USD' ? '\$' : 'DH';

  Future<void> _loadSavedCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCurrency = prefs.getString(_currencyKey);
    if (savedCurrency != null) {
      await switchCurrency(savedCurrency);
    } else {
      // Set MAD as default if no currency is saved
      await prefs.setString(_currencyKey, 'MAD');
    }
  }
  
  Future<void> switchCurrency(String newCurrency) async {
    if (newCurrency == _currentCurrency) return;
    
    if (_currentCurrency == 'USD' && newCurrency == 'MAD') {
      _conversionRate = USD_TO_MAD;
    } else if (_currentCurrency == 'MAD' && newCurrency == 'USD') {
      _conversionRate = 1 / USD_TO_MAD;
    }
    
    _currentCurrency = newCurrency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, newCurrency);
    notifyListeners();
  }
  
  double convert(double amount) {
    if (_currentCurrency == 'USD') {
      return amount / USD_TO_MAD;
    } else {
      return amount;
    }
  }
  
  String formatAmount(double amount) {
    if (_currentCurrency == 'USD') {
      return '\$${_numberFormat.format(convert(amount))}';
    } else {
      return '${_numberFormat.format(amount)} DH';
    }
  }
}
