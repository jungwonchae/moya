// lib/screens/data_period/data_period_screen.dart
import 'package:flutter/material.dart';
import 'package:moya_app/widgets/greeting_header.dart';
import 'package:moya_app/widgets/nav_bar.dart';
import 'package:moya_app/widgets/period_calendar.dart';
import 'package:moya_app/themes/colortheme.dart';
import 'package:moya_app/services/user_service.dart';
import 'package:moya_app/services/period_service.dart';
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/foundation.dart'; // kDebugMode


class DataPeriodScreen extends StatefulWidget {
  const DataPeriodScreen({super.key});

  @override
  State<DataPeriodScreen> createState() => _DataPeriodScreenState();
}

class _DataPeriodScreenState extends State<DataPeriodScreen> {
  // Firebase 서비스
  final UserService _userService = UserService();
  final PeriodService _periodService = PeriodService();

  String? userName;
  String? userId;

  /// 일반 이벤트 (생리대 교체, 메모 등)
  final Map<DateTime, List<DayLog>> _events = {};

  /// 생리 날짜들 (캘린더 배경색 표시용)
  final Set<DateTime> _periodDates = {};

  bool _isLoading = true;

  // ===== 알림 뱃지(읽지 않은 개수) =====
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _unreadSub;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _unreadSub?.cancel();
    super.dispose();
  }

  /// 사용자 정보와 생리 데이터 초기화
  Future<void> _initializeData() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _initializeUser(),
        _loadPeriodDates(),
      ]);
      
      // 알림 뱃지 구독 시작
      _subscribeUnreadBadge();
    } catch (e) {
      print('데이터 초기화 실패: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _initializeUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      userId = currentUser.uid;
      final fetched = await _userService.getUserName(currentUser.uid);
      if (mounted) {
        setState(() {
          userName = fetched;
        });
      }
    }
  }

  // 읽지 않은 알림 개수 구독 (배지 표시용)
  void _subscribeUnreadBadge() {
    if (userId == null) return;
    _unreadSub?.cancel();
    _unreadSub = FirebaseFirestore.instance
        .collection('notifications')
        .doc(userId)
        .collection('items')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      setState(() {
        _unreadCount = snap.docs.length;
      });
    });
  }

  /// 'YYYY-MM-DD' → DateTime(로컬 자정)
  DateTime _dayIdToDate(String dayId) {
    final p = dayId.split('-'); // [YYYY, MM, DD]
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  /// Timestamp → TimeOfDay (표시용)
  TimeOfDay _toTimeOfDay(DateTime dt) => TimeOfDay(hour: dt.hour, minute: dt.minute);

  /// 생리 날짜들을 Set에 저장 + daily/lastChangeAt을 이벤트로 반영
  Future<void> _loadPeriodDates() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      debugPrint('[DEBUG] 사용자가 로그인되지 않음');
      return;
    }

    try {
      debugPrint('[DEBUG] 생리 데이터 로드 시작');

      // 🆕 새로운 메서드 사용: 타입별 날짜 정보 가져오기
      final periodInfo = await _periodService.getPeriodDatesWithTypes(currentUser.uid)
          .timeout(const Duration(seconds: 15));
      
      final List<DateTime> periodDates = periodInfo['periodDates'] as List<DateTime>;
      final List<DateTime> startDates = periodInfo['startDates'] as List<DateTime>;
      
      debugPrint('[DEBUG] 가져온 생리 날짜 수: ${periodDates.length}');
      debugPrint('[DEBUG] 가져온 시작 날짜 수: ${startDates.length}');
      debugPrint('[DEBUG] 생리 날짜들: $periodDates');
      debugPrint('[DEBUG] 시작 날짜들: $startDates');

      if (periodDates.isEmpty) {
        debugPrint('[DEBUG] 생리 날짜가 없음');
        return;
      }

      // Set에 정규화된 날짜들 저장
      _periodDates
        ..clear()
        ..addAll(periodDates.map(PeriodCalendar.normalize));

      // 시작일들에 대해 '생리 시작' 이벤트 추가
      for (final startDate in startDates) {
        final normalizedStart = PeriodCalendar.normalize(startDate);
        final startLogs = List<DayLog>.from(_events[normalizedStart] ?? const <DayLog>[]);
        
        // 시작 시간은 실제 데이터에서 가져오거나 기본값 사용
        TimeOfDay startTime = TimeOfDay(hour: startDate.hour, minute: startDate.minute);
        if (startTime.hour == 0 && startTime.minute == 0) {
          startTime = const TimeOfDay(hour: 9, minute: 0); // 기본값
        }
        
        startLogs.add(DayLog(
          time: startTime,
          title: '생리 시작',
        ));
        _events[normalizedStart] = startLogs;
      }

      debugPrint('[DEBUG] 생리 시작 이벤트 ${startDates.length}개 추가됨');

      // daily 컬렉션에서 교체 기록 가져오기 (기존 로직 유지)
      final latestPeriod = await _periodService.getLatestPeriod(currentUser.uid);
      if (latestPeriod != null) {
        final periodId = latestPeriod['periodId'] as String?;
        if (periodId != null) {
          try {
            final dailySnap = await FirebaseFirestore.instance
                .collection('periods')
                .doc(periodId)
                .collection('daily')
                .get()
                .timeout(const Duration(seconds: 10));

            debugPrint('[DEBUG] daily 문서 수: ${dailySnap.docs.length}');

            int changeEventCount = 0;
            for (final doc in dailySnap.docs) {
              final data = doc.data();
              final lastTs = data['lastChangeAt'];
              if (lastTs is! Timestamp) continue;

              final dayId = doc.id; // 'YYYY-MM-DD'
              final date = PeriodCalendar.normalize(_dayIdToDate(dayId));
              final time = _toTimeOfDay(lastTs.toDate());

              final dayLogs = List<DayLog>.from(_events[date] ?? const <DayLog>[]);
              dayLogs.add(DayLog(
                time: time,
                title: '생리대 교체',
              ));
              _events[date] = dayLogs;
              changeEventCount++;
            }
            
            debugPrint('[DEBUG] 교체 이벤트 추가됨: $changeEventCount개');
          } catch (e) {
            debugPrint('[ERROR] daily 데이터 로드 실패: $e');
          }
        }
      }

      if (mounted) setState(() {});
    } catch (e) {
      if (e is TimeoutException) {
        debugPrint('[ERROR] 네트워크 타임아웃');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('네트워크 연결을 확인해주세요')),
          );
        }
      } else {
        debugPrint('[ERROR] 생리 데이터 로드 실패: $e');
        
        if (e is FirebaseException) {
          debugPrint('[ERROR] Firebase 에러 코드: ${e.code}');
          debugPrint('[ERROR] Firebase 에러 메시지: ${e.message}');
        }
      }
    }
  }

  /// 데이터 새로고침
  Future<void> _refreshData() async {
    await _loadPeriodDates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const NavBar(currentIndex: 1),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _refreshData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // 헤더 + 우상단 알림 배지 오버레이
                      Stack(
                        children: [
                          GreetingHeader(
                            userName: userName,
                            height: 120,
                            dropAsset: 'assets/icons/moya.svg',
                            onAiTap: () => Navigator.pushNamed(context, '/ondevice'),
                            onBellTap: () => Navigator.pushNamed(context, '/notification'),
                          ),
                          // if (_unreadCount > 0 || kDebugMode)  // 디버그 빌드면 무조건 배지 표시                          
                          if (_unreadCount > 0)
                            Positioned(
                              // bell 아이콘 위치에 맞춰 정확히 조정
                              top: 40, // SafeArea + padding 고려
                              right: 37, // bell 아이콘의 오른쪽 위 모서리 근처
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF3B30), // iOS red
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),

                      // 달력 패널 - 생리 날짜를 직접 전달
                      PeriodCalendar(
                        events: _events, // 일반 이벤트 (생리대 교체, 메모 등)
                        periodDates: _periodDates, // 생리 날짜들 (배경색 표시용)
                        onSelected: (selectedDate) {
                          final normalizedDate = PeriodCalendar.normalize(selectedDate);

                          // 생리 날짜인지 확인
                          if (_periodDates.contains(normalizedDate)) {
                            // print('생리 날짜입니다.');
                          }

                          // 일반 이벤트 확인
                          final logs = _events[normalizedDate];
                          if (logs != null && logs.isNotEmpty) {
                            // print('해당 날짜의 이벤트: ${logs.map((l) => l.title).join(', ')}');
                          }
                        },
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}