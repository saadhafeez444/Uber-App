import 'package:flutter/material.dart';

class LoginBackgroundPainter extends CustomPainter {
  final Color mainWaveColor;
  final Color circleColor;
  final Color lightColor;

  LoginBackgroundPainter({
    required this.mainWaveColor,
    required this.circleColor,
    required this.lightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {

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

  
    final mainWavePath = Path();
    mainWavePath.moveTo(0, size.height * 0.2);
    mainWavePath.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.5,
      size.width,
      size.height * 0.4,
    );
    mainWavePath.lineTo(size.width, size.height);
    mainWavePath.lineTo(0, size.height);
    mainWavePath.close();

    final mainWavePaint = Paint()
      ..shader = LinearGradient(
        colors: [mainWaveColor, circleColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(mainWavePath, mainWavePaint);

    final roundedShape1Path = Path();
    roundedShape1Path.moveTo(size.width * 0.4, 0);
    roundedShape1Path.cubicTo(
      size.width * 0.7,
      size.height * 0.1,
      size.width * 0.7,
      size.height * 0.3,
      size.width * 0.5,
      size.height * 0.4,
    );
    roundedShape1Path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.35,
      size.width * 0.4,
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

    final circle1Paint = Paint()
      ..shader =
          LinearGradient(
            colors: [mainWaveColor, circleColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.9, size.height * 0.15),
              radius: size.width * 0.1,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.15),
      size.width * 0.1,
      circle1Paint,
    );

 
    final circle2Paint = Paint()
      ..shader =
          LinearGradient(
            colors: [lightColor.withOpacity(0.5), lightColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.35, size.height * 0.25),
              radius: size.width * 0.05,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.35, size.height * 0.25),
      size.width * 0.05,
      circle2Paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}



