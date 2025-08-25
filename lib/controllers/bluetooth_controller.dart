//블루투스 연결
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothController extends GetxController {
  var isBluetoothEnabled = false.obs;
  var isConnected = false.obs;
  var connectedDevice = Rx<BluetoothDevice?>(null);
  var availableDevices = <BluetoothDevice>[].obs;
  var isScanning = false.obs;
  var connectionStatus = '연결 필요'.obs;
  
  BluetoothConnection? _connection;
  
  @override
  void onInit() {
    super.onInit();
    checkBluetoothState();
    requestPermissions();
  }
  
  Future<void> requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();
  }
  
  Future<void> checkBluetoothState() async {
    try {
      bool? isEnabled = await FlutterBluetoothSerial.instance.isEnabled;
      isBluetoothEnabled.value = isEnabled ?? false;
      
      if (isBluetoothEnabled.value) {
        startDiscovery();
      }
    } catch (e) {
      print('블루투스 상태 확인 오류: $e');
    }
  }
  
  Future<void> enableBluetooth() async {
    try {
      await FlutterBluetoothSerial.instance.requestEnable();
      isBluetoothEnabled.value = true;
      startDiscovery();
    } catch (e) {
      Get.snackbar('오류', '블루투스를 활성화할 수 없습니다.');
    }
  }
  
  Future<void> startDiscovery() async {
    if (isScanning.value) return;
    
    isScanning.value = true;
    availableDevices.clear();
    
    try {
      // 페어링된 기기 먼저 확인
      List<BluetoothDevice> bondedDevices = 
          await FlutterBluetoothSerial.instance.getBondedDevices();
      
      for (BluetoothDevice device in bondedDevices) {
        if (device.name?.contains('MOYA') == true || 
            device.name?.contains('모야') == true) {
          availableDevices.add(device);
        }
      }
      
      // 새로운 기기 검색
      FlutterBluetoothSerial.instance.startDiscovery().listen((result) {
        BluetoothDevice device = result.device;
        if (device.name?.isNotEmpty == true && 
            (device.name!.contains('MOYA') || device.name!.contains('모야'))) {
          if (!availableDevices.any((d) => d.address == device.address)) {
            availableDevices.add(device);
          }
        }
      }).onDone(() {
        isScanning.value = false;
      });
    } catch (e) {
      isScanning.value = false;
      print('기기 검색 오류: $e');
    }
  }
  
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      if (_connection?.isConnected == true) {
        await _connection?.close();
      }
      
      _connection = await BluetoothConnection.toAddress(device.address);
      
      if (_connection?.isConnected == true) {
        connectedDevice.value = device;
        isConnected.value = true;
        connectionStatus.value = '연결 완료';
        
        // 연결 상태 모니터링
        _connection?.input?.listen(
          (data) {
            // MOYA 기기에서 오는 데이터 처리
            handleDeviceData(data);
          },
          onDone: () {
            disconnect();
          },
          onError: (error) {
            print('연결 오류: $error');
            disconnect();
          },
        );
        
        Get.snackbar('연결 완료', '${device.name}에 연결되었습니다.');
        return true;
      }
    } catch (e) {
      print('연결 실패: $e');
      Get.snackbar('연결 실패', '기기에 연결할 수 없습니다.');
    }
    return false;
  }
  
  void disconnect() {
    _connection?.close();
    _connection = null;
    connectedDevice.value = null;
    isConnected.value = false;
    connectionStatus.value = '연결 필요';
  }
  
  void handleDeviceData(List<int> data) {
    String message = String.fromCharCodes(data);
    print('MOYA 기기 메시지: $message');
    
    // 혈자국 감지 신호 처리
    if (message.contains('BLOOD_DETECTED')) {
      Get.find<MenstrualController>().recordChange();
      Get.find<NotificationController>().showChangeNeededNotification();
    }
  }
  
  Future<void> sendChangeSignal() async {
    if (isConnected.value && _connection != null) {
      try {
        _connection?.output.add([67, 72, 65, 78, 71, 69]); // "CHANGE"
        await _connection?.output.allSent;
      } catch (e) {
        print('신호 전송 실패: $e');
      }
    }
  }
  
  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}