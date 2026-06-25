import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../core/arrow_model.dart';

class ArrowTile extends PositionComponent with TapCallbacks {
  static const double cellSize = 40.0;

  ArrowModel model;
  final Function(ArrowModel) onTapped;
  final bool isDark;

  ArrowTile({
    required this.model,
    required this.onTapped,
    required this.isDark,
  }) {
    size = Vector2.zero(); // no fixed size, we draw manually
    position = Vector2.zero();
  }

  void updateModel(ArrowModel newModel) {
    model = newModel;
  }

  Color get _pathColor {
    switch (model.state) {
      case ArrowState.idle:
        return isDark
            ? const Color(0xFFBFC6FF)
            : const Color(0xFF3A3A6A);
      case ArrowState.moving:
        return isDark
            ? const Color(0xFFDDDDDD)
            : const Color(0xFF888888);
      case ArrowState.collided:
        return Colors.red.shade400;
      case ArrowState.extracted:
        return Colors.transparent;
    }
  }

  // Convert grid position to canvas offset accounting for movement offset
  Offset _cellCenter(GridPosition cell) {
    final col = cell.col + model.offsetCol;
    final row = cell.row + model.offsetRow;
    return Offset(
      col * cellSize + cellSize / 2,
      row * cellSize + cellSize / 2,
    );
  }

  @override
  void render(Canvas canvas) {
    if (model.state == ArrowState.extracted) return;
    if (model.cells.isEmpty) return;

    final color = _pathColor;
    final paint = Paint()
      ..color = color
      ..strokeWidth = cellSize * 0.12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;

    // draw the path
    final path = Path();
    final first = _cellCenter(model.cells.first);
    path.moveTo(first.dx, first.dy);

    for (int i = 1; i < model.cells.length; i++) {
      final pt = _cellCenter(model.cells[i]);
      path.lineTo(pt.dx, pt.dy);
    }

    canvas.drawPath(path, paint);

    // draw arrowhead at head
    _drawArrowhead(canvas, color);
  }

  void _drawArrowhead(Canvas canvas, Color color) {
    final head = _cellCenter(model.head);
    const double headSize = 5.0;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final arrowPath = Path();

    switch (model.direction) {
      case ArrowDirection.up:
        arrowPath.moveTo(head.dx, head.dy - headSize * 1.5);
        arrowPath.lineTo(head.dx - headSize, head.dy);
        arrowPath.lineTo(head.dx + headSize, head.dy);
        break;
      case ArrowDirection.down:
        arrowPath.moveTo(head.dx, head.dy + headSize * 1.5);
        arrowPath.lineTo(head.dx - headSize, head.dy);
        arrowPath.lineTo(head.dx + headSize, head.dy);
        break;
      case ArrowDirection.left:
        arrowPath.moveTo(head.dx - headSize * 1.5, head.dy);
        arrowPath.lineTo(head.dx, head.dy - headSize);
        arrowPath.lineTo(head.dx, head.dy + headSize);
        break;
      case ArrowDirection.right:
        arrowPath.moveTo(head.dx + headSize * 1.5, head.dy);
        arrowPath.lineTo(head.dx, head.dy - headSize);
        arrowPath.lineTo(head.dx, head.dy + headSize);
        break;
    }

    arrowPath.close();
    canvas.drawPath(arrowPath, fillPaint);
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    // check if point is near any cell in the path
    for (final cell in model.cells) {
      final center = _cellCenter(cell);
      final dx = point.x - center.dx;
      final dy = point.y - center.dy;
      if (dx * dx + dy * dy < (cellSize * 0.6) * (cellSize * 0.6)) {
        return true;
      }
    }
    return false;
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (model.state == ArrowState.idle) {
      onTapped(model);
    }
  }
}