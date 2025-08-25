import 'package:flutter/material.dart';

class OndeviceCameraScreen extends StatefulWidget {
  @override
  _OndeviceCameraScreenState createState() => _OndeviceCameraScreenState();
}

class _OndeviceCameraScreenState extends State<OndeviceCameraScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 카메라 뷰 (시뮬레이션)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[800],
            child: Center(
              child: Text(
                '카메라 화면\n(실제 앱에서는 카메라 미리보기)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          
          // 상단 컨트롤
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 플래시 버튼
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.flash_off,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  
                  // 각도 조절 버튼
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.rotate_90_degrees_ccw,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  
                  // 카메라 전환 버튼
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.flip_camera_ios,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 하단 컨트롤
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
              ),
              child: Column(
                children: [
                  // 촬영 모드
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text('CINEMA\nTIC', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                        Text('VIDE\nO', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                        Text('PHOT\nO', textAlign: TextAlign.center, style: TextStyle(color: Colors.yellow, fontSize: 10, fontWeight: FontWeight.bold)),
                        Text('PORTR\nAIT', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                        Text('PAN\nO', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                      ],
                    ),
                  ),
                  
                  // 줌 컨트롤
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text('0.5', style: TextStyle(color: Colors.white, fontSize: 14)),
                        Text('1x', style: TextStyle(color: Colors.yellow, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // 촬영 버튼
                  GestureDetector(
                    onTap: () {
                      // 촬영 애니메이션 후 로딩 화면으로
                      Navigator.pushReplacementNamed(context, '/ondevice_loading');
                    },
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[300]!, width: 3),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}