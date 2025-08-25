import 'package:cloud_firestore/cloud_firestore.dart';

class PeriodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _col => _firestore.collection('periods');

  // 생리 정보를 periods 컬렉션에 저장
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
      // periods 컬렉션에 새 문서 생성
      DocumentReference periodDoc = await _firestore.collection('periods').add({
        'userId': userId, // 어떤 사용자의 기록인지
        'startDate': Timestamp.fromDate(startDate),
        'endDate': endDate != null ? Timestamp.fromDate(endDate) : null,
        'cycleLength': cycleLength ?? 28, // 기본값 28일
        'periodLength': periodLength ?? 5, // 기본값 5일
        'isOnMedication': isOnMedication ?? false,
        'flow': flow ?? '보통',
        if (nick != null && nick.trim().isNotEmpty) 'nick': nick.trim(),
      });

      print('생리 정보 저장 성공! Period ID: ${periodDoc.id}');
      return periodDoc.id; // 생성된 period 문서 ID 반환

    } catch (e) {
      print('생리 정보 저장 실패: $e');
      return null;
    }
  }

  /// 닉네임만 먼저 저장하는 드래프트 생성
  Future<String> createDraftWithNick({
    required String userId,
    required String nick,
  }) async {
    try {
      final data = {
        'userId': userId,
        'nick': nick.trim(),
        // 나중 단계에서 채움
        // 'startDate','endDate','cycleLength','periodLength','flow','isOnMedication'
        'createdAt': FieldValue.serverTimestamp(),
      };

      final doc = await _col.add(data);
      // 디버그용 로그
      // ignore: avoid_print
      print('[PeriodService] draft created: ${doc.id} for user=$userId nick=$nick');
      return doc.id;
    } on FirebaseException catch (e) {
      // ignore: avoid_print
      print('[PeriodService] Firestore error: ${e.code} ${e.message}');
      rethrow;
    } catch (e) {
      // ignore: avoid_print
      print('[PeriodService] unknown error: $e');
      rethrow;
    }
  }

  // 특정 사용자의 최근 생리 기록 가져오기
  Future<Map<String, dynamic>?> getLatestPeriod(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('periods')
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

  // 특정 기간의 생리 기록들 가져오기
  Future<List<Map<String, dynamic>>> getPeriodsInRange(
    String userId, 
    DateTime startDate, 
    DateTime endDate
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('periods')
          .where('userId', isEqualTo: userId)
          .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
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

  // 생리 정보 업데이트
  Future<bool> updatePeriodData(String periodId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('periods').doc(periodId).update({
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

// 사용 예시
class ExampleUsage {
  final PeriodService _periodService = PeriodService();

  // 생리 정보 저장 예시
  void savePeriodExample(String userId) async {
    String? periodId = await _periodService.savePeriodData(
      userId: userId,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(Duration(days: 5)),
      cycleLength: 28,
      periodLength: 5,
      isOnMedication: false,
      flow: '보통',
    );

    if (periodId != null) {
      print('저장 성공! Period ID: $periodId');
    }
  }

  // 최근 생리 기록 조회 예시
  void getLatestPeriodExample(String userId) async {
    var latestPeriod = await _periodService.getLatestPeriod(userId);
    if (latestPeriod != null) {
      print('최근 생리 시작일: ${latestPeriod['startDate']}');
      print('생리 기간: ${latestPeriod['periodLength']}일');
    }
  }
}