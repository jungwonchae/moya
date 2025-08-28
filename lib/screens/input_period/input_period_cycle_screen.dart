import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moya_app/themes/colortheme.dart';
import 'package:moya_app/widgets/confirm_button.dart';
import 'package:moya_app/widgets/choice_button.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:moya_app/services/period_service.dart';

class InputPeriodCycleScreen extends StatefulWidget {
  @override
  _InputPeriodCycleScreenState createState() => _InputPeriodCycleScreenState();
}

class _InputPeriodCycleScreenState extends State<InputPeriodCycleScreen> {
  TextEditingController cycleController = TextEditingController();

  final PeriodService _service = PeriodService();
  bool _saving = false;
  bool _loading = true;

  final List<String> cyclePresets = ["20", "25", "28", "30"];
  
  // 수정 모드인지 확인
  bool isEditMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingData();
    });
  }

  Future<void> _loadExistingData() async {
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    isEditMode = args['isEdit'] == true;
    
    if (isEditMode) {
      final periodId = args['periodId'] as String?;
      if (periodId != null) {
        try {
          final data = await _service.getPeriodData(periodId);
          final existingCycle = data['cycleLength'] as int?;
          if (existingCycle != null && mounted) {
            setState(() {
              cycleController.text = existingCycle.toString();
            });
          }
        } catch (e) {
          print('[CycleScreen] Error loading existing data: $e');
        }
      }
    }
    
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _onNext() async {
    if (_saving) return;

    final cycle = int.tryParse(cycleController.text.trim());
    if (cycle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('숫자를 입력해 주세요.'), backgroundColor: Colors.red),
      );
      return;
    }

    // 이전 화면에서 값 받기
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    final recentStartDate = args['recentStartDate'] as DateTime?;
    final userId = args['userId'] as String?;
    final periodId = args['periodId'] as String?;

    if (userId == null || userId.isEmpty || periodId == null || periodId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('세션 정보가 없습니다. 처음부터 다시 시도해 주세요.'), backgroundColor: Colors.red),
      );
      print('[CycleScreen] missing userId/periodId. args=$args');
      return;
    }

    setState(() => _saving = true);
    try {
      await _service.updatePeriodData(periodId, {
        'cycleLength': cycle,
      });
      print('[CycleScreen] cycleLength saved: $cycle for periodId=$periodId');

      if (isEditMode) {
        // 수정 모드면 뒤로가기
        Navigator.pop(context);
      } else {
        // 일반 모드면 다음 화면으로
        Navigator.pushNamed(
          context,
          '/input_days',
          arguments: {
            'userId': userId,
            'periodId': periodId,
            'recentStartDate': recentStartDate,
            'cycleLength': cycle,
          },
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장 실패. 다시 시도해 주세요.'), backgroundColor: Colors.red),
      );
      print('[CycleScreen] error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_loading) {
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
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ColorTheme.mainColor),
          ),
        ),
      );
    }

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
              '평균 주기 길이',
              style: TextStyle(
                fontSize: 14,
                color: ColorTheme.subColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            SizedBox(height: 20),
            
            // 제목
            Text(
              isEditMode ? '생리 주기를\n수정해주세요' : '보통 생리 주기는 며칠인가요?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: ColorTheme.textBlack,
                height: 1.3,
              ),
            ),
            
            SizedBox(height: 8),
            
            // 부제목
            Text(
              isEditMode ? '평균 주기 길이를 다시 입력해주세요' : '한 번 시작일부터 다음 시작일까지 걸리는 일수',
              textAlign: TextAlign.center,
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
                    value: cyclePresets[0],
                    label: "${cyclePresets[0]}일",                 // 화면 표시용
                    isSelected: cycleController.text.trim() == cyclePresets[0],
                    onTap: () => setState(() => cycleController.text = cyclePresets[0]),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ChoiceButton<String>(
                    value: cyclePresets[1],
                    label: "${cyclePresets[1]}일",                 // 화면 표시용
                    isSelected: cycleController.text.trim() == cyclePresets[1],
                    onTap: () => setState(() => cycleController.text = cyclePresets[1]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: ChoiceButton<String>(
                    value: cyclePresets[2],
                    label: "${cyclePresets[2]}일",                 // 화면 표시용
                    isSelected: cycleController.text.trim() == cyclePresets[2],
                    onTap: () => setState(() => cycleController.text = cyclePresets[2]),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ChoiceButton<String>(
                    value: cyclePresets[3],
                    label: "${cyclePresets[3]}일",                 // 화면 표시용
                    isSelected: cycleController.text.trim() == cyclePresets[3],
                    onTap: () => setState(() => cycleController.text = cyclePresets[3]),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 15),
            
            // 입력 필드
            TextField(
              controller: cycleController,
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

            const SizedBox(height: 8),
            

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
              text: isEditMode ? '저장' : '다음',
              isEnabled: cycleController.text.trim().isNotEmpty && !_saving,
              onPressed: _saving ? null : _onNext,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}