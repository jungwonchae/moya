// lib/screens/home/home_screen.dart
import 'dart:async';
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
import 'package:moya_app/services/ble_service.dart';

import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Firebase 데이터
  String? name;
  String? currentFlow;                 // 'before' | 'safe' | 'warning' | 'need'
  int daysUntilNext = 5;
  bool isOnPeriod = false;

  // UI 상태
  PadStatus padStatus = PadStatus.before;
  bool _isLoading = true;

  // 센서/연결 디버그 표시용
  bool _isBleConnected = false;
  List<int>? _latestSensorData;
  DateTime _lastDataTime = DateTime.now();

  // 서비스
  final _userService = UserService();
  final _periodService = PeriodService();
  final _ble = BleService(); // ✅ 싱글톤(전역)

  // 로그인 정보
  String? userId;

  // 구독 핸들러
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _periodSub;
  StreamSubscription<bool>? _bleConnectionSub;
  StreamSubscription<List<int>>? _sensorDataSub;

  @override
  void initState() {
    super.initState();
    _initUserThenLoad();
    _subscribeBleStreams();
    _ble.connectionStream.listen((ok) {
      setState(() => _isBleConnected = ok);
    });
    _ble.sensorDataStream.listen((v) {
      setState(() => _latestSensorData = v);
    });
  }

  @override
  void dispose() {
    _periodSub?.cancel();
    _bleConnectionSub?.cancel();
    _sensorDataSub?.cancel();
    super.dispose();
  }

  // ============ BLE 구독만 (연결/스캔은 main.dart) ============
  void _subscribeBleStreams() {
    _bleConnectionSub = _ble.connectionStream.listen((connected) {
      if (!mounted) return;
      setState(() => _isBleConnected = connected);
    });

    _sensorDataSub = _ble.sensorDataStream.listen((values) {
      if (!mounted) return;
      setState(() {
        _latestSensorData = values;
        _lastDataTime = DateTime.now();
      });
    });
  }

  // ============ 사용자 초기화 ============
  Future<void> _initUserThenLoad() async {
    try {
      final cur = FirebaseAuth.instance.currentUser;
      if (cur == null) {
        final cred = await FirebaseAuth.instance.signInAnonymously();
        userId = cred.user?.uid;
      } else {
        userId = cur.uid;
      }
      if (userId == null) throw Exception('no uid');

      await _ensureUserDoc();
      await _loadUserData();

      // 최신 periodId를 BLE 서비스에 알려서 Firebase 업데이트 타깃 설정
      final latest = await _periodService.getLatestPeriod(userId!);
      final periodId = latest?['periodId'] as String?;
      if (periodId != null) {
        _ble.setPeriodId(periodId); // 중앙 서비스에 periodId 전달
        _subscribePeriodDoc(periodId); // UI는 실시간 반영만
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('초기화 실패: $e')),
      );
    }
  }

  Future<void> _ensureUserDoc() async {
    final ref = FirebaseFirestore.instance.collection('users').doc(userId);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({'createdAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    }
  }

  Future<void> _loadUserData() async {
    if (!mounted || userId == null) return;
    setState(() => _isLoading = true);

    try {
      final fetchedName = await _userService.getUserName(userId!);
      final fetchedFlow = await _periodService.getLatestFlow(userId!);
      final latestPeriod = await _periodService.getLatestPeriod(userId!);

      setState(() {
        name = fetchedName;
        currentFlow = fetchedFlow ?? 'before';
        padStatus = _flowToPad(currentFlow!);
        _isLoading = false;
      });

      if (latestPeriod != null) {
        _calcDays(latestPeriod);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        padStatus = PadStatus.before;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('데이터 로드 실패: $e'),
          action: SnackBarAction(label: '다시 시도', onPressed: _loadUserData),
        ),
      );
    }
  }

  void _subscribePeriodDoc(String periodId) {
    _periodSub?.cancel();
    _periodSub = FirebaseFirestore.instance
        .collection('periods')
        .doc(periodId)
        .snapshots()
        .listen((doc) {
      final data = doc.data();
      if (data == null) return;
      final flow = (data['flow'] as String?) ?? 'before';
      if (!mounted) return;
      setState(() {
        currentFlow = flow;
        padStatus = _flowToPad(flow);
      });
    });
  }

  // ============ 유틸 ============
  PadStatus _flowToPad(String flow) {
    switch (flow) {
      case 'safe': return PadStatus.fresh;
      case 'warning': return PadStatus.warning;
      case 'need': return PadStatus.danger;
      case 'before':
      default: return PadStatus.before;
    }
  }

  void _calcDays(Map<String, dynamic> latest) {
    try {
      final now = DateTime.now();
      final startDate = (latest['startDate'] as Timestamp?)?.toDate();
      final endDate   = (latest['endDate']   as Timestamp?)?.toDate();
      final cycleLen  = latest['cycleLength'] as int? ?? 28;
      final periodLen = latest['periodLength'] as int? ?? 5;
      final isOn = latest['isOnPeriod'] as bool?;

      bool onPeriod;
      int  left;

      if (isOn != null) {
        onPeriod = isOn;
        if (onPeriod) {
          final pseudoEnd = endDate ?? startDate?.add(Duration(days: periodLen - 1));
          left = pseudoEnd == null ? 0
              : (pseudoEnd.difference(DateTime(now.year, now.month, now.day)).inDays + 1).clamp(0, 999);
        } else {
          final base = endDate ?? startDate;
          if (base == null) {
            left = 0;
          } else {
            final next = base.add(Duration(days: cycleLen));
            left = (DateTime(next.year, next.month, next.day)
                    .difference(DateTime(now.year, now.month, now.day)).inDays)
                .clamp(0, 999);
          }
        }
      } else {
        if (startDate == null) {
          onPeriod = false;
          left = 0;
        } else {
          final pseudoEnd = endDate ?? startDate.add(Duration(days: periodLen - 1));
          final today = DateTime(now.year, now.month, now.day);
          final startD = DateTime(startDate.year, startDate.month, startDate.day);
          final endD   = DateTime(pseudoEnd.year, pseudoEnd.month, pseudoEnd.day);
          final within = (today.isAfter(startD) || today.isAtSameMomentAs(startD)) &&
                         (today.isBefore(endD)   || today.isAtSameMomentAs(endD));
          onPeriod = within;
          left = onPeriod
              ? (endD.difference(today).inDays + 1).clamp(0, 999)
              : (DateTime((endDate ?? startDate).add(Duration(days: cycleLen)).year,
                          (endDate ?? startDate).add(Duration(days: cycleLen)).month,
                          (endDate ?? startDate).add(Duration(days: cycleLen)).day)
                    .difference(today)
                    .inDays)
                  .clamp(0, 999);
        }
      }

      setState(() {
        daysUntilNext = left;
        isOnPeriod = onPeriod;
      });
    } catch (e) {
      debugPrint('[Home] 날짜 계산 실패: $e');
    }
  }

  Future<void> _refresh() => _loadUserData();

  // 사용자가 PeriodWidget에서 수동으로 상태 바꿀 경우(테스트용)
  void _onStatusChanged(PadStatus s) async {
    setState(() => padStatus = s);
    final flow = switch (s) {
      PadStatus.before => 'before',
      PadStatus.fresh  => 'safe',
      PadStatus.warning=> 'warning',
      PadStatus.danger => 'need',
    };
    try {
      final latest = await _periodService.getLatestPeriod(userId!);
      if (latest != null) {
        await _periodService.updateFlowBySensorStatus(latest['periodId'], flow);
      }
    } catch (e) {
      debugPrint('[Home] flow 수동 업데이트 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bluetooth = context.watch<BluetoothProvider>(); // 기존 UI 의존성 유지

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const NavBar(currentIndex: 0),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _refresh,
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
                                  isConnected: _isBleConnected,
                                  onTap: () => Navigator.pushNamed(context, '/setting_bluetooth'),
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
                            onStatusChanged: _onStatusChanged, // 테스트용 수동 변경
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
                            changeCount: 0,
                            lastChangeText: '',
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ===== 디버그 정보 =====
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
                              Text('다음까지: ${daysUntilNext}일'),
                              Text('생리 중: $isOnPeriod'),
                              Text('BLE 연결: ${_isBleConnected ? '연결됨' : '연결 안됨'}'),
                              if (_latestSensorData != null) Text('최신 센서값: $_latestSensorData'),
                              Text('마지막 수신: ${DateTime.now().difference(_lastDataTime).inSeconds}초 전'),
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