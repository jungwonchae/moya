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
    final borderRadius = BorderRadius.circular(50);

    return SizedBox(
      width: double.infinity,
      child: Container(
        // Figma Drop shadow: X 0, Y 3, Blur 4, Spread 0
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: ColorTheme.shadow.withOpacity(0.25),
                    offset: const Offset(0, 3),
                    blurRadius: 4,
                    spreadRadius: 0,
                  ),
                ]
              : const [],
        ),
        child: ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.disabled)) return Colors.white;
              return ColorTheme.subColor;
            }),
            foregroundColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.disabled)) return ColorTheme.subColor;
              return Colors.white;
            }),
            side: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.disabled)) {
                return BorderSide(color: ColorTheme.subColor, width: 0.5);
              }
              return const BorderSide(color: Colors.transparent, width: 0.5);
            }),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(borderRadius: borderRadius),
            ),

            // 버튼 자체 그림자는 끄기 (컨테이너 BoxShadow만 사용)
            elevation: MaterialStateProperty.all(0),
            shadowColor: MaterialStateProperty.all(Colors.transparent),

            // M3에서 색 틴트 올라오는 것 방지(있으면)
            surfaceTintColor: MaterialStateProperty.all(Colors.transparent),

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
      ),
    );
  }
}