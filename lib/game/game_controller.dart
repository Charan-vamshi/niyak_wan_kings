import 'dart:async';
import 'package:flutter/material.dart';
import '../core/arrow_model.dart';
import '../core/game_state.dart';
import 'level_generator.dart';

enum TapResult { extracted, collided, invalid, hint }

class GameController extends ChangeNotifier {
  final GameState gameState;
  final VoidCallback onLevelComplete;
  final VoidCallback onGameOver;

  late LevelData levelData;

  GameController({
    required this.gameState,
    required this.onLevelComplete,
    required this.onGameOver,
  }) {
    _loadLevel();
  }

  void _loadLevel() {
    levelData = LevelGenerator.generate(gameState.currentLevel);
    notifyListeners();
  }

  void reload() {
    _loadLevel();
  }

  Map<String, int> get occupiedMap => levelData.buildOccupiedMap();

  TapResult onArrowTapped(ArrowModel arrow) {
    if (arrow.state != ArrowState.idle) return TapResult.invalid;

    if (arrow.canExit(occupiedMap, levelData.rows, levelData.cols)) {
      arrow.state = ArrowState.moving;
      gameState.onCorrectTap();
      notifyListeners();
      return TapResult.extracted;
    } else {
      arrow.state = ArrowState.collided;
      arrow.isStuck = true;
      gameState.onWrongTap();
      notifyListeners();
      return TapResult.collided;
    }
  }

  void onExtractionComplete(ArrowModel arrow) {
    arrow.state = ArrowState.extracted;
    
    final remaining = levelData.arrows
        .where((a) => a.state != ArrowState.extracted)
        .toList();

    if (remaining.isEmpty) {
      Future.delayed(const Duration(milliseconds: 200), onLevelComplete);
    }
    notifyListeners();
  }

  void onCollisionComplete(ArrowModel arrow) {
    arrow.state = ArrowState.idle;
    
    if (gameState.isGameOver) {
      Future.delayed(const Duration(milliseconds: 200), onGameOver);
    }
    notifyListeners();
  }

  ArrowModel? useHint() {
    if (gameState.hintsLeft <= 0) return null;
    
    for (final arrow in levelData.arrows) {
      if (arrow.state != ArrowState.idle) continue;
      if (arrow.canExit(occupiedMap, levelData.rows, levelData.cols)) {
        gameState.useHint();
        arrow.state = ArrowState.collided; // Use wiggle for hint
        notifyListeners();
        return arrow;
      }
    }
    return null;
  }
}