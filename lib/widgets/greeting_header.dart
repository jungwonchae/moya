// widgets/greeting_header.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../themes/colortheme.dart';

class GreetingHeader extends StatelessWidget {
  final String? userName;
  final VoidCallback? onAiTap;
  final VoidCallback? onBellTap;
  final VoidCallback? onTap;
  final bool showAi;
  final bool showBell;
  final bool tappable;

  // ✅ 우측 꺾쇠 표시 + 위치 미세조정용 패딩(위쪽). 기본 0이라 기존 화면 영향 없음.
  final bool showRightChevron;
  final double chevronTop; // <— 추가

  final double height;
  final String dropAsset;

  const GreetingHeader({
    super.key,
    required this.userName,
    this.onAiTap,
    this.onBellTap,
    this.onTap,
    this.showAi = true,
    this.showBell = true,
    this.tappable = false,
    this.showRightChevron = false,
    this.chevronTop = 0, // <— 추가: 기본 0
    this.height = 180,
    this.dropAsset = 'assets/icons/moya.svg',
  });

  @override
  Widget build(BuildContext context) {
    final displayName = (userName ?? '').trim().isEmpty ? 'MOYA' : userName!.trim();

    final header = Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: const BoxDecoration(
        color: ColorTheme.mainColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start, // ← 기존 정렬 유지(다른 페이지 영향 X)
        children: [
          // 왼쪽: 로고 + 인사
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64, height: 64,
                decoration: const BoxDecoration(
                  color: ColorTheme.textWhite,
                  shape: BoxShape.circle,
                ),
                alignment: const Alignment(0.2, 0),
                child: SvgPicture.asset(
                  dropAsset,
                  width: 34, height: 34,
                  colorFilter: const ColorFilter.mode(ColorTheme.subColor, BlendMode.srcIn),
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: ColorTheme.textWhite,
                      fontSize: 16,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      const TextSpan(text: '어서오세요,\n'),
                      TextSpan(
                        text: '$displayName님!',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 오른쪽: AI / 알림 / (옵션) 꺾쇠
          Row(
            children: [
              if (showAi)
                IconButton(
                  onPressed: onAiTap,
                  icon: const Icon(Icons.center_focus_strong_rounded,
                      color: ColorTheme.textWhite, size: 28),
                  splashRadius: 22,
                  tooltip: '온디바이스 AI',
                ),
              if (showAi && showBell) const SizedBox(width: 6),
              if (showBell)
                IconButton(
                  onPressed: onBellTap,
                  icon: const Icon(Icons.notifications_none_rounded,
                      color: ColorTheme.textWhite, size: 28),
                  splashRadius: 22,
                  tooltip: '알림',
                ),

              // ✅ 꺾쇠만 아래로 내리고 싶을 때
              if (showRightChevron)
                Padding(
                  padding: EdgeInsets.only(top: chevronTop), // ← 여기만 조절!
                  child: const Icon(Icons.chevron_right_rounded,
                      color: ColorTheme.textWhite, size: 32),
                ),
            ],
          ),
        ],
      ),
    );

    return tappable
        ? Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              onTap: onTap,
              child: header,
            ),
          )
        : header;
  }
}
