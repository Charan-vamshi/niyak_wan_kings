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

        return SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: onExitPressed,
                  child: Icon(Icons.arrow_back_ios, color: fg, size: 24),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('LEVEL ${gameState.currentLevel}',
                        style: TextStyle(
                            color: fg,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                        child: Icon(
                          i < gameState.lives ? Icons.favorite : Icons.favorite_border,
                          color: i < gameState.lives
                              ? const Color(0xFFD32F2F)
                              : fg.withAlpha(76),
                          size: 16,
                        ),
                      )),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: gameState.hintsLeft > 0 ? onHintPressed : null,
                  child: Icon(Icons.lightbulb_outline,
                      color: gameState.hintsLeft > 0 ? fg : fg.withAlpha(76), size: 24),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}