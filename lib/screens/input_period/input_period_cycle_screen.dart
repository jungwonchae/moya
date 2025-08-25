import 'package:flutter/material.dart';

class InputPeriodCycleScreen extends StatefulWidget {
  @override
  _InputPeriodCycleScreenState createState() => _InputPeriodCycleScreenState();
}

class _InputPeriodCycleScreenState extends State<InputPeriodCycleScreen> {
  int selectedCycle = 28;
  
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
              '평균 주기 길이',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFFE91E63),
                fontWeight: FontWeight.w500,
              ),
            ),
            
            SizedBox(height: 20),
            
            // 제목
            Text(
              '보통 생리 주기는 며칠인가요?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            SizedBox(height: 8),
            
            // 부제목
            Text(
              '한 번 시작일부터 다음 시작일까지 걸리는 일수',
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
                  child: _buildCycleButton(20),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: _buildCycleButton(25),
                ),
              ],
            ),
            
            SizedBox(height: 15),
            
            Row(
              children: [
                Expanded(
                  child: _buildCycleButton(28),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: _buildCycleButton(30),
                ),
              ],
            ),
            
            SizedBox(height: 15),
            
            // 직접 입력
            Container(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // 직접 입력 다이얼로그
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
                onPressed: () => Navigator.pushNamed(context, '/input_days'),
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
  
  Widget _buildCycleButton(int days) {
    bool isSelected = selectedCycle == days;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCycle = days;
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
                  selectedCycle = int.parse(controller.text);
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