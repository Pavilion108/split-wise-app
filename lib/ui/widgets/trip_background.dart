import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/country_themes.dart';

/// Full-screen animated background for the trip dashboard.
/// Shows a country-themed image with realistic multi-layer weather particles.
class TripBackground extends StatefulWidget {
  const TripBackground({
    super.key,
    required this.currencyCode,
    required this.child,
  });

  final String currencyCode;
  final Widget child;

  @override
  State<TripBackground> createState() => _TripBackgroundState();
}

class _TripBackgroundState extends State<TripBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final _ParticleSimulation _simulation;

  @override
  void initState() {
    super.initState();
    _simulation = _ParticleSimulation();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // ~60fps
    )..addListener(() {
        _simulation.tick();
        setState(() {});
      });
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CountryThemes.forCurrency(widget.currencyCode);
    if (theme == null) return widget.child;

    return Stack(
      children: [
        // Layer 1: High-quality country image with parallax blur
        Positioned.fill(
          child: _CachedNetworkImage(
            url: theme.imageUrl,
            fallbackColors: theme.fallbackColors,
          ),
        ),
        // Layer 2: Atmospheric fog layer
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.25),
                  Colors.black.withValues(alpha: 0.65),
                ],
                stops: const [0.0, 0.35, 1.0],
              ),
            ),
          ),
        ),
        // Layer 3: Tinted atmosphere
        Positioned.fill(
          child: Container(color: theme.tintColor),
        ),
        // Layer 4: Animated weather particles
        if (theme.effectType != WeatherEffect.none)
          Positioned.fill(
            child: CustomPaint(
              painter: _RealisticWeatherPainter(
                effect: theme.effectType,
                simulation: _simulation,
                tintColor: theme.tintColor,
              ),
            ),
          ),
        // Layer 5: Vignette for depth
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                ],
                stops: const [0.5, 1.0],
              ),
            ),
          ),
        ),
        // Layer 6: Content
        Positioned.fill(child: widget.child),
      ],
    );
  }
}

/// Caches network images for fast repeated renders.
class _CachedNetworkImage extends StatelessWidget {
  const _CachedNetworkImage({required this.url, required this.fallbackColors});
  final String url;
  final List<Color> fallbackColors;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
      frameBuilder: (_, child, frame, __) {
        if (frame == null) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: fallbackColors,
              ),
            ),
          );
        }
        return child;
      },
      errorBuilder: (_, __, ___) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: fallbackColors,
          ),
        ),
      ),
    );
  }
}

/// Tracks particle positions and velocities for realistic motion.
class _ParticleSimulation {
  final _random = Random();
  final List<_Particle> _particles = [];
  double _time = 0;

  void tick() {
    _time += 0.016;
    for (final p in _particles) {
      p.x += p.vx;
      p.y += p.vy;
      p.vx += p.ax;
      p.vy += p.ay;
      p.rotation += p.rotationSpeed;
      p.alpha = (p.alpha - 0.001).clamp(0.0, 1.0);
      p.life -= 0.016;
    }
    _particles.removeWhere((p) => p.life <= 0 || p.y > 1200 || p.alpha <= 0);
  }

  void ensureCount(int target, WeatherEffect effect, double width, double height) {
    while (_particles.length < target) {
      _particles.add(_createParticle(effect, width, height));
    }
  }

  _Particle _createParticle(WeatherEffect effect, double w, double h) {
    final r = _random.nextDouble;
    switch (effect) {
      case WeatherEffect.rain:
        return _Particle(
          x: r() * w * 1.2 - w * 0.1,
          y: -20 - r() * 100,
          vx: -0.8 - r() * 1.5,
          vy: 12 + r() * 8,
          ax: -0.02,
          ay: 0.15,
          size: 1.0 + r() * 1.5,
          alpha: 0.15 + r() * 0.35,
          life: 3 + r() * 2,
          rotation: 0,
          rotationSpeed: 0,
          layer: r() < 0.3 ? 0 : (r() < 0.6 ? 1 : 2),
        );
      case WeatherEffect.snow:
        return _Particle(
          x: r() * w * 1.4 - w * 0.2,
          y: -10 - r() * 80,
          vx: sin(_time + r() * 6) * 1.2,
          vy: 0.8 + r() * 2.0,
          ax: 0,
          ay: 0.02,
          size: 1.5 + r() * 4,
          alpha: 0.3 + r() * 0.5,
          life: 6 + r() * 4,
          rotation: r() * 6.28,
          rotationSpeed: (r() - 0.5) * 0.05,
          layer: r() < 0.3 ? 0 : (r() < 0.6 ? 1 : 2),
        );
      case WeatherEffect.petals:
        return _Particle(
          x: r() * w * 1.2 - w * 0.1,
          y: -15 - r() * 60,
          vx: 1.5 + r() * 2.5,
          vy: 1.0 + r() * 2.5,
          ax: sin(_time * 2) * 0.1,
          ay: 0.05,
          size: 4 + r() * 6,
          alpha: 0.35 + r() * 0.45,
          life: 5 + r() * 4,
          rotation: r() * 6.28,
          rotationSpeed: (r() - 0.5) * 0.12,
          layer: r() < 0.3 ? 0 : (r() < 0.6 ? 1 : 2),
        );
      case WeatherEffect.leaves:
        return _Particle(
          x: r() * w * 1.3 - w * 0.15,
          y: -20 - r() * 80,
          vx: 2.0 + r() * 3.0,
          vy: 1.5 + r() * 2.0,
          ax: sin(_time + r() * 4) * 0.15,
          ay: 0.08,
          size: 5 + r() * 7,
          alpha: 0.4 + r() * 0.4,
          life: 4 + r() * 3,
          rotation: r() * 6.28,
          rotationSpeed: (r() - 0.5) * 0.15,
          layer: r() < 0.3 ? 0 : (r() < 0.6 ? 1 : 2),
        );
      case WeatherEffect.sand:
        return _Particle(
          x: -10 - r() * 60,
          y: r() * h,
          vx: 3.0 + r() * 5.0,
          vy: sin(_time * 3 + r() * 2) * 0.8,
          ax: 0.05,
          ay: 0,
          size: 0.8 + r() * 2,
          alpha: 0.1 + r() * 0.25,
          life: 4 + r() * 3,
          rotation: 0,
          rotationSpeed: 0,
          layer: r() < 0.3 ? 0 : (r() < 0.6 ? 1 : 2),
        );
      case WeatherEffect.aurora:
        return _Particle(
          x: r() * w,
          y: h * 0.1 + r() * h * 0.4,
          vx: 0.3 + r() * 0.5,
          vy: sin(_time + r() * 3) * 0.3,
          ax: 0,
          ay: 0,
          size: 30 + r() * 50,
          alpha: 0.08 + r() * 0.12,
          life: 8 + r() * 6,
          rotation: r() * 6.28,
          rotationSpeed: (r() - 0.5) * 0.02,
          layer: 1,
        );
      case WeatherEffect.fireflies:
        final cx = w / 2;
        final cy = h / 2;
        final angle = r() * 6.28;
        final dist = 50 + r() * min(w, h) * 0.35;
        return _Particle(
          x: cx + cos(angle) * dist,
          y: cy + sin(angle) * dist,
          vx: (r() - 0.5) * 1.2,
          vy: (r() - 0.5) * 1.2,
          ax: 0,
          ay: 0,
          size: 2 + r() * 3,
          alpha: 0.3 + r() * 0.6,
          life: 5 + r() * 8,
          rotation: 0,
          rotationSpeed: 0,
          layer: 1,
        );
      case WeatherEffect.none:
        return _Particle(x: 0, y: -9999, vx: 0, vy: 0, ax: 0, ay: 0, size: 0, alpha: 0, life: 0, rotation: 0, rotationSpeed: 0, layer: 0);
    }
  }

  List<_Particle> get particles => _particles;
  double get time => _time;
}

class _Particle {
  double x, y, vx, vy, ax, ay;
  double size, alpha, life;
  double rotation, rotationSpeed;
  int layer; // 0=far, 1=mid, 2=near

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.ax,
    required this.ay,
    required this.size,
    required this.alpha,
    required this.life,
    required this.rotation,
    required this.rotationSpeed,
    required this.layer,
  });
}

/// Paints realistic multi-layer weather particles with depth, blur, and wind.
class _RealisticWeatherPainter extends CustomPainter {
  _RealisticWeatherPainter({
    required this.effect,
    required this.simulation,
    required this.tintColor,
  });

  final WeatherEffect effect;
  final _ParticleSimulation simulation;
  final Color tintColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Ensure enough particles
    switch (effect) {
      case WeatherEffect.rain:
        simulation.ensureCount(120, effect, size.width, size.height);
        break;
      case WeatherEffect.snow:
        simulation.ensureCount(80, effect, size.width, size.height);
        break;
      case WeatherEffect.petals:
        simulation.ensureCount(50, effect, size.width, size.height);
        break;
      case WeatherEffect.leaves:
        simulation.ensureCount(40, effect, size.width, size.height);
        break;
      case WeatherEffect.sand:
        simulation.ensureCount(150, effect, size.width, size.height);
        break;
      case WeatherEffect.aurora:
        simulation.ensureCount(15, effect, size.width, size.height);
        break;
      case WeatherEffect.fireflies:
        simulation.ensureCount(35, effect, size.width, size.height);
        break;
      case WeatherEffect.none:
        return;
    }

    // Sort by layer for depth ordering
    final sorted = simulation.particles.toList()
      ..sort((a, b) => a.layer.compareTo(b.layer));

    for (final p in sorted) {
      switch (effect) {
        case WeatherEffect.rain:
          _drawRainDrop(canvas, p, size);
          break;
        case WeatherEffect.snow:
          _drawSnowflake(canvas, p, size);
          break;
        case WeatherEffect.petals:
          _drawPetal(canvas, p);
          break;
        case WeatherEffect.leaves:
          _drawLeaf(canvas, p);
          break;
        case WeatherEffect.sand:
          _drawSandGrain(canvas, p);
          break;
        case WeatherEffect.aurora:
          _drawAuroraWave(canvas, p, size);
          break;
        case WeatherEffect.fireflies:
          _drawFirefly(canvas, p);
          break;
        case WeatherEffect.none:
          break;
      }
    }
  }

  void _drawRainDrop(Canvas canvas, _Particle p, Size size) {
    final depthScale = [0.4, 0.7, 1.0][p.layer];
    final len = (12 + p.size * 10) * depthScale;
    final w = (0.8 + p.size * 0.6) * depthScale;

    final paint = Paint()
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.linear(
        Offset(p.x, p.y),
        Offset(p.x + p.vx * 2, p.y + len),
        [
          Colors.white.withValues(alpha: p.alpha * 0.1),
          Colors.white.withValues(alpha: p.alpha * depthScale),
          Colors.white.withValues(alpha: p.alpha * 0.3),
        ],
        [0.0, 0.4, 1.0],
      );

    canvas.drawLine(
      Offset(p.x, p.y),
      Offset(p.x + p.vx * 2, p.y + len),
      paint,
    );

    // Splash at bottom
    if (p.y > size.height * 0.92) {
      final splashPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..color = Colors.white.withValues(alpha: p.alpha * 0.3 * depthScale);
      canvas.drawCircle(
        Offset(p.x, size.height * 0.95),
        3 + (1 - (size.height - p.y) / (size.height * 0.08)) * 8,
        splashPaint,
      );
    }
  }

  void _drawSnowflake(Canvas canvas, _Particle p, Size size) {
    final depthScale = [0.35, 0.65, 1.0][p.layer];
    final r = p.size * depthScale;

    canvas.save();
    canvas.translate(p.x, p.y);
    canvas.rotate(p.rotation);

    // Outer glow
    final glowPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset.zero,
        r * 3,
        [
          Colors.white.withValues(alpha: p.alpha * 0.15 * depthScale),
          Colors.white.withValues(alpha: 0),
        ],
      );
    canvas.drawCircle(Offset.zero, r * 3, glowPaint);

    // Core
    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: p.alpha * depthScale);
    canvas.drawCircle(Offset.zero, r, corePaint);

    // Sparkle highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: p.alpha * 0.8 * depthScale);
    canvas.drawCircle(Offset(-r * 0.2, -r * 0.2), r * 0.35, highlightPaint);

    canvas.restore();
  }

  void _drawPetal(Canvas canvas, _Particle p) {
    final depthScale = [0.4, 0.7, 1.0][p.layer];

    canvas.save();
    canvas.translate(p.x, p.y);
    canvas.rotate(p.rotation);

    final paint = Paint()
      ..color = Color.lerp(
        const Color(0xFFFFB7C5),
        const Color(0xFFFF69B4),
        depthScale,
      )!.withValues(alpha: p.alpha * depthScale);

    // Realistic petal shape: overlapping ellipses
    final path = Path();
    final s = p.size * depthScale;

    // Main petal body
    path.moveTo(0, -s * 0.8);
    path.cubicTo(s * 0.6, -s * 0.6, s * 0.8, -s * 0.1, s * 0.3, s * 0.5);
    path.cubicTo(s * 0.1, s * 0.7, -s * 0.1, s * 0.7, -s * 0.3, s * 0.5);
    path.cubicTo(-s * 0.8, -s * 0.1, -s * 0.6, -s * 0.6, 0, -s * 0.8);

    canvas.drawPath(path, paint);

    // Vein line
    final veinPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = Colors.white.withValues(alpha: p.alpha * 0.3 * depthScale);
    canvas.drawLine(Offset(0, -s * 0.6), Offset(0, s * 0.3), veinPaint);

    canvas.restore();
  }

  void _drawLeaf(Canvas canvas, _Particle p) {
    final depthScale = [0.4, 0.7, 1.0][p.layer];

    canvas.save();
    canvas.translate(p.x, p.y);
    canvas.rotate(p.rotation);

    final s = p.size * depthScale;
    final colors = [
      [const Color(0xFF8B4513), const Color(0xFFD2691E), const Color(0xFFDAA520)],
      [const Color(0xFFB22222), const Color(0xFFCD853F), const Color(0xFFDAA520)],
      [const Color(0xFF228B22), const Color(0xFF6B8E23), const Color(0xFF9ACD32)],
    ];
    final palette = colors[p.layer];

    final paint = Paint()
      ..color = palette[0].withValues(alpha: p.alpha * depthScale);

    // Leaf shape
    final path = Path();
    path.moveTo(0, -s);
    path.cubicTo(s * 0.5, -s * 0.5, s * 0.7, 0, s * 0.3, s * 0.6);
    path.quadraticBezierTo(0, s * 0.8, -s * 0.3, s * 0.6);
    path.cubicTo(-s * 0.7, 0, -s * 0.5, -s * 0.5, 0, -s);
    canvas.drawPath(path, paint);

    // Center vein
    final veinPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = palette[1].withValues(alpha: p.alpha * 0.5 * depthScale);
    canvas.drawLine(Offset(0, -s * 0.8), Offset(0, s * 0.5), veinPaint);

    canvas.restore();
  }

  void _drawSandGrain(Canvas canvas, _Particle p) {
    final depthScale = [0.3, 0.6, 1.0][p.layer];
    final paint = Paint()
      ..color = Color.lerp(
        const Color(0xFFC2B280),
        const Color(0xFFDEB887),
        depthScale,
      )!.withValues(alpha: p.alpha * depthScale);

    canvas.drawCircle(Offset(p.x, p.y), p.size * depthScale, paint);
  }

  void _drawAuroraWave(Canvas canvas, _Particle p, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = p.size
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    final path = Path();
    path.moveTo(p.x - 100, p.y);
    for (double dx = 0; dx <= 200; dx += 5) {
      final x = p.x - 100 + dx;
      final y = p.y + sin((dx / 200) * pi * 2 + simulation.time * 1.5) * 30;
      path.lineTo(x, y);
    }

    final hue = (simulation.time * 20 + p.x) % 360;
    paint.color = HSLColor.fromAHSL(p.alpha, hue, 0.7, 0.6).toColor();
    canvas.drawPath(path, paint);
  }

  void _drawFirefly(Canvas canvas, _Particle p) {
    final pulse = (sin(simulation.time * 3 + p.x * 0.01) + 1) / 2;
    final brightness = 0.3 + pulse * 0.7;

    canvas.save();
    canvas.translate(p.x, p.y);

    // Outer glow (large, soft)
    final outerGlow = Paint()
      ..shader = ui.Gradient.radial(
        Offset.zero,
        p.size * 8,
        [
          Colors.amberAccent.withValues(alpha: p.alpha * brightness * 0.2),
          Colors.amberAccent.withValues(alpha: 0),
        ],
      );
    canvas.drawCircle(Offset.zero, p.size * 8, outerGlow);

    // Mid glow
    final midGlow = Paint()
      ..shader = ui.Gradient.radial(
        Offset.zero,
        p.size * 4,
        [
          Colors.yellowAccent.withValues(alpha: p.alpha * brightness * 0.4),
          Colors.yellowAccent.withValues(alpha: 0),
        ],
      );
    canvas.drawCircle(Offset.zero, p.size * 4, midGlow);

    // Core (bright center)
    final core = Paint()
      ..color = Colors.white.withValues(alpha: p.alpha * brightness);
    canvas.drawCircle(Offset.zero, p.size * 0.8, core);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_RealisticWeatherPainter old) => true;
}
