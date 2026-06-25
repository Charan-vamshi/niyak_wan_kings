enum ArrowDirection { up, down, left, right }

enum ArrowState { idle, moving, extracted, collided }

enum DifficultyType { easy, hard, nightmare }

class ArrowModel {
  final int id;
  int row;
  int col;
  final ArrowDirection direction;
  ArrowState state;

  ArrowModel({
    required this.id,
    required this.row,
    required this.col,
    required this.direction,
    this.state = ArrowState.idle,
  });

  ArrowModel copyWith({
    int? row,
    int? col,
    ArrowState? state,
  }) {
    return ArrowModel(
      id: id,
      row: row ?? this.row,
      col: col ?? this.col,
      direction: direction,
      state: state ?? this.state,
    );
  }
}

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
      case ArrowDirection.up:
        return GridPosition(row - 1, col);
      case ArrowDirection.down:
        return GridPosition(row + 1, col);
      case ArrowDirection.left:
        return GridPosition(row, col - 1);
      case ArrowDirection.right:
        return GridPosition(row, col + 1);
    }
  }
}

DifficultyType getDifficulty(int level) {
  final cycle = (level - 1) % 5;
  if (cycle < 2) return DifficultyType.easy;
  if (cycle < 4) return DifficultyType.hard;
  return DifficultyType.nightmare;
}