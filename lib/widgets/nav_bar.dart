import 'package:flutter/material.dart';
import '../themes/colortheme.dart';
// 각 탭의 스크린 import
import 'package:moya_app/screens/home/home_screen.dart';
import 'package:moya_app/screens/data_period/data_period_screen.dart';
import 'package:moya_app/screens/setting/setting_screen.dart';

class NavBar extends StatelessWidget {
  final int currentIndex;
  const NavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _item(context, Icons.home, 0, currentIndex == 0, HomeScreen()),
          _item(context, Icons.calendar_today, 1, currentIndex == 1, DataPeriodScreen()),
          _item(context, Icons.settings, 2, currentIndex == 2, SettingScreen()),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, int index, bool isActive, Widget page) {
    return GestureDetector(
      onTap: () {
        if (isActive) return;
        Navigator.of(context).pushReplacement(_noAnim(page));
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            height: 2, width: 45,
            color: isActive ? ColorTheme.mainColor : Colors.transparent,
          ),
          Icon(icon, size: 32, color: isActive ? ColorTheme.mainColor : Colors.grey[400]),
        ],
      ),
    );
  }

  // 전환 애니메이션 0
  PageRoute _noAnim(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      );
}
