import 'package:flutter/material.dart';

class UsageThirdScreen extends StatelessWidget {
  final bool isFromOnboarding;
  
  const UsageThirdScreen({this.isFromOnboarding = false});
  
  @override
  Widget build(BuildContext context) {
    // arguments에서 온보딩 여부 확인
    final fromOnboarding = isFromOnboarding;
    
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
            
            // 스마트폰 이미지
            Container(
              height: 200,
              child: Center(
                child: Container(
                  width: 120,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Container(
                    margin: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: 20),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Color(0xFFFF85B4),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Icon(
                            Icons.water_drop,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        SizedBox(height: 15),
                        Text(
                          'MOYA',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF85B4),
                          ),
                        ),
                        SizedBox(height: 20),
                        Container(
                          width: 80,
                          height: 2,
                          color: Colors.grey[200],
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: 60,
                          height: 2,
                          color: Colors.grey[200],
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: 70,
                          height: 2,
                          color: Colors.grey[200],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            Spacer(),
            
            // 페이지 인디케이터
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDot(false),
                SizedBox(width: 8),
                _buildDot(false),
                SizedBox(width: 8),
                _buildDot(true),
              ],
            ),
            
            SizedBox(height: 30),
            
            // 완료 버튼
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  print('isFromOnboarding: $isFromOnboarding');
                  if (isFromOnboarding) {
                    Navigator.pushNamed(context, '/input_name');
                  } else { // 설정 화면에서 들어갈 때 -> 다시 설정으로
                    Navigator.pushNamed(context, '/setting');
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
                  fromOnboarding ? '시작하기' : '완료',
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