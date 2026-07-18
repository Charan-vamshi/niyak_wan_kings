import 'dart:math';
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

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late GameController _controller;
  bool _showLevelComplete = false;
  bool _showGameOver = false;

  late AnimationController _extractController;
  late AnimationController _wiggleController;
  ArrowModel? _animatingArrow;

  @override
  void initState() {
    super.initState();
    widget.gameState.resetLevelState();
    
    _extractController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _extractController.addListener(() {
      if (_animatingArrow != null) {
        // Apply ease-out curve for extraction
        final curve = Curves.easeOutCubic.transform(_extractController.value);
        _animatingArrow!.animOffset = curve;
        setState(() {}); // trigger rebuild for painter
      }
    });

    _wiggleController.addListener(() {
      if (_animatingArrow != null) {
        // Quick back and forth wiggle
        final t = _wiggleController.value;
        _animatingArrow!.animOffset = sin(t * pi * 3) * 0.15; // wiggle intensity
        setState(() {});
      }
    });

    _extractController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _animatingArrow != null) {
        _controller.onExtractionComplete(_animatingArrow!);
        _animatingArrow = null;
      }
    });

    _wiggleController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _animatingArrow != null) {
        _animatingArrow!.animOffset = 0;
        _controller.onCollisionComplete(_animatingArrow!);
        _animatingArrow = null;
      }
    });

    _initController();
  }

  void _initController() {
    _controller = GameController(
      gameState: widget.gameState,
      onLevelComplete: () => setState(() => _showLevelComplete = true),
      onGameOver: () => setState(() => _showGameOver = true),
    );
    _controller.addListener(_onGameControllerUpdated);
  }

  void _onGameControllerUpdated() {
    // Check if an arrow just started moving or colliding
    for (final arrow in _controller.levelData.arrows) {
      if (arrow.state == ArrowState.moving && _animatingArrow != arrow) {
        _animatingArrow = arrow;
        _extractController.forward(from: 0.0);
        break;
      } else if (arrow.state == ArrowState.collided && _animatingArrow != arrow) {
        _animatingArrow = arrow;
        _wiggleController.forward(from: 0.0);
        break;
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _extractController.dispose();
    _wiggleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details, double scale, Offset offset) {
    if (_controller.isAnimating) return;

    // Convert local tap position to grid coordinates based on the FittedBox scale
    final localTap = details.localPosition;
    
    final col = (localTap.dx / ArrowPainter.cellSize).floor();
    final row = (localTap.dy / ArrowPainter.cellSize).floor();

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
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA);
    
    final gridW = _controller.levelData.cols * ArrowPainter.cellSize;
    final gridH = _controller.levelData.rows * ArrowPainter.cellSize;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 80, bottom: 40, left: 16, right: 16),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: GestureDetector(
                    onTapDown: (details) => _onTapDown(details, 1.0, Offset.zero),
                    child: Container(
                      color: Colors.transparent, // Ensure gesture detector captures taps
                      width: gridW,
                      height: gridH,
                      child: CustomPaint(
                        size: Size(gridW, gridH),
                        painter: ArrowPainter(
                          arrows: _controller.levelData.arrows,
                          isDark: isDark,
                          rows: _controller.levelData.rows,
                          cols: _controller.levelData.cols,
                        ),
                      ),
                    ),
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
            ? const Color(0xFF1E1E1E)
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