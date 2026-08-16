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

// Rewritten: the previous version tried to compose the "f" from 3 separate
// RRects (hook + stem + crossbar) with hand-tuned overlapping coordinates,
// which produced a broken/misaligned glyph at render time. This version
// draws the Facebook "f" as a SINGLE continuous vector path (matching the
// real logomark's proportions), which renders correctly and consistently
// at any icon size.
class _FacebookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    // Circle background
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFF1877F2));

    // Single continuous "f" path, proportional to icon size.
    final stemW = w * 0.16;
    final stemLeft = w * 0.50;
    final stemRight = stemLeft + stemW;
    final crossbarY = h * 0.46;
    final crossbarH = h * 0.13;
    final stemBottom = h * 0.82;
    final hookTopY = h * 0.22;

    final path = Path()
      // Start at bottom-left of stem
      ..moveTo(stemLeft, stemBottom)
      // Up the left side of the stem to where the crossbar notch begins
      ..lineTo(stemLeft, crossbarY + crossbarH)
      // Left into the crossbar notch
      ..lineTo(w * 0.36, crossbarY + crossbarH)
      ..lineTo(w * 0.36, crossbarY)
      ..lineTo(stemLeft, crossbarY)
      // Up to where the rounded hook begins
      ..lineTo(stemLeft, hookTopY + stemW * 0.5)
      // Rounded hook at the top (curves up and over to the right)
      ..quadraticBezierTo(stemLeft, hookTopY, stemLeft + stemW * 0.5, hookTopY)
      ..lineTo(w * 0.66, hookTopY)
      ..lineTo(w * 0.66, hookTopY + stemW * 0.9)
      ..lineTo(stemRight, hookTopY + stemW * 0.9)
      // Down the right side of the stem to the crossbar
      ..lineTo(stemRight, crossbarY)
      // Right edge of crossbar
      ..lineTo(stemRight, crossbarY + crossbarH)
      // Down the right side of the stem to the bottom
      ..lineTo(stemRight, stemBottom)
      // Rounded bottom edge back to start
      ..quadraticBezierTo(stemRight, stemBottom + stemW * 0.3, stemLeft + stemW * 0.5, stemBottom + stemW * 0.3)
      ..quadraticBezierTo(stemLeft, stemBottom + stemW * 0.3, stemLeft, stemBottom)
      ..close();

    canvas.drawPath(path, Paint()..color = Colors.white..style = PaintingStyle.fill);
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