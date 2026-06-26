import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../core/arrow_model.dart';
import '../core/game_state.dart';
import '../components/arrow_tile.dart';
import 'level_generator.dart';

class NiyakGame extends FlameGame with DragCallbacks, ScaleDetector {
  final GameState gameState;
  final VoidCallback onLevelComplete;
  final VoidCallback onGameOver;

  late LevelData _levelData;
  final List<ArrowTile> _tiles = [];
  final gameWorld = PositionComponent();
  final List<_MovingArrow> _movingArrows = [];

  double _scale = 1.0;
  double _startScale = 1.0;
  static const double _minScale = 0.3;
  static const double _maxScale = 2.0;

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

    // center grid
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

  // Snake movement — advances head one cell at a time
  // Each cell takes position of cell ahead of it
  static const double _stepInterval = 0.08; // seconds per cell step

  @override
  void update(double dt) {
    super.update(dt);

    final toRemove = <_MovingArrow>[];

    for (final moving in _movingArrows) {
      moving.elapsed += dt;

      while (moving.elapsed >= _stepInterval) {
        moving.elapsed -= _stepInterval;

        // advance the snake by one cell
        final newHead = moving.model.head.shift(moving.model.direction);

        // check collision with idle arrows at new head position
        bool collided = false;
        for (final tile in _tiles) {
          if (tile.model.id == moving.model.id) continue;
          if (tile.model.state != ArrowState.idle) continue;

          for (final cell in tile.model.cells) {
            if (cell == newHead) {
              collided = true;
              _handleCollision(moving, tile.model);
              toRemove.add(moving);
              break;
            }
          }
          if (collided) break;
        }

        if (collided) break;

        // check if head exited grid
        if (newHead.row < 0 ||
            newHead.row >= _levelData.rows ||
            newHead.col < 0 ||
            newHead.col >= _levelData.cols) {
          // remove tail cell (snake shrinks from back)
          moving.model.cells.removeLast();

          if (moving.model.cells.isEmpty) {
            // fully extracted
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
            break;
          }
        } else {
          // add new head, remove tail (snake moves forward)
          moving.model.cells.insert(0, newHead);
          moving.model.cells.removeLast();
        }

        _getTile(moving.model)?.updateModel(moving.model);
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

  // Pan
  @override
  void onDragUpdate(DragUpdateEvent event) {
    gameWorld.position += event.localDelta;
  }

  // Pinch zoom
  @override
  void onScaleStart(ScaleStartInfo info) {
    _startScale = _scale;
  }

  @override
  void onScaleUpdate(ScaleUpdateInfo info) {
    final newScale = (_startScale * info.scale.global.x)
        .clamp(_minScale, _maxScale);
    _scale = newScale;
    gameWorld.scale = Vector2.all(_scale);
  }

  @override
  void onScaleEnd(ScaleEndInfo info) {}

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
  double elapsed = 0;

  _MovingArrow({required this.model});
}