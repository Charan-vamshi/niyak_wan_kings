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
    model.state = ArrowState.moving;
    _getTile(model)?.updateModel(model);
    _movingArrows.add(_MovingArrow(model: model));
  }

  @override
  void update(double dt) {
    super.update(dt);

    const double speed = 6.0;
    final toRemove = <_MovingArrow>[];

    for (final moving in _movingArrows) {
      switch (moving.model.direction) {
        case ArrowDirection.up:
          moving.model.offsetRow -= speed * dt;
          break;
        case ArrowDirection.down:
          moving.model.offsetRow += speed * dt;
          break;
        case ArrowDirection.left:
          moving.model.offsetCol -= speed * dt;
          break;
        case ArrowDirection.right:
          moving.model.offsetCol += speed * dt;
          break;
      }

      _getTile(moving.model)?.updateModel(moving.model);

      // check collision using leading edge only
      bool collided = false;
      final headRow = moving.model.head.row + moving.model.offsetRow;
      final headCol = moving.model.head.col + moving.model.offsetCol;

      for (final tile in _tiles) {
        if (tile.model.id == moving.model.id) continue;
        if (tile.model.state != ArrowState.idle) continue;

        for (final cell in tile.model.cells) {
          final dr = (headRow - cell.row).abs();
          final dc = (headCol - cell.col).abs();
          if (dr < 0.5 && dc < 0.5) {
            collided = true;
            _handleCollision(moving, tile.model);
            toRemove.add(moving);
            break;
          }
        }
        if (collided) break;
      }

      if (collided) continue;

      // check if head has fully exited grid
      bool exited = false;
      switch (moving.model.direction) {
        case ArrowDirection.up:
          exited = headRow < -1;
          break;
        case ArrowDirection.down:
          exited = headRow > _levelData.rows;
          break;
        case ArrowDirection.left:
          exited = headCol < -1;
          break;
        case ArrowDirection.right:
          exited = headCol > _levelData.cols;
          break;
      }

      if (exited) {
        moving.model.state = ArrowState.extracted;
        _getTile(moving.model)?.removeFromParent();
        _tiles.removeWhere((t) => t.model.id == moving.model.id);
        toRemove.add(moving);

        gameState.correctTap();

        final remaining = _tiles
            .where((t) => t.model.state != ArrowState.extracted)
            .toList();
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

    Future.delayed(const Duration(milliseconds: 600), () {
      moving.model.offsetRow = 0;
      moving.model.offsetCol = 0;
      moving.model.state = ArrowState.idle;
      other.state = ArrowState.idle;

      _getTile(moving.model)?.updateModel(moving.model);
      _getTile(other)?.updateModel(other);

      if (!_tiles.any((t) => t.model.id == moving.model.id)) {
        final tile = ArrowTile(
          model: moving.model,
          onTapped: _onArrowTapped,
          isDark: gameState.isDarkTheme,
        );
        _tiles.add(tile);
        gameWorld.add(tile);
      }
    });

    if (gameState.isGameOver) {
      Future.delayed(const Duration(milliseconds: 700), () {
        onGameOver();
      });
    }
  }

  void useHint() {
    if (gameState.hintsLeft <= 0) return;
    gameState.useHint();

    for (final tile in _tiles) {
      if (tile.model.state != ArrowState.idle) continue;
      if (_isSafeToExtract(tile.model)) {
        tile.model.state = ArrowState.collided;
        tile.updateModel(tile.model);
        Future.delayed(const Duration(milliseconds: 800), () {
          tile.model.state = ArrowState.idle;
          tile.updateModel(tile.model);
        });
        break;
      }
    }
  }

  bool _isSafeToExtract(ArrowModel arrow) {
    for (final tile in _tiles) {
      if (tile.model.id == arrow.id) continue;
      if (tile.model.state != ArrowState.idle) continue;

      for (final cell in arrow.cells) {
        for (final other in tile.model.cells) {
          switch (arrow.direction) {
            case ArrowDirection.up:
              if (cell.col == other.col && other.row < cell.row) return false;
              break;
            case ArrowDirection.down:
              if (cell.col == other.col && other.row > cell.row) return false;
              break;
            case ArrowDirection.left:
              if (cell.row == other.row && other.col < cell.col) return false;
              break;
            case ArrowDirection.right:
              if (cell.row == other.row && other.col > cell.col) return false;
              break;
          }
        }
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
  Color backgroundColor() => gameState.isDarkTheme
      ? const Color(0xFF0D0D1A)
      : const Color(0xFFF5F5F5);
}

class _MovingArrow {
  final ArrowModel model;
  _MovingArrow({required this.model});
}