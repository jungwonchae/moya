import 'package:cloud_firestore/cloud_firestore.dart';

class PeriodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _col => _firestore.collection('periods');

  /// 날짜만 유지(시간 00:00:00)로 정규화
  DateTime _normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);

  // 생리 정보를 periods 컬렉션에 저장 (기존 메서드)
  Future<String?> savePeriodData({
    required String userId,
    required DateTime startDate,
    DateTime? endDate,
    int? cycleLength,
    int? periodLength,
    bool? isOnMedication,
    String? flow, // "적음", "보통", "많음"
    String? nick,
  }) async {
    try {
      final normalizedStart = _normalizeDate(startDate);

      // 기존처럼 랜덤 문서ID로 추가(현재 구조 유지)
      DocumentReference periodDoc = await _col.add({
        'userId': userId,
        'startDate': Timestamp.fromDate(normalizedStart), // ✅ 정규화해서 저장
        'endDate': endDate != null ? Timestamp.fromDate(_normalizeDate(endDate)) : null,
        'cycleLength': cycleLength ?? 28,
        'periodLength': periodLength ?? 5,
        'isOnMedication': isOnMedication ?? false,
        'flow': flow ?? '보통',
        if (nick != null && nick.trim().isNotEmpty) 'nick': nick.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('생리 정보 저장 성공! Period ID: ${periodDoc.id}');
      return periodDoc.id;

    } catch (e) {
      print('생리 정보 저장 실패: $e');
      return null;
    }
  }

  /// 추가 화면용: recentStartDate(= startDate) 기준으로 upsert
  /// - 문서가 있으면 endDate / isOnMedication 등 업데이트
  /// - 없으면 최소 필드로 새로 생성
  Future<String> upsertExtraByStartDate({
    required String userId,
    required DateTime recentStartDate,   // 시작일
    required DateTime selectedEndDate,   // 종료일
    bool? isOnMedication,
  }) async {
    try {
      final start = _normalizeDate(recentStartDate);
      final end = _normalizeDate(selectedEndDate);

      // 동일 유저 + 동일 startDate 문서 있는지 조회 (정확히 같은 Timestamp여야 하므로 정규화 중요)
      final qs = await _col
          .where('userId', isEqualTo: userId)
          .where('startDate', isEqualTo: Timestamp.fromDate(start))
          .limit(1)
          .get();

      if (qs.docs.isNotEmpty) {
        // ✅ 이미 있으면 업데이트
        final doc = qs.docs.first.reference;
        await doc.set({
          'endDate': Timestamp.fromDate(end),
          'isOnMedication': isOnMedication,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return doc.id;
      } else {
        // ✅ 없으면 새로 생성 (최소 필드)
        final doc = await _col.add({
          'userId': userId,
          'startDate': Timestamp.fromDate(start),
          'endDate': Timestamp.fromDate(end),
          'isOnMedication': isOnMedication,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return doc.id;
      }
    } on FirebaseException catch (e) {
      print('[PeriodService] Firestore error: ${e.code} ${e.message}');
      rethrow;
    } catch (e) {
      print('[PeriodService] unknown error: $e');
      rethrow;
    }
  }

  /// 닉네임만 먼저 저장하는 드래프트 생성 (기존 유지)
  Future<String> createDraftWithNick({
    required String userId,
    required String nick,
  }) async {
    try {
      final data = {
        'userId': userId,
        'nick': nick.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      final doc = await _col.add(data);
      print('[PeriodService] draft created: ${doc.id} for user=$userId nick=$nick');
      return doc.id;
    } on FirebaseException catch (e) {
      print('[PeriodService] Firestore error: ${e.code} ${e.message}');
      rethrow;
    } catch (e) {
      print('[PeriodService] unknown error: $e');
      rethrow;
    }
  }

  // 특정 사용자의 최근 생리 기록 가져오기 (기존)
  Future<Map<String, dynamic>?> getLatestPeriod(String userId) async {
    try {
      QuerySnapshot snapshot = await _col
          .where('userId', isEqualTo: userId)
          .orderBy('startDate', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        var doc = snapshot.docs.first;
        return {
          'periodId': doc.id,
          ...doc.data() as Map<String, dynamic>
        };
      }
      return null;
    } catch (e) {
      print('최근 생리 기록 조회 실패: $e');
      return null;
    }
  }

  // 특정 기간의 생리 기록들 가져오기 (기존)
  Future<List<Map<String, dynamic>>> getPeriodsInRange(
    String userId, 
    DateTime startDate, 
    DateTime endDate
  ) async {
    try {
      final s = _normalizeDate(startDate);
      final e = _normalizeDate(endDate);

      QuerySnapshot snapshot = await _col
          .where('userId', isEqualTo: userId)
          .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(s))
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(e))
          .orderBy('startDate', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return {
          'periodId': doc.id,
          ...doc.data() as Map<String, dynamic>
        };
      }).toList();
    } catch (e) {
      print('생리 기록 범위 조회 실패: $e');
      return [];
    }
  }

  // 생리 정보 업데이트 (기존)
  Future<bool> updatePeriodData(String periodId, Map<String, dynamic> data) async {
    try {
      await _col.doc(periodId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('생리 정보 업데이트 성공!');
      return true;
    } catch (e) {
      print('생리 정보 업데이트 실패: $e');
      return false;
    }
  }
}