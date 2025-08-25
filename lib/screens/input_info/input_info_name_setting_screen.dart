import 'package:flutter/material.dart';
import 'package:moya_app/themes/colortheme.dart';

class InputInfoNameSettingScreen extends StatefulWidget {
  @override
  _InputInfoNameSettingScreenState createState() => _InputInfoNameSettingScreenState();
}

class _InputInfoNameSettingScreenState extends State<InputInfoNameSettingScreen> {
  TextEditingController nameController = TextEditingController(text: '민서');
  FocusNode nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 포커스가 없어질 때 자동 저장
    nameFocusNode.addListener(() {
      if (!nameFocusNode.hasFocus) {
        _saveName();
      }
    });
  }
  
  @override
  void dispose() {
    nameController.dispose();
    nameFocusNode.dispose();
    super.dispose();
  }

  void _saveName() {
    // 임시 이름 저장 로직 추후에 파베로 연결
    print('이름 저장됨: ${nameController.text}');
    
    // 저장 완료 피드백 (선택사항)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('이름이 저장되었습니다.'),
        backgroundColor: ColorTheme.subColor,
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
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
          icon: Icon(Icons.arrow_back, color: ColorTheme.subColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이름 섹션
            Text(
              '이름',
              style: TextStyle(
                fontSize: 18,
                color: ColorTheme.subColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            SizedBox(height: 8),
            
            // 이름 입력 필드
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameController,
                    focusNode: nameFocusNode, // 다른데 터치하면 자동 저장되도록
                    decoration: InputDecoration(
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: ColorTheme.textGray, width: 0.5),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: ColorTheme.subColor, width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.edit,
                  color: ColorTheme.iconGray,
                  size: 20,
                ),
              ],
            ),
            
            SizedBox(height: 40),
            
            // 가입일 섹션
            Text(
              '가입일',
              style: TextStyle(
                fontSize: 18,
                color: ColorTheme.subColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            SizedBox(height: 15),
            
            // 가입일 표시
            Text(
              '2025-08-10',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            
            Spacer(),

            // 로그아웃 버튼
            Center(
              child: TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: EdgeInsets.all(24),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.logout,
                            color: ColorTheme.subColor,
                            size: 48,
                          ),
                          SizedBox(height: 20),
                          Text(
                            '로그아웃',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: ColorTheme.textBlack,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            '정말 로그아웃 하시겠습니까?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: ColorTheme.textGray,
                            ),
                          ),
                          SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[100],
                                      foregroundColor: Colors.grey[600],
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      '취소',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.pushReplacementNamed(context, '/login');
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[400],
                                      foregroundColor: ColorTheme.background,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      '로그아웃',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Text(
                  '로그아웃',
                  style: TextStyle(
                    color: ColorTheme.subColor,
                    fontSize: 18,
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