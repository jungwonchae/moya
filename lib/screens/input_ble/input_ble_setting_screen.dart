// lib/screens/input_ble/input_ble_setting_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:moya_app/services/ble_service.dart';
import 'package:moya_app/models/ble_models.dart';

class InputBleSettingScreen extends StatefulWidget {
  @override
  State<InputBleSettingScreen> createState() => _InputBleSettingScreenState();
}

class _InputBleSettingScreenState extends State<InputBleSettingScreen> {
  final BleService _ble = BleService();

  List<ConnectedDevice> _connected = [];
  List<AvailableDevice> _available = [];
  bool _isScanning = false;

  StreamSubscription<List<ConnectedDevice>>? _subConn;
  StreamSubscription<List<AvailableDevice>>? _subAvail;
  StreamSubscription<bool>? _subScan;

  @override
  void initState() {
    super.initState();
    // 전역 서비스 스트림 구독만
    _subConn  = _ble.connectedDevicesStream.listen((v) => setState(() => _connected = v));
    _subAvail = _ble.availableDevicesStream.listen((v) => setState(() => _available = v));
    _subScan  = _ble.isScanningStream.listen((v) => setState(() => _isScanning = v));
  }

  @override
  void dispose() {
    _subConn?.cancel();
    _subAvail?.cancel();
    _subScan?.cancel();
    super.dispose();
  }

  Future<void> _toggleScan() async {
    if (_isScanning) {
      await _ble.stopScan();
    } else {
      await _ble.startScan();
    }
  }

  void _toast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : const Color(0xFFFF85B4)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ====== UI는 그대로 ======
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
            child: const Text('완료', style: TextStyle(color: Color(0xFFFF85B4), fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('블루투스 연결 관리', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 30),
            const Text('현재 연결 기기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
            const SizedBox(height: 15),

            ..._connected.map(_buildConnectedDeviceItem).toList(),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('새로운 기기 연결', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                IconButton(
                  onPressed: _toggleScan,
                  icon: Icon(_isScanning ? Icons.stop : Icons.search, color: const Color(0xFFFF85B4)),
                ),
              ],
            ),
            const SizedBox(height: 15),

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
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF85B4))),
                          ),
                          SizedBox(width: 12),
                          Text('기기를 검색하는 중...'),
                        ],
                      ),
                    ),
                  ..._available.map(_buildAvailableDeviceItem).toList(),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

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
          IconButton(
            tooltip: 'ping 전송',
            onPressed: () => _ble.write(device.address, const [0x70, 0x69, 0x6E, 0x67]),
            icon: const Icon(Icons.bolt, color: Color(0xFFFF85B4)),
          ),
          GestureDetector(
            onTap: () async {
              await _ble.disconnect(device);
              _toast('${device.name} 연결이 해제되었습니다.', isError: true);
            },
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
            onPressed: () => _ble.connect(device),
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