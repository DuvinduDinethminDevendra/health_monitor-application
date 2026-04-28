import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../repositories/activity_repository.dart';
import '../repositories/goal_repository.dart';
import '../repositories/health_log_repository.dart';
import 'activity_screen.dart';
import 'health_log_screen.dart';
import 'goals_screen.dart';
import 'health_tips_screen.dart';
import 'charts_screen.dart';
import 'reminders_screen.dart';
import 'profile_screen.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';
import '../widgets/horizontal_week_calendar.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  int _totalActivities = 0;
  int _activeGoals = 0;
  double _latestBmi = 0;
  String _bmiCategory = 'N/A';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.isFirstTimeLogin) {
        authService.clearFirstTimeLogin();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
      }
    });
  }

  Future<void> _loadDashboardData() async {
    final userId =
        Provider.of<AuthService>(context, listen: false).currentUser?.id;
    if (userId == null) return;

    // Trigger Firebase Sync on every manual refresh
    await SyncService().syncData(userId);

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final activities = await ActivityRepository()
        .getActivitiesByDateRange(userId, dateStr, dateStr);
    final goals = await GoalRepository().getActiveGoals(userId);
    final latestLog = await HealthLogRepository().getLatestLog(userId);

    if (!mounted) return;

    setState(() {
      _totalActivities = activities.length;
      _activeGoals = goals.length;
      if (latestLog != null) {
        _latestBmi = latestLog.bmi;
        _bmiCategory = latestLog.bmiCategory;
      }
    });
  }

  void _showAddMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Quick Add',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAddOption(
                  'Activity',
                  Icons.directions_run_rounded,
                  AppTheme.emeraldGreen,
                  () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 1);
                  },
                ),
                _buildAddOption(
                  'Goal',
                  Icons.flag_rounded,
                  AppTheme.warmOrange,
                  () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 3);
                  },
                ),
                _buildAddOption(
                  'Health Log',
                  Icons.monitor_weight_rounded,
                  AppTheme.skyBlue,
                  () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 2);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOption(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final screens = [
      _buildDashboardHome(authService.currentUser?.name ?? 'User'),
      const ActivityScreen(),
      const HealthLogScreen(),
      const GoalsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: _currentIndex == 0 ? null : AppBar(
        title: Text(
          _currentIndex == 1 ? 'Activities' : _currentIndex == 2 ? 'Health Metrics' : 'My Goals',
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkCharcoal),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: screens[_currentIndex],
      floatingActionButton: _currentIndex == 0 ? null : Padding(
        padding: const EdgeInsets.only(bottom: 110),
        child: _buildScreenSpecificFAB(),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.dashboard_rounded, 'Dashboard'),
                  _buildNavItem(1, Icons.directions_run_rounded, 'Activities'),
                  GestureDetector(
                    onTap: _showAddMenu,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: AppTheme.emeraldGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x4D10B981),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      child:
                          const Icon(Icons.add, color: Colors.white, size: 28),
                    ),
                  ),
                  _buildNavItem(2, Icons.monitor_weight_rounded, 'Health'),
                  _buildNavItem(3, Icons.flag_rounded, 'Goals'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
        if (index == 0) _loadDashboardData();
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Icon(
          icon,
          color: isSelected ? AppTheme.emeraldGreen : AppTheme.mutedGrey,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildDashboardHome(String userName) {
    final authService = Provider.of<AuthService>(context, listen: false);
    return Column(
      children: [
        // Top Horizontal Calendar with Integrated Profile
        HorizontalWeekCalendar(
          selectedDate: _selectedDate,
          profilePicture: authService.currentUser?.profilePicture,
          onProfileTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ).then((_) => _loadDashboardData());
          },
          onDateSelected: (date) {
            setState(() {
              _selectedDate = date;
            });
            _loadDashboardData();
          },
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadDashboardData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 16, bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Central Circular Progress (DesignIdea1 style)
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, $userName!',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Your Daily Overview',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.darkCharcoal
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 140,
                                height: 140,
                                child: CircularProgressIndicator(
                                  value: _totalActivities > 0
                                      ? 0.75
                                      : 0.0, // Example progress
                                  backgroundColor:
                                      AppTheme.mutedGrey.withValues(alpha: 0.2),
                                  color: AppTheme.warmOrange,
                                  strokeWidth: 10,
                                  strokeCap: StrokeCap.round,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _totalActivities.toString(),
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.warmOrange,
                                    ),
                                  ),
                                  const Text(
                                    'Activities',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2x2 Grid Stats (DesignIdea1 style)
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Active Goals',
                          _activeGoals.toString(),
                          Icons.flag_rounded,
                          AppTheme.emeraldGreen,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'BMI',
                          _latestBmi > 0 ? _latestBmi.toString() : 'N/A',
                          Icons.monitor_weight_rounded,
                          AppTheme.skyBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Health Status',
                          _bmiCategory,
                          Icons.health_and_safety_rounded,
                          AppTheme.warmOrange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Health Tips',
                          'View',
                          Icons.lightbulb_rounded,
                          AppTheme.darkCharcoal,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const HealthTipsScreen())),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionBtn(
                          'Charts',
                          Icons.bar_chart_rounded,
                          AppTheme.skyBlue,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ChartsScreen())),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionBtn(
                          'Reminders',
                          Icons.notifications_active_rounded,
                          AppTheme.emeraldGreen,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RemindersScreen())),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        color: color.withValues(alpha: 0.05), // Subtle color tint
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.darkCharcoal.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionBtn(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 16),
        color: color.withValues(alpha: 0.1),
        borderRadius: 16,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildScreenSpecificFAB() {
    switch (_currentIndex) {
      case 1: // Activities
        return FloatingActionButton(
          heroTag: 'activity_fab',
          onPressed: () {
            // We need a way to trigger the ActivityScreen's add dialog
            // For now, we'll just show the same bottom sheet menu
            _showAddMenu();
          },
          backgroundColor: AppTheme.emeraldGreen,
          child: const Icon(Icons.add, color: Colors.white),
        );
      case 2: // Health
        return FloatingActionButton(
          heroTag: 'health_fab',
          onPressed: _showAddMenu,
          backgroundColor: AppTheme.skyBlue,
          child: const Icon(Icons.add, color: Colors.white),
        );
      case 3: // Goals
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton.small(
              heroTag: 'charts_fab_dashboard',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChartsScreen(initialIndex: 2)),
                );
              },
              backgroundColor: AppTheme.skyBlue,
              child: const Icon(Icons.show_chart, color: Colors.white),
            ),
            const SizedBox(width: 16),
            FloatingActionButton.extended(
              heroTag: 'add_goal_fab_dashboard',
              onPressed: _showAddMenu,
              backgroundColor: AppTheme.emeraldGreen,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Goal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
