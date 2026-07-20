import 'arrow_model.dart';

class LevelConfig {
  final int gridRows;
  final int gridCols;
  final int arrowCount;
  final int minArrowLength;
  final int maxArrowLength;

  const LevelConfig({
    required this.gridRows,
    required this.gridCols,
    required this.arrowCount,
    required this.minArrowLength,
    required this.maxArrowLength,
  });

  static LevelConfig fromDifficulty(DifficultyType difficulty, int level) {
    final cycle = ((level - 1) ~/ 5) + 1;
    switch (difficulty) {
      case DifficultyType.easy:
        // Previous 'Hard' size
        return LevelConfig(
          gridRows: 10 + cycle,
          gridCols: 7 + cycle,
          arrowCount: 9999, // Uncapped for dense packing
          minArrowLength: 3,
          maxArrowLength: 10,
        );
      case DifficultyType.hard:
        // Previous 'Nightmare' size
        return LevelConfig(
          gridRows: 12 + cycle,
          gridCols: 10 + cycle,
          arrowCount: 9999,
          minArrowLength: 3,
          maxArrowLength: 15,
        );
      case DifficultyType.nightmare:
        // Gigantic size, requires panning to see
        return LevelConfig(
          gridRows: 35 + cycle * 2,
          gridCols: 25 + cycle * 2,
          arrowCount: 9999,
          minArrowLength: 3,
          maxArrowLength: 25, // Significantly longer arrows to snake across the massive grid
        );
    }
  }
}