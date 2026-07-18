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
  bool isAnimating = false; // True if any arrow is currently animating

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
    // Animation logic is now handled by GameScreen UI using AnimationController
    notifyListeners();
  }

  void _wrongTap(ArrowModel arrow) {
    isAnimating = true;
    arrow.state = ArrowState.collided;
    gameState.onWrongTap();
    // Animation logic is now handled by GameScreen UI using AnimationController
    notifyListeners();
  }

  // Called by GameScreen when an arrow's extraction animation finishes
  void onExtractionComplete(ArrowModel arrow) {
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
  }

  // Called by GameScreen when an arrow's collision wiggle animation finishes
  void onCollisionComplete(ArrowModel arrow) {
    arrow.state = ArrowState.idle;
    isAnimating = false;
    notifyListeners();
    
    if (gameState.isGameOver) {
      Future.delayed(const Duration(milliseconds: 200), onGameOver);
    }
  }

  void useHint() {
    if (gameState.hintsLeft <= 0 || isAnimating) return;
    final occupied = occupiedMap;
    for (final arrow in levelData.arrows) {
      if (arrow.state != ArrowState.idle) continue;
      if (arrow.canExit(occupied, levelData.rows, levelData.cols)) {
        gameState.useHint();
        // Just trigger a quick visual bump or highlight in a real game,
        // for now we use the collided state to wiggle it as a hint.
        arrow.state = ArrowState.collided;
        isAnimating = true;
        notifyListeners();
        break;
      }
    }
  }
}