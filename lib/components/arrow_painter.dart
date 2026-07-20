import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/arrow_model.dart';

class ArrowPainter extends CustomPainter {
  final List<ArrowModel> arrows;
  final bool isDark;
  final int rows;
  final int cols;
  final bool showGuideLines;
  static const double cellSize = 48.0;

  ArrowPainter({
    required this.arrows,
    required this.isDark,
    required this.rows,
    required this.cols,
    this.showGuideLines = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 0. Draw Guide Lines (Tangents) if enabled
    if (showGuideLines) {
      final normalLinePaint = Paint()
        ..color = isDark ? const Color(0xFF333333) : const Color(0xFFD0D0D0)
        ..strokeWidth = cellSize * 0.15
        ..style = PaintingStyle.stroke;

      final stuckLinePaint = Paint()
        ..color = const Color(0xFFD32F2F) // Red for stuck lasers
        ..strokeWidth = cellSize * 0.15
        ..style = PaintingStyle.stroke;
        
      for (final arrow in arrows) {
        if (arrow.state == ArrowState.extracted) continue;
        
        final headCenter = _cellCenter(arrow.head);
        Offset target = headCenter;
        
        switch (arrow.direction) {
          case ArrowDirection.up:    target = Offset(headCenter.dx, -10000); break;
          case ArrowDirection.down:  target = Offset(headCenter.dx, 10000); break;
          case ArrowDirection.left:  target = Offset(-10000, headCenter.dy); break;
          case ArrowDirection.right: target = Offset(10000, headCenter.dy); break;
        }
        
        // Draw the laser line from the head to the edge of the board
        canvas.drawLine(headCenter, target, arrow.isStuck ? stuckLinePaint : normalLinePaint);
      }
    }

    // 1. Draw background dot grid
    final dotPaint = Paint()
      ..color = isDark ? Colors.white24 : Colors.black26
      ..style = PaintingStyle.fill;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final center = _cellCenter(GridPosition(r, c));
        canvas.drawCircle(center, 1.5, dotPaint); // Small dot
      }
    }

    // 2. Draw all arrows
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
    final tailCenter = _cellCenter(tail);
    
    final double tailExtDist = cellSize * 0.35; // Stop short of the cell boundary to leave a gap

    Offset tailExtension = Offset.zero;
    if (arrow.cells.length == 1) {
      switch (arrow.direction) {
        case ArrowDirection.up:    tailExtension = Offset(0, tailExtDist); break;
        case ArrowDirection.down:  tailExtension = Offset(0, -tailExtDist); break;
        case ArrowDirection.left:  tailExtension = Offset(tailExtDist, 0); break;
        case ArrowDirection.right: tailExtension = Offset(-tailExtDist, 0); break;
      }
    } else {
      final prev = _cellCenter(arrow.cells[arrow.cells.length - 2]);
      final dirVec = tailCenter - prev; 
      // dirVec has length cellSize. We want length tailExtDist.
      tailExtension = Offset(
        (dirVec.dx / cellSize) * tailExtDist,
        (dirVec.dy / cellSize) * tailExtDist,
      );
    }
    
    final extendedTail = tailCenter + tailExtension;
    path.moveTo(extendedTail.dx, extendedTail.dy);

    for (int i = arrow.cells.length - 1; i >= 0; i--) {
      final pt = _cellCenter(arrow.cells[i]);
      path.lineTo(pt.dx, pt.dy);
    }

    // Extend the path far enough to fully exit the board
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
    // The snake's physical length now includes the tail extension (tailExtDist)
    final double snakeLength = (arrow.cells.length - 1) * cellSize + tailExtDist;
    final double currentDistance = arrow.animOffset * maxDist * cellSize;
    
    final metrics = path.computeMetrics().first;
    double start = currentDistance;
    double end = start + snakeLength;
    
    if (end > metrics.length) end = metrics.length;
    if (start > metrics.length) start = metrics.length;
    
    final segment = metrics.extractPath(start, end);

    // Get position for the head (which will be exactly at the tip of the extracted segment)
    final headMetric = metrics.getTangentForOffset(end);
    if (headMetric == null) return;
    final headPos = headMetric.position;
    
    double headAngle = 0;
    switch (arrow.direction) {
      case ArrowDirection.up: headAngle = -pi / 2; break;
      case ArrowDirection.down: headAngle = pi / 2; break;
      case ArrowDirection.left: headAngle = pi; break;
      case ArrowDirection.right: headAngle = 0; break;
    }

    // 3. Define colors (Thin solid styling)
    Color baseColor;
    
    if (arrow.state == ArrowState.collided || arrow.isStuck) {
      baseColor = const Color(0xFFD32F2F); // Red for collision or stuck
    } else {
      baseColor = isDark ? Colors.white : Colors.black;
    }

    // Very thin solid line for the body
    final basePaint = Paint()
      ..color = baseColor
      ..strokeWidth = cellSize * 0.15 // Thin solid line
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square // Square caps to connect cleanly
      ..strokeJoin = StrokeJoin.miter;
      
    canvas.drawPath(segment, basePaint);

    // Draw Head
    _drawHead(canvas, headPos, headAngle, baseColor);
  }

  Offset _cellCenter(GridPosition cell) {
    return Offset(
      cell.col * cellSize + cellSize / 2,
      cell.row * cellSize + cellSize / 2,
    );
  }

  void _drawHead(Canvas canvas, Offset pos, double angle, Color baseColor) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);

    const double s = 6.0; // Small, sharp head
    
    // Solid triangle head
    final path = Path();
    path.moveTo(s * 1.5, 0); // Tip
    path.lineTo(-s, -s * 1.2); // Top base
    path.lineTo(-s, s * 1.2); // Bottom base
    path.close();

    // Fill the head solidly with the base color
    canvas.drawPath(path, Paint()..color = baseColor..style = PaintingStyle.fill);

    canvas.restore();
  }

  @override
  bool shouldRepaint(ArrowPainter old) => true;
}