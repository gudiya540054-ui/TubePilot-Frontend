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

// Rewritten AGAIN: the previous version tried to build the "f" as one
// FILLED outline by manually stitching together the outer/inner edges of
// the stem, crossbar notch, and hook as a single sequence of line/curve
// points. Getting every one of those edges to line up pixel-perfectly by
// hand is extremely error-prone — a single wrong coordinate anywhere in
// that chain produces a lopsided notch or misaligned joint, which is
// exactly the "broken f" that kept showing up.
//
// This version sidesteps that entirely: instead of drawing a filled
// outline, it draws the "f" the way you'd actually write it — as a
// STROKED path along the letter's skeleton (stem + hook as one continuous
// path, crossbar as a second short stroke), using round caps/joins so the
// strokes blend into each other cleanly with zero manual alignment. This
// is far more robust and matches the real wordmark's proportions.
class _FacebookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    // Circle background
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFF1877F2));

    final strokeWidth = w * 0.15;
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Stem + top hook as ONE continuous path — the curve into the hook is
    // a natural extension of the stem line, so there's no seam/joint to
    // misalign in the first place.
    final stemAndHook = Path()
      ..moveTo(w * 0.54, h * 0.80)
      ..lineTo(w * 0.54, h * 0.30)
      ..quadraticBezierTo(w * 0.54, h * 0.20, w * 0.64, h * 0.20)
      ..lineTo(w * 0.70, h * 0.20);
    canvas.drawPath(stemAndHook, strokePaint);

    // Crossbar — a short horizontal stroke through the stem, just below
    // its midpoint (matches the real Facebook wordmark's proportions).
    final crossbar = Path()
      ..moveTo(w * 0.40, h * 0.52)
      ..lineTo(w * 0.62, h * 0.52);
    canvas.drawPath(crossbar, strokePaint);
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