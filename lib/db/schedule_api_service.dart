import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'app_http_client.dart';

// 스케줄 데이터 모델
class ScheduleData {
  final String? id;
  final String? userId;
  final String title;
  final String date;
  final String time;
  final String category;
  final String description;
  final String? createdAt;
  final String? updatedAt;

  ScheduleData({
    this.id,
    this.userId,
    required this.title,
    required this.date,
    required this.time,
    required this.category,
    required this.description,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date': date,
      'time': time,
      'category': category,
      'description': description,
    };
  }

  factory ScheduleData.fromJson(Map<String, dynamic> json) {
    return ScheduleData(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class ScheduleApiService {
  // Supabase Function URL - .env 파일이 없는 경우 기본값 사용
  final String baseUrl =
      dotenv.env['SUPABASE_FUNCTION_URL'] ??
      'https://fratbzhsgiiyggfrdqpk.supabase.co/functions/v1';
  final String token =
      dotenv.env['SUPABASE_ANON_KEY'] ??
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZyYXRiemhzZ2lpeWdnZnJkcXBrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIyMTQ1MTgsImV4cCI6MjA2Nzc5MDUxOH0.FsRC0wTUVrA7JgSk1S25NnCshVFoGRaCgJQNKwE97RI';
  final AppHttpClient _http = AppHttpClient();

  // 스케줄 API 엔드포인트
  String get scheduleUrl => '$baseUrl/test-schedule';
  String get editScheduleUrl => '$baseUrl/edit-schedule';
  String get deleteScheduleUrl => '$baseUrl/delete-schedule';

  /// 스케줄 추가
  Future<Map<String, dynamic>> addSchedule(ScheduleData scheduleData) async {
    try {
      final url = Uri.parse(scheduleUrl);

      print('📅 스케줄 추가 요청: $url');
      print('📄 데이터: ${json.encode(scheduleData.toJson())}');

      final response = await _http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(scheduleData.toJson()),
      );

      print('📡 응답 상태: ${response.statusCode}');
      print('📡 응답 본문: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': '스케줄이 성공적으로 추가되었습니다.',
          'data': responseData,
        };
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 스케줄 추가 오류: $e');
      return {
        'success': false,
        'message': '스케줄 추가에 실패했습니다: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  /// 스케줄 목록 조회
  Future<List<ScheduleData>> fetchSchedules({String? date}) async {
    try {
      // URL 구성 (날짜 필터링 지원)
      String url = scheduleUrl;
      if (date != null) {
        url += '?date=$date';
      }

      print('📅 스케줄 조회 요청: $url');

      final response = await _http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 응답 상태: ${response.statusCode}');
      print('📡 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // API 응답 구조에 따른 데이터 추출
        if (responseData['success'] == true &&
            responseData['schedules'] != null) {
          final List<dynamic> schedulesJson = responseData['schedules'];
          return schedulesJson
              .map((json) => ScheduleData.fromJson(json))
              .toList();
        } else {
          print('📅 스케줄 목록이 비어있습니다.');
          return [];
        }
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 스케줄 조회 오류: $e');
      throw Exception('스케줄 조회에 실패했습니다: ${e.toString()}');
    }
  }

  /// 스케줄 수정 (새로운 전용 API 사용)
  Future<Map<String, dynamic>> updateSchedule(
    String id,
    ScheduleData scheduleData,
  ) async {
    try {
      final url = Uri.parse(editScheduleUrl);

      // ID와 함께 수정할 데이터 구성
      final requestData = {'id': id, ...scheduleData.toJson()};

      print('📅 스케줄 수정 요청: $url');
      print('📄 데이터: ${json.encode(requestData)}');

      final response = await _http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestData),
      );

      print('📡 응답 상태: ${response.statusCode}');
      print('📡 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return {
            'success': true,
            'message': responseData['message'] ?? '스케줄이 성공적으로 수정되었습니다.',
            'data': responseData['schedule'],
          };
        } else {
          throw Exception(responseData['error'] ?? '수정에 실패했습니다.');
        }
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 스케줄 수정 오류: $e');
      return {
        'success': false,
        'message': '스케줄 수정에 실패했습니다: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  /// 스케줄 삭제 (새로운 전용 API 사용)
  Future<Map<String, dynamic>> deleteSchedule(String id) async {
    try {
      final url = Uri.parse(deleteScheduleUrl);

      print('📅 스케줄 삭제 요청: $url');
      print('📄 삭제할 ID: $id');

      final response = await _http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'id': id}),
      );

      print('📡 응답 상태: ${response.statusCode}');
      print('📡 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return {
            'success': true,
            'message': responseData['message'] ?? '스케줄이 성공적으로 삭제되었습니다.',
            'data': responseData['deletedSchedule'],
          };
        } else {
          throw Exception(responseData['error'] ?? '삭제에 실패했습니다.');
        }
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 스케줄 삭제 오류: $e');
      return {
        'success': false,
        'message': '스케줄 삭제에 실패했습니다: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }
}
