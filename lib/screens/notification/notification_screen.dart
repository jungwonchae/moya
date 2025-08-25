import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('최근 알림 내역'),
        backgroundColor: Color(0xFFFF85B4),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          _buildNotificationItem(
            '생리대 교체 확인 필요',
            '2025 08 20 오후 03:56',
            Icons.warning,
            Colors.orange,
          ),
          SizedBox(height: 10),
          _buildNotificationItem(
            '생리대 교체',
            '2025 08 20 오후 03:56',
            Icons.check_circle,
            Colors.green,
          ),
          SizedBox(height: 10),
          _buildNotificationItem(
            '생리대 교체',
            '2025 08 20 오후 03:56',
            Icons.check_circle,
            Colors.green,
          ),
        ],
      ),
    );
  }
  
  Widget _buildNotificationItem(String title, String time, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}