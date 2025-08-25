import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moya_app/themes/colortheme.dart';
import 'package:moya_app/widgets/confirm_button.dart';

class InputPeriodRecentScreen extends StatefulWidget {
  @override
  _InputPeriodRecentScreenState createState() => _InputPeriodRecentScreenState();
}

class _InputPeriodRecentScreenState extends State<InputPeriodRecentScreen> {
  DateTime selectedDate = DateTime.now().subtract(const Duration(days: 7));

  // 날짜 함수
  String formatKoreanDate(DateTime d) {
    return "${d.year}년 ${d.month}월 ${d.day}일";
  }
  // 플랫폼별 날짜 선택 (iOS: CupertinoDatePicker, Android: showDatePicker)
  Future<void> _pickDateAdaptive() async {
    if (Platform.isIOS) {
      _showCupertinoDatePicker();
    } else {
      final picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2010),
        lastDate: DateTime(2035),
        helpText: '날짜 선택',
      );
      if (picked != null) setState(() => selectedDate = picked);
    } 
  }

  // ✅ iOS 스타일 모달 피커
  void _showCupertinoDatePicker() {
  DateTime temp = selectedDate;
  final min = DateTime.now().subtract(const Duration(days: 365 * 10));
  final max = DateTime.now().add(const Duration(days: 365));

  showCupertinoModalPopup(
    context: context,
    builder: (context) {
      return CupertinoTheme(
        data: CupertinoThemeData(
          brightness: Brightness.light,
          primaryColor: ColorTheme.subColor, // 취소/완료 텍스트 색
        ),
        child: CupertinoPopupSurface( // iOS 모달 표면 느낌
          isSurfacePainted: true,
          child: Container(
            height: 320,
            color: CupertinoColors.systemBackground,
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  // 상단 액션 바 (iOS 스타일: 텍스트 버튼)
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

                  // 휠 피커
                  Expanded(
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: selectedDate,
                      minimumDate: min,
                      maximumDate: max,
                      // 원하면 순서 고정
                      // dateOrder: DatePickerDateOrder.ymd,
                      onDateTimeChanged: (d) => temp = d,
                      // 배경 고정 (다크/라이트에 영향받지 않게)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '최근 시작일',
              style: TextStyle(
                fontSize: 14,
                color: ColorTheme.subColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '최근 생리가\n시작된 날을 알려주세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: ColorTheme.textBlack,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '마지막으로 생리가 시작된 날짜를 선택해주세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: ColorTheme.textGray,
              ),
            ),
            const SizedBox(height: 40),

            // 날짜 표시 + 탭하여 피커 열기
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:ColorTheme.borderGray,
                  width: 0.2,
                ),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickDateAdaptive,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        // color: const Color(0xFFF2F3F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        formatKoreanDate(selectedDate),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '탭하여 날짜 변경',
                    style: TextStyle(fontSize: 12, color: ColorTheme.textLightGray),
                  ),
                ],
              ),
            ),

            const Spacer(),

            ConfirmButton(
              text: '다음',
              isEnabled: true,
              onPressed: () => Navigator.pushNamed(
                  context, '/input_cycle',
                  arguments: {
                    'recentStartDate' : selectedDate,
                  }
                ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}