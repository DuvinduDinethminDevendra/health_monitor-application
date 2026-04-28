import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../theme/app_theme.dart';

class HorizontalWeekCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback? onProfileTap;
  final String? profilePicture;
  final String userName;

  const HorizontalWeekCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.userName,
    this.onProfileTap,
    this.profilePicture,
  });

  @override
  State<HorizontalWeekCalendar> createState() => _HorizontalWeekCalendarState();
}

class _HorizontalWeekCalendarState extends State<HorizontalWeekCalendar> {
  late ScrollController _scrollController;
  late DateTime _startDate;
  final int _dayCount = 30;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _startDate = DateTime.now().subtract(const Duration(days: 15));
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate();
    });
  }

  void _scrollToSelectedDate() {
    if (!_scrollController.hasClients) return;
    final int difference = widget.selectedDate.difference(_startDate).inDays;
    final double offset = (difference * 68.0) - (MediaQuery.of(context).size.width / 2) + 34;
    _scrollController.animateTo(
      offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(HorizontalWeekCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _scrollToSelectedDate();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _selectFullDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.emeraldGreen,
              onPrimary: Colors.white,
              onSurface: AppTheme.darkCharcoal,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != widget.selectedDate) {
      widget.onDateSelected(picked);
      setState(() {
        _startDate = picked.subtract(const Duration(days: 15));
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelectedDate());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCharcoal.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${widget.userName}',
                        style: TextStyle(
                          color: AppTheme.emeraldGreen.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      GestureDetector(
                        onTap: _selectFullDate,
                        child: Row(
                          children: [
                            Text(
                              DateFormat('MMMM, yyyy').format(widget.selectedDate),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: widget.onProfileTap,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.emeraldGreen, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white10,
                        backgroundImage: (widget.profilePicture != null && widget.profilePicture!.isNotEmpty)
                            ? MemoryImage(base64Decode(widget.profilePicture!))
                            : null,
                        child: (widget.profilePicture == null || widget.profilePicture!.isEmpty)
                            ? const Icon(Icons.person, color: Colors.white, size: 18)
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height: 55,
                child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: _dayCount,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final date = _startDate.add(Duration(days: index));
                  final isSelected = date.year == widget.selectedDate.year &&
                                     date.month == widget.selectedDate.month &&
                                     date.day == widget.selectedDate.day;

                  return GestureDetector(
                    onTap: () => widget.onDateSelected(date),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 50,
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.emeraldGreen : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: AppTheme.emeraldGreen.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ] : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('E').format(date).substring(0, 1),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            date.day.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
