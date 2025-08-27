import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moya_app/themes/colortheme.dart';
import 'package:moya_app/widgets/confirm_button.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:moya_app/services/period_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp, FirebaseException;

class InputPeriodRecentScreen extends StatefulWidget {
  @override
  _InputPeriodRecentScreenState createState() => _InputPeriodRecentScreenState();
}

class _InputPeriodRecentScreenState extends State<InputPeriodRecentScreen> {
  final _service = PeriodService();
  bool _saving = false;

  DateTime selectedDate = DateTime.now().subtract(const Duration(days: 7));

  // 날짜 함수
  String formatKoreanDate(DateTime d) {
    return "${d.year}년 ${d.month}월 ${d.day}일";
  }

  // 플랫폼별 날짜 선택 (iOS: CupertinoDatePicker, Android: 커스텀 모달)
  Future<void> _pickDateAdaptive() async {
    if (Platform.isIOS) {
      _showCupertinoDatePicker();
    } else {
      _showMaterialDatePicker();
    } 
  }

  // Android용 예쁜 모달 날짜 선택기
  void _showMaterialDatePicker() {
    DateTime tempDate = selectedDate;
    final min = DateTime.now().subtract(const Duration(days: 365 * 10));
    final max = DateTime.now().add(const Duration(days: 365));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // 상단 헤더
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      
                    ),
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            '취소',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '날짜 선택',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: ColorTheme.textBlack,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() => selectedDate = tempDate);
                            Navigator.pop(context);
                          },
                          child: Text(
                            '완료',
                            style: TextStyle(
                              color: ColorTheme.subColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 선택된 날짜 표시
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: ColorTheme.subColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ColorTheme.subColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      formatKoreanDate(tempDate),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: ColorTheme.subColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 날짜 선택기
                  Expanded(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: ColorTheme.mainColor, // 오늘 날짜
                          onPrimary: ColorTheme.subColor,
                          surface: Colors.white,
                          onSurface: ColorTheme.textBlack,
                        ),
                      ),
                      child: CalendarDatePicker(
                        initialDate: tempDate,
                        firstDate: min,
                        lastDate: max,
                        onDateChanged: (date) {
                          setModalState(() {
                            tempDate = date;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // iOS 스타일 모달 피커
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

  // ✅ Firebase에 시작일 저장
  Future<void> _onNext() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final userId   = (args?['userId'] as String?) ?? '';
    String? periodId = args?['periodId'] as String?;
    final nick     = args?['nick'] as String?;

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 정보를 찾을 수 없어요.'), backgroundColor: Colors.red),
      );
      debugPrint('[RecentScreen] missing userId. args=$args');
      return;
    }

    setState(() => _saving = true);
    try {
      if (periodId == null || periodId.isEmpty) {
        // 드래프트가 없으면 새로 생성
        periodId = await _service.createDraftWithNick(
          userId: userId,
          nick: (nick ?? '알림'),
        );
        debugPrint('[RecentScreen] draft created: $periodId');
      }

      // ✅ Firestore에 startDate 저장
      await _service.updatePeriodData(periodId, {
        'startDate': Timestamp.fromDate(selectedDate),
      });
      debugPrint('[RecentScreen] startDate saved: $selectedDate');

      // 다음 화면으로 이동
      Navigator.pushNamed(
        context,
        '/input_cycle',
        arguments: {
          'userId': userId,
          'periodId': periodId,
          'nick': nick,
          'recentStartDate': selectedDate,
        },
      );
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: ${e.message ?? e.code}'), backgroundColor: Colors.red),
      );
      debugPrint('[RecentScreen] FirebaseException: ${e.code} ${e.message}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장에 실패했습니다. 다시 시도해 주세요.'), backgroundColor: Colors.red),
      );
      debugPrint('[RecentScreen] Unknown error: $e');
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

            // 날짜 표시
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
                    onTap: _pickDateAdaptive,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
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
              isEnabled: !_saving,
              onPressed: _saving ? null : _onNext,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}