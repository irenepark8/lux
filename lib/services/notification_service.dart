import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../language_provider.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // 언어별 알림 메시지
  static const Map<String, Map<String, String>> _notificationMessages = {
    'ko-KR': {
      'title': '곧 마감되는 일정이 있어요!',
      'body': '놓치기 전에 확인해보세요.',
      'defaultBody': '새로운 알림이 도착했습니다.',
    },
    'en-US': {
      'title': 'You have a deadline approaching!',
      'body': 'Check it out before you miss it.',
      'defaultBody': 'You have a new notification.',
    },
  };

  // 현재 언어 설정 가져오기
  static Future<AppLanguage> _getCurrentLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('selected_language');

      if (languageCode != null) {
        for (AppLanguage lang in AppLanguage.values) {
          if (lang.localeId == languageCode) {
            return lang;
          }
        }
      }
      return AppLanguage.korean; // 기본값
    } catch (e) {
      print('언어 설정 로드 실패: $e');
      return AppLanguage.korean;
    }
  }

  // 언어에 맞는 알림 메시지 가져오기
  static Future<Map<String, String>> _getLocalizedNotificationMessage({
    String? originalTitle,
    String? originalBody,
  }) async {
    final currentLanguage = await _getCurrentLanguage();
    final messages =
        _notificationMessages[currentLanguage.localeId] ??
        _notificationMessages['ko-KR']!;

    return {
      'title': messages['title']!,
      'body': originalBody?.isNotEmpty == true
          ? originalBody!
          : messages['defaultBody']!,
    };
  }

  // 초기화
  static Future<void> initialize() async {
    try {
      print('🚀 Starting NotificationService initialization...');

      // Timezone 초기화
      tz.initializeTimeZones();
      print('✅ Timezone initialized');

      // Firebase 초기화
      await Firebase.initializeApp();
      print('✅ Firebase initialized');

      // Firebase 앱 정보 출력
      await _printFirebaseAppInfo();

      // iOS에서 APNS 설정 강제 대기
      if (Platform.isIOS) {
        print('📱 iOS detected - Starting APNS setup...');
        await _forceAPNSSetup();
      }

      // FCM 권한 요청
      print('🔐 Requesting FCM permissions...');
      await _requestPermission();

      // 로컬 알림 초기화
      print('📲 Initializing local notifications...');
      await _initializeLocalNotifications();

      // 백그라운드 메시지 핸들러 설정
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // 포그라운드 메시지 핸들러 설정
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 앱이 백그라운드에서 열렸을 때 핸들러
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // 앱이 종료된 상태에서 열렸을 때 초기 메시지 확인
      RemoteMessage? initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      print('🎉 NotificationService initialized successfully!');

      // 초기화 완료 후 토큰 테스트
      await _testTokenGeneration();
    } catch (e) {
      print('❌ Error initializing NotificationService: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  // Firebase 앱 정보 출력
  static Future<void> _printFirebaseAppInfo() async {
    try {
      final app = Firebase.app();
      print('📊 Firebase App Info:');
      print('   - App Name: ${app.name}');
      print('   - Project ID: ${app.options.projectId}');
      print('   - Bundle ID: ${app.options.iosBundleId}');
      print('   - API Key: ${app.options.apiKey.substring(0, 20)}...');
      print('   - Messaging Sender ID: ${app.options.messagingSenderId}');
    } catch (e) {
      print('❌ Error getting Firebase app info: $e');
    }
  }

  // 토큰 생성 테스트
  static Future<void> _testTokenGeneration() async {
    try {
      print('🧪 Testing FCM token generation...');

      // 권한 상태 확인
      final settings = await _firebaseMessaging.getNotificationSettings();
      print('   - Permission Status: ${settings.authorizationStatus}');
      print('   - Alert Setting: ${settings.alert}');
      print('   - Badge Setting: ${settings.badge}');
      print('   - Sound Setting: ${settings.sound}');

      if (Platform.isIOS) {
        // iOS APNS 토큰 확인
        try {
          final apnsToken = await _firebaseMessaging.getAPNSToken();
          if (apnsToken != null) {
            print('   - APNS Token: ${apnsToken.substring(0, 30)}...');
          } else {
            print('   - APNS Token: null ⚠️');
          }
        } catch (e) {
          print('   - APNS Token Error: $e');
        }
      }

      // FCM 토큰 시도
      try {
        final fcmToken = await _firebaseMessaging.getToken();
        if (fcmToken != null) {
          print('   - FCM Token: ${fcmToken.substring(0, 50)}... ✅');
        } else {
          print('   - FCM Token: null ❌');
        }
      } catch (e) {
        print('   - FCM Token Error: $e ❌');
      }
    } catch (e) {
      print('❌ Error in token generation test: $e');
    }
  }

  // 권한 요청
  static Future<void> _requestPermission() async {
    print('🔐 Requesting FCM permissions...');

    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('📋 Permission Results:');
    print('   - Authorization Status: ${settings.authorizationStatus}');
    print('   - Alert: ${settings.alert}');
    print('   - Badge: ${settings.badge}');
    print('   - Sound: ${settings.sound}');
    print('   - Announcement: ${settings.announcement}');
    print('   - Car Play: ${settings.carPlay}');
    print('   - Critical Alert: ${settings.criticalAlert}');

    // 로컬 알림 권한 요청 (Android 13+)
    if (await Permission.notification.isDenied) {
      print('📲 Requesting local notification permission...');
      final localPermission = await Permission.notification.request();
      print('   - Local Permission: $localPermission');
    }

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ FCM permissions granted successfully');
    } else {
      print(
        '⚠️ FCM permissions not fully granted: ${settings.authorizationStatus}',
      );
    }
  }

  // 로컬 알림 초기화
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    // Android 알림 채널 생성
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  // FCM 토큰 가져오기 (iOS APNS 호환)
  static Future<String?> getToken() async {
    try {
      // iOS에서 APNS 토큰을 먼저 설정
      if (Platform.isIOS) {
        // APNS 토큰이 설정될 때까지 대기
        await _waitForAPNSToken();
      }

      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('FCM Token successfully retrieved: ${token.substring(0, 50)}...');
      } else {
        print('FCM Token is null');
      }
      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  // iOS APNS 토큰 강제 설정 (iOS 전용)
  static Future<void> _forceAPNSSetup() async {
    try {
      print('📱 Starting iOS APNS token setup...');

      // 1. 권한 먼저 요청
      print('   🔐 Requesting APNS permissions...');
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      print('   📋 APNS Permission Status: ${settings.authorizationStatus}');

      // 2. APNS 토큰 강제 요청 및 대기
      int attempts = 0;
      const maxAttempts = 30; // 1초 * 30 = 30초

      print('   ⏳ Waiting for APNS token (max 30 seconds)...');

      while (attempts < maxAttempts) {
        try {
          final apnsToken = await _firebaseMessaging.getAPNSToken();
          if (apnsToken != null) {
            print(
              '   ✅ APNS Token successfully obtained: ${apnsToken.substring(0, 30)}...',
            );

            // APNS 토큰을 얻었으니 FCM 토큰도 테스트
            try {
              final fcmToken = await _firebaseMessaging.getToken();
              if (fcmToken != null) {
                print(
                  '   🎯 FCM Token also generated: ${fcmToken.substring(0, 50)}...',
                );
              } else {
                print('   ⚠️ APNS Token obtained but FCM Token still null');
              }
            } catch (e) {
              print('   ⚠️ Error getting FCM token after APNS: $e');
            }

            return;
          }
        } catch (e) {
          // APNS 토큰이 아직 준비되지 않음
          if (attempts % 5 == 0) {
            print(
              '   ⏳ Attempt ${attempts + 1}/$maxAttempts: APNS token not ready yet...',
            );
          }
        }

        await Future.delayed(const Duration(milliseconds: 1000));
        attempts++;

        // 10번째 시도마다 Firebase 재초기화
        if (attempts % 10 == 0) {
          print('   🔄 Re-requesting APNS permission (attempt $attempts)...');
          try {
            await _firebaseMessaging.requestPermission(
              alert: true,
              badge: true,
              sound: true,
            );
          } catch (e) {
            print('   ❌ Error re-requesting permission: $e');
          }
        }
      }

      print('   ⚠️ APNS token setup timeout after 30 seconds');
      print(
        '   💡 This might indicate Firebase Console APNs configuration issues',
      );
    } catch (e) {
      print('   ❌ Error in APNS setup: $e');
      print('   📋 Stack trace: ${StackTrace.current}');
    }
  }

  // iOS APNS 토큰 대기 (iOS 전용)
  static Future<void> _waitForAPNSToken() async {
    try {
      // APNS 토큰이 설정될 때까지 최대 10초 대기
      int attempts = 0;
      const maxAttempts = 20; // 0.5초 * 20 = 10초

      while (attempts < maxAttempts) {
        try {
          final apnsToken = await _firebaseMessaging.getAPNSToken();
          if (apnsToken != null) {
            print('APNS Token available: ${apnsToken.substring(0, 20)}...');
            return;
          }
        } catch (e) {
          // APNS 토큰이 아직 준비되지 않음
        }

        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
      }

      print('APNS token not available after waiting');
    } catch (e) {
      print('Error waiting for APNS token: $e');
    }
  }

  // 플랫폼별 안전한 토큰 가져오기
  static Future<String?> getTokenSafely() async {
    try {
      // 권한 확인
      final settings = await _firebaseMessaging.getNotificationSettings();
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        print('Notification permission not granted');
        return null;
      }

      // iOS의 경우 APNS 토큰 문제를 우회하는 방법 시도
      if (Platform.isIOS) {
        return await _getIOSTokenWithRetry();
      } else {
        // Android는 정상적으로
        return await getToken();
      }
    } catch (e) {
      print('Error in getTokenSafely: $e');
      return null;
    }
  }

  // iOS 전용 토큰 가져오기 (재시도 로직 포함)
  static Future<String?> _getIOSTokenWithRetry() async {
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        print('iOS FCM Token attempt $attempt/3...');

        // APNS 토큰 강제 확인
        try {
          final apnsToken = await _firebaseMessaging.getAPNSToken();
          if (apnsToken != null) {
            print('APNS Token confirmed: ${apnsToken.substring(0, 20)}...');
          } else {
            print('APNS Token is null, but continuing...');
          }
        } catch (e) {
          print('APNS Token check failed: $e');
          // APNS 문제가 있어도 계속 진행
        }

        // FCM 토큰 요청
        final fcmToken = await _firebaseMessaging.getToken();
        if (fcmToken != null) {
          print(
            '✅ iOS FCM Token success on attempt $attempt: ${fcmToken.substring(0, 50)}...',
          );
          return fcmToken;
        }

        print('⚠️ FCM Token is null on attempt $attempt');
      } catch (e) {
        print('❌ iOS FCM Token attempt $attempt failed: $e');

        if (attempt == 3) {
          // 마지막 시도에서도 실패하면 null 반환
          print('🔴 All iOS FCM Token attempts failed');
          return null;
        }
      }

      // 다음 시도 전에 잠시 대기
      await Future.delayed(Duration(seconds: attempt * 2));
    }

    return null;
  }

  // 백그라운드 메시지 핸들러
  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    await Firebase.initializeApp();
    print('Handling a background message: ${message.messageId}');
    // 여기서 백그라운드 알림 처리
  }

  // 포그라운드 메시지 핸들러
  static void _handleForegroundMessage(RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');
    print('Message notification: ${message.notification}');
    print('Message title: ${message.notification?.title}');
    print('Message body: ${message.notification?.body}');

    if (message.notification != null) {
      print('Showing local notification...');

      // 1. 로컬 알림 표시 (기존 방식)
      _showLocalNotificationAsync(message);

      // 2. 포그라운드 인앱 알림 표시 (새로운 방식)
      _showForegroundInAppNotification(message);
    } else {
      print('No notification data found in message');
    }
  }

  // 포그라운드에서 인앱 알림 표시
  static void _showForegroundInAppNotification(RemoteMessage message) {
    _showForegroundInAppNotificationAsync(message);
  }

  // 비동기 포그라운드 알림 처리
  static Future<void> _showForegroundInAppNotificationAsync(
    RemoteMessage message,
  ) async {
    try {
      final context = MyApp.scaffoldMessengerKey.currentContext;
      if (context != null && message.notification != null) {
        final notification = message.notification!;

        // 언어에 맞는 알림 메시지 가져오기
        final localizedMessage = await _getLocalizedNotificationMessage(
          originalTitle: notification.title,
          originalBody: notification.body,
        );

        _showTopNotificationOverlay(
          context: context,
          title: localizedMessage['title']!,
          body: localizedMessage['body']!,
          onTap: () => _handleNotificationTap(message.data),
        );

        print('✅ 포그라운드 상단 알림 표시됨 (${localizedMessage['title']})');
      } else {
        print('⚠️ Context를 찾을 수 없음');
      }
    } catch (e) {
      print('❌ 포그라운드 인앱 알림 표시 실패: $e');
    }
  }

  // 상단 슬라이드 알림 오버레이
  static void _showTopNotificationOverlay({
    required BuildContext context,
    required String title,
    required String body,
    required VoidCallback onTap,
  }) {
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _TopNotificationWidget(
        title: title,
        body: body,
        onTap: () {
          onTap();
          overlayEntry.remove();
        },
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    // 8초 후 자동 제거
    Future.delayed(const Duration(seconds: 8), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  // 앱이 백그라운드에서 열렸을 때 메시지 처리
  static void _handleMessageOpenedApp(RemoteMessage message) {
    print('A new onMessageOpenedApp event was published!');
    // 알림을 탭했을 때의 동작 처리
    _handleNotificationTap(message.data);
  }

  // 로컬 알림 표시 (언어 지원)
  static void _showLocalNotificationAsync(RemoteMessage message) {
    _showLocalNotificationWithLanguage(message);
  }

  // 언어에 맞는 로컬 알림 표시
  static Future<void> _showLocalNotificationWithLanguage(
    RemoteMessage message,
  ) async {
    try {
      // 언어에 맞는 알림 메시지 가져오기
      final localizedMessage = await _getLocalizedNotificationMessage(
        originalTitle: message.notification?.title,
        originalBody: message.notification?.body,
      );

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            ticker: 'ticker',
          );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _localNotifications.show(
        message.hashCode,
        localizedMessage['title'],
        localizedMessage['body'],
        platformChannelSpecifics,
        payload: jsonEncode(message.data),
      );

      print('✅ 로컬 알림 표시됨 (${localizedMessage['title']})');
    } catch (e) {
      print('❌ 로컬 알림 표시 실패: $e');
      // 실패 시 기본 알림 표시
      _showLocalNotificationFallback(message);
    }
  }

  // 기본 로컬 알림 표시 (백업용)
  static Future<void> _showLocalNotificationFallback(
    RemoteMessage message,
  ) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'ticker',
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );
  }

  // 로컬 알림 클릭 처리
  static void _onDidReceiveNotificationResponse(NotificationResponse response) {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      _handleNotificationTap(data);
    }
  }

  // 알림 탭 처리
  static void _handleNotificationTap(Map<String, dynamic> data) {
    print('Notification tapped with data: $data');
    // 여기서 특정 화면으로 이동하거나 액션 수행
    // 예: Navigator.pushNamed(context, '/specific-screen');
  }

  // 토픽 구독
  static Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  // 토픽 구독 해제
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }

  // 로컬 알림 직접 표시 (앱 내에서 사용)
  static Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.high,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  // 예약된 알림 (스케줄 기능용)
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    Map<String, dynamic>? data,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'scheduled_notifications',
          'Scheduled Notifications',
          channelDescription: 'Notifications for scheduled tasks',
          importance: Importance.high,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    // DateTime을 TZDateTime으로 변환
    final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(
      scheduledDate,
      tz.local,
    );

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDate,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  // 알림 취소
  static Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  // 모든 알림 취소
  static Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }
}

// 상단 알림 위젯
class _TopNotificationWidget extends StatefulWidget {
  final String title;
  final String body;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _TopNotificationWidget({
    required this.title,
    required this.body,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  _TopNotificationWidgetState createState() => _TopNotificationWidgetState();
}

class _TopNotificationWidgetState extends State<_TopNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: () {
                    _dismiss();
                    widget.onTap();
                  },
                  onVerticalDragUpdate: (details) {
                    if (details.delta.dy < -5) {
                      _dismiss();
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[600]!, Colors.blue[700]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.notifications_active,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.body.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  widget.body,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _dismiss,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
