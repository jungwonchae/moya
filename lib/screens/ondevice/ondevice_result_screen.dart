import 'package:flutter/material.dart';

class OndeviceResultScreen extends StatelessWidget {
  final bool hasBloodStain;
  
  const OndeviceResultScreen({this.hasBloodStain = true});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(height: 80),
            
            // 결과 아이콘
            Container(
              width: 120,
              height: 120,
              child: hasBloodStain
                ? Icon(
                    Icons.water_drop,
                    size: 80,
                    color: Color(0xFFFF85B4),
                  )
                : Icon(
                    Icons.star,
                    size: 80,
                    color: Color(0xFFFF85B4),
                  ),
            ),
            
            SizedBox(height: 30),
            
            // 결과 텍스트
            Text(
              '혈자국이 있어요!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF85B4),
              ),
            ),
            
            SizedBox(height: 12),
            
            Text(
              hasBloodStain ? '지금 교체가 필요해요' : '혈이 아니에요, 안심하세요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            
            SizedBox(height: 60),
            
            // 확인 버튼
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // 교체 기록 업데이트 후 홈으로 이동
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (route) => false,
                  );
                  
                  // 스낵바로 알림
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(hasBloodStain ? '교체가 기록되었습니다!' : 'AI 분석이 완료되었습니다!'),
                      backgroundColor: Color(0xFFFF85B4),
                    ),
                  );
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
                  '확인',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 15),
            
            // 한번더 확인 버튼
            Container(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/ondevice_camera');
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                child: Text(
                  '한번더\n확인',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
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