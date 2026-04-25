import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// Conditional imports
import 'database_helper_stub.dart'
    if (dart.library.html) 'database_helper_web.dart';

import '../models/user.dart';
import '../models/goal.dart';
import '../models/activity.dart';
import '../models/health_log.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      await initWebDatabase();
    }

    String path = join(await getDatabasesPath(), 'health_monitor.db');
    
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        name TEXT,
        email TEXT,
        createdAt TEXT,
        sync_status INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE goals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        title TEXT,
        target_value REAL,
        current_value REAL,
        unit TEXT,
        deadline TEXT,
        is_completed INTEGER DEFAULT 0,
        sync_status INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE activities(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        type TEXT,
        value REAL,
        date TEXT,
        duration INTEGER,
        sync_status INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE health_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        weight REAL,
        height REAL,
        bmi REAL,
        date TEXT,
        sync_status INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {}

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
