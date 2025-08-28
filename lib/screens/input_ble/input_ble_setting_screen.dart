// lib/screens/input_ble/input_ble_setting_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:moya_app/services/ble_service.dart';

class InputBleSettingScreen extends StatefulWidget {
  @override
  State<InputBleSettingScreen> createState() => _InputBleSettingScreenState();
}

class _InputBleSettingScreenState extends State<InputBleSettingScreen> {
  final BleService _ble = BleService();

  // 화면 표시용 상태 (UI는 유지)
  bool _isScanning = false;
  bool _isConnected = false;

  // 스캔 결과(간단 목록) — 선택해서 연결 버튼 제공
  final List<ScanResult> _scanResults = [];

  // 구독
  StreamSubscription<bool>? _subConn;
  StreamSubscription<bool>? _subScan;
  StreamSubscription<List<ScanResult>>? _subScanResults;

  @override
  void initState() {
    super.initState();

    // 1) 연결 상태
    _subConn = _ble.connectionStream.listen((v) {
      if (!mounted) return;
      setState(() => _isConnected = v);
    });

    // 2) 스캔 상태
    _subScan = _ble.isScanningStream.listen((v) {
      if (!mounted) return;
      setState(() => _isScanning = v);
    });

    // 3) 스캔 결과: FlutterBluePlus 전역 스트림 구독해서 화면에 보여주기
    //    - BleService는 단일 기기 정책으로 "매칭 즉시 연결"까지 해도 되지만,
    //      여기서는 사용자가 수동으로 "연결" 버튼을 누르도록 UI를 살려둠.
    _subScanResults = FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) return;
      // 간단 필터: 이름에 MOYA 포함 or NUS 포함
      final filtered = <ScanResult>[];
      for (final r in results) {
        final name = r.advertisementData.advName;
        final svcList = r.advertisementData.serviceUuids.map((e) => e.toString().toUpperCase());
        final matches = (name.toUpperCase().contains('MOYA') ||
                         svcList.contains('6E400001-B5A3-F393-E0A9-E50E24DCCA9E'));
        if (matches) {
          // 중복 제거
          if (filtered.indexWhere((e) => e.device.remoteId.str == r.device.remoteId.str) < 0) {
            filtered.add(r);
          }
        }
      }
      setState(() {
        _scanResults
          ..clear()
          ..addAll(filtered);
      });
    });
  }

  @override
  void dispose() {
    _subConn?.cancel();
    _subScan?.cancel();
    _subScanResults?.cancel();
    super.dispose();
  }

  Future<void> _toggleScan() async {
    if (_isScanning) {
      await _ble.stopScan();
    } else {
      _scanResults.clear();
      setState(() {}); // 깔끔히 초기화
      await _ble.startScan();
    }
  }

  void _toast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : const Color(0xFFFF85B4),
      ),
    );
  }

  Future<void> _connectTo(ScanResult r) async {
    try {
      await _ble.connect(r.device);
      _toast('${r.advertisementData.advName.isNotEmpty ? r.advertisementData.advName : r.device.platformName} 에 연결했습니다');
    } catch (e) {
      _toast('연결 실패: $e', isError: true);
    }
  }

  Future<void> _disconnect() async {
    try {
      await _ble.disconnect();
      _toast('연결을 해제했습니다', isError: true);
    } catch (e) {
      _toast('해제 실패: $e', isError: true);
    }
  }

  Future<void> _sendPing() async {
    try {
      await _ble.write(const [0x70, 0x69, 0x6E, 0x67]); // "ping"
      _toast('ping 전송!');
    } catch (e) {
      _toast('전송 실패: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ====== UI는 그대로 유지하되, 소스만 단일-서비스 기준으로 바뀜 ======
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFF85B4)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.stop : Icons.search, color: const Color(0xFFFF85B4)),
            onPressed: _toggleScan,
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _toast('설정이 저장되었습니다.');
            },
            child: const Text(
              '완료',
              style: TextStyle(
                color: Color(0xFFFF85B4),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('블루투스 연결 관리',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 30),

            const Text('현재 연결 기기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
            const SizedBox(height: 15),

            // 연결된 기기 1개만 표시 (단일 기기 정책)
            _buildConnectedCard(),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('새로운 기기 연결',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                IconButton(
                  onPressed: _toggleScan,
                  icon: Icon(_isScanning ? Icons.stop : Icons.search, color: const Color(0xFFFF85B4)),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // 검색 결과 (필터링된 MOYA/NUS 기기)
            Expanded(
              child: Column(
                children: [
                  if (_isScanning)
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF85B4)),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('기기를 검색하는 중...'),
                        ],
                      ),
                    ),
                  ..._scanResults.map(_buildAvailableTile).toList(),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ====== 연결된 카드(단일 기기) ======
  Widget _buildConnectedCard() {
    if (!_isConnected) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFF85B4)),
          color: const Color(0xFFFF85B4).withOpacity(0.05),
        ),
        child: Row(
          children: [
            const Icon(Icons.bluetooth_disabled, color: Color(0xFFFF85B4), size: 24),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('연결된 기기가 없습니다', style: TextStyle(fontSize: 16, color: Colors.black)),
            ),
          ],
        ),
      );
    }

    // 연결된 상태이면 ping/해제 버튼 제공
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF85B4)),
        color: const Color(0xFFFF85B4).withOpacity(0.05),
      ),
      child: Row(
        children: [
          const Icon(Icons.bluetooth_connected, color: Color(0xFFFF85B4), size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('MOYA (연결됨)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
          ),
          IconButton(
            tooltip: 'ping 전송',
            onPressed: _sendPing,
            icon: const Icon(Icons.bolt, color: Color(0xFFFF85B4)),
          ),
          GestureDetector(
            onTap: _disconnect,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.red)),
              child: const Text('연결 해제', style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }

  // ====== 스캔 결과 타일 ======
  Widget _buildAvailableTile(ScanResult r) {
    final name = r.advertisementData.advName.isNotEmpty
        ? r.advertisementData.advName
        : (r.device.platformName.isNotEmpty ? r.device.platformName : 'Unknown');
    final addr = r.device.remoteId.str;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Icon(Icons.bluetooth, color: Colors.grey[600], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                const SizedBox(height: 4),
                Text(addr, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _connectTo(r),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF85B4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            child: const Text('연결', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}