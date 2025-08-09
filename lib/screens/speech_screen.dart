import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../language_provider.dart';
import '../db/schedule_api_service.dart';

class SpeechModal extends StatefulWidget {
  const SpeechModal({super.key});

  @override
  State<SpeechModal> createState() => _SpeechModalState();
}

class _SpeechModalState extends State<SpeechModal> {
  final SpeechToText _speechToText = SpeechToText();
  final ScheduleApiService _scheduleApiService = ScheduleApiService();
  bool _speechEnabled = false;
  String _lastWords = '';
  bool _isListening = false;
  ScheduleData? _detectedSchedule;
  bool _isAddingSchedule = false;
  String? _apiResult;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  /// 음성 인식 초기화
  Future<void> _initSpeech() async {
    // 마이크 권한 확인
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }

    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  /// 음성 인식 시작
  Future<void> _startListening() async {
    if (!_speechEnabled) {
      await _initSpeech();
    }

    if (_speechEnabled) {
      setState(() {
        _isListening = true;
      });

      // 현재 설정된 언어 가져오기
      if (!mounted) return;
      final languageProvider = Provider.of<LanguageProvider>(
        context,
        listen: false,
      );
      final localeId = languageProvider.speechLocaleId;

      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30), // 30초 동안 듣기
        pauseFor: const Duration(seconds: 3), // 3초 무음시 정지
        localeId: localeId, // 설정된 언어 사용
        listenOptions: SpeechListenOptions(
          partialResults: true, // 실시간 결과 표시
          cancelOnError: true,
          listenMode: ListenMode.confirmation,
        ),
      );
    }
  }

  /// 음성 인식 정지
  Future<void> _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  /// 음성 인식 결과 처리
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
      // 스케줄 관련 텍스트인지 분석
      _detectedSchedule = _analyzeScheduleFromText(_lastWords);
    });
  }

  /// 텍스트에서 스케줄 정보 추출
  ScheduleData? _analyzeScheduleFromText(String text) {
    if (text.isEmpty) return null;

    // 텍스트를 소문자로 변환하여 대소문자 구분 없이 검색
    final lowerText = text.toLowerCase();

    // 스케줄 관련 키워드가 있는지 확인 (한국어 + 영어)
    final scheduleKeywords = [
      // 한국어
      '일정', '약속', '미팅', '과외', '수업', '회의', '만남',
      // 영어
      'meeting', 'appointment', 'class', 'lesson', 'tutoring', 'session',
      'conference', 'schedule', 'event', 'gathering', 'date', 'interview',
    ];
    bool hasScheduleKeyword = scheduleKeywords.any(
      (keyword) => lowerText.contains(keyword.toLowerCase()),
    );

    // 시간 관련 키워드가 있는지 확인 (한국어 + 영어)
    final timeKeywords = [
      // 한국어
      '시', '분', '오전', '오후', '아침', '점심', '저녁', '밤',
      // 영어
      'o\'clock', 'hour', 'minute', 'am', 'pm', 'a.m.', 'p.m.',
      'morning', 'afternoon', 'evening', 'night', 'noon', 'midnight',
    ];
    bool hasTimeKeyword = timeKeywords.any(
      (keyword) => lowerText.contains(keyword.toLowerCase()),
    );

    // 날짜 관련 키워드가 있는지 확인 (한국어 + 영어)
    final dateKeywords = [
      // 한국어
      '오늘', '내일', '모레', '이번', '다음', '월', '화', '수', '목', '금', '토', '일',
      // 영어
      'today', 'tomorrow', 'yesterday', 'this', 'next', 'monday', 'tuesday',
      'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
      'week', 'month', 'day',
    ];
    bool hasDateKeyword = dateKeywords.any(
      (keyword) => lowerText.contains(keyword.toLowerCase()),
    );

    if (!hasScheduleKeyword && !hasTimeKeyword && !hasDateKeyword) {
      return null; // 스케줄과 관련없는 텍스트
    }

    // 날짜 정보 추출
    String date = _extractDate(text);

    // 시간 정보 추출
    String time = _extractTime(text);

    // 제목 정보 추출 (간단한 키워드 기반)
    String title = _extractTitle(text);

    // 카테고리 추출
    String category = _extractCategory(text);

    return ScheduleData(
      title: title,
      date: date,
      time: time,
      category: category,
      description: text,
    );
  }

  /// 날짜 정보 추출 (한국어 + 영어 지원)
  String _extractDate(String text) {
    final lowerText = text.toLowerCase();

    // 한국어 날짜 패턴
    if (text.contains('오늘') || lowerText.contains('today')) {
      return DateTime.now().toString().split(' ')[0]; // YYYY-MM-DD 형식
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

    // 영어 요일 패턴 처리
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

    // 기본값은 오늘
    return DateTime.now().toString().split(' ')[0];
  }

  /// 다음 특정 요일 날짜 계산
  DateTime _getNextWeekday(DateTime from, int targetWeekday) {
    final currentWeekday = from.weekday;
    int daysToAdd = targetWeekday - currentWeekday;

    // 만약 오늘이 목표 요일이거나 이미 지났다면 다음 주로
    if (daysToAdd <= 0) {
      daysToAdd += 7;
    }

    return from.add(Duration(days: daysToAdd));
  }

  /// 시간 정보 추출 (한국어 + 영어 지원)
  String _extractTime(String text) {
    final lowerText = text.toLowerCase();

    // 한국어 시간 패턴 매칭 (예: "4시", "오후 2시", "14시 30분")
    RegExp koreanTimePattern = RegExp(r'(\d{1,2})시(\s*(\d{1,2})분)?');
    Match? koreanMatch = koreanTimePattern.firstMatch(text);

    if (koreanMatch != null) {
      int hour = int.parse(koreanMatch.group(1) ?? '0');
      int minute = int.parse(koreanMatch.group(3) ?? '0');

      // 오후인지 확인
      if (text.contains('오후') && hour < 12) {
        hour += 12;
      }

      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }

    // 영어 시간 패턴 매칭
    // 패턴 1: "2pm", "3am", "12 pm"
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
        hour = 0; // 12am = 00:00
      }

      return '${hour.toString().padLeft(2, '0')}:00';
    }

    // 패턴 2: "3:30", "14:45", "2:15 pm"
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

    // 패턴 3: "2 o'clock", "three o'clock" - 간단한 처리
    if (lowerText.contains('oclock')) {
      // 숫자 + o'clock 패턴 찾기
      final words = lowerText.split(' ');
      for (int i = 0; i < words.length - 1; i++) {
        if (words[i + 1].contains('oclock')) {
          final hourStr = words[i];
          final hour = int.tryParse(hourStr);
          if (hour != null && hour >= 1 && hour <= 12) {
            int finalHour = hour;
            // 오후인지 확인
            if (lowerText.contains('afternoon') ||
                lowerText.contains('evening')) {
              if (finalHour < 12) finalHour += 12;
            }
            return '${finalHour.toString().padLeft(2, '0')}:00';
          }
        }
      }
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

    return '09:00'; // 기본값
  }

  /// 제목 추출 (한국어 + 영어 지원)
  String _extractTitle(String text) {
    final lowerText = text.toLowerCase();

    // 교육 관련
    if (text.contains('과외') || lowerText.contains('tutoring')) return '과외';
    if (text.contains('수업') ||
        lowerText.contains('class') ||
        lowerText.contains('lesson'))
      return '수업';
    if (lowerText.contains('study') || lowerText.contains('homework'))
      return '공부';

    // 업무 관련
    if (text.contains('미팅') ||
        text.contains('회의') ||
        lowerText.contains('meeting'))
      return '회의';
    if (lowerText.contains('conference') || lowerText.contains('presentation'))
      return '컨퍼런스';
    if (lowerText.contains('interview')) return '인터뷰';
    if (lowerText.contains('work') || lowerText.contains('project'))
      return '업무';

    // 개인 관련
    if (text.contains('약속') || lowerText.contains('appointment')) return '약속';
    if (text.contains('만남') ||
        lowerText.contains('date') ||
        lowerText.contains('gathering'))
      return '만남';
    if (lowerText.contains('dinner') ||
        lowerText.contains('lunch') ||
        lowerText.contains('meal'))
      return '식사';
    if (lowerText.contains('exercise') ||
        lowerText.contains('gym') ||
        lowerText.contains('workout'))
      return '운동';

    // 의료 관련
    if (lowerText.contains('doctor') ||
        lowerText.contains('hospital') ||
        lowerText.contains('clinic'))
      return '병원';
    if (lowerText.contains('dentist')) return '치과';

    // 쇼핑/외출
    if (lowerText.contains('shopping') || lowerText.contains('buy'))
      return '쇼핑';
    if (lowerText.contains('movie') || lowerText.contains('cinema'))
      return '영화';

    return lowerText.contains('meeting') ||
            lowerText.contains('appointment') ||
            lowerText.contains('class') ||
            lowerText.contains('session')
        ? 'Schedule'
        : '일정'; // 기본값
  }

  /// 카테고리 추출 (한국어 + 영어 지원)
  String _extractCategory(String text) {
    final lowerText = text.toLowerCase();

    // 교육 카테고리
    if (text.contains('과외') ||
        text.contains('수업') ||
        lowerText.contains('tutoring') ||
        lowerText.contains('class') ||
        lowerText.contains('lesson') ||
        lowerText.contains('study') ||
        lowerText.contains('homework') ||
        lowerText.contains('exam')) {
      return '교육';
    }

    // 업무 카테고리
    if (text.contains('미팅') ||
        text.contains('회의') ||
        lowerText.contains('meeting') ||
        lowerText.contains('conference') ||
        lowerText.contains('presentation') ||
        lowerText.contains('interview') ||
        lowerText.contains('work') ||
        lowerText.contains('project') ||
        lowerText.contains('office')) {
      return '업무';
    }

    // 의료 카테고리
    if (lowerText.contains('doctor') ||
        lowerText.contains('hospital') ||
        lowerText.contains('clinic') ||
        lowerText.contains('dentist') ||
        lowerText.contains('medical') ||
        lowerText.contains('checkup')) {
      return '의료';
    }

    // 운동/건강 카테고리
    if (lowerText.contains('exercise') ||
        lowerText.contains('gym') ||
        lowerText.contains('workout') ||
        lowerText.contains('fitness') ||
        lowerText.contains('yoga') ||
        lowerText.contains('sport')) {
      return '운동';
    }

    // 쇼핑 카테고리
    if (lowerText.contains('shopping') ||
        lowerText.contains('buy') ||
        lowerText.contains('store') ||
        lowerText.contains('mall')) {
      return '쇼핑';
    }

    // 엔터테인먼트 카테고리
    if (lowerText.contains('movie') ||
        lowerText.contains('cinema') ||
        lowerText.contains('theater') ||
        lowerText.contains('concert') ||
        lowerText.contains('show') ||
        lowerText.contains('entertainment')) {
      return '오락';
    }

    // 개인 카테고리 (기본)
    if (text.contains('약속') ||
        text.contains('만남') ||
        lowerText.contains('appointment') ||
        lowerText.contains('date') ||
        lowerText.contains('gathering') ||
        lowerText.contains('dinner') ||
        lowerText.contains('lunch') ||
        lowerText.contains('meal') ||
        lowerText.contains('friend') ||
        lowerText.contains('family')) {
      return '개인';
    }

    return '기타'; // 기본값
  }

  /// 스케줄 추가 API 호출
  Future<void> _addScheduleToServer() async {
    if (_detectedSchedule == null) return;

    setState(() {
      _isAddingSchedule = true;
      _apiResult = null;
    });

    try {
      final result = await _scheduleApiService.addSchedule(_detectedSchedule!);

      setState(() {
        _apiResult = result['success']
            ? '✅ ${result['message']}'
            : '❌ ${result['message']}';
      });

      if (result['success']) {
        // 성공 시 스낵바 표시
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _apiResult = '❌ 스케줄 추가 중 오류가 발생했습니다: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isAddingSchedule = false;
      });
    }
  }

  /// 스케줄 정보 행 위젯 생성
  Widget _buildScheduleInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '음성 인식',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '언어: ${languageProvider.displayName}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
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
              const SizedBox(height: 20),
              // 음성 인식 상태 표시
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _speechEnabled
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _speechEnabled ? Colors.green : Colors.red,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _speechEnabled ? Icons.mic : Icons.mic_off,
                      color: _speechEnabled ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _speechEnabled ? '음성 인식 사용 가능' : '음성 인식 사용 불가',
                      style: TextStyle(
                        color: _speechEnabled ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 인식된 텍스트 표시
              Container(
                width: double.infinity,
                height: 150,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '인식된 텍스트:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          _lastWords.isEmpty
                              ? '음성을 인식하면 여기에 표시됩니다.'
                              : _lastWords,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: _lastWords.isEmpty
                                    ? Colors.grey
                                    : Colors.black,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 스케줄 분석 결과 표시
              if (_detectedSchedule != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.event, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          Text(
                            '스케줄 인식됨',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 분석된 스케줄 정보
                      _buildScheduleInfoRow('제목', _detectedSchedule!.title),
                      _buildScheduleInfoRow('날짜', _detectedSchedule!.date),
                      _buildScheduleInfoRow('시간', _detectedSchedule!.time),
                      _buildScheduleInfoRow(
                        '카테고리',
                        _detectedSchedule!.category,
                      ),

                      const SizedBox(height: 16),

                      // add-schedule 함수 호출 예시
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'add-schedule 함수 호출 예시:',
                              style: TextStyle(
                                color: Colors.green[300],
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'addSchedule({\n'
                              '  "title": "${_detectedSchedule!.title}",\n'
                              '  "date": "${_detectedSchedule!.date}",\n'
                              '  "time": "${_detectedSchedule!.time}",\n'
                              '  "category": "${_detectedSchedule!.category}",\n'
                              '  "description": "${_detectedSchedule!.description}"\n'
                              '})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'monospace',
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 스케줄 추가 버튼
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isAddingSchedule
                              ? null
                              : _addScheduleToServer,
                          icon: _isAddingSchedule
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.add_circle_outline),
                          label: Text(
                            _isAddingSchedule ? '추가 중...' : '스케줄 추가하기',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),

                      // API 결과 표시
                      if (_apiResult != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _apiResult!.startsWith('✅')
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _apiResult!.startsWith('✅')
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          child: Text(
                            _apiResult!,
                            style: TextStyle(
                              color: _apiResult!.startsWith('✅')
                                  ? Colors.green[700]
                                  : Colors.red[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              const SizedBox(height: 30),

              // 음성 인식 버튼
              Column(
                children: [
                  if (_isListening)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.hearing, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            '듣고 있습니다...',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 시작 버튼
                      ElevatedButton.icon(
                        onPressed: _speechEnabled && !_isListening
                            ? _startListening
                            : null,
                        icon: const Icon(Icons.mic),
                        label: const Text('음성 인식 시작'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),

                      // 정지 버튼
                      ElevatedButton.icon(
                        onPressed: _isListening ? _stopListening : null,
                        icon: const Icon(Icons.stop),
                        label: const Text('정지'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 텍스트 초기화 버튼
                  TextButton.icon(
                    onPressed:
                        _lastWords.isNotEmpty ||
                            _detectedSchedule != null ||
                            _apiResult != null
                        ? () {
                            setState(() {
                              _lastWords = '';
                              _detectedSchedule = null;
                              _apiResult = null;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.clear),
                    label: const Text('전체 지우기'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _speechToText.stop();
    super.dispose();
  }
}
