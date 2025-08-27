import 'package:flutter/material.dart';
import 'package:moya_app/themes/colortheme.dart';

// Firebase & Service
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moya_app/services/user_service.dart';

class InputInfoNameSettingScreen extends StatefulWidget {
  const InputInfoNameSettingScreen({super.key});

  @override
  State<InputInfoNameSettingScreen> createState() => _InputInfoNameSettingScreenState();
}

class _InputInfoNameSettingScreenState extends State<InputInfoNameSettingScreen> {
  final _userService = UserService();

  final TextEditingController nameController = TextEditingController();
  final FocusNode nameFocusNode = FocusNode();

  bool _loading = true;
  String _joinDateText = '-';

  @override
  void initState() {
    super.initState();
    // 포커스 잃으면 자동 저장
    nameFocusNode.addListener(() {
      if (!nameFocusNode.hasFocus) {
        _saveName();
      }
    });
    _loadUser();
  }

  @override
  void dispose() {
    nameController.dispose();
    nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        // 로그인 정보가 없으면 기본값
        nameController.text = '';
        _joinDateText = '-';
        setState(() => _loading = false);
        return;
      }

      // 이름 불러오기
      final name = await _userService.getUserName(uid);
      nameController.text = name ?? '';

      // 가입일 불러오기 (users/{uid}.joinDate)
      final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final ts = snap.data()?['joinDate'] as Timestamp?;
      if (ts != null) {
        final d = ts.toDate();
        _joinDateText = '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      } else {
        _joinDateText = '-';
      }
    } catch (e) {
      // 실패해도 화면은 그려줌
      _joinDateText = '-';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveName() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final text = nameController.text.trim();
      await _userService.updateName(uid: uid, name: text);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('이름이 저장되었습니다.'),
          backgroundColor: ColorTheme.subColor,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름 저장에 실패했습니다. 다시 시도해주세요.')),
      );
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorTheme.subColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 이름
                  const Text('이름',
                      style: TextStyle(fontSize: 18, color: ColorTheme.subColor, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: nameController,
                          focusNode: nameFocusNode, // 포커스 해제 시 자동 저장
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _saveName(), // 키보드 완료로도 저장
                          decoration: const InputDecoration(
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: ColorTheme.textGray, width: 0.5),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: ColorTheme.subColor, width: 2),
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Icon(Icons.edit, color: ColorTheme.iconGray, size: 20),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // 가입일
                  const Text('가입일',
                      style: TextStyle(fontSize: 18, color: ColorTheme.subColor, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 15),
                  Text(_joinDateText,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),

                  const Spacer(),

                  // 로그아웃
                  Center(
                    child: TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            contentPadding: const EdgeInsets.all(24),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.logout, color: ColorTheme.subColor, size: 48),
                                const SizedBox(height: 20),
                                const Text('로그아웃',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ColorTheme.textBlack)),
                                const SizedBox(height: 12),
                                const Text('정말 로그아웃 하시겠습니까?', textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 14, color: ColorTheme.textGray)),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 48,
                                        child: ElevatedButton(
                                          onPressed: () => Navigator.pop(context),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.grey[100],
                                            foregroundColor: Colors.grey[600],
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          child: const Text('취소', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: SizedBox(
                                        height: 48,
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            Navigator.pop(context);
                                            await _signOut(context);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red[400],
                                            foregroundColor: ColorTheme.background,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          child: const Text('로그아웃', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: const Text('로그아웃', style: TextStyle(color: ColorTheme.subColor, fontSize: 18)),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}