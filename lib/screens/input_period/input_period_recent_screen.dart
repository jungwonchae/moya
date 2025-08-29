import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moya_app/themes/colortheme.dart';
import 'package:moya_app/widgets/confirm_button.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:moya_app/services/period_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

class InputPeriodRecentScreen extends StatefulWidget {
  @override
  _InputPeriodRecentScreenState createState() => _InputPeriodRecentScreenState();
}

class _InputPeriodRecentScreenState extends State<InputPeriodRecentScreen> {
  final PeriodService _service = PeriodService();
  bool _saving = false;
  bool _loading = true;

  DateTime selectedDate = DateTime.now().subtract(const Duration(days: 7));
  
  // 수정 모드인지 확인
  bool isEditMode = false;
  // 홈에서 온 간단 입력 모드인지 확인
  bool isQuickInputMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingData();
    });
  }

  Future<void> _loadExistingData() async {
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    
    print('[RecentScreen] Received arguments: $args');
    
    isEditMode = args['isEdit'] == true;
    isQuickInputMode = args['quickInput'] == true; // 홈에서 온 간단 입력 모드
    
    print('[RecentScreen] Mode - isEditMode: $isEditMode, isQuickInputMode: $isQuickInputMode');
    
    if (isEditMode || isQuickInputMode) {
      final periodId = args['periodId'] as String?;
      
      // periodId가 없으면 최신 period 찾기
      String? targetPeriodId = periodId;
      if (targetPeriodId == null || targetPeriodId.isEmpty) {
        final userId = args['userId'] as String?;
        if (userId != null) {
          final latestPeriod = await _service.getLatestPeriod(userId);
          targetPeriodId = latestPeriod?['periodId'] as String?;
          print('[RecentScreen] Found latest periodId: $targetPeriodId');
        }
      }
      
      if (targetPeriodId != null) {
        try {
          final data = await _service.getPeriodData(targetPeriodId);
          final existingDate = data['startDate'];
          DateTime? parsedDate;
          
          // Timestamp 처리
          if (existingDate is Timestamp) {
            parsedDate = existingDate.toDate();
          } else if (existingDate is DateTime) {
            parsedDate = existingDate;
          }
          
          if (parsedDate != null && mounted) {
            setState(() {
              selectedDate = parsedDate!;
            });
          }
          print('[RecentScreen] Loaded existing date: $parsedDate');
        } catch (e) {
          print('[RecentScreen] Error loading existing data: $e');
        }
      }
    }
    
    if (mounted) {
      setState(() => _loading = false);
    }
  }

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

  Future<void> _onNext() async {
    if (_saving) return;

    // 이전 화면에서 값 받기
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    final userId = args['userId'] as String?;
    final nick = args['nick'] as String?;
    String? periodId = args['periodId'] as String?;

    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 정보를 찾을 수 없어요.'), backgroundColor: Colors.red),
      );
      print('[RecentScreen] missing userId. args=$args');
      return;
    }

    setState(() => _saving = true);
    try {
      if (isQuickInputMode) {
        // 홈에서 온 간단 입력 모드: 최신 period를 찾아서 업데이트
        final latestPeriod = await _service.getLatestPeriod(userId);
        
        if (latestPeriod != null && latestPeriod['periodId'] != null) {
          // 기존 period가 있으면 생리 시작 정보 업데이트
          final existingPeriodId = latestPeriod['periodId'] as String;
          
          // 🆕 새로운 메서드 사용: 생리 시작일과 기간 정보 저장
          await _service.savePeriodStartInfo(
            periodId: existingPeriodId,
            startDate: selectedDate,
            periodLength: 5, // 기본 5일, 나중에 설정값으로 변경 가능
          );
          
          print('[RecentScreen] Updated period with detailed info: $existingPeriodId, startDate: $selectedDate');
        } else {
          // 기존 period가 없으면 새로 생성
          periodId = await _service.createDraftWithNick(
            userId: userId,
            nick: (nick ?? '알림'),
          );
          
          // 🆕 새로운 메서드 사용: 생리 시작일과 기간 정보 저장
          await _service.savePeriodStartInfo(
            periodId: periodId,
            startDate: selectedDate,
            periodLength: 5,
          );
          
          print('[RecentScreen] Created new period with detailed info: $periodId, startDate: $selectedDate');
        }

        // 홈으로 돌아가기
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('생리 시작이 기록되었습니다.'),
            backgroundColor: ColorTheme.mainColor,
          ),
        );
        
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (Route<dynamic> route) => false,
        );
        return;
      }
      
      if (periodId == null || periodId.isEmpty) {
        periodId = await _service.createDraftWithNick(
          userId: userId,
          nick: (nick ?? '알림'),
        );
        print('[RecentScreen] draft created: $periodId');
      }

      // 일반 모드에서도 새로운 메서드 사용
      if (isEditMode) {
        // 수정 모드면 기존 데이터 업데이트
        await _service.updatePeriodData(periodId, {
          'startDate': selectedDate,
        });
        // 기간 정보도 다시 생성
        await _service.savePeriodStartInfo(
          periodId: periodId,
          startDate: selectedDate,
          periodLength: 5,
        );
        Navigator.pop(context);
      } else {
        // 일반 모드면 기본 정보만 저장하고 다음 단계로
        await _service.updatePeriodData(periodId, {
          'startDate': selectedDate,
        });
        
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
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장 실패. 다시 시도해 주세요.'), backgroundColor: Colors.red),
      );
      print('[RecentScreen] error: $e');
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
            icon: const Icon(Icons.arrow_back, color: Colors.black),
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
              isQuickInputMode ? '생리가 시작되었나요?' : 
              (isEditMode ? '최근 생리 시작일을\n수정해주세요' : '최근 생리가\n시작된 날을 알려주세요'),
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
              isQuickInputMode ? '오늘 날짜로 설정하거나 다른 날짜를 선택해주세요' :
              (isEditMode ? '날짜를 다시 선택해주세요' : '마지막으로 생리가 시작된 날짜를 선택해주세요'),
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
              text: isQuickInputMode ? '저장' : (isEditMode ? '저장' : '다음'),
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