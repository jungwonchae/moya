import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { normal, warning }

class NotificationItem {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? relatedData;

  NotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.relatedData,
  });

  factory NotificationItem.fromMap(
  String id,
  Map<String, dynamic> data,
  ) {
    final t = (data['type'] as String?) ?? 'normal';
    final ts = data['createdAt'];
    final dt = ts is Timestamp ? ts.toDate() : DateTime.now();

    return NotificationItem(
      id: id,
      userId: (data['userId'] as String?) ?? '',
      title: (data['title'] as String?) ?? '',
      message: (data['message'] as String?) ?? '',
      type: t == 'warning' ? NotificationType.warning : NotificationType.normal,
      isRead: (data['isRead'] as bool?) ?? false,
      createdAt: dt,
      relatedData: (data['relatedData'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type == NotificationType.warning ? 'warning' : 'normal',
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'relatedData': relatedData ?? {},
    };
  }
}