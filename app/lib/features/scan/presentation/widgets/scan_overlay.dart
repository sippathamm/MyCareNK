import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Side length of the square scan window, shared between the camera's
/// [MobileScanner.scanWindow] and the overlay cut-out so they stay aligned.
const double kScanFrameSize = 240;

/// Dimmed full-screen overlay with a transparent square cut-out and primary
/// corner brackets marking the scan window.
class ScannerOverlay extends StatelessWidget {
  const ScannerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OverlayPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  static const double _cornerLength = 28;
  static const double _cornerRadius = 8;
  static const double _cornerStroke = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2 - 40;

    final Rect frame = Rect.fromCenter(
      center: Offset(cx, cy),
      width: kScanFrameSize,
      height: kScanFrameSize,
    );

    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(frame, const Radius.circular(_cornerRadius)),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      overlayPath,
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );

    final cornerPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = _cornerStroke
      ..strokeCap = StrokeCap.round;

    _drawCorners(canvas, frame, cornerPaint);
  }

  void _drawCorners(Canvas canvas, Rect frame, Paint paint) {
    final l = _cornerLength;
    final r = _cornerRadius;
    final left = frame.left;
    final top = frame.top;
    final right = frame.right;
    final bottom = frame.bottom;

    canvas.drawPath(
      Path()
        ..moveTo(left + r, top)
        ..lineTo(left + l, top)
        ..moveTo(left, top + r)
        ..lineTo(left, top + l),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(right - l, top)
        ..lineTo(right - r, top)
        ..moveTo(right, top + r)
        ..lineTo(right, top + l),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(left, bottom - l)
        ..lineTo(left, bottom - r)
        ..moveTo(left + r, bottom)
        ..lineTo(left + l, bottom),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(right, bottom - l)
        ..lineTo(right, bottom - r)
        ..moveTo(right - l, bottom)
        ..lineTo(right - r, bottom),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
