import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moya_app/themes/colortheme.dart';
import 'package:moya_app/widgets/confirm_button.dart';
import 'package:moya_app/widgets/choice_button.dart';



class InputPeriodExtraScreen extends StatefulWidget {
  @override
  _InputPeriodExtraScreenState createState() => _InputPeriodExtraScreenState();
}

class _InputPeriodExtraScreenState extends State<InputPeriodExtraScreen> {
  bool? isOnMedication;
  TextEditingController endDateController = TextEditingController();
  DateTime selectedDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime? recentStartDate; // 추가: 이전 페이지에서 받아온 생리 시작일

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 이전 페이지에서 전달받은 데이터 가져오기
    final args = (ModalRoute.of(context)!.settings.arguments as Map?) ?? {};
    recentStartDate = args['recentStartDate'] as DateTime?;
    
    // 만약 selectedDate가 recentStartDate보다 이전이면 조정
    if (recentStartDate != null && selectedDate.isBefore(recentStartDate!)) {
      selectedDate = recentStartDate!.add(const Duration(days: 1)); // 시작일 다음날로 설정
    }
  }

  // 날짜 함수
  String formatKoreanDate(DateTime d) {
    return "${d.year}년 ${d.month}월 ${d.day}일";
  }
  
  // 플랫폼별 날짜 선택 (iOS: CupertinoDatePicker, Android: showDatePicker)
  Future<void> _pickDateAdaptive() async {
    if (recentStartDate == null) return; // 시작일이 없으면 선택 불가
    
    if (Platform.isIOS) {
      _showCupertinoDatePicker();
    } else {
      final picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: recentStartDate!, // 생리 시작일 이후만 선택 가능
        lastDate: DateTime(2035),
        helpText: '날짜 선택',
      );
      if (picked != null) setState(() => selectedDate = picked);
    } 
  }

  // ✅ iOS 스타일 모달 피커
  void _showCupertinoDatePicker() {
    if (recentStartDate == null) return; // 시작일이 없으면 선택 불가
    
    DateTime temp = selectedDate;
    final min = recentStartDate!; // 생리 시작일을 최소 날짜로 설정
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
              '(선택) 추가 질문',
              style: TextStyle(
                fontSize: 14, 
                color: ColorTheme.subColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            SizedBox(height: 20),
            
            // 제목
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
            
            // 최근 생리 종료일
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 점 (Circle)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: ColorTheme.subColor,
                    shape: BoxShape.circle,
                  ),
                ),

                // 텍스트
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
            
            // 안내 메시지 추가
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
            
            // 날짜 표시 + 탭하여 피커 열기
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
                    onTap: recentStartDate != null ? _pickDateAdaptive : null, // 시작일이 있을 때만 선택 가능
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
                          color: recentStartDate != null ? Colors.black : Colors.grey, // 비활성화 시 회색
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
            
            // 피임약/호르몬 치료 질문
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
            
            // 네/아니오 버튼 - ChoiceButton 사용
            Row(
              children: [
                Expanded(
                  child: ChoiceButton<bool>(
                    value: true,
                    label: '네',
                    isSelected: isOnMedication == true,
                    onTap: () {
                      setState(() {
                        // 이미 '네' 선택 상태라면 해제(null), 아니면 true로 선택
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
                        // 이미 '아니오' 선택 상태라면 해제(null), 아니면 false로 선택
                        isOnMedication = (isOnMedication == false) ? null : false;
                      });
                    },
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 30),
            
            Spacer(),

            // 다음 버튼
            ConfirmButton(
              text: '다음',
              isEnabled: true,
              onPressed: () {
                // 다음 페이지로 데이터 전달
                Navigator.pushNamed(
                  context, 
                  '/input_ble',
                  arguments: {
                    'recentStartDate': recentStartDate,
                    'selectedEndDate': selectedDate,
                    'isOnMedication': isOnMedication,
                  },
                );
              },
            ),
    
            // 건너뛰기 버튼
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/input_ble'),
                child: Text(
                  '건너뛰기',
                  style: TextStyle(
                    fontSize: 14,
                    color: ColorTheme.textGray,
                    //decoration: TextDecoration.underline,
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