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

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE mood_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        emotion TEXT NOT NULL,
        cause TEXT NOT NULL,
        note TEXT,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertMood(String emotion, String cause, {String note = ''}) async {
    final db = await instance.database;
    return await db.insert('mood_log', {
      'emotion': emotion,
      'cause': cause,
      'note': note,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // ─── TODAY ──────────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getDailyMoods() async {
    final db = await instance.database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return await db.query(
      'mood_log',
      where: 'timestamp >= ?',
      whereArgs: [start.toIso8601String()],
      orderBy: 'timestamp DESC',
    );
  }

  // ─── THIS WEEK (Monday–Sunday) ───────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getWeeklyMoods() async {
    final db = await instance.database;
    final now = DateTime.now();
    final monday = _getMondayOfWeek(now);
    final sunday = monday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    return await db.query(
      'mood_log',
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [monday.toIso8601String(), sunday.toIso8601String()],
      orderBy: 'timestamp DESC',
    );
  }

  // ─── LAST WEEK (Mon–Sun) for trend comparison ────────────────────────────
  Future<List<Map<String, dynamic>>> getLastWeekMoods() async {
    final db = await instance.database;
    final now = DateTime.now();
    final thisMonday = _getMondayOfWeek(now);
    final lastMonday = thisMonday.subtract(const Duration(days: 7));
    final lastSunday = thisMonday.subtract(const Duration(seconds: 1));
    return await db.query(
      'mood_log',
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [lastMonday.toIso8601String(), lastSunday.toIso8601String()],
      orderBy: 'timestamp DESC',
    );
  }

  // ─── HELPER ──────────────────────────────────────────────────────────────
  DateTime _getMondayOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - DateTime.monday;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
