import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/activity_provider.dart';

class PedometerService {
  StreamSubscription<StepCount>? _stepCountStream;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusStream;
  bool _isListening = false;
  int? _initialStepOffset;
  int _mockSteps = 0;

  void addManualSteps(int steps) {
    if (kIsWeb) {
      _mockSteps += steps;
    } else if (_initialStepOffset != null) {
      _initialStepOffset = _initialStepOffset! - steps;
    }
  }

  Future<void> startListening(ActivityProvider provider, String userId) async {
    if (_isListening) return;

    if (kIsWeb) {
      _isListening = true;
      _initialStepOffset = 0;
      _mockSteps = provider.liveStepCount; // Initialize with current live steps

      // MOCK MODE: Use a Timer to generate fake steps every 5 seconds
      Timer.periodic(const Duration(seconds: 5), (timer) {
        if (!_isListening) {
          timer.cancel();
          return;
        }
        _mockSteps += 1;
        provider.updateLiveSteps(_mockSteps, userId);
      });
      return;
    }

    var permission = await Permission.activityRecognition.status;
    if (permission.isDenied) {
      permission = await Permission.activityRecognition.request();
    }

    if (permission.isPermanentlyDenied) {
      provider.setError(
          'Physical activity permission restricted. Open settings to enable.');
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
          _initialStepOffset ??= event.steps - provider.liveStepCount;
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
