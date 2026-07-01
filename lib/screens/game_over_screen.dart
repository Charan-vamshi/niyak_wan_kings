import 'package:flutter/material.dart';
import '../core/game_state.dart';

class GameOverScreen extends StatefulWidget {
  final GameState gameState;
  final VoidCallback onRestart;
  const GameOverScreen({super.key, required this.gameState, required this.onRestart});

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))..forward();
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.gameState.isDarkTheme;
    final bg = isDark
        ? const Color(0xFF0D0D1A).withAlpha(242)
        : const Color(0xFFF5F5F5).withAlpha(242);
    final fg = isDark ? Colors.white : Colors.black;

    return FadeTransition(
      opacity: _fadeIn,
      child: Container(
        color: bg,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.heart_broken, color: Colors.red.shade400, size: 64),
              const SizedBox(height: 24),
              Text('GAME OVER',
                  style: TextStyle(
                      color: fg, fontSize: 32,
                      fontWeight: FontWeight.bold, letterSpacing: 4)),
              const SizedBox(height: 8),
              Text('Level ${widget.gameState.currentLevel}',
                  style: TextStyle(color: fg.withAlpha(128), fontSize: 16, letterSpacing: 2)),
              const SizedBox(height: 48),
              GestureDetector(
                onTap: widget.onRestart,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  decoration: BoxDecoration(
                      border: Border.all(color: fg.withAlpha(128)),
                      borderRadius: BorderRadius.circular(40)),
                  child: Text('TRY AGAIN',
                      style: TextStyle(
                          color: fg, fontSize: 16,
                          fontWeight: FontWeight.bold, letterSpacing: 3)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}