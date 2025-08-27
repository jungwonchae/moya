import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moya_app/themes/colortheme.dart';
import 'package:moya_app/widgets/confirm_button.dart';
import 'package:moya_app/widgets/choice_button.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moya_app/services/period_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

class InputPeriodExtraScreen extends StatefulWidget {
  @override
  _InputPeriodExtraScreenState createState() => _InputPeriodExtraScreenState();
}

class _InputPeriodExtraScreenState extends State<InputPeriodExtraScreen> {
  bool? isOnMedication;
  DateTime selectedDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime? recentStartDate;
  String? userId;
  
  final PeriodService _service = PeriodService();
  bool _saving = false;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    setState(() => userId = uid);

    if (uid == null) return; // 로그인 필요

    // 최근 시작일 Firestore에서 가져오기
    final latest = await _service.getLatestPeriod(uid); // 기대: { id, startDate, endDate, ... }
    final ts = latest?["startDate"];
    DateTime? start;
    if (ts is Timestamp) {
      start = ts.toDate();
    } else if (ts is DateTime) {
      start = ts;
    } else if (ts is String) {
      start = DateTime.tryParse(ts);
    }

    if (start != null) {
      if (!mounted) return; // 위젯 dispose된 뒤 setState 방지

      final startOnly = _dateOnly(start);
      final selectedOnly = _dateOnly(selectedDate);

      setState(() {
        recentStartDate = startOnly;
        // selectedDate가 recentStartDate 이전이면 보정 (날짜만 비교)
        if (selectedOnly.isBefore(startOnly)) {
          selectedDate = startOnly.add(const Duration(days: 1));
        }
      });
    } else {
      // Firestore에 startDate가 없을 때 안내
      debugPrint('InputPeriodExtraScreen> startDate not found for uid=$uid');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('최근 생리 시작일 정보를 불러오지 못했어요. 생리 시작일 입력 화면에서 먼저 시작일을 저장해 주세요.')),
        );
      }
    }
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
  if (_saving || recentStartDate == null || userId == null) return;

  setState(() => _saving = true);

  try {
    await PeriodService().upsertExtraByStartDate(
      userId: userId!,
      recentStartDate: recentStartDate!,
      selectedEndDate: selectedDate,
      isOnMedication: isOnMedication,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('생리 정보가 저장되었습니다!'),
        backgroundColor: ColorTheme.subColor,
      ),
    );
    // 저장 후 다음 화면으로 이동 (인자 전달 없이, 다음 화면에서 Firestore 재조회)
    if (mounted) {
      Navigator.pushNamed(context, '/input_ble');
    }

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('저장 실패: $e'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    if (mounted) setState(() => _saving = false);
  }
}
  
  @override
  Widget build(BuildContext context) {
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
              isEnabled: !_saving && recentStartDate != null && userId != null,
              onPressed: _saving ? () {} : _savePeriodToFirebase,
            ),

            Center(
              child: TextButton(
                onPressed: _saving
                    ? null
                    : () => Navigator.pushNamed(context, '/input_ble'),
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