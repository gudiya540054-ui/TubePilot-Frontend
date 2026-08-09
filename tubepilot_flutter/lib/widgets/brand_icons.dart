import 'package:flutter/material.dart';

/// Real brand icons (drawn with CustomPainter, no external asset/package
/// dependency needed) — used everywhere we previously used emoji (📺 📘 📁)
/// for platform logos, so YouTube / Facebook / Drive always render as their
/// actual brand mark instead of a generic emoji glyph.

class YoutubeIcon extends StatelessWidget {
  final double size;
  const YoutubeIcon({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _YoutubePainter()),
    );
  }
}

class _YoutubePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, h * 0.14, w, h * 0.72),
      Radius.circular(h * 0.22),
    );
    final bgPaint = Paint()..color = const Color(0xFFFF0000);
    canvas.drawRRect(rrect, bgPaint);

    final playPath = Path()
      ..moveTo(w * 0.40, h * 0.32)
      ..lineTo(w * 0.40, h * 0.68)
      ..lineTo(w * 0.68, h * 0.50)
      ..close();
    canvas.drawPath(playPath, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FacebookIcon extends StatelessWidget {
  final double size;
  const FacebookIcon({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _FacebookPainter()),
    );
  }
}

class _FacebookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w / 2;

    // Background circle — clipped so nothing (including the F) can ever
    // paint outside it, which is what caused the previous version to look
    // cut off / misaligned inside its container.
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromLTWH(0, 0, w, h)));
    canvas.drawCircle(Offset(r, r), r, Paint()..color = const Color(0xFF1877F2));

    // Simple, well-centered lowercase "f" — stem + one flag, sized as a
    // fraction of the circle so it scales cleanly at any icon size.
    final stemWidth = w * 0.16;
    final stemLeft = w * 0.46;
    final stemTop = h * 0.28;
    final stemBottom = h * 0.82;

    final path = Path()
      // Vertical stem.
      ..addRect(Rect.fromLTRB(stemLeft, stemTop, stemLeft + stemWidth, stemBottom))
      // Top hook curving right, like the top of an "f".
      ..addRRect(RRect.fromRectAndCorners(
        Rect.fromLTRB(stemLeft, h * 0.16, w * 0.68, stemTop + h * 0.02),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      ))
      // Horizontal crossbar.
      ..addRect(Rect.fromLTRB(w * 0.32, h * 0.46, w * 0.68, h * 0.46 + h * 0.12));

    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DriveIcon extends StatelessWidget {
  final double size;
  const DriveIcon({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _DrivePainter()),
    );
  }
}

class _DrivePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Left triangle (yellow) — top-left arm of the Drive logomark.
    final left = Path()
      ..moveTo(w * 0.32, h * 0.06)
      ..lineTo(w * 0.02, h * 0.58)
      ..lineTo(w * 0.22, h * 0.94)
      ..lineTo(w * 0.52, h * 0.42)
      ..close();
    canvas.drawPath(left, Paint()..color = const Color(0xFFFFC107));

    // Right triangle (green).
    final right = Path()
      ..moveTo(w * 0.68, h * 0.06)
      ..lineTo(w * 0.98, h * 0.58)
      ..lineTo(w * 0.78, h * 0.94)
      ..lineTo(w * 0.48, h * 0.42)
      ..close();
    canvas.drawPath(right, Paint()..color = const Color(0xFF4CAF50));

    // Bottom triangle (blue).
    final bottom = Path()
      ..moveTo(w * 0.22, h * 0.94)
      ..lineTo(w * 0.78, h * 0.94)
      ..lineTo(w * 0.63, h * 0.68)
      ..lineTo(w * 0.37, h * 0.68)
      ..close();
    canvas.drawPath(bottom, Paint()..color = const Color(0xFF2196F3));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}