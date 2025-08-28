// 전역 싱글톤 BLE 서비스
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:moya_app/models/ble_models.dart';

class BleService {
  static final BleService _inst = BleService._internal();
  factory BleService() => _inst;
  BleService._internal();

  // NUS UUID
  static const String _nusService = '6E400001-B5A3-F393-E0A9-E50E24DCCA9E';
  static const String _nusTx      = '6E400003-B5A3-F393-E0A9-E50E24DCCA9E';
  static const String _nusRx      = '6E400002-B5A3-F393-E0A9-E50E24DCCA9E';
  final Guid _svcGuid = Guid(_nusService);
  final Guid _txGuid  = Guid(_nusTx);
  final Guid _rxGuid  = Guid(_nusRx);

  // 상태 보관
  final _available = <String, AvailableDevice>{};
  final _connected = <String, ConnectedDevice>{};
  final _txChar = <String, BluetoothCharacteristic>{};
  final _rxChar = <String, BluetoothCharacteristic>{};
  final _notifySubs = <String, StreamSubscription<List<int>>>{};

  // Streams (화면은 이거만 구독)
  final _availableCtrl = StreamController<List<AvailableDevice>>.broadcast();
  Stream<List<AvailableDevice>> get availableDevicesStream => _availableCtrl.stream;

  final _connectedCtrl = StreamController<List<ConnectedDevice>>.broadcast();
  Stream<List<ConnectedDevice>> get connectedDevicesStream => _connectedCtrl.stream;

  final _isScanningCtrl = StreamController<bool>.broadcast();
  Stream<bool> get isScanningStream => _isScanningCtrl.stream;

  final _sensorDataCtrl = StreamController<List<int>>.broadcast();
  Stream<List<int>> get sensorDataStream => _sensorDataCtrl.stream;

  final StreamController<bool> _connectionStateController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionStateController.stream;

  bool _isScanning = false;
  StreamSubscription<List<ScanResult>>? _scanSub;

  String? _currentPeriodId;                 // 홈에서 세팅
  DateTime _lastDataAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastFlowAt = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _changeThreshold = 20;
  final _recent = <List<int>>[];

  // ---------- 초기화 ----------
  Future<void> initialize() async {
    // 앱 시작 시, 이미 연결된 기기 반영
    await _primeInitialConnected();
    // 데이터 워치독
    _startWatchdog();
  }

  void setPeriodId(String? periodId) {
    _currentPeriodId = periodId;
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

    _available.clear();
    _isScanning = true;
    _isScanningCtrl.add(true);

    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      bool changed = false;
      for (final r in results) {
        final name = r.advertisementData.advName;
        final svcList = r.advertisementData.serviceUuids.map((e) => e.toString().toUpperCase());
        final matches = name.toUpperCase().contains('MOYA') || svcList.contains(_nusService);
        if (!matches) continue;

        final addr = r.device.remoteId.str;
        if (_available.containsKey(addr) || _connected.containsKey(addr)) continue;

        _available[addr] = AvailableDevice(
          name: name.isNotEmpty ? name : (r.device.platformName.isNotEmpty ? r.device.platformName : 'Unknown'),
          address: addr,
          dev: r.device,
        );
        changed = true;
      }
      if (changed) _availableCtrl.add(_available.values.toList());
    });

    await FlutterBluePlus.startScan(withServices: [_svcGuid], timeout: const Duration(seconds: 12));
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

  // ---------- 초기 연결 목록 ----------
  Future<void> _primeInitialConnected() async {
    final bonded = await FlutterBluePlus.connectedDevices;
    _connected.clear();
    for (final d in bonded) {
      _connected[d.remoteId.str] = ConnectedDevice(
        name: d.platformName.isNotEmpty ? d.platformName : 'Unknown',
        address: d.remoteId.str,
        dev: d,
      );
      await _ensureNusSubscribe(d); // 알림 구독
    }
    _connectedCtrl.add(_connected.values.toList());
  }

  // ---------- 연결/해제 ----------
  Future<void> connect(AvailableDevice target) async {
    final d = target.dev;
    try { await d.connect(timeout: const Duration(seconds: 10)); } catch (_) {}

    final ok = await _ensureNusSubscribe(d);
    if (!ok) {
      await d.disconnect();
      throw Exception('NUS characteristics not found');
    }
    _available.remove(target.address);
    _connected[target.address] = ConnectedDevice(name: target.name, address: target.address, dev: d);
    _availableCtrl.add(_available.values.toList());
    _connectedCtrl.add(_connected.values.toList());
  }

  Future<void> disconnect(ConnectedDevice target) async {
    try { await target.dev.disconnect(); } catch (_) {}
    _notifySubs[target.address]?.cancel();
    _notifySubs.remove(target.address);
    _txChar.remove(target.address);
    _rxChar.remove(target.address);
    _connected.remove(target.address);
    _connectedCtrl.add(_connected.values.toList());
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

    _txChar[d.remoteId.str] = tx!;
    _rxChar[d.remoteId.str] = rx!;

    await tx!.setNotifyValue(true);
    await _notifySubs[d.remoteId.str]?.cancel();
    _notifySubs[d.remoteId.str] = tx!.onValueReceived.listen((bytes) {
      final s = String.fromCharCodes(bytes).trim();  // "123,456,789" or "hb:12"
      if (s.startsWith('hb:')) return;
      _onSensorData(s);
    });

    return true;
  }

  Future<void> write(String address, List<int> data, {bool withoutResponse = true}) async {
    final rx = _rxChar[address];
    if (rx == null) throw Exception('RX characteristic not ready');
    await rx.write(data, withoutResponse: withoutResponse);
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

      // 0,0,0 이면 즉시 safe
      if (a==0 && b==0 && c==0) {
        _updateFlow('safe','all_zero');
        return;
      }
      if (_recent.length >= 2) _analyzeAndUpdate();
    } catch (e) {
      debugPrint('[BleService] parse fail: $e');
    }
  }

  void _analyzeAndUpdate() {
    if (_currentPeriodId == null) return;
    final prev = _recent[_recent.length-2];
    final cur  = _recent[_recent.length-1];
    int changed = 0;
    for (int i=0;i<3;i++) {
      if ((cur[i]-prev[i]).abs() >= _changeThreshold) changed++;
    }
    String? flow;
    if (changed == 0) flow = 'safe';
    else if (changed == 2) flow = 'warning';
    else if (changed >= 3) flow = 'need';

    if (flow != null && DateTime.now().difference(_lastFlowAt).inSeconds >= 10) {
      _updateFlow(flow, 'sensor_change_$changed');
    }
  }

  Future<void> _updateFlow(String flow, String reason) async {
    if (_currentPeriodId == null) return;
    try {
      await FirebaseFirestore.instance.collection('periods').doc(_currentPeriodId).update({
        'flow': flow,
        'lastSensorUpdate': FieldValue.serverTimestamp(),
        'updateReason': reason,
        'lastSensorData': _recent.isNotEmpty ? _recent.last : [0,0,0],
      });
      _lastFlowAt = DateTime.now();
      debugPrint('[BleService] flow -> $flow ($reason)');
    } catch (e) {
      debugPrint('[BleService] flow update fail: $e');
    }
  }

  // ---------- 워치독(데이터 멈추면 재탐색/재연결 등 넣고 싶으면 확장) ----------
  void _startWatchdog() {
    Timer.periodic(const Duration(seconds: 20), (_) {
      final idle = DateTime.now().difference(_lastDataAt).inSeconds;
      if (idle > 40 && _connected.isNotEmpty) {
        debugPrint('[BleService] no data for $idle s');
        // 필요하면 여기서 재연결 로직 추가 가능
      }
    });
  }

  // ---------- 정리 ----------
  Future<void> dispose() async {
    await _scanSub?.cancel();
    for (final s in _notifySubs.values) { await s.cancel(); }
    await _availableCtrl.close();
    await _connectedCtrl.close();
    await _isScanningCtrl.close();
    await _sensorDataCtrl.close();
  }
}