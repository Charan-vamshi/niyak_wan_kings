import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../core/arrow_model.dart';

class ArrowTile extends PositionComponent with TapCallbacks {
  static const double cellSize = 52.0;

  ArrowModel model;
  final Function(ArrowModel) onTapped;
  final bool isDark;

  ArrowTile({
    required this.model,
    required this.onTapped,
    required this.isDark,
  }) {
    size = Vector2(cellSize, cellSize);
    position = Vector2(
      model.col * cellSize,
      model.row * cellSize,
    );
  }

  void updateModel(ArrowModel newModel) {
    model = newModel;
    position = Vector2(
      model.col * cellSize,
      model.row * cellSize,
    );
  }

  Color get _bgColor =>
      isDark ? const Color(0xFF1A1A2E) : const Color(0xFFE8E8E8);

  @override
  void render(Canvas canvas) {
    if (model.state == ArrowState.extracted) return;

    Color arrowColor;
    Color bgColor;

    switch (model.state) {
      case ArrowState.idle:
        arrowColor = isDark ? Colors.white : Colors.black;
        bgColor = _bgColor;
        break;
      case ArrowState.moving:
        arrowColor = Colors.grey.shade400;
        bgColor = _bgColor;
        break;
      case ArrowState.collided:
        arrowColor = Colors.red.shade400;
        bgColor = Colors.red.shade900.withAlpha(80);
        break;
      case ArrowState.extracted:
        return;
    }

    // background tile
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(3, 3, size.x - 6, size.y - 6),
        const Radius.circular(8),
      ),
      bgPaint,
    );

    // arrow
    final paint = Paint()
      ..color = arrowColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = arrowColor
      ..style = PaintingStyle.fill;

    final center = Offset(size.x / 2, size.y / 2);
    const double headSize = 8.0;
    const double shaftLength = 12.0;

    Offset tail;
    Offset head;

    switch (model.direction) {
      case ArrowDirection.up:
        tail = Offset(center.dx, center.dy + shaftLength);
        head = Offset(center.dx, center.dy - shaftLength);
        break;
      case ArrowDirection.down:
        tail = Offset(center.dx, center.dy - shaftLength);
        head = Offset(center.dx, center.dy + shaftLength);
        break;
      case ArrowDirection.left:
        tail = Offset(center.dx + shaftLength, center.dy);
        head = Offset(center.dx - shaftLength, center.dy);
        break;
      case ArrowDirection.right:
        tail = Offset(center.dx - shaftLength, center.dy);
        head = Offset(center.dx + shaftLength, center.dy);
        break;
    }

    canvas.drawLine(tail, head, paint);

    final path = Path();
    switch (model.direction) {
      case ArrowDirection.up:
        path.moveTo(head.dx, head.dy);
        path.lineTo(head.dx - headSize, head.dy + headSize);
        path.lineTo(head.dx + headSize, head.dy + headSize);
        break;
      case ArrowDirection.down:
        path.moveTo(head.dx, head.dy);
        path.lineTo(head.dx - headSize, head.dy - headSize);
        path.lineTo(head.dx + headSize, head.dy - headSize);
        break;
      case ArrowDirection.left:
        path.moveTo(head.dx, head.dy);
        path.lineTo(head.dx + headSize, head.dy - headSize);
        path.lineTo(head.dx + headSize, head.dy + headSize);
        break;
      case ArrowDirection.right:
        path.moveTo(head.dx, head.dy);
        path.lineTo(head.dx - headSize, head.dy - headSize);
        path.lineTo(head.dx - headSize, head.dy + headSize);
        break;
    }
    path.close();
    canvas.drawPath(path, fillPaint);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (model.state == ArrowState.idle) {
      onTapped(model);
    }
  }
}