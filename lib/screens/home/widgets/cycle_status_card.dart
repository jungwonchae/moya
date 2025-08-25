import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../themes/colortheme.dart';

/// 생리 상태 배너 카드
class CycleStatusCard extends StatelessWidget {
  final bool isOnPeriod;
  final int days;
  final String dropAsset;
  final VoidCallback? onTap;

  /// 아이콘 크기와 텍스트와의 간격을 조절할 수 있어요.
  final double iconSize;
  final double gap;

  const CycleStatusCard({
    super.key,
    required this.isOnPeriod,
    required this.days,
    this.dropAsset = 'assets/icons/moya.svg',
    this.onTap,
    this.iconSize = 44, // 아이콘 크기
    this.gap = 12,      // 글씨와 아이콘 간격
  });

  @override
  Widget build(BuildContext context) {
    final title   = isOnPeriod ? '생리중이에요!' : '곧 생리주기가 돌아와요!';
    final subtitle = isOnPeriod ? '$days일 남음' : '${days}일뒤 시작';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: ColorTheme.background, // 배경 → 흰색
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEAEAF1)),
          boxShadow: const [
            BoxShadow(
              color: ColorTheme.shadow, // 그림자 (10%)
              offset: Offset(0, 4),
              blurRadius: 28,
            ),
            BoxShadow(
              color: Color(0x14EAEAF1), // 서브 그림자 (8%) → ColorTheme에 없어서 유지
              offset: Offset(0, 20),
              blurRadius: 60,
              spreadRadius: -10,
            ),
          ],
        ),

        // 아이콘과 텍스트를 세로 중앙 정렬
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8), // 양옆 패딩
              child: SizedBox(
                width: iconSize,
                height: iconSize,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SvgPicture.asset(
                    dropAsset,
                    colorFilter: const ColorFilter.mode(
                      ColorTheme.subColor, // 브랜드 핑크
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: gap), // 텍스트와 간격

            // 텍스트 블록
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min, // 높이 최소화
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '현재 내 상태',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ColorTheme.textGray, // 그레이 텍스트
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: ColorTheme.textBlack, // 검정 텍스트
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: ColorTheme.subColor, // 진한 핑크
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
