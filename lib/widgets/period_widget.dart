import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../themes/colortheme.dart';

/// 생리대 상태
enum PadStatus { before, fresh, warning, danger }

/// 얼굴 + 상태문구 + (옵션) 데모 토글 + (내장) 아래 섹션(시작 전/후)
class PeriodWidget extends StatefulWidget {
  final PadStatus status;                 // 초기 상태
  final bool showDemoToggle;              // 데모 토글 노출
  final ValueChanged<PadStatus>? onStatusChanged; // 상태 변경 콜백(선택)
  final VoidCallback? onStartTap;         // "생리 시작 하셨나요?" CTA 탭 콜백
  final int changeCount;                  // 교체 횟수(시작 후)
  final String lastChangeText;            // 마지막 교체 문구(시작 후)
  /// 아이콘을 화면 너비의 몇 %로 보일지 (기본 0.30 = 30%)
  final double iconScaleOfWidth;

  const PeriodWidget({
    super.key,
    required this.status,
    this.showDemoToggle = true,
    this.onStatusChanged,
    this.onStartTap,
    this.changeCount = 0,
    this.lastChangeText = '-',
    this.iconScaleOfWidth = 0.45,
  });

  @override
  State<PeriodWidget> createState() => _PeriodWidgetState();
}

class _PeriodWidgetState extends State<PeriodWidget> {
  late PadStatus _status;

  @override
  void initState() {
    super.initState();
    _status = widget.status;
  }

  // 아이콘 경로
  String get _icon {
    switch (_status) {
      case PadStatus.before:  return 'assets/icons/periodBefore.svg';
      case PadStatus.fresh:   return 'assets/icons/periodSafe.svg';
      case PadStatus.warning: return 'assets/icons/periodWarning.svg';
      case PadStatus.danger:  return 'assets/icons/periodNeed.svg';
    }
  }

  // 컬러
  Color get _color {
    switch (_status) {
      case PadStatus.before:  return ColorTheme.textLightGray;
      case PadStatus.fresh:   return ColorTheme.periodSafe;
      case PadStatus.warning: return ColorTheme.periodWarning;
      case PadStatus.danger:  return ColorTheme.periodNeed;
    }
  }

  // 문구
  String get _message {
    switch (_status) {
      case PadStatus.before:  return '아직은 시작 전이에요!';
      case PadStatus.fresh:   return '아직은 보송보송 해요';
      case PadStatus.warning: return '곧 교체할 시간이 다가와요';
      case PadStatus.danger:  return '교체가 필요해요';
    }
  }

  void _nextStatus() {
    setState(() {
      switch (_status) {
        case PadStatus.before:  _status = PadStatus.fresh;   break;
        case PadStatus.fresh:   _status = PadStatus.warning; break;
        case PadStatus.warning: _status = PadStatus.danger;  break;
        case PadStatus.danger:  _status = PadStatus.before;  break;
      }
    });
    widget.onStatusChanged?.call(_status);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final iconSize = w * widget.iconScaleOfWidth; // 화면 너비의 30%
    final cardWidth = w - 48; // 좌우 24씩 여백 → 두 카드 동일 폭

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 얼굴 아이콘
        SvgPicture.asset(
          _icon,
          width: iconSize,
          height: iconSize,
          placeholderBuilder: (_) => SizedBox(
            width: iconSize, height: iconSize,
            child: const Center(child: CircularProgressIndicator()),
          ),
        ),
        const SizedBox(height: 10),

        // 상태 문구 (조금 더 작게)
        Text(
          _message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _color,
          ),
        ),

        // 데모용 토글 버튼
        /*
        if (widget.showDemoToggle) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _nextStatus,
            icon: const Icon(Icons.autorenew, size: 16),
            label: const Text('상태 바꾸기'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(120, 34),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              foregroundColor: ColorTheme.subColor,
              side: const BorderSide(color: ColorTheme.subColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
        ],
        */

        const SizedBox(height: 14),

        // ▼ 아래 섹션: 시작 전이면 CTA 카드, 그 외엔 교체현황 카드
        if (_status == PadStatus.before)
          _PeriodStartCtaCard(width: cardWidth, onTap: widget.onStartTap)
        else
          _PadStatsCard(
            width: cardWidth,
            changeCount: widget.changeCount,
            lastChangeText: widget.lastChangeText,
          ),
      ],
    );
  }
}

/// 시작 전일 때 표시되는 CTA 카드 (폭/높이 고정, 패딩/폰트 축소)
/// 시작 전일 때 표시되는 CTA 카드 (가로·세로 완전 중앙정렬)
class _PeriodStartCtaCard extends StatelessWidget {
  final double width;
  final VoidCallback? onTap;
  const _PeriodStartCtaCard({required this.width, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFEAEAF1)),
            boxShadow: const [
              BoxShadow(color: Color(0x192E3176), blurRadius: 24, offset: Offset(0, 4)),
              BoxShadow(color: Color(0x14EAEAF1), blurRadius: 48, spreadRadius: -8, offset: Offset(0, 18)),
            ],
          ),

          // ✅ 중앙 정렬
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center, // 세로 중앙
              crossAxisAlignment: CrossAxisAlignment.center, // 가로 중앙
              children: const [
                Text(
                  '생리 시작 하셨나요?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: ColorTheme.subColor,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '시작하셨다면 여기를 눌러주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 시작 후일 때 표시되는 2-칸 교체 현황 카드 (폭/높이 고정, 패딩/폰트 축소)
class _PadStatsCard extends StatelessWidget {
  final double width;
  final int changeCount;
  final String lastChangeText;

  const _PadStatsCard({
    required this.width,
    required this.changeCount,
    required this.lastChangeText,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        constraints: const BoxConstraints(minHeight: 88),
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFEAEAF1)),
          boxShadow: const [
            BoxShadow(color: Color(0x192E3176), blurRadius: 24, offset: Offset(0, 4)),
            BoxShadow(color: Color(0x14EAEAF1), blurRadius: 48, spreadRadius: -8, offset: Offset(0, 18)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('오늘 교체 횟수',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                  const SizedBox(height: 6),
                  Text('$changeCount회',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: ColorTheme.subColor)),
                ],
              ),
            ),
            Container(width: 1, height: 34, color: const Color(0xFFEAEAF1)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('마지막 교체',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                  const SizedBox(height: 6),
                  Text(lastChangeText,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: ColorTheme.subColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
