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

  // 사용자 이름 가져오기 (홈 화면에서 사용)
  Future<String?> getUserName(String userId) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['name'] as String?;
      }
      return null;
    } on FirebaseException catch (e) {
      print('사용자 이름 조회 실패: ${e.code} ${e.message}');
      return null;
    } catch (e) {
      print('사용자 이름 조회 실패: $e');
      return null;
    }
  }
  
  // 사용자 정보 전체 가져오기
  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return {
          'userId': userId,
          ...userData,
        };
      }
      return null;
    } on FirebaseException catch (e) {
      print('사용자 정보 조회 실패: ${e.code} ${e.message}');
      return null;
    } catch (e) {
      print('사용자 정보 조회 실패: $e');
      return null;
    }
  }
}