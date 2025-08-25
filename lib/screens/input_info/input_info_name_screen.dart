import 'package:flutter/material.dart';
import 'package:moya_app/themes/colortheme.dart';  // mainColor 가져오기

class InputInfoNameScreen extends StatefulWidget {
  @override
  _InputInfoNameScreenState createState() => _InputInfoNameScreenState();
}

class _InputInfoNameScreenState extends State<InputInfoNameScreen> {
  TextEditingController nameController = TextEditingController();
  
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
              '이름 입력',
              style: TextStyle(
                fontSize: 14,
                color: ColorTheme.subColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            SizedBox(height: 20),
            
            // 제목
            Text(
              '이름을 입력해주세요',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: ColorTheme.textBlack,
              ),
            ),
            
            SizedBox(height: 8),
            
            // 부제목
            Text(
              '별명을 입력해도 돼요!',
              style: TextStyle(
                fontSize: 14,
                color: ColorTheme.textGray,
              ),
            ),
            
            SizedBox(height: 40),
            
            // 입력 필드
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: ColorTheme.mainColor, width: 2),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: ColorTheme.subColor, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),

            SizedBox(height: 8),
            

            // 밑줄 아래 예시 텍스트
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'ex) 홍길동',
                style: TextStyle(
                  fontSize: 14,
                  color: ColorTheme.textLightGray,
                ),
              ),
            ),

            Spacer(),
            
            // 다음 버튼
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: nameController.text.isNotEmpty 
                  ? () => Navigator.pushNamed(context, '/input_nick')
                  : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: nameController.text.isNotEmpty 
                    ? ColorTheme.subColor
                    : Colors.white,
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
                    color: Color(0xFFFF85B4),
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