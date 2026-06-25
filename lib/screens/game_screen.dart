import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../core/game_state.dart';
import '../game/game.dart';
import '../game/level_generator.dart';
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
  late NiyakGame _game;
  late LevelData _levelData;
  bool _showLevelComplete = false;
  bool _showGameOver = false;

  @override
  void initState() {
    super.initState();
    _levelData = LevelGenerator.generate(widget.gameState.currentLevel);
    widget.gameState.resetLevelState();
    _initGame();
  }

  void _initGame() {
    _game = NiyakGame(
      gameState: widget.gameState,
      onLevelComplete: _onLevelComplete,
      onGameOver: _onGameOver,
    );
  }

  void _onLevelComplete() {
    setState(() => _showLevelComplete = true);
  }

  void _onGameOver() {
    setState(() => _showGameOver = true);
  }

  void _onExitPressed() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: widget.gameState.isDarkTheme
            ? const Color(0xFF1A1A2E)
            : Colors.white,
        title: Text(
          'Exit Level?',
          style: TextStyle(
            color:
                widget.gameState.isDarkTheme ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          'Your progress will be lost.',
          style: TextStyle(
            color: widget.gameState.isDarkTheme
                ? Colors.white70
                : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Stay', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child:
                const Text('Exit', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: _game),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HudWidget(
              gameState: widget.gameState,
              totalArrows: _levelData.arrows.length,
              onHintPressed: () => _game.useHint(),
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
                  _levelData = LevelGenerator.generate(
                      widget.gameState.currentLevel);
                  widget.gameState.resetLevelState();
                  _initGame();
                });
              },
            ),
          if (_showGameOver)
            GameOverScreen(
              gameState: widget.gameState,
              onRestart: () {
                widget.gameState.restartAfterGameOver();
                setState(() {
                  _showGameOver = false;
                  widget.gameState.resetLevelState();
                  _initGame();
                });
              },
            ),
        ],
      ),
    );
  }
}