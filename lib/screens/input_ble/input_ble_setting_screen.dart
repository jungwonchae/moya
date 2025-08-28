import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class InputBleSettingScreen extends StatefulWidget {
  @override
  _InputBleSettingScreenState createState() => _InputBleSettingScreenState();
}

class _InputBleSettingScreenState extends State<InputBleSettingScreen> {
  // ===== NUS UUIDs =====
  static const String nusService = '6E400001-B5A3-F393-E0A9-E50E24DCCA9E';
  static const String nusRx      = '6E400002-B5A3-F393-E0A9-E50E24DCCA9E'; // phone -> ESP32 (Write/NR)
  static const String nusTx      = '6E400003-B5A3-F393-E0A9-E50E24DCCA9E'; // ESP32 -> phone (Notify)

  final Guid svcGuid = Guid(nusService);
  final Guid rxGuid  = Guid(nusRx);
  final Guid txGuid  = Guid(nusTx);

  // ===== UI 모델 (기존 UI 유지용) =====
  final List<ConnectedDevice> connectedDevices = [];
  List<AvailableDevice> availableDevices = [];

  // ===== BLE 상태 =====
  bool isScanning = false;
  StreamSubscription<List<ScanResult>>? _scanSub;
  final Map<String, BluetoothDevice> _deviceById = {};
  final Map<String, BluetoothCharacteristic> _txCharById = {};
  final Map<String, BluetoothCharacteristic> _rxCharById = {};
  final Map<String, StreamSubscription<List<int>>> _notifySubs = {}; // 수정: 꺽쇠괄호 하나 제거

  @override
  void initState() {
    super.initState();
    _primeInitialConnected(); // 앱 진입 시 이미 연결된 기기 반영
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    for (final s in _notifySubs.values) {
      s.cancel();
    }
    super.dispose();
  }

  // ---- 초기 연결 목록 채우기 (UI 그대로 유지) ----
  Future<void> _primeInitialConnected() async {
    final bonded = await FlutterBluePlus.connectedDevices;
    connectedDevices.clear();
    for (final d in bonded) {
      _deviceById[d.remoteId.str] = d;
      connectedDevices.add(
        ConnectedDevice(
          name: d.platformName.isNotEmpty ? d.platformName : 'Unknown',
          address: d.remoteId.str,
          isConnected: true,
        ),
      );
    }
    setState(() {});
  }

  // ---- 권한요청 (iOS/Android) ----
  Future<void> _ensurePermissions() async {
    if (Platform.isAndroid) {
      // Android 12+ 권한
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location, // 일부 기기에서 필요
      ].request();
    } else if (Platform.isIOS) {
      // iOS는 Info.plist 키만 있으면 됨 (추가 런타임 권한 없음)
    }
  }

  // ---- 스캔 토글 (UI 버튼 유지) ----
  void _scanForDevices() async {
    if (isScanning) {
      await FlutterBluePlus.stopScan();
      await _scanSub?.cancel();
      _scanSub = null;
      setState(() {
        isScanning = false;
      });
      return;
    }

    await _ensurePermissions();

    availableDevices = []; // 새로고침 느낌
    setState(() {
      isScanning = true;
    });

    // 스캔 결과 수신
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      bool changed = false;
      for (final r in results) {
        final adv = r.advertisementData;
        // NUS UUID 광고 혹은 이름에 MOYA 포함 필터
        final matchesUuid = adv.serviceUuids.map((e) => e.toString().toUpperCase()).contains(nusService); // 수정: toString() 추가
        final matchesName = (adv.advName.isNotEmpty && adv.advName.toUpperCase().contains('MOYA'));

        if (matchesUuid || matchesName) {
          final addr = r.device.remoteId.str;
          // 중복 방지
          if (availableDevices.indexWhere((e) => e.address == addr) < 0 &&
              connectedDevices.indexWhere((e) => e.address == addr) < 0) {
            _deviceById[addr] = r.device;
            availableDevices.add(
              AvailableDevice(
                name: adv.advName.isNotEmpty ? adv.advName : (r.device.platformName.isNotEmpty ? r.device.platformName : 'Unknown'),
                address: addr,
              ),
            );
            changed = true;
          }
        }
      }
      if (changed) setState(() {});
    });

    // withServices로 NUS만 우선 스캔
    FlutterBluePlus.startScan(
      withServices: [svcGuid],
      timeout: const Duration(seconds: 12),
    ).then((_) {
      // timeout 후 자동 stop
      if (mounted) {
        setState(() {
          isScanning = false;
        });
      }
    });
  }

  // ---- 연결 (UI의 '연결' 버튼에 바인딩) ----
  Future<void> _connectToNewDevice(AvailableDevice device) async {
    final d = _deviceById[device.address];
    if (d == null) {
      _toast('장치를 찾을 수 없어요.');
      return;
    }

    // 스캔 중이면 잠깐 중지
    if (isScanning) {
      await FlutterBluePlus.stopScan();
      await _scanSub?.cancel();
      _scanSub = null;
      setState(() {
        isScanning = false;
      });
    }

    try {
      await d.connect(timeout: const Duration(seconds: 10));
    } catch (e) {
      // 이미 연결된 경우 예외 발생 가능
      // ignore
    }

    // 서비스 탐색 -> NUS 캐릭터 찾기
    final services = await d.discoverServices();
    BluetoothCharacteristic? tx;
    BluetoothCharacteristic? rx;
    for (final s in services) {
      if (s.uuid == svcGuid) {
        for (final c in s.characteristics) {
          if (c.uuid == txGuid) tx = c;
          if (c.uuid == rxGuid) rx = c;
        }
      }
    }

    if (tx == null || rx == null) {
      _toast('NUS 캐릭터리스틱을 찾지 못했어요.');
      await d.disconnect();
      return;
    }

    _txCharById[d.remoteId.str] = tx;
    _rxCharById[d.remoteId.str] = rx;

    // Notify 구독
    await tx.setNotifyValue(true);
    _notifySubs[d.remoteId.str]?.cancel();
    _notifySubs[d.remoteId.str] = tx.onValueReceived.listen((data) {
      // ESP32 -> 앱 수신 (hb:1, "123,456,789" 등)
      final text = String.fromCharCodes(data);
      // 필요 시 여기서 상태 저장 / 파싱
      debugPrint('[MOYA][RX from ESP32] $text');
    });

    // UI 목록 이동
    setState(() {
      connectedDevices.add(
        ConnectedDevice(
          name: device.name,
          address: device.address,
          isConnected: true,
        ),
      );
      availableDevices.removeWhere((e) => e.address == device.address);
    });

    _toast('${device.name}에 연결되었습니다!');
  }

  // ---- 연결 해제 (UI의 '연결 해제') ----
  void _showDisconnectDialog(ConnectedDevice device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('연결 해제'),
        content: Text('${device.name}\n${device.address}\n\n기기 연결을 취소하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('아니오')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final d = _deviceById[device.address];
              if (d != null) {
                try {
                  await d.disconnect();
                } catch (_) {}
              }
              _notifySubs[device.address]?.cancel();
              _notifySubs.remove(device.address);
              _txCharById.remove(device.address);
              _rxCharById.remove(device.address);

              setState(() {
                connectedDevices.removeWhere((e) => e.address == device.address);
              });
              _toast('${device.name} 연결이 해제되었습니다.', isError: true);
            },
            child: const Text('예', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ---- (옵션) 간단 Write 보내기: MOYA에 "ping" ----
  Future<void> _writePingTo(String address) async {
    final rx = _rxCharById[address];
    if (rx == null) {
      _toast('쓰기 특성이 준비되지 않았어요.');
      return;
    }
    try {
      await rx.write(const [0x70, 0x69, 0x6E, 0x67], withoutResponse: true); // "ping"
      _toast('ping 전송!');
    } catch (e) {
      _toast('전송 실패: $e', isError: true);
    }
  }

  void _toast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : const Color(0xFFFF85B4)),
    );
  }

  // ================== UI (기존과 동일) ==================
  @override
  Widget build(BuildContext context) {
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

            // 연결된 기기 (UI 동일) + "ping" 액션만 살짝 추가(아이콘)
            ...connectedDevices.map((device) => _buildConnectedDeviceItem(device)).toList(),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('새로운 기기 연결',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                IconButton(
                  onPressed: _scanForDevices,
                  icon: Icon(isScanning ? Icons.stop : Icons.search, color: const Color(0xFFFF85B4)),
                ),
              ],
            ),
            const SizedBox(height: 15),

            Expanded(
              child: Column(
                children: [
                  if (isScanning)
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF85B4))),
                          ),
                          SizedBox(width: 12),
                          Text('기기를 검색하는 중...'),
                        ],
                      ),
                    ),
                  ...availableDevices.map((device) => _buildAvailableDeviceItem(device)).toList(),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- 기존 카드 UI 유지 + "핑" 아이콘만 오른쪽에 추가 (UI 배치는 동일 라인 유지) ---
  Widget _buildConnectedDeviceItem(ConnectedDevice device) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                const SizedBox(height: 4),
                Text(device.address, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          // ping 아이콘 (레이아웃 영향 최소화)
          IconButton(
            tooltip: 'ping 전송',
            onPressed: () => _writePingTo(device.address),
            icon: const Icon(Icons.bolt, color: Color(0xFFFF85B4)),
          ),
          GestureDetector(
            onTap: () => _showDisconnectDialog(device),
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

  Widget _buildAvailableDeviceItem(AvailableDevice device) {
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
                Text(device.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                const SizedBox(height: 4),
                Text(device.address, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _connectToNewDevice(device),
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

// ===== 기존 모델 유지 =====
class ConnectedDevice {
  final String name;
  final String address;
  final bool isConnected;
  ConnectedDevice({required this.name, required this.address, required this.isConnected});
}

class AvailableDevice {
  final String name;
  final String address;
  AvailableDevice({required this.name, required this.address});
}