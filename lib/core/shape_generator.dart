import 'dart:math';
import 'arrow_model.dart';

class ShapeGenerator {
  static Set<GridPosition> generate(int level, int rows, int cols) {
    final shapeIndex = (level - 1) % _shapes.length;
    final baseShape = _shapes[shapeIndex];
    return _fitShape(baseShape, rows, cols);
  }

  static Set<GridPosition> _fitShape(
      List<List<int>> shape, int rows, int cols) {
    final result = <GridPosition>{};
    final shapeRows = shape.length;
    final shapeCols = shape[0].length;
    final rowOffset = (rows - shapeRows) ~/ 2;
    final colOffset = (cols - shapeCols) ~/ 2;

    for (int r = 0; r < shapeRows; r++) {
      for (int c = 0; c < shapeCols; c++) {
        if (shape[r][c] == 1) {
          result.add(GridPosition(r + rowOffset, c + colOffset));
        }
      }
    }
    return result;
  }

  static final List<List<List<int>>> _shapes = [
    // Bird
    [
      [0, 0, 1, 0, 0, 0, 0],
      [0, 1, 1, 1, 0, 0, 0],
      [1, 1, 1, 1, 1, 1, 1],
      [0, 1, 1, 1, 0, 0, 0],
      [0, 0, 1, 0, 0, 0, 0],
    ],
    // Tree
    [
      [0, 0, 1, 0, 0],
      [0, 1, 1, 1, 0],
      [1, 1, 1, 1, 1],
      [0, 0, 1, 0, 0],
      [0, 0, 1, 0, 0],
    ],
    // Heart
    [
      [0, 1, 1, 0, 1, 1, 0],
      [1, 1, 1, 1, 1, 1, 1],
      [1, 1, 1, 1, 1, 1, 1],
      [0, 1, 1, 1, 1, 1, 0],
      [0, 0, 1, 1, 1, 0, 0],
      [0, 0, 0, 1, 0, 0, 0],
    ],
    // Diamond
    [
      [0, 0, 1, 0, 0],
      [0, 1, 1, 1, 0],
      [1, 1, 1, 1, 1],
      [0, 1, 1, 1, 0],
      [0, 0, 1, 0, 0],
    ],
    // House
    [
      [0, 0, 1, 0, 0],
      [0, 1, 1, 1, 0],
      [1, 1, 1, 1, 1],
      [1, 1, 1, 1, 1],
      [1, 1, 0, 1, 1],
    ],
    // Star
    [
      [0, 0, 1, 0, 0],
      [1, 1, 1, 1, 1],
      [0, 1, 1, 1, 0],
      [1, 0, 1, 0, 1],
      [0, 0, 1, 0, 0],
    ],
    // Cross
    [
      [0, 1, 1, 1, 0],
      [1, 1, 1, 1, 1],
      [1, 1, 1, 1, 1],
      [1, 1, 1, 1, 1],
      [0, 1, 1, 1, 0],
    ],
    // Lightning bolt
    [
      [0, 1, 1, 1, 0],
      [0, 0, 1, 0, 0],
      [0, 1, 1, 0, 0],
      [0, 0, 1, 0, 0],
      [0, 1, 1, 1, 0],
    ],
    // Crown
    [
      [1, 0, 1, 0, 1],
      [1, 1, 1, 1, 1],
      [1, 1, 1, 1, 1],
      [0, 1, 1, 1, 0],
    ],
    // Fish
    [
      [0, 1, 1, 1, 0, 0],
      [1, 1, 1, 1, 1, 1],
      [1, 1, 1, 1, 1, 1],
      [0, 1, 1, 1, 0, 0],
    ],
  ];
}