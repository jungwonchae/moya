import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moya_app/themes/colortheme.dart';
import 'package:moya_app/widgets/confirm_button.dart';
import 'package:moya_app/widgets/choice_button.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:moya_app/services/period_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

class InputPeriodDaysScreen extends StatefulWidget {
  @override
  _InputPeriodDaysScreenState createState() => _InputPeriodDaysScreenState();
}

class _InputPeriodDaysScreenState extends State<InputPeriodDaysScreen> {
  bool? isOnMedication;
  DateTime selectedDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime? recentStartDate;
  
  final PeriodService _service = PeriodService();
  bool _saving = false;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    // arguments에서 recentStartDate 가져오기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
      final startDate = args['recentStartDate'] as DateTime?;
      
      if (startDate != null) {
        setState(() {
          recentStartDate = _dateOnly(startDate);
          // selectedDate가 recentStartDate 이전이면 보정
          final selectedOnly = _dateOnly(selectedDate);
          if (selectedOnly.isBefore(recentStartDate!)) {
            selectedDate = recentStartDate!.add(const Duration(days: 1));
          }
        });
      } else {
        // startDate가 없을 때 안내
        debugPrint('[DaysScreen] recentStartDate not found in arguments');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('생리 시작일 정보를 불러오지 못했어요. 이전 단계에서 먼저 시작일을 저장해 주세요.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  // 날짜 함수
  String formatKoreanDate(DateTime d) {
    return "${d.year}년 ${d.month}월 ${d.day}일";
  }
  
  // 플랫폼별 날짜 선택
  Future<void> _pickDateAdaptive() async {
    if (recentStartDate == null) return;
    
    if (Platform.isIOS) {
      _showCupertinoDatePicker();
    } else {
      final picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: recentStartDate!,
        lastDate: DateTime(2035),
        helpText: '날짜 선택',
      );
      if (picked != null) setState(() => selectedDate = picked);
    } 
  }

  // iOS 스타일 모달 피커
  void _showCupertinoDatePicker() {
    if (recentStartDate == null) return;
    
    DateTime temp = selectedDate;
    final min = recentStartDate!;
    final max = DateTime.now().add(const Duration(days: 365));

    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return CupertinoTheme(
          data: CupertinoThemeData(
            brightness: Brightness.light,
            primaryColor: ColorTheme.subColor,
          ),
          child: CupertinoPopupSurface(
            isSurfacePainted: true,
            child: Container(
              height: 320,
              color: CupertinoColors.systemBackground,
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    SizedBox(
                      height: 44,
                      child: Row(
                        children: [
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: const Text('취소'),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: const Text(
                              '완료',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            onPressed: () {
                              setState(() => selectedDate = temp);
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 0.5),
                    Expanded(
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.date,
                        initialDateTime: selectedDate,
                        minimumDate: min,
                        maximumDate: max,
                        onDateTimeChanged: (d) => temp = d,
                        backgroundColor: CupertinoColors.systemBackground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Firebase에 생리 정보 저장
  Future<void> _savePeriodToFirebase() async {
    if (_saving || recentStartDate == null) return;

    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    final userId = args['userId'] as String?;
    final periodId = args['periodId'] as String?;

    if (userId == null || userId.isEmpty || periodId == null || periodId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('세션 정보가 없습니다. 처음부터 다시 시도해 주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('[DaysScreen] missing userId/periodId. args=$args');
      return;
    }

    setState(() => _saving = true);

    try {
      // periodId를 사용해서 해당 문서를 업데이트
      final updateData = <String, dynamic>{};
      
      // 종료일이 설정되었으면 추가
      if (selectedDate != recentStartDate) {
        updateData['endDate'] = Timestamp.fromDate(selectedDate);
      }
      
      // 피임약 정보가 설정되었으면 추가
      if (isOnMedication != null) {
        updateData['isOnMedication'] = isOnMedication;
      }
      
      // 업데이트할 데이터가 있으면 저장
      if (updateData.isNotEmpty) {
        await _service.updatePeriodData(periodId, updateData);
        debugPrint('[DaysScreen] Extra data saved for periodId=$periodId: $updateData');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('생리 정보가 저장되었습니다!'),
            backgroundColor: ColorTheme.subColor,
          ),
        );
        
        // 다음 화면으로 이동 (필요한 데이터 전달)
        Navigator.pushNamed(
          context,
          '/input_ble',
          arguments: {
            'userId': userId,
            'periodId': periodId,
            'recentStartDate': recentStartDate,
            ...args, // 기존 arguments도 함께 전달
          },
        );
      }

    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 실패: ${e.message ?? e.code}'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('[DaysScreen] FirebaseException: ${e.code} ${e.message}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('저장에 실패했습니다. 다시 시도해 주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('[DaysScreen] Unknown error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // 건너뛰기 처리
  void _onSkip() {
    if (_saving) return;
    
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    Navigator.pushNamed(
      context,
      '/input_ble',
      arguments: args, // 기존 arguments 그대로 전달
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    
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
            Text(
              '(선택) 추가 질문',
              style: TextStyle(
                fontSize: 14, 
                color: ColorTheme.subColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            SizedBox(height: 20),
            
            Text(
              '더 정확한 예측을\n위해 알려주세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: ColorTheme.textBlack,
              ),
            ),
            
            SizedBox(height: 40),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: ColorTheme.subColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    '최근 생리 종료일 (몰라도 괜찮아요)',
                    style: TextStyle(
                      fontSize: 14,
                      color: ColorTheme.textGray,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 15),
            
            if (recentStartDate != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 15),
                child: Text(
                  '생리 시작일(${formatKoreanDate(recentStartDate!)}) 이후 날짜만 선택 가능합니다.',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 12,
                    color: ColorTheme.subColor,
                  ),
                ),
              ),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ColorTheme.borderGray,
                  width: 0.2,
                ),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: recentStartDate != null ? _pickDateAdaptive : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        formatKoreanDate(selectedDate),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.w600,
                          color: recentStartDate != null ? Colors.black : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    recentStartDate != null ? '탭하여 날짜 변경' : '생리 시작일 정보가 필요합니다',
                    style: TextStyle(
                      fontSize: 12, 
                      color: recentStartDate != null ? ColorTheme.textLightGray : Colors.red[400],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 40),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: ColorTheme.subColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    '피임약이나 호르몬 치료 중인가요?',
                    style: TextStyle(
                      fontSize: 14,
                      color: ColorTheme.textGray,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: ChoiceButton<bool>(
                    value: true,
                    label: '네',
                    isSelected: isOnMedication == true,
                    onTap: () {
                      setState(() {
                        isOnMedication = (isOnMedication == true) ? null : true;
                      });
                    },
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: ChoiceButton<bool>(
                    value: false,
                    label: '아니오',
                    isSelected: isOnMedication == false,
                    onTap: () {
                      setState(() {
                        isOnMedication = (isOnMedication == false) ? null : false;
                      });
                    },
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 30),
            
            Spacer(),

            ConfirmButton(
              text: '다음',
              isEnabled: !_saving && recentStartDate != null,
              onPressed: _saving ? null : _savePeriodToFirebase,
            ),

            Center(
              child: TextButton(
                onPressed: _saving ? null : _onSkip,
                child: Text(
                  '건너뛰기',
                  style: TextStyle(
                    fontSize: 14, 
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}