import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../core/game_state.dart';

class LaserButton extends StatefulWidget {
  final GameState gameState;
  final ValueNotifier<int> tapNotifier;

  const LaserButton({
    super.key,
    required this.gameState,
    required this.tapNotifier,
  });

  @override
  State<LaserButton> createState() => _LaserButtonState();
}

class _LaserButtonState extends State<LaserButton> with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    widget.tapNotifier.addListener(_onGridTap);
    widget.gameState.addListener(_onGameStateChange);
    _resetTimer();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _shakeController.dispose();
    widget.tapNotifier.removeListener(_onGridTap);
    widget.gameState.removeListener(_onGameStateChange);
    super.dispose();
  }

  void _onGridTap() {
    _resetTimer();
  }

  void _onGameStateChange() {
    // If the user turns the lasers ON, stop shaking immediately.
    if (widget.gameState.showGuideLines) {
      _idleTimer?.cancel();
      _shakeController.reset();
    } else {
      _resetTimer();
    }
  }

  void _resetTimer() {
    _idleTimer?.cancel();
    _shakeController.reset();

    if (widget.gameState.showGuideLines) return;

    _idleTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && !widget.gameState.showGuideLines) {
        _shakeController.forward(from: 0.0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_shakeController, widget.gameState]),
      builder: (context, child) {
        final isOn = widget.gameState.showGuideLines;
        
        // Shake physics: A combination of translation and slight rotation
        final t = _shakeController.value;
        final shakeOffset = sin(t * pi * 10) * 6.0; // 5 back-and-forth shakes per cycle
        final shakeAngle = sin(t * pi * 10) * 0.1;

        Widget button = GestureDetector(
          onTap: widget.gameState.toggleGuideLines,
          child: Container(
            width: 76,
            height: 100, // Increased vertical oval size
            decoration: BoxDecoration(
              color: const Color(0xFF00B0FF), // Bright Blue always
              borderRadius: const BorderRadius.all(Radius.elliptical(38, 50)), // Perfect egg curve for 76x100
              boxShadow: _shakeController.isAnimating
                  ? [
                      BoxShadow(
                        color: const Color(0xFF00B0FF).withOpacity(0.6), // Aura only during shake
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
              border: Border.all(
                color: isOn ? Colors.white : Colors.transparent,
                width: 2,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.grid_3x3, // The # (cross) logo
                color: Colors.white, // Always white
                size: 42,
              ),
            ),
          ),
        );

        if (_shakeController.isAnimating) {
          button = Transform.translate(
            offset: Offset(shakeOffset, 0),
            child: Transform.rotate(
              angle: shakeAngle,
              child: button,
            ),
          );
        }

        return button;
      },
    );
  }
}
