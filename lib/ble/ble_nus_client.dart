import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ble_ids.dart';

/// ESP32(NimBLE NUS) 전용 클라이언트
class BleNusClient with ChangeNotifier {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _rx; // phone -> ESP32 (Write)
  BluetoothCharacteristic? _tx; // ESP32 -> phone (Notify)

  StreamSubscription<List<int>>? _notifySub;
  final _lines = <String>[];

  bool get isConnected => _device?.isConnected ?? false;
  List<String> get logs => List.unmodifiable(_lines);

  void _log(String m) {
    debugPrint(m);
    _lines.add(m);
    notifyListeners();
  }

  Future<void> _ensurePermissions() async {
    if (Platform.isAndroid) {
      final reqs = <Permission>[
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location, // 일부 기기에서 필요
      ];
      final results = await reqs.request();
      if (results.values.any((s) => s.isDenied || s.isPermanentlyDenied)) {
        throw Exception('Bluetooth 권한 거부됨');
      }
    }
    // iOS는 Info.plist만으로 OK (런타임 권한 없음)
  }

  Future<void> scanAndConnect({Duration scanTimeout = const Duration(seconds: 8)}) async {
    await _ensurePermissions();

    // 어댑터 ON 체크
    final state = await FlutterBluePlus.adapterState.first;
    if (state != BluetoothAdapterState.on) {
      throw Exception('블루투스가 꺼져있어요');
    }

    // 기존 연결/구독 정리
    await disconnect();

    _log('[SCAN] with NUS service filter…');
    await FlutterBluePlus.startScan(
      withServices: [BleIds.service],
      timeout: scanTimeout,
    );

    BluetoothDevice? found;

    // scanResults 스트림에서 MOYA 또는 서비스 일치하는 첫 디바이스 선정
    final results = await FlutterBluePlus.scanResults.firstWhere((list) => list.isNotEmpty);
    for (final r in results) {
      final name = r.advertisementData.advName.trim();
      if (name == 'MOYA' || r.advertisementData.serviceUuids.contains(BleIds.service)) {
        found = r.device;
        break;
      }
    }
    await FlutterBluePlus.stopScan();

    if (found == null) {
      // 이름으로만 찾아보기(제조사마다 advName 비울 때 있음)
      final results2 = await FlutterBluePlus.scanResults.firstWhere((list) => list.isNotEmpty, orElse: () => []);
      for (final r in results2) {
        if (r.advertisementData.advName == 'MOYA') {
          found = r.device; break;
        }
      }
    }

    if (found == null) {
      throw Exception('MOYA를 찾지 못했어요(가까이/전원확인/재부팅 후 다시 시도)');
    }

    _device = found;
    _log('[SCAN] found: ${found.platformName} (${found.remoteId.str})');

    await _connectAndDiscover();
  }

  Future<void> _connectAndDiscover() async {
    final dev = _device!;
    _log('[CONN] connecting…');
    await dev.connect(timeout: const Duration(seconds: 8));
    _log('[CONN] connected');

    // (선택) 안드로이드 MTU 증가
    if (Platform.isAndroid) {
      try {
        await dev.requestMtu(247);
        _log('[CONN] MTU requested 247');
      } catch (_) {}
    }

    _log('[DISC] discovering services…');
    final svcs = await dev.discoverServices();

    BluetoothCharacteristic? rx, tx;
    for (final s in svcs) {
      if (s.uuid == BleIds.service) {
        for (final c in s.characteristics) {
          if (c.uuid == BleIds.rx) rx = c;
          if (c.uuid == BleIds.tx) tx = c;
        }
      }
    }
    if (rx == null || tx == null) {
      throw Exception('NUS RX/TX characteristic을 찾지 못했어요');
    }

    _rx = rx;
    _tx = tx;

    // Notify 구독
    await _tx!.setNotifyValue(true);
    _notifySub?.cancel();
    _notifySub = _tx!.onValueReceived.listen((data) {
      final line = String.fromCharCodes(data);
      _log('[NOTIFY] $line');
    });

    _log('[READY] NUS ready. (rx: ${_rx!.uuid.str}, tx: ${_tx!.uuid.str})');
  }

  Future<void> sendText(String text) async {
    if (!isConnected || _rx == null) {
      _log('[SEND] not connected'); return;
    }
    final bytes = text.codeUnits;
    // ESP32 RX는 Write/WriteNR 모두 허용 → writeWithoutResponse가 더 빠름
    await _rx!.write(bytes, withoutResponse: true);
    _log('[SEND] $text');
  }

  Future<void> disconnect() async {
    _notifySub?.cancel();
    _notifySub = null;
    _rx = null;
    _tx = null;
    if (_device != null) {
      try {
        await _device!.disconnect();
      } catch (_) {}
    }
    _device = null;
  }

  @override
  void dispose() {
    _notifySub?.cancel();
    super.dispose();
  }
}