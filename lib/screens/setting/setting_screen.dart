import 'package:flutter/material.dart';

class SettingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('설정'),
        backgroundColor: Color(0xFFFF85B4),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          _buildSettingItem(
            '이름 설정',
            Icons.person,
            () => Navigator.pushNamed(context, '/setting_name'),
          ),
          _buildSettingItem(
            '알림 문구 설정',
            Icons.notifications,
            () => Navigator.pushNamed(context, '/setting_nick'),
          ),
          _buildSettingItem(
            '생리 주기 입력', 
            Icons.calendar_today, 
            () => Navigator.pushNamed(context, '/setting_period'),
          ),
          _buildSettingItem(
            '블루투스 연결 관리', 
            Icons.bluetooth, 
            () => Navigator.pushNamed(context, '/setting_bluetooth'),
          ),
          _buildSettingItem(
            '앱 사용 안내', 
            Icons.help, 
            () => Navigator.pushNamed(context, '/usage_guide'),
          ),
          
          SizedBox(height: 20),
          
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Color(0xFFFCE4EC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '사용자 정보',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text('이름: 민서'),
                Text('가입일: 2025-08-10'),
                SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () {
                    // 로그아웃 확인 다이얼로그
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('로그아웃'),
                        content: Text('정말 로그아웃 하시겠습니까?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('취소'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            child: Text('로그아웃', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
                  child: Text('로그아웃', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: Color(0xFFFF85B4)),
        title: Text(title),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        tileColor: Colors.grey[50],
      ),
    );
  }
}