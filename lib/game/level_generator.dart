import 'dart:math';
import '../core/arrow_model.dart';
import '../core/level_config.dart';

class LevelData {
  final List<ArrowModel> arrows;
  final int rows;
  final int cols;

  LevelData({
    required this.arrows,
    required this.rows,
    required this.cols,
  });
}

class LevelGenerator {
  static LevelData generate(int level) {
    final difficulty = getDifficulty(level);
    final config = LevelConfig.fromDifficulty(difficulty, level);
    final random = Random(level * 9999);

    final int rows = config.gridRows;
    final int cols = config.gridCols;

    // occupiedMap: which arrow id owns each cell
    final Map<String, int> occupiedMap = {};
    final List<ArrowModel> arrows = [];
    int id = 0;

    // get all cells
    final allCells = <GridPosition>[];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        allCells.add(GridPosition(r, c));
      }
    }
    allCells.shuffle(random);

    for (final startCell in allCells) {
      final key = startCell.toString();
      if (occupiedMap.containsKey(key)) continue;

      // grow a snake path from this cell
      final path = _growPath(
        start: startCell,
        occupiedMap: occupiedMap,
        rows: rows,
        cols: cols,
        random: random,
        minLength: config.minArrowLength,
        maxLength: config.maxArrowLength,
      );

      if (path.length < 2) continue;

      // pick exit direction based on last segment direction
      final exitDir = _getExitDirection(path);

      // mark all cells
      for (final cell in path) {
        occupiedMap[cell.toString()] = id;
      }

      arrows.add(ArrowModel(
        id: id++,
        cells: path,
        direction: exitDir,
      ));
    }

    return LevelData(
      arrows: arrows,
      rows: rows,
      cols: cols,
    );
  }

  static List<GridPosition> _growPath({
    required GridPosition start,
    required Map<String, int> occupiedMap,
    required int rows,
    required int cols,
    required Random random,
    required int minLength,
    required int maxLength,
  }) {
    final path = <GridPosition>[start];
    final targetLength = minLength + random.nextInt(maxLength - minLength + 1);

    int attempts = 0;
    while (path.length < targetLength && attempts < 50) {
      attempts++;
      final current = path.last;

      // get valid neighbors
      final neighbors = <GridPosition>[];
      for (final dir in ArrowDirection.values) {
        final next = current.shift(dir);
        if (next.row < 0 || next.row >= rows) continue;
        if (next.col < 0 || next.col >= cols) continue;
        if (occupiedMap.containsKey(next.toString())) continue;
        if (path.contains(next)) continue;
        neighbors.add(next);
      }

      if (neighbors.isEmpty) break;
      neighbors.shuffle(random);
      path.add(neighbors.first);
    }

    return path;
  }

  static ArrowDirection _getExitDirection(List<GridPosition> path) {
    if (path.length < 2) return ArrowDirection.right;

    final secondLast = path[path.length - 2];
    final last = path[path.length - 1];

    final dr = last.row - secondLast.row;
    final dc = last.col - secondLast.col;

    if (dr == -1) return ArrowDirection.up;
    if (dr == 1) return ArrowDirection.down;
    if (dc == -1) return ArrowDirection.left;
    return ArrowDirection.right;
  }
}