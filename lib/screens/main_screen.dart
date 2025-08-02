import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../widgets/custom_bottom_nav.dart';
import 'pomodoro_screen.dart';
import 'todo_screen.dart';
import 'settings_screen.dart';
import 'calendar_page.dart';
import 'package:flutter/cupertino.dart'; // Added for CupertinoActionSheet and CupertinoAlertDialog

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  List<dynamic> _schedule = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeScreen();
      case 1:
        return const CalendarPage();
      case 2:
        return const PomodoroScreen();
      case 3:
        return TodoScreen(
          onBackToMain: () {
            setState(() {
              _selectedIndex = 0;
            });
          },
        );
      default:
        return _buildPlaceholderScreen();
    }
  }

  Widget _buildHomeScreen() {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFFF7D8C5), // Always peach, even in dark mode
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Image.asset(
                  'assets/mainScreenImg.jpg',
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 0, 8),
              child: Text(
                'Daily Schedule',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 0,
                      ),
                      itemCount: _schedule.length,
                      itemBuilder: (context, index) {
                        final item = _schedule[index];
                        final isLast = index == _schedule.length - 1;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 24,
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                                ),
                                if (!isLast)
                                  Container(
                                    width: 2,
                                    height: 32,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: CustomPaint(
                                      painter: DottedLinePainter(
                                        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF444444) : Colors.grey[400]!,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Text(
                                '${item['start']} - ${item['end']}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
        Positioned(
          bottom: 24.0,
          right: 24.0,
          child: FloatingActionButton(
            onPressed: () {
              // TODO: 채팅 기능 연결
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('채팅 기능 준비 중!')));
            },
            backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2E) : const Color(0xFFDBE8F2),
            child: Icon(Icons.chat, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
          ),
        ),
      ],
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


  










  Widget _buildPlaceholderScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Coming Soon!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This feature is under development',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSchedule() async {
    final String jsonString = await rootBundle.loadString(
      'dumy/daily_schedule.json',
    );
    final List<dynamic> jsonData = json.decode(jsonString);
    setState(() {
      _schedule = jsonData;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light 
          ? Colors.white 
          : Theme.of(context).scaffoldBackgroundColor,
      appBar: _selectedIndex == 0 ? AppBar(
        centerTitle: true,
        title: const Text(
          'Study Planner',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ) : null,
      body: _buildBody(),
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

class DottedLinePainter extends CustomPainter {
  final Color color;
  DottedLinePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    double dashHeight = 4, dashSpace = 4, startY = 0;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
