import 'package:flutter/material.dart';

class OndeviceResultScreen extends StatefulWidget {
  /// 초기 결과(기본: 혈자국 있음)
  final bool initialHasBloodStain;
  const OndeviceResultScreen({super.key, this.initialHasBloodStain = true});

  @override
  State<OndeviceResultScreen> createState() => _OndeviceResultScreenState();
}

class _OndeviceResultScreenState extends State<OndeviceResultScreen> {
  late bool _hasBloodStain;
  late double _confidence;
  late String _description;
  late List<String> _stainLocations;
  late String _stainSize;

  @override
  void initState() {
    super.initState();
    _hasBloodStain = widget.initialHasBloodStain;
    _confidence = 0.0;
    _description = '';
    _stainLocations = [];
    _stainSize = 'none';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // AI 분석 결과 받기
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _hasBloodStain = args['hasBloodStain'] as bool? ?? false;
      _confidence = args['confidence'] as double? ?? 0.0;
      _description = args['description'] as String? ?? '';
      _stainLocations = (args['stainLocations'] as List<dynamic>?)
          ?.map((e) => e.toString()).toList() ?? [];
      _stainSize = args['stainSize'] as String? ?? 'none';
    }
  }

  static const _pink = Color(0xFFFF85B4);

  String _getSizeText(String size) {
    switch (size) {
      case 'small':
        return '작음';
      case 'medium':
        return '중간';
      case 'large':
        return '큼';
      default:
        return '없음';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _hasBloodStain ? '혈자국이 있어요!' : '혈자국이 없어요!';
    final subtitle = _hasBloodStain ? '지금 교체가 필요해요' : '혈이 아니에요, 안심하세요';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 🔁 데모용 결과 토글 + 디버깅 정보
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 디버깅 정보 표시 버튼
                    TextButton.icon(
                      onPressed: _showDebugInfo,
                      icon: const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                      label: const Text(
                        '분석 정보',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    // 데모용 토글
                    // TextButton.icon(
                    //   onPressed: () => setState(() => _hasBloodStain = !_hasBloodStain),
                    //   icon: const Icon(Icons.swap_horiz, size: 18, color: _pink),
                    //   label: const Text(
                    //     '데모: 결과 토글',
                    //     style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _pink),
                    //   ),
                    //   style: TextButton.styleFrom(
                    //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    //     tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    //   ),
                    // ),
                  ],
                ),

                const SizedBox(height: 60),

                // 결과 아이콘
                Center(
                  child: Icon(
                    _hasBloodStain ? Icons.water_drop_rounded : Icons.grade_rounded,
                    size: 140,
                    color: _pink,
                  ),
                ),

                const SizedBox(height: 28),

                // 결과 타이틀
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _pink,
                  ),
                ),

                const SizedBox(height: 10),

                // 결과 서브 텍스트
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 24),

                // AI 분석 결과 요약 카드
                /*
                if (_confidence > 0 || _description.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _hasBloodStain ? Colors.red[50] : Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _hasBloodStain ? Colors.red[200]! : Colors.green[200]!,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.psychology,
                              size: 20,
                              color: _hasBloodStain ? Colors.red[600] : Colors.green[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'AI 분석 결과',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _hasBloodStain ? Colors.red[600] : Colors.green[600],
                              ),
                            ),
                            const Spacer(),
                            if (_confidence > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _hasBloodStain ? Colors.red[100] : Colors.green[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_confidence.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _hasBloodStain ? Colors.red[700] : Colors.green[700],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (_description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            _description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ), 
                  ),
                  const SizedBox(height: 24),
                ],
                */

                // 확인 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // 기록 처리/분기 등은 나중에 연결
                      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_hasBloodStain ? '교체가 기록되었습니다!' : 'AI 분석이 완료되었습니다!'),
                          backgroundColor: _pink,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pink,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      elevation: 0,
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // 한번더 확인
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/ondevice_camera'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      side: const BorderSide(color: _pink),
                    ),
                    child: const Text(
                      '한번더',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _pink),
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // 하단 안내
                const Text(
                  '안심하세요!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _pink),
                ),
                const SizedBox(height: 6),
                Text(
                  'AI가 정확하게 분석하여 결과를 제공했습니다',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),

                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDebugInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('상세 분석 정보'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('혈액 감지', _hasBloodStain ? '예' : '아니오'),
              _buildInfoRow('신뢰도', '${_confidence.toStringAsFixed(1)}%'),
              _buildInfoRow('얼룩 크기', _getSizeText(_stainSize)),
              if (_stainLocations.isNotEmpty)
                _buildInfoRow('발견 위치', _stainLocations.join(', ')),
              if (_description.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'AI 설명:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(_description),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}