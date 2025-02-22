import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/database_helper.dart';
import '../models/account.dart';
import '../models/transaction.dart';

class AccountProvider with ChangeNotifier {
  static const String userNameKey = 'user_name';
  static const String currentAccountIdKey = 'current_account_id';
  List<Account> _accounts = [];
  Account? _selectedAccount;
  List<Transaction> _transactions = [];
  String? _userName;
  double _totalBalance = 0;
  Account? _displayedWalletAccount;

  List<Account> get accounts => _accounts;
  Account? get selectedAccount => _selectedAccount;
  List<Transaction> get transactions => _transactions;
  String? get userName => _userName;
  double get totalBalance => _totalBalance;
  Account? get displayedWalletAccount => _displayedWalletAccount;

  Future<void> loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString(userNameKey);
    notifyListeners();
  }

  Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userNameKey, name);
    _userName = name;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(userNameKey);
    await prefs.remove(currentAccountIdKey);
    await prefs.remove('has_session');
    _userName = null;
    _selectedAccount = null;
    _displayedWalletAccount = null;
    _accounts.clear();
    _transactions.clear();
    _totalBalance = 0;
    notifyListeners();
  }

  Future<void> updateProfile(
    String newName,
    double newBalance, {
    String? newPassword,
  }) async {
    if (_selectedAccount != null) {
      final db = await DatabaseHelper.instance.database;
      final data = {'name': newName, 'balance': newBalance};

      if (newPassword != null) {
        data['password'] = newPassword;
      }

      await db.update(
        'accounts',
        data,
        where: 'id = ?',
        whereArgs: [_selectedAccount!.id],
      );
      await loadAccounts();
      await selectAccount(
        _accounts.firstWhere((a) => a.id == _selectedAccount!.id),
      );
    }
  }

  Future<void> deleteProfile() async {
    if (_selectedAccount != null) {
      final db = await DatabaseHelper.instance.database;
      await db.transaction((txn) async {
        // Delete all transactions for this account
        await txn.delete(
          'transactions',
          where: 'account_id = ?',
          whereArgs: [_selectedAccount!.id],
        );
        // Delete the account
        await txn.delete(
          'accounts',
          where: 'id = ?',
          whereArgs: [_selectedAccount!.id],
        );
      });

      // Load remaining accounts
      await loadAccounts();

      if (_accounts.isEmpty) {
        await logout();
      } else {
        await selectAccount(_accounts.first);
      }
    }
  }

  Future<void> saveCurrentAccount() async {
    if (_selectedAccount != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(currentAccountIdKey, _selectedAccount!.id!);
    }
  }

  Future<bool> loadLastSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSession = prefs.getBool('has_session') ?? false;
      if (!hasSession) return false;

      final accountId = prefs.getInt(currentAccountIdKey);
      _userName = prefs.getString(userNameKey);

      if (accountId == null || _userName == null) {
        return false;
      }

      await loadAccounts();

      try {
        final lastAccount = _accounts.firstWhere(
          (account) => account.id == accountId,
        );
        await selectAccount(lastAccount);
        return true;
      } catch (e) {
        // Account not found
        return false;
      }
    } catch (e) {
      print('Error loading last session: $e');
      return false;
    }
  }

  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return !prefs.containsKey(userNameKey);
  }

  Future<List<Account>> getAllAccounts() async {
    final accountsData = await DatabaseHelper.instance.getAccounts();
    return accountsData.map((data) => Account.fromMap(data)).toList();
  }

  Future<void> loadAccounts() async {
    final accountsData = await DatabaseHelper.instance.getAccounts();
    _accounts = accountsData.map((data) => Account.fromMap(data)).toList();

    if (_accounts.isNotEmpty) {
      if (_selectedAccount == null) {
        // Only set first account if no account is selected
        final prefs = await SharedPreferences.getInstance();
        final savedAccountId = prefs.getInt(currentAccountIdKey);

        if (savedAccountId != null) {
          _selectedAccount = _accounts.firstWhere(
            (account) => account.id == savedAccountId,
            orElse: () => _accounts.first,
          );
        } else {
          _selectedAccount = _accounts.first;
        }

        _displayedWalletAccount = _selectedAccount;
        _totalBalance = _selectedAccount!.balance;
        await loadTransactions();
      } else {
        // Update selected account with fresh data
        final updatedAccount = _accounts.firstWhere(
          (account) => account.id == _selectedAccount!.id,
          orElse: () => _selectedAccount!,
        );
        _selectedAccount = updatedAccount;
        _displayedWalletAccount =
            updatedAccount; // Always sync with selected account
        _totalBalance = updatedAccount.balance;
      }
    }

    notifyListeners();
  }

  Future<Account> createAccount(
    String name,
    double balance,
    String password,
  ) async {
    final id = await DatabaseHelper.instance.createAccount(
      name,
      balance,
      password,
    );
    
    // Reload accounts to get the fresh data
    await loadAccounts();
    
    // Find and return the newly created account
    final newAccount = _accounts.firstWhere((account) => account.id == id);
    return newAccount;
  }

  Future<Account?> findAccountByName(String name) async {
    final accounts = await getAllAccounts();
    return accounts.cast<Account?>().firstWhere(
      (account) => account?.name.toLowerCase() == name.toLowerCase(),
      orElse: () => null,
    );
  }

  Future<bool> verifyPassword(Account account, String password) async {
    return account.password ==
        password; // In a real app, use proper password hashing
  }

  Future<void> selectAccount(Account account) async {
    _selectedAccount = account;
    _displayedWalletAccount = account;
    _userName = account.name;
    _totalBalance = account.balance;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(currentAccountIdKey, account.id!);
    await prefs.setString(userNameKey, account.name);
    await prefs.setBool('has_session', true);

    await loadTransactions();
    notifyListeners();
  }

  Future<void> loadTransactions() async {
    if (_selectedAccount != null) {
      final transactionsData = await DatabaseHelper.instance
          .getTransactionsByAccount(_selectedAccount!.id!);
      _transactions =
          transactionsData.map((data) => Transaction.fromMap(data)).toList();
      notifyListeners();
    }
  }

  Future<void> addTransaction(
    String title,
    String description,
    double amount,
    String type,
  ) async {
    if (_selectedAccount != null) {
      final date = DateTime.now().toIso8601String();
      final id = await DatabaseHelper.instance.addTransaction(
        _selectedAccount!.id!,
        title,
        description,
        amount,
        type,
        date,
      );

      final transaction = Transaction(
        id: id,
        accountId: _selectedAccount!.id!,
        title: title,
        description: description,
        amount: amount,
        type: type,
        date: DateTime.now(),
      );

      _transactions.insert(0, transaction);
      await loadAccounts();
      notifyListeners();
    }
  }

  Future<List<Transaction>> searchTransactions(String query) async {
    if (query.isEmpty || _selectedAccount == null) return [];
    final results = await DatabaseHelper.instance.searchTransactions(
      query,
      _selectedAccount!.id!,
    );
    return results.map((data) => Transaction.fromMap(data)).toList();
  }

  Future<List<Transaction>> getTransactionsByTitle(String title) async {
    final results = await DatabaseHelper.instance.searchTransactionsByTitle(
      title,
    );
    return results.map((data) => Transaction.fromMap(data)).toList();
  }

  Map<String, double> getTransactionStats(String period) {
    final now = DateTime.now();
    DateTime startDate;

    switch (period.toLowerCase()) {
      case 'week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = now.subtract(const Duration(days: 30));
    }

    final periodTransactions =
        _transactions
            .where(
              (t) =>
                  t.date.isAfter(startDate) ||
                  t.date.isAtSameMomentAs(startDate),
            )
            .toList();

    double totalDeposits = 0;
    double totalPayments = 0;

    for (var transaction in periodTransactions) {
      if (transaction.type == 'deposit') {
        totalDeposits += transaction.amount;
      } else {
        totalPayments += transaction.amount;
      }
    }

    final total = totalDeposits + totalPayments;
    final depositPercentage =
        total > 0 ? (totalDeposits / total * 100).toDouble() : 0.0;
    final paymentPercentage =
        total > 0 ? (totalPayments / total * 100).toDouble() : 0.0;

    return {
      'totalDeposits': totalDeposits,
      'totalPayments': totalPayments,
      'depositPercentage': depositPercentage,
      'paymentPercentage': paymentPercentage,
    };
  }

  void updateDisplayedWalletAccount(Account account) {
    _displayedWalletAccount = account;
    notifyListeners();
  }

  void resetDisplayedWalletAccount() {
    _displayedWalletAccount = _selectedAccount;
    notifyListeners();
  }

  Future<List<Transaction>> getTransactionsForAccount(Account account) async {
    if (account.id != null) {
      final transactionsData = await DatabaseHelper.instance
          .getTransactionsByAccount(account.id!);
      return transactionsData.map((data) => Transaction.fromMap(data)).toList();
    }
    return [];
  }

  Future<void> deleteTransaction(int? id) async {
    if (_selectedAccount != null && id != null) {
      await DatabaseHelper.instance.deleteTransaction(id);
      _transactions.removeWhere((transaction) => transaction.id == id);
      await loadAccounts(); // Reload account to update balance
      notifyListeners();
    }
  }
}
