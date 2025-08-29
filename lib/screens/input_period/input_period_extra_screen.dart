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
  bool _loading = true;
  
  // 수정 모드인지 확인
  bool isEditMode = false;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    setState(() => userId = uid);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) {
      _init();
    }
  }

  Future<void> _init() async {
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    isEditMode = args['isEdit'] == true;

    if (userId == null) return;

    if (isEditMode) {
      await _loadExistingData(args);
    } else {
      await _loadRecentStartDate(userId!);
    }
    
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadExistingData(Map args) async {
    final periodId = args['periodId'] as String?;
    final startDate = args['recentStartDate'] as DateTime?;
    
    if (startDate != null) {
      setState(() {
        recentStartDate = _dateOnly(startDate);
      });
    }
    
    if (periodId != null) {
      try {
        final data = await _service.getPeriodData(periodId);
        print('[ExtraScreen] Firebase data received: $data');
        
        // 종료일 정보 로드
        DateTime? existingEndDate;
        if (data['endDate'] != null) {
          final endDateValue = data['endDate'];
          if (endDateValue is Timestamp) {
            existingEndDate = endDateValue.toDate();
          } else if (endDateValue is DateTime) {
            existingEndDate = endDateValue;
          }
        }
        
        // extraData에서도 확인
        final extraData = data['extraData'] as Map<String, dynamic>?;
        if (extraData != null) {
          if (existingEndDate == null && extraData['endDate'] != null) {
            final endDateValue = extraData['endDate'];
            if (endDateValue is DateTime) {
              existingEndDate = endDateValue;
            }
          }
          
          // 피임약 정보 로드
          if (extraData['medication'] != null) {
            isOnMedication = extraData['medication'] as bool;
          }
        }
        
        // isOnMedication 필드에서도 확인
        if (isOnMedication == null && data['isOnMedication'] != null) {
          isOnMedication = data['isOnMedication'] as bool;
        }
        
        if (existingEndDate != null) {
          selectedDate = existingEndDate;
        } else if (recentStartDate != null) {
          // 종료일이 없으면 시작일(같은 날)로 설정
          selectedDate = recentStartDate!;
        }
        
        print('[ExtraScreen] Loaded - endDate: $existingEndDate, medication: $isOnMedication');
        
      } catch (e) {
        print('[ExtraScreen] Error loading existing data: $e');
      }
    }
  }

  Future<void> _loadRecentStartDate(String uid) async {
    // 최근 시작일 Firestore에서 가져오기
    final latest = await _service.getLatestPeriod(uid);
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
      if (!mounted) return;

      final startOnly = _dateOnly(start);
      final selectedOnly = _dateOnly(selectedDate);

      setState(() {
        recentStartDate = startOnly;
        if (selectedOnly.isBefore(startOnly)) {
          selectedDate = startOnly;
        }
      });
    } else {
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
    final minSelectableDate = recentStartDate!.subtract(const Duration(days: 120)); // 시작일 이전(최대 120일 전)도 허용
    if (Platform.isIOS) {
      _showCupertinoDatePicker();
    } else {
      final picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: minSelectableDate,
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
    final min = recentStartDate!.subtract(const Duration(days: 120)); // 시작일 이전도 허용
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
      if (isEditMode) {
        // 수정 모드일 때는 기존 periodId를 사용해서 업데이트
        final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
        final periodId = args['periodId'] as String?;
        
        if (periodId != null) {
          final updateData = <String, dynamic>{};
          
          // 종료일 저장
          updateData['endDate'] = Timestamp.fromDate(selectedDate);
          
          // 피임약 정보 저장
          if (isOnMedication != null) {
            updateData['isOnMedication'] = isOnMedication;
          }
          
          // extraData로도 저장 (호환성을 위해)
          Map<String, dynamic> extraData = {};
          extraData['endDate'] = selectedDate;
          
          if (isOnMedication != null) {
            extraData['medication'] = isOnMedication;
          }
          if (extraData.isNotEmpty) {
            updateData['extraData'] = extraData;
          }
          
          if (updateData.isNotEmpty) {
            await _service.updatePeriodData(periodId, updateData);
            print('[ExtraScreen] Data updated for periodId=$periodId: $updateData');
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('추가 정보가 저장되었습니다!'),
              backgroundColor: ColorTheme.subColor,
            ),
          );
          
          if (mounted) {
            Navigator.pop(context);
          }
        }
      } else {
        // 일반 모드일 때는 기존 방식 사용
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
        
        if (mounted) {
          Navigator.pushNamed(context, '/input_ble');
        }
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('[ExtraScreen] Save error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _onSkip() {
    if (isEditMode) {
      Navigator.pop(context);
    } else {
      Navigator.pushNamed(context, '/input_ble');
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
              isEditMode ? '추가 정보를\n수정해주세요' : '더 정확한 예측을\n위해 알려주세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: ColorTheme.textBlack,
                height: 1.3,
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
                    isEditMode ? '생리 종료일' : '최근 생리 종료일 (몰라도 괜찮아요)',
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
                  '생리 시작일(${formatKoreanDate(recentStartDate!)}) 이전 날짜도 선택할 수 있어요. (보통 이전 생리의 종료일을 선택해요)',
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
                    recentStartDate != null ? '탭하여 날짜 변경 (시작일 이전 날짜도 가능)' : '생리 시작일 정보가 필요합니다',
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
              text: isEditMode ? '저장' : '다음',
              isEnabled: !_saving && recentStartDate != null && userId != null,
              onPressed: _saving ? () {} : _savePeriodToFirebase,
            ),

            if (!isEditMode) // 수정 모드에서는 건너뛰기 버튼 숨김
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