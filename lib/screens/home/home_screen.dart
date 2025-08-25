import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = '민서';
  int daysUntilNext = 5;
  bool isOnPeriod = true;
  int changeCount = 2;
  String timeSinceLastChange = '0.5시간 전';
  String statusMessage = '아직은 보송보송 해요';
  bool isConnected = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 인사말
              Text(
                '어서오세요,\n${userName}님!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              
              SizedBox(height: 20),
              
              // 생리 주기 상태 카드
              _buildStatusCard(),
              
              SizedBox(height: 20),
              
              // 블루투스 연결 상태
              _buildConnectionStatus(),
              
              Spacer(),
              
              // AI 분석 버튼
              _buildAIButton(),
              
              SizedBox(height: 20),
              
              // 하단 네비게이션
              _buildBottomNavigation(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFFCE4EC),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          // 날짜 정보
          Text(
            isOnPeriod ? '${daysUntilNext}일 남음' : '${daysUntilNext}일뒤 시작',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          SizedBox(height: 5),
          
          Text(
            isOnPeriod ? '생리중이에요!' : '곧 생리주기가 돌아와요!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          
          SizedBox(height: 15),
          
          Text(
            '현재 내 상태',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          
          // 생리 중일 때만 교체 정보 표시
          if (isOnPeriod) ...[
            SizedBox(height: 15),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '오늘 교체 횟수',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      '${changeCount}회',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '마지막 교체',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      timeSinceLastChange,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            SizedBox(height: 15),
            
            Text(
              statusMessage,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            SizedBox(height: 10),
            Text(
              '아직은 시작 전이에요!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildConnectionStatus() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: isConnected ? Color(0xFFC8E6C9) : Color(0xFFFFCDD2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
            size: 16,
            color: isConnected ? Color(0xFF2E7D32) : Color(0xFFFF85B4),
          ),
          SizedBox(width: 5),
          Text(
            isConnected ? '연결 완료' : '연결 필요',
            style: TextStyle(
              color: isConnected ? Color(0xFF2E7D32) : Color(0xFFFF85B4),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAIButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushNamed(context, '/ondevice');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFFF85B4),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.camera_alt, size: 30),
            SizedBox(height: 8),
            Text(
              'MOYA가\n확인해드려요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            SizedBox(height: 5),
            Text(
              '안심하세요!\n데이터는 안전하게, 기기 안에서만 처리됩니다',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBottomNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildNavItem('데이터', Icons.bar_chart, () {
          Navigator.pushNamed(context, '/data');
        }),
        _buildNavItem('알림', Icons.notifications, () {
          Navigator.pushNamed(context, '/notification');
        }),
        _buildNavItem('설정', Icons.settings, () {
          Navigator.pushNamed(context, '/setting');
        }),
      ],
    );
  }
  
  Widget _buildNavItem(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 28,
              color: Colors.grey[600],
            ),
            SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}