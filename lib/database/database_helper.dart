import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// Conditional imports
import 'database_helper_stub.dart'
    if (dart.library.html) 'database_helper_web.dart';

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
    String path;
    if (kIsWeb) {
      await initWebDatabase();
      path = 'health_monitor.db';
    } else {
      path = join(await getDatabasesPath(), 'health_monitor.db');
    }

    return await openDatabase(
      path,

      version: 10,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE reminders (
          id INTEGER PRIMARY KEY,
          title TEXT NOT NULL,
          body TEXT NOT NULL,
          hour INTEGER NOT NULL,
          minute INTEGER NOT NULL,
          is_enabled INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE favorite_tips (
          topic_id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          content TEXT NOT NULL,
          url TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE recent_tips (
          topic_id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          content TEXT NOT NULL,
          url TEXT NOT NULL,
          visited_at INTEGER NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE favorite_tips ADD COLUMN image_url TEXT');
      await db.execute('ALTER TABLE recent_tips ADD COLUMN image_url TEXT');
    }
    if (oldVersion < 5) {
      await db.execute("ALTER TABLE reminders ADD COLUMN alert_style TEXT NOT NULL DEFAULT 'banner'");
      await db.execute("ALTER TABLE reminders ADD COLUMN repeat_days TEXT NOT NULL DEFAULT '1111111'");
      await db.execute('ALTER TABLE reminders ADD COLUMN vibration INTEGER NOT NULL DEFAULT 1');
      await db.execute("ALTER TABLE reminders ADD COLUMN sound_name TEXT NOT NULL DEFAULT 'default'");
    }
    if (oldVersion < 8) {
      await db.execute('ALTER TABLE health_logs ADD COLUMN tags TEXT');
      await db.execute('ALTER TABLE health_logs ADD COLUMN notes TEXT');
    }
    if (oldVersion < 9) {
      await db.execute("ALTER TABLE health_logs ADD COLUMN unit TEXT NOT NULL DEFAULT 'metric'");
      await db.execute('ALTER TABLE health_logs ADD COLUMN waist REAL');
      await db.execute('ALTER TABLE health_logs ADD COLUMN hip REAL');
      await db.execute('ALTER TABLE health_logs ADD COLUMN chest REAL');
      await db.execute('ALTER TABLE health_logs ADD COLUMN body_fat REAL');
    }
    if (oldVersion < 10) {
      await db.execute("ALTER TABLE reminders ADD COLUMN times TEXT NOT NULL DEFAULT '[]'");
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        name TEXT,
        email TEXT,
        password TEXT,
        created_at TEXT,
        age INTEGER,
        gender TEXT,
        height REAL,
        weight REAL,
        profile_picture TEXT,
        interests TEXT,
        is_dark_mode INTEGER DEFAULT 0,
        sync_status INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE goals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        title TEXT,
        category TEXT,
        target_value REAL,
        current_value REAL,
        unit TEXT,
        deadline TEXT,
        reminder_time TEXT,
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
        tags TEXT,
        notes TEXT,
        unit TEXT NOT NULL DEFAULT 'metric',
        waist REAL,
        hip REAL,
        chest REAL,
        body_fat REAL,
        sync_status INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        times TEXT NOT NULL DEFAULT '[]',
        is_enabled INTEGER NOT NULL DEFAULT 0,
        alert_style TEXT NOT NULL DEFAULT 'banner',
        repeat_days TEXT NOT NULL DEFAULT '1111111',
        vibration INTEGER NOT NULL DEFAULT 1,
        sound_name TEXT NOT NULL DEFAULT 'default'
      )
    ''');

    await db.execute('''
      CREATE TABLE favorite_tips (
        topic_id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        content TEXT NOT NULL,
        url TEXT NOT NULL,
        image_url TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE recent_tips (
        topic_id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        content TEXT NOT NULL,
        url TEXT NOT NULL,
        visited_at INTEGER NOT NULL,
        image_url TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE step_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        date TEXT,
        step_count INTEGER,
        goal INTEGER,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE workout_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        workout_type TEXT,
        duration_mins INTEGER,
        calories_burned INTEGER,
        logged_at TEXT,
        notes TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }



  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
