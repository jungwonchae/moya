import 'package:flutter/material.dart';

class InputPeriodExtraScreen extends StatefulWidget {
  @override
  _InputPeriodExtraScreenState createState() => _InputPeriodExtraScreenState();
}

class _InputPeriodExtraScreenState extends State<InputPeriodExtraScreen> {
  bool? isOnMedication;
  TextEditingController endDateController = TextEditingController();
  
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
              '(선택) 추가 질문',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFFFF85B4), // 새로운 색상
                fontWeight: FontWeight.w500,
              ),
            ),
            
            SizedBox(height: 20),
            
            // 제목
            Text(
              '더 정확한 예측을\n위해 알려주세요',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                height: 1.3,
              ),
            ),
            
            SizedBox(height: 40),
            
            // 최근 생리 종료일
            Text(
              '최근 생리 종료일 (몰라도 괜찮아요)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            
            SizedBox(height: 15),
            
            TextField(
              controller: endDateController,
              decoration: InputDecoration(
                hintText: '직접 입력',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFFFF85B4)), // 새로운 색상
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              readOnly: true,
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().subtract(Duration(days: 5)),
                  firstDate: DateTime.now().subtract(Duration(days: 30)),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: Color(0xFFFF85B4), // 새로운 색상
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() {
                    endDateController.text = '${picked.year}.${picked.month.toString().padLeft(2, '0')}.${picked.day.toString().padLeft(2, '0')}';
                  });
                }
              },
            ),
            
            SizedBox(height: 40),
            
            // 피임약/호르몬 치료 질문
            Text(
              '피임약이나 호르몬 치료 중인가요?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            
            SizedBox(height: 20),
            
            // 네/아니오 버튼
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isOnMedication = true;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isOnMedication == true ? Color(0xFFFF85B4) : Colors.white, // 새로운 색상
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isOnMedication == true ? Color(0xFFFF85B4) : Colors.grey[300]!, // 새로운 색상
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '네',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isOnMedication == true ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isOnMedication = false;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isOnMedication == false ? Color(0xFFFF85B4) : Colors.white, // 새로운 색상
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isOnMedication == false ? Color(0xFFFF85B4) : Colors.grey[300]!, // 새로운 색상
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '아니오',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isOnMedication == false ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 30),
            
            // 건너뛰기 버튼
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/input_ble'),
                child: Text(
                  '건너뛰기',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            
            Spacer(),
            
            // 다음 버튼
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/input_ble'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF85B4), // 새로운 색상
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