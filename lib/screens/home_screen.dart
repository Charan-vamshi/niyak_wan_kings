import 'package:flutter/material.dart';
import '../core/game_state.dart';
import 'game_screen.dart';

class HomeScreen extends StatelessWidget {
  final GameState gameState;
  const HomeScreen({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gameState,
      builder: (context, _) {
        final isDark = gameState.isDarkTheme;
        final bg = isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA);
        final fg = isDark ? Colors.white : Colors.black;

        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 16, right: 16,
                  child: GestureDetector(
                    onTap: gameState.toggleTheme,
                    child: Icon(isDark ? Icons.light_mode : Icons.dark_mode,
                        color: fg.withAlpha(128), size: 28),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.call_split, size: 80, color: fg),
                      const SizedBox(height: 24),
                      Text('ARROWS',
                          style: TextStyle(
                              color: fg,
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 8)),
                      Text('PUZZLE ESCAPE',
                          style: TextStyle(
                              color: fg.withAlpha(128),
                              fontSize: 14,
                              letterSpacing: 4)),
                      const SizedBox(height: 80),
                      Text('LEVEL ${gameState.currentLevel}',
                          style: TextStyle(
                              color: fg.withAlpha(180),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2)),
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  GameScreen(gameState: gameState)),
                        ),
                        child: Container(
                          width: 120, height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? const Color(0xFF333333) : const Color(0xFF222222),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(50),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.play_arrow, color: Colors.white, size: 60),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}