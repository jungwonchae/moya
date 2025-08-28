// lib/services/notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moya_app/models/notification_item.dart';


class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _getUserNotifications(String userId) {
    return _firestore.collection('notifications').doc(userId).collection('items');
  }

  /// 새 알림 생성
  Future<String> createNotification({
    required String userId,
    required String title,
    required String message,
    NotificationType type = NotificationType.normal,
    Map<String, dynamic>? relatedData,
  }) async {
    // createdAt은 서버 시간 추천
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

  /// 사용자의 모든 알림 가져오기 (최신순)
  Stream<List<NotificationItem>> getUserNotifications(String userId) {
    return _getUserNotifications(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationItem.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// 알림 읽음 상태 변경
  Future<void> markAsRead(String userId, String notificationId, bool isRead) {
    return _getUserNotifications(userId).doc(notificationId).update({'isRead': isRead});
  }

  /// 알림 삭제
  Future<void> deleteNotification(String userId, String notificationId) {
    return _getUserNotifications(userId).doc(notificationId).delete();
  }

  /// 읽지 않은 알림 개수
  Future<int> getUnreadCount(String userId) async {
    final snapshot =
        await _getUserNotifications(userId).where('isRead', isEqualTo: false).get();
    return snapshot.docs.length;
  }

  /// 생리대 교체 알림 생성 (특화 메서드)
  Future<void> createPadChangeNotification({
    required String userId,
    required bool isWarning,
    required int changeCount,
    required double lastChangeHours,
  }) {
    final title = isWarning ? '생리대 교체 확인 필요' : '생리대 교체';
    final message = isWarning
        ? '흡수량이 높게 감지됐어요. 생리대 상태를 확인하고 필요하면 교체해 주세요.'
        : '정상적으로 교체가 기록되었어요. 수분 보충과 휴식도 잊지 마세요.';

    return createNotification(
      userId: userId,
      title: title,
      message: message,
      type: isWarning ? NotificationType.warning : NotificationType.normal,
      relatedData: {
        'changeCount': changeCount,
        'lastChangeHours': lastChangeHours,
        'recommendedInterval': '4~6시간',
      },
    );
  }
}