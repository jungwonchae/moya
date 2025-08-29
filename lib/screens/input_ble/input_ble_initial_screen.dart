import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:moya_app/themes/colortheme.dart';
import 'package:moya_app/widgets/confirm_button.dart';
import 'package:moya_app/services/ble_service.dart';

class InputBleInitialScreen extends StatefulWidget {
  @override
  _InputBleInitialScreenState createState() => _InputBleInitialScreenState();
}

class _InputBleInitialScreenState extends State<InputBleInitialScreen> {
  final BleService _ble = BleService();
  
  bool isScanning = false;
  BluetoothDevice? selectedDevice;
  List<ScanResult> availableDevices = [];
  
  // 구독
  StreamSubscription<bool>? _subConn;
  StreamSubscription<bool>? _subScan;
  StreamSubscription<List<ScanResult>>? _subScanResults;
  
  @override
  void initState() {
    super.initState();
    _initializeBle();
  }
  
  void _initializeBle() {
    // 연결 상태 구독
    _subConn = _ble.connectionStream.listen((connected) {
      if (!mounted) return;
      // 연결된 기기가 있으면 선택 상태로 설정
      setState(() {});
    });

    // 스캔 상태 구독
    _subScan = _ble.isScanningStream.listen((scanning) {
      if (!mounted) return;
      setState(() => isScanning = scanning);
    });

    // 스캔 결과 구독
    _subScanResults = FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) return;
      
      // MOYA/NUS 기기만 필터링
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
        availableDevices = filtered;
      });
    });
    
    // 자동으로 스캔 시작
    _startScan();
  }
  
  @override
  void dispose() {
    _subConn?.cancel();
    _subScan?.cancel();
    _subScanResults?.cancel();
    super.dispose();
  }
  
  Future<void> _startScan() async {
    try {
      await _ble.startScan();
    } catch (e) {
      _showToast('스캔 시작 실패: $e', isError: true);
    }
  }
  
  void _showToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : ColorTheme.subColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 단계 표시
            Text(
              '기기 연결',
              style: TextStyle(
                fontSize: 14,
                color: ColorTheme.subColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            SizedBox(height: 20),
            
            // 제목
            Text(
              '사용하실 기기를 연결해주세요',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: ColorTheme.textBlack,
              ),
            ),
            
            SizedBox(height: 40),
            
            // 기기 목록 영역 (배경색 적용)
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ColorTheme.backgroundGray,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (availableDevices.isEmpty && isScanning)
                      // 검색 중일 때 표시
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: ColorTheme.subColor,
                              ),
                              SizedBox(height: 20),
                              Text(
                                '주변 기기를 검색 중입니다...',
                                style: TextStyle(
                                  color: ColorTheme.textGray,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    if (availableDevices.isEmpty && !isScanning)
                      // 검색 완료했지만 기기가 없을 때
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bluetooth_searching,
                                color: ColorTheme.textGray,
                                size: 48,
                              ),
                              SizedBox(height: 20),
                              Text(
                                'MOYA 기기를 찾을 수 없습니다',
                                style: TextStyle(
                                  color: ColorTheme.textGray,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 10),
                              TextButton(
                                onPressed: _startScan,
                                child: Text(
                                  '다시 검색',
                                  style: TextStyle(color: ColorTheme.subColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // 찾은 기기들
                    if (availableDevices.isNotEmpty)
                      Expanded(
                        child: ListView.builder(
                          itemCount: availableDevices.length,
                          itemBuilder: (context, index) {
                            return _buildDeviceItem(availableDevices[index]);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 40),
            
            // 완료 버튼
            ConfirmButton(
              text: '완료',
              isEnabled: selectedDevice != null,
              onPressed: selectedDevice != null 
                ? () => Navigator.pushNamed(context, '/home')
                : () {},
            ),
            
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDeviceItem(ScanResult scanResult) {
    final device = scanResult.device;
    final name = scanResult.advertisementData.advName.isNotEmpty
        ? scanResult.advertisementData.advName
        : (device.platformName.isNotEmpty ? device.platformName : 'MOYA');
    final address = device.remoteId.str;
    
    bool isConnected = selectedDevice?.remoteId.str == device.remoteId.str;
    
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _connectToDevice(scanResult),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isConnected ? ColorTheme.subColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isConnected ? ColorTheme.subColor : Colors.grey[300]!,
              width: 1,
            ),
            boxShadow: isConnected 
              ? [BoxShadow(
                  color: ColorTheme.subColor.withOpacity(0.2),
                  offset: Offset(0, 4),
                  blurRadius: 8,
                )]
              : [],
          ),
          child: Row(
            children: [
              // 기기 아이콘 (원형 배경)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isConnected 
                    ? Colors.white.withOpacity(0.2) 
                    : ColorTheme.subColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/moya.svg',
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      isConnected ? Colors.white : ColorTheme.subColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              
              SizedBox(width: 16),
              
              // 기기 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address,
                      style: TextStyle(
                        fontSize: 12,
                        color: isConnected 
                          ? Colors.white.withOpacity(0.8) 
                          : ColorTheme.textGray,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isConnected ? Colors.white : ColorTheme.textBlack,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 연결 상태 표시
              if (isConnected)
                Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 24,
                )
              else
                Text(
                  '탭하여 연결',
                  style: TextStyle(
                    fontSize: 12,
                    color: ColorTheme.textGray,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _connectToDevice(ScanResult scanResult) async {
    try {
      // 연결 시도
      await _ble.connect(scanResult.device);
      
      setState(() {
        selectedDevice = scanResult.device;
      });
      
      // 연결 성공 메시지
      final deviceName = scanResult.advertisementData.advName.isNotEmpty
          ? scanResult.advertisementData.advName
          : (scanResult.device.platformName.isNotEmpty 
              ? scanResult.device.platformName 
              : 'MOYA');
      
      _showToast('${deviceName}에 연결되었습니다!');
      
    } catch (e) {
      _showToast('연결 실패: $e', isError: true);
    }
  }
}