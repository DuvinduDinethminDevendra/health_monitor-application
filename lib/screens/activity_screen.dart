import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import '../providers/activity_provider.dart';
import '../models/workout_record.dart';
import '../widgets/step_progress_ring.dart';
import '../widgets/weekly_steps_chart.dart';
import '../services/auth_service.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Activity Tracker'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _showGoalDialog(context),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Steps'),
              Tab(text: 'Workouts'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _StepsTab(),
            _WorkoutsTab(),
          ],
        ),
      ),
    );
  }

  void _showGoalDialog(BuildContext context) {
    final provider = Provider.of<ActivityProvider>(context, listen: false);
    final controller = TextEditingController(text: provider.dailyStepGoal.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Daily Step Goal'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Steps'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newGoal = int.tryParse(controller.text);
              if (newGoal != null && newGoal > 0) {
                provider.setGoal(newGoal);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _StepsTab extends StatelessWidget {
  const _StepsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final caloriesBurned = (provider.liveStepCount * 0.04).toInt();

        return SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),
              _HeroCard(
                currentSteps: provider.liveStepCount,
                dailyGoal: provider.dailyStepGoal,
                caloriesBurned: caloriesBurned,
              ),
              const SizedBox(height: 16),
              const _StatisticsCard(),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => _showManualStepDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Steps Manually (Emulator Debug)'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showManualStepDialog(BuildContext context) {
    final provider = Provider.of<ActivityProvider>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.id ?? 1;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Manual Step Entry'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Total Steps Today'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final steps = int.tryParse(controller.text);
              if (steps != null && steps >= 0) {
                provider.updateLiveSteps(steps, userId);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final int currentSteps;
  final int dailyGoal;
  final int caloriesBurned;

  const _HeroCard({
    required this.currentSteps,
    required this.dailyGoal,
    required this.caloriesBurned,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = (currentSteps / dailyGoal).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Text
          Text.rich(
            TextSpan(
              text: 'You have walked ',
              style: const TextStyle(fontSize: 18, color: Colors.black87),
              children: [
                TextSpan(
                  text: '$currentSteps',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurpleAccent,
                  ),
                ),
                const TextSpan(text: ' steps today'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Semi-circular Progress Ring
          SizedBox(
            height: 180, // Height is half of the width to make a perfect semi-circle
            width: 250,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                CustomPaint(
                  size: const Size(250, 180),
                  painter: _SemiCircleProgressPainter(progress: progress),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.directions_run_rounded, size: 36, color: Colors.green.shade600),
                    const SizedBox(height: 8),
                    Text(
                      '$currentSteps',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Steps',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Secondary Stats
          Row(
            children: [
              Expanded(
                child: _StatColumn(
                  label: 'Cal Burned',
                  value: '$caloriesBurned Cal',
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.grey.shade300,
              ),
              Expanded(
                child: _StatColumn(
                  label: 'Daily Goal',
                  value: '${(dailyGoal / 1000).toStringAsFixed(0)}k Step',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SemiCircleProgressPainter extends CustomPainter {
  final double progress;

  _SemiCircleProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(size.width / 2, size.height); // Bottom center
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    const double strokeWidth = 18.0;
    
    // Background Dashed Track
    final Paint trackPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final int dashCount = 35;
    final double dashAngle = math.pi / (dashCount * 2);
    
    for (int i = 0; i < dashCount * 2; i += 2) {
      canvas.drawArc(rect, math.pi + i * dashAngle, dashAngle, false, trackPaint);
    }

    // Foreground Solid Progress Arc
    final Paint progressPaint = Paint()
      ..color = Colors.green.shade500
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, math.pi, math.pi * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _SemiCircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _StatisticsCard extends StatelessWidget {
  const _StatisticsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey.shade800),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Hourly Bar Chart
          SizedBox(
            height: 200,
            child: _HourlyBarChart(),
          ),
        ],
      ),
    );
  }
}

class _HourlyBarChart extends StatelessWidget {
  // Mock data for the last 12 hours (e.g. 6am to 6pm)
  final List<double> hourlySteps = [
    200, 500, 1200, 800, 300, 2500, 1800, 600, 400, 900, 1100, 350, 150
  ];

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 3000,
        minY: 0,
        gridData: FlGridData(show: false), // No grid lines
        borderData: FlBorderData(show: false), // No borders
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: _bottomTitles,
              reservedSize: 42,
            ),
          ),
        ),
        barGroups: List.generate(
          hourlySteps.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: hourlySteps[index],
                color: Colors.deepPurpleAccent.withOpacity(0.8),
                width: 12,
                borderRadius: BorderRadius.circular(6),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 3000,
                  color: Colors.grey.shade100,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 10);
    Widget text;
    IconData? icon;

    switch (value.toInt()) {
      case 0:
        text = const Text('6AM', style: style);
        icon = Icons.wb_sunny_outlined;
        break;
      case 6:
        text = const Text('12PM', style: style);
        icon = Icons.wb_sunny;
        break;
      case 12:
        text = const Text('6PM', style: style);
        icon = Icons.nightlight_round;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(height: 4),
          text,
        ],
      ),
    );
  }
}

class _WorkoutsTab extends StatelessWidget {
  const _WorkoutsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              width: double.infinity,
              child: Text(
                '${provider.todaysWorkouts.length} workouts · ${provider.totalWorkoutMinutesToday} min today',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.allWorkouts.length,
                itemBuilder: (context, index) {
                  final workout = provider.allWorkouts[index];
                  return Dismissible(
                    key: Key(workout.id.toString()),
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) {
                      provider.deleteWorkout(workout.id!, workout.userId);
                    },
                    child: Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.shade100,
                          child: Icon(Icons.fitness_center, color: Colors.red.shade700),
                        ),
                        title: Text('${workout.workoutType} • ${workout.durationMins} min'),
                        subtitle: Text('${workout.caloriesBurned ?? 0} kcal · ${workout.loggedAt.split('T')[0]}'),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FloatingActionButton.extended(
                onPressed: () => _showWorkoutBottomSheet(context),
                icon: const Icon(Icons.add),
                label: const Text('Log Workout'),
                backgroundColor: const Color(0xFF1A73E8),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showWorkoutBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _WorkoutForm(),
    );
  }
}

class _WorkoutForm extends StatefulWidget {
  const _WorkoutForm();

  @override
  State<_WorkoutForm> createState() => _WorkoutFormState();
}

class _WorkoutFormState extends State<_WorkoutForm> {
  final _formKey = GlobalKey<FormState>();
  String _workoutType = 'Running';
  double _durationMins = 30;
  final _notesController = TextEditingController();

  final Map<String, int> caloriesPerMin = {
    'Running': 10,
    'Cycling': 8,
    'Swimming': 9,
    'Yoga': 4,
    'Gym / Weights': 7,
    'Walking': 5,
    'Other': 5
  };

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estCalories = (_durationMins * caloriesPerMin[_workoutType]!).toInt();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Log Workout', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _workoutType,
              decoration: const InputDecoration(labelText: 'Workout Type'),
              items: caloriesPerMin.keys.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _workoutType = val);
              },
            ),
            const SizedBox(height: 24),
            Text('Duration: ${_durationMins.toInt()} min'),
            Slider(
              value: _durationMins,
              min: 1,
              max: 120,
              divisions: 119,
              onChanged: (val) => setState(() => _durationMins = val),
            ),
            const SizedBox(height: 8),
            Text('Estimated Calories: $estCalories kcal', style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLength: 200,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final provider = Provider.of<ActivityProvider>(context, listen: false);
                    final authService = Provider.of<AuthService>(context, listen: false);
                    final userId = authService.currentUser?.id ?? 1;
                    
                    final workout = WorkoutRecord(
                      userId: userId,
                      workoutType: _workoutType,
                      durationMins: _durationMins.toInt(),
                      caloriesBurned: estCalories,
                      loggedAt: DateTime.now().toIso8601String(),
                      notes: _notesController.text,
                    );
                    
                    provider.addWorkout(workout);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
