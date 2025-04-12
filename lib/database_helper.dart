import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Ensure sqflite_sw.js is properly set up for web:
// Follow the documentation: https://github.com/tekartik/sqflite/tree/master/packages_web/sqflite_common_ffi_web#setup-binaries

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 3, onCreate: _createTables, onUpgrade: _upgradeDB);
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        password TEXT NOT NULL,
        image_path TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE location_notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT,
        description TEXT,
        date TEXT,
        image_path TEXT
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
      ALTER TABLE location_notes ADD COLUMN timestamp TEXT
      ''');
      await db.execute('''
      ALTER TABLE location_notes ADD COLUMN address TEXT
      ''');
      await db.execute('''
      ALTER TABLE location_notes ADD COLUMN image_path TEXT
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
      ALTER TABLE users ADD COLUMN email TEXT
      ''');
    }
    // Add more migrations as needed
  }

  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await instance.database;
    return await db.insert('users', user);
  }

  Future<int> insertLocationNote(Map<String, dynamic> note) async {
    final db = await instance.database;
    return await db.insert('location_notes', note);
  }

  Future<List<Map<String, dynamic>>> getLocationNotes() async {
    final db = await instance.database;
    return await db.query('location_notes');
  }

  Future<int> updateLocationNote(Map<String, dynamic> note) async {
    final db = await instance.database;
    final int id = note['id'];
    return await db.update(
      'location_notes',
      note,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteLocationNote(int id) async {
    final db = await instance.database;
    return await db.delete(
      'location_notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>?> authenticateUser(String name, String password) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'name = ? AND password = ?',
      whereArgs: [name, password],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> authenticateUserByCredential(String credential, String password) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: '(name = ? OR email = ?) AND password = ?',
      whereArgs: [credential, credential, password],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateUser(Map<String, dynamic> user) async {
    final db = await instance.database;
    return await db.update(
      'users',
      user,
      where: 'name = ?',
      whereArgs: [user['name']],
    );
  }

  Future<int> deleteUser(String name) async {
    final db = await instance.database;
    return await db.delete(
      'users',
      where: 'name = ?',
      whereArgs: [name],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
