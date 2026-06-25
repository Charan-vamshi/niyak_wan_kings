import 'dart:math';
import 'package:flutter/material.dart';
import '../core/game_state.dart';

class LevelCompleteScreen extends StatefulWidget {
  final GameState gameState;
  final VoidCallback onNext;

  const LevelCompleteScreen({
    super.key,
    required this.gameState,
    required this.onNext,
  });

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
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    _generateParticles();
    _smokeController.forward();
    _fadeController.forward();
  }

  void _generateParticles() {
    final size = WidgetsBinding.instance.platformDispatcher.views.first.physicalSize /
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

    for (int i = 0; i < 60; i++) {
      final fromLeft = _random.nextBool();
      _particles.add(_SmokeParticle(
        x: fromLeft
            ? _random.nextDouble() * 80
            : size.width - _random.nextDouble() * 80,
        startY: size.height,
        speedX: (fromLeft ? 1 : -1) *
            (_random.nextDouble() * 2 + 0.5),
        speedY: -(_random.nextDouble() * 4 + 2),
        size: _random.nextDouble() * 30 + 10,
        opacity: _random.nextDouble() * 0.6 + 0.2,
        delay: _random.nextDouble() * 0.5,
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
        ? const Color(0xFF0D0D1A).withOpacity(0.95)
        : const Color(0xFFF5F5F5).withOpacity(0.95);
    final fg = isDark ? Colors.white : Colors.black;

    return FadeTransition(
      opacity: _fadeIn,
      child: Container(
        color: bg,
        child: Stack(
          children: [
            // Smoke particles
            AnimatedBuilder(
              animation: _smokeController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _SmokePainter(
                    particles: _particles,
                    progress: _smokeController.value,
                    isDark: isDark,
                  ),
                  size: Size.infinite,
                );
              },
            ),

            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '✓',
                    style: TextStyle(
                      color: fg,
                      fontSize: 72,
                      fontWeight: FontWeight.w100,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'LEVEL COMPLETE',
                    style: TextStyle(
                      color: fg,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Level ${widget.gameState.currentLevel}',
                    style: TextStyle(
                      color: fg.withOpacity(0.5),
                      fontSize: 14,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 48),
                  GestureDetector(
                    onTap: widget.onNext,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 48, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: fg.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Text(
                        'NEXT LEVEL',
                        style: TextStyle(
                          color: fg,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                        ),
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
  }
}

class _SmokeParticle {
  final double x;
  final double startY;
  final double speedX;
  final double speedY;
  final double size;
  final double opacity;
  final double delay;

  _SmokeParticle({
    required this.x,
    required this.startY,
    required this.speedX,
    required this.speedY,
    required this.size,
    required this.opacity,
    required this.delay,
  });
}

class _SmokePainter extends CustomPainter {
  final List<_SmokeParticle> particles;
  final double progress;
  final bool isDark;

  _SmokePainter({
    required this.particles,
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress - p.delay).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final x = p.x + p.speedX * t * 100;
      final y = p.startY + p.speedY * t * 200;
      final fade = t < 0.7 ? t / 0.7 : (1.0 - t) / 0.3;

      final paint = Paint()
        ..color = (isDark ? Colors.white : Colors.black)
            .withOpacity(p.opacity * fade * 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

      canvas.drawCircle(Offset(x, y), p.size * (0.5 + t * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_SmokePainter old) => old.progress != progress;
}