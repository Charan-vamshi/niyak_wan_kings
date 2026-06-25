import 'arrow_model.dart';

class LevelConfig {
  final int gridRows;
  final int gridCols;
  final int arrowCount;
  final double longArrowRatio; // 0.0 to 1.0, how many arrows are long
  final int maxArrowLength; // max cells an arrow can span
  final int minArrowLength;
  final bool scrollable; // hard and nightmare levels scroll

  const LevelConfig({
    required this.gridRows,
    required this.gridCols,
    required this.arrowCount,
    required this.longArrowRatio,
    required this.maxArrowLength,
    required this.minArrowLength,
    required this.scrollable,
  });

  static LevelConfig fromDifficulty(DifficultyType difficulty, int level) {
    final cycle = ((level - 1) ~/ 5) + 1; // increases every 5 levels

    switch (difficulty) {
      case DifficultyType.easy:
        return LevelConfig(
          gridRows: 6 + cycle,
          gridCols: 6 + cycle,
          arrowCount: 10 + (cycle * 2),
          longArrowRatio: 0.7,
          maxArrowLength: 5,
          minArrowLength: 3,
          scrollable: false,
        );

      case DifficultyType.hard:
        return LevelConfig(
          gridRows: 9 + cycle,
          gridCols: 9 + cycle,
          arrowCount: 18 + (cycle * 3),
          longArrowRatio: 0.3,
          maxArrowLength: 4,
          minArrowLength: 2,
          scrollable: true,
        );

      case DifficultyType.nightmare:
        return LevelConfig(
          gridRows: 12 + cycle,
          gridCols: 12 + cycle,
          arrowCount: 28 + (cycle * 4),
          longArrowRatio: 0.1,
          maxArrowLength: 5,
          minArrowLength: 1,
          scrollable: true,
        );
    }
  }
}