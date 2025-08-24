import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HC-05 블루투스',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: BluetoothScreen(),
    );
  }
}

class BluetoothScreen extends StatefulWidget {
  @override
  _BluetoothScreenState createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection? connection;
  bool isConnecting = false;
  bool get isConnected => connection != null && connection!.isConnected;

  List<BluetoothDevice> _devicesList = [];
  BluetoothDevice? _connectedDevice;
  String _receivedData = '';
  TextEditingController _sendController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initBluetooth();
  }

  Future<void> initBluetooth() async {
    // 권한 요청
    await requestPermissions();
    
    // 블루투스 상태 가져오기
    _bluetoothState = await FlutterBluetoothSerial.instance.state;
    
    // 블루투스가 꺼져있으면 켜달라고 요청
    if (_bluetoothState == BluetoothState.STATE_OFF) {
      await FlutterBluetoothSerial.instance.requestEnable();
    }
    
    // 페어링된 장치 목록 가져오기
    getPairedDevices();
    
    setState(() {});
  }

  Future<void> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  void getPairedDevices() async {
    List<BluetoothDevice> devices = await _bluetooth.getBondedDevices();
    setState(() {
      _devicesList = devices;
    });
  }

  void connectToDevice(BluetoothDevice device) async {
    setState(() {
      isConnecting = true;
    });

    try {
      connection = await BluetoothConnection.toAddress(device.address);
      setState(() {
        _connectedDevice = device;
        isConnecting = false;
      });

      // 데이터 수신 리스너
      connection!.input!.listen((Uint8List data) {
        String receivedData = utf8.decode(data);
        setState(() {
          _receivedData += receivedData;
        });
      }).onDone(() {
        setState(() {
          connection = null;
          _connectedDevice = null;
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${device.name}에 연결되었습니다!')),
      );
    } catch (error) {
      setState(() {
        isConnecting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('연결 실패: $error')),
      );
    }
  }

  void disconnect() async {
    if (connection != null) {
      await connection!.close();
      setState(() {
        connection = null;
        _connectedDevice = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('연결이 해제되었습니다.')),
      );
    }
  }

  void sendData(String data) async {
    if (connection != null && connection!.isConnected) {
      connection!.output.add(utf8.encode(data + '\n'));
      await connection!.output.allSent;
      _sendController.clear();
    }
  }

  @override
  void dispose() {
    connection?.dispose();
    _sendController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('HC-05 블루투스 연결'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: getPairedDevices,
          ),
        ],
      ),
      body: Column(
        children: [
          // 연결 상태
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: isConnected ? Colors.green[100] : Colors.red[100],
            child: Text(
              isConnected 
                ? '연결됨: ${_connectedDevice?.name}'
                : '연결되지 않음',
              style: TextStyle(
                color: isConnected ? Colors.green[800] : Colors.red[800],
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          
          // 장치 목록
          if (!isConnected) ...[
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '페어링된 장치 목록 (HC-05를 선택하세요):', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              flex: 1,
              child: _devicesList.isEmpty 
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('페어링된 장치가 없습니다'),
                        Text('폰 설정에서 HC-05와 페어링하세요'),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: getPairedDevices,
                          child: Text('새로고침'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _devicesList.length,
                    itemBuilder: (context, index) {
                      BluetoothDevice device = _devicesList[index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: Icon(
                            device.name?.contains('HC-') == true 
                              ? Icons.bluetooth 
                              : Icons.device_unknown,
                            color: device.name?.contains('HC-') == true 
                              ? Colors.blue 
                              : Colors.grey,
                          ),
                          title: Text(device.name ?? '알 수 없는 장치'),
                          subtitle: Text(device.address),
                          trailing: isConnecting 
                            ? CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: () => connectToDevice(device),
                                child: Text('연결'),
                              ),
                        ),
                      );
                    },
                  ),
            ),
          ],

          // 연결된 경우의 UI
          if (isConnected) ...[
            // 연결 해제 버튼
            Padding(
              padding: EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: disconnect,
                child: Text('연결 해제'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            // 빠른 명령어 버튼들
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('아두이노 제어 명령어:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => sendData('LED_ON'),
                        child: Text('LED 켜기'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      ),
                      ElevatedButton(
                        onPressed: () => sendData('LED_OFF'),
                        child: Text('LED 끄기'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      ),
                      ElevatedButton(
                        onPressed: () => sendData('STATUS'),
                        child: Text('상태확인'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 수신된 데이터
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('수신된 데이터:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Spacer(),
                        ElevatedButton(
                          onPressed: () => setState(() => _receivedData = ''),
                          child: Text('지우기'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            _receivedData.isEmpty ? '받은 데이터가 없습니다.' : _receivedData,
                            style: TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 데이터 전송.
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _sendController,
                      decoration: InputDecoration(
                        hintText: '명령어 입력 (LED_ON, LED_OFF, STATUS)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => sendData(_sendController.text),
                    child: Text('전송'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}