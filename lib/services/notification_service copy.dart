// lib/services/notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:moya_app/models/notification_item.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
  }

  Future<void> showLocalBanner({
    required String title,
    String body = '', // ← 폰 배너에 본문 비우고 싶으면 그냥 '' 유지
  }) async {
    const android = AndroidNotificationDetails(
      'moya_channel', 'MOYA Alerts',
      channelDescription: 'MOYA sensor alerts',
      importance: Importance.max,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );

    await _plugin.show(
      0,
      title,
      body,
      const NotificationDetails(android: android, iOS: ios),
    );
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
    final data = {
      'title': title,
      'message': message,
      'type': type == NotificationType.warning ? 'warning' : 'normal',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'relatedData': relatedData ?? {},
    };
    final docRef = await _getUserNotifications(userId).add(data);
    return docRef.id;
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

  // 기존 메서드들 그대로 유지 ...

  /// ✅ 분리 버전: 폰 배너에는 `nick`만, 앱 내 알림에는 `nick` + `message`
  Future<void> notifyNeedFlowSplit({
    required String userId,
    required String nick,
    required String message,                 // 앱 내 알림 본문
    Map<String, dynamic>? relatedData,
  }) async {
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
  }
}