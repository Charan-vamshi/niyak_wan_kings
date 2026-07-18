import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/arrow_model.dart';

class ArrowPainter extends CustomPainter {
  final List<ArrowModel> arrows;
  final bool isDark;
  final int rows;
  final int cols;
  static const double cellSize = 48.0;

  ArrowPainter({
    required this.arrows,
    required this.isDark,
    required this.rows,
    required this.cols,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final arrow in arrows) {
      if (arrow.state == ArrowState.extracted) continue;
      _drawArrow(canvas, arrow);
    }
  }

  void _drawArrow(Canvas canvas, ArrowModel arrow) {
    // 1. Build the full backbone path
    final path = Path();
    if (arrow.cells.isEmpty) return;

    // Start from tail (last element) to head (first element)
    final tail = arrow.cells.last;
    path.moveTo(_cellCenter(tail).dx, _cellCenter(tail).dy);

    for (int i = arrow.cells.length - 2; i >= 0; i--) {
      final pt = _cellCenter(arrow.cells[i]);
      path.lineTo(pt.dx, pt.dy);
    }

    // Extend the path far enough to fully exit the board
    // Max distance is roughly rows + cols
    final maxDist = (rows + cols + arrow.cells.length).toDouble();
    final headCenter = _cellCenter(arrow.head);
    Offset exitTarget = headCenter;
    
    switch (arrow.direction) {
      case ArrowDirection.up:    exitTarget += Offset(0, -maxDist * cellSize); break;
      case ArrowDirection.down:  exitTarget += Offset(0, maxDist * cellSize); break;
      case ArrowDirection.left:  exitTarget += Offset(-maxDist * cellSize, 0); break;
      case ArrowDirection.right: exitTarget += Offset(maxDist * cellSize, 0); break;
    }
    path.lineTo(exitTarget.dx, exitTarget.dy);

    // 2. Extract the segment based on animOffset
    // The snake's physical length is (cells.length - 1) * cellSize
    final double snakeLength = (arrow.cells.length - 1) * cellSize;
    
    // animOffset goes from 0.0 to 1.0 (or slightly higher/lower for wiggles)
    // When 0.0, the snake starts at distance 0 along the backbone.
    // When 1.0, it should be fully off screen.
    // We'll map animOffset=1.0 to a distance of maxDist * cellSize
    final double currentDistance = arrow.animOffset * maxDist * cellSize;
    
    final metrics = path.computeMetrics().first;
    
    double start = currentDistance;
    double end = start + snakeLength;
    
    // Ensure we don't extract past the backbone length
    if (end > metrics.length) end = metrics.length;
    if (start > metrics.length) start = metrics.length;
    
    final segment = metrics.extractPath(start, end);

    // Get position and angle for the head
    final headMetric = metrics.getTangentForOffset(end);
    if (headMetric == null) return;
    final headPos = headMetric.position;
    final headAngle = headMetric.vector.direction; // Radians

    // 3. Define colors (Minimalist pseudo-3D)
    Color baseColor;
    Color highlightColor;
    
    if (arrow.state == ArrowState.collided) {
      baseColor = const Color(0xFFD32F2F); // Dark Red
      highlightColor = const Color(0xFFEF5350); // Light Red
    } else {
      if (isDark) {
        baseColor = const Color(0xFF333333);
        highlightColor = const Color(0xFF555555);
      } else {
        baseColor = const Color(0xFF222222);
        highlightColor = const Color(0xFF444444);
      }
    }

    // Draw Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(50)
      ..strokeWidth = cellSize * 0.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(segment.shift(const Offset(2, 4)), shadowPaint);

    // Draw Base Pipe
    final basePaint = Paint()
      ..color = baseColor
      ..strokeWidth = cellSize * 0.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(segment, basePaint);

    // Draw Highlight (Pseudo-3D)
    final highlightPaint = Paint()
      ..color = highlightColor
      ..strokeWidth = cellSize * 0.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(segment, highlightPaint);

    // Draw Head
    _drawHead(canvas, headPos, headAngle, baseColor, highlightColor);
  }

  Offset _cellCenter(GridPosition cell) {
    return Offset(
      cell.col * cellSize + cellSize / 2,
      cell.row * cellSize + cellSize / 2,
    );
  }

  void _drawHead(Canvas canvas, Offset pos, double angle, Color base, Color highlight) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);

    const double s = 10.0;
    
    final path = Path();
    path.moveTo(s * 1.5, 0);
    path.lineTo(-s, -s * 1.2);
    path.lineTo(-s, s * 1.2);
    path.close();

    // Shadow
    canvas.drawPath(path.shift(const Offset(2, 4)), Paint()..color = Colors.black.withAlpha(50));
    
    // Base
    canvas.drawPath(path, Paint()..color = base..style = PaintingStyle.fill);
    
    // Highlight
    final innerPath = Path();
    innerPath.moveTo(s * 0.8, 0);
    innerPath.lineTo(-s * 0.5, -s * 0.6);
    innerPath.lineTo(-s * 0.5, s * 0.6);
    innerPath.close();
    canvas.drawPath(innerPath, Paint()..color = highlight..style = PaintingStyle.fill);

    canvas.restore();
  }

  @override
  bool shouldRepaint(ArrowPainter old) => true;
}