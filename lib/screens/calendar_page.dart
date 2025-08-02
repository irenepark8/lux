import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  // Calendar state
  int _selectedDay = DateTime.now().day;
  int _calendarViewMonths = 1; // Default to 1 month view
  DateTime _startMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  // Custom date range state
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  // Dot indicator state
  int _currentPageIndex = 0;
  int _totalPages = 1;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Apple Calendar-style Header
        Container(
          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light 
                ? Colors.white 
                : Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey[800]! 
                    : Colors.grey[200]!,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              // Calendar Icon Button (Apple-style)
              GestureDetector(
                onTap: () {
                  _showCalendarContextMenu(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(6.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.transparent,
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: const Color(0xFF1A237E),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Simple "Calendar" Title (Apple-style) - Centered
              Expanded(
                child: Center(
                  child: Text(
                    'Calendar',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white 
                          : Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              // Today Button (Apple Calendar style)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _startMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
                    _selectedDay = DateTime.now().day;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFF1A237E),
                  ),
                  child: Text(
                    'Today',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Calendar Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Calendar Grid (vertical scroll, all months stacked)
                Column(
                  children: List.generate(_calendarViewMonths, (i) {
                    final monthDate = DateTime(_startMonth.year, _startMonth.month + i, 1);
                    return Container(
                      height: 400, // Fixed height for each month block
                      margin: const EdgeInsets.only(bottom: 32.0),
                      child: _buildSingleMonth(monthDate),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                // Dot Indicator
                _buildDotIndicator(),
                const SizedBox(height: 32),
                // Daily Schedule Section
                _buildDailySchedule(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
      child: Column(
        children: _buildMultipleMonths(),
      ),
    );
  }
  
  List<Widget> _buildMultipleMonths() {
    List<Widget> monthWidgets = [];
    
    for (int i = 0; i < _calendarViewMonths; i++) {
                DateTime monthDate = DateTime(_startMonth.year, _startMonth.month + i, 1);
      monthWidgets.add(_buildSingleMonth(monthDate));
      
      // Add spacing between months (except for the last one)
      if (i < _calendarViewMonths - 1) {
        monthWidgets.add(const SizedBox(height: 32));
      }
    }
    
    return monthWidgets;
  }
  
  Widget _buildSingleMonth(DateTime monthDate) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate available height for the calendar grid
        final availableHeight = constraints.maxHeight;
        final headerHeight = 40.0; // Reduced month header
        final weekdayHeight = 25.0; // Reduced weekday row
        final gridHeight = availableHeight - headerHeight - weekdayHeight;
        
        // Calculate how many weeks this month has
        final weeks = _generateCalendarData(monthDate);
        final weekCount = weeks.length;
        
        // Calculate row height to fit all weeks with proper spacing
        final rowHeight = (gridHeight / weekCount).clamp(40.0, 60.0); // Adjusted row height
        final rowSpacing = 0.0; // No spacing between rows for seamless grid
        
        return Column(
          children: [
            // Month/Year Header - More Compact
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Center(
                child: Text(
                  _getMonthYearString(monthDate),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),
            // Weekday Row - Clean
            Container(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                children: List.generate(7, (i) {
                  final day = ['S', 'M', 'T', 'W', 'T', 'F', 'S'][i];
                  final isSunday = i == 0;
                  final isSaturday = i == 6;
                  Color textColor;
                  if (isSunday) {
                    textColor = const Color(0xFF000F40); // Navy
                  } else if (isSaturday) {
                    textColor = const Color(0xFFA9A5F4); // Periwinkle
                  } else {
                    textColor = Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[300]!
                        : Colors.grey[800]!;
                  }
                  return Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            // Calendar Days Grid - Constrained Height
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(top: 8.0), // Add spacing from weekday row
                child: Column(
                  children: _buildCalendarWeeksForMonth(monthDate, rowHeight, rowSpacing),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  String _getMonthYearString(DateTime date) {
    List<String> months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  List<Widget> _buildCalendarWeeksForMonth(DateTime monthDate, double rowHeight, double rowSpacing) {
    // Generate calendar data for the given month
    List<List<int?>> weeks = _generateCalendarData(monthDate);

    return weeks.map((week) {
      return Container(
        height: rowHeight,
        margin: EdgeInsets.symmetric(vertical: rowSpacing),
        child: Row(
          children: week.asMap().entries.map((entry) {
            int dayIndex = entry.key;
            int? day = entry.value;
            
            // Determine if this is a weekend
            bool isSunday = dayIndex == 0;
            bool isSaturday = dayIndex == 6;
            
            return Expanded(
              child: Container(
                decoration: BoxDecoration(
                  // Black grid border
                  border: Border.all(
                    color: Colors.black,
                    width: 0.5,
                  ),
                ),
                child: day == null
                    ? const SizedBox()
                    : GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDay = day;
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: _getDayBackgroundColor(day, isSunday, isSaturday),
                          ),
                          child: Center(
                            child: Text(
                              day.toString(),
                              style: TextStyle(
                                fontSize: (rowHeight * 0.25).clamp(12.0, 16.0),
                                fontWeight: day == _selectedDay ? FontWeight.w600 : FontWeight.w400,
                                color: _getDayTextColor(day, isSunday, isSaturday),
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            );
          }).toList(),
        ),
      );
    }).toList();
  }
  
  Color _getDayBackgroundColor(int day, bool isSunday, bool isSaturday) {
    if (day == _selectedDay) {
      return const Color(0xFF1A237E); // Selected day - navy blue
    } else {
      return Colors.transparent; // All other days - transparent
    }
  }
  
  Color _getDayTextColor(int day, bool isSunday, bool isSaturday) {
    if (day == _selectedDay) {
      return Colors.white; // Selected day - white text
    } else if (isSunday) {
      return const Color(0xFF000F40); // Sunday - navy text
    } else if (isSaturday) {
      return const Color(0xFFA9A5F4); // Saturday - periwinkle text
    } else {
      return Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : Colors.black87; // Weekday - theme-appropriate text
    }
  }
  
  List<List<int?>> _generateCalendarData(DateTime monthDate) {
    // Get the first day of the month
    DateTime firstDay = DateTime(monthDate.year, monthDate.month, 1);
    // Get the last day of the month
    DateTime lastDay = DateTime(monthDate.year, monthDate.month + 1, 0);
    
    // Get the day of week for the first day (0 = Sunday, 1 = Monday, etc.)
    int firstDayOfWeek = firstDay.weekday % 7; // Convert to Sunday = 0
    int lastDayOfMonth = lastDay.day;
    
    List<List<int?>> weeks = [];
    List<int?> currentWeek = [];
    
    // Add empty cells for days before the first day of the month
    for (int i = 0; i < firstDayOfWeek; i++) {
      currentWeek.add(null);
    }
    
    // Add all days of the month
    for (int day = 1; day <= lastDayOfMonth; day++) {
      currentWeek.add(day);
      
      // If we've reached the end of a week (7 days), start a new week
      if (currentWeek.length == 7) {
        weeks.add(List.from(currentWeek));
        currentWeek = [];
      }
    }
    
    // Add empty cells to complete the last week if needed
    while (currentWeek.length < 7) {
      currentWeek.add(null);
    }
    
    // Add the last week if it has any days
    if (currentWeek.isNotEmpty) {
      weeks.add(currentWeek);
    }
    
    return weeks;
  }

  Widget _buildDotIndicator() {
    // Only show dots if more than one month is displayed
    if (_calendarViewMonths <= 1) {
      return const SizedBox.shrink();
    }
    
    // Calculate total pages based on view range
    int totalPages = _calculateTotalPages();
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalPages, (index) {
          return Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: _currentPageIndex == index 
                  ? const Color(0xFF1A237E) 
                  : (Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey[600] 
                      : Colors.grey[400]),
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
  
  int _calculateTotalPages() {
    if (_calendarViewMonths <= 6) {
      // 1 dot per month for 6 months or fewer
      return _calendarViewMonths;
    } else {
      // Group by 2 months per dot for more than 6 months
      return (_calendarViewMonths / 2).ceil();
    }
  }

  Widget _buildCalendarPage(int pageIndex) {
    int monthsPerPage = _calendarViewMonths <= 6 ? 1 : 2;
    int startMonthIndex = pageIndex * monthsPerPage;
    
    return Column(
      children: List.generate(
        monthsPerPage,
        (monthOffset) {
          int monthIndex = startMonthIndex + monthOffset;
          if (monthIndex >= _calendarViewMonths) return const SizedBox.shrink();
          
          DateTime monthDate = DateTime(_startMonth.year, _startMonth.month + monthIndex, 1);
          return Column(
            children: [
              // Month/Year Header (Apple Calendar style) - Centered
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Center(
                  child: Text(
                    _getMonthYearString(monthDate),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white 
                          : Colors.black,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              // Weekday Row (Apple Calendar style)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.grey[500] 
                                : Colors.grey[600],
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              // Calendar Days Grid (Apple Calendar style)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Column(
                  children: _buildCalendarWeeksForMonth(monthDate, 44.0, 6.0),
                ),
              ),
              // Add spacing between months on the same page
              if (monthOffset < monthsPerPage - 1 && monthIndex < _calendarViewMonths - 1)
                const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  void _showCalendarContextMenu(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Select View Duration'),
        actions: [
          CupertinoActionSheetAction(
            child: const Text('2 months'),
            onPressed: () {
              Navigator.pop(context);
              _updateCalendarView('2 months', 2);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('3 months'),
            onPressed: () {
              Navigator.pop(context);
              _updateCalendarView('3 months', 3);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('4 months'),
            onPressed: () {
              Navigator.pop(context);
              _updateCalendarView('4 months', 4);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('6 months'),
            onPressed: () {
              Navigator.pop(context);
              _updateCalendarView('6 months', 6);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('1 year'),
            onPressed: () {
              Navigator.pop(context);
              _updateCalendarView('1 year', 12);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Customize'),
            onPressed: () {
              Navigator.pop(context);
              _showCustomizeDialog(context);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _updateCalendarView(String duration, int months) {
    setState(() {
      _calendarViewMonths = months;
      _currentPageIndex = 0; // Reset to first page when view changes
      _startMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calendar view updated to: $duration'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showCustomizeDialog(BuildContext context) {
    DateTime tempStartDate = _customStartDate ?? DateTime.now();
    DateTime tempEndDate = _customEndDate ?? DateTime.now().add(const Duration(days: 30));
    
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 400,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.grey[900]! 
                : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.grey[800]! 
                          : Colors.grey[300]!,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Custom Date Range',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white 
                              : Colors.black87,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.close,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white 
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              // Date Pickers
              Expanded(
                child: Row(
                  children: [
                    // Start Date Picker
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              'Start Date',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.white 
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          Expanded(
                            child: CupertinoDatePicker(
                              mode: CupertinoDatePickerMode.date,
                              initialDateTime: tempStartDate,
                              minimumDate: DateTime.now(),
                              maximumDate: DateTime.now().add(Duration(days: 365 * 10)),
                              onDateTimeChanged: (DateTime newDate) {
                                tempStartDate = newDate;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Divider
                    Container(
                      width: 1,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.grey[800]! 
                          : Colors.grey[300]!,
                    ),
                    // End Date Picker
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              'End Date',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.white 
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          Expanded(
                            child: CupertinoDatePicker(
                              mode: CupertinoDatePickerMode.date,
                              initialDateTime: tempEndDate,
                              minimumDate: tempStartDate,
                              maximumDate: DateTime.now().add(Duration(days: 365 * 10)),
                              onDateTimeChanged: (DateTime newDate) {
                                tempEndDate = newDate;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Action Buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.grey[800]! 
                          : Colors.grey[300]!,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    Expanded(
                      child: CupertinoButton(
                        color: const Color(0xFF1A237E),
                        child: const Text('Apply'),
                        onPressed: () {
                          setState(() {
                            _customStartDate = tempStartDate;
                            _customEndDate = tempEndDate;
                            // Calculate months between dates
                            int months = ((tempEndDate.year - tempStartDate.year) * 12) + 
                                       (tempEndDate.month - tempStartDate.month);
                            _calendarViewMonths = months.abs() + 1;
                            _startMonth = DateTime(tempStartDate.year, tempStartDate.month, 1);
                          });
                          Navigator.of(context).pop();
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Custom range applied: ${tempStartDate.month}/${tempStartDate.year} - ${tempEndDate.month}/${tempEndDate.year}'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDailySchedule() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header (Apple Calendar style)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              'Daily Schedule',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : Colors.black,
                letterSpacing: -0.3,
              ),
            ),
          ),
          // Schedule Items
          ..._buildScheduleItems(),
        ],
      ),
    );
  }

  List<Widget> _buildScheduleItems() {
    List<Map<String, String>> scheduleItems = [
      {'time': '8:00 AM – 9:00 AM', 'activity': 'Morning Study Session'},
      {'time': '10:30 AM – 11:30 AM', 'activity': 'Break & Refresh'},
      {'time': '2:00 PM – 3:30 PM', 'activity': 'Afternoon Focus Time'},
      {'time': '4:00 PM – 5:00 PM', 'activity': 'Review & Planning'},
      {'time': '7:00 PM – 8:00 PM', 'activity': 'Evening Review'},
    ];

    return scheduleItems.asMap().entries.map((entry) {
      int index = entry.key;
      Map<String, String> item = entry.value;
      bool isLast = index == scheduleItems.length - 1;

      return Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time Column (Apple Calendar style)
            Container(
              width: 60,
              child: Column(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 40,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.grey[700] 
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Content Column (Apple Calendar style)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['time']!,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white 
                          : Colors.black87,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['activity']!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.grey[400] 
                          : Colors.grey[600],
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
} 