import 'package:flutter/material.dart';
import 'usage_second_screen.dart';

class UsageFirstScreen extends StatelessWidget {
  final bool isFromOnboarding;
  
  const UsageFirstScreen({this.isFromOnboarding = false});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: isFromOnboarding 
          ? null 
          : IconButton(
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
              'MOYA를 통해 쉽고 빠르게\n교체 주기를 확인하세요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                height: 1.4,
              ),
            ),
            
            SizedBox(height: 80),
            
            // MOYA 기기들 이미지
            Container(
              height: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 첫 번째 MOYA 기기
                  _buildMoyaDevice(false),
                  
                  // 두 번째 MOYA 기기  
                  _buildMoyaDevice(true),
                ],
              ),
            ),
            
            SizedBox(height: 40),
            
            // 설명 텍스트
            Text(
              '교체할 시기가 되면 무드등이\n깜빡거려요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            
            Spacer(),
            
            // 페이지 인디케이터
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDot(true),
                SizedBox(width: 8),
                _buildDot(false),
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
                  if (isFromOnboarding) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UsageSecondScreen(isFromOnboarding: true), // 직접 전달
                      ),
                    );
                  } else {
                    Navigator.pushNamed(context, '/usage_second');
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
  
  Widget _buildMoyaDevice(bool isActive) {
    return Container(
      width: 80,
      height: 160,
      child: Column(
        children: [
          // MOYA 기기 본체
          Container(
            width: 60,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.grey[300]!, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'MOYA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isActive ? Color(0xFFFF85B4) : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: isActive 
                    ? Icon(Icons.circle, color: Color(0xFFFF85B4), size: 8)
                    : null,
                ),
              ],
            ),
          ),
          
          SizedBox(height: 20),
          
          // MOYA 텍스트
          Text(
            'MOYA',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF85B4),
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