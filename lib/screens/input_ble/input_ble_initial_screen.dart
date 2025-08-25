import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moya_app/themes/colortheme.dart';
import 'package:moya_app/widgets/confirm_button.dart';

class InputBleInitialScreen extends StatefulWidget {
  @override
  _InputBleInitialScreenState createState() => _InputBleInitialScreenState();
}

class _InputBleInitialScreenState extends State<InputBleInitialScreen> {
  bool isScanning = false;
  BluetoothDevice? selectedDevice;
  List<BluetoothDevice> availableDevices = [
    BluetoothDevice(name: 'MOYA', address: 'D7:1E:F2:AF:B9:77'),
  ];
  
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
                    if (availableDevices.isEmpty && !isScanning)
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
                    
                    // 찾은 기기들 - 리스트뷰로 변경하여 꽉 차게
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
  
  Widget _buildDeviceItem(BluetoothDevice device) {
    bool isConnected = selectedDevice?.address == device.address;
    
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _connectToDevice(device),
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
                      device.address,
                      style: TextStyle(
                        fontSize: 12,
                        color: isConnected 
                          ? Colors.white.withOpacity(0.8) 
                          : ColorTheme.textGray,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      device.name,
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
  
  void _connectToDevice(BluetoothDevice device) {
    // 연결 처리
    setState(() {
      selectedDevice = device;
    });
    
    // 연결 성공 메시지
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${device.name}에 연결되었습니다!'),
        backgroundColor: ColorTheme.subColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class BluetoothDevice {
  final String name;
  final String address;
  
  BluetoothDevice({required this.name, required this.address});
}