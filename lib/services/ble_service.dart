// lib/services/ble_service.dart
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moya_app/services/notification_service.dart';
import 'package:moya_app/algorithms/fluid_classifier.dart';

class BleService {
  // ---- 싱글톤 ----
  static final BleService _inst = BleService._internal();
  factory BleService() => _inst;
  BleService._internal();

  // 알림 쿨다운 관련
  bool _needNotifiedSinceLastSafe = false;
  DateTime _lastNeedNotiAt = DateTime.fromMillisecondsSinceEpoch(0);
  final Duration _needNotiCooldown = const Duration(minutes: 5);

  // ---- NUS UUID ----
  static const String _nusService = '6E400001-B5A3-F393-E0A9-E50E24DCCA9E';
  static const String _nusTx      = '6E400003-B5A3-F393-E0A9-E50E24DCCA9E';
  static const String _nusRx      = '6E400002-B5A3-F393-E0A9-E50E24DCCA9E';
  final Guid _svcGuid = Guid(_nusService);
  final Guid _txGuid  = Guid(_nusTx);
  final Guid _rxGuid  = Guid(_nusRx);

  // ---- 땀/피 분류 기준(간단 규칙) ----
  static const int _sweatDiffThreshold = 40; // 축별 큰 변화 임계값
  final FluidClassifier _classifier = FluidClassifier(
    diffThreshold: _sweatDiffThreshold,
    window: const Duration(minutes: 1), // 1분 윈도우 내 3축 감지 → sweat
  );

  // 마지막으로 반영한 flow
  String? _prevFlow;

  // ---- 단일 기기 상태 ----
  bool _isConnected = false;
  BluetoothDevice? _device;
  BluetoothCharacteristic? _txChar; // ESP32 -> App (Notify)
  BluetoothCharacteristic? _rxChar; // App   -> ESP32 (Write)
  StreamSubscription<List<int>>? _notifySub;

  // ---- 화면 구독용 스트림 ----
  final _connectionCtrl = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionCtrl.stream;
  bool get isConnected => _isConnected;

  final _sensorDataCtrl = StreamController<List<int>>.broadcast();
  Stream<List<int>> get sensorDataStream => _sensorDataCtrl.stream;

  // ---- 스캔 상태 (UI 필요시 확장) ----
  final _isScanningCtrl = StreamController<bool>.broadcast();
  Stream<bool> get isScanningStream => _isScanningCtrl.stream;
  bool _isScanning = false;
  StreamSubscription<List<ScanResult>>? _scanSub;

  // ---- Firebase 업데이트 관련 ----
  String? _currentPeriodId;
  DateTime _lastDataAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastFlowAt = DateTime.fromMillisecondsSinceEpoch(0);

  // ---- 센서 분석 ----
  static const int _changeThreshold = 10; // 변화 감지 기준
  final List<List<int>> _recent = [];     // 최근 샘플 5개 저장

  // ---------- 외부에서 periodId 설정 ----------
  void setPeriodId(String? periodId) {
    _currentPeriodId = periodId;
  }

  String? _userId;
  String? _nick;

  void setUserContext({required String userId, required String nick}) {
    _userId = userId;
    _nick = nick;
  }

  // ---------- 초기화 ----------
  Future<void> initialize() async {
    await _primeInitialConnected();
    _startWatchdog();
  }

  // ---------- 권한 ----------
  Future<void> _ensurePermissions() async {
    if (Platform.isAndroid) {
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();
    }
  }

  // ---------- 스캔 ----------
  Future<void> startScan() async {
    if (_isScanning) return;
    await _ensurePermissions();

    _isScanning = true;
    _isScanningCtrl.add(true);

    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) async {
      for (final r in results) {
        final name = r.advertisementData.advName;
        final svcList = r.advertisementData.serviceUuids.map((e) => e.toString().toUpperCase());
        final matches = (name.toUpperCase().contains('MOYA') || svcList.contains(_nusService));

        if (matches) {
          // 첫 매칭 기기에 바로 연결 (단일 기기 정책)
          await FlutterBluePlus.stopScan();
          await _scanSub?.cancel();
          _scanSub = null;
          _isScanning = false;
          _isScanningCtrl.add(false);

          try {
            await connect(r.device);
          } catch (e) {
            debugPrint('[BleService] connect during scan fail: $e');
          }
          break;
        }
      }
    });

    // NUS 필터로 스캔 시작
    await FlutterBluePlus.startScan(withServices: [_svcGuid], timeout: const Duration(seconds: 12));
    // 타임아웃 종료
    _isScanning = false;
    _isScanningCtrl.add(false);
  }

  Future<void> stopScan() async {
    if (!_isScanning) return;
    await FlutterBluePlus.stopScan();
    await _scanSub?.cancel();
    _scanSub = null;
    _isScanning = false;
    _isScanningCtrl.add(false);
  }

  // ---------- 이미 연결된 기기 있는지 초기 반영 ----------
  Future<void> _primeInitialConnected() async {
    final bonded = await FlutterBluePlus.connectedDevices;
    if (bonded.isEmpty) {
      _setConnected(false);
      return;
    }
    // 단일 정책: 첫 기기만 사용
    final d = bonded.first;
    if (await _ensureNusSubscribe(d)) {
      _device = d;
      _setConnected(true);
    } else {
      _setConnected(false);
    }
  }

  // ---------- 연결 ----------
  Future<void> connect(BluetoothDevice device) async {
    try { await device.connect(timeout: const Duration(seconds: 10)); } catch (_) {}

    final ok = await _ensureNusSubscribe(device);
    if (!ok) {
      await device.disconnect();
      throw Exception('NUS characteristics not found');
    }

    _device = device;
    _setConnected(true);
  }

  // ---------- 해제 ----------
  Future<void> disconnect() async {
    try { await _device?.disconnect(); } catch (_) {}
    await _notifySub?.cancel();
    _notifySub = null;
    _txChar = null;
    _rxChar = null;
    _device = null;
    _setConnected(false);
  }

  // ---------- NUS TX notify & RX write ----------
  Future<bool> _ensureNusSubscribe(BluetoothDevice d) async {
    final svcs = await d.discoverServices();
    BluetoothCharacteristic? tx, rx;
    for (final s in svcs) {
      if (s.uuid != _svcGuid) continue;
      for (final c in s.characteristics) {
        if (c.uuid == _txGuid) tx = c;
        if (c.uuid == _rxGuid) rx = c;
      }
    }
    if (tx == null || rx == null) return false;

    _txChar = tx;
    _rxChar = rx;

    await _txChar!.setNotifyValue(true);
    await _notifySub?.cancel();
    _notifySub = _txChar!.onValueReceived.listen((bytes) {
      final s = String.fromCharCodes(bytes).trim();  // "123,456,789" or "hb:12"
      if (s.startsWith('hb:')) return;               // 하트비트 무시
      _onSensorData(s);
    });

    return true;
  }

  Future<void> write(List<int> data, {bool withoutResponse = true}) async {
    if (_rxChar == null) throw Exception('RX characteristic not ready');
    await _rxChar!.write(data, withoutResponse: withoutResponse);
  }

  // ---------- 센서 데이터 처리 ----------
  void _onSensorData(String raw) {
    try {
      final parts = raw.split(',');
      if (parts.length < 3) return;
      final a = int.tryParse(parts[0]) ?? 0;
      final b = int.tryParse(parts[1]) ?? 0;
      final c = int.tryParse(parts[2]) ?? 0;

      final cur = [a,b,c];
      _recent.add(cur);
      if (_recent.length > 5) _recent.removeAt(0);
      _sensorDataCtrl.add(cur);
      _lastDataAt = DateTime.now();

      // 특수 케이스: 모두 0이면 즉시 safe
      if (a==0 && b==0 && c==0) {
        _updateFlow('safe','all_zero');
        return;
      }
      if (_recent.length >= 2) _analyzeAndUpdate();
    } catch (e) {
      debugPrint('[BleService] parse fail: $e');
    }
  }

  // 생리량 계산 + 분류기 적용
  Future<void> _analyzeAndUpdate() async {
    if (_currentPeriodId == null) return;
    final prev = _recent[_recent.length - 2];
    final cur  = _recent[_recent.length - 1];

    debugPrint('[BleService] 분석 시작 - prev: $prev, cur: $cur');

    // 변화량 기반 판단 (로그용)
    int changed = 0;
    List<int> changes = [];
    for (int i = 0; i < 3; i++) {
      final change = (cur[i] - prev[i]).abs();
      changes.add(change);
      if (change >= _changeThreshold) changed++;
    }
    debugPrint('[BleService] 변화량: $changes, changed: $changed');

    // === 1분 윈도우 기반 땀/피 분류 ===
    final fluid = _classifier.addSample(prev, cur);
    if (fluid == FluidType.sweat) {
      // 땀으로 판단되면 false positive 방지를 위해 flow 업데이트/알림 스킵
      debugPrint('[BleService] 분류기: sweat(땀) → flow/알림 스킵');
      return;
    }

    // === 기존 flow 판단 ===
    String? flow;
    if (changed == 2) {
      flow = 'warning'; // warning: 알림은 안 보냄
    } else if (changed >= 3) {
      flow = 'need';
    }
    // changed == 0 또는 1 → 상태 유지 (업데이트 안 함)

    // flow 업데이트 (10초 쿨다운 적용)
    if (flow != null && DateTime.now().difference(_lastFlowAt).inSeconds >= 10) {
      await _updateFlow(flow, 'sensor_change_$changed');
      if (flow == 'need') {
        await _maybeNotifyNeedOnce();
      }
    }
  }

  Future<void> _maybeNotifyNeedOnce() async {
    // if already notified since last safe AND cooldown not passed, return
    final now = DateTime.now();
    if (_needNotifiedSinceLastSafe && now.difference(_lastNeedNotiAt) < _needNotiCooldown) {
      debugPrint('[BleService] need 알림 스킵(쿨다운)');
      return;
    }

    String? uid = _userId;
    String nick = _nick ?? 'MOYA';

    if (uid == null || _nick == null) {
      if (_currentPeriodId == null) return;
      try {
        final ps = await FirebaseFirestore.instance.collection('periods').doc(_currentPeriodId).get();
        if (ps.exists) {
          uid = ps['userId'] as String? ?? uid;
          nick = (ps['nick'] as String?) ?? nick;
        }
      } catch (e) {
        debugPrint('[BleService] period 문서 조회 실패: $e');
      }
    }

    if (uid == null) return;

    // set flags BEFORE sending to avoid duplicate floods
    _needNotifiedSinceLastSafe = true;
    _lastNeedNotiAt = now;

    try {
      await NotificationService().notifyNeedFlowSplit(
        userId: uid,
        nick: nick,
        message: '지금 상태에서 바로 교체하는 걸 추천해요',
        relatedData: {
          'periodId': _currentPeriodId,
          'recommendedInterval': '3~4시간',
        },
      );
      debugPrint('[BleService] need 알림 발송 완료: userId=$uid, nick=$nick');
    } catch (e) {
      debugPrint('[BleService] need 알림 발송 실패: $e');
    }
  }

  // ---------- flow update하면서 전이 체크 ----------
  Future<void> _updateFlow(String flow, String reason) async {
    if (_currentPeriodId == null) return;
    try {
      // --- 1) 전이 감지: warning/need -> safe ---
      final wasWarningOrNeed = (_prevFlow == 'warning' || _prevFlow == 'need');
      final isNowSafe = (flow == 'safe');

      await FirebaseFirestore.instance.collection('periods').doc(_currentPeriodId).update({
        'flow': flow,
        'lastSensorUpdate': FieldValue.serverTimestamp(),
        'updateReason': reason,
        'lastSensorData': _recent.isNotEmpty ? _recent.last : [0,0,0],
      });

      // --- 2) 일일 통계 업데이트 (전이가 safe일 때만) ---
      if (wasWarningOrNeed && isNowSafe) {
        await _bumpDailyChangeAndMarkTime(_currentPeriodId!);
      }

      _prevFlow = flow;            // ← 이번 반영 상태를 저장해 다음 전이 체크에 사용
      _lastFlowAt = DateTime.now();
      if (isNowSafe) {
        _needNotifiedSinceLastSafe = false;
      }
      debugPrint('[BleService] flow -> $flow ($reason)');
    } catch (e) {
      debugPrint('[BleService] flow update fail: $e');
    }
  }

  // BleService 내부: 오늘 날짜 키와 통계 업데이트 로직
  String _todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4,'0')}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
  }

  // periods/{periodId}/daily/{YYYY-MM-DD} 문서에 changeCount++, lastChangeAt 업데이트
  Future<void> _bumpDailyChangeAndMarkTime(String periodId) async {
    final dayId = _todayKey();
    final ref = FirebaseFirestore.instance
        .collection('periods')
        .doc(periodId)
        .collection('daily')
        .doc(dayId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        tx.set(ref, {
          'changeCount': 1,
          'lastChangeAt': FieldValue.serverTimestamp(),
        });
      } else {
        tx.update(ref, {
          'changeCount': FieldValue.increment(1),
          'lastChangeAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  // ---------- 연결/워치독 ----------
  void _setConnected(bool v) {
    _isConnected = v;
    _connectionCtrl.add(v);
    debugPrint('[BleService] connected=$v');
  }

  void _startWatchdog() {
    Timer.periodic(const Duration(seconds: 20), (_) {
      final idle = DateTime.now().difference(_lastDataAt).inSeconds;
      if (_isConnected && idle > 40) {
        debugPrint('[BleService] no sensor data for $idle s');
        // 필요 시 여기에 재스캔/재연결 로직 추가 가능
      }
    });
  }

  // ---------- 정리 ----------
  Future<void> dispose() async {
    await _scanSub?.cancel();
    await _notifySub?.cancel();
    await _connectionCtrl.close();
    await _sensorDataCtrl.close();
    await _isScanningCtrl.close();
  }
}