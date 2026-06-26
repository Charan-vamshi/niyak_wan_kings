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

    final Map<String, int> occupiedMap = {};
    final List<ArrowModel> arrows = [];
    int id = 0;

    int attempts = 0;
    while (arrows.length < config.arrowCount && attempts < 10000) {
      attempts++;

      // pick random head cell
      final headRow = random.nextInt(rows);
      final headCol = random.nextInt(cols);
      final headKey = '${headRow}_$headCol';
      if (occupiedMap.containsKey(headKey)) continue;

      // pick random direction
      final direction =
          ArrowDirection.values[random.nextInt(ArrowDirection.values.length)];

      // exit path from head must be completely clear
      if (!_isExitClear(headRow, headCol, direction, occupiedMap, rows, cols)) {
        continue;
      }

      // grow tail from head (tail grows in any direction except exit direction)
      final cells = _growTail(
        headRow: headRow,
        headCol: headCol,
        direction: direction,
        occupiedMap: occupiedMap,
        rows: rows,
        cols: cols,
        random: random,
        minLength: config.minArrowLength,
        maxLength: config.maxArrowLength,
      );

      if (cells.isEmpty) continue;

      // mark all cells
      for (final cell in cells) {
        occupiedMap[cell.toString()] = id;
      }

      arrows.add(ArrowModel(
        id: id++,
        cells: cells,
        direction: direction,
      ));
    }

    return LevelData(
      arrows: arrows,
      rows: rows,
      cols: cols,
    );
  }

  static bool _isExitClear(
    int row,
    int col,
    ArrowDirection direction,
    Map<String, int> occupiedMap,
    int rows,
    int cols,
  ) {
    int r = row;
    int c = col;

    while (true) {
      switch (direction) {
        case ArrowDirection.up:
          r--;
          break;
        case ArrowDirection.down:
          r++;
          break;
        case ArrowDirection.left:
          c--;
          break;
        case ArrowDirection.right:
          c++;
          break;
      }

      if (r < 0 || r >= rows || c < 0 || c >= cols) return true;
      if (occupiedMap.containsKey('${r}_$c')) return false;
    }
  }

  static List<GridPosition> _growTail({
    required int headRow,
    required int headCol,
    required ArrowDirection direction,
    required Map<String, int> occupiedMap,
    required int rows,
    required int cols,
    required Random random,
    required int minLength,
    required int maxLength,
  }) {
    // cells[0] = head
    final cells = <GridPosition>[GridPosition(headRow, headCol)];
    final targetLength =
        minLength + random.nextInt(maxLength - minLength + 1);

    int attempts = 0;
    while (cells.length < targetLength && attempts < 100) {
      attempts++;
      final current = cells.last;

      final neighbors = <GridPosition>[];
      for (final dir in ArrowDirection.values) {
        // never grow in exit direction — that would block the head
        if (dir == direction) continue;

        final next = current.shift(dir);
        if (next.row < 0 || next.row >= rows) continue;
        if (next.col < 0 || next.col >= cols) continue;
        if (occupiedMap.containsKey(next.toString())) continue;
        if (cells.contains(next)) continue;

        neighbors.add(next);
      }

      if (neighbors.isEmpty) break;
      neighbors.shuffle(random);
      cells.add(neighbors.first);
    }

    return cells;
  }
}