import 'package:flutter/material.dart';

class InputInfoNameSettingScreen extends StatefulWidget {
  @override
  _InputInfoNameSettingScreenState createState() => _InputInfoNameSettingScreenState();
}

class _InputInfoNameSettingScreenState extends State<InputInfoNameSettingScreen> {
  TextEditingController nameController = TextEditingController(text: '민서');
  
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
              // 로그아웃 기능
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('로그아웃'),
                  content: Text('정말 로그아웃 하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('취소'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: Text('로그아웃', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            child: Text(
              '로그아웃',
              style: TextStyle(
                color: Color(0xFFFF85B4),
                fontSize: 14,
              ),
            ),
          ),
        ],
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
                fontSize: 14,
                color: Color(0xFFFF85B4),
                fontWeight: FontWeight.w500,
              ),
            ),
            
            SizedBox(height: 15),
            
            // 이름 입력 필드
            Container(
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: nameController,
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
                        fontSize: 16,
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
            
            // 가입일 섹션
            Text(
              '가입일',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFFFF85B4),
                fontWeight: FontWeight.w500,
              ),
            ),
            
            SizedBox(height: 15),
            
            // 가입일 표시
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                color: Colors.grey[50],
              ),
              child: Text(
                '2025-08-10',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
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