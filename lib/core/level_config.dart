import 'arrow_model.dart';

class LevelConfig {
  final int gridRows;
  final int gridCols;
  final int arrowCount;
  final int maxArrowLength;
  final int minArrowLength;
  final bool scrollable;

  const LevelConfig({
    required this.gridRows,
    required this.gridCols,
    required this.arrowCount,
    required this.maxArrowLength,
    required this.minArrowLength,
    required this.scrollable,
  });

  static LevelConfig fromDifficulty(DifficultyType difficulty, int level) {
    final cycle = ((level - 1) ~/ 5) + 1;

    switch (difficulty) {
      case DifficultyType.easy:
        // fits screen, long arrows, easy to solve
        return LevelConfig(
          gridRows: 8 + cycle,
          gridCols: 6 + cycle,
          arrowCount: 8 + (cycle * 2),
          maxArrowLength: 8,
          minArrowLength: 3,
          scrollable: false,
        );

      case DifficultyType.hard:
        // bigger than screen, medium arrows
        return LevelConfig(
          gridRows: 16 + cycle,
          gridCols: 12 + cycle,
          arrowCount: 20 + (cycle * 3),
          maxArrowLength: 6,
          minArrowLength: 3,
          scrollable: true,
        );

      case DifficultyType.nightmare:
        // much bigger than screen, short arrows, dense
        return LevelConfig(
          gridRows: 24 + cycle,
          gridCols: 18 + cycle,
          arrowCount: 40 + (cycle * 5),
          maxArrowLength: 5,
          minArrowLength: 3,
          scrollable: true,
        );
    }
  }
}