import 'dart:math';
import '../core/arrow_model.dart';
import '../core/level_config.dart';

class LevelData {
  final List<ArrowModel> arrows;
  final int rows;
  final int cols;

  LevelData({required this.arrows, required this.rows, required this.cols});

  Map<String, int> buildOccupiedMap() {
    final map = <String, int>{};
    for (final arrow in arrows) {
      if (arrow.state == ArrowState.extracted) continue;
      for (final cell in arrow.cells) {
        map[cell.toString()] = arrow.id;
      }
    }
    return map;
  }
}

class LevelGenerator {
  static LevelData generate(int level) {
    final difficulty = getDifficulty(level);
    final config = LevelConfig.fromDifficulty(difficulty, level);
    final random = Random(level * 13337);

    final int rows = config.gridRows;
    final int cols = config.gridCols;

    final Map<String, int> occupiedMap = {};
    final List<ArrowModel> arrows = [];
    int id = 0;

    int totalAttempts = 0;

    while (arrows.length < config.arrowCount && totalAttempts < 50000) {
      totalAttempts++;

      final headRow = random.nextInt(rows);
      final headCol = random.nextInt(cols);
      final headKey = '${headRow}_$headCol';
      if (occupiedMap.containsKey(headKey)) continue;

      final direction = ArrowDirection.values[random.nextInt(4)];

      if (!_isExitPathClear(headRow, headCol, direction, occupiedMap, rows, cols)) continue;

      final cells = _buildSnake(
        headRow: headRow,
        headCol: headCol,
        direction: direction,
        occupiedMap: occupiedMap,
        rows: rows,
        cols: cols,
        random: random,
        minLen: config.minArrowLength,
        maxLen: config.maxArrowLength,
      );

      if (cells.length < config.minArrowLength) continue;

      for (final cell in cells) {
        occupiedMap[cell.toString()] = id;
      }

      arrows.add(ArrowModel(id: id++, cells: cells, direction: direction));
    }

    return LevelData(arrows: arrows, rows: rows, cols: cols);
  }

  static bool _isExitPathClear(
    int row, int col, ArrowDirection dir,
    Map<String, int> occupied, int rows, int cols,
  ) {
    int r = row;
    int c = col;
    while (true) {
      switch (dir) {
        case ArrowDirection.up:    r--; break;
        case ArrowDirection.down:  r++; break;
        case ArrowDirection.left:  c--; break;
        case ArrowDirection.right: c++; break;
      }
      if (r < 0 || r >= rows || c < 0 || c >= cols) return true;
      if (occupied.containsKey('${r}_$c')) return false;
    }
  }

  static List<GridPosition> _buildSnake({
    required int headRow,
    required int headCol,
    required ArrowDirection direction,
    required Map<String, int> occupiedMap,
    required int rows,
    required int cols,
    required Random random,
    required int minLen,
    required int maxLen,
  }) {
    final cells = <GridPosition>[GridPosition(headRow, headCol)];
    final target = minLen + random.nextInt(maxLen - minLen + 1);

    int attempts = 0;
    while (cells.length < target && attempts < 200) {
      attempts++;
      final current = cells.last;
      final candidates = <GridPosition>[];

      for (final dir in ArrowDirection.values) {
        if (dir == direction) continue;
        final next = current.shift(dir);
        if (next.row < 0 || next.row >= rows) continue;
        if (next.col < 0 || next.col >= cols) continue;
        if (occupiedMap.containsKey(next.toString())) continue;
        if (cells.contains(next)) continue;
        candidates.add(next);
      }

      if (candidates.isEmpty) break;
      candidates.shuffle(random);
      cells.add(candidates.first);
    }

    return cells;
  }
}