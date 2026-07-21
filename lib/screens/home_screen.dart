import 'package:flutter/material.dart';
import '../core/game_state.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  final GameState gameState;
  const HomeScreen({super.key, required this.gameState});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOutSine)
    );
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.gameState,
      builder: (context, _) {
        final isDark = widget.gameState.isDarkTheme;
        final bg = Colors.black;
        final fg = Colors.white; // Force white foreground for the pure black theme

        return Scaffold(
          backgroundColor: bg,
          body: Stack(
            children: [
              SafeArea(
                child: Stack(
                  children: [
                Positioned(
                  top: 16, right: 16,
                  child: GestureDetector(
                    onTap: widget.gameState.toggleTheme,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: fg.withAlpha(15),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: fg.withAlpha(30)),
                      ),
                      child: Row(
                        children: [
                          Icon(isDark ? Icons.light_mode : Icons.dark_mode,
                              color: fg.withAlpha(180), size: 18),
                          const SizedBox(width: 8),
                          Text(isDark ? 'LIGHT' : 'DARK',
                              style: TextStyle(color: fg.withAlpha(180), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: Image.asset(
                              'assets/logo.png',
                              fit: BoxFit.cover, // Expands to fill available space
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Text(
                                    'Please place logo.png in the assets folder\nand Hot Restart.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white54, fontSize: 16),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('LEVEL ${widget.gameState.currentLevel}',
                          style: TextStyle(
                              color: fg.withAlpha(180),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2)),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  GameScreen(gameState: widget.gameState)),
                        ),
                        child: Container(
                          width: 100, height: 100,
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
                            child: Icon(Icons.play_arrow, color: Colors.white, size: 50),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40), // Padding at the very bottom
                    ],
                  ),
                ), // Center
                  ],
                ), // Inner Stack
              ), // SafeArea
            ],
          ), // Outer Stack
        ); // Scaffold
      },
    );
  }
}