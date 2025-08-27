import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;

/// 분석 결과 모델 - Cloudflare Workers 응답에 맞게 수정
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

class OndeviceCameraScreen extends StatefulWidget {
  const OndeviceCameraScreen({super.key});

  @override
  State<OndeviceCameraScreen> createState() => _OndeviceCameraScreenState();
}

class _OndeviceCameraScreenState extends State<OndeviceCameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        throw '카메라를 찾을 수 없습니다.';
      }
      _controller = CameraController(
        _cameras!.first, // 후면 카메라
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420, // iOS/Android 모두 호환
      );
      await _controller!.initialize();
      if (!mounted) return;
      setState(() => _initialized = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('카메라 초기화 실패: $e')),
      );
    }
  }

  Future<void> _shootAndAnalyze() async {
  if (_controller == null || !_controller!.value.isInitialized) return;

  try {
    final XFile shot = await _controller!.takePicture();
    final Uint8List bytes = await shot.readAsBytes();

    // (선택) 임시 파일 삭제
    try {
      if (await File(shot.path).exists()) {
        await File(shot.path).delete();
      }
    } catch (_) {}

    if (!mounted) return;

    // ✅ 바로 로딩화면으로 이동
    Navigator.pushReplacementNamed(
      context,
      '/ondevice_loading',
      arguments: {'imageBytes': bytes},
    );

  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('촬영 실패: $e')),
    );
  }
}

  /*
  Future<void> _showDebugAnalysis(Uint8List bytes) async {
    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('AI 분석 중...'),
          ],
        ),
      ),
    );

    try {
      // AI 분석 실행
      final VisionResult result = await _analyzeViaProxy(bytes);
      
      if (!mounted) return;
      
      // 로딩 다이얼로그 닫기
      //Navigator.of(context).pop();
      
      // 디버깅 결과 표시
      //_showDebugDialog(result);
      
    } catch (e) {
      if (!mounted) return;
      
      // 로딩 다이얼로그 닫기
      Navigator.of(context).pop();
      
      // 에러 표시
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('디버깅: 분석 실패'),
          content: SingleChildScrollView(
            child: Text('에러 내용:\n$e'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // 로딩 화면으로 이동 (정상 플로우)
                Navigator.pushReplacementNamed(
                  context,
                  '/ondevice_loading',
                  arguments: {'imageBytes': bytes},
                );
              },
              child: const Text('계속 진행'),
            ),
          ],
        ),
      );
    }
  }
  */
  
  // 디버깅을 위함
  void _showDebugDialog(VisionResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('디버깅: AI 분석 결과'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('혈액 감지: ${result.hasRedStains ? "예" : "아니오"}'),
              const SizedBox(height: 8),
              Text('신뢰도: ${result.confidence.toStringAsFixed(1)}%'),
              const SizedBox(height: 8),
              Text('크기: ${result.stainSize}'),
              const SizedBox(height: 8),
              if (result.stainLocations.isNotEmpty) ...[
                Text('위치: ${result.stainLocations.join(", ")}'),
                const SizedBox(height: 8),
              ],
              const Text('설명:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(result.description),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 로딩 화면으로 이동 (정상 플로우)
              Navigator.pushReplacementNamed(
                context,
                '/ondevice_loading',
                arguments: {
                  'imageBytes': null, // 이미 분석했으므로 null로 전달
                  'debugResult': {
                    'hasBloodStain': result.hasRedStains,
                    'confidence': (result.confidence * 100).clamp(0, 100.0), // ← 퍼센트로
                    'description': result.description,
                    'stainLocations': result.stainLocations,
                    'stainSize': result.stainSize,
                  },
                },
              );
            },
            child: const Text('계속 진행'),
          ),
        ],
      ),
    );
  }

  /// 🔒 프록시 서버에 바이트 업로드(저장 없이) → 서버가 OpenAI에 요청
  Future<VisionResult> _analyzeViaProxy(Uint8List bytes) async {
  final uri = Uri.parse('https://moya-proxy-vercel.vercel.app/api/analyze'); // ← 본인 Vercel URL
  final base64Image = base64Encode(bytes);

  final resp = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'image': 'data:image/jpeg;base64,$base64Image',
      // 'hint': '이 사진에서 혈액 얼룩 여부를 JSON으로만 답해줘…' // 선택
    }),
  );

  print('HTTP Status: ${resp.statusCode}');
  print('Response body: ${resp.body}');

  if (resp.statusCode ~/ 100 != 2) {
    throw '서버 오류: ${resp.statusCode}\n응답: ${resp.body}';
  }

  final Map<String, dynamic> data = jsonDecode(resp.body);
  // 프록시가 이미 {hasRedStains, stainLocations, stainSize, confidence(0~1), description}로 반환
  return VisionResult.fromJson(data);
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 카메라 프리뷰
          if (_initialized && _controller != null && _controller!.value.isInitialized)
            Positioned.fill(
              child: CameraPreview(_controller!),
            )
          else
            Positioned.fill(
              child: Container(
                color: Colors.grey[800],
                alignment: Alignment.center,
                child: const Text(
                  '카메라 초기화 중...',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

          // 상단 컨트롤 (뒤로가기)
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              ),
            ),
          ),

          // 안내 텍스트
          Positioned(
            top: 120,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '생리대나 패드를 카메라에 가까이 대고 촬영 버튼을 눌러주세요.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // 하단 컨트롤 (촬영 버튼)
          Positioned(
            bottom: 28,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _shootAndAnalyze,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.grey,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}