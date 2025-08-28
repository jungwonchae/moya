import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moya_app/themes/colortheme.dart';
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
  bool _loading = true;

  final List<String> dayPresets = ["3", "4", "5", "6"];
  
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
    
    print('[DaysScreen] _loadExistingData called, isEditMode: $isEditMode');
    
    if (isEditMode) {
      final periodId = args['periodId'] as String?;
      print('[DaysScreen] periodId: $periodId');
      
      if (periodId != null) {
        try {
          final data = await _service.getPeriodData(periodId);
          print('[DaysScreen] Firebase data received: $data');
          
          // 다양한 필드명으로 시도
          int? existingDays;
          existingDays = data['periodLength'] as int?;
          if (existingDays == null) {
            existingDays = data['periodDays'] as int?;
          }
          if (existingDays == null) {
            existingDays = data['days'] as int?;
          }
          
          print('[DaysScreen] Existing days found: $existingDays');
          
          if (existingDays != null && mounted) {
            setState(() {
              dayController.text = existingDays.toString();
            });
            print('[DaysScreen] dayController set to: ${dayController.text}');
          } else {
            print('[DaysScreen] No existing days data found');
          }
        } catch (e) {
          print('[DaysScreen] Error loading existing data: $e');
        }
      } else {
        print('[DaysScreen] periodId is null');
      }
    }
    
    if (mounted) {
      setState(() => _loading = false);
    }
    print('[DaysScreen] _loadExistingData completed');
  }

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
    final cycleLength = args['cycleLength'];

    if (userId == null || userId.isEmpty || periodId == null || periodId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('세션 정보가 없습니다. 처음부터 다시 시도해 주세요.'), backgroundColor: Colors.red),
      );
      print('[DaysScreen] missing userId/periodId. args=$args');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await _service.updatePeriodData(periodId, {
        'periodLength': days,
      });
      print('[DaysScreen] periodLength saved: $days for periodId=$periodId');

      if (isEditMode) {
        // 수정 모드면 뒤로가기
        Navigator.pop(context);
      } else {
        // 일반 모드면 다음 화면으로
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
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장에 실패했습니다. 다시 시도해 주세요.'), backgroundColor: Colors.red),
      );
      print('[DaysScreen] error: $e');
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
              isEditMode ? '생리 기간을\n수정해주세요' : '생리는 보통\n며칠 동안 지속되나요?',
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
              isEditMode ? '출혈이 지속되는 기간을 다시 입력해주세요' : '평균 며칠간 출혈이 지속되는지 알려주세요',
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
                    value: dayPresets[0],
                    label: "${dayPresets[0]}일",
                    isSelected: dayController.text.trim() == dayPresets[0],
                    onTap: () => setState(() => dayController.text = dayPresets[0]),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ChoiceButton<String>(
                    value: dayPresets[1],
                    label: "${dayPresets[1]}일",
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
                    label: "${dayPresets[2]}일",
                    isSelected: dayController.text.trim() == dayPresets[2],
                    onTap: () => setState(() => dayController.text = dayPresets[2]),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ChoiceButton<String>(
                    value: dayPresets[3],
                    label: "${dayPresets[3]}일",
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
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
              text: isEditMode ? '저장' : '다음',
              isEnabled: dayController.text.trim().isNotEmpty && !_saving,
              onPressed: _saving ? null : _onNext,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}