import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AirplaneBranding extends StatelessWidget {
  final double airplaneSize;
  final double textSize;

  const AirplaneBranding({
    super.key,
    this.airplaneSize = 64,
    this.textSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: airplaneSize + 20,
          width: airplaneSize * 2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Airplane flies in from top-right and lands
              Icon(
                Icons.flight,
                size: airplaneSize,
                color: const Color(0xFF667eea),
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 600.ms)
                  .then(delay: 100.ms)
                  .slide(
                    begin: const Offset(1.5, -2.0),
                    end: Offset.zero,
                    duration: 800.ms,
                    curve: Curves.easeOutCubic,
                  )
                  .then(delay: 200.ms)
                  .rotate(
                    begin: -0.4,
                    end: 0.0,
                    duration: 600.ms,
                    curve: Curves.easeOutBack,
                  ),
              // Trail dots that fade in behind the plane
              ...List.generate(5, (i) {
                final delay = 600 + i * 80;
                return Positioned(
                  right: 20 + i * 14.0,
                  top: 10 + i * 12.0,
                  child: Container(
                    width: 4 - i * 0.5,
                    height: 4 - i * 0.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.3 - i * 0.05),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: delay), duration: 300.ms)
                    .then(delay: 200.ms)
                    .fadeOut(duration: 400.ms);
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Spliti5',
          style: TextStyle(
            fontSize: textSize,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        )
            .animate()
            .fadeIn(delay: 1200.ms, duration: 600.ms)
            .scale(
              begin: const Offset(0.85, 0.85),
              end: const Offset(1.0, 1.0),
              duration: 500.ms,
              curve: Curves.easeOutBack,
            )
            .slideY(begin: 0.1, end: 0, duration: 500.ms),
      ],
    );
  }
}
