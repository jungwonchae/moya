import 'package:flutter/material.dart';

class InputInfoNickSettingScreen extends StatefulWidget {
  @override
  _InputInfoNickSettingScreenState createState() => _InputInfoNickSettingScreenState();
}

class _InputInfoNickSettingScreenState extends State<InputInfoNickSettingScreen> {
  TextEditingController nickController = TextEditingController(text: '모야');
  
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
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 알림 별명 별명 섹션
            Text(
              '알림 시 별명',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFFFF85B4),
                fontWeight: FontWeight.w500,
              ),
            ),
            
            SizedBox(height: 8),
            
            Text(
              '고객 시 알림에만 사용',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            
            SizedBox(height: 20),
            
            // 별명 입력 필드
            Container(
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: nickController,
                      decoration: InputDecoration(
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(
                    Icons.edit,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 40),
            
            // 완료 버튼
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('별명이 저장되었습니다.'),
                      backgroundColor: Color(0xFFFF85B4),
                    ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF85B4),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '완료',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 15),
            
            // 취소 버튼
            Container(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                child: Text(
                  '취소',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            
            Spacer(),
          ],
        ),
      ),
    );
  }
}