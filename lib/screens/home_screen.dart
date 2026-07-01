import 'dart:math';
import 'package:flutter/material.dart';
import '../core/game_state.dart';
import '../core/arrow_model.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  final GameState gameState;
  const HomeScreen({super.key, required this.gameState});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _bgController;
  final List<_FloatingArrow> _floatingArrows = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    for (int i = 0; i < 18; i++) {
      _floatingArrows.add(_FloatingArrow(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        direction: ArrowDirection.values[_random.nextInt(4)],
        speed: _random.nextDouble() * 0.015 + 0.005,
        opacity: _random.nextDouble() * 0.12 + 0.04,
        size: _random.nextDouble() * 14 + 8,
      ));
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.gameState.isDarkTheme
          ? const Color(0xFF1A1A2E)
          : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ListenableBuilder(
        listenable: widget.gameState,
        builder: (context, _) {
          final fg = widget.gameState.isDarkTheme ? Colors.white : Colors.black;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: fg.withAlpha(51),
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 24),
                Text('SETTINGS',
                    style: TextStyle(
                        color: fg,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3)),
                const SizedBox(height: 24),
                _SettingsRow(
                    label: 'Sound Effects',
                    value: widget.gameState.soundEnabled,
                    fg: fg,
                    onToggle: widget.gameState.toggleSound),
                const SizedBox(height: 16),
                _SettingsRow(
                    label: 'Haptics',
                    value: widget.gameState.hapticsEnabled,
                    fg: fg,
                    onToggle: widget.gameState.toggleHaptics),
                const SizedBox(height: 24),
                Text('Best Streak: ${widget.gameState.bestStreak}',
                    style: TextStyle(
                        color: fg.withAlpha(102),
                        fontSize: 13,
                        letterSpacing: 1)),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.gameState,
      builder: (context, _) {
        final isDark = widget.gameState.isDarkTheme;
        final bg = isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF5F5F5);
        final fg = isDark ? Colors.white : Colors.black;

        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _bgController,
                  builder: (context, _) => CustomPaint(
                    painter: _FloatingArrowsPainter(
                        arrows: _floatingArrows,
                        progress: _bgController.value,
                        isDark: isDark),
                    size: Size.infinite,
                  ),
                ),
                Positioned(
                  top: 8, right: 16,
                  child: GestureDetector(
                    onTap: widget.gameState.toggleTheme,
                    child: Icon(isDark ? Icons.light_mode : Icons.dark_mode,
                        color: fg, size: 24),
                  ),
                ),
                Positioned(
                  top: 8, left: 16,
                  child: GestureDetector(
                    onTap: _openSettings,
                    child: Icon(Icons.tune, color: fg, size: 24),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('NIYAK',
                          style: TextStyle(
                              color: fg,
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 12)),
                      const SizedBox(height: 4),
                      Text('WAN KINGS',
                          style: TextStyle(
                              color: fg.withAlpha(102),
                              fontSize: 13,
                              letterSpacing: 6)),
                      const SizedBox(height: 60),
                      Text('LEVEL ${widget.gameState.currentLevel}',
                          style: TextStyle(
                              color: fg.withAlpha(128),
                              fontSize: 14,
                              letterSpacing: 4)),
                      const SizedBox(height: 4),
                      Text(_difficultyLabel(),
                          style: TextStyle(
                              color: fg.withAlpha(76),
                              fontSize: 11,
                              letterSpacing: 3)),
                      const SizedBox(height: 40),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  GameScreen(gameState: widget.gameState)),
                        ),
                        child: Container(
                          width: 160, height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: fg.withAlpha(76), width: 1.5),
                          ),
                          child: Center(
                            child: Text('PLAY',
                                style: TextStyle(
                                    color: fg,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 6)),
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

  String _difficultyLabel() {
    switch (widget.gameState.currentDifficulty) {
      case DifficultyType.easy: return 'EASY';
      case DifficultyType.hard: return 'HARD';
      case DifficultyType.nightmare: return 'NIGHTMARE';
    }
  }
}

class _FloatingArrow {
  final double x, y, speed, opacity, size;
  final ArrowDirection direction;
  _FloatingArrow({
    required this.x, required this.y, required this.direction,
    required this.speed, required this.opacity, required this.size,
  });
}

class _FloatingArrowsPainter extends CustomPainter {
  final List<_FloatingArrow> arrows;
  final double progress;
  final bool isDark;

  _FloatingArrowsPainter({required this.arrows, required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final a in arrows) {
      final t = (progress + a.speed * 10) % 1.0;
      final x = a.x * size.width;
      final y = (a.y + t * a.speed * 20) % 1.0 * size.height;
      paint.color = (isDark ? Colors.white : Colors.black).withAlpha((a.opacity * 255).toInt());
      canvas.save();
      canvas.translate(x, y);
      switch (a.direction) {
        case ArrowDirection.down:
          canvas.translate(a.size, a.size); canvas.rotate(pi); break;
        case ArrowDirection.left:
          canvas.translate(0, a.size); canvas.rotate(-pi / 2); break;
        case ArrowDirection.right:
          canvas.translate(a.size, 0); canvas.rotate(pi / 2); break;
        default: break;
      }
      final path = Path();
      path.moveTo(a.size / 2, 0);
      path.lineTo(0, a.size);
      path.lineTo(a.size / 2, a.size * 0.7);
      path.lineTo(a.size, a.size);
      path.close();
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_FloatingArrowsPainter old) => old.progress != progress || old.isDark != isDark;
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final bool value;
  final Color fg;
  final VoidCallback onToggle;

  const _SettingsRow({
    required this.label, required this.value,
    required this.fg, required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: fg, fontSize: 16, letterSpacing: 1)),
        GestureDetector(
          onTap: onToggle,
          child: Container(
            width: 48, height: 26,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              color: value ? fg.withAlpha(204) : fg.withAlpha(38),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: value
                        ? (fg == Colors.white ? Colors.black : Colors.white)
                        : fg.withAlpha(128),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}