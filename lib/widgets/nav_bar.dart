import 'package:flutter/material.dart';
import '../themes/colortheme.dart';

class NavBar extends StatelessWidget {
  final int currentIndex;

  const NavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24), // 아래에서 얼마나 떨어져있는지
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(context, Icons.home, 0, currentIndex == 0, '/home'),
          _buildNavItem(context, Icons.calendar_today, 1, currentIndex == 1, '/data'),
          _buildNavItem(context, Icons.settings, 2, currentIndex == 2, '/setting'),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, int index, bool isActive, String route) {
    return GestureDetector(
      onTap: () {
        if (!isActive) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✅ 활성화된 탭 밑줄
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            height: 2,
            width: 45,
            color: isActive ? ColorTheme.mainColor : Colors.transparent,
          ),
          // ✅ 아이콘 (색만 바뀜)
          Icon(
            icon,
            size: 32,
            color: isActive ? ColorTheme.mainColor : Colors.grey[400],
          ),
        ],
      ),
    );
  }
}
