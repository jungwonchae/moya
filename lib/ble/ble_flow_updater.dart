// lib/ble/ble_flow_updater.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

typedef FlowChanged = void Function(String flow); // 'safe' | 'warning' | 'need'
typedef RawChanged  = void Function(List<int> raw); // [raw0, raw1, raw2]

class BleFlowUpdater {
  static const String targetName = 'MOYA';
  // NUS UUIDs (ESP32 코드와 동일)
  static final Guid nusService = Guid('6E400001-B5A3-F393-E0A9-E50E24DCCA9E');
  static final Guid txChar     = Guid('6E400003-B5A3-F393-E0A9-E50E24DCCA9E'); // Notify (ESP->Phone)

  final String? periodId; // 있으면 전달, 없어도 동작
  final FlowChanged? onFlowChanged;
  final RawChanged?  onRawChanged;

  BluetoothDevice? _device;
  StreamSubscription<List<int>>? _notifySub;

  // 변화 감지 기준
  // 직전 샘플과의 절대 차이가 threshold 이상이면 "반응"
  final int threshold;
  List<int>? _prev; // 직전 raw 3ch

  bool _connected = false;
  bool get isConnected => _connected;

  BleFlowUpdater({
    this.periodId,
    this.onFlowChanged,
    this.onRawChanged,
    this.threshold = 30, // 필요시 조정
  });

  Future<void> scanAndConnect({Duration timeout = const Duration(seconds: 6)}) async {
    // 스캔
    final scanResults = <ScanResult>[];
    await FlutterBluePlus.startScan(timeout: timeout);
    FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        if (r.device.platformName == targetName || r.advertisementData.advName == targetName) {
          scanResults.add(r);
        }
      }
    });
    await FlutterBluePlus.stopScan();

    // 가장 강한 RSSI 선택
    if (scanResults.isEmpty) {
      throw 'MOYA를 찾지 못했어요';
    }
    scanResults.sort((a, b) => (b.rssi).compareTo(a.rssi));
    _device = scanResults.first.device;

    // 연결
    try {
      await _device!.connect(
        autoConnect: false,
        timeout: const Duration(seconds: 8),
      );
    } catch (e) {
      // 이미 연결 상태인지 확인
      final state = await _device!.connectionState.first;
      if (state != BluetoothConnectionState.connected) {
        rethrow; // 진짜 에러라면 다시 throw
      }
}
    _connected = true;

    // 서비스 탐색
    final services = await _device!.discoverServices();
    final nus = services.firstWhere((s) => s.uuid == nusService, orElse: () => throw 'NUS 서비스 없음');
    final tx = nus.characteristics.firstWhere((c) => c.uuid == txChar && c.properties.notify,
        orElse: () => throw 'TX notify 캐릭터리스틱 없음');

    // Notify 구독
    await tx.setNotifyValue(true);
    _notifySub = tx.onValueReceived.listen(_onNotify, onError: (e) {});

    // 끝
  }

  void _onNotify(List<int> data) {
    // ESP32가 "123,456,789" ASCII CSV로 보냄
    try {
      final s = String.fromCharCodes(data);
      final parts = s.trim().split(',');
      if (parts.length != 3) return;
      final raw = parts.map((e) => int.parse(e)).toList(); // [raw0, raw1, raw2]
      onRawChanged?.call(raw);

      // 변화 개수 계산
      int diffCnt = 0;
      if (_prev != null) {
        for (int i = 0; i < 3; i++) {
          if ((raw[i] - _prev![i]).abs() >= threshold) diffCnt++;
        }
      }
      _prev = raw;

      // 규칙: 0개 반응 → safe, 2개 반응 → warning, 3개 반응 → need
      // (1개 반응은 사용자가 안 적어줬으니 safe로 처리)
      String flow;
      if (diffCnt >= 3) {
        flow = 'need';
      } else if (diffCnt >= 2) {
        flow = 'warning';
      } else {
        flow = 'safe';
      }
      onFlowChanged?.call(flow);
    } catch (_) {
      // 파싱 실패 무시
    }
  }

  Future<void> disconnect() async {
    try {
      await _notifySub?.cancel();
      _notifySub = null;
      if (_device != null) {
        await _device!.disconnect();
      }
    } finally {
      _connected = false;
      _prev = null;
    }
  }

  void dispose() {
    disconnect();
  }
}