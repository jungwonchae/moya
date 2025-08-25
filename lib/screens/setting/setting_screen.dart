import 'package:flutter/material.dart';
import 'package:moya_app/widgets/greeting_header.dart';
import 'package:moya_app/widgets/nav_bar.dart';
import 'package:moya_app/themes/colortheme.dart';

class SettingScreen extends StatelessWidget {
  final String userName = '민서';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: NavBar(currentIndex: 2),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ✅ 헤더: 아이콘 숨김 + 전체 탭 → 이름 변경
              GreetingHeader(
                userName: userName,
                height: 120,
                dropAsset: 'assets/icons/moya.svg',
                showAi: false,
                showBell: false,
                chevronTop: 15,   
                tappable: true,
                showRightChevron: true,   
                onTap: () => Navigator.pushNamed(context, '/setting_name'),
              ),

              const SizedBox(height: 20),

              // 리스트 섹션
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _SettingItem(
                      icon: Icons.notifications,
                      title: '알림 문구 설정',
                      onTap: () => Navigator.pushNamed(context, '/setting_nick'),
                    ),
                    _SettingItem(
                      icon: Icons.calendar_today,
                      title: '생리 주기 입력',
                      onTap: () => Navigator.pushNamed(context, '/setting_period'),
                    ),
                    _SettingItem(
                      icon: Icons.bluetooth,
                      title: '블루투스 연결 관리',
                      onTap: () => Navigator.pushNamed(context, '/setting_bluetooth'),
                    ),
                    _SettingItem(
                      icon: Icons.help_outline,
                      title: '앱 사용 안내',
                      onTap: () => Navigator.pushNamed(context, '/usage_container'),
                    ),

                    const SizedBox(height: 20),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: ColorTheme.subColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 20),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
