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

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Firebase에서 가져올 데이터들
  String userName = 'MOYA';
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
  
  // 사용자 ID (실제 구현에서는 로그인 시스템에서 가져와야 함)
  String? userId; // Firebase Auth에서 가져오거나 임시 ID 사용

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Firebase에서 사용자 데이터 로드
  Future<void> _loadUserData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);

    try {
      // Firebase Console의 users 컬렉션에서 실제 문서 ID 사용
      // 예: 'iT6h4kPdUmmodcF4GRJ4' (Firebase Console에서 확인한 실제 ID)
      userId = 'iT6h4kPdUmmodcF4GRJ4'; // ← Firebase Console에서 복사한 실제 문서 ID
      
      if (userId != null) {
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
            // UserService에서 가져온 이름 사용, 없으면 'MOYA' 기본값
            userName = fetchedUserName ?? 'MOYA';
            currentFlow = fetchedFlow ?? 'before';
            padStatus = _convertFlowToPadStatus(currentFlow);
            
            // 다음 생리까지 남은 일수 계산
            if (latestPeriod != null) {
              _calculateDaysUntilNext(latestPeriod);
            }
            
            _isLoading = false;
          });
          
          print('사용자 데이터 로드 완료: 이름=$userName, 상태=$currentFlow');
        }
      } else {
        // userId가 없는 경우 기본값 사용
        if (mounted) {
          setState(() {
            userName = 'MOYA';
            currentFlow = 'before';
            padStatus = PadStatus.before;
            _isLoading = false;
          });
        }
      }
    } on FirebaseException catch (e) {
      print('Firebase 오류: ${e.code} ${e.message}');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 로드 실패: ${e.message}')),
        );
      }
    } catch (e) {
      print('사용자 데이터 로드 실패: $e');
      if (mounted) {
        setState(() {
          // 오류 발생 시 기본값 사용
          userName = 'MOYA';
          currentFlow = 'before'; 
          padStatus = PadStatus.before;
          _isLoading = false;
        });
      }
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
      final endDate = (latestPeriod['endDate'] as Timestamp?)?.toDate();
      final cycleLength = latestPeriod['cycleLength'] as int? ?? 28;
      
      if (endDate != null) {
        final nextPeriodDate = endDate.add(Duration(days: cycleLength));
        final daysLeft = nextPeriodDate.difference(DateTime.now()).inDays;
        
        setState(() {
          daysUntilNext = daysLeft > 0 ? daysLeft : 0;
          isOnPeriod = daysLeft <= 0; // 예상일이 지났으면 생리 중
        });
      }
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

  @override
  Widget build(BuildContext context) {
    final bluetooth = context.watch<BluetoothProvider>();

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
                      userName: userName, // Firebase에서 가져온 실제 사용자 이름
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
                                isConnected: bluetooth.isConnected,
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
                          showDemoToggle: true, // 개발 중에는 true, 출시 시 false
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
                              Text('사용자: $userName'),
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