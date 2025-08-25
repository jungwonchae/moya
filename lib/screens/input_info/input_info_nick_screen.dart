import 'package:flutter/material.dart';
import 'package:moya_app/themes/colortheme.dart';  // mainColor 가져오기
import 'package:moya_app/widgets/confirm_button.dart';
import 'package:moya_app/widgets/choice_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moya_app/services/period_service.dart';



class InputInfoNickScreen extends StatefulWidget {
  @override
  _InputInfoNickScreenState createState() => _InputInfoNickScreenState();
}

class _InputInfoNickScreenState extends State<InputInfoNickScreen> {
  TextEditingController nickController = TextEditingController();
  final PeriodService _periodService = PeriodService(); // Provider 없어도 OK
  bool _saving = false;

  final List<String> nickPresets = ["모야예요!", "교체하세요.", "모야모야?!", "교체 알림!"];
  
  Future<void> _onNext() async {
    final nick = nickController.text.trim();
    if (nick.isEmpty || _saving) return;

    // 이전 화면에서 userId 받아오기
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final userId = (args?['userId'] as String?) ?? '';

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('사용자 정보를 찾을 수 없어요. 다시 시도해 주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      // 디버그 로그
      // ignore: avoid_print
      print('[NickScreen] Missing userId in route arguments: $args');
      return;
    }

    setState(() => _saving = true);
    try {
      final periodId = await _periodService.createDraftWithNick(
        userId: userId,
        nick: nick,
      );

      // 디버그 로그
      // ignore: avoid_print
      print('[NickScreen] Saved nick draft. periodId=$periodId userId=$userId nick=$nick');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('알림 문구가 저장되었어요'),
          backgroundColor: ColorTheme.subColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      Navigator.pushNamed(
        context,
        '/input_recent',
        arguments: {
          'userId': userId,
          'periodId': periodId,
          'nick': nick,
        },
      );
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 실패: ${e.message ?? e.code}'),
          backgroundColor: Colors.red,
        ),
      );
      // ignore: avoid_print
      print('[NickScreen] FirebaseException: ${e.code} ${e.message}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('저장에 실패했습니다. 다시 시도해 주세요.'), backgroundColor: Colors.red),
      );
      // ignore: avoid_print
      print('[NickScreen] Unknown error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canProceed = nickController.text.trim().isNotEmpty && !_saving;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
            // 단계 표시
            Text(
              '별명 입력',
              style: TextStyle(
                fontSize: 14,
                color: ColorTheme.subColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            SizedBox(height: 20),
            
            // 제목
            Text(
              '알림에 표시될 문구를 정해주세요',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: ColorTheme.textBlack,
              ),
            ),
            
            SizedBox(height: 8),
            
            // 부제목
            Text(
              '예시: "생리대 교체 시기입니다."',
              style: TextStyle(
                fontSize: 14,
                color: ColorTheme.textGray,
              ),
            ),
            
            SizedBox(height: 40),
            
            // 선택 버튼들
            // 선택 상태는 nickController.text 로 판정
            Row(
              children: [
                Expanded(
                  child: ChoiceButton<String>(
                    value: nickPresets[0],
                    label: nickPresets[0],
                    isSelected: nickController.text.trim() == nickPresets[0],
                    onTap: () => setState(() => nickController.text = nickPresets[0]),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ChoiceButton<String>(
                    value: nickPresets[1],
                    label: nickPresets[1],
                    isSelected: nickController.text.trim() == nickPresets[1],
                    onTap: () => setState(() => nickController.text = nickPresets[1]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: ChoiceButton<String>(
                    value: nickPresets[2],
                    label: nickPresets[2],
                    isSelected: nickController.text.trim() == nickPresets[2],
                    onTap: () => setState(() => nickController.text = nickPresets[2]),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ChoiceButton<String>(
                    value: nickPresets[3],
                    label: nickPresets[3],
                    isSelected: nickController.text.trim() == nickPresets[3],
                    onTap: () => setState(() => nickController.text = nickPresets[3]),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 15),
            
            // 입력 필드
            TextField(
              controller: nickController,
              decoration: InputDecoration(
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: ColorTheme.mainColor, width: 2),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: ColorTheme.subColor, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              onChanged: (_) => setState(() {}),
            ),

            SizedBox(height: 8),

            // 밑줄(입력) 아래 텍스트
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '직접 입력',
                style: TextStyle(
                  fontSize: 14,
                  color: ColorTheme.textLightGray,
                ),
              ),
            ),

            Spacer(),
            
            // 다음 버튼
            ConfirmButton(
              text: '다음',
              isEnabled: canProceed,
              onPressed: _saving ? null : _onNext,
            ),
            
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}