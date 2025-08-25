import 'package:flutter/material.dart';

class OndeviceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
            
            // 제목
            Text(
              'MOYA가\n확인해드려요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF85B4),
                height: 1.2,
              ),
            ),
            
            SizedBox(height: 10),
            
            // 부제목
            Text(
              '모야가 혈자국을 대신 체크해드려요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            
            SizedBox(height: 60),
            
            // 캐릭터 일러스트
            Container(
              width: 200,
              height: 200,
              child: CustomPaint(
                painter: CharacterPainter(),
              ),
            ),
            
            SizedBox(height: 60),
            
            // 시작하기 버튼
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/ondevice_camera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF85B4),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '시작하기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            
            Spacer(),
            
            // 하단 안내 문구
            Column(
              children: [
                Text(
                  '안심하세요!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF85B4),
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  '데이터는 안전하게, 기기 안에서만 처리됩니다',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// 캐릭터 그리기를 위한 CustomPainter
class CharacterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // 캐릭터 몸체 (흰색)
    paint.color = Colors.white;
    paint.style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.7,
        height: size.height * 0.8,
      ),
      paint,
    );
    
    // 캐릭터 테두리 (검은색)
    paint.color = Colors.black;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.7,
        height: size.height * 0.8,
      ),
      paint,
    );
    
    // 팔
    paint.style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.05, size.height * 0.4, size.width * 0.15, size.height * 0.3),
      paint,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.8, size.height * 0.4, size.width * 0.15, size.height * 0.3),
      paint,
    );
    
    // 눈 (웃는 눈)
    paint.color = Colors.black;
    paint.strokeWidth = 2;
    paint.style = PaintingStyle.stroke;
    
    // 왼쪽 눈
    Path leftEye = Path();
    leftEye.moveTo(size.width * 0.35, size.height * 0.35);
    leftEye.quadraticBezierTo(size.width * 0.4, size.height * 0.4, size.width * 0.45, size.height * 0.35);
    canvas.drawPath(leftEye, paint);
    
    // 오른쪽 눈
    Path rightEye = Path();
    rightEye.moveTo(size.width * 0.55, size.height * 0.35);
    rightEye.quadraticBezierTo(size.width * 0.6, size.height * 0.4, size.width * 0.65, size.height * 0.35);
    canvas.drawPath(rightEye, paint);
    
    // 볼터치 (핑크)
    paint.color = Color(0xFFFF85B4);
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.45), size.width * 0.04, paint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.45), size.width * 0.04, paint);
    
    // 물방울 (핑크)
    paint.color = Color(0xFFFF85B4);
    Path droplet = Path();
    droplet.moveTo(size.width * 0.5, size.height * 0.5);
    droplet.quadraticBezierTo(size.width * 0.45, size.height * 0.55, size.width * 0.5, size.height * 0.65);
    droplet.quadraticBezierTo(size.width * 0.55, size.height * 0.55, size.width * 0.5, size.height * 0.5);
    canvas.drawPath(droplet, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}