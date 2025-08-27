import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:moya_app/widgets/greeting_header.dart';
import 'package:moya_app/screens/home/widgets/cycle_status_card.dart';
import 'package:moya_app/widgets/bluetooth_button.dart';
import 'package:moya_app/providers/bluetooth_provider.dart';
import 'package:moya_app/widgets/nav_bar.dart';
import 'package:moya_app/widgets/period_widget.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moya_app/services/user_service.dart';
import 'package:moya_app/services/period_service.dart';

import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Firebase에서 가져올 데이터들
  String? name;
  String currentFlow = 'before'; // before, safe, warning, need
  int daysUntilNext = 5;
  bool isOnPeriod = false;
  
  // 예시 데이터 (나중에 센서 연결 시 실제 데이터로 대체)
  int changeCount = 2;
  String lastChangeText = '0.5시간 전';
  
  // PeriodWidget과 동기화되는 상태
  PadStatus padStatus = PadStatus.before;
  
  // Firebase 서비스
  final UserService _userService = UserService();
  final PeriodService _periodService = PeriodService();
  
  // 로딩 상태
  bool _isLoading = true;
  
  // 사용자 ID
  String? userId;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  // Firebase Auth로부터 현재 사용자 가져오기
  Future<void> _initializeUser() async {
    try {
      // Firebase Auth에서 현재 로그인된 사용자 가져오기
      final User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        userId = currentUser.uid;
        print('현재 사용자 ID: $userId');
        await _loadUserData();
      } else {
        print('로그인된 사용자가 없음');
        // 로그인 화면으로 이동하거나 익명 로그인 처리
        await _handleNoUser();
      }
    } catch (e) {
      print('사용자 초기화 실패: $e');
      setState(() => _isLoading = false);
    }
  }
  // 로그인되지 않은 사용자 처리
  Future<void> _handleNoUser() async {
    try {
      // 익명 로그인 시도
      final UserCredential result = await FirebaseAuth.instance.signInAnonymously();
      userId = result.user?.uid;
      
      if (userId != null) {
        print('익명 사용자로 로그인: $userId');
        await _loadUserData();
      }
    } catch (e) {
      print('익명 로그인 실패: $e');
      setState(() => _isLoading = false);
      // 오류 처리 또는 로그인 화면으로 이동
    }
  }

  /// Flow를 PadStatus로 변환
  PadStatus _convertFlowToPadStatus(String flow) {
    switch (flow) {
      case 'before':
        return PadStatus.before;
      case 'safe':
        return PadStatus.fresh;
      case 'warning':
        return PadStatus.warning;
      case 'need':
        return PadStatus.danger;
      default:
        return PadStatus.before;
    }
  }

  /// 다음 생리까지 남은 일수 계산
  void _calculateDaysUntilNext(Map<String, dynamic> latestPeriod) {
  try {
    final now = DateTime.now();

    final startDate = (latestPeriod['startDate'] as Timestamp?)?.toDate();
    final endDate   = (latestPeriod['endDate']   as Timestamp?)?.toDate();
    final cycleLen  = latestPeriod['cycleLength'] as int? ?? 28;
    final periodLen = latestPeriod['periodLength'] as int? ?? 5;

    // 1) 문서에 isOnPeriod가 있으면 우선 사용
    final isOnPeriodField = latestPeriod['isOnPeriod'] as bool?;

    bool onPeriod;
    int  daysLeft;

    if (isOnPeriodField != null) {
      onPeriod = isOnPeriodField;

      if (onPeriod) {
        // 종료일이 있으면 그날까지 남은 일수, 없으면 startDate + periodLen 기준
        final pseudoEnd = endDate ?? startDate?.add(Duration(days: periodLen - 1));
        if (pseudoEnd != null) {
          // +1 해서 "오늘 포함 며칠 남음" 느낌으로 보이고 싶다면 +1 유지/조정
          daysLeft = (pseudoEnd.difference(DateTime(now.year, now.month, now.day)).inDays + 1).clamp(0, 999);
        } else {
          daysLeft = 0;
        }
      } else {
        // 다음 생리까지 남은 일수 (endDate가 있으면 endDate+cycle, 없으면 startDate+cycle)
        final base = endDate ?? startDate;
        if (base != null) {
          final nextDate = base.add(Duration(days: cycleLen));
          daysLeft = (DateTime(nextDate.year, nextDate.month, nextDate.day)
                        .difference(DateTime(now.year, now.month, now.day)).inDays)
                      .clamp(0, 999);
        } else {
          daysLeft = 0;
        }
      }
    } else {
      // 2) isOnPeriod 필드가 없으면 날짜로 추정
      //    - endDate가 없으면 startDate ~ (startDate + periodLen - 1) 동안은 생리 중으로 간주
      //    - endDate가 있으면 now가 start~end 사이면 생리 중
      if (startDate != null) {
        final pseudoEnd = endDate ?? startDate.add(Duration(days: periodLen - 1));
        final today = DateTime(now.year, now.month, now.day);
        final startD = DateTime(startDate.year, startDate.month, startDate.day);
        final endD   = DateTime(pseudoEnd.year, pseudoEnd.month, pseudoEnd.day);

        final within = (today.isAfter(startD) || today.isAtSameMomentAs(startD)) &&
                       (today.isBefore(endD)   || today.isAtSameMomentAs(endD));

        onPeriod = within;

        if (onPeriod) {
          daysLeft = (endD.difference(today).inDays + 1).clamp(0, 999); // 오늘 포함 남은 일수
        } else {
          final base = endDate ?? startDate;
          final nextDate = base.add(Duration(days: cycleLen));
          daysLeft = (DateTime(nextDate.year, nextDate.month, nextDate.day)
                        .difference(today).inDays).clamp(0, 999);
        }
      } else {
        // start/end 둘 다 없으면 안전값
        onPeriod = false;
        daysLeft = 0;
      }
    }

    setState(() {
      daysUntilNext = daysLeft;
      isOnPeriod = onPeriod;
    });
  } catch (e) {
    print('날짜 계산 실패: $e');
  }
}

  /// 데이터 새로고침
  Future<void> _refreshData() async {
    await _loadUserData();
  }

  /// Flow 상태 변경 시 Firebase 업데이트 (센서 연결 시 사용)
  void _onStatusChanged(PadStatus newStatus) {
    setState(() => padStatus = newStatus);
    
    // Firebase에 새 상태 저장 (센서 데이터 시뮬레이션)
    if (userId != null) {
      final flowStatus = _convertPadStatusToFlow(newStatus);
      // 실제로는 센서에서 데이터가 오면 자동으로 업데이트됨
      _updateFlowInFirebase(flowStatus);
    }
  }

  Future<bool> _checkFirebaseConnection() async {
    try {
      await FirebaseFirestore.instance.collection('_ping').limit(1).get();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _createNewUserDocument() async {
    if (userId == null) return;
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _loadUserData() async {
    if (!mounted || userId == null) return;
    
    setState(() => _isLoading = true);

    try {
      // Firebase 연결 확인
      final isConnected = await _checkFirebaseConnection();
      if (!isConnected) {
        throw Exception('Firebase 연결 실패');
      }

      print('사용자 데이터 로딩 시작: $userId');
      
      // 사용자 문서가 존재하는지 확인
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (!userDoc.exists) {
        print('사용자 문서가 존재하지 않음. 새로 생성...');
        // 새 사용자 문서 생성
        await _createNewUserDocument();
      }

      // UserService를 사용해서 사용자 이름 가져오기
      final fetchedUserName = await _userService.getUserName(userId!);
      
      // PeriodService에서 생리 정보 가져오기
      final results = await Future.wait([
        _periodService.getLatestFlow(userId!),
        _periodService.getLatestPeriod(userId!),
      ]);

      final fetchedFlow = results[0] as String?;
      final latestPeriod = results[1] as Map<String, dynamic>?;

      if (mounted) {
        setState(() { 
          name = fetchedUserName;
          currentFlow = fetchedFlow ?? 'before';
          padStatus = _convertFlowToPadStatus(currentFlow);
          
          if (latestPeriod != null) {
            _calculateDaysUntilNext(latestPeriod);
          }
          
          _isLoading = false;
        });
        
        print('사용자 데이터 로드 완료: 이름=$name, 상태=$currentFlow');
      }
    } catch (e) {
      print('사용자 데이터 로드 실패: $e');
      if (mounted) {
        setState(() {
          // 초기값
          // 이름은 강제로 기본값을 넣지 않음 (null 유지)
          currentFlow = 'before';
          padStatus = PadStatus.before;
          _isLoading = false;
        });
        
        // 사용자에게 오류 알림
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('데이터를 불러올 수 없습니다. 인터넷 연결을 확인해주세요.'),
            action: SnackBarAction(
              label: '다시 시도',
              onPressed: _loadUserData,
            ),
          ),
        );
      }
    }
}

  /// PadStatus를 Flow로 변환
  String _convertPadStatusToFlow(PadStatus status) {
    switch (status) {
      case PadStatus.before:
        return 'before';
      case PadStatus.fresh:
        return 'safe';
      case PadStatus.warning:
        return 'warning';
      case PadStatus.danger:
        return 'need';
    }
  }

  /// Firebase에 Flow 상태 업데이트
  Future<void> _updateFlowInFirebase(String flow) async {
    try {
      final latestPeriod = await _periodService.getLatestPeriod(userId!);
      if (latestPeriod != null) {
        final periodId = latestPeriod['periodId'];
        await _periodService.updateFlowBySensorStatus(periodId, flow);
        
        // UI 업데이트
        setState(() => currentFlow = flow);
      }
    } catch (e) {
      print('Flow 업데이트 실패: $e');
    }
  }

  // ↓ 디버그용 플래그
  final bool _mockBluetoothConnected = true;

  @override
  Widget build(BuildContext context) {
    final bluetooth = context.watch<BluetoothProvider>();

    final bool isConnectedForUI =
        _mockBluetoothConnected ? true : bluetooth.isConnected;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const NavBar(currentIndex: 0),
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GreetingHeader(
                      userName: name ?? '', // Firebase에서 가져온 실제 사용자 이름
                      height: 190,
                      dropAsset: 'assets/icons/moya.svg',
                      onAiTap: () => Navigator.pushNamed(context, '/ondevice'),
                      onBellTap: () => Navigator.pushNamed(context, '/notification'),
                    ),
                    
                    // 상태 카드 + 블루투스 칩
                    Transform.translate(
                      offset: const Offset(0, -80),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            CycleStatusCard(
                              isOnPeriod: isOnPeriod,
                              days: daysUntilNext,
                              dropAsset: 'assets/icons/moya.svg',
                              onTap: () {},
                              // 추가: 현재 flow 상태 전달
                              // flow: currentFlow,
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: BluetoothStatusChip(
                                // ↓ 여기서 강제로 true 사용
                                  isConnected: isConnectedForUI,
                                // isConnected: bluetooth.isConnected,
                                onTap: () => Navigator.pushNamed(context, '/setting_bluetooth'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // PeriodWidget
                    Transform.translate(
                      offset: const Offset(0, -50),
                      child: Center(
                        child: PeriodWidget(
                          status: padStatus, // Firebase에서 가져온 상태
                          showDemoToggle: false, // 개발 중에는 true, 출시 시 false
                          onStatusChanged: _onStatusChanged,
                          onStartTap: () => Navigator.pushNamed(context, '/input_recent'),
                          changeCount: changeCount,
                          lastChangeText: lastChangeText,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // 디버그 정보 (개발 중에만 표시)
                    if (_isLoading == false) ...[
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('디버그 정보:', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('사용자: ${name ?? '(이름 없음)'}'),
                              Text('현재 상태: $currentFlow'),
                              Text('메시지: ${_periodService.getFlowMessage(currentFlow)}'),
                              Text('다음까지: ${daysUntilNext}일'),
                              Text('생리 중: $isOnPeriod'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
      ),
    );
  }
}