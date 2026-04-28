import 'package:flutter/material.dart';
import '../services/health_tips_service.dart';
import '../theme/app_theme.dart';

class HealthTipsScreen extends StatefulWidget {
  const HealthTipsScreen({super.key});

  @override
  State<HealthTipsScreen> createState() => _HealthTipsScreenState();
}

class _HealthTipsScreenState extends State<HealthTipsScreen> {
  final HealthTipsService _tipsService = HealthTipsService();
  List<HealthTip> _tips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTips();
  }

  Future<void> _loadTips() async {
    setState(() => _isLoading = true);
    final tips = await _tipsService.fetchHealthTips();
    if (!mounted) return;
    setState(() {
      _tips = tips;
      _isLoading = false;
    });
  }

  final List<Color> _cardColors = const [
    Color(0xFF1A73E8),
    Color(0xFF00BFA5),
    Color(0xFFFB8C00),
    Color(0xFFE53935),
    Color(0xFFAB47BC),
    Color(0xFF42A5F5),
    Color(0xFF26A69A),
    Color(0xFFFFA726),
  ];

  final List<IconData> _tipIcons = const [
    Icons.water_drop,
    Icons.bedtime,
    Icons.fitness_center,
    Icons.restaurant,
    Icons.spa,
    Icons.medical_services,
    Icons.visibility,
    Icons.accessibility_new,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Health Insights', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.darkCharcoal,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTips,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _tips.length,
                itemBuilder: (context, index) {
                  final tip = _tips[index];
                  final color = _cardColors[index % _cardColors.length];
                  final icon = _tipIcons[index % _tipIcons.length];

                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return MatteCard(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: EdgeInsets.zero,
                    color: isDark ? const Color(0xFF0A2A3F) : Colors.white,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => _showTipDetail(tip, color),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: color, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tip.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      color: isDark ? Colors.white : AppTheme.sapphire,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    tip.description,
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? Colors.white60 : AppTheme.heather),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 14, color: color.withValues(alpha: 0.4)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  void _showTipDetail(HealthTip tip, Color color) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tip.description,
                  style: TextStyle(color: color, fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                tip.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                tip.content.isNotEmpty
                    ? tip.content
                    : 'Follow this health tip to improve your overall wellness and maintain a healthy lifestyle.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
