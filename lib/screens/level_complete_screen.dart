import 'dart:math';
import 'package:flutter/material.dart';
import '../core/game_state.dart';

class LevelCompleteScreen extends StatefulWidget {
  final GameState gameState;
  final VoidCallback onNext;
  const LevelCompleteScreen({super.key, required this.gameState, required this.onNext});

  @override
  State<LevelCompleteScreen> createState() => _LevelCompleteScreenState();
}

class _LevelCompleteScreenState extends State<LevelCompleteScreen>
    with TickerProviderStateMixin {
  late AnimationController _smokeController;
  late AnimationController _fadeController;
  late Animation<double> _fadeIn;
  final List<_SmokeParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _smokeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))..forward();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400))..forward();
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _generateParticles();
  }

  void _generateParticles() {
    for (int i = 0; i < 70; i++) {
      final fromLeft = _random.nextBool();
      _particles.add(_SmokeParticle(
        x: fromLeft ? _random.nextDouble() * 100 : 1.0 - _random.nextDouble() * 0.2,
        speedX: (fromLeft ? 1 : -1) * (_random.nextDouble() * 1.5 + 0.5),
        speedY: -(_random.nextDouble() * 5 + 2),
        size: _random.nextDouble() * 28 + 8,
        opacity: _random.nextDouble() * 0.5 + 0.2,
        delay: _random.nextDouble() * 0.4,
        fromLeft: fromLeft,
      ));
    }
  }

  @override
  void dispose() {
    _smokeController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.gameState.isDarkTheme;
    final bg = isDark
        ? const Color(0xFF0D0D1A).withAlpha(242)
        : const Color(0xFFF5F5F5).withAlpha(242);
    final fg = isDark ? Colors.white : Colors.black;
    final screenSize = MediaQuery.of(context).size;

    return FadeTransition(
      opacity: _fadeIn,
      child: Container(
        color: bg,
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _smokeController,
              builder: (context, _) => CustomPaint(
                painter: _SmokePainter(
                    particles: _particles,
                    progress: _smokeController.value,
                    isDark: isDark,
                    screenSize: screenSize),
                size: Size.infinite,
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('✓',
                      style: TextStyle(color: fg, fontSize: 80, fontWeight: FontWeight.w100)),
                  const SizedBox(height: 16),
                  Text('LEVEL COMPLETE',
                      style: TextStyle(
                          color: fg, fontSize: 26,
                          fontWeight: FontWeight.bold, letterSpacing: 4)),
                  const SizedBox(height: 8),
                  Text('Level ${widget.gameState.currentLevel}',
                      style: TextStyle(color: fg.withAlpha(128), fontSize: 14, letterSpacing: 2)),
                  const SizedBox(height: 48),
                  GestureDetector(
                    onTap: widget.onNext,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                      decoration: BoxDecoration(
                          border: Border.all(color: fg.withAlpha(128)),
                          borderRadius: BorderRadius.circular(40)),
                      child: Text('NEXT LEVEL',
                          style: TextStyle(
                              color: fg, fontSize: 16,
                              fontWeight: FontWeight.bold, letterSpacing: 3)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmokeParticle {
  final double x, speedX, speedY, size, opacity, delay;
  final bool fromLeft;
  _SmokeParticle({
    required this.x, required this.speedX, required this.speedY,
    required this.size, required this.opacity, required this.delay,
    required this.fromLeft,
  });
}

class _SmokePainter extends CustomPainter {
  final List<_SmokeParticle> particles;
  final double progress;
  final bool isDark;
  final Size screenSize;

  _SmokePainter({required this.particles, required this.progress,
      required this.isDark, required this.screenSize});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress - p.delay).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final x = p.fromLeft
          ? p.x + p.speedX * t * 80
          : size.width * p.x - p.speedX * t * 80;
      final y = size.height - t * p.speedY * -40;
      final fade = t < 0.6 ? t / 0.6 : (1.0 - t) / 0.4;
      final paint = Paint()
        ..color = (isDark ? Colors.white : Colors.black)
            .withAlpha((p.opacity * fade * 0.6 * 255).toInt())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(Offset(x, y), p.size * (0.4 + t * 0.6), paint);
    }
  }

  @override
  bool shouldRepaint(_SmokePainter old) => old.progress != progress;
}