 // lib/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _db;
  UserService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  /// 유저 생성, 생성된 documentId 반환
  Future<String> createUser({required String name}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('name is empty');
    }

    try {
      final docRef = await _db.collection('users').add({
        'name': trimmed,
        'joinDate': FieldValue.serverTimestamp(),
        'isOnboarded': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } on FirebaseException catch (e) {
      // 필요하면 코드별 매핑
      // e.code: 'permission-denied', 'unavailable', ...
      rethrow;
    } catch (_) {
      rethrow;
    }
  }

  /// (선택) auth를 쓰는 경우 uid로 문서 고정 생성
  Future<void> upsertUserWithUid({
    required String uid,
    required String name,
  }) async {
    await _db.collection('users').doc(uid).set({
      'name': name.trim(),
      'isOnboarded': false,
      'createdAt': FieldValue.serverTimestamp(),
      'joinDate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}