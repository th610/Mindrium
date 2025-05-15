// ✅ ocean_ui.dart — 바다 관련 UI 요소만 분리
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';

class OceanBubbles extends StatelessWidget {
  final int count;
  final Size screenSize;

  const OceanBubbles({super.key, required this.count, required this.screenSize});

  @override
  Widget build(BuildContext context) {
    final random = math.Random();
    return Stack(
      children: List.generate(count, (index) {
        return Positioned(
          left: random.nextDouble() * screenSize.width,
          top: random.nextDouble() * screenSize.height,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.white.withAlpha((0.3 * 255).toInt()),
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}

class OceanBackground extends StatelessWidget {
  const OceanBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.lightBlueAccent,
            Colors.lightBlue,
            Colors.blue,
            Colors.blueAccent,
            Colors.grey
          ],
        ),
      ),
    );
  }
}

class CoralReef extends StatelessWidget {
  final Size screenSize;
  const CoralReef({super.key, required this.screenSize});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: screenSize.width,
        height: 180,
        child: CustomPaint(painter: CoralReefPainter()),
      ),
    );
  }
}

class CoralReefPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final colors = [
      const Color(0x55006064),
      const Color(0x55004D40),
      const Color(0x55558B2F),
    ];

    for (int i = 0; i < 8; i++) {
      final x = size.width * (i / 7.0);
      final height = 60 + random.nextDouble() * 80;
      final width = 50 + random.nextDouble() * 40;
      final color = colors[random.nextInt(colors.length)];

      final path = Path();
      path.moveTo(x, size.height);
      path.lineTo(x - width / 2, size.height);
      path.quadraticBezierTo(x - width / 2, size.height - height * 0.7, x, size.height - height);
      path.quadraticBezierTo(x + width / 2, size.height - height * 0.7, x + width / 2, size.height);
      path.close();

      final shadowPaint = Paint()
        ..color = color.withAlpha((0.3 * 255).toInt())
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawPath(path, shadowPaint);

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, paint);

      for (int j = 0; j < 4; j++) {
        final decorX = x + (random.nextDouble() - 0.5) * width * 0.8;
        final decorY = size.height - random.nextDouble() * height * 0.7;
        final decorSize = 4 + random.nextDouble() * 8;

        canvas.drawCircle(Offset(decorX + 2, decorY + 2), decorSize,
            Paint()..color = color.withAlpha((0.3 * 255).toInt()));
        canvas.drawCircle(Offset(decorX, decorY), decorSize,
            Paint()..color = color.withAlpha((0.8 * 255).toInt()));
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class BubbleArrowPainter extends CustomPainter {
  final double arrowOffset;
  const BubbleArrowPainter({required this.arrowOffset});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha((0.1 * 255).toInt())
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final path = Path();
    final arrowX = size.width * arrowOffset;
    path.moveTo(arrowX - 10, 0);
    path.lineTo(arrowX, size.height);
    path.lineTo(arrowX + 10, 0);
    path.close();

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(BubbleArrowPainter oldDelegate) => arrowOffset != oldDelegate.arrowOffset;
}