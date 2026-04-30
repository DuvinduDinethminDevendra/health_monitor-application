import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/activity_provider.dart';

class PedometerService {
  StreamSubscription<StepCount>? _stepCountStream;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusStream;
  bool _isListening = false;
  int? _initialStepOffset;

  Future<void> startListening(ActivityProvider provider, String userId) async {
    if (_isListening) return;

    var permission = await Permission.activityRecognition.status;
    if (permission.isDenied) {
      permission = await Permission.activityRecognition.request();
    }
    
    if (permission.isPermanentlyDenied) {
      provider.setError('Physical activity permission restricted. Open settings to enable.');
      await openAppSettings();
      return;
    }
    
    if (!permission.isGranted) {
      provider.setError('Physical activity permission denied.');
      return;
    }

    _isListening = true;
    _initialStepOffset = null;

    try {
      _stepCountStream = Pedometer.stepCountStream.listen(
        (StepCount event) {
          if (_initialStepOffset == null) {
            _initialStepOffset = event.steps - provider.liveStepCount;
          }
          final int adjustedSteps = event.steps - _initialStepOffset!;
          
          if (adjustedSteps >= 0) {
            provider.updateLiveSteps(adjustedSteps, userId);
          } else {
            // Device rebooted, reset offset
            _initialStepOffset = event.steps - provider.liveStepCount;
            provider.updateLiveSteps(provider.liveStepCount, userId);
          }
        },
        onError: (error) {
          provider.setError('Step counter unavailable on this device');
        },
        cancelOnError: true,
      );

      _pedestrianStatusStream = Pedometer.pedestrianStatusStream.listen(
        (PedestrianStatus event) {
          // Status updates could be handled if needed, e.g. "walking" or "stopped"
        },
        onError: (error) {
          // Ignore status errors, less critical than step count
        },
      );
    } catch (e) {
      _isListening = false;
      provider.setError('Failed to initialize step counter');
    }
  }

  void stop() {
    _stepCountStream?.cancel();
    _pedestrianStatusStream?.cancel();
    _isListening = false;
  }
}
