import 'dart:math';
import 'package:flutter/material.dart';
import '../core/game_state.dart';
import '../core/arrow_model.dart';
import '../game/game_controller.dart';
import '../components/arrow_painter.dart';
import '../ui/hud.dart';
import '../ui/laser_button.dart';
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
  final ValueNotifier<int> _tapNotifier = ValueNotifier<int>(0);

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
    _tapNotifier.dispose();
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

    _tapNotifier.value++; // Notify the LaserButton timer that a tap occurred

    // Auto-hide lasers when the player taps an arrow to hide processing and keep UI clean
    if (widget.gameState.showGuideLines) {
      widget.gameState.toggleGuideLines();
    }

    final result = _controller.onArrowTapped(targetArrow);

    if (result == TapResult.extracted) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400), // Slightly faster but accelerates
      );
      _activeControllers.add(controller);
      
      // Realistic extraction: Start from standstill and accelerate
      final curve = CurvedAnimation(parent: controller, curve: Curves.easeIn);
      
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
      duration: const Duration(milliseconds: 500), // Longer duration to allow the spring to settle
    );
    _activeControllers.add(controller);
    
    controller.addListener(() {
      setState(() {
        // Realistic Spring Physics:
        // Damped harmonic oscillator formula: A * sin(wt) * e^(-dt)
        // This gives a hard hit into the wall, a slight elastic bounce back, and smooth settling.
        final t = controller.value;
        targetArrow.animOffset = 0.15 * sin(t * pi * 4) * exp(-t * 4);
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
            child: Padding(
              padding: const EdgeInsets.only(top: 80, bottom: 40, left: 16, right: 16),
              child: ClipRect(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                  return TweenAnimationBuilder<double>(
                    key: ValueKey(widget.gameState.currentLevel),
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.scale(
                          scale: 1.2 - (value * 0.2), // Zoom out smoothly from 1.2x down to 1.0x
                          child: child,
                        ),
                      );
                    },
                    child: InteractiveViewer(
                      minScale: 0.15, // Allow zooming out very far to see the massive grid
                      maxScale: 5.0,
                      boundaryMargin: const EdgeInsets.symmetric(horizontal: 300, vertical: 300),
                      clipBehavior: Clip.none, 
                      constrained: false, // Critical: Allows the grid to be larger than the screen
                      child: Container(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                          minHeight: constraints.maxHeight,
                        ),
                        alignment: Alignment.center,
                        child: GestureDetector(
                          onTapUp: (details) => _onTapUp(details, 1.0, Offset.zero),
                          child: Container(
                            color: Colors.transparent, 
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
                  );
                }
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

          Positioned(
            bottom: 40,
            right: 24,
            child: LaserButton(
              gameState: widget.gameState,
              tapNotifier: _tapNotifier,
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