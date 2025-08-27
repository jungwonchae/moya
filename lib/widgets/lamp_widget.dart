import 'dart:math' as math;
import 'package:flutter/material.dart';

class LampWidget extends StatefulWidget {
  final double width;
  final double height;
  final Duration blinkPeriod;
  final double minIntensity;
  final double maxIntensity;
  final bool randomizeFlicker;

  const LampWidget({
    super.key,
    this.width = 140,
    this.height = 190,
    this.blinkPeriod = const Duration(seconds: 2),
    this.minIntensity = 0.65,
    this.maxIntensity = 1.0,
    this.randomizeFlicker = true,
  });

  @override
  State<LampWidget> createState() => _LampWidgetState();
}

class _LampWidgetState extends State<LampWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.blinkPeriod)
      ..repeat(reverse: true);

    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        double t = _anim.value;

        if (widget.randomizeFlicker) {
          final noise = 0.05 * math.sin(2 * math.pi * (t + 0.19)) +
              0.03 * math.cos(2 * math.pi * (t * 1.7 + 0.41));
          t = (t + noise).clamp(0.0, 1.0);
        }

        final intensity =
            _lerp(widget.minIntensity, widget.maxIntensity, t);

        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _EggTeardropLampPainter(intensity: intensity),
        );
      },
    );
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;
}

class _EggTeardropLampPainter extends CustomPainter {
  final double intensity; // 0~1

  _EggTeardropLampPainter({required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    // ===== 받침대(2단) =====
    // 바닥 그림자(은은)
    final floorGlow = Paint()
      ..color = Colors.black.withOpacity(0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, size.height * 0.92),
        width: size.width * 0.9,
        height: size.height * 0.16,
      ),
      floorGlow,
    );

    final baseTopY = size.height * 0.86;
    final basePaint = Paint()..color = Colors.grey.shade300;

    // 윗원판(얇은 링 느낌)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, baseTopY),
        width: size.width * 0.62,
        height: size.height * 0.11,
      ),
      basePaint,
    );

    // 아래 원판
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, size.height * 0.90),
        width: size.width * 0.70,
        height: size.height * 0.12,
      ),
      basePaint,
    );

    // ===== 물방울(계란형) =====
    // 형상 포인트:
    // - top: 더 뾰족 (0.06H)
    // - belly: 0.60H 부근이 가장 넓음
    // - bottom: 0.80H에서 살짝 납작(받침과 맞닿도록)
    final topY = size.height * 0.06;
    final bellyY = size.height * 0.80;
    final bottomY = size.height * 0.78; // 살짝 위에서 끝내 받침에 얹히는 느낌
    final widest = size.width * 0.78;   // 배 둘레 폭

    final tear = Path()
      ..moveTo(cx, topY)
      // 오른쪽으로 내려오며 부풀림
      ..cubicTo(
        cx + widest * 0.40, size.height * 0.22, // 상단 오른쪽 컨트롤
        cx + widest * 0.48, bellyY,             // 중간 오른쪽 컨트롤
        cx, bottomY,                            // 하단
      )
      // 왼쪽으로 올라가며 대칭 (완전 대칭은 아니고 약간 달리해 자연스러움)
      ..cubicTo(
        cx - widest * 0.48, bellyY,             // 중간 왼쪽 컨트롤
        cx - widest * 0.40, size.height * 0.22, // 상단 왼쪽 컨트롤
        cx, topY,                                // 상단
      )
      ..close();

    final bulbRect = tear.getBounds();

    // 내부 라디얼 그라디언트(중심 밝기 ↑)
    final gradientCenter = Offset(cx, _lerp(bulbRect.top, bulbRect.center.dy, 0.35));
    final fill = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          ((gradientCenter.dx - bulbRect.center.dx) / (bulbRect.width / 2))
              .clamp(-1, 1),
          ((gradientCenter.dy - bulbRect.center.dy) / (bulbRect.height / 2))
              .clamp(-1, 1),
        ),
        radius: 0.90,
        colors: [
          Colors.white.withOpacity(0.97 * intensity),
          Colors.amber.shade100.withOpacity(0.85 * intensity),
          Colors.amber.shade200.withOpacity(0.55 * intensity),
          Colors.amber.shade200.withOpacity(0.00),
        ],
        stops: const [0.0, 0.35, 0.72, 1.0],
      ).createShader(bulbRect);
    canvas.drawPath(tear, fill);

    // 외곽 글로우(램프 전체 주변)
    final glowPaint = Paint()
      ..color = Colors.amberAccent.withOpacity(_lerp(0.12, 0.28, intensity))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(
      Offset(cx, size.height * 0.40),
      size.width * _lerp(0.55, 0.70, intensity),
      glowPaint,
    );

    // 상단 유리 하이라이트(부드러운 사선 띠)
    final highlight = Path()
      ..moveTo(bulbRect.left + 8, bulbRect.top + 16)
      ..quadraticBezierTo(
          bulbRect.center.dx, bulbRect.top + 4, bulbRect.right - 8, bulbRect.top + 18)
      ..lineTo(bulbRect.right - 8, bulbRect.top + 28)
      ..quadraticBezierTo(
          bulbRect.center.dx, bulbRect.top + 12, bulbRect.left + 8, bulbRect.top + 24)
      ..close();

    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.35 * intensity),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(highlight.getBounds());

    canvas.save();
    canvas.clipPath(tear);
    canvas.drawPath(highlight, highlightPaint);
    canvas.restore();

    // 아주 얇은 외곽선
    final stroke = Paint()
      ..color = Colors.black.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(tear, stroke);
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(covariant _EggTeardropLampPainter old) {
    return intensity != old.intensity;
  }
}