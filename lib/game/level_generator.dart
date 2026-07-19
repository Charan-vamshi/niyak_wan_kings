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
      // Ignore extracted arrows AND moving arrows (they instantly free up their space)
      if (arrow.state == ArrowState.extracted || arrow.state == ArrowState.moving) continue;
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

    int failedAttempts = 0;

    while (arrows.length < config.arrowCount && failedAttempts < 5000) {
      final headRow = random.nextInt(rows);
      final headCol = random.nextInt(cols);
      final headKey = '${headRow}_$headCol';
      if (occupiedMap.containsKey(headKey)) {
        failedAttempts++;
        continue;
      }

      final direction = ArrowDirection.values[random.nextInt(4)];

      if (!_isExitPathClear(headRow, headCol, direction, occupiedMap, rows, cols)) {
        failedAttempts++;
        continue;
      }

      // Standard dense maze packing lengths
      final currentMinL = 3;
      final currentMaxL = 10;

      final cells = _buildSnake(
        headRow: headRow,
        headCol: headCol,
        direction: direction,
        occupiedMap: occupiedMap,
        rows: rows,
        cols: cols,
        random: random,
        minLen: currentMinL,
        maxLen: currentMaxL,
      );

      if (cells.length < currentMinL) {
        failedAttempts++;
        continue;
      }

      // Success! Reset failed attempts.
      failedAttempts = 0;

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

    GridPosition firstNeck;
    ArrowDirection currentTailDir;
    switch (direction) {
      case ArrowDirection.up:    
        firstNeck = GridPosition(headRow + 1, headCol); 
        currentTailDir = ArrowDirection.down;
        break;
      case ArrowDirection.down:  
        firstNeck = GridPosition(headRow - 1, headCol); 
        currentTailDir = ArrowDirection.up;
        break;
      case ArrowDirection.left:  
        firstNeck = GridPosition(headRow, headCol + 1); 
        currentTailDir = ArrowDirection.right;
        break;
      case ArrowDirection.right: 
        firstNeck = GridPosition(headRow, headCol - 1); 
        currentTailDir = ArrowDirection.left;
        break;
    }

    // Build a set of cells that make up the exit path. The snake cannot grow into these!
    final exitPath = <String>{};
    int er = headRow;
    int ec = headCol;
    while (true) {
      switch (direction) {
        case ArrowDirection.up:    er--; break;
        case ArrowDirection.down:  er++; break;
        case ArrowDirection.left:  ec--; break;
        case ArrowDirection.right: ec++; break;
      }
      if (er < 0 || er >= rows || ec < 0 || ec >= cols) break;
      exitPath.add('${er}_$ec');
    }

    if (firstNeck.row >= 0 && firstNeck.row < rows && 
        firstNeck.col >= 0 && firstNeck.col < cols && 
        !occupiedMap.containsKey(firstNeck.toString()) &&
        !exitPath.contains(firstNeck.toString())) {
      cells.add(firstNeck);
    } else {
      return cells; 
    }

    int attempts = 0;
    while (cells.length < target && attempts < 200) {
      attempts++;
      final current = cells.last;
      
      final candidates = <ArrowDirection, GridPosition>{};
      for (final dir in ArrowDirection.values) {
        final next = current.shift(dir);
        if (next.row < 0 || next.row >= rows) continue;
        if (next.col < 0 || next.col >= cols) continue;
        if (occupiedMap.containsKey(next.toString())) continue;
        if (cells.contains(next)) continue;
        if (exitPath.contains(next.toString())) continue; // Prevent self-blocking
        candidates[dir] = next;
      }

      if (candidates.isEmpty) break;
      
      final keys = candidates.keys.toList()..shuffle(random);
      currentTailDir = keys.first;
      cells.add(candidates[currentTailDir]!);
    }

    return cells;
  }
}