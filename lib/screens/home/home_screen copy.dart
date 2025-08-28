import 'dart:async'; // ★ 추가
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

// ★ 추가: BLE 처리 유틸
import 'package:moya_app/ble/ble_flow_updater.dart';

import 'package:get/get.dart';
import 'package:moya_app/controllers/menstrual_controller.dart';


class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Firebase에서 가져올 데이터들
  String? name;
  String? currentFlow; // before, safe, warning, need
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

  final MenstrualController _mc = Get.put(MenstrualController(), permanent: true);


  // 로딩 상태
  bool _isLoading = true;

  // 사용자 ID
  String? userId;

  // ★ 추가: BLE & 실시간 구독
  BleFlowUpdater? _flow;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _periodSub;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  @override
  void dispose() {
    // ★ 추가: 리소스 정리
    _periodSub?.cancel();
    _flow?.dispose();
    super.dispose();
  }

  // Firebase Auth로부터 현재 사용자 가져오기
  Future<void> _initializeUser() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        userId = currentUser.uid;
        print('현재 사용자 ID: $userId');
        await _loadUserData();
      } else {
        print('로그인된 사용자가 없음');
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
      final UserCredential result = await FirebaseAuth.instance.signInAnonymously();
      userId = result.user?.uid;
      if (userId != null) {
        print('익명 사용자로 로그인: $userId');
        await _loadUserData();
      }
    } catch (e) {
      print('익명 로그인 실패: $e');
      setState(() => _isLoading = false);
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

  /// 다음 생리까지 남은 일수 계산 (네 코드 유지)
  void _calculateDaysUntilNext(Map<String, dynamic> latestPeriod) {
    try {
      final now = DateTime.now();

      final startDate = (latestPeriod['startDate'] as Timestamp?)?.toDate();
      final endDate   = (latestPeriod['endDate']   as Timestamp?)?.toDate();
      final cycleLen  = latestPeriod['cycleLength'] as int? ?? 28;
      final periodLen = latestPeriod['periodLength'] as int? ?? 5;

      final isOnPeriodField = latestPeriod['isOnPeriod'] as bool?;

      bool onPeriod;
      int  daysLeft;

      if (isOnPeriodField != null) {
        onPeriod = isOnPeriodField;
        if (onPeriod) {
          final pseudoEnd = endDate ?? startDate?.add(Duration(days: periodLen - 1));
          if (pseudoEnd != null) {
            daysLeft = (pseudoEnd
                        .difference(DateTime(now.year, now.month, now.day))
                        .inDays + 1)
                      .clamp(0, 999);
          } else {
            daysLeft = 0;
          }
        } else {
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
        if (startDate != null) {
          final pseudoEnd = endDate ?? startDate.add(Duration(days: periodLen - 1));
          final today = DateTime(now.year, now.month, now.day);
          final startD = DateTime(startDate.year, startDate.month, startDate.day);
          final endD   = DateTime(pseudoEnd.year, pseudoEnd.month, pseudoEnd.day);

          final within = (today.isAfter(startD) || today.isAtSameMomentAs(startD)) &&
                         (today.isBefore(endD)   || today.isAtSameMomentAs(endD));

          onPeriod = within;

          if (onPeriod) {
            daysLeft = (endD.difference(today).inDays + 1).clamp(0, 999);
          } else {
            final base = endDate ?? startDate;
            final nextDate = base.add(Duration(days: cycleLen));
            daysLeft = (DateTime(nextDate.year, nextDate.month, nextDate.day)
                        .difference(today).inDays).clamp(0, 999);
          }
        } else {
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
    if (userId != null) {
      final flowStatus = _convertPadStatusToFlow(newStatus);
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
      final isConnected = await _checkFirebaseConnection();
      if (!isConnected) {
        throw Exception('Firebase 연결 실패');
      }

      print('사용자 데이터 로딩 시작: $userId');

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        print('사용자 문서가 존재하지 않음. 새로 생성...');
        await _createNewUserDocument();
      }

      final fetchedUserName = await _userService.getUserName(userId!);
      final results = await Future.wait([
        _periodService.getLatestFlow(userId!),
        _periodService.getLatestPeriod(userId!),
      ]);

      final fetchedFlow = results[0] as String?;
      final latestPeriod = results[1] as Map<String, dynamic>?;

      if (!mounted) return;

      setState(() {
        name = fetchedUserName;
        currentFlow = fetchedFlow ?? 'before';
        padStatus = _convertFlowToPadStatus(currentFlow!);
        _isLoading = false;
      });

      if (latestPeriod != null) {
        _calculateDaysUntilNext(latestPeriod);
      }

      // ========= ★ 여기부터 BLE + 실시간 반영 추가 =========
      final periodId = latestPeriod?['periodId'] as String?;
      if (periodId != null) {
        // 1) Firestore 실시간 구독: flow 변경 자동 반영
        _periodSub?.cancel();
        _periodSub = FirebaseFirestore.instance
            .collection('periods')
            .doc(periodId)
            .snapshots()
            .listen((doc) {
          final data = doc.data();
          if (data == null) return;
          final flow = data['flow'] as String? ?? 'before';
          if (!mounted) return;
          setState(() {
            currentFlow = flow;
            padStatus = _convertFlowToPadStatus(flow);
          });
        });

        // 2) BLE 스캔/연결 시작 (센서값 → 판정 → periods/{periodId}.flow 업데이트)
        _flow ??= BleFlowUpdater(periodId: periodId);
        // 비동기 시작: 실패해도 UI는 실시간 구독으로 유지됨
        _flow!
            .scanAndConnect()
            .catchError((e) => debugPrint('BLE scan/connect error: $e'));
      }
      // ========= ★ 여기까지 =========

      print('사용자 데이터 로드 완료: 이름=$name, 상태=$currentFlow');
      print('[HomeScreen] latestPeriod: $latestPeriod');

    } catch (e) {
      print('사용자 데이터 로드 실패: $e');
      if (!mounted) return;
      setState(() {
        padStatus = PadStatus.before;
        _isLoading = false;
      });
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
                        userName: name ?? '',
                        height: 190,
                        dropAsset: 'assets/icons/moya.svg',
                        onAiTap: () => Navigator.pushNamed(context, '/ondevice'),
                        onBellTap: () => Navigator.pushNamed(context, '/notification'),
                      ),

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
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: BluetoothStatusChip(
                                  isConnected: bluetooth.isConnected,
                                  onTap: () => Navigator.pushNamed(
                                      context, '/setting_bluetooth'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      Transform.translate(
                        offset: const Offset(0, -50),
                        child: Center(
                          child: PeriodWidget(
                            status: padStatus,
                            showDemoToggle: false,
                            onStatusChanged: _onStatusChanged,
                            onStartTap: () => Navigator.pushNamed(
                              context,
                              '/input_recent',
                              arguments: {
                                'userId': userId,
                                'periodId': null,
                                'nick': name,
                                'quickInput': true,
                              },
                            ),
                            changeCount: changeCount,
                            lastChangeText: lastChangeText,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

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
                              const Text('디버그 정보:', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('사용자: ${name ?? '(이름 없음)'}'),
                              Text('현재 상태: $currentFlow'),
                              if (currentFlow != null)
                                Obx(() => Text('메시지: ${_mc.statusMessage.value}')),
                              Text('다음까지: ${daysUntilNext}일'),
                              Text('생리 중: $isOnPeriod'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}