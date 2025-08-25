import 'package:flutter/material.dart';
import 'package:moya_app/themes/colortheme.dart';  // mainColor 가져오기
import 'package:moya_app/widgets/confirm_button.dart';
import 'package:moya_app/widgets/choice_button.dart';


class InputInfoNickScreen extends StatefulWidget {
  @override
  _InputInfoNickScreenState createState() => _InputInfoNickScreenState();
}

class _InputInfoNickScreenState extends State<InputInfoNickScreen> {
  TextEditingController nickController = TextEditingController();

  final List<String> nickPresets = ["모야예요!", "교체하세요.", "모야모야?!", "교체 알림!"];
  
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
              '별명 입력',
              style: TextStyle(
                fontSize: 14,
                color: ColorTheme.subColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            SizedBox(height: 20),
            
            // 제목
            Text(
              '알림에 표시될 문구를 정해주세요',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: ColorTheme.textBlack,
              ),
            ),
            
            SizedBox(height: 8),
            
            // 부제목
            Text(
              '예시: "생리대 교체 시기입니다."',
              style: TextStyle(
                fontSize: 14,
                color: ColorTheme.textGray,
              ),
            ),
            
            SizedBox(height: 40),
            
            // 선택 버튼들
            // 선택 상태는 nickController.text 로 판정
            Row(
              children: [
                Expanded(
                  child: ChoiceButton<String>(
                    value: nickPresets[0],
                    label: nickPresets[0],
                    isSelected: nickController.text.trim() == nickPresets[0],
                    onTap: () => setState(() => nickController.text = nickPresets[0]),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ChoiceButton<String>(
                    value: nickPresets[1],
                    label: nickPresets[1],
                    isSelected: nickController.text.trim() == nickPresets[1],
                    onTap: () => setState(() => nickController.text = nickPresets[1]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: ChoiceButton<String>(
                    value: nickPresets[2],
                    label: nickPresets[2],
                    isSelected: nickController.text.trim() == nickPresets[2],
                    onTap: () => setState(() => nickController.text = nickPresets[2]),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ChoiceButton<String>(
                    value: nickPresets[3],
                    label: nickPresets[3],
                    isSelected: nickController.text.trim() == nickPresets[3],
                    onTap: () => setState(() => nickController.text = nickPresets[3]),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 15),
            
            // 입력 필드
            TextField(
              controller: nickController,
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
            

            // 밑줄(입력) 아래 텍스트
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '직접 입력',
                style: TextStyle(
                  fontSize: 14,
                  color: ColorTheme.textLightGray,
                ),
              ),
            ),

            Spacer(),
            
            // 다음 버튼
            ConfirmButton(
              text: '다음',
              isEnabled: nickController.text.trim().isNotEmpty,
              onPressed: () => Navigator.pushNamed(context, '/input_recent'),
            ),
            
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}