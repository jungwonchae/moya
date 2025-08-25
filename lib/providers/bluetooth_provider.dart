import 'package:flutter/material.dart';

class BluetoothProvider with ChangeNotifier {
  bool _isConnected = false;
  String _deviceName = '';
  String _deviceAddress = '';

  bool get isConnected => _isConnected;
  String get deviceName => _deviceName;
  String get deviceAddress => _deviceAddress;

  // 블루투스 연결 시
  void connect(String name, String address) {
    _isConnected = true;
    _deviceName = name;
    _deviceAddress = address;
    notifyListeners();
  }

  // 블루투스 연결 해제 시
  void disconnect() {
    _isConnected = false;
    _deviceName = '';
    _deviceAddress = '';
    notifyListeners();
  }
}
