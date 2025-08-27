import 'package:flutter/material.dart';
import 'package:moya_app/widgets/greeting_header.dart';
import 'package:moya_app/widgets/nav_bar.dart';
import 'package:moya_app/themes/colortheme.dart';

// Firebase & Service
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moya_app/services/user_service.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final UserService _userService = UserService();

  String? _userName;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        // 로그인 상태가 없으면 익명 로그인 or 로그인 화면 이동 등 처리
        setState(() {
          _userName = null;
          _loading = false;
        });
        return;
      }

      final name = await _userService.getUserName(uid);
      if (!mounted) return;
      setState(() {
        _userName = name; // null이면 GreetingHeader에서 기본 처리
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const NavBar(currentIndex: 2),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadUserName,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // ✅ 헤더: 파베에서 가져온 이름 사용
                      GreetingHeader(
                        userName: _userName,               // ← 여기!
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
                            const SizedBox(height: 24),
                          ],
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
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
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