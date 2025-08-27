import 'package:flutter/material.dart';

class WearableDeviceWidget extends StatelessWidget {
  /// 렌더링 크기
  final double width;
  final double height;

  /// 색상 커스터마이즈
  final Color strapColor;     // 밴드 색
  final Color bodyColor;      // 본체(캡슐) 바디 색
  final Color accentColor;    // LED/버튼 등 포인트 색

  /// 스타일 옵션
  final double tilt;          // 기기 기울기(라디안). 0이면 정면
  final double shadowStrength; // 바닥 그림자 강도(0~1)
  final bool withOutline;     // 외곽선 표시 여부

  const WearableDeviceWidget({
    super.key,
    this.width = 220,
    this.height = 260,
    this.strapColor = const Color(0xFFFDFDFD),
    this.bodyColor = const Color(0xFFEDEDED),
    this.accentColor = const Color(0xFF6AC4FF),
    this.tilt = -0.08,           // 살짝 왼쪽으로 기울여서 입체감
    this.shadowStrength = 0.35,
    this.withOutline = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _WearablePainter(
        strapColor: strapColor,
        bodyColor: bodyColor,
        accentColor: accentColor,
        tilt: tilt,
        shadowStrength: shadowStrength.clamp(0, 1),
        withOutline: withOutline,
      ),
    );
  }
}

class _WearablePainter extends CustomPainter {
  final Color strapColor;
  final Color bodyColor;
  final Color accentColor;
  final double tilt;
  final double shadowStrength;
  final bool withOutline;

  _WearablePainter({
    required this.strapColor,
    required this.bodyColor,
    required this.accentColor,
    required this.tilt,
    required this.shadowStrength,
    required this.withOutline,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 중앙 기준 회전(tilt)
    canvas.save();
    final center = Offset(size.width * 0.48, size.height * 0.48);
    canvas.translate(center.dx, center.dy);
    canvas.rotate(tilt);
    canvas.translate(-center.dx, -center.dy);

    // ===== 0) 바닥 그림자(타원) =====
    final shadowRect = Rect.fromCenter(
      center: Offset(size.width * 0.50, size.height * 0.88),
      width: size.width * 0.55,
      height: size.height * 0.10,
    );
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.18 * shadowStrength)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(shadowRect, shadowPaint);

    // ===== 1) 밴드 =====
    // 밴드를 두 겹 구조(내/외측)처럼 만들어 두께감 + 미세 하이라이트
    final bandPath = Path()
      ..moveTo(size.width * 0.25, size.height * 0.28)
      ..quadraticBezierTo(size.width * 0.07, size.height * 0.58,
          size.width * 0.27, size.height * 0.90)
      ..lineTo(size.width * 0.53, size.height * 0.90)
      ..quadraticBezierTo(size.width * 0.73, size.height * 0.58,
          size.width * 0.51, size.height * 0.28)
      ..close();

    // 밴드 베이스
    final bandBase = Paint()
      ..color = strapColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(bandPath, bandBase);

    // 밴드 그라디언트 하이라이트
    final bandGrad = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.85),
          strapColor.withOpacity(0.35),
        ],
      ).createShader(bandPath.getBounds());
    canvas.drawPath(bandPath, bandGrad);

    // 얇은 외곽선(옵션)
    if (withOutline) {
      final bandStroke = Paint()
        ..color = Colors.black.withOpacity(0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawPath(bandPath, bandStroke);
    }

    // 밴드 홈(디자인 포인트) — 살짝 안쪽 음영 라인
    final groove = Path()
      ..moveTo(size.width * 0.29, size.height * 0.36)
      ..quadraticBezierTo(size.width * 0.15, size.height * 0.60,
          size.width * 0.31, size.height * 0.84)
      ..moveTo(size.width * 0.49, size.height * 0.36)
      ..quadraticBezierTo(size.width * 0.63, size.height * 0.60,
          size.width * 0.47, size.height * 0.84);
    final groovePaint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(groove, groovePaint);

    // ===== 2) 본체(캡슐) =====
    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.40, size.height * 0.22),
        width: size.width * 0.50,
        height: size.height * 0.20,
      ),
      const Radius.circular(18),
    );

    // 본체 베이스
    final bodyBase = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(bodyRRect, bodyBase);

    // 본체 미세 하이라이트(유광 코팅 느낌)
    final bodySheen = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.95),
          Colors.white.withOpacity(0.15),
        ],
        stops: const [0.0, 0.85],
      ).createShader(bodyRRect.outerRect);
    canvas.drawRRect(bodyRRect, bodySheen);

    // 본체 하단 음영(살짝 둔탁함)
    final bodyShadow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.black.withOpacity(0.06),
        ],
      ).createShader(bodyRRect.outerRect);
    canvas.drawRRect(bodyRRect, bodyShadow);

    // 본체 외곽선(옵션)
    if (withOutline) {
      final bodyStroke = Paint()
        ..color = Colors.black.withOpacity(0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRRect(bodyRRect, bodyStroke);
    }

    // ===== 3) LED 인디케이터 & 홈 =====
    // LED
    final ledCenter =
        Offset(bodyRRect.center.dx + bodyRRect.width * 0.30, bodyRRect.center.dy);
    final ledOuter = Paint()..color = accentColor.withOpacity(0.25);
    final ledInner = Paint()..color = accentColor;
    canvas.drawCircle(ledCenter, 5.5, ledOuter);
    canvas.drawCircle(ledCenter, 3.0, ledInner);

    // 작은 홈(센서/마이크 구멍 느낌)
    final notchPaint = Paint()..color = Colors.black.withOpacity(0.12);
    canvas.drawCircle(
      Offset(bodyRRect.center.dx - bodyRRect.width * 0.32, bodyRRect.center.dy),
      1.6,
      notchPaint,
    );
    canvas.drawCircle(
      Offset(bodyRRect.center.dx - bodyRRect.width * 0.26, bodyRRect.center.dy),
      1.6,
      notchPaint,
    );

    // ===== 4) 유리 글로스(상단 사선 하이라이트 클립) =====
    final gloss = Path()
      ..addRRect(bodyRRect)
      ..close();
    canvas.save();
    canvas.clipPath(gloss);

    final glossBand = Path()
      ..moveTo(bodyRRect.left - 10, bodyRRect.top + 6)
      ..lineTo(bodyRRect.right + 20, bodyRRect.top - 10)
      ..lineTo(bodyRRect.right + 20, bodyRRect.top + 18)
      ..lineTo(bodyRRect.left - 10, bodyRRect.top + 34)
      ..close();

    final glossPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.55),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(glossBand.getBounds());
    canvas.drawPath(glossBand, glossPaint);
    canvas.restore();

    // 마무리
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WearablePainter old) {
    return strapColor != old.strapColor ||
        bodyColor != old.bodyColor ||
        accentColor != old.accentColor ||
        tilt != old.tilt ||
        shadowStrength != old.shadowStrength ||
        withOutline != old.withOutline;
  }
}