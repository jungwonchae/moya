import 'package:flutter/material.dart';

class InputPeriodDaysScreen extends StatefulWidget {
  @override
  _InputPeriodDaysScreenState createState() => _InputPeriodDaysScreenState();
}

class _InputPeriodDaysScreenState extends State<InputPeriodDaysScreen> {
  int selectedDays = 5;
  
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
              '생리 기간',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFFFF85B4),
                fontWeight: FontWeight.w500,
              ),
            ),
            
            SizedBox(height: 20),
            
            // 제목
            Text(
              '생리는 보통\n며칠 동안 지속되나요?',
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
              '평균 며칠간 출혈이 지속되는지 알려주세요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            
            SizedBox(height: 60),
            
            // 선택 버튼들
            Row(
              children: [
                Expanded(
                  child: _buildDaysButton(3),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: _buildDaysButton(4),
                ),
              ],
            ),
            
            SizedBox(height: 15),
            
            Row(
              children: [
                Expanded(
                  child: _buildDaysButton(5),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: _buildDaysButton(6),
                ),
              ],
            ),
            
            SizedBox(height: 15),
            
            // 직접 입력
            Container(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  _showCustomInputDialog();
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                child: Text(
                  '직접 입력',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            
            Spacer(),
            
            // 다음 버튼
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/input_extra'),
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
  
  Widget _buildDaysButton(int days) {
    bool isSelected = selectedDays == days;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDays = days;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFFF85B4) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFFFF85B4) : Colors.grey[300]!,
          ),
        ),
        child: Center(
          child: Text(
            '${days}일',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
  
  void _showCustomInputDialog() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('직접 입력'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '일수를 입력하세요',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  selectedDays = int.parse(controller.text);
                });
              }
              Navigator.pop(context);
            },
            child: Text('확인'),
          ),
        ],
      ),
    );
  }
}