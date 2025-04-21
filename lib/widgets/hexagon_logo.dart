import 'package:flutter/material.dart';

class HexagonLogo extends StatelessWidget {
  const HexagonLogo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '3D Cube Logo',
      child: CustomPaint(
        painter: CubePainter(),
        size: const Size(60, 60),
      ),
    );
  }
}

class CubePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    // Define the top face path
    final Path topFacePath = Path();
    topFacePath.moveTo(centerX, centerY - 30); // Top center
    topFacePath.lineTo(centerX - 30, centerY - 15); // Top-left
    topFacePath.lineTo(centerX, centerY); // Bottom center
    topFacePath.lineTo(centerX + 30, centerY - 15); // Top-right
    topFacePath.close();

    // Define the left face path
    final Path leftFacePath = Path();
    leftFacePath.moveTo(centerX - 30, centerY - 15); // Top-left
    leftFacePath.lineTo(centerX - 30, centerY + 15); // Bottom-left
    leftFacePath.lineTo(centerX, centerY + 30); // Bottom center
    leftFacePath.lineTo(centerX, centerY); // Top center
    leftFacePath.close();

    // Define the right face path
    final Path rightFacePath = Path();
    rightFacePath.moveTo(centerX, centerY); // Top center
    rightFacePath.lineTo(centerX + 30, centerY - 15); // Top-right
    rightFacePath.lineTo(centerX + 30, centerY + 15); // Bottom-right
    rightFacePath.lineTo(centerX, centerY + 30); // Bottom center
    rightFacePath.close();

    // Create gradients
    final Gradient topGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF3B1BA8),
        const Color(0xFF4F2BC4),
      ],
    );

    final Gradient leftGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF3215A0),
        const Color(0xFF251175),
      ],
    );

    final Gradient rightGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF251175),
        const Color(0xFF1A0C54),
      ],
    );

    // Draw top face with gradient
    final Paint topPaint = Paint()
      ..shader = topGradient.createShader(
        Rect.fromPoints(
          Offset(centerX - 30, centerY - 15),
          Offset(centerX + 30, centerY),
        ),
      )
      ..style = PaintingStyle.fill;
    canvas.drawPath(topFacePath, topPaint);

    // Draw left face with gradient
    final Paint leftPaint = Paint()
      ..shader = leftGradient.createShader(
        Rect.fromPoints(
          Offset(centerX - 30, centerY - 15),
          Offset(centerX, centerY + 30),
        ),
      )
      ..style = PaintingStyle.fill;
    canvas.drawPath(leftFacePath, leftPaint);

    // Draw right face with gradient
    final Paint rightPaint = Paint()
      ..shader = rightGradient.createShader(
        Rect.fromPoints(
          Offset(centerX, centerY),
          Offset(centerX + 30, centerY + 15),
        ),
      )
      ..style = PaintingStyle.fill;
    canvas.drawPath(rightFacePath, rightPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
