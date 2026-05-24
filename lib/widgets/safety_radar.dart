import 'dart:math';
import 'package:flutter/material.dart';
import 'package:suraksha_women_safety_app/theme/app_theme.dart';

class SafetyRadar extends StatefulWidget {
  const SafetyRadar({super.key});

  @override
  State<SafetyRadar> createState() => _SafetyRadarState();
}

class _SafetyRadarState extends State<SafetyRadar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(200, 200),
          painter: RadarPainter(_controller.value),
        );
      },
    );
  }
}

class RadarPainter extends CustomPainter {
  final double angle;
  RadarPainter(this.angle);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);

    final bgPaint = Paint()
      ..color = AppTheme.primaryColor.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw concentric circles
    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, radius * (i / 4), bgPaint);
    }

    // Draw the scanning sweep
    final sweepShader = SweepGradient(
      colors: [
        Colors.transparent,
        AppTheme.primaryColor.withOpacity(0.5),
      ],
      stops: const [0.75, 1.0],
      transform: GradientRotation(angle * 2 * pi),
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    final sweepPaint = Paint()..shader = sweepShader;

    canvas.drawCircle(center, radius, sweepPaint);

    // Draw some "detected" points
    final random = Random(42);
    for (int i = 0; i < 5; i++) {
      final pAngle = random.nextDouble() * 2 * pi;
      final pRadius = random.nextDouble() * radius;
      final pointOffset = Offset(
        center.dx + pRadius * cos(pAngle),
        center.dy + pRadius * sin(pAngle),
      );
      
      final sweepAngle = (angle * 2 * pi) % (2 * pi);
      final diff = (sweepAngle - pAngle).abs();
      if (diff < 0.5) {
        final pointPaint = Paint()..color = Colors.greenAccent.withOpacity(1 - diff * 2);
        canvas.drawCircle(pointOffset, 4, pointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(RadarPainter oldDelegate) => true;
}
