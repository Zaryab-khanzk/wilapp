import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../colors/app_colors.dart';

class AppLoader extends StatefulWidget {
  const AppLoader({super.key, this.size = 48, this.color = AppColors.primary});

  final double size;
  final Color color;

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotSize = widget.size * 0.18;
    final gap = widget.size * 0.12;

    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  if (index > 0) {
                    return Padding(
                      padding: EdgeInsets.only(left: gap),
                      child: _buildDot(index, dotSize),
                    );
                  }
                  return _buildDot(index, dotSize);
                }),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDot(int index, double dotSize) {
    final phase = (_controller.value + index * 0.2) % 1.0;
    final pulse = 0.5 - 0.5 * math.cos(phase * math.pi * 2);
    final scale = 0.72 + (pulse * 0.46);
    final opacity = 0.35 + (pulse * 0.65);
    final dotColor = Color.lerp(
      widget.color,
      index == 1 ? AppColors.glowCyan : AppColors.glowPurple,
      0.16 + (index * 0.07),
    )!;

    return Transform.scale(
      scale: scale,
      child: Container(
        width: dotSize,
        height: dotSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: dotColor.withValues(alpha: opacity),
          boxShadow: [
            BoxShadow(
              color: AppColors.glowPurple.withValues(
                alpha: 0.18 + (pulse * 0.26),
              ),
              blurRadius: widget.size * 0.18,
              spreadRadius: widget.size * 0.01,
            ),
            BoxShadow(
              color: AppColors.glowCyan.withValues(
                alpha: 0.14 + (pulse * 0.18),
              ),
              blurRadius: widget.size * 0.22,
              spreadRadius: widget.size * 0.006,
            ),
          ],
        ),
      ),
    );
  }
}
