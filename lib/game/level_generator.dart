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
    Map<int, Set<int>> dependencyGraph = {};

    while (arrows.length < config.arrowCount && failedAttempts < 20000) {
      final headRow = random.nextInt(rows);
      final headCol = random.nextInt(cols);
      final headKey = '${headRow}_$headCol';
      if (occupiedMap.containsKey(headKey)) {
        failedAttempts++;
        continue;
      }

      final direction = ArrowDirection.values[random.nextInt(4)];

      // Standard dense maze packing lengths based on difficulty
      final currentMinL = config.minArrowLength;
      final currentMaxL = config.maxArrowLength;

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

      // ---------------------------------------------------------
      // DAG Dependency Checking for Deep Complexity
      // ---------------------------------------------------------
      final tempGraph = <int, Set<int>>{};
      dependencyGraph.forEach((k, v) => tempGraph[k] = Set.from(v));
      tempGraph[id] = <int>{};

      // 1. What does the new arrow (id) depend on?
      int er = cells.first.row;
      int ec = cells.first.col;
      while (true) {
        switch (direction) {
          case ArrowDirection.up:    er--; break;
          case ArrowDirection.down:  er++; break;
          case ArrowDirection.left:  ec--; break;
          case ArrowDirection.right: ec++; break;
        }
        if (er < 0 || er >= rows || ec < 0 || ec >= cols) break;
        final key = '${er}_$ec';
        if (occupiedMap.containsKey(key)) {
          tempGraph[id]!.add(occupiedMap[key]!);
        }
      }

      // 2. Which existing arrows depend on the new arrow?
      final nBodyKeys = cells.map((c) => c.toString()).toSet();
      for (final existing in arrows) {
        int exr = existing.cells.first.row;
        int exc = existing.cells.first.col;
        while (true) {
          switch (existing.direction) {
            case ArrowDirection.up:    exr--; break;
            case ArrowDirection.down:  exr++; break;
            case ArrowDirection.left:  exc--; break;
            case ArrowDirection.right: exc++; break;
          }
          if (exr < 0 || exr >= rows || exc < 0 || exc >= cols) break;
          
          if (nBodyKeys.contains('${exr}_$exc')) {
            if (!tempGraph.containsKey(existing.id)) {
              tempGraph[existing.id] = <int>{};
            }
            tempGraph[existing.id]!.add(id);
          }
        }
      }

      // 3. Reject if adding this arrow creates a deadlock cycle
      if (_hasCycle(tempGraph)) {
        failedAttempts++;
        continue;
      }

      // Success! Update graph and place arrow.
      dependencyGraph = tempGraph;
      failedAttempts = 0;

      for (final cell in cells) {
        occupiedMap[cell.toString()] = id;
      }

      arrows.add(ArrowModel(id: id++, cells: cells, direction: direction));
    }

    return LevelData(arrows: arrows, rows: rows, cols: cols);
  }

  static bool _hasCycle(Map<int, Set<int>> graph) {
    final visited = <int>{};
    final recStack = <int>{};

    bool dfs(int node) {
      if (recStack.contains(node)) return true;
      if (visited.contains(node)) return false;

      visited.add(node);
      recStack.add(node);

      if (graph.containsKey(node)) {
        for (final neighbor in graph[node]!) {
          if (dfs(neighbor)) return true;
        }
      }

      recStack.remove(node);
      return false;
    }

    for (final node in graph.keys) {
      if (!visited.contains(node)) {
        if (dfs(node)) return true;
      }
    }
    return false;
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