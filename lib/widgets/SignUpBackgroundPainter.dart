import 'package:flutter/material.dart';

class SignUpBackgroundPainter extends CustomPainter {
  final Color mainWaveColor;
  final Color circleColor;
  final Color lightColor;

  SignUpBackgroundPainter({
    required this.mainWaveColor,
    required this.circleColor,
    required this.lightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient for the entire canvas
    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        colors: [mainWaveColor.withOpacity(0.5), lightColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    // Large main blue wavy shape on the top left
    final mainWavePath = Path();
    mainWavePath.moveTo(0, 0);
    mainWavePath.lineTo(0, size.height * 0.4);
    mainWavePath.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.5,
      size.width,
      size.height * 0.2,
    );
    mainWavePath.lineTo(size.width, 0);
    mainWavePath.close();

    final mainWavePaint = Paint()
      ..shader = LinearGradient(
        colors: [mainWaveColor, circleColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(mainWavePath, mainWavePaint);

    // First rounded shape on the right
    final roundedShape1Path = Path();
    roundedShape1Path.moveTo(size.width * 0.6, 0);
    roundedShape1Path.cubicTo(
      size.width * 0.9,
      size.height * 0.1,
      size.width * 0.9,
      size.height * 0.3,
      size.width * 0.7,
      size.height * 0.4,
    );
    roundedShape1Path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.35,
      size.width * 0.6,
      0,
    );
    roundedShape1Path.close();

    final roundedShape1Paint = Paint()
      ..shader = LinearGradient(
        colors: [lightColor, lightColor.withOpacity(0.5)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(roundedShape1Path, roundedShape1Paint);

    // Second rounded shape on the left, overlapping the main wave
    final roundedShape2Path = Path();
    roundedShape2Path.moveTo(size.width * 0.1, size.height * 0.1);
    roundedShape2Path.cubicTo(
      size.width * 0.3,
      size.height * 0.2,
      size.width * 0.2,
      size.height * 0.4,
      size.width * 0.1,
      size.height * 0.3,
    );
    roundedShape2Path.close();

    final roundedShape2Paint = Paint()
      ..shader = LinearGradient(
        colors: [mainWaveColor, circleColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(roundedShape2Path, roundedShape2Paint);

    // Third rounded shape at the bottom-right
    final roundedShape3Path = Path();
    roundedShape3Path.addOval(
      Rect.fromCircle(
        center: Offset(size.width * 0.7, size.height * 0.3),
        radius: size.width * 0.08,
      ),
    );

    final roundedShape3Paint = Paint()
      ..shader = LinearGradient(
        colors: [lightColor, lightColor.withOpacity(0.5)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(roundedShape3Path, roundedShape3Paint);

    // The larger blue circle on the left
    final circle1Paint = Paint()
      ..shader =
          LinearGradient(
            colors: [mainWaveColor, circleColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.1, size.height * 0.15),
              radius: size.width * 0.1,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.15),
      size.width * 0.1,
      circle1Paint,
    );

    // The white circle near the center
    final circle2Paint = Paint()
      ..shader =
          LinearGradient(
            colors: [lightColor.withOpacity(0.5), lightColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.65, size.height * 0.25),
              radius: size.width * 0.05,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.65, size.height * 0.25),
      size.width * 0.05,
      circle2Paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

