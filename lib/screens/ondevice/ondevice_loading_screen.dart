import 'package:flutter/material.dart';

class OndeviceLoadingScreen extends StatefulWidget {
  @override
  _OndeviceLoadingScreenState createState() => _OndeviceLoadingScreenState();
}

class _OndeviceLoadingScreenState extends State<OndeviceLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    // 3초 후 결과 화면으로 이동
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/ondevice_result');
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(height: 80),
            
            // 제목
            Text(
              'MOYA가\n확인중이에요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF85B4),
                height: 1.3,
              ),
            ),
            
            SizedBox(height: 8),
            
            Text(
              '모야가 혈자국을 대신 체크해드려요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            
            SizedBox(height: 80),
            
            // 로딩 애니메이션
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  width: 150,
                  height: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 외곽 원
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue[100],
                        ),
                      ),
                      
                      // 회전하는 원
                      Transform.rotate(
                        angle: _controller.value * 2 * 3.14159,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue[600],
                          ),
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      ),
                      
                      // 돋보기 아이콘
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFF85B4),
                          ),
                          child: Icon(
                            Icons.search,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            Spacer(),
            
            // 안심 메시지
            Text(
              '안심하세요!',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFF85B4),
              ),
            ),
            
            SizedBox(height: 8),
            
            Text(
              '데이터는 안전하게, 기기 안에서만 처리됩니다',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}