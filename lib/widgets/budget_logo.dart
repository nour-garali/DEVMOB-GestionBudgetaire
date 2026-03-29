import 'package:flutter/material.dart';
import 'dart:math' as math;

class BudgetLogo extends StatelessWidget {
  final double size;

  const BudgetLogo({
    super.key,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BudgetLogoPainter(),
      ),
    );
  }
}

class _BudgetLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // --- Gradients ---
    final coinGradient = LinearGradient(
      colors: [const Color(0xFF10B981), const Color(0xFF34D399)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final scaleGradient = LinearGradient(
      colors: [const Color(0xFF60A5FA), const Color(0xFF93C5FD)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // --- Background ---
    final bgPaint = Paint()
      ..color = const Color(0xFFF0FDF4).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.95, bgPaint);

    // --- Scale Stand ---
    final standPaint = Paint()..shader = scaleGradient;
    
    // Vertical stand
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.46, size.height * 0.56, size.width * 0.08, size.height * 0.25),
        const Radius.circular(3),
      ),
      standPaint,
    );
    
    // Base
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.375, size.height * 0.78, size.width * 0.25, size.height * 0.05),
        const Radius.circular(2),
      ),
      standPaint,
    );

    // --- Scale Beam ---
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.18, size.height * 0.52, size.width * 0.64, size.height * 0.05),
        const Radius.circular(2),
      ),
      standPaint,
    );

    // --- Left Pan ---
    final panPaint = Paint()
      ..shader = scaleGradient
      ..style = PaintingStyle.fill;
    
    // Left Triangle
    final leftPath = Path()
      ..moveTo(size.width * 0.25, size.height * 0.55)
      ..lineTo(size.width * 0.18, size.height * 0.65)
      ..lineTo(size.width * 0.32, size.height * 0.65)
      ..close();
    canvas.drawPath(leftPath, panPaint..color = const Color(0xFF60A5FA).withValues(alpha: 0.8));
    
    // Left Ellipse
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.25, size.height * 0.65),
        width: size.width * 0.2,
        height: size.height * 0.05,
      ),
      panPaint,
    );

    // --- Right Pan ---
    // Right Triangle
    final rightPath = Path()
      ..moveTo(size.width * 0.75, size.height * 0.55)
      ..lineTo(size.width * 0.68, size.height * 0.65)
      ..lineTo(size.width * 0.82, size.height * 0.65)
      ..close();
    canvas.drawPath(rightPath, panPaint..color = const Color(0xFF60A5FA).withValues(alpha: 0.8));
    
    // Right Ellipse
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.75, size.height * 0.65),
        width: size.width * 0.2,
        height: size.height * 0.05,
      ),
      panPaint,
    );

    // --- Coin on Right Pan ---
    final coinPaint = Paint()..shader = coinGradient;
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.6), size.width * 0.075, coinPaint);
    
    final innerCoinStroke = Paint()
      ..color = const Color(0xFFF0FDF4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.6), size.width * 0.05, innerCoinStroke);

    // Dollar sign
    final textPainter = TextPainter(
      text: TextSpan(
        text: '\$',
        style: TextStyle(
          color: Color(0xFFF0FDF4),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.width * 0.75 - textPainter.width / 2, size.height * 0.6 - textPainter.height / 2),
    );

    // --- Coins on Left ---
    canvas.drawCircle(Offset(size.width * 0.22, size.height * 0.6), size.width * 0.05, coinPaint..color = const Color(0xFF10B981).withValues(alpha: 0.9));
    canvas.drawCircle(Offset(size.width * 0.27, size.height * 0.6), size.width * 0.05, coinPaint);

    // --- Center Pivot ---
    final pivotPaint = Paint()..color = const Color(0xFF34D399);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.55), size.width * 0.05, pivotPaint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.55), size.width * 0.025, Paint()..color = const Color(0xFFF0FDF4));

    // --- Sparkles ---
    final sparklePaint = Paint();
    canvas.drawCircle(Offset(size.width * 0.31, size.height * 0.38), 2, sparklePaint..color = const Color(0xFF10B981).withValues(alpha: 0.6));
    canvas.drawCircle(Offset(size.width * 0.69, size.height * 0.4), 2, sparklePaint..color = const Color(0xFF60A5FA).withValues(alpha: 0.6));
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.31), 2.5, sparklePaint..color = const Color(0xFF34D399).withValues(alpha: 0.5));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
