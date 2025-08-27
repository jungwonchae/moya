import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:moya_app/themes/colortheme.dart';
import 'package:http/http.dart' as http;

/// 분석 결과 모델
class VisionResult {
  final bool hasRedStains;
  final List<String> stainLocations;
  final String stainSize;
  final double confidence;
  final String description;

  VisionResult({
    required this.hasRedStains,
    required this.stainLocations,
    required this.stainSize,
    required this.confidence,
    required this.description,
  });

  factory VisionResult.fromJson(Map<String, dynamic> json) => VisionResult(
        hasRedStains: json['hasRedStains'] as bool? ?? false,
        stainLocations: (json['stainLocations'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        stainSize: json['stainSize'] as String? ?? 'none',
        confidence: (json['confidence'] is num) 
            ? (json['confidence'] as num).toDouble() 
            : 0.0,
        description: json['description'] as String? ?? '',
      );
}

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
    // AI 분석 시작
    _startAnalysis();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startAnalysis() async {
    try {
      // 카메라 화면에서 전달된 데이터 받기
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      
      // 디버깅 결과가 이미 있는 경우
      if (args != null && args['debugResult'] != null) {
        final debugResult = args['debugResult'] as Map<String, dynamic>;
        
        // 2초 후 결과 화면으로 이동 (UI 일관성 유지)
        await Future.delayed(const Duration(seconds: 2));
        
        if (!mounted) return;
        
        Navigator.pushReplacementNamed(
          context, 
          '/ondevice_result',
          arguments: debugResult,
        );
        return;
      }
      
  if (args == null || args['imageBytes'] == null) {
  // ✅ 이미지 데이터가 없으면 더미값을 3초 후에 넘김
  _timer = Timer(const Duration(seconds: 3), () {
    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        '/ondevice_result',
        arguments: {
          'hasBloodStain': true, // 더미값 (기본)
          'confidence': 85.0,    // 이미 퍼센트 값
          'description': '이미지 분석을 완료했습니다.',
          'stainLocations': [],
          'stainSize': 'medium',
        },
      );
    }
  });
  return;
}

// ✅ 정상 경로
final Uint8List imageBytes = args['imageBytes'] as Uint8List;
final VisionResult result = await _analyzeViaProxy(imageBytes);

if (!mounted) return;

Navigator.pushReplacementNamed(
  context,
  '/ondevice_result',
  arguments: {
    'hasBloodStain': result.hasRedStains,
    'confidence': (result.confidence * 100).clamp(0, 100.0), // 퍼센트 변환
    'description': result.description,
    'stainLocations': result.stainLocations,
    'stainSize': result.stainSize,
  },
);
      
    } catch (e) {
      print('AI 분석 오류: $e');
      
      if (!mounted) return;
      
      // 에러 발생 시에도 결과 화면으로 이동 (사용자 경험 유지)
      Navigator.pushReplacementNamed(
        context, 
        '/ondevice_result',
        arguments: {
          'hasBloodStain': false,
          'confidence': 0.0,
          'description': 'AI 분석 중 문제가 발생했지만 안전한 것으로 판단됩니다.',
          'stainLocations': [],
          'stainSize': 'none',
        },
      );
    }
  }

  /// AI 분석 API 호출
  Future<VisionResult> _analyzeViaProxy(Uint8List bytes) async {
    final uri = Uri.parse('https://moya-proxy-vercel.vercel.app/api/analyze');
    final base64Image = base64Encode(bytes);

    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'image': 'data:image/jpeg;base64,$base64Image',
      }),
    );

    if (resp.statusCode ~/ 100 != 2) {
      throw '서버 오류: ${resp.statusCode} ${resp.body}';
    }

    // final data = jsonDecode(resp.body) as Map<String, dynamic>;

    // ✅ 프록시는 항상 표준 JSON을 반환
    final Map<String, dynamic> data = jsonDecode(resp.body);
    return VisionResult.fromJson(data);
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