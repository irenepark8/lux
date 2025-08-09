import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';
import '../db/schedule_api_service.dart';

class ChatModal extends StatefulWidget {
  const ChatModal({super.key});

  @override
  State<ChatModal> createState() => _ChatModalState();
}

class _ChatModalState extends State<ChatModal> {
  final List<types.Message> _messages = [];
  final ScheduleApiService _scheduleApiService = ScheduleApiService();
  final _uuid = const Uuid();

  // 사용자 정보 (bot과 구분하기 위해)
  final _user = const types.User(id: 'user', firstName: 'User');

  final _bot = const types.User(id: 'bot', firstName: 'Assistant');

  @override
  void initState() {
    super.initState();
    _addBotMessage(
      '안녕하세요! 스케줄 관리를 도와드리겠습니다.\nHello! I can help you manage your schedule.\n\n💡 사용법 / Usage:\n• 스케줄 추가 / Add: "내일 오후 2시에 회의 있어", "meeting tomorrow 2pm"\n• 스케줄 조회 / Query: "오늘 일정", "today schedule", "this week"',
    );
  }

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _addBotMessage(String text) {
    final message = types.TextMessage(
      author: _bot,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: _uuid.v4(),
      text: text,
    );
    _addMessage(message);
  }

  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: _uuid.v4(),
      text: message.text,
    );

    _addMessage(textMessage);
    _processUserMessage(message.text);
  }

  /// 사용자 메시지 처리
  Future<void> _processUserMessage(String text) async {
    final lowerText = text.toLowerCase().trim();

    // 먼저 스케줄 조회 요청인지 확인 (조회가 우선)
    if (_isScheduleQuery(lowerText)) {
      await _handleScheduleQuery(lowerText);
      return;
    }

    // 스케줄 추가 요청 처리 (구체적인 시간과 활동이 포함된 경우)
    final detectedSchedule = _analyzeScheduleFromText(text);
    if (detectedSchedule != null) {
      await _handleScheduleAdd(detectedSchedule, text);
      return;
    }

    // 일반 대화 처리
    _handleGeneralConversation(text);
  }

  /// 스케줄 조회 요청인지 확인
  bool _isScheduleQuery(String text) {
    // 1. 명확한 조회 키워드들
    final pureQueryPatterns = [
      // 한국어 조회 표현
      '뭐해', '뭐 있어', '뭐 하지', '언제', '무슨 일', '계획', '예정',
      // 영어 조회 표현
      'what', 'when', 'plan', 'agenda', 'show me', 'list', 'check',
      'what\'s on', 'any plans', 'schedule for', 'events', 'what do i have',
      'do i have', 'what am i doing', 'free', 'busy', 'available',
    ];

    bool hasPureQuery = pureQueryPatterns.any(
      (pattern) => text.contains(pattern),
    );
    if (hasPureQuery) {
      return true;
    }

    // 2. "일정" 또는 "스케줄" + 날짜 조합 (구체적 시간/활동 없는 경우)
    bool hasScheduleWord =
        text.contains('일정') ||
        text.contains('스케줄') ||
        text.contains('schedule');

    if (hasScheduleWord) {
      // 구체적인 시간이 있으면 추가 요청일 가능성이 높음
      final timePatterns = [
        r'\d+시',
        r'\d+:\d+',
        r'\d+\s*am',
        r'\d+\s*pm',
        '오전',
        '오후',
        'morning',
        'afternoon',
        'evening',
      ];

      bool hasSpecificTime = timePatterns.any(
        (pattern) => RegExp(pattern, caseSensitive: false).hasMatch(text),
      );

      // 추가 의도를 나타내는 키워드들
      final additionKeywords = [
        '있어',
        '해야',
        '가야',
        '만나',
        '봐야',
        '추가',
        'add',
        'create',
      ];

      bool hasAdditionIntent = additionKeywords.any(
        (keyword) => text.contains(keyword),
      );

      // 시간이나 추가 의도가 없으면 조회 요청
      return !hasSpecificTime && !hasAdditionIntent;
    }

    // 3. 날짜만 있는 경우 (순수 조회)
    final dateOnlyPatterns = [
      '오늘',
      '내일',
      '모레',
      '이번주',
      '다음주',
      '이번 주',
      '다음 주',
      'today',
      'tomorrow',
      'this week',
      'next week',
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];

    bool hasDateOnly = dateOnlyPatterns.any(
      (pattern) => text.contains(pattern),
    );

    if (hasDateOnly) {
      // 구체적인 활동이나 시간이 있다면 추가 요청
      final activityKeywords = [
        '회의',
        '미팅',
        '과외',
        '수업',
        '약속',
        '만남',
        '병원',
        '치과',
        '운동',
        '식사',
        'meeting',
        'class',
        'appointment',
        'lesson',
        'tutoring',
        'gym',
        'hospital',
      ];

      final timeKeywords = ['시', '분', '오전', '오후', 'am', 'pm', 'o\'clock'];

      bool hasActivity = activityKeywords.any(
        (keyword) => text.contains(keyword),
      );
      bool hasTime = timeKeywords.any((keyword) => text.contains(keyword));

      // 날짜만 있고 구체적인 활동이나 시간이 없으면 조회 요청
      return !hasActivity && !hasTime;
    }

    return false;
  }

  /// 스케줄 조회 처리
  Future<void> _handleScheduleQuery(String text) async {
    try {
      _addBotMessage('📋 스케줄을 조회하고 있습니다...');

      final schedules = await _scheduleApiService.fetchSchedules();

      if (schedules.isEmpty) {
        _addBotMessage('📅 등록된 스케줄이 없습니다.');
        return;
      }

      // 날짜별로 필터링
      List<ScheduleData> filteredSchedules = _filterSchedulesByQuery(
        schedules,
        text,
      );

      if (filteredSchedules.isEmpty) {
        _addBotMessage('📅 해당 조건에 맞는 스케줄이 없습니다.');
        return;
      }

      // 스케줄 목록을 문자열로 포맷
      String scheduleText = '📋 스케줄 목록:\n\n';
      for (var schedule in filteredSchedules) {
        scheduleText += '• ${schedule.title}\n';
        scheduleText += '  📅 ${schedule.date} ${schedule.time}\n';
        scheduleText += '  🏷️ ${schedule.category}\n';
        if (schedule.description.isNotEmpty) {
          scheduleText += '  📝 ${schedule.description}\n';
        }
        scheduleText += '\n';
      }

      _addBotMessage(scheduleText);
    } catch (e) {
      _addBotMessage('❌ 스케줄 조회 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  /// 쿼리에 따라 스케줄 필터링
  List<ScheduleData> _filterSchedulesByQuery(
    List<ScheduleData> schedules,
    String query,
  ) {
    final today = DateTime.now();
    final todayStr = today.toString().split(' ')[0];
    final tomorrowStr = today
        .add(const Duration(days: 1))
        .toString()
        .split(' ')[0];

    if (query.contains('오늘') || query.contains('today')) {
      return schedules.where((s) => s.date == todayStr).toList();
    } else if (query.contains('내일') || query.contains('tomorrow')) {
      return schedules.where((s) => s.date == tomorrowStr).toList();
    } else if (query.contains('이번주') || query.contains('this week')) {
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));
      return schedules.where((s) {
        final scheduleDate = DateTime.parse(s.date);
        return scheduleDate.isAfter(
              weekStart.subtract(const Duration(days: 1)),
            ) &&
            scheduleDate.isBefore(weekEnd.add(const Duration(days: 1)));
      }).toList();
    } else if (query.contains('다음주') || query.contains('next week')) {
      final nextWeekStart = today.add(Duration(days: 7 - today.weekday + 1));
      final nextWeekEnd = nextWeekStart.add(const Duration(days: 6));
      return schedules.where((s) {
        final scheduleDate = DateTime.parse(s.date);
        return scheduleDate.isAfter(
              nextWeekStart.subtract(const Duration(days: 1)),
            ) &&
            scheduleDate.isBefore(nextWeekEnd.add(const Duration(days: 1)));
      }).toList();
    }

    // 영어 요일 처리
    final lowerQuery = query.toLowerCase();
    final weekdayMap = {
      'monday': 1,
      'tuesday': 2,
      'wednesday': 3,
      'thursday': 4,
      'friday': 5,
      'saturday': 6,
      'sunday': 7,
    };

    for (var entry in weekdayMap.entries) {
      if (lowerQuery.contains(entry.key)) {
        final targetWeekday = entry.value;
        final nextTargetDate = _getNextWeekday(today, targetWeekday);
        final targetDateStr = nextTargetDate.toString().split(' ')[0];
        return schedules.where((s) => s.date == targetDateStr).toList();
      }
    }

    // 기본적으로 모든 스케줄 반환
    return schedules;
  }

  /// 스케줄 추가 처리
  Future<void> _handleScheduleAdd(
    ScheduleData schedule,
    String originalText,
  ) async {
    try {
      _addBotMessage(
        '📝 다음 스케줄을 인식했습니다:\n\n'
        '• 제목: ${schedule.title}\n'
        '• 날짜: ${schedule.date}\n'
        '• 시간: ${schedule.time}\n'
        '• 카테고리: ${schedule.category}\n\n'
        '스케줄을 추가하고 있습니다...',
      );

      final result = await _scheduleApiService.addSchedule(schedule);

      if (result['success']) {
        _addBotMessage('✅ ${result['message']}');
      } else {
        _addBotMessage('❌ ${result['message']}');
      }
    } catch (e) {
      _addBotMessage('❌ 스케줄 추가 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  /// 일반 대화 처리
  void _handleGeneralConversation(String text) {
    final lowerText = text.toLowerCase();

    if (text.contains('안녕') ||
        lowerText.contains('hello') ||
        lowerText.contains('hi')) {
      _addBotMessage(
        '안녕하세요! 스케줄 관리를 도와드리겠습니다. 어떤 일정을 추가하거나 조회하고 싶으신가요?\n\nHello! I can help you manage your schedule. What would you like to add or check?',
      );
    } else if (text.contains('도움') || lowerText.contains('help')) {
      _addBotMessage(
        '💡 사용 가능한 명령어 / Available Commands:\n\n'
        '📅 스케줄 조회 / Schedule Query:\n'
        '• "오늘 일정" / "today schedule"\n'
        '• "내일 스케줄" / "tomorrow"\n'
        '• "이번 주 일정" / "this week"\n\n'
        '➕ 스케줄 추가 / Add Schedule:\n'
        '• "내일 오후 2시에 회의" / "meeting tomorrow 2pm"\n'
        '• "금요일 3시 과외" / "tutoring friday 3pm"\n'
        '• "다음주 월요일 10시 병원" / "hospital next monday 10am"',
      );
    } else {
      _addBotMessage(
        '죄송하지만 이해하지 못했습니다. "도움"이라고 입력하시면 사용법을 안내해드릴게요.\n\nSorry, I didn\'t understand. Type "help" for usage instructions.',
      );
    }
  }

  /// 텍스트에서 스케줄 정보 추출 (speech_screen.dart와 동일한 로직)
  ScheduleData? _analyzeScheduleFromText(String text) {
    if (text.isEmpty) return null;

    final lowerText = text.toLowerCase();

    // 스케줄 관련 키워드가 있는지 확인
    final scheduleKeywords = [
      '일정',
      '약속',
      '미팅',
      '과외',
      '수업',
      '회의',
      '만남',
      'meeting',
      'appointment',
      'class',
      'lesson',
      'tutoring',
      'session',
      'conference',
      'schedule',
      'event',
      'gathering',
      'date',
      'interview',
    ];
    bool hasScheduleKeyword = scheduleKeywords.any(
      (keyword) => lowerText.contains(keyword.toLowerCase()),
    );

    // 시간 관련 키워드가 있는지 확인
    final timeKeywords = [
      '시',
      '분',
      '오전',
      '오후',
      '아침',
      '점심',
      '저녁',
      '밤',
      'o\'clock',
      'hour',
      'minute',
      'am',
      'pm',
      'a.m.',
      'p.m.',
      'morning',
      'afternoon',
      'evening',
      'night',
      'noon',
      'midnight',
    ];
    bool hasTimeKeyword = timeKeywords.any(
      (keyword) => lowerText.contains(keyword.toLowerCase()),
    );

    // 날짜 관련 키워드가 있는지 확인
    final dateKeywords = [
      '오늘',
      '내일',
      '모레',
      '이번',
      '다음',
      '월',
      '화',
      '수',
      '목',
      '금',
      '토',
      '일',
      'today',
      'tomorrow',
      'yesterday',
      'this',
      'next',
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
      'week',
      'month',
      'day',
    ];
    bool hasDateKeyword = dateKeywords.any(
      (keyword) => lowerText.contains(keyword.toLowerCase()),
    );

    if (!hasScheduleKeyword && !hasTimeKeyword && !hasDateKeyword) {
      return null;
    }

    String date = _extractDate(text);
    String time = _extractTime(text);
    String title = _extractTitle(text);
    String category = _extractCategory(text);

    return ScheduleData(
      title: title,
      date: date,
      time: time,
      category: category,
      description: text,
    );
  }

  /// 날짜 정보 추출 (speech_screen.dart와 동일)
  String _extractDate(String text) {
    final lowerText = text.toLowerCase();

    if (text.contains('오늘') || lowerText.contains('today')) {
      return DateTime.now().toString().split(' ')[0];
    } else if (text.contains('내일') || lowerText.contains('tomorrow')) {
      return DateTime.now()
          .add(const Duration(days: 1))
          .toString()
          .split(' ')[0];
    } else if (text.contains('모레')) {
      return DateTime.now()
          .add(const Duration(days: 2))
          .toString()
          .split(' ')[0];
    }

    // "08일", "6일" 같은 형태의 날짜 패턴 처리
    RegExp dayPattern = RegExp(r'(\d{1,2})일');
    Match? dayMatch = dayPattern.firstMatch(text);

    if (dayMatch != null) {
      int day = int.parse(dayMatch.group(1) ?? '0');
      final today = DateTime.now();

      if (day >= 1 && day <= 31) {
        try {
          // 이번 달의 해당 날짜로 설정
          final targetDate = DateTime(today.year, today.month, day);

          // 만약 해당 날짜가 이미 지났다면 다음 달로
          if (targetDate.isBefore(today)) {
            final nextMonthDate = DateTime(today.year, today.month + 1, day);
            return nextMonthDate.toString().split(' ')[0];
          }

          return targetDate.toString().split(' ')[0];
        } catch (e) {
          // 날짜가 유효하지 않은 경우 (예: 2월 30일) 다음 달로
          final nextMonthDate = DateTime(today.year, today.month + 1, day);
          return nextMonthDate.toString().split(' ')[0];
        }
      }
    }

    final today = DateTime.now();

    if (lowerText.contains('monday')) {
      return _getNextWeekday(today, 1).toString().split(' ')[0];
    } else if (lowerText.contains('tuesday')) {
      return _getNextWeekday(today, 2).toString().split(' ')[0];
    } else if (lowerText.contains('wednesday')) {
      return _getNextWeekday(today, 3).toString().split(' ')[0];
    } else if (lowerText.contains('thursday')) {
      return _getNextWeekday(today, 4).toString().split(' ')[0];
    } else if (lowerText.contains('friday')) {
      return _getNextWeekday(today, 5).toString().split(' ')[0];
    } else if (lowerText.contains('saturday')) {
      return _getNextWeekday(today, 6).toString().split(' ')[0];
    } else if (lowerText.contains('sunday')) {
      return _getNextWeekday(today, 7).toString().split(' ')[0];
    }

    return DateTime.now().toString().split(' ')[0];
  }

  /// 다음 특정 요일 날짜 계산
  DateTime _getNextWeekday(DateTime from, int targetWeekday) {
    final currentWeekday = from.weekday;
    int daysToAdd = targetWeekday - currentWeekday;

    if (daysToAdd <= 0) {
      daysToAdd += 7;
    }

    return from.add(Duration(days: daysToAdd));
  }

  /// 시간 정보 추출 (speech_screen.dart와 동일)
  String _extractTime(String text) {
    final lowerText = text.toLowerCase();

    // 한국어 시간 패턴
    RegExp koreanTimePattern = RegExp(r'(\d{1,2})시(\s*(\d{1,2})분)?');
    Match? koreanMatch = koreanTimePattern.firstMatch(text);

    if (koreanMatch != null) {
      int hour = int.parse(koreanMatch.group(1) ?? '0');
      int minute = int.parse(koreanMatch.group(3) ?? '0');

      if (text.contains('오후') && hour < 12) {
        hour += 12;
      }

      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }

    // 영어 시간 패턴
    RegExp englishPattern1 = RegExp(
      r'(\d{1,2})\s*(am|pm|a\.m\.|p\.m\.)',
      caseSensitive: false,
    );
    Match? englishMatch1 = englishPattern1.firstMatch(lowerText);

    if (englishMatch1 != null) {
      int hour = int.parse(englishMatch1.group(1) ?? '0');
      String ampm = englishMatch1.group(2)?.toLowerCase() ?? '';

      if ((ampm.contains('pm') || ampm.contains('p.m.')) && hour < 12) {
        hour += 12;
      } else if ((ampm.contains('am') || ampm.contains('a.m.')) && hour == 12) {
        hour = 0;
      }

      return '${hour.toString().padLeft(2, '0')}:00';
    }

    RegExp englishPattern2 = RegExp(
      r'(\d{1,2}):(\d{2})\s*(am|pm|a\.m\.|p\.m\.)?',
      caseSensitive: false,
    );
    Match? englishMatch2 = englishPattern2.firstMatch(lowerText);

    if (englishMatch2 != null) {
      int hour = int.parse(englishMatch2.group(1) ?? '0');
      int minute = int.parse(englishMatch2.group(2) ?? '0');
      String? ampm = englishMatch2.group(3)?.toLowerCase();

      if (ampm != null) {
        if ((ampm.contains('pm') || ampm.contains('p.m.')) && hour < 12) {
          hour += 12;
        } else if ((ampm.contains('am') || ampm.contains('a.m.')) &&
            hour == 12) {
          hour = 0;
        }
      }

      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }

    // 특별한 시간 표현들
    if (lowerText.contains('noon') || lowerText.contains('점심')) {
      return '12:00';
    } else if (lowerText.contains('midnight') || lowerText.contains('자정')) {
      return '00:00';
    } else if (lowerText.contains('morning') || lowerText.contains('아침')) {
      return '09:00';
    } else if (lowerText.contains('afternoon') || lowerText.contains('오후')) {
      return '14:00';
    } else if (lowerText.contains('evening') || lowerText.contains('저녁')) {
      return '18:00';
    } else if (lowerText.contains('night') || lowerText.contains('밤')) {
      return '20:00';
    }

    return '09:00';
  }

  /// 제목 추출 (speech_screen.dart와 동일)
  String _extractTitle(String text) {
    final lowerText = text.toLowerCase();

    if (text.contains('과외') || lowerText.contains('tutoring')) return '과외';
    if (text.contains('수업') ||
        lowerText.contains('class') ||
        lowerText.contains('lesson'))
      return '수업';
    if (lowerText.contains('study') || lowerText.contains('homework'))
      return '공부';

    if (text.contains('미팅') ||
        text.contains('회의') ||
        lowerText.contains('meeting'))
      return '회의';
    if (lowerText.contains('conference') || lowerText.contains('presentation'))
      return '컨퍼런스';
    if (lowerText.contains('interview')) return '인터뷰';
    if (lowerText.contains('work') || lowerText.contains('project'))
      return '업무';

    if (text.contains('약속') || lowerText.contains('appointment')) return '약속';
    if (text.contains('만남') ||
        lowerText.contains('date') ||
        lowerText.contains('gathering'))
      return '만남';
    if (lowerText.contains('dinner') ||
        lowerText.contains('lunch') ||
        lowerText.contains('meal'))
      return '식사';

    if (lowerText.contains('doctor') ||
        lowerText.contains('hospital') ||
        lowerText.contains('clinic'))
      return '병원';

    return '일정';
  }

  /// 카테고리 추출 (speech_screen.dart와 동일)
  String _extractCategory(String text) {
    final lowerText = text.toLowerCase();

    if (text.contains('과외') ||
        text.contains('수업') ||
        lowerText.contains('tutoring') ||
        lowerText.contains('class') ||
        lowerText.contains('lesson') ||
        lowerText.contains('study'))
      return '교육';

    if (text.contains('미팅') ||
        text.contains('회의') ||
        lowerText.contains('meeting') ||
        lowerText.contains('conference') ||
        lowerText.contains('work'))
      return '업무';

    if (lowerText.contains('doctor') ||
        lowerText.contains('hospital') ||
        lowerText.contains('clinic'))
      return '의료';

    if (lowerText.contains('exercise') ||
        lowerText.contains('gym') ||
        lowerText.contains('workout'))
      return '운동';

    return '개인';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '스케줄 채팅',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // 채팅 UI
            Expanded(
              child: Chat(
                messages: _messages,
                onSendPressed: _handleSendPressed,
                user: _user,
                theme: DefaultChatTheme(
                  primaryColor: Theme.of(context).primaryColor,
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[900]!
                      : Colors.grey[50]!,
                  inputBackgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]!
                      : Colors.white,
                  inputTextColor:
                      Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
                showUserAvatars: true,
                showUserNames: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
