import 'package:flutter/material.dart';
import 'package:moya_app/widgets/greeting_header.dart';
import 'package:moya_app/widgets/nav_bar.dart';
import 'package:moya_app/widgets/period_calendar.dart';
import 'package:moya_app/themes/colortheme.dart';
import 'package:moya_app/services/user_service.dart';
import 'package:moya_app/services/period_service.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  
  /// 일반 이벤트 (생리대 교체, 메모 등)
  final Map<DateTime, List<DayLog>> _events = {};
  
  /// 생리 날짜들 (캘린더 배경색 표시용)
  final Set<DateTime> _periodDates = {};
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  /// 사용자 정보와 생리 데이터 초기화
  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    
    try {
      await Future.wait([
        _initializeUser(),
        _loadPeriodDates(),
      ]);
    } catch (e) {
      print('데이터 초기화 실패: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _initializeUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final fetched = await _userService.getUserName(currentUser.uid);
      if (mounted) {
        setState(() {
          userName = fetched;
        });
      }
    }
  }

  /// 생리 날짜들을 Set에 저장
Future<void> _loadPeriodDates() async {
 final currentUser = FirebaseAuth.instance.currentUser;
 if (currentUser == null) return;

 try {
   final days = await _periodService.getLatestPeriodDays(currentUser.uid);
   if (days.isEmpty) return;

   _periodDates
     ..clear()
     ..addAll(days.map(PeriodCalendar.normalize));

   // 최신 생리 정보에서 시간 가져오기
   final latestPeriod = await _periodService.getLatestPeriod(currentUser.uid);
   TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0); // 기본값

   if (latestPeriod != null) {
     if (latestPeriod['createdAt'] != null) {
       final createdAt = (latestPeriod['createdAt'] as Timestamp).toDate();
       startTime = TimeOfDay(hour: createdAt.hour, minute: createdAt.minute);
     } else if (latestPeriod['startDate'] != null) {
       final startDateTime = (latestPeriod['startDate'] as Timestamp).toDate();
       startTime = TimeOfDay(hour: startDateTime.hour, minute: startDateTime.minute);
     }
   }

   // 시작일 로그 추가: '생리 시작'
   final start = PeriodCalendar.normalize(days.first);
   final startLogs = List<DayLog>.from(_events[start] ?? const <DayLog>[]);
   startLogs.add(DayLog(
     time: startTime, // 서버에서 가져온 실제 시간
     title: '생리 시작',
   ));
   _events[start] = startLogs;
   
   if (mounted) setState(() {});
 } catch (e) {
   print('생리 데이터 로드 실패: $e');
 }
}
  

  /// 생기 날짜들을 Set에 저장하는 메서드 삭제
  void _clearPeriodEvents() {
    // 더 이상 필요하지 않음 - Set 방식으로 변경
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
                    // 상단 인사 헤더
                    GreetingHeader(
                      userName: userName,
                      height: 120,
                      dropAsset: 'assets/icons/moya.svg',
                      onAiTap: () => Navigator.pushNamed(context, '/ondevice'),
                      onBellTap: () => Navigator.pushNamed(context, '/notification'),
                    ),
                    
                    // 달력 패널 - 생리 날짜를 직접 전달
                    PeriodCalendar(
                      events: _events, // 일반 이벤트 (생리대 교체, 메모 등)
                      periodDates: _periodDates, // 생리 날짜들 (배경색 표시용)
                      onSelected: (selectedDate) {
                        print('선택된 날짜: $selectedDate');
                        
                        final normalizedDate = PeriodCalendar.normalize(selectedDate);
                        
                        // 생리 날짜인지 확인
                        if (_periodDates.contains(normalizedDate)) {
                          print('생리 날짜입니다.');
                        }
                        
                        // 일반 이벤트 확인
                        final logs = _events[normalizedDate];
                        if (logs != null && logs.isNotEmpty) {
                          print('해당 날짜의 이벤트: ${logs.map((l) => l.title).join(', ')}');
                        }
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // 디버그 정보 (개발 중에만 표시)
                    /*
                    if (!_isLoading) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('디버그 정보:', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('사용자: ${userName ?? "알 수 없음"}'),
                              Text('생리 날짜 수: ${_periodDates.length}개'),
                              Text('생리 날짜들: ${_periodDates.map((d) => '${d.month}/${d.day}').join(', ')}'),
                              Text('일반 이벤트 수: ${_events.length}개'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    */
                  ],
                ),
              ),
            ),
      ),
    );
  }
}