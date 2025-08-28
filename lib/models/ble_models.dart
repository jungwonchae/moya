// 공용 BLE 모델 (화면/서비스가 같이 씀)
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ConnectedDevice {
  final String name;
  final String address;     // device.remoteId.str
  final BluetoothDevice dev;
  ConnectedDevice({required this.name, required this.address, required this.dev});
}

class AvailableDevice {
  final String name;
  final String address;     // device.remoteId.str
  final BluetoothDevice dev;
  AvailableDevice({required this.name, required this.address, required this.dev});
}