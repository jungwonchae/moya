import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart'; // ✅ 추가

class OndeviceScreen extends StatelessWidget {
  const OndeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFFFF85B4), size: 24),
          onPressed: () => Navigator.pop(context),
          splashRadius: 22,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            const Text(
              'MOYA가\n확인해드려요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF85B4),
                height: 1.2,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              '모야가 혈자국을 대신 체크해드려요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 1),

            // ✅ 중앙 Lottie 서치 애니메이션
            SizedBox(
              width: 350,
              height: 350,
              child: Lottie.asset(
                'assets/lottie/searching.json',   // <- 여기에 파일 두면 됩니다
                repeat: true,
                animate: true,
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 1),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/ondevice_camera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF85B4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '시작하기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const Spacer(),

            Column(
              children: [
                const Text(
                  '안심하세요!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF85B4),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '데이터는 안전하게, 기기 안에서만 처리됩니다',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
