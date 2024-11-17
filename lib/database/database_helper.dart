import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('money_management.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE categories(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      isExpense INTEGER NOT NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE transactions(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      amount REAL NOT NULL,
      description TEXT,
      categoryId INTEGER,
      date TEXT NOT NULL,
      isExpense INTEGER NOT NULL,
      FOREIGN KEY (categoryId) REFERENCES categories(id)
    )
    ''');
  }

  Future<int> createCategory(String name, bool isExpense) async {
    final db = await instance.database;
    final data = {'name': name, 'isExpense': isExpense ? 1 : 0};
    return await db.insert('categories', data);
  }

  Future<List<Map<String, dynamic>>> getCategories(bool isExpense) async {
    final db = await instance.database;
    return await db.query(
      'categories',
      where: 'isExpense = ?',
      whereArgs: [isExpense ? 1 : 0],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> createTransaction(double amount, String description,
      int categoryId, DateTime date, bool isExpense) async {
    final db = await instance.database;
    final data = {
      'amount': amount,
      'description': description,
      'categoryId': categoryId,
      'date': date.toIso8601String(),
      'isExpense': isExpense ? 1 : 0,
    };
    return await db.insert('transactions', data);
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    final db = await instance.database;
    return await db.rawQuery('''
    SELECT t.*, c.name as categoryName
    FROM transactions t
    LEFT JOIN categories c ON t.categoryId = c.id
    ORDER BY t.date DESC
    ''');
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>> getTransactionSummary(
      DateTime startDate, DateTime endDate) async {
    final db = await instance.database;

    // Tổng thu nhập
    final incomeResult = await db.rawQuery('''
    SELECT COALESCE(SUM(amount), 0) as total 
    FROM transactions 
    WHERE isExpense = 0 
    AND date BETWEEN ? AND ?
  ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    // Tổng chi tiêu
    final expenseResult = await db.rawQuery('''
    SELECT COALESCE(SUM(amount), 0) as total 
    FROM transactions 
    WHERE isExpense = 1 
    AND date BETWEEN ? AND ?
  ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    // Chi tiêu theo danh mục
    final categorizedExpenses = await db.rawQuery('''
    SELECT c.name as categoryName, 
           COALESCE(SUM(t.amount), 0) as total 
    FROM transactions t
    JOIN categories c ON t.categoryId = c.id
    WHERE t.isExpense = 1 
    AND t.date BETWEEN ? AND ?
    GROUP BY c.name
    ORDER BY total DESC
  ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    return {
      'totalIncome': (incomeResult[0]['total'] as num).toDouble(),
      'totalExpense': (expenseResult[0]['total'] as num).toDouble(),
      'netBalance': ((incomeResult[0]['total'] as num).toDouble()) -
          ((expenseResult[0]['total'] as num).toDouble()),
      'categorizedExpenses': categorizedExpenses
    };
  }

// Thống kê giao dịch theo tháng
  Future<List<Map<String, dynamic>>> getMonthlyTransactionSummary(
      int year) async {
    final db = await instance.database;

    return await db.rawQuery('''
    SELECT 
      strftime('%m', date) as month,
      COALESCE(SUM(CASE WHEN isExpense = 0 THEN amount ELSE 0 END), 0) as income,
      COALESCE(SUM(CASE WHEN isExpense = 1 THEN amount ELSE 0 END), 0) as expense
    FROM transactions
    WHERE strftime('%Y', date) = ?
    GROUP BY month
    ORDER BY month
  ''', ['$year']);
  }

// Lấy giao dịch gần đây nhất
  Future<List<Map<String, dynamic>>> getRecentTransactions(int limit) async {
    final db = await instance.database;

    return await db.rawQuery('''
    SELECT t.*, c.name as categoryName
    FROM transactions t
    LEFT JOIN categories c ON t.categoryId = c.id
    ORDER BY t.date DESC
    LIMIT ?
  ''', [limit]);
  }

// Tìm danh mục có chi tiêu nhiều nhất
  Future<Map<String, dynamic>?> getTopExpenseCategory(
      DateTime startDate, DateTime endDate) async {
    final db = await instance.database;

    final result = await db.rawQuery('''
    SELECT c.name as categoryName, 
           COALESCE(SUM(t.amount), 0) as total 
    FROM transactions t
    JOIN categories c ON t.categoryId = c.id
    WHERE t.isExpense = 1 
    AND t.date BETWEEN ? AND ?
    GROUP BY c.name
    ORDER BY total DESC
    LIMIT 1
  ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    return result.isNotEmpty ? result.first : null;
  }
}
