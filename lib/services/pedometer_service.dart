import 'dart:async';
import 'package:pedometer/pedometer.dart';
import '../providers/activity_provider.dart';

class PedometerService {
  StreamSubscription<StepCount>? _stepCountStream;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusStream;

  void startListening(ActivityProvider provider, String userId) {
    try {
      _stepCountStream = Pedometer.stepCountStream.listen(
        (StepCount event) {
          provider.updateLiveSteps(event.steps, userId);
        },
        onError: (error) {
          provider.setError('Step counter unavailable on this device');
        },
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
      provider.setError('Failed to initialize step counter');
    }
  }

  void stop() {
    _stepCountStream?.cancel();
    _pedestrianStatusStream?.cancel();
  }
}
