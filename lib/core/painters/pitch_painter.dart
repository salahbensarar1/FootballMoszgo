import 'package:flutter/material.dart';

class PitchLinePainter extends CustomPainter {
  final Color lineColor;

  PitchLinePainter({this.lineColor = const Color(0x08EEE9DF)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Diagonal lines pattern
    const spacing = 60.0;
    for (double i = -size.height; i < size.width + size.height;
         i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }

    // Center circle suggestion
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.height * 0.3,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}