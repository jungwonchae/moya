import 'package:flutter/material.dart';
import 'package:moya_app/themes/colortheme.dart';

class ConfirmButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isEnabled;

  const ConfirmButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled)) {
              return Colors.white;
            }
            return ColorTheme.subColor;
          }),
          foregroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled)) {
              return ColorTheme.subColor;
            }
            return Colors.white;
          }),
          side: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled)) {
              return BorderSide(color: ColorTheme.subColor, width: 0.5); // ✅ 테두리 두께 0.5
            }
            return const BorderSide(color: Colors.transparent, width: 0.5); // ✅ 일관성 있게 유지
          }),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50), // ✅ radius 50
            ),
          ),
          shadowColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled)) {
              return Colors.transparent;
            }
            return ColorTheme.shadow;
          }),
          elevation: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled)) return 0;
            return 6;
          }),
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}