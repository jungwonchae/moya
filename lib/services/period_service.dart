import 'package:cloud_firestore/cloud_firestore.dart';

extension _DateHelpers on DateTime {
  DateTime get d => DateTime(year, month, day); // normalize
}

class PeriodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _col => _firestore.collection('periods');
  

  /// 날짜만 유지(시간 00:00:00)로 정규화
  DateTime _normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);

  /// 생리 주기 상태 계산 함수 (flow로 반환: before, need, safe, warning)
  String _calculateFlow({
    required DateTime startDate,
    DateTime? endDate,
    int? cycleLength,
    String? sensorStatus, // 센서 상태 (나중에 연결할 예정)
  }) {
    final now = DateTime.now();
    
    // 센서 데이터가 있으면 우선 적용 (나중에 구현)
    if (sensorStatus != null) {
      return sensorStatus; // 'safe', 'warning', 'need' 중 하나
    }
    
    // 센서 데이터가 없으면 생리 예상일 기산으로 계산
    if (endDate != null) {
      // 이전 생리 종료일이 있는 경우: 다음 생리 예상일 계산
      final avgCycle = cycleLength ?? 28;
      final nextPeriodDate = endDate.add(Duration(days: avgCycle));
      final daysUntilNextPeriod = nextPeriodDate.difference(now).inDays;
      
      if (daysUntilNextPeriod > 3) {
        return 'before'; // 아직 시작 전
      } else {
        // 생리 예상일이 가까워지면 기본적으로 safe 상태
        // 실제로는 센서 데이터로 판단
        return 'safe'; 
      }
    } else {
      // 종료일 정보가 없는 경우: 시작일로부터 추정
      final daysSinceStart = now.difference(startDate).inDays;
      final avgCycle = cycleLength ?? 28;
      
      if (daysSinceStart < avgCycle - 5) {
        return 'before'; // 다음 생리까지 여유
      } else {
        return 'safe'; // 기본값
      }
    }
  }

  // 생리 정보를 periods 컬렉션에 저장
  Future<String?> savePeriodData({
    required String userId,
    required DateTime startDate,
    DateTime? endDate,
    int? cycleLength,
    int? periodLength,
    bool? isOnMedication,
    String? flow, // 직접 지정하거나 자동 계산
    String? nick,
    String? sensorStatus, // 센서 상태 (나중에 추가)
  }) async {
    try {
      final normalizedStart = _normalizeDate(startDate);
      final normalizedEnd = endDate != null ? _normalizeDate(endDate) : null;
      
      // flow가 지정되지 않았으면 자동 계산
      final calculatedFlow = flow ?? _calculateFlow(
        startDate: normalizedStart,
        endDate: normalizedEnd,
        cycleLength: cycleLength,
        sensorStatus: sensorStatus,
      );

      DocumentReference periodDoc = await _col.add({
        'userId': userId,
        'startDate': Timestamp.fromDate(normalizedStart),
        'endDate': normalizedEnd != null ? Timestamp.fromDate(normalizedEnd) : null,
        'cycleLength': cycleLength ?? 28,
        'periodLength': periodLength ?? 5,
        'isOnMedication': isOnMedication ?? false,
        'flow': calculatedFlow, // before, need, safe, warning
        if (nick != null && nick.trim().isNotEmpty) 'nick': nick.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('생리 정보 저장 성공! Period ID: ${periodDoc.id}, Flow: $calculatedFlow');
      return periodDoc.id;

    } catch (e) {
      print('생리 정보 저장 실패: $e');
      return null;
    }
  }

  /// 추가 화면용: recentStartDate 기준으로 upsert
  Future<String> upsertExtraByStartDate({
    required String userId,
    required DateTime recentStartDate,
    required DateTime selectedEndDate,
    bool? isOnMedication,
    String? sensorStatus, // 센서 상태 (나중에 추가)
  }) async {
    try {
      final start = _normalizeDate(recentStartDate);
      final end = _normalizeDate(selectedEndDate);
      
      // flow 계산
      final flow = _calculateFlow(
        startDate: start,
        endDate: end,
        sensorStatus: sensorStatus,
      );

      final qs = await _col
          .where('userId', isEqualTo: userId)
          .where('startDate', isEqualTo: Timestamp.fromDate(start))
          .limit(1)
          .get();

      if (qs.docs.isNotEmpty) {
        // 기존 문서 업데이트
        final doc = qs.docs.first.reference;
        await doc.set({
          'endDate': Timestamp.fromDate(end),
          'isOnMedication': isOnMedication,
          'flow': flow,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return doc.id;
      } else {
        // 새 문서 생성
        final doc = await _col.add({
          'userId': userId,
          'startDate': Timestamp.fromDate(start),
          'endDate': Timestamp.fromDate(end),
          'isOnMedication': isOnMedication,
          'flow': flow,
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

  /// 닉네임만 먼저 저장하는 드래프트 생성
  Future<String> createDraftWithNick({
    required String userId,
    required String nick,
  }) async {
    try {
      final data = {
        'userId': userId,
        'nick': nick.trim(),
        'flow': 'safe', // 기본값
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

  // 특정 사용자의 최근 생리 기록 가져오기
  Future<Map<String, dynamic>?> getLatestPeriod(String userId) async {
    try {
      // 1차: startDate 기준
      var q = await _col
          .where('userId', isEqualTo: userId)
          .orderBy('startDate', descending: true)
          .limit(1)
          .get();

      if (q.docs.isEmpty) return null;
      final d = q.docs.first;
      return {'periodId': d.id, ...d.data() as Map<String, dynamic>};
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

  // 생리 정보 업데이트 (flow 재계산 포함)
  Future<bool> updatePeriodData(String periodId, Map<String, dynamic> data) async {
    try {
      // 기존 데이터 먼저 가져오기
      DocumentSnapshot doc = await _col.doc(periodId).get();
      if (!doc.exists) return false;

      Map<String, dynamic> existingData = doc.data() as Map<String, dynamic>;
      
      // 날짜 정보로 flow 재계산
      DateTime? startDate;
      DateTime? endDate;
      
      if (data.containsKey('startDate') && data['startDate'] is Timestamp) {
        startDate = (data['startDate'] as Timestamp).toDate();
      } else if (existingData.containsKey('startDate') && existingData['startDate'] is Timestamp) {
        startDate = (existingData['startDate'] as Timestamp).toDate();
      }
      
      if (data.containsKey('endDate') && data['endDate'] is Timestamp) {
        endDate = (data['endDate'] as Timestamp).toDate();
      } else if (existingData.containsKey('endDate') && existingData['endDate'] is Timestamp) {
        endDate = (existingData['endDate'] as Timestamp).toDate();
      }

      // flow 재계산 (날짜 정보가 있는 경우)
      if (startDate != null) {
        final newFlow = _calculateFlow(
          startDate: startDate,
          endDate: endDate,
          cycleLength: data['cycleLength'] ?? existingData['cycleLength'],
          sensorStatus: data['sensorStatus'], // 센서 상태 (나중에 추가)
        );
        data['flow'] = newFlow;
      }

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

  /// 특정 사용자의 최근 1개 생리 기록을 실시간으로 가져오는 스트림
  Stream<Map<String, dynamic>?> latestPeriodStream(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .orderBy('startDate', descending: true)
        .limit(1)
        .snapshots()
        .map((qs) {
      if (qs.docs.isEmpty) return null;
      final d = qs.docs.first;
      return {'periodId': d.id, ...d.data() as Map<String, dynamic>};
    });
  }

  /// 사용자의 최신 생리 flow만 가져오기
  Future<String?> getLatestFlow(String userId) async {
    try {
      final latestPeriod = await getLatestPeriod(userId);
      return latestPeriod?['flow'] as String?;
    } catch (e) {
      print('최근 flow 조회 실패: $e');
      return null;
    }
  }

  /// flow별 메시지 가져오기 (새로운 메시지 체계)
  String getFlowMessage(String flow) {
    switch (flow) {
      case 'before':
        return '아직 시작 전이에요'; // 생리 예상일 전
      case 'safe':
        return '아직은 보송보송해요'; // 센서 1개 켜짐
      case 'warning':
        return '곧 교체할 시간이 다가와요'; // 센서 2개 켜짐
      case 'need':
        return '교체가 필요해요'; // 센서 3개 켜짐
      default:
        return '상태를 확인해주세요';
    }
  }

  /// 다음 생리 예상일 계산
  Future<DateTime?> calculateNextPeriodDate(String userId) async {
    try {
      final latestPeriod = await getLatestPeriod(userId);
      if (latestPeriod == null) return null;

      final endDate = (latestPeriod['endDate'] as Timestamp?)?.toDate();
      final cycleLength = latestPeriod['cycleLength'] as int? ?? 28;

      if (endDate != null) {
        return endDate.add(Duration(days: cycleLength));
      }
      return null;
    } catch (e) {
      print('다음 생리 예상일 계산 실패: $e');
      return null;
    }
  }

  /// 센서 상태로 flow 업데이트 (나중에 센서 연결 시 사용)
  Future<bool> updateFlowBySensorStatus(String periodId, String sensorStatus) async {
    try {
      // sensorStatus: 'safe' (1개), 'warning' (2개), 'need' (3개)
      await _col.doc(periodId).update({
        'flow': sensorStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('센서 상태로 flow 업데이트: $sensorStatus');
      return true;
    } catch (e) {
      print('센서 flow 업데이트 실패: $e');
      return false;
    }
  }

  /// 최신 period의 [startDate..endDate] 날짜들을 모두 리턴
  Future<List<DateTime>> getLatestPeriodDays(String userId) async {
    final latest = await getLatestPeriod(userId);
    if (latest == null) return [];

    final tsStart = latest['startDate'] as Timestamp?;
    final tsEnd   = latest['endDate']   as Timestamp?;

    final start = tsStart != null ? _normalizeDate(tsStart.toDate()) : null;
    if (start == null) return [];

    final int periodLen = (latest['periodLength'] as int?) ?? 5;
    final DateTime end =
        tsEnd != null ? _normalizeDate(tsEnd.toDate())
                      : _normalizeDate(start.add(Duration(days: periodLen - 1)));

    final days = <DateTime>[];
    for (DateTime d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      days.add(_normalizeDate(d));
    }
    return days;
  }
}