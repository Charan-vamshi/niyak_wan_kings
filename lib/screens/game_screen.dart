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

  final Set<AnimationController> _activeControllers = {};

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
    _controller.addListener(_onGameControllerUpdated);
  }

  void _onGameControllerUpdated() {
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final controller in _activeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onTapUp(TapUpDetails details, double scale, Offset offset) {
    // Convert local tap position to grid coordinates based on the FittedBox scale
    final localTap = details.localPosition;
    
    final col = (localTap.dx / ArrowPainter.cellSize).floor();
    final row = (localTap.dy / ArrowPainter.cellSize).floor();

    ArrowModel? targetArrow;
    for (final arrow in _controller.levelData.arrows) {
      if (arrow.state == ArrowState.extracted) continue;
      for (final cell in arrow.cells) {
        if (cell.row == row && cell.col == col) {
          targetArrow = arrow;
          break;
        }
      }
      if (targetArrow != null) break;
    }

    if (targetArrow == null) return;

    final result = _controller.onArrowTapped(targetArrow);

    if (result == TapResult.extracted) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1800), // Slower, relaxed speed
      );
      _activeControllers.add(controller);
      
      final curve = CurvedAnimation(parent: controller, curve: Curves.easeOutCubic);
      
      controller.addListener(() {
        setState(() {
          targetArrow!.animOffset = curve.value;
        });
      });
      
      controller.forward().then((_) {
        if (mounted) {
          _controller.onExtractionComplete(targetArrow!);
        }
        controller.dispose();
        _activeControllers.remove(controller);
      });
      
    } else if (result == TapResult.collided) {
      _startWiggle(targetArrow);
    }
  }

  void _startWiggle(ArrowModel targetArrow) {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _activeControllers.add(controller);
    
    controller.addListener(() {
      setState(() {
        targetArrow.animOffset = sin(controller.value * pi * 3) * 0.1;
      });
    });
    
    controller.forward().then((_) {
      if (mounted) {
        _controller.onCollisionComplete(targetArrow);
        targetArrow.animOffset = 0;
      }
      controller.dispose();
      _activeControllers.remove(controller);
    });
  }

  void _onHintPressed() {
    final targetArrow = _controller.useHint();
    if (targetArrow != null) {
      _startWiggle(targetArrow);
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
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 5.0,
                  boundaryMargin: const EdgeInsets.symmetric(horizontal: 120, vertical: 120),
                  clipBehavior: Clip.none, // Allows zooming to overflow the padding for a premium feel
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: GestureDetector(
                      onTapUp: (details) => _onTapUp(details, 1.0, Offset.zero),
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
                            showGuideLines: widget.gameState.showGuideLines,
                          ),
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
              onHintPressed: _onHintPressed,
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