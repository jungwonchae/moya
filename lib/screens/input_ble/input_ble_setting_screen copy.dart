import 'package:flutter/material.dart';

class InputBleSettingScreen extends StatefulWidget {
  @override
  _InputBleSettingScreenState createState() => _InputBleSettingScreenState();
}

class _InputBleSettingScreenState extends State<InputBleSettingScreen> {
  List<ConnectedDevice> connectedDevices = [
    ConnectedDevice(name: 'MOYA', address: 'D7:1E:F2:AF:B9:77', isConnected: true),
  ];
  
  List<AvailableDevice> availableDevices = [];
  bool isScanning = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFFFF85B4)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('설정이 저장되었습니다.'),
                  backgroundColor: Color(0xFFFF85B4),
                ),
              );
            },
            child: Text(
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
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목
            Text(
              '블루투스 연결 관리',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            SizedBox(height: 30),
            
            // 현재 연결 기기
            Text(
              '현재 연결 기기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            
            SizedBox(height: 15),
            
            // 연결된 기기 목록
            ...connectedDevices.map((device) => 
              _buildConnectedDeviceItem(device),
            ).toList(),
            
            SizedBox(height: 30),
            
            // 새로운 기기 연결
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '새로운 기기 연결',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                
                // 검색 버튼
                IconButton(
                  onPressed: () {
                    setState(() {
                      isScanning = !isScanning;
                    });
                    _scanForDevices();
                  },
                  icon: Icon(
                    isScanning ? Icons.stop : Icons.search,
                    color: Color(0xFFFF85B4),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 15),
            
            // 사용 가능한 기기 목록
            Expanded(
              child: Column(
                children: [
                  if (isScanning)
                    Container(
                      padding: EdgeInsets.all(16),
                      child: Row(
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
                  
                  ...availableDevices.map((device) => 
                    _buildAvailableDeviceItem(device),
                  ).toList(),
                ],
              ),
            ),
            
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildConnectedDeviceItem(ConnectedDevice device) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFFF85B4)),
        color: Color(0xFFFF85B4).withOpacity(0.05),
      ),
      child: Row(
        children: [
          // 블루투스 아이콘
          Icon(
            Icons.bluetooth_connected,
            color: Color(0xFFFF85B4),
            size: 24,
          ),
          
          SizedBox(width: 12),
          
          // 기기 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  device.address,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // 연결 해제 버튼
          GestureDetector(
            onTap: () => _showDisconnectDialog(device),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.red),
              ),
              child: Text(
                '연결 해제',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAvailableDeviceItem(AvailableDevice device) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        color: Colors.white,
      ),
      child: Row(
        children: [
          // 블루투스 아이콘
          Icon(
            Icons.bluetooth,
            color: Colors.grey[600],
            size: 24,
          ),
          
          SizedBox(width: 12),
          
          // 기기 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  device.address,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // 연결 버튼
          ElevatedButton(
            onPressed: () => _connectToNewDevice(device),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF85B4),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            child: Text(
              '연결',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _scanForDevices() {
    if (isScanning) {
      // 2초 후 검색 결과 시뮬레이션
      Future.delayed(Duration(seconds: 2), () {
        setState(() {
          availableDevices = [
            AvailableDevice(name: 'MOYA-2', address: 'A1:2B:3C:4D:5E:6F'),
          ];
          isScanning = false;
        });
      });
    }
  }
  
  void _showDisconnectDialog(ConnectedDevice device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('연결 해제'),
        content: Text('${device.name}\n${device.address}\n\n기기 연결을 취소하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('아니오'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                connectedDevices.remove(device);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${device.name} 연결이 해제되었습니다.'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: Text('예', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  void _connectToNewDevice(AvailableDevice device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('기기 연결'),
        content: Text('${device.name}\n${device.address}\n\n기기 등록 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('아니오'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                connectedDevices.add(
                  ConnectedDevice(
                    name: device.name, 
                    address: device.address, 
                    isConnected: true,
                  ),
                );
                availableDevices.remove(device);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${device.name}에 연결되었습니다!'),
                  backgroundColor: Color(0xFFFF85B4),
                ),
              );
            },
            child: Text('예', style: TextStyle(color: Color(0xFFFF85B4))),
          ),
        ],
      ),
    );
  }
}

class ConnectedDevice {
  final String name;
  final String address;
  final bool isConnected;
  
  ConnectedDevice({
    required this.name, 
    required this.address, 
    required this.isConnected,
  });
}

class AvailableDevice {
  final String name;
  final String address;
  
  AvailableDevice({required this.name, required this.address});
}