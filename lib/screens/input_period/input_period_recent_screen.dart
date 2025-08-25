import 'package:flutter/material.dart';

class InputPeriodRecentScreen extends StatefulWidget {
  @override
  _InputPeriodRecentScreenState createState() => _InputPeriodRecentScreenState();
}

class _InputPeriodRecentScreenState extends State<InputPeriodRecentScreen> {
  DateTime selectedDate = DateTime.now().subtract(Duration(days: 7));
  
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 단계 표시
            Text(
              '최근 시작일',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFFFF85B4),
                fontWeight: FontWeight.w500,
              ),
            ),
            
            SizedBox(height: 20),
            
            // 제목
            Text(
              '최근 생리가\n시작된 날을 알려주세요',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                height: 1.3,
              ),
            ),
            
            SizedBox(height: 8),
            
            // 부제목
            Text(
              '마지막으로 생리가 시작된 날짜를 선택해주세요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            
            SizedBox(height: 40),
            
            // 날짜 선택 영역
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  // 연도/월 표시
                  Text(
                    '2024년 8월 16일',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // 간단한 달력 UI
                  Container(
                    height: 200,
                    child: GridView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: 31,
                      itemBuilder: (context, index) {
                        int day = index + 1;
                        bool isSelected = day == 16;
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedDate = DateTime(2024, 8, day);
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? Color(0xFFFF85B4) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            Spacer(),
            
            // 다음 버튼
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/input_cycle'),  // 주기로
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF85B4),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '다음',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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