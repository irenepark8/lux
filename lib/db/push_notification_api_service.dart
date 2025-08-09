import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/notification_service.dart';

class PushNotificationApiService {
  // 백엔드 서버 URL
  static const String baseUrl = 'http://127.0.0.1:3002';
  
  // 단일 디바이스에 푸시 알림 전송
  static Future<Map<String, dynamic>> sendNotification({
    required String token,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send-notification'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': token,
          'title': title,
          'body': body,
          'data': data ?? {},
        }),
      );

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // 여러 디바이스에 푸시 알림 전송
  static Future<Map<String, dynamic>> sendNotificationToMultiple({
    required List<String> tokens,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send-notification-multiple'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'tokens': tokens,
          'title': title,
          'body': body,
          'data': data ?? {},
        }),
      );

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // 토픽으로 푸시 알림 전송
  static Future<Map<String, dynamic>> sendNotificationToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send-notification-topic'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'topic': topic,
          'title': title,
          'body': body,
          'data': data ?? {},
        }),
      );

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // 토픽 구독
  static Future<Map<String, dynamic>> subscribeToTopic({
    required List<String> tokens,
    required String topic,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/subscribe-topic'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'tokens': tokens,
          'topic': topic,
        }),
      );

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // 토픽 구독 해제
  static Future<Map<String, dynamic>> unsubscribeFromTopic({
    required List<String> tokens,
    required String topic,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/unsubscribe-topic'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'tokens': tokens,
          'topic': topic,
        }),
      );

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // 현재 디바이스의 FCM 토큰으로 자신에게 테스트 알림 전송
  static Future<Map<String, dynamic>> sendTestNotificationToSelf({
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      // 안전한 FCM 토큰 가져오기
      String? token = await NotificationService.getTokenSafely();
      
      if (token == null) {
        return {
          'success': false,
          'error': 'FCM token not available. iOS에서는 앱을 재시작해보세요.',
        };
      }

      print('Sending test notification to token: ${token.substring(0, 50)}...');

      return await sendNotification(
        token: token,
        title: title,
        body: body,
        data: data,
      );
    } catch (e) {
      return {
        'success': false,
        'error': 'Error getting FCM token: $e',
      };
    }
  }

  // FCM 토큰 가져오기 (편의 메서드)
  static Future<String?> getFCMToken() async {
    return await NotificationService.getTokenSafely();
  }

  // 서버 상태 확인
  static Future<Map<String, dynamic>> checkServerStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api-docs'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Server connection error: $e',
      };
    }
  }
}

// 푸시 알림 테스트용 헬퍼 클래스
class PushNotificationTestHelper {
  // 다양한 테스트 시나리오
  static Future<void> runAllTests() async {
    print('=== Push Notification Tests ===');
    
    // 1. 서버 상태 확인
    await testServerConnection();
    
    // 2. FCM 토큰 확인
    await testFCMToken();
    
    // 3. 자신에게 테스트 알림 전송
    await testSelfNotification();
    
    // 4. 토픽 구독 테스트
    await testTopicSubscription();
    
    print('=== Tests Completed ===');
  }

  static Future<void> testServerConnection() async {
    print('\n--- Testing Server Connection ---');
    final result = await PushNotificationApiService.checkServerStatus();
    print('Server Status: ${result['success'] ? 'Connected' : 'Failed'}');
    if (!result['success']) {
      print('Error: ${result['error']}');
    }
  }

  static Future<void> testFCMToken() async {
    print('\n--- Testing FCM Token ---');
    final token = await PushNotificationApiService.getFCMToken();
    if (token != null) {
      print('FCM Token: ${token.substring(0, 50)}...');
    } else {
      print('FCM Token: Not available');
    }
  }

  static Future<void> testSelfNotification() async {
    print('\n--- Testing Self Notification ---');
    final result = await PushNotificationApiService.sendTestNotificationToSelf(
      title: '테스트 알림',
      body: '푸시 알림 테스트가 성공적으로 전송되었습니다!',
      data: {
        'type': 'test',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    
    print('Test Notification: ${result['success'] ? 'Sent' : 'Failed'}');
    if (!result['success']) {
      print('Error: ${result['error']}');
    } else {
      print('Response: ${result['data']}');
    }
  }

  static Future<void> testTopicSubscription() async {
    print('\n--- Testing Topic Subscription ---');
    final token = await PushNotificationApiService.getFCMToken();
    
    if (token != null) {
      // 토픽 구독
      final subscribeResult = await PushNotificationApiService.subscribeToTopic(
        tokens: [token],
        topic: 'study_reminders',
      );
      
      print('Topic Subscription: ${subscribeResult['success'] ? 'Success' : 'Failed'}');
      
      if (subscribeResult['success']) {
        // 토픽으로 알림 전송
        final topicResult = await PushNotificationApiService.sendNotificationToTopic(
          topic: 'study_reminders',
          title: '공부 시간!',
          body: '영어 학습 시간입니다. 열심히 공부해봅시다!',
          data: {
            'type': 'study_reminder',
            'subject': 'english',
          },
        );
        
        print('Topic Notification: ${topicResult['success'] ? 'Sent' : 'Failed'}');
      }
    } else {
      print('Cannot test topic subscription: FCM token not available');
    }
  }
}