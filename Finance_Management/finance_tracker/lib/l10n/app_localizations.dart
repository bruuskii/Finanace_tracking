import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  late Map<String, String> _localizedStrings;

  Future<bool> load() async {
    String jsonString = await rootBundle.loadString('lib/l10n/app_${locale.languageCode}.arb');
    Map<String, dynamic> jsonMap = json.decode(jsonString);

    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });

    return true;
  }

  String get appTitle => _localizedStrings['appTitle'] ?? 'Finance Tracker';
  String get home => _localizedStrings['home'] ?? 'Home';
  String get wallet => _localizedStrings['wallet'] ?? 'Wallet';
  String get more => _localizedStrings['more'] ?? 'More';
  String get settings => _localizedStrings['settings'] ?? 'Settings';
  String get language => _localizedStrings['language'] ?? 'Language';
  String get currency => _localizedStrings['currency'] ?? 'Currency';
  String get theme => _localizedStrings['theme'] ?? 'Theme';
  String get income => _localizedStrings['income'] ?? 'Income';
  String get expense => _localizedStrings['expense'] ?? 'Expense';
  String get balance => _localizedStrings['balance'] ?? 'Balance';
  String get addTransaction => _localizedStrings['addTransaction'] ?? 'Add Transaction';
  String get categories => _localizedStrings['categories'] ?? 'Categories';
  String get statistics => _localizedStrings['statistics'] ?? 'Statistics';
  String get profile => _localizedStrings['profile'] ?? 'Profile';
  String get logout => _localizedStrings['logout'] ?? 'Logout';
  String get logOut => _localizedStrings['logout'] ?? 'Logout'; 
  String get switchProfile => _localizedStrings['switchProfile'] ?? 'Switch Profile';
  String get totalBalance => _localizedStrings['totalBalance'] ?? 'Total Balance';
  String get selectLanguage => _localizedStrings['selectLanguage'] ?? 'Select Language';
  String get selectCurrency => _localizedStrings['selectCurrency'] ?? 'Select Currency';
  String get cancel => _localizedStrings['cancel'] ?? 'Cancel';
  String get done => _localizedStrings['done'] ?? 'Done';
  String get areYouSureYouWantToLogOut => _localizedStrings['areYouSureYouWantToLogOut'] ?? 'Are you sure you want to log out?';
  String get recentTransactions => _localizedStrings['recentTransactions'] ?? 'Recent Transactions';
  String get noTransactions => _localizedStrings['noTransactions'] ?? 'No transactions';
  String get noTransactionsForAccount => _localizedStrings['noTransactionsForAccount'] ?? 'No transactions for this account';
  String get active => _localizedStrings['active'] ?? 'Active';
  String get spendingAnalysis => _localizedStrings['spendingAnalysis'] ?? 'Spending Analysis';
  String get spendingAnalysisSubtitle => _localizedStrings['spendingAnalysisSubtitle'] ?? 'Track your income and spending patterns';
  String get week => _localizedStrings['week'] ?? 'Week';
  String get month => _localizedStrings['month'] ?? 'Month';
  String get threeMonths => _localizedStrings['threeMonths'] ?? '3 Months';
  String get year => _localizedStrings['year'] ?? 'Year';
  String get spent => _localizedStrings['spent'] ?? 'Spent';
  String get saved => _localizedStrings['saved'] ?? 'Saved';
  String spentThisPeriod(String period) {
    final template = _localizedStrings['spentThisPeriod'] ?? 'Spent this {period}';
    return template.replaceAll('{period}', period);
  }
  String get totalIncome => _localizedStrings['totalIncome'] ?? 'Total Income';
  String get totalSpending => _localizedStrings['totalSpending'] ?? 'Total Spending';
  String get savings => _localizedStrings['savings'] ?? 'Savings';
  String get welcomeBack => _localizedStrings['welcomeBack'] ?? 'Welcome back,';
  String get defaultUsername => _localizedStrings['defaultUsername'] ?? 'User';
  String get editProfile => _localizedStrings['editProfile'] ?? 'Edit Profile';
  String get deleteProfile => _localizedStrings['deleteProfile'] ?? 'Delete Profile';
  String get deleteProfileConfirmation => _localizedStrings['deleteProfileConfirmation'] ?? 'Are you sure you want to delete this profile? This action cannot be undone.';
  String get delete => _localizedStrings['delete'] ?? 'Delete';
  String get addIncome => _localizedStrings['addIncome'] ?? 'Add Income';
  String get addExpense => _localizedStrings['addExpense'] ?? 'Add Expense';
  String get viewAll => _localizedStrings['viewAll'] ?? 'View All';
  String get noRecentTransactions => _localizedStrings['noRecentTransactions'] ?? 'No recent transactions';
  String get title => _localizedStrings['title'] ?? 'Title';
  String get pleaseEnterTitle => _localizedStrings['pleaseEnterTitle'] ?? 'Please enter a title';
  String get descriptionOptional => _localizedStrings['descriptionOptional'] ?? 'Description (Optional)';
  String get amount => _localizedStrings['amount'] ?? 'Amount';
  String get pleaseEnterAmount => _localizedStrings['pleaseEnterAmount'] ?? 'Please enter an amount';
  String get pleaseEnterValidNumber => _localizedStrings['pleaseEnterValidNumber'] ?? 'Please enter a valid number';
  String get transactions => _localizedStrings['transactions'] ?? 'Transactions';
  String get searchTransactions => _localizedStrings['searchTransactions'] ?? 'Search transactions...';
  String get all => _localizedStrings['all'] ?? 'All';
  String get noTransactionsFound => _localizedStrings['noTransactionsFound'] ?? 'No transactions found';
  String get noTransactionsYet => _localizedStrings['noTransactionsYet'] ?? 'No transactions yet';
  String get tryAdjustingSearch => _localizedStrings['tryAdjustingSearch'] ?? 'Try adjusting your search';
  String get deleteTransaction => _localizedStrings['deleteTransaction'] ?? 'Delete Transaction';
  String get deleteTransactionConfirmation => _localizedStrings['deleteTransactionConfirmation'] ?? 'Are you sure you want to delete this transaction?';
  String get transactionDeleted => _localizedStrings['transactionDeleted'] ?? 'Transaction deleted';
  String get undo => _localizedStrings['undo'] ?? 'Undo';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'fr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
