import 'package:flutter/material.dart';
import '../core/game_state.dart';
import '../core/arrow_model.dart';

class HudWidget extends StatelessWidget {
  final GameState gameState;
  final int totalArrows;
  final VoidCallback onHintPressed;
  final VoidCallback onExitPressed;

  const HudWidget({
    super.key,
    required this.gameState,
    required this.totalArrows,
    required this.onHintPressed,
    required this.onExitPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gameState,
      builder: (context, _) {
        final isDark = gameState.isDarkTheme;
        final fg = isDark ? Colors.white : Colors.black;
        final bg = isDark
            ? const Color(0xFF0D0D1A).withAlpha(230)
            : const Color(0xFFF5F5F5).withAlpha(230);

        return Container(
          color: bg,
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: onExitPressed,
                        child: Icon(Icons.arrow_back_ios, color: fg, size: 22),
                      ),
                      Column(
                        children: [
                          Text('LEVEL ${gameState.currentLevel}',
                              style: TextStyle(
                                  color: fg,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2)),
                          Text(_difficultyLabel(),
                              style: TextStyle(
                                  color: fg.withAlpha(128),
                                  fontSize: 11,
                                  letterSpacing: 1.5)),
                        ],
                      ),
                      GestureDetector(
                        onTap: gameState.toggleTheme,
                        child: Icon(
                            isDark ? Icons.light_mode : Icons.dark_mode,
                            color: fg, size: 22),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: totalArrows == 0 ? 0 : gameState.currentStreak / totalArrows,
                      backgroundColor: fg.withAlpha(25),
                      valueColor: AlwaysStoppedAnimation<Color>(fg.withAlpha(153)),
                      minHeight: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(3, (i) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(
                            i < gameState.lives ? Icons.favorite : Icons.favorite_border,
                            color: i < gameState.lives
                                ? Colors.red.shade400
                                : fg.withAlpha(76),
                            size: 22,
                          ),
                        )),
                      ),
                      GestureDetector(
                        onTap: gameState.hintsLeft > 0 ? onHintPressed : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: gameState.hintsLeft > 0
                                    ? fg.withAlpha(128)
                                    : fg.withAlpha(38)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.lightbulb_outline,
                                  color: gameState.hintsLeft > 0
                                      ? fg : fg.withAlpha(76),
                                  size: 16),
                              const SizedBox(width: 4),
                              Text('${gameState.hintsLeft}',
                                  style: TextStyle(
                                      color: gameState.hintsLeft > 0
                                          ? fg : fg.withAlpha(76),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  String _difficultyLabel() {
    switch (gameState.currentDifficulty) {
      case DifficultyType.easy: return 'EASY';
      case DifficultyType.hard: return 'HARD';
      case DifficultyType.nightmare: return 'NIGHTMARE';
    }
  }
}