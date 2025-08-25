import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:moya_app/themes/colortheme.dart';

class OndeviceLoadingScreen extends StatefulWidget {
  const OndeviceLoadingScreen({super.key});

  @override
  State<OndeviceLoadingScreen> createState() => _OndeviceLoadingScreenState();
}

class _OndeviceLoadingScreenState extends State<OndeviceLoadingScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 3초 후 결과 화면으로 전환
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/ondevice_result');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 48),

              // 제목
              Text(
                'MOYA가\n확인중이에요!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                  height: 1.25,
                  color: ColorTheme.subColor,
                ),
              ),

              const SizedBox(height: 10),

              // 부제목
              Text(
                '모야가 혈자국을 대신 체크해드려요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 20),

              // 가운데 Lottie 애니메이션 (정중앙)
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320, maxHeight: 320),
                    child: Lottie.asset(
                      'assets/lottie/scan.json',
                      repeat: true,
                      animate: true,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              // 하단 안심 문구
              const SizedBox(height: 8),
              const Text(
                '안심하세요!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ColorTheme.subColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '데이터는 안전하게, 기기 안에서만 처리됩니다',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}
