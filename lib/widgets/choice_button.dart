import 'package:flutter/material.dart';
import 'package:moya_app/themes/colortheme.dart';

class ChoiceButton<T> extends StatelessWidget {
  final T value;                      // 실제 선택 값 (String/int 등)
  final String label;                 // 화면에 보여줄 라벨
  final bool isSelected;
  final VoidCallback onTap;

  const ChoiceButton({
    Key? key,
    required this.value,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? ColorTheme.subColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? ColorTheme.subColor : ColorTheme.mainColor!,
          ),
          // 드롭섀도 추가:
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withOpacity(0.15), offset: const Offset(0,3), blurRadius: 4)]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: isSelected ? Colors.white : ColorTheme.textGray,
            ),
          ),
        ),
      ),
    );
  }
}