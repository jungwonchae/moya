import 'package:flutter/material.dart';
import 'usage_third_screen.dart';

class UsageSecondScreen extends StatelessWidget {
  final bool isFromOnboarding;
  
  const UsageSecondScreen({this.isFromOnboarding = false});
  
  @override
  Widget build(BuildContext context) {
    // arguments에서 온보딩 여부 확인
    final args = ModalRoute.of(context)?.settings.arguments as bool?;
    final fromOnboarding = args ?? isFromOnboarding;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFFFF85B4)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(height: 40),
            
            // 로고
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Color(0xFFFF85B4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.water_drop,
                color: Colors.white,
                size: 30,
              ),
            ),
            
            SizedBox(height: 30),
            
            // 제목
            Text(
              '어플을 통해 내 정보를\n쉽고 빠르게 확인해보세요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                height: 1.4,
              ),
            ),
            
            SizedBox(height: 80),
            
            // 생리컵/생리대 이미지
            Container(
              height: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 생리컵
                  _buildProductImage(Icons.local_drink, '생리컵'),
                  
                  // 생리대
                  _buildProductImage(Icons.healing, '생리대'),
                ],
              ),
            ),
            
            Spacer(),
            
            // 페이지 인디케이터
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDot(false),
                SizedBox(width: 8),
                _buildDot(true),
                SizedBox(width: 8),
                _buildDot(false),
              ],
            ),
            
            SizedBox(height: 30),
            
            // 다음 버튼
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (fromOnboarding) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UsageThirdScreen(isFromOnboarding: true), // 직접 전달
                      ),
                    );
                  } else {
                    Navigator.pushNamed(context, '/usage_third');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF85B4),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '다음',
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
  
  Widget _buildProductImage(IconData icon, String label) {
    return Container(
      width: 100,
      height: 160,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              size: 50,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 15),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDot(bool isActive) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? Color(0xFFFF85B4) : Colors.grey[300],
        shape: BoxShape.circle,
      ),
    );
  }
}