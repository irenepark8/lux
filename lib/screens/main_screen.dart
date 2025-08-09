import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../widgets/custom_bottom_nav.dart';
import '../db/schedule_api_service.dart';
import 'pomodoro_screen.dart';
import 'todo_screen.dart';
import 'settings_screen.dart';
import 'dictionary_screen.dart';
import 'speech_screen.dart';
import 'chat_screen.dart';
import 'calendar_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  List<ScheduleData> _schedule = [];
  bool _isLoading = true;
  final ScheduleApiService _scheduleService = ScheduleApiService();

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
      case 4:
        return const DictionaryScreen();
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _schedule.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_note,
                            size: 64,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[600]
                                : Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '오늘 예정된 일정이 없습니다',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '마이크 버튼을 눌러 새로운 일정을 추가해보세요',
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[500]
                                  : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
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
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 24,
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  if (!isLast)
                                    Container(
                                      width: 2,
                                      height: 48,
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: CustomPaint(
                                        painter: DottedLinePainter(
                                          color:
                                              Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? const Color(0xFF444444)
                                              : Colors.grey[400]!,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _showScheduleOptionsModal(item),
                                  child: Container(
                                    padding: const EdgeInsets.all(12.0),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color(0xFF2C2C2E)
                                          : Colors.grey[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? const Color(0xFF444444)
                                            : Colors.grey[300]!,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          Theme.of(
                                                                context,
                                                              ).brightness ==
                                                              Brightness.dark
                                                          ? Colors.white
                                                          : Colors.black87,
                                                    ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    Theme.of(
                                                          context,
                                                        ).brightness ==
                                                        Brightness.dark
                                                    ? Colors.deepPurple
                                                          .withOpacity(0.3)
                                                    : Colors.deepPurple
                                                          .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                item.category,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      Theme.of(
                                                            context,
                                                          ).brightness ==
                                                          Brightness.dark
                                                      ? Colors.deepPurple[200]
                                                      : Colors.deepPurple[700],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${item.time} • ${item.date}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color:
                                                    Theme.of(
                                                          context,
                                                        ).brightness ==
                                                        Brightness.dark
                                                    ? Colors.grey[400]
                                                    : Colors.grey[600],
                                              ),
                                        ),
                                        if (item.description.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            item.description,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color:
                                                      Theme.of(
                                                            context,
                                                          ).brightness ==
                                                          Brightness.dark
                                                      ? Colors.grey[300]
                                                      : Colors.grey[700],
                                                ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        Positioned(
          bottom: 24.0,
          right: 24.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 새로고침 버튼
              FloatingActionButton(
                heroTag: "refresh",
                onPressed: () {
                  _loadSchedule();
                },
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFDBE8F2),
                child: Icon(
                  Icons.refresh,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              // 채팅 버튼
              FloatingActionButton(
                heroTag: "chat",
                onPressed: () async {
                  // 채팅 모달 표시
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return const ChatModal();
                    },
                  );

                  // 스케줄이 추가되었다면 새로고침
                  if (result == true) {
                    _loadSchedule();
                  }
                },
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFDBE8F2),
                child: Icon(
                  Icons.chat_bubble_outline,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              // 음성 인식 버튼
              FloatingActionButton(
                heroTag: "speech",
                onPressed: () async {
                  // 음성 인식 모달 표시
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return const SpeechModal();
                    },
                  );

                  // 일정이 추가되었다면 새로고침
                  if (result == true) {
                    _loadSchedule();
                  }
                },
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFDBE8F2),
                child: Icon(
                  Icons.mic,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ],
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
          Icon(Icons.construction, size: 64, color: Colors.grey),
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
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSchedule() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 오늘 날짜의 스케줄을 조회
      final today = DateTime.now();
      final dateString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      print('📅 오늘 날짜로 스케줄 조회: $dateString');

      // 실제 API 호출
      final schedules = await _scheduleService.fetchSchedules(date: dateString);

      setState(() {
        _schedule = schedules;
        _isLoading = false;
      });

      print('📅 로드된 스케줄 개수: ${schedules.length}');
    } catch (e) {
      print('❌ 스케줄 로드 오류: $e');
      setState(() {
        _schedule = [];
        _isLoading = false;
      });

      // 에러 발생 시 사용자에게 알림
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('스케줄을 불러오는데 실패했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 스케줄 옵션 모달 표시
  void _showScheduleOptionsModal(ScheduleData schedule) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1C1C1E)
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 핸들
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // 스케줄 정보
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${schedule.time} • ${schedule.date}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                      ),
                      if (schedule.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          schedule.description,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                              ),
                        ),
                      ],
                    ],
                  ),
                ),

                const Divider(),

                // 옵션 버튼들
                ListTile(
                  leading: Icon(
                    Icons.edit,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.blue[300]
                        : Colors.blue[700],
                  ),
                  title: const Text('편집하기'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditScheduleModal(schedule);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.red[300]
                        : Colors.red[700],
                  ),
                  title: const Text('삭제하기'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmDialog(schedule);
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // 스케줄 편집 모달
  void _showEditScheduleModal(ScheduleData schedule) {
    final titleController = TextEditingController(text: schedule.title);
    final descriptionController = TextEditingController(
      text: schedule.description,
    );
    final categoryController = TextEditingController(text: schedule.category);

    // 현재 시간을 DateTime으로 파싱
    DateTime selectedTime = _parseTimeString(schedule.time);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('스케줄 편집'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: '제목',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cupertino Time Picker 버튼
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ListTile(
                        title: Text(
                          '시간',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        subtitle: Text(
                          _formatTime(selectedTime),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: const Icon(Icons.access_time),
                        onTap: () => _showCupertinoTimePicker(
                          context,
                          selectedTime,
                          (DateTime time) {
                            setState(() {
                              selectedTime = time;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    TextField(
                      controller: categoryController,
                      decoration: const InputDecoration(
                        labelText: '카테고리',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: '설명',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final updatedSchedule = ScheduleData(
                      id: schedule.id,
                      userId: schedule.userId,
                      title: titleController.text.trim(),
                      date: schedule.date,
                      time: _formatTime(selectedTime),
                      category: categoryController.text.trim(),
                      description: descriptionController.text.trim(),
                      createdAt: schedule.createdAt,
                      updatedAt: schedule.updatedAt,
                    );

                    Navigator.pop(context);
                    _editSchedule(updatedSchedule);
                  },
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 삭제 확인 다이얼로그
  void _showDeleteConfirmDialog(ScheduleData schedule) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('스케줄 삭제'),
          content: Text(
            '\'${schedule.title}\' 스케줄을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteSchedule(schedule);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }

  // 스케줄 편집
  Future<void> _editSchedule(ScheduleData schedule) async {
    if (schedule.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('편집할 수 없는 스케줄입니다.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final result = await _scheduleService.updateSchedule(
        schedule.id!,
        schedule,
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? '스케줄이 수정되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        _loadSchedule(); // 목록 새로고침
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? '스케줄 수정에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('스케줄 수정 중 오류가 발생했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 시간 문자열을 DateTime으로 파싱 (예: "14:30" -> DateTime)
  DateTime _parseTimeString(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day, hour, minute);
      }
    } catch (e) {
      print('시간 파싱 오류: $e');
    }

    // 파싱 실패 시 현재 시간 반환
    return DateTime.now();
  }

  // DateTime을 HH:MM 형식 문자열로 변환
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Cupertino Time Picker 모달 표시
  void _showCupertinoTimePicker(
    BuildContext context,
    DateTime initialTime,
    Function(DateTime) onTimeChanged,
  ) {
    DateTime tempTime = initialTime;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1C1C1E)
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('취소'),
                    ),
                    const Text(
                      '시간 선택',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        onTimeChanged(tempTime);
                        Navigator.pop(context);
                      },
                      child: const Text('확인'),
                    ),
                  ],
                ),
              ),

              // Time Picker
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: initialTime,
                  use24hFormat: true,
                  onDateTimeChanged: (DateTime dateTime) {
                    tempTime = dateTime;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 스케줄 삭제
  Future<void> _deleteSchedule(ScheduleData schedule) async {
    if (schedule.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('삭제할 수 없는 스케줄입니다.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final result = await _scheduleService.deleteSchedule(schedule.id!);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? '스케줄이 삭제되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        _loadSchedule(); // 목록 새로고침
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? '스케줄 삭제에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('스케줄 삭제 중 오류가 발생했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? Colors.white
          : Theme.of(context).scaffoldBackgroundColor,
      appBar: _selectedIndex == 0
          ? AppBar(
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
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            )
          : null,
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
