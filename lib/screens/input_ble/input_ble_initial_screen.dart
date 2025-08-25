import 'package:flutter/material.dart';

class InputBleInitialScreen extends StatefulWidget {
  @override
  _InputBleInitialScreenState createState() => _InputBleInitialScreenState();
}

class _InputBleInitialScreenState extends State<InputBleInitialScreen> {
  bool isScanning = false;
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 단계 표시
            Text(
              '사용할 기기 연결',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFFFF85B4),
                fontWeight: FontWeight.w500,
              ),
            ),
            
            SizedBox(height: 20),
            
            // 제목
            Text(
              '사용하실 기기를 연결해주세요',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            SizedBox(height: 40),
            
            // 기기 목록
            Expanded(
              child: Column(
                children: [
                  if (availableDevices.isEmpty && !isScanning)
                    Center(
                      child: Text(
                        '주변 기기를 검색 중입니다...',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ),
                  
                  // 찾은 기기들
                  ...availableDevices.map((device) => 
                    _buildDeviceItem(device),
                  ).toList(),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            // 완료 버튼
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: availableDevices.isNotEmpty 
                  ? () => Navigator.pushNamed(context, '/home')
                  : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: availableDevices.isNotEmpty 
                    ? Color(0xFFFF85B4) 
                    : Colors.grey[300],
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '완료',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDeviceItem(BluetoothDevice device) {
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
          
          // 연결 버튼
          ElevatedButton(
            onPressed: () => _connectToDevice(device),
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
  
  void _connectToDevice(BluetoothDevice device) {
    // 연결 로직
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('기기 연결'),
        content: Text('${device.name}에 연결하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${device.name}에 연결되었습니다!'),
                  backgroundColor: Color(0xFFFF85B4),
                ),
              );
            },
            child: Text('연결', style: TextStyle(color: Color(0xFFFF85B4))),
          ),
        ],
      ),
    );
  }
}

class BluetoothDevice {
  final String name;
  final String address;
  
  BluetoothDevice({required this.name, required this.address});
}