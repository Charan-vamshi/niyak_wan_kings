import 'package:flutter/material.dart';
import '../core/game_state.dart';
import '../core/arrow_model.dart';
import '../game/game_controller.dart';
import '../components/arrow_painter.dart';
import '../ui/hud.dart';
import 'level_complete_screen.dart';
import 'game_over_screen.dart';

class GameScreen extends StatefulWidget {
  final GameState gameState;
  const GameScreen({super.key, required this.gameState});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameController _controller;
  bool _showLevelComplete = false;
  bool _showGameOver = false;
  final TransformationController _transformController = TransformationController();

  @override
  void initState() {
    super.initState();
    widget.gameState.resetLevelState();
    _initController();
  }

  void _initController() {
    _controller = GameController(
      gameState: widget.gameState,
      onLevelComplete: () => setState(() => _showLevelComplete = true),
      onGameOver: () => setState(() => _showGameOver = true),
    );
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (_controller.isAnimating) return;

    final matrix = _transformController.value;
    final scale = matrix.getMaxScaleOnAxis();
    final translated = details.localPosition;
    final worldX = (translated.dx - matrix.getTranslation().x) / scale;
    final worldY = (translated.dy - matrix.getTranslation().y) / scale;

    final col = (worldX / ArrowPainter.cellSize).floor();
    final row = (worldY / ArrowPainter.cellSize).floor();

    for (final arrow in _controller.levelData.arrows) {
      if (arrow.state == ArrowState.extracted) continue;
      for (final cell in arrow.cells) {
        if (cell.row == row && cell.col == col) {
          _controller.onArrowTapped(arrow);
          return;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.gameState.isDarkTheme;
    final bg = isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF5F5F5);
    final gridW = _controller.levelData.cols * ArrowPainter.cellSize;
    final gridH = _controller.levelData.rows * ArrowPainter.cellSize;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          GestureDetector(
            onTapDown: _onTapDown,
            child: InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.3,
              maxScale: 3.0,
              boundaryMargin: const EdgeInsets.all(200),
              child: Container(
                color: bg,
                width: gridW,
                height: gridH,
                child: CustomPaint(
                  size: Size(gridW, gridH),
                  painter: ArrowPainter(
                    arrows: _controller.levelData.arrows,
                    isDark: isDark,
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 0, left: 0, right: 0,
            child: HudWidget(
              gameState: widget.gameState,
              totalArrows: _controller.levelData.arrows.length,
              onHintPressed: _controller.useHint,
              onExitPressed: _onExitPressed,
            ),
          ),

          if (_showLevelComplete)
            LevelCompleteScreen(
              gameState: widget.gameState,
              onNext: () {
                widget.gameState.completeLevel();
                setState(() {
                  _showLevelComplete = false;
                  _initController();
                  widget.gameState.resetLevelState();
                });
              },
            ),

          if (_showGameOver)
            GameOverScreen(
              gameState: widget.gameState,
              onRestart: () {
                widget.gameState.restartLevel();
                setState(() {
                  _showGameOver = false;
                  _initController();
                });
              },
            ),
        ],
      ),
    );
  }

  void _onExitPressed() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: widget.gameState.isDarkTheme
            ? const Color(0xFF1A1A2E)
            : Colors.white,
        title: Text('Exit Level?',
            style: TextStyle(
                color: widget.gameState.isDarkTheme ? Colors.white : Colors.black)),
        content: Text('Your progress will be lost.',
            style: TextStyle(
                color: widget.gameState.isDarkTheme ? Colors.white70 : Colors.black54)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Stay', style: TextStyle(color: Colors.grey))),
          TextButton(
              onPressed: () { Navigator.pop(context); Navigator.pop(context); },
              child: const Text('Exit', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}