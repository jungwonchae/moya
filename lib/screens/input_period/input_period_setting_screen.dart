import 'package:flutter/material.dart';
import 'package:moya_app/themes/colortheme.dart';

class InputPeriodSettingScreen extends StatefulWidget {
  @override
  _InputPeriodSettingScreenState createState() => _InputPeriodSettingScreenState();
}

class _InputPeriodSettingScreenState extends State<InputPeriodSettingScreen> {
  DateTime? recentStartDate = DateTime(2025, 8, 23);
  int cycleLength = 20;
  int periodDays = 5;
  DateTime? recentEndDate = DateTime(2025, 8, 28);
  bool isOnMedication = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFFFF85B4)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('생리 주기 정보가 저장되었습니다.'),
                  backgroundColor: Color(0xFFFF85B4),
                ),
              );
            },
            child: Text(
              '완료',
              style: TextStyle(
                color: Color(0xFFFF85B4),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목
            Text(
              '생리 주기 설정',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            SizedBox(height: 30),
            
            // 최근 시작일
            _buildSettingItem(
              '최근 시작일',
              recentStartDate != null 
                ? '${recentStartDate!.year}.${recentStartDate!.month.toString().padLeft(2, '0')}.${recentStartDate!.day.toString().padLeft(2, '0')}'
                : '날짜 선택',
              () => _selectStartDate(),
            ),
            
            SizedBox(height: 20),
            
            // 평균 주기 길이
            _buildSettingItem(
              '평균 주기 길이',
              '${cycleLength}일',
              () => _showCycleLengthDialog(),
            ),
            
            SizedBox(height: 20),
            
            // 생리 기간
            _buildSettingItem(
              '생리 기간',
              '${periodDays}일',
              () => _showPeriodDaysDialog(),
            ),
            
            SizedBox(height: 20),
            
            // 최근 생리 종료일 (선택사항)
            _buildSettingItem(
              '(선택) 추가 질문',
              '최근 생리 종료일',
              () => _selectEndDate(),
              subtitle: recentEndDate != null 
                ? '${recentEndDate!.year}.${recentEndDate!.month.toString().padLeft(2, '0')}.${recentEndDate!.day.toString().padLeft(2, '0')}'
                : null,
            ),
            
            SizedBox(height: 20),
            
            // 피임약/호르몬 치료
            _buildSettingItem(
              '피임약이나 호르몬 치료 여부',
              isOnMedication ? '네' : '아니오',
              () => _showMedicationDialog(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSettingItem(String title, String value, VoidCallback onTap, {String? subtitle}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: ColorTheme.subColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: ColorTheme.textGray,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
  
  void _selectStartDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: recentStartDate ?? DateTime.now().subtract(Duration(days: 7)),
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ColorTheme.subColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        recentStartDate = picked;
      });
    }
  }
  
  void _selectEndDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: recentEndDate ?? (recentStartDate?.add(Duration(days: periodDays)) ?? DateTime.now()),
      firstDate: recentStartDate ?? DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ColorTheme.subColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        recentEndDate = picked;
      });
    }
  }
  
  void _showCycleLengthDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('평균 주기 길이'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 3,
                children: [20, 25, 28, 30].map((days) {
                  bool isSelected = cycleLength == days;
                  return GestureDetector(
                    onTap: () => setDialogState(() => cycleLength = days),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? ColorTheme.subColor : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? ColorTheme.subColor : Colors.grey[300]!,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${days}일',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
            },
            child: Text('확인', style: TextStyle(color: ColorTheme.subColor,)),
          ),
        ],
      ),
    );
  }
  
  void _showPeriodDaysDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('생리 기간'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 3,
                children: [3, 4, 5, 6].map((days) {
                  bool isSelected = periodDays == days;
                  return GestureDetector(
                    onTap: () => setDialogState(() => periodDays = days),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Color(0xFFFF85B4) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Color(0xFFFF85B4) : Colors.grey[300]!,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${days}일',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
            },
            child: Text('확인', style: TextStyle(color: Color(0xFFFF85B4))),
          ),
        ],
      ),
    );
  }
  
  void _showMedicationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('피임약이나 호르몬 치료'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('네'),
              leading: Radio<bool>(
                value: true,
                groupValue: isOnMedication,
                onChanged: (value) {
                  setState(() {
                    isOnMedication = value!;
                  });
                  Navigator.pop(context);
                },
                activeColor: Color(0xFFFF85B4),
              ),
            ),
            ListTile(
              title: Text('아니오'),
              leading: Radio<bool>(
                value: false,
                groupValue: isOnMedication,
                onChanged: (value) {
                  setState(() {
                    isOnMedication = value!;
                  });
                  Navigator.pop(context);
                },
                activeColor: Color(0xFFFF85B4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}