import 'package:flutter/material.dart';
import '../themes/colortheme.dart';

class BluetoothStatusChip extends StatelessWidget {
  final bool isConnected;
  final VoidCallback? onTap;

  const BluetoothStatusChip({
    super.key,
    required this.isConnected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // 눌렀을 때 블루투스 설정 화면으로 이동할 수 있음
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x192E3176),
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              size: 18,
              color: isConnected
                  ? ColorTheme.bluetoothConnected
                  : ColorTheme.bluetoothDisconnected,
            ),
            const SizedBox(width: 8),
            Text(
              isConnected ? '연결 완료' : '연결 필요',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isConnected
                    ? ColorTheme.bluetoothConnected
                    : ColorTheme.bluetoothDisconnected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
