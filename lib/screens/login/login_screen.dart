import 'package:flutter/material.dart';
import '../usage/usage_screens_container.dart';
import 'package:moya_app/themes/colortheme.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 배경 원형 디자인
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: Color(0xFFF8BBD9),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          // 메인 컨텐츠
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 120),
                  
                  // 로고 아이콘
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
                  
                  // 제목 텍스트
                  Text(
                    '안녕하세요.\nMOYA 입니다.',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      color: Colors.black87,
                    ),
                  ),
                  
                  Spacer(),
                  
                  // 회원가입 버튼
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // 직접 UsageFirstScreen으로 이동하면서 파라미터 전달
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UsageScreensContainer(isFromOnboarding: true),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF85B4),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        '회원가입하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 15),
                  
                  // 비회원 시작 버튼
                  Container(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                      // 회원가입 -> Usage 화면으로 직접 이동 (파라미터 전달)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UsageScreensContainer(isFromOnboarding: true),
                        ),
                      );
                    },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '비회원 시작',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}