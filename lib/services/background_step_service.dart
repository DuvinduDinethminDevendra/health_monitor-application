import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../repositories/step_record_repository.dart';
import '../models/step_record.dart';

Future<void> initBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onServiceStart,
      autoStart: true,
      isForegroundMode: false,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onServiceStart,
      onBackground: (ServiceInstance service) {
        return true;
      },
    ),
  );
  
  await service.startService();
}

@pragma('vm:entry-point')
void onServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  
  Timer.periodic(const Duration(minutes: 15), (timer) async {
    final now = DateTime.now();
    
    // Check if it's midnight (between 00:00 and 00:14)
    if (now.hour == 0 && now.minute < 15) {
      final prefs = await SharedPreferences.getInstance();
      
      const kStepCacheDate = 'activity_step_cache_date';
      const kStepCacheCount = 'activity_step_cache_count';
      
      final cachedDate = prefs.getString(kStepCacheDate);
      final cachedSteps = prefs.getInt(kStepCacheCount) ?? 0;
      
      if (cachedDate != null && cachedSteps > 0) {
        final stepRepo = StepRecordRepository();
        
        final userId = prefs.getString('active_user_id') ?? '1'; 

        final record = StepRecord(
          userId: userId,
          date: cachedDate,
          stepCount: cachedSteps,
        );
        
        await stepRepo.upsertStepRecord(record);
        
        // Reset cache for the new day
        final today = DateFormat('yyyy-MM-dd').format(now);
        await prefs.setString(kStepCacheDate, today);
        await prefs.setInt(kStepCacheCount, 0);
      }
    }
  });
}
