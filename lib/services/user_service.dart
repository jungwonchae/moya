// lib/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _db;
  UserService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  Future<void> createUserWithUid({required String uid, required String name}) async {
    await _db.collection('users').doc(uid).set({
      'name': name.trim(),
      'isOnboarded': false,
      'isAnonymous': true,
      'createdAt': FieldValue.serverTimestamp(),
      'joinDate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 권장: Auth UID로 users/{uid} upsert
  Future<void> upsertUserWithUid({
    required String uid,
    required String name,
    bool isAnonymous = true,
  }) async {
    await _db.collection('users').doc(uid).set({
      'name': name.trim(),
      'isOnboarded': false,
      'isAnonymous': isAnonymous,
      'createdAt': FieldValue.serverTimestamp(),
      'joinDate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 이름(또는 별명)만 업데이트
  Future<void> updateName({
    required String uid,
    required String name,
  }) async {
    await _db.collection('users').doc(uid).set({
      'name': name.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Users/{uid}에서 표시용 이름 가져오기
  /// 우선순위: nickname → 
  Future<String?> getUserName(String userId) async {
    try {
      final snap = await _db.collection('users').doc(userId).get();
      if (!snap.exists) return null;

      final data = snap.data(); // Map<String, dynamic>?
      if (data == null) return null;

      final name = (data?['name'] as String?)?.trim();
      return (name?.isNotEmpty == true) ? name : null;

    // 로그는 존재하는 필드만 출력 (없는 'userId' 접근 금지!)
    // debugPrint('users/$userId name=$name nickname=$nickname');
    } on FirebaseException catch (e) {
      print('이름 조회 실패: ${e.code} ${e.message}');
      return null;
    } catch (e) {
      print('이름 조회 실패: $e');
      return null;
    }
  }

  /// 사용자 전체 정보 가져오기
  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      final snap = await _db.collection('users').doc(userId).get();
      if (!snap.exists) return null;

      final data = snap.data() as Map<String, dynamic>?;
      if (data == null) return null;

      return {
        'userId': userId, // 문서 id를 명시적으로 포함
        ...data,
      };
    } on FirebaseException catch (e) {
      print('사용자 정보 조회 실패: ${e.code} ${e.message}');
      return null;
    } catch (e) {
      print('사용자 정보 조회 실패: $e');
      return null;
    }
  }

  /// 초깃값만 채우고 싶은 경우: 존재하지 않을 때만 joinDate를 설정
  Future<void> ensureUserDefaults(String uid) async {
    final ref = _db.collection('users').doc(uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'isOnboarded': false,
        'isAnonymous': true,
        'createdAt': FieldValue.serverTimestamp(),
        'joinDate': FieldValue.serverTimestamp(),
      });
      return;
    }
    // 이미 존재하면 joinDate 덮어쓰지 않음
    await ref.set({
      'isOnboarded': snap.data()?['isOnboarded'] ?? false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}