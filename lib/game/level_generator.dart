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

    final List<ArrowModel> arrows = [];
    final Set<String> occupied = {};

    int id = 0;
    int attempts = 0;
    final maxAttempts = config.arrowCount * 10;

    while (arrows.length < config.arrowCount && attempts < maxAttempts) {
      attempts++;

      final row = random.nextInt(config.gridRows);
      final col = random.nextInt(config.gridCols);
      final key = '$row\_$col';

      if (occupied.contains(key)) continue;

      final direction =
          ArrowDirection.values[random.nextInt(ArrowDirection.values.length)];

      occupied.add(key);
      arrows.add(ArrowModel(
        id: id++,
        row: row,
        col: col,
        direction: direction,
      ));
    }

    return LevelData(
      arrows: arrows,
      rows: config.gridRows,
      cols: config.gridCols,
    );
  }
}