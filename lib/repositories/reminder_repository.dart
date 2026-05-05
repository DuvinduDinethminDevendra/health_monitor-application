import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/reminder.dart';

class ReminderRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insertReminder(Reminder reminder) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'reminders',
      reminder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Reminder>> getReminders() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('reminders');
    return maps.map((map) => Reminder.fromMap(map)).toList();
  }

  Future<int> updateReminder(Reminder reminder) async {
    final db = await _dbHelper.database;
    return await db.update(
      'reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<int> deleteReminder(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'reminders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Reminder>> getRemindersByGoalId(String goalId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reminders',
      where: 'linked_goal_id = ?',
      whereArgs: [goalId],
    );
    return maps.map((map) => Reminder.fromMap(map)).toList();
  }
}
