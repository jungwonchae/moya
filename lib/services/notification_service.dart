// lib/services/notification_service.dart
import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:moya_app/models/notification_item.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    debugPrint('[NotificationService] 초기화 시작');
    
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
    debugPrint('[NotificationService] 플러그인 초기화 완료');

    // Android 채널 등록 및 권한 요청
    if (Platform.isAndroid) {
      await _setupAndroidNotifications();
    }
    
    debugPrint('[NotificationService] 초기화 완료');
  }

  Future<void> _setupAndroidNotifications() async {
    debugPrint('[NotificationService] Android 알림 설정 시작');
    
    // 채널 등록
    const channel = AndroidNotificationChannel(
      'moya_channel',
      'MOYA Alerts',
      description: 'MOYA sensor alerts',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      // 채널 생성
      await androidPlugin.createNotificationChannel(channel);
      debugPrint('[NotificationService] 알림 채널 생성 완료');
      
      // Android 13+ 권한 요청
      final permissionGranted = await androidPlugin.requestNotificationsPermission();
      debugPrint('[NotificationService] 알림 권한 요청 결과: $permissionGranted');
      
      // 추가 권한 체크
      final exactAlarmPermission = await androidPlugin.requestExactAlarmsPermission();
      debugPrint('[NotificationService] 정확한 알람 권한: $exactAlarmPermission');
    }
  }

  Future<void> showLocalBanner({
    required String title,
    String body = '',
  }) async {
    debugPrint('[NotificationService] showLocalBanner 호출: title="$title", body="$body"');
    
    try {
      const android = AndroidNotificationDetails(
        'moya_channel', 
        'MOYA Alerts',
        channelDescription: 'MOYA sensor alerts',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        autoCancel: true,
        // 알림 스타일 추가
        styleInformation: BigTextStyleInformation(''),
      );
      
      const ios = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      );

      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000), // 고유 ID
        title,
        body,
        const NotificationDetails(android: android, iOS: ios),
      );
      
      debugPrint('[NotificationService] 로컬 알림 전송 완료');
    } catch (e) {
      debugPrint('[NotificationService] 로컬 알림 실패: $e');
      debugPrint('[NotificationService] 스택 트레이스: ${StackTrace.current}');
    }
  }

  CollectionReference<Map<String, dynamic>> _getUserNotifications(String userId) {
    return _firestore.collection('notifications').doc(userId).collection('items');
  }

  Future<String> createNotification({
    required String userId,
    required String title,
    required String message,
    NotificationType type = NotificationType.normal,
    Map<String, dynamic>? relatedData,
  }) async {
    debugPrint('[NotificationService] 앱 내 알림 생성: userId=$userId, title="$title"');
    
    try {
      final data = {
        'title': title,
        'message': message,
        'type': type == NotificationType.warning ? 'warning' : 'normal',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'relatedData': relatedData ?? {},
      };
      
      final docRef = await _getUserNotifications(userId).add(data);
      debugPrint('[NotificationService] 앱 내 알림 생성 완료: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('[NotificationService] 앱 내 알림 생성 실패: $e');
      rethrow;
    }
  }

  Stream<List<NotificationItem>> getUserNotifications(String userId) {
    return _getUserNotifications(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => NotificationItem.fromMap(d.id, d.data())).toList());
  }

  Future<void> markAsRead(String userId, String notificationId, bool isRead) {
    return _getUserNotifications(userId).doc(notificationId).update({'isRead': isRead});
  }

  Future<void> deleteNotification(String userId, String notificationId) {
    return _getUserNotifications(userId).doc(notificationId).delete();
  }

  Future<int> getUnreadCount(String userId) async {
    final snapshot =
        await _getUserNotifications(userId).where('isRead', isEqualTo: false).get();
    return snapshot.docs.length;
  }

  /// ✅ 분리 버전: 폰 배너에는 `nick`만, 앱 내 알림에는 `nick` + `message`
  Future<void> notifyNeedFlowSplit({
    required String userId,
    required String nick,
    required String message,
    Map<String, dynamic>? relatedData,
  }) async {
    debugPrint('[NotificationService] notifyNeedFlowSplit 시작: userId=$userId, nick="$nick"');
    
    try {
      // 1) 폰 배너: title = nick, body 비우기
      await showLocalBanner(title: nick, body: '');
      
      // 2) 앱 내 알림: title = nick, message = 상세 메시지
      await createNotification(
        userId: userId,
        title: nick,
        message: message,
        type: NotificationType.warning,
        relatedData: relatedData,
      );
      
      debugPrint('[NotificationService] notifyNeedFlowSplit 완료');
    } catch (e) {
      debugPrint('[NotificationService] notifyNeedFlowSplit 실패: $e');
      rethrow;
    }
  }

  // 권한 상태 체크 메서드 (디버깅용)
  Future<void> checkNotificationPermissions() async {
    debugPrint('[NotificationService] 권한 상태 체크 시작');
    
    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        final areNotificationsEnabled = await androidPlugin.areNotificationsEnabled();
        debugPrint('[NotificationService] 알림 활성화 상태: $areNotificationsEnabled');
        
        try {
          final pendingNotifications = await _plugin.pendingNotificationRequests();
          debugPrint('[NotificationService] 대기 중인 알림 수: ${pendingNotifications.length}');
        } catch (e) {
          debugPrint('[NotificationService] 대기 알림 조회 실패: $e');
        }
      }
    }
  }
}