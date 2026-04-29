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
  ImageProvider? _cachedImage;
  String? _lastProfilePicture;

  ImageProvider? _getProfileImage() {
    if (widget.profilePicture == null || widget.profilePicture!.isEmpty) {
      _cachedImage = null;
      _lastProfilePicture = null;
      return null;
    }
    if (widget.profilePicture != _lastProfilePicture) {
      _lastProfilePicture = widget.profilePicture;
      _cachedImage = MemoryImage(base64Decode(widget.profilePicture!));
    }
    return _cachedImage;
  }

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
    if (!mounted || !_scrollController.hasClients) return;
    final int difference = widget.selectedDate.difference(_startDate).inDays;
    final double offset = (difference * 58.0) - (MediaQuery.of(context).size.width / 2) + 29;
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
            colorScheme: ColorScheme.light(
              primary: AppTheme.blueLagoon,
              onPrimary: Colors.white,
              onSurface: AppTheme.sapphire,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.scooter : AppTheme.blueLagoon;
    final headerBg = isDark ? AppTheme.sapphire : AppTheme.alabaster;
    final textColor = isDark ? Colors.white : AppTheme.sapphire;
    final subTextColor = isDark ? Colors.white70 : AppTheme.sapphire.withOpacity(0.6);

    return Container(
      decoration: BoxDecoration(
        color: headerBg,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
        boxShadow: [
          if (!isDark) 
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
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
                          color: textColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      GestureDetector(
                        onTap: _selectFullDate,
                        child: Row(
                          children: [
                            Text(
                              DateFormat('MMMM, yyyy').format(widget.selectedDate),
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Icon(Icons.keyboard_arrow_down_rounded, color: subTextColor, size: 18),
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
                        border: Border.all(color: primaryColor, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: isDark ? AppTheme.blueLagoon : Colors.white,
                        backgroundImage: _getProfileImage(),
                        child: (widget.profilePicture == null || widget.profilePicture!.isEmpty)
                            ? Icon(Icons.person, color: isDark ? Colors.white : AppTheme.sapphire, size: 18)
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

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => widget.onDateSelected(date),
                        borderRadius: BorderRadius.circular(15),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 50,
                          decoration: BoxDecoration(
                            color: isSelected ? primaryColor : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 10,
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
                                  color: isSelected ? Colors.white : (isDark ? Colors.white60 : AppTheme.sapphire.withOpacity(0.5)),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                date.day.toString(),
                                style: TextStyle(
                                  color: isSelected ? Colors.white : (isDark ? Colors.white : AppTheme.sapphire),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
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
