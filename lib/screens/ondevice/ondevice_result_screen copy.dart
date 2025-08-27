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

  @override
  void initState() {
    super.initState();
    _hasBloodStain = widget.initialHasBloodStain;
  }

  static const _pink = Color(0xFFFF85B4);

  @override
  Widget build(BuildContext context) {
    final title = _hasBloodStain ? '혈자국이 있어요!' : '혈자국이 없어요!';
    final subtitle = _hasBloodStain ? '지금 교체가 필요해요' : '혈이 아니에요, 안심하세요';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🔁 데모용 결과 토글 (원하면 삭제 가능)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => setState(() => _hasBloodStain = !_hasBloodStain),
                  icon: const Icon(Icons.swap_horiz, size: 18, color: _pink),
                  label: const Text(
                    '데모: 결과 토글',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _pink),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),

              const SizedBox(height: 120),

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

              const SizedBox(height: 48),

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

              const Spacer(),

              // 하단 안내
              const Text(
                '안심하세요!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _pink),
              ),
              const SizedBox(height: 6),
              Text(
                '데이터는 안전하게, 기기 안에서만 처리됩니다',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
