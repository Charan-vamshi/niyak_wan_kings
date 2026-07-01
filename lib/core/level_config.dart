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
        return LevelConfig(
          gridRows: 7 + cycle,
          gridCols: 5 + cycle,
          arrowCount: 6 + cycle * 2,
          minArrowLength: 3,
          maxArrowLength: 8,
        );
      case DifficultyType.hard:
        return LevelConfig(
          gridRows: 14 + cycle,
          gridCols: 10 + cycle,
          arrowCount: 16 + cycle * 3,
          minArrowLength: 3,
          maxArrowLength: 6,
        );
      case DifficultyType.nightmare:
        return LevelConfig(
          gridRows: 22 + cycle,
          gridCols: 16 + cycle,
          arrowCount: 30 + cycle * 5,
          minArrowLength: 3,
          maxArrowLength: 5,
        );
    }
  }
}