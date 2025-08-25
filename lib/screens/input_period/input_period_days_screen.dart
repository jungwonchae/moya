import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moya_app/themes/colortheme.dart';  // mainColor 가져오기
import 'package:moya_app/widgets/confirm_button.dart';
import 'package:moya_app/widgets/choice_button.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:moya_app/services/period_service.dart';

class InputPeriodDaysScreen extends StatefulWidget {
  @override
  _InputPeriodDaysScreenState createState() => _InputPeriodDaysScreenState();
}

class _InputPeriodDaysScreenState extends State<InputPeriodDaysScreen> {
  TextEditingController dayController = TextEditingController();
  final PeriodService _service = PeriodService();
  bool _saving = false;

  final List<String> dayPresets = ["3", "4", "5", "6"];

  Future<void> _onNext() async {
    if (_saving) return;

    final daysText = dayController.text.trim();
    final days = int.tryParse(daysText);
    if (days == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('숫자를 입력해 주세요.'), backgroundColor: Colors.red),
      );
      return;
    }

    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    final recentStartDate = args['recentStartDate'] as DateTime?;
    final userId = args['userId'] as String?;
    final periodId = args['periodId'] as String?;
    final cycleLength = args['cycleLength']; // 다음 화면에 넘길 용도(있으면)

    if (userId == null || userId.isEmpty || periodId == null || periodId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('세션 정보가 없습니다. 처음부터 다시 시도해 주세요.'), backgroundColor: Colors.red),
      );
      // ignore: avoid_print
      print('[DaysScreen] missing userId/periodId. args=$args');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await _service.updatePeriodData(periodId, {
        'periodLength': days,
      });
      // ignore: avoid_print
      print('[DaysScreen] periodLength saved: $days for periodId=$periodId');

      Navigator.pushNamed(
        context,
        '/input_extra',
        arguments: {
          'userId': userId,
          'periodId': periodId,
          'recentStartDate': recentStartDate,
          'cycleLength': cycleLength,
          'periodLength': days,
        },
      );
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: ${e.message ?? e.code}'), backgroundColor: Colors.red),
      );
      // ignore: avoid_print
      print('[DaysScreen] FirebaseException: ${e.code} ${e.message}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장에 실패했습니다. 다시 시도해 주세요.'), backgroundColor: Colors.red),
      );
      // ignore: avoid_print
      print('[DaysScreen] Unknown error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)!.settings.arguments as Map?) ?? {};
    final recentStartDate = args['recentStartDate'] as DateTime;
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
              '생리 기간',
              style: TextStyle(
                fontSize: 14,
                color: ColorTheme.subColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            SizedBox(height: 20),
            
            // 제목
            Text(
              '생리는 보통\n며칠 동안 지속되나요?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: ColorTheme.textBlack,
              ),
            ),
            
            SizedBox(height: 8),
            
            // 부제목
            Text(
              '평균 며칠간 출혈이 지속되는지 알려주세요',
              style: TextStyle(
                fontSize: 14,
                color: ColorTheme.textGray,
              ),
            ),
            
            SizedBox(height: 40),
            
            // 선택 버튼들
            Row(
              children: [
                Expanded(
                  child: ChoiceButton<String>(
                    value: dayPresets[0],
                    label: "${dayPresets[0]}일",                 // 화면 표시용
                    isSelected: dayController.text.trim() == dayPresets[0],
                    onTap: () => setState(() => dayController.text = dayPresets[0]),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ChoiceButton<String>(
                    value: dayPresets[1],
                    label: "${dayPresets[1]}일",                 // 화면 표시용
                    isSelected: dayController.text.trim() == dayPresets[1],
                    onTap: () => setState(() => dayController.text = dayPresets[1]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: ChoiceButton<String>(
                    value: dayPresets[2],
                    label: "${dayPresets[2]}일",                 // 화면 표시용
                    isSelected: dayController.text.trim() == dayPresets[2],
                    onTap: () => setState(() => dayController.text = dayPresets[2]),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ChoiceButton<String>(
                    value: dayPresets[3],
                    label: "${dayPresets[3]}일",                 // 화면 표시용
                    isSelected: dayController.text.trim() == dayPresets[3],
                    onTap: () => setState(() => dayController.text = dayPresets[3]),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 15),
            
            // 입력 필드
            TextField(
              controller: dayController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly], //숫자만
              decoration: InputDecoration(
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: ColorTheme.mainColor, width: 2),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: ColorTheme.subColor, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                suffixText: "일",
              ),
              onChanged: (value) {
                setState(() {});
              },
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
              text: '다음',                            // 항상 '다음'
              isEnabled: dayController.text.trim().isNotEmpty && !_saving,
              onPressed: _saving ? null : _onNext,   // 중복 클릭 방지
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}