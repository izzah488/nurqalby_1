import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class MoodDatabase {
  static final MoodDatabase instance = MoodDatabase._init();
  static Database? _database;

  MoodDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mood_log.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE mood_log (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        emotion   TEXT    NOT NULL,
        cause     TEXT,
        note      TEXT,
        timestamp TEXT    NOT NULL
      )
    ''');
  }

  // Save a new mood entry
  Future<void> insertMood({
    required String emotion,
    String? cause,
    String? note,
  }) async {
    final db = await instance.database;
    await db.insert('mood_log', {
      'emotion':   emotion,
      'cause':     cause ?? '',
      'note':      note ?? '',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Get all entries (newest first)
  Future<List<Map<String, dynamic>>> getAllMoods() async {
    final db = await instance.database;
    return await db.query('mood_log', orderBy: 'timestamp DESC');
  }

  // Get last 7 days (for Week view)
  Future<List<Map<String, dynamic>>> getWeeklyMoods() async {
    final db = await instance.database;
    final since = DateTime.now()
        .subtract(const Duration(days: 7))
        .toIso8601String();
    return await db.query(
      'mood_log',
      where: 'timestamp >= ?',
      whereArgs: [since],
      orderBy: 'timestamp DESC',
    );
  }

  // Get today only (for Day view)
  Future<List<Map<String, dynamic>>> getDailyMoods() async {
    final db = await instance.database;
    final now = DateTime.now();
    // Start of today at 00:00:00
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
    return await db.query(
      'mood_log',
      where: 'timestamp >= ?',
      whereArgs: [startOfDay],
      orderBy: 'timestamp DESC',
    );
  }
}
