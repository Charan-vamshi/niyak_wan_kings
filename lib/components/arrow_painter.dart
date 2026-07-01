import 'package:flutter/material.dart';
import '../core/arrow_model.dart';

class ArrowPainter extends CustomPainter {
  final List<ArrowModel> arrows;
  final bool isDark;
  static const double cellSize = 48.0;

  ArrowPainter({required this.arrows, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    for (final arrow in arrows) {
      if (arrow.state == ArrowState.extracted) continue;
      _drawArrow(canvas, arrow);
    }
  }

  void _drawArrow(Canvas canvas, ArrowModel arrow) {
    Color color;
    switch (arrow.state) {
      case ArrowState.idle:
        color = isDark ? const Color(0xFFBFC6FF) : const Color(0xFF3A3A8A);
        break;
      case ArrowState.moving:
        color = isDark ? Colors.white : Colors.black;
        break;
      case ArrowState.collided:
        color = Colors.red.shade400;
        break;
      case ArrowState.extracted:
        return;
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = cellSize * 0.13
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;

    final offset = _getOffset(arrow);

    final path = Path();
    final firstCenter = _cellCenter(arrow.cells[0], offset);
    path.moveTo(firstCenter.dx, firstCenter.dy);

    for (int i = 1; i < arrow.cells.length; i++) {
      final pt = _cellCenter(arrow.cells[i], offset);
      path.lineTo(pt.dx, pt.dy);
    }

    canvas.drawPath(path, paint);
    _drawHead(canvas, arrow, color, offset);
  }

  Offset _getOffset(ArrowModel arrow) {
    final step = arrow.animOffset;
    switch (arrow.direction) {
      case ArrowDirection.up:    return Offset(0, -step * cellSize);
      case ArrowDirection.down:  return Offset(0, step * cellSize);
      case ArrowDirection.left:  return Offset(-step * cellSize, 0);
      case ArrowDirection.right: return Offset(step * cellSize, 0);
    }
  }

  Offset _cellCenter(GridPosition cell, Offset offset) {
    return Offset(
      cell.col * cellSize + cellSize / 2 + offset.dx,
      cell.row * cellSize + cellSize / 2 + offset.dy,
    );
  }

  void _drawHead(Canvas canvas, ArrowModel arrow, Color color, Offset offset) {
    final head = _cellCenter(arrow.head, offset);
    const double s = 7.0;

    final fill = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path();

    switch (arrow.direction) {
      case ArrowDirection.up:
        path.moveTo(head.dx, head.dy - s * 1.6);
        path.lineTo(head.dx - s, head.dy);
        path.lineTo(head.dx + s, head.dy);
        break;
      case ArrowDirection.down:
        path.moveTo(head.dx, head.dy + s * 1.6);
        path.lineTo(head.dx - s, head.dy);
        path.lineTo(head.dx + s, head.dy);
        break;
      case ArrowDirection.left:
        path.moveTo(head.dx - s * 1.6, head.dy);
        path.lineTo(head.dx, head.dy - s);
        path.lineTo(head.dx, head.dy + s);
        break;
      case ArrowDirection.right:
        path.moveTo(head.dx + s * 1.6, head.dy);
        path.lineTo(head.dx, head.dy - s);
        path.lineTo(head.dx, head.dy + s);
        break;
    }

    path.close();
    canvas.drawPath(path, fill);
  }

  @override
  bool shouldRepaint(ArrowPainter old) => true;
}