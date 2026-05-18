import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('luxury_pos.db');
    await _ensureColumnsExist(_database!);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3, // Incremented version to apply upgrade
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE products (
  id $idType,
  name $textType,
  barcode $textType,
  price $realType,
  cost $realType,
  stock $intType,
  category $textType,
  notes TEXT
)
''');

    await db.execute('''
CREATE TABLE formulas (
  id $idType,
  name $textType,
  recipe $textType,
  notes $textType
)
''');

    await db.execute('''
CREATE TABLE sales (
  id $idType,
  product_id $intType,
  product_name $textType,
  ml_sold $realType,
  price $realType,
  date $textType
)
''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE products ADD COLUMN notes TEXT;');
      } catch (e) {
        // ignore if already exists
      }
    }
    if (oldVersion < 3) {
      try {
        await db.execute('''
        CREATE TABLE IF NOT EXISTS sales (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id INTEGER NOT NULL,
          product_name TEXT NOT NULL,
          ml_sold REAL NOT NULL,
          price REAL NOT NULL,
          date TEXT NOT NULL
        )
        ''');
      } catch (e) {
        // ignore
      }
    }
  }

  Future<void> _ensureColumnsExist(Database db) async {
    try {
      await db.execute('ALTER TABLE products ADD COLUMN notes TEXT;');
    } catch (e) {
      // Column already exists or table doesn't exist yet, ignore
    }
    try {
      await db.execute('''
      CREATE TABLE IF NOT EXISTS sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        ml_sold REAL NOT NULL,
        price REAL NOT NULL,
        date TEXT NOT NULL
      )
      ''');
    } catch (e) {
      // Ignore
    }
  }

  Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'luxury_pos.db');
  }

  Future<void> closeDb() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<void> importDatabaseFromFile(String sourcePath) async {
    await closeDb();
    final dbPath = await getDatabasePath();
    final sourceFile = File(sourcePath);
    if (await sourceFile.exists()) {
      // Overwrite the existing local database
      await sourceFile.copy(dbPath);
      // Re-initialize database
      _database = await _initDB('luxury_pos.db');
      await _ensureColumnsExist(_database!);
    } else {
      throw Exception('Source database file not found');
    }
  }

  Future<void> close() async {
    await closeDb();
  }
}
