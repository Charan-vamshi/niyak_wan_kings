enum ArrowDirection { up, down, left, right }
enum ArrowState { idle, moving, collided, extracted }
enum DifficultyType { easy, hard, nightmare }

class GridPosition {
  final int row;
  final int col;
  const GridPosition(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      other is GridPosition && other.row == row && other.col == col;

  @override
  int get hashCode => row * 1000 + col;

  GridPosition shift(ArrowDirection dir) {
    switch (dir) {
      case ArrowDirection.up:    return GridPosition(row - 1, col);
      case ArrowDirection.down:  return GridPosition(row + 1, col);
      case ArrowDirection.left:  return GridPosition(row, col - 1);
      case ArrowDirection.right: return GridPosition(row, col + 1);
    }
  }

  @override
  String toString() => '${row}_$col';
}

class ArrowModel {
  final int id;
  final List<GridPosition> cells;
  ArrowDirection direction;
  ArrowState state;
  double animOffset;
  bool isStuck;

  ArrowModel({
    required this.id,
    required this.cells,
    required this.direction,
    this.state = ArrowState.idle,
    this.animOffset = 0,
    this.isStuck = false,
  });

  GridPosition get head => cells[0];
  GridPosition get tail => cells[cells.length - 1];

  bool canExit(Map<String, int> occupiedMap, int rows, int cols) {
    int r = head.row;
    int c = head.col;
    while (true) {
      switch (direction) {
        case ArrowDirection.up:    r--; break;
        case ArrowDirection.down:  r++; break;
        case ArrowDirection.left:  c--; break;
        case ArrowDirection.right: c++; break;
      }
      if (r < 0 || r >= rows || c < 0 || c >= cols) return true;
      final key = '${r}_$c';
      if (occupiedMap.containsKey(key) && occupiedMap[key] != id) return false;
    }
  }
}

DifficultyType getDifficulty(int level) {
  final cycle = (level - 1) % 5;
  if (cycle < 2) return DifficultyType.easy;
  if (cycle < 4) return DifficultyType.hard;
  return DifficultyType.nightmare;
}