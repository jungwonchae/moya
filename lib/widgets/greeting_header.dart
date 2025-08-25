import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../themes/colortheme.dart';

/// 상단 인사 헤더
/// - 왼쪽: 흰 원 안에 분홍 물방울(SVG)
/// - 가운데: "어서오세요,\n{이름}님!" (이름 없으면 'MOYA')
/// - 오른쪽: 온디바이스 AI 버튼(카메라/포커스 아이콘) + 알림 버튼
class GreetingHeader extends StatelessWidget {
  final String? userName;
  final VoidCallback? onAiTap;
  final VoidCallback? onBellTap;
  final double height;
  final String dropAsset;

  const GreetingHeader({
    super.key,
    required this.userName,
    this.onAiTap,
    this.onBellTap,
    this.height = 180,
    this.dropAsset = 'assets/icons/moya.svg',
  });

  @override
  Widget build(BuildContext context) {
    final displayName =
        (userName ?? '').trim().isEmpty ? 'MOYA' : userName!.trim();

    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: const BoxDecoration(
        color: ColorTheme.mainColor, // 메인 브랜드 핑크
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 왼쪽: 로고 + 인사
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 흰 원 안에 물방울
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: ColorTheme.textWhite, // 흰색 원
                  shape: BoxShape.circle,
                ),
                alignment: const Alignment(0.2, 0),
                child: SvgPicture.asset(
                  dropAsset,
                  width: 34,
                  height: 34,
                  colorFilter: const ColorFilter.mode(
                    ColorTheme.subColor, // 브랜드 진한 핑크
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: ColorTheme.textWhite, // 기본 글자 흰색
                      fontSize: 16,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      const TextSpan(text: '어서오세요,\n'),
                      TextSpan(
                        text: '$displayName님!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: ColorTheme.textWhite, // 이름 강조도 흰색
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 오른쪽: AI + 알림
          Row(
            children: [
              IconButton(
                onPressed: onAiTap,
                icon: const Icon(
                  Icons.center_focus_strong_rounded,
                  color: ColorTheme.textWhite, // 아이콘도 흰색
                  size: 28,
                ),
                splashRadius: 22,
                tooltip: '온디바이스 AI',
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: onBellTap,
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: ColorTheme.textWhite, // 아이콘도 흰색
                  size: 28,
                ),
                splashRadius: 22,
                tooltip: '알림',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
