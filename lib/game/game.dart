import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../core/arrow_model.dart';
import '../core/game_state.dart';
import '../components/arrow_tile.dart';
import 'level_generator.dart';

class NiyakGame extends FlameGame with TapCallbacks {
  final GameState gameState;
  final VoidCallback onLevelComplete;
  final VoidCallback onGameOver;

  late LevelData _levelData;
  final List<ArrowTile> _tiles = [];
  final gameWorld = PositionComponent();

  // arrows currently moving
  final List<_MovingArrow> _movingArrows = [];

  NiyakGame({
    required this.gameState,
    required this.onLevelComplete,
    required this.onGameOver,
  });

  @override
  Future<void> onLoad() async {
    add(gameWorld);
    loadLevel();
  }

  void loadLevel() {
    gameWorld.removeAll(gameWorld.children.toList());
    _tiles.clear();
    _movingArrows.clear();

    _levelData = LevelGenerator.generate(gameState.currentLevel);

    final gridWidth = _levelData.cols * ArrowTile.cellSize;
    final gridHeight = _levelData.rows * ArrowTile.cellSize;

    gameWorld.position = Vector2(
      (size.x - gridWidth) / 2,
      (size.y - gridHeight) / 2,
    );

    for (final arrow in _levelData.arrows) {
      final tile = ArrowTile(
        model: arrow,
        onTapped: _onArrowTapped,
        isDark: gameState.isDarkTheme,
      );
      _tiles.add(tile);
      gameWorld.add(tile);
    }
  }

  void _onArrowTapped(ArrowModel model) {
    if (model.state != ArrowState.idle) return;

    // mark as moving
    model.state = ArrowState.moving;
    _getTile(model)?.updateModel(model);

    _movingArrows.add(_MovingArrow(
      model: model,
      currentRow: model.row.toDouble(),
      currentCol: model.col.toDouble(),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);

    const double speed = 8.0; // cells per second

    final toRemove = <_MovingArrow>[];

    for (final moving in _movingArrows) {
      // move
      switch (moving.model.direction) {
        case ArrowDirection.up:
          moving.currentRow -= speed * dt;
          break;
        case ArrowDirection.down:
          moving.currentRow += speed * dt;
          break;
        case ArrowDirection.left:
          moving.currentCol -= speed * dt;
          break;
        case ArrowDirection.right:
          moving.currentCol += speed * dt;
          break;
      }

      // update tile visual position
      final tile = _getTile(moving.model);
      if (tile != null) {
        tile.position = Vector2(
          moving.currentCol * ArrowTile.cellSize,
          moving.currentRow * ArrowTile.cellSize,
        );
      }

      // check collision with idle arrows
      bool collided = false;
      for (final other in _tiles) {
        if (other.model.id == moving.model.id) continue;
        if (other.model.state != ArrowState.idle) continue;

        final dx = (moving.currentCol - other.model.col).abs();
        final dy = (moving.currentRow - other.model.row).abs();

        if (dx < 0.6 && dy < 0.6) {
          // collision!
          collided = true;
          _handleCollision(moving, other.model);
          toRemove.add(moving);
          break;
        }
      }

      if (collided) continue;

      // check if exited grid
      if (moving.currentRow < -1 ||
          moving.currentRow > _levelData.rows ||
          moving.currentCol < -1 ||
          moving.currentCol > _levelData.cols) {
        // extracted successfully
        moving.model.state = ArrowState.extracted;
        tile?.removeFromParent();
        _tiles.removeWhere((t) => t.model.id == moving.model.id);
        toRemove.add(moving);

        gameState.correctTap();

        // check level complete
        final remaining = _tiles.where(
            (t) => t.model.state != ArrowState.extracted).toList();
        if (remaining.isEmpty) {
          Future.delayed(const Duration(milliseconds: 300), () {
            onLevelComplete();
          });
        }
      }
    }

    for (final r in toRemove) {
      _movingArrows.remove(r);
    }
  }

  void _handleCollision(_MovingArrow moving, ArrowModel other) {
    moving.model.state = ArrowState.collided;
    other.state = ArrowState.collided;

    _getTile(moving.model)?.updateModel(moving.model);
    _getTile(other)?.updateModel(other);

    gameState.wrongTap();

    // reset both after delay
    Future.delayed(const Duration(milliseconds: 500), () {
      moving.model.state = ArrowState.idle;
      moving.model.row = moving.model.row;
      moving.model.col = moving.model.col;

      other.state = ArrowState.idle;

      _getTile(moving.model)?.updateModel(moving.model);
      _getTile(other)?.updateModel(other);

      // reset position visually
      _getTile(moving.model)?.position = Vector2(
        moving.model.col * ArrowTile.cellSize,
        moving.model.row * ArrowTile.cellSize,
      );
    });

    if (gameState.isGameOver) {
      Future.delayed(const Duration(milliseconds: 600), () {
        onGameOver();
      });
    }
  }

  void useHint() {
    if (gameState.hintsLeft <= 0) return;
    gameState.useHint();

    // find an arrow that can be safely extracted
    for (final tile in _tiles) {
      if (tile.model.state != ArrowState.idle) continue;
      if (_isSafeToExtract(tile.model)) {
        tile.model.state = ArrowState.moving;
        tile.updateModel(tile.model);

        // flash hint color briefly then auto-tap
        Future.delayed(const Duration(milliseconds: 600), () {
          tile.model.state = ArrowState.idle;
          tile.updateModel(tile.model);
          _onArrowTapped(tile.model);
        });
        break;
      }
    }
  }

  bool _isSafeToExtract(ArrowModel arrow) {
    // check if any idle arrow is in the path
    for (final other in _tiles) {
      if (other.model.id == arrow.id) continue;
      if (other.model.state != ArrowState.idle) continue;

      switch (arrow.direction) {
        case ArrowDirection.up:
          if (other.model.col == arrow.col && other.model.row < arrow.row)
            return false;
          break;
        case ArrowDirection.down:
          if (other.model.col == arrow.col && other.model.row > arrow.row)
            return false;
          break;
        case ArrowDirection.left:
          if (other.model.row == arrow.row && other.model.col < arrow.col)
            return false;
          break;
        case ArrowDirection.right:
          if (other.model.row == arrow.row && other.model.col > arrow.col)
            return false;
          break;
      }
    }
    return true;
  }

  ArrowTile? _getTile(ArrowModel model) {
    try {
      return _tiles.firstWhere((t) => t.model.id == model.id);
    } catch (_) {
      return null;
    }
  }

  @override
  Color backgroundColor() =>
      gameState.isDarkTheme
          ? const Color(0xFF0D0D1A)
          : const Color(0xFFF5F5F5);
}

class _MovingArrow {
  final ArrowModel model;
  double currentRow;
  double currentCol;

  _MovingArrow({
    required this.model,
    required this.currentRow,
    required this.currentCol,
  });
}