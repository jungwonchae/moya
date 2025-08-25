import 'package:flutter/material.dart';

class InputInfoNickScreen extends StatefulWidget {
  @override
  _InputInfoNickScreenState createState() => _InputInfoNickScreenState();
}

class _InputInfoNickScreenState extends State<InputInfoNickScreen> {
  TextEditingController nickController = TextEditingController();
  
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
              '별명 입력',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFFFF85B4),
                fontWeight: FontWeight.w500,
              ),
            ),
            
            SizedBox(height: 20),
            
            // 제목
            Text(
              '알림 시 별명을 입력해주세요',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            SizedBox(height: 40),
            
            // 예시 박스
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '예시 : "생리대 교체 시기입니다!"',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '모야 예요! 모야 모야\n교체 알림! 교체 하세요.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 30),
            
            // 입력 필드
            TextField(
              controller: nickController,
              decoration: InputDecoration(
                hintText: '직접 입력',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFFFF85B4)),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
            
            Spacer(),
            
            // 다음 버튼
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/input_recent'),
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