import 'package:flutter/material.dart';
import '../usage/usage_screens_container.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
                color: ColorTheme.subColor.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // 왼쪽 아래 원형
          Positioned(
            top: 390,
            left: -200, // 왼쪽으로 빼기
            child: Container(
              width: 365,
              height: 365,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: ColorTheme.subColor.withOpacity(0.1), // subColor, 10% 투명도
                  width: 3, // 테두리 두께 (원하는 대로 조정)
                ),
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
                    alignment: Alignment.centerLeft,
                    child: SvgPicture.asset(
                        'assets/icons/moya.svg',
                        width: 30,
                        height: 30,
                        color: ColorTheme.subColor, // 필요하다면 색상 입히기 가능
                      ),
                    ),
                  
                  SizedBox(height: 20),

                  // 제목 텍스트 1
                  Text(
                    '안녕하세요.',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.normal,
                      height: 1.3,
                      color: Colors.black87,
                    ),
                  ),
                  
                  // 제목 텍스트 2
                  Text(
                    'MOYA 입니다.',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: 25,
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
                        '회원가입 하기',
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