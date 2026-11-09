import 'package:flutter/material.dart';

export 'table_circle_widget.dart';
export 'empty_state_widget.dart';

class VirtualCanvasBackgroundPainter extends CustomPainter {
  final bool isEditMode;

  VirtualCanvasBackgroundPainter({required this.isEditMode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isEditMode
          ? Colors.blue.withValues(alpha: 0.12)
          : Colors.grey.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;

    const double step = 80.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant VirtualCanvasBackgroundPainter oldDelegate) {
    return oldDelegate.isEditMode != isEditMode;
  }
}

class CropMaskPainter extends CustomPainter {
  final Rect cropRect;

  CropMaskPainter({required this.cropRect});

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(cropRect);

    final Paint maskPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, maskPaint);
  }

  @override
  bool shouldRepaint(covariant CropMaskPainter oldDelegate) {
    return oldDelegate.cropRect != cropRect;
  }
}