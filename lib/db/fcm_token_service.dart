import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';

class FCMTokenService {
  // Supabase URL
  static const String supabaseUrl = 'https://fratbzhsgiiyggfrdqpk.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZyYXRiemhzZ2lpeWdnZnJkcXBrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjAxNDk1NzQsImV4cCI6MjAzNTcyNTU3NH0.VXOhxBRAXSDgR6RsUeXWPTEMSmrWPVOYl6VqV8B2LQk';
  
  // 고정 사용자 ID (실제로는 인증 시스템에서 가져와야 함)
  static const String fixedUserId = '00000000-0000-0000-0000-000000000000';

  /// FCM 토큰을 Supabase에 저장/업데이트
  static Future<Map<String, dynamic>> saveToken() async {
    try {
      // FCM 토큰 가져오기
      final fcmToken = await NotificationService.getTokenSafely();
      if (fcmToken == null) {
        return {
          'success': false,
          'error': 'FCM token not available'
        };
      }

      // 플랫폼 감지
      String deviceType = 'unknown';
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        deviceType = 'ios';
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        deviceType = 'android';
      } else if (kIsWeb) {
        deviceType = 'web';
      }

      final response = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/fcm_tokens'),
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $anonKey',
          'Content-Type': 'application/json',
          'Prefer': 'resolution=merge-duplicates',
        },
        body: jsonEncode({
          'user_id': fixedUserId,
          'device_token': fcmToken,
          'device_type': deviceType,
          'app_version': '1.0.0',
          'device_info': {
            'platform': deviceType,
            'timestamp': DateTime.now().toIso8601String(),
          },
          'is_active': true,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ FCM Token saved to Supabase: ${fcmToken.substring(0, 50)}...');
        return {
          'success': true,
          'message': 'FCM token saved successfully',
          'token': fcmToken.substring(0, 50) + '...',
        };
      } else {
        print('❌ Failed to save FCM token: ${response.statusCode}');
        print('Response: ${response.body}');
        return {
          'success': false,
          'error': 'Failed to save token: ${response.statusCode}',
          'details': response.body,
        };
      }
    } catch (e) {
      print('❌ Error saving FCM token: $e');
      return {
        'success': false,
        'error': 'Error saving token: $e',
      };
    }
  }

  /// 저장된 FCM 토큰 목록 조회
  static Future<Map<String, dynamic>> getTokens() async {
    try {
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/fcm_tokens?user_id=eq.$fixedUserId&is_active=eq.true'),
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $anonKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> tokens = jsonDecode(response.body);
        return {
          'success': true,
          'tokens': tokens,
          'count': tokens.length,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch tokens: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error fetching tokens: $e',
      };
    }
  }

  /// 전체 유저에게 푸시 알림 전송 (Supabase Edge Function 호출)
  static Future<Map<String, dynamic>> sendBroadcastNotification({
    required String title,
    required String body,
    Map<String, String>? data,
    String targetType = 'all', // 'all', 'ios', 'android', 'web'
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$supabaseUrl/functions/v1/send-push-notification'),
        headers: {
          'Authorization': 'Bearer $anonKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': title,
          'body': body,
          'data': data ?? {},
          'target_type': targetType,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Broadcast notification sent successfully',
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to send broadcast: ${response.statusCode}',
          'details': responseData,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error sending broadcast: $e',
      };
    }
  }

  /// 토큰 비활성화
  static Future<Map<String, dynamic>> deactivateToken(String token) async {
    try {
      final response = await http.patch(
        Uri.parse('$supabaseUrl/rest/v1/fcm_tokens?device_token=eq.$token'),
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $anonKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'is_active': false,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {
          'success': true,
          'message': 'Token deactivated successfully',
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to deactivate token: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error deactivating token: $e',
      };
    }
  }
}