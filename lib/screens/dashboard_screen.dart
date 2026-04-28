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
import 'package:fl_chart/fl_chart.dart';
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
  int _touchedIndex = -1;

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
      const ChartsScreen(initialIndex: 0),
      const GoalsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.dashboard_rounded, 'Home'),
                  _buildNavItem(1, Icons.directions_run_rounded, 'Activity'),
                  _buildAddButton(),
                  _buildNavItem(2, Icons.bar_chart_rounded, 'Progress'),
                  _buildNavItem(3, Icons.flag_rounded, 'Goals'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _showAddMenu,
      child: Container(
        width: 48,
        height: 48,
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
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
    );
  }

  final ScrollController _scrollController = ScrollController();

  void _onItemTapped(int index) {
    if (index == _currentIndex) {
      // If home is already selected and tapped again, reset the view
      if (index == 0 && _scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOutBack);
      }
    }
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        _onItemTapped(index);
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
          userName: userName,
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
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 16, bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Central Progress (DesignIdea1 style - Multi-Metric)
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
                                const Text(
                                  'Daily Progress',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1,
                                    color: AppTheme.darkCharcoal,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Your health at a glance',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.darkCharcoal.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.emeraldGreen.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.bolt_rounded, color: AppTheme.emeraldGreen, size: 22),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          height: 200,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              PieChart(
                                PieChartData(
                                  pieTouchData: PieTouchData(
                                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                      setState(() {
                                        if (!event.isInterestedForInteractions ||
                                            pieTouchResponse == null ||
                                            pieTouchResponse.touchedSection == null) {
                                          _touchedIndex = -1;
                                          return;
                                        }
                                        _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                      });
                                    },
                                  ),
                                  sectionsSpace: 0,
                                  centerSpaceRadius: 70,
                                  startDegreeOffset: -90,
                                  sections: [
                                    PieChartSectionData(
                                      value: 70,
                                      color: AppTheme.emeraldGreen,
                                      radius: _touchedIndex == 0 ? 30 : 20,
                                      showTitle: false,
                                      badgeWidget: _buildPieBadge(Icons.directions_run_rounded, AppTheme.emeraldGreen),
                                      badgePositionPercentageOffset: 1,
                                    ),
                                    PieChartSectionData(
                                      value: 15,
                                      color: AppTheme.warmOrange,
                                      radius: _touchedIndex == 1 ? 25 : 16,
                                      showTitle: false,
                                    ),
                                    PieChartSectionData(
                                      value: 15,
                                      color: AppTheme.skyBlue,
                                      radius: _touchedIndex == 2 ? 22 : 12,
                                      showTitle: false,
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _touchedIndex == 1 ? _activeGoals.toString() : (_touchedIndex == 2 ? 'Optimal' : '8,432'),
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.darkCharcoal,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  Text(
                                    _touchedIndex == 1 ? 'ACTIVE GOALS' : (_touchedIndex == 2 ? 'HEALTH STATE' : 'STEPS TODAY'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.darkCharcoal.withValues(alpha: 0.4),
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMiniLegend('Activity', AppTheme.emeraldGreen),
                            _buildMiniLegend('Goals', AppTheme.warmOrange),
                            _buildMiniLegend('Health', AppTheme.skyBlue),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2x2 Grid Stats (Premium Style)
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Active Goals',
                          _activeGoals.toString(),
                          Icons.insights_rounded,
                          AppTheme.emeraldGreen,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Current BMI',
                          _latestBmi > 0 ? _latestBmi.toString() : '22.4',
                          Icons.speed_rounded,
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
                          'Health State',
                          _bmiCategory != 'N/A' ? _bmiCategory : 'Optimal',
                          Icons.favorite_rounded,
                          AppTheme.warmOrange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Health Tips',
                          'Explore',
                          Icons.auto_awesome_rounded,
                          AppTheme.darkCharcoal,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const HealthTipsScreen())),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.darkCharcoal),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionBtn(
                          'Health Logs',
                          Icons.assignment_rounded,
                          AppTheme.skyBlue,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const HealthLogScreen())),
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
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.25),
              color.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: color.withValues(alpha: 0.3), size: 14),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkCharcoal,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkCharcoal.withValues(alpha: 0.5)),
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

  Widget _buildPieBadge(IconData icon, Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }

  Widget _buildMiniLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.darkCharcoal.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
