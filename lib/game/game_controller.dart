import 'dart:async';
import 'package:flutter/material.dart';
import '../core/arrow_model.dart';
import '../core/game_state.dart';
import 'level_generator.dart';

class GameController extends ChangeNotifier {
  final GameState gameState;
  final VoidCallback onLevelComplete;
  final VoidCallback onGameOver;

  late LevelData levelData;
  bool isAnimating = false;

  GameController({
    required this.gameState,
    required this.onLevelComplete,
    required this.onGameOver,
  }) {
    _loadLevel();
  }

  void _loadLevel() {
    levelData = LevelGenerator.generate(gameState.currentLevel);
    isAnimating = false;
    notifyListeners();
  }

  void reload() {
    _loadLevel();
  }

  Map<String, int> get occupiedMap => levelData.buildOccupiedMap();

  void onArrowTapped(ArrowModel arrow) {
    if (isAnimating) return;
    if (arrow.state != ArrowState.idle) return;

    final occupied = occupiedMap;

    if (arrow.canExit(occupied, levelData.rows, levelData.cols)) {
      _extractArrow(arrow);
    } else {
      _wrongTap(arrow);
    }
  }

  void _extractArrow(ArrowModel arrow) {
    isAnimating = true;
    arrow.state = ArrowState.moving;
    notifyListeners();

    const stepDuration = Duration(milliseconds: 60);
    final totalSteps = arrow.cells.length + levelData.rows + levelData.cols;
    int step = 0;

    Timer.periodic(stepDuration, (timer) {
      step++;
      arrow.animOffset = step.toDouble();

      if (step >= totalSteps) {
        timer.cancel();
        arrow.state = ArrowState.extracted;
        isAnimating = false;
        gameState.onCorrectTap();

        final remaining = levelData.arrows
            .where((a) => a.state != ArrowState.extracted)
            .toList();

        if (remaining.isEmpty) {
          Future.delayed(const Duration(milliseconds: 200), onLevelComplete);
        }
        notifyListeners();
        return;
      }

      notifyListeners();
    });
  }

  void _wrongTap(ArrowModel arrow) {
    arrow.state = ArrowState.collided;
    gameState.onWrongTap();
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 500), () {
      arrow.state = ArrowState.idle;
      notifyListeners();
      if (gameState.isGameOver) {
        Future.delayed(const Duration(milliseconds: 200), onGameOver);
      }
    });
  }

  void useHint() {
    if (gameState.hintsLeft <= 0) return;
    final occupied = occupiedMap;
    for (final arrow in levelData.arrows) {
      if (arrow.state != ArrowState.idle) continue;
      if (arrow.canExit(occupied, levelData.rows, levelData.cols)) {
        gameState.useHint();
        arrow.state = ArrowState.collided;
        notifyListeners();
        Future.delayed(const Duration(milliseconds: 800), () {
          arrow.state = ArrowState.idle;
          notifyListeners();
        });
        break;
      }
    }
  }
}