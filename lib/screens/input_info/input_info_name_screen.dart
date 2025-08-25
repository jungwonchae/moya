// lib/screens/onboard/input_info_name_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:moya_app/themes/colortheme.dart';
import 'package:moya_app/widgets/confirm_button.dart';
import 'package:moya_app/services/user_service.dart';

class InputInfoNameScreen extends StatefulWidget {
  @override
  _InputInfoNameScreenState createState() => _InputInfoNameScreenState();
}

class _InputInfoNameScreenState extends State<InputInfoNameScreen> {
  final TextEditingController nameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _onNext() async {
    final userService = context.read<UserService>();
    final name = nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final docId = await userService.createUser(name: name);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('환영합니다, $name님!'),
          backgroundColor: ColorTheme.subColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      Navigator.pushNamed(
        context,
        '/input_nick',
        arguments: {'userId': docId, 'name': name},
      );
    } on FirebaseException catch (e) {
      // 에러 메시지는 UI에서
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 실패: ${e.message ?? e.code}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장에 실패했습니다. 다시 시도해주세요.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canProceed = nameController.text.trim().isNotEmpty && !_isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('이름 입력',
              style: TextStyle(fontSize: 14, color: ColorTheme.subColor, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 20),
            Text('이름을 입력해주세요',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ColorTheme.textBlack),
            ),
            SizedBox(height: 8),
            Text('별명을 입력해도 돼요!',
              style: TextStyle(fontSize: 14, color: ColorTheme.textGray),
            ),
            SizedBox(height: 40),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: ColorTheme.mainColor!, width: 2),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: ColorTheme.subColor, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('ex) 홍길동',
                style: TextStyle(fontSize: 14, color: ColorTheme.textLightGray),
              ),
            ),
            Spacer(),
            ConfirmButton(
              text: _isLoading ? '저장중...' : '다음',
              isEnabled: canProceed,
              onPressed: _isLoading ? null : _onNext,
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}