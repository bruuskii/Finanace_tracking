import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io' show Platform;
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'finance_tracker.db');
    return await openDatabase(
      path,
      version: 2, // Increment version for migration
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE accounts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            balance REAL NOT NULL,
            password TEXT NOT NULL
          )
        ''');
        
        await db.execute('''
          CREATE TABLE transactions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            account_id INTEGER,
            title TEXT NOT NULL,
            description TEXT,
            amount REAL NOT NULL,
            type TEXT NOT NULL,
            date TEXT NOT NULL,
            FOREIGN KEY (account_id) REFERENCES accounts (id)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE accounts ADD COLUMN password TEXT NOT NULL DEFAULT ""');
        }
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // This method is no longer used
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // This method is no longer used
  }

  Future<int> createAccount(String name, double balance, String password) async {
    final db = await database;
    final data = {
      'name': name,
      'balance': balance,
      'password': password,
    };
    return await db.insert('accounts', data);
  }

  Future<int> addTransaction(int accountId, String title, String description, double amount, String type, String date) async {
    final db = await database;
    final data = {
      'account_id': accountId,
      'title': title,
      'description': description,
      'amount': amount,
      'type': type,
      'date': date,
    };
    
    // Update account balance
    if (type == 'deposit') {
      await db.rawUpdate(
        'UPDATE accounts SET balance = balance + ? WHERE id = ?',
        [amount, accountId]
      );
    } else {
      await db.rawUpdate(
        'UPDATE accounts SET balance = balance - ? WHERE id = ?',
        [amount, accountId]
      );
    }
    
    return await db.insert('transactions', data);
  }

  Future<List<Map<String, dynamic>>> getAccounts() async {
    final db = await database;
    return db.query('accounts');
  }

  Future<List<Map<String, dynamic>>> getTransactionsByAccount(int accountId) async {
    final db = await database;
    return db.query(
      'transactions',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> searchTransactions(String query, int accountId) async {
    final db = await database;
    return db.rawQuery(
      '''
      SELECT t.*, a.name as account_name 
      FROM transactions t 
      JOIN accounts a ON t.account_id = a.id 
      WHERE (t.title LIKE ? OR t.description LIKE ?) AND t.account_id = ?
      ORDER BY t.date DESC
      ''',
      ['%$query%', '%$query%', accountId]
    );
  }

  Future<List<Map<String, dynamic>>> searchTransactionsByTitle(String title) async {
    final db = await database;
    return db.rawQuery(
      '''
      SELECT t.*, a.name as account_name 
      FROM transactions t 
      JOIN accounts a ON t.account_id = a.id 
      WHERE t.title = ?
      ORDER BY t.date DESC
      ''',
      [title],
    );
  }

  Future<double> getTotalBalance() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(balance) as total FROM accounts');
    return result.first['total'] as double? ?? 0.0;
  }

  Future<void> deleteTransaction(int? id) async {
    if (id == null) return;
    
    final db = await database;
    
    // First get the transaction details to update the account balance
    final transaction = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (transaction.isNotEmpty) {
      final accountId = transaction.first['account_id'] as int;
      final amount = transaction.first['amount'] as double;
      final type = transaction.first['type'] as String;

      // Update account balance (reverse the transaction)
      if (type == 'deposit') {
        await db.rawUpdate(
          'UPDATE accounts SET balance = balance - ? WHERE id = ?',
          [amount, accountId]
        );
      } else {
        await db.rawUpdate(
          'UPDATE accounts SET balance = balance + ? WHERE id = ?',
          [amount, accountId]
        );
      }

      // Delete the transaction
      await db.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }
}
