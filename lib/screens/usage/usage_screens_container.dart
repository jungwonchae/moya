import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moya_app/themes/colortheme.dart';

import 'package:moya_app/widgets/lamp_widget.dart';
import 'package:moya_app/widgets/wearable_widget.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart'; //3d 모델링




class UsageScreensContainer extends StatefulWidget {
  final bool isFromOnboarding;
  
  const UsageScreensContainer({this.isFromOnboarding = false});

  @override
  _UsageScreensContainerState createState() => _UsageScreensContainerState();
}

class _UsageScreensContainerState extends State<UsageScreensContainer> {
  PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // 마지막 페이지에서 스와이프하면 다음 화면으로 이동
  void _handlePageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  // 페이지가 끝까지 가면 다음 화면으로 이동하는 로직 추가 가능
  void _onLastPageReached() {
    if (widget.isFromOnboarding) {
      // 온보딩에서 왔다면 이름 입력 화면으로
      Navigator.pushReplacementNamed(context, '/input_name');
    } else {
      // 설정에서 왔다면 이전 화면으로
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _handlePageChanged,
                children: [
                  _UsageFirstPage(),
                  _UsageSecondPage(),
                  _UsageThirdPage(),
                ],
              ),
            ),
            
            // 페이지 인디케이터와 건너뛰기/완료 버튼
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 건너뛰기 버튼 (마지막 페이지가 아닐 때만)
                  if (_currentPage < 2)
                    TextButton(
                      onPressed: _onLastPageReached,
                      child: Text(
                        '건너뛰기',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    )
                  else
                    SizedBox(width: 60), // 공간 확보
                  
                  // 페이지 인디케이터
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3, // 3개 페이지
                      (index) => _buildPageIndicator(index),
                    ),
                  ),
                  
                  // 완료 버튼 (마지막 페이지일 때만)
                  if (_currentPage == 2)
                    TextButton(
                      onPressed: _onLastPageReached,
                      child: Text(
                        '완료',
                        style: TextStyle(
                          color: ColorTheme.subColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    SizedBox(width: 60), // 공간 확보
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        width: 8,
        height: 8,
        margin: EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _currentPage == index 
            ? ColorTheme.subColor 
            : Colors.grey[300],
        ),
      ),
    );
  }
}

// 내부에서만 사용하는 페이지들 (외부와 충돌 방지)
class _UsageFirstPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          SizedBox(height: 60),
          
          // 상단 로고
          SvgPicture.asset(
            'assets/icons/moya.svg',
            width: 32,
            height: 32,
            colorFilter: ColorFilter.mode(
              ColorTheme.subColor,
              BlendMode.srcIn,
            ),
          ),
          
          // 중앙 이미지 영역
          Expanded(
            child: Center(
              child: SizedBox(
                width: 250,
                height: 250,
                child: ModelViewer(
                  src: 'assets/3d/moya_hw.glb',   // 에셋 경로
                  alt: 'My Blender GLB',
                  cameraControls: true,            // 드래그/줌
                  autoRotate: true,                // 자동 회전
                  disableZoom: false,
                  exposure: 1.0,
                  shadowIntensity: 1.0,
                  ar: false,                       // iOS는 usdz 필요, Android는 glb만으로 가능
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ),
          
          // 하단 텍스트
          Padding(
            padding: EdgeInsets.only(bottom: 60),
            child: Text(
              'MOYA를 통해 쉽고 빠르게\n교체 주기를 확인하세요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ColorTheme.textBlack,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageSecondPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          SizedBox(height: 60),
          
          // 상단 로고
          SvgPicture.asset(
            'assets/icons/moya.svg',
            width: 32,
            height: 32,
            colorFilter: ColorFilter.mode(
              ColorTheme.subColor,
              BlendMode.srcIn,
            ),
          ),
          
          // 중앙 이미지 영역
          Expanded(
            child: Center(
              child: SizedBox(
                width: 250,
                height: 250,
                child: ModelViewer(
                  src: 'assets/3d/moya_light.glb',   // 에셋 경로
                  alt: 'My Blender GLB',
                  cameraControls: true,            // 드래그/줌
                  autoRotate: true,                // 자동 회전
                  disableZoom: false,
                  exposure: 1.0,
                  shadowIntensity: 1.0,
                  ar: false,                       // iOS는 usdz 필요, Android는 glb만으로 가능
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ),
          
          // 하단 텍스트
          Padding(
            padding: EdgeInsets.only(bottom: 60),
            child: Text(
              '교체할 시기가 되면 무드등이\n깜빡거려요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ColorTheme.textBlack,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageThirdPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          SizedBox(height: 60),
          
          // 상단 로고
          SvgPicture.asset(
            'assets/icons/moya.svg',
            width: 32,
            height: 32,
            colorFilter: ColorFilter.mode(
              ColorTheme.subColor,
              BlendMode.srcIn,
            ),
          ),
          
          // 중앙 이미지 영역
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 300,
                  maxHeight: 400,
                ),
                child: Image.asset(     // ← SvgPicture.asset → Image.asset
                  'assets/images/app_hw.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          
          // 하단 텍스트
          Padding(
            padding: EdgeInsets.only(bottom: 60),
            child: Text(
              '어플을 통해 내 정보를\n쉽고 빠르게 확인해보세요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ColorTheme.textBlack,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}