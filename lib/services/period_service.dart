// lib/services/period_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

extension _DateHelpers on DateTime {
  DateTime get d => DateTime(year, month, day); // normalize
}

class PeriodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _noti = NotificationService();
  CollectionReference get _col => _firestore.collection('periods');
  

  /// 날짜만 유지(시간 00:00:00)로 정규화
  DateTime _normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);

  // ============== 내부 헬퍼: 최신 period 문서 ref 찾기 ==============
  Future<DocumentReference?> _latestPeriodRef(String userId) async {
    // startDate 기준 최신 1개 (없으면 createdAt 기준으로 한번 더 시도)
    QuerySnapshot q = await _col
        .where('userId', isEqualTo: userId)
        .orderBy('startDate', descending: true)
        .limit(1)
        .get();

    if (q.docs.isNotEmpty) return q.docs.first.reference;

    // fallback: createdAt 기준
    QuerySnapshot q2 = await _col
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (q2.docs.isNotEmpty) return q2.docs.first.reference;

    return null;
  }

  // ============== 센서 최종 업데이트(권장): userId로 최신 문서 flow 수정 ==============
  Future<void> updateLatestFlowByUserId(String userId, String flow) async {
    final ref = await _latestPeriodRef(userId);
    if (ref == null) {
      // 최신 문서가 없다면, 초안(draft)을 만들어 flow만 넣을 수도 있음(선택)
      // 여기서는 에러로 처리
      debugPrint('[PeriodService] latest period not found for $userId');
      throw Exception('latest period not found for $userId');
    }

    await ref.set({
      'flow': flow,
      'flowUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    debugPrint('[PeriodService] updateLatestFlowByUserId OK: userId=$userId flow=$flow doc=${ref.id}');
  }

  /// 생리 주기 상태 계산 함수 (flow로 반환: before, need, safe, warning)
  String _calculateFlow({
    required DateTime startDate,
    DateTime? endDate,
    int? cycleLength,
    String? sensorStatus, // 센서 상태가 있으면 우선
  }) {
    final now = DateTime.now();

    if (sensorStatus != null) {
      return sensorStatus; // 'safe' | 'warning' | 'need'
    }

    if (endDate != null) {
      final avgCycle = cycleLength ?? 28;
      final nextPeriodDate = endDate.add(Duration(days: avgCycle));
      final daysUntilNextPeriod = nextPeriodDate.difference(now).inDays;

      if (daysUntilNextPeriod > 3) return 'before';
      return 'safe'; // 센서 없을 때 기본 추정
    } else {
      final daysSinceStart = now.difference(startDate).inDays;
      final avgCycle = cycleLength ?? 28;
      if (daysSinceStart < avgCycle - 5) return 'before';
      return 'safe';
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
    String? sensorStatus, // 센서 상태
  }) async {
    try {
      final normalizedStart = _normalizeDate(startDate);
      final normalizedEnd = endDate != null ? _normalizeDate(endDate) : null;

      final calculatedFlow = flow ??
          _calculateFlow(
            startDate: normalizedStart,
            endDate: normalizedEnd,
            cycleLength: cycleLength,
            sensorStatus: sensorStatus,
          );

      final doc = await _col.add({
        'userId': userId,
        'startDate': Timestamp.fromDate(normalizedStart),
        'endDate': normalizedEnd != null ? Timestamp.fromDate(normalizedEnd) : null,
        'cycleLength': cycleLength ?? 28,
        'periodLength': periodLength ?? 5,
        'isOnMedication': isOnMedication ?? false,
        'flow': calculatedFlow,
        if (nick != null && nick.trim().isNotEmpty) 'nick': nick.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[PeriodService] savePeriodData OK: id=${doc.id} flow=$calculatedFlow');
      return doc.id;
    } catch (e) {
      debugPrint('[PeriodService] savePeriodData ERR: $e');
      return null;
    }
  }

  /// 추가 화면용: recentStartDate 기준으로 upsert
  Future<String> upsertExtraByStartDate({
    required String userId,
    required DateTime recentStartDate,
    required DateTime selectedEndDate,
    bool? isOnMedication,
    String? sensorStatus,
  }) async {
    try {
      final start = _normalizeDate(recentStartDate);
      final end = _normalizeDate(selectedEndDate);

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
        final doc = qs.docs.first.reference;
        await doc.set({
          'endDate': Timestamp.fromDate(end),
          'isOnMedication': isOnMedication,
          'flow': flow,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return doc.id;
      } else {
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
      debugPrint('[PeriodService] upsertExtra Firestore error: ${e.code} ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[PeriodService] upsertExtra unknown error: $e');
      rethrow;
    }
  }

  /// 닉네임만 먼저 저장하는 드래프트 생성
  Future<String> createDraftWithNick({
    required String userId,
    required String nick,
  }) async {
    final data = {
      'userId': userId,
      'nick': nick.trim(),
      'flow': 'safe',
      'createdAt': FieldValue.serverTimestamp(),
    };
    final doc = await _col.add(data);
    debugPrint('[PeriodService] draft created: ${doc.id} for user=$userId nick=$nick');
    return doc.id;
  }

  // 특정 사용자의 최근 생리 기록 가져오기
  Future<Map<String, dynamic>?> getLatestPeriod(String userId) async {
    try {
      var q = await _col
          .where('userId', isEqualTo: userId)
          .orderBy('startDate', descending: true)
          .limit(1)
          .get();

      if (q.docs.isEmpty) return null;
      final d = q.docs.first;
      return {'periodId': d.id, ...d.data() as Map<String, dynamic>};
    } catch (e) {
      debugPrint('[PeriodService] getLatestPeriod ERR: $e');
      return null;
    }
  }

  // 특정 기간의 생리 기록들 가져오기
  Future<List<Map<String, dynamic>>> getPeriodsInRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final s = _normalizeDate(startDate);
      final e = _normalizeDate(endDate);

      final snapshot = await _col
          .where('userId', isEqualTo: userId)
          .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(s))
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(e))
          .orderBy('startDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => {'periodId': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      debugPrint('[PeriodService] getPeriodsInRange ERR: $e');
      return [];
    }
  }

  // 생리 정보 업데이트 (flow 재계산 포함)
  Future<bool> updatePeriodData(String periodId, Map<String, dynamic> data) async {
    try {
      final ref = _col.doc(periodId);
      final snap = await ref.get();
      if (!snap.exists) return false;

      final existing = snap.data() as Map<String, dynamic>;

      // 1) 입력 데이터 정규화
      Timestamp? tsStart;
      Timestamp? tsEnd;

      if (data.containsKey('startDate')) {
        final v = data['startDate'];
        if (v is Timestamp) {
          tsStart = v;
        } else if (v is DateTime) {
          tsStart = Timestamp.fromDate(_normalizeDate(v));
        }
      } else if (existing['startDate'] is Timestamp) {
        tsStart = existing['startDate'] as Timestamp;
      }

      if (data.containsKey('endDate')) {
        final v = data['endDate'];
        if (v is Timestamp) {
          tsEnd = v;
        } else if (v is DateTime) {
          tsEnd = Timestamp.fromDate(_normalizeDate(v));
        } else if (v == null) {
          tsEnd = null;
        }
      } else if (existing['endDate'] is Timestamp) {
        tsEnd = existing['endDate'] as Timestamp?;
      }

      // 2) flow 결정: 명시적 입력 > 계산
      String? flowFromInput;
      final fv = data['flow'];
      if (fv is String && fv.trim().isNotEmpty) {
        flowFromInput = fv.trim();
      }

      String finalFlow;
      if (flowFromInput != null) {
        finalFlow = flowFromInput;
      } else {
        final DateTime? startDate = tsStart?.toDate();
        final DateTime? endDate = tsEnd?.toDate();
        if (startDate != null) {
          finalFlow = _calculateFlow(
            startDate: startDate,
            endDate: endDate,
            cycleLength: data['cycleLength'] ?? existing['cycleLength'],
            sensorStatus: data['sensorStatus'],
          );
        } else {
          finalFlow = (existing['flow'] as String?) ?? 'before';
        }
      }

      final payload = <String, dynamic>{
        if (tsStart != null) 'startDate': tsStart,
        'endDate': tsEnd,
        ...data..remove('startDate')..remove('endDate')..remove('flow')..remove('updatedAt'),
        'flow': finalFlow,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await ref.update(payload);

      final check = await ref.get(const GetOptions(source: Source.server));
      debugPrint('[PeriodService] updatePeriodData saved: ${check.data()}');
      return true;
    } catch (e) {
      debugPrint('[PeriodService] updatePeriodData ERR: $e');
      return false;
    }
  }

  /// 특정 사용자의 최근 1개 생리 기록 스트림
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
      final latest = await getLatestPeriod(userId);
      if (latest == null) return null;
      final raw = latest['flow'];
      if (raw is String) {
        final v = raw.trim();
        return v.isNotEmpty ? v : null;
      }
      return null;
    } catch (e) {
      debugPrint('[PeriodService] getLatestFlow ERR: $e');
      return null;
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
      debugPrint('[PeriodService] calculateNextPeriodDate ERR: $e');
      return null;
    }
  }

  /// (호환용) 특정 periodId로 flow 업데이트
  Future<bool> updateFlowBySensorStatus(String periodId, String sensorStatus) async {
    try {
      await _col.doc(periodId).update({
        'flow': sensorStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[PeriodService] updateFlowBySensorStatus OK: $sensorStatus on $periodId');
      return true;
    } catch (e) {
      debugPrint('[PeriodService] updateFlowBySensorStatus ERR: $e');
      return false;
    }
  }

  /// 최신 period의 [startDate..endDate] 날짜들을 모두 리턴
  Future<List<DateTime>> getLatestPeriodDays(String userId) async {
    final latest = await getLatestPeriod(userId);
    if (latest == null) return [];

    final tsStart = latest['startDate'] as Timestamp?;
    final tsEnd = latest['endDate'] as Timestamp?;

    final start = tsStart != null ? _normalizeDate(tsStart.toDate()) : null;
    if (start == null) return [];

    final int periodLen = (latest['periodLength'] as int?) ?? 5;
    final DateTime end =
        tsEnd != null ? _normalizeDate(tsEnd.toDate()) : _normalizeDate(start.add(Duration(days: periodLen - 1)));

    final days = <DateTime>[];
    for (DateTime d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      days.add(_normalizeDate(d));
    }
    return days;
  }

  // 상세 조회
  Future<Map<String, dynamic>> getPeriodData(String periodId) async {
    final doc = await _col.doc(periodId).get();
    if (!doc.exists) {
      throw Exception('Period document not found: $periodId');
    }

    final raw = doc.data() as Map<String, dynamic>? ?? {};

    DateTime? _toDate(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return null;
    }

    int? _toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return null;
    }

    final int? cycleLen = _toInt(raw['cycleLength']) ?? 28;
    final int? periodLen = _toInt(raw['periodDays']) ?? _toInt(raw['periodLength']) ?? 5;

    return {
      'periodId': doc.id,
      'userId': raw['userId'],
      'nick': raw['nick'],
      'flow': raw['flow'] as String?,
      'startDate': _toDate(raw['startDate']),
      'endDate': _toDate(raw['endDate']),
      'cycleLength': cycleLen,
      'periodDays': periodLen,
      'extraData': raw['extraData'] as Map<String, dynamic>?,
      'createdAt': raw['createdAt'],
      'updatedAt': raw['updatedAt'],
    };
  }
}