import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/step_record.dart';

class StepRecordRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> upsertStepRecord(StepRecord record) async {
    final db = await _dbHelper.database;
    await db.insert(
      'step_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<StepRecord?> getStepRecordByDate(int userId, String date) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'step_records',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
    );

    if (maps.isNotEmpty) {
      return StepRecord.fromMap(maps.first);
    }
    return null;
  }

  Future<List<StepRecord>> getLast7DaysSteps(int userId) async {
    final db = await _dbHelper.database;
    
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));
    final formattedDate = '${sevenDaysAgo.year}-${sevenDaysAgo.month.toString().padLeft(2, '0')}-${sevenDaysAgo.day.toString().padLeft(2, '0')}';

    final maps = await db.query(
      'step_records',
      where: 'user_id = ? AND date >= ?',
      whereArgs: [userId, formattedDate],
      orderBy: 'date ASC',
    );

    final List<StepRecord> records = maps.map((map) => StepRecord.fromMap(map)).toList();
    
    final List<StepRecord> filledRecords = [];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      final existingRecord = records.where((r) => r.date == dateStr).toList();
      if (existingRecord.isNotEmpty) {
        filledRecords.add(existingRecord.first);
      } else {
        filledRecords.add(StepRecord(
          userId: userId,
          date: dateStr,
          stepCount: 0,
        ));
      }
    }

    return filledRecords;
  }

  Future<List<StepRecord>> getLast30DaysSteps(int userId) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 29));
    final formattedDate = '${thirtyDaysAgo.year}-${thirtyDaysAgo.month.toString().padLeft(2, '0')}-${thirtyDaysAgo.day.toString().padLeft(2, '0')}';

    final maps = await db.query(
      'step_records',
      where: 'user_id = ? AND date >= ?',
      whereArgs: [userId, formattedDate],
      orderBy: 'date ASC',
    );

    return maps.map((map) => StepRecord.fromMap(map)).toList();
  }

  Future<void> deleteStepRecord(int id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'step_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
