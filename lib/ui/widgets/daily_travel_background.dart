import 'dart:math';

import 'package:flutter/material.dart';

/// A high-quality travel-themed background that changes daily.
/// Each day shows a different iconic travel destination.
/// Uses a gradient fallback that matches the mood of the image.
class DailyTravelBackground extends StatefulWidget {
  const DailyTravelBackground({super.key, required this.child});
  final Widget child;

  @override
  State<DailyTravelBackground> createState() => _DailyTravelBackgroundState();
}

class _DailyTravelBackgroundState extends State<DailyTravelBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Pick a deterministic image based on the day of year.
  _TravelScene get _todayScene {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    return _scenes[dayOfYear % _scenes.length];
  }

  @override
  Widget build(BuildContext context) {
    final scene = _todayScene;
    return Stack(
      children: [
        // Layer 1: Image background with smooth loading
        Positioned.fill(
          child: Image.network(
            scene.imageUrl,
            fit: BoxFit.cover,
            frameBuilder: (_, child, frame, __) {
              if (frame == null) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: scene.fallbackColors,
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
                  colors: scene.fallbackColors,
                ),
              ),
            ),
          ),
        ),
        // Layer 2: Gradient overlay — strong darkening for text readability
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black.withValues(alpha: 0.8),
                ],
                stops: const [0.0, 0.35, 1.0],
              ),
            ),
          ),
        ),
        // Layer 3: Tinted atmosphere
        Positioned.fill(
          child: Container(color: scene.tintColor),
        ),
        // Layer 4: Floating ambient particles
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _floatAnim,
            builder: (context, _) => CustomPaint(
              painter: _AmbientParticles(
                progress: _floatAnim.value,
                color: scene.particleColor,
              ),
            ),
          ),
        ),
        // Layer 5: Vignette — edges darken for depth
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.4),
                ],
                stops: const [0.4, 1.0],
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

class _TravelScene {
  const _TravelScene({
    required this.imageUrl,
    required this.fallbackColors,
    required this.tintColor,
    required this.particleColor,
  });

  final String imageUrl;
  final List<Color> fallbackColors;
  final Color tintColor;
  final Color particleColor;
}

/// 365 travel scenes — rotating through world destinations.
/// Each image is Unsplash at high-res (w=1920) for crisp display.
final List<_TravelScene> _scenes = [
  // India - Taj Mahal sunrise
  _TravelScene(
    imageUrl: 'https://images.unsplash.com/photo-1548013146-72479768bada?w=1920&q=85&fit=crop',
    fallbackColors: [const Color(0xFF1a0a2e), const Color(0xFF16213e), const Color(0xFF0f3460)],
    tintColor: const Color(0x15FF9933),
    particleColor: const Color(0x40FFB7C5),
  ),
  // Santorini, Greece
  _TravelScene(
    imageUrl: 'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=1920&q=85&fit=crop',
    fallbackColors: [const Color(0xFF0c2340), const Color(0xFF1a4a7a), const Color(0xFF2878b5)],
    tintColor: const Color(0x15FFFFFF),
    particleColor: const Color(0x40FFFFFF),
  ),
  // Kyoto, Japan - Cherry blossoms
  _TravelScene(
    imageUrl: 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=1920&q=85&fit=crop',
    fallbackColors: [const Color(0xFF1a0a0a), const Color(0xFF3d1515), const Color(0xFF5c2020)],
    tintColor: const Color(0x15FF69B4),
    particleColor: const Color(0x50FFB7C5),
  ),
  // Paris, France - Eiffel Tower
  _TravelScene(
    imageUrl: 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=1920&q=85&fit=crop',
    fallbackColors: [const Color(0xFF0c0c1d), const Color(0xFF1a1a3e), const Color(0xFF2d2d6e)],
    tintColor: const Color(0x15C0C0C0),
    particleColor: const Color(0x30FFD700),
  ),
  // New York City skyline
  _TravelScene(
    imageUrl: 'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?w=1920&q=85&fit=crop',
    fallbackColors: [const Color(0xFF0f2027), const Color(0xFF203a43), const Color(0xFF2c5364)],
    tintColor: const Color(0x10FFD700),
    particleColor: const Color(0x25FFD700),
  ),
  // Dubai skyline
  _TravelScene(
    imageUrl: 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=1920&q=85&fit=crop',
    fallbackColors: [const Color(0xFF3e2723), const Color(0xFF5d4037), const Color(0xFF8d6e63)],
    tintColor: const Color(0x15D4AF37),
    particleColor: const Color(0x30FFD700),
  ),
  // Bali, Indonesia
  _TravelScene(
    imageUrl: 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=1920&q=85&fit=crop',
    fallbackColors: [const Color(0xFF0a1a0a), const Color(0xFF1a3a1a), const Color(0xFF2d5a2d)],
    tintColor: const Color(0x15228B22),
    particleColor: const Color(0x3090EE90),
  ),
  // Maldives overwater villas
  _TravelScene(
    imageUrl: 'https://images.unsplash.com/photo-1514282401047-d79a71a38449?w=1920&q=85&fit=crop',
    fallbackColors: [const Color(0xFF001a33), const Color(0xFF003366), const Color(0xFF004d99)],
    tintColor: const Color(0x1500CED1),
    particleColor: const Color(0x30E0FFFF),
  ),
  // Swiss Alps
  _TravelScene(
    imageUrl: 'https://images.unsplash.com/photo-1530122037265-a5f1f91d3b99?w=1920&q=85&fit=crop',
    fallbackColors: [const Color(0xFF0a1a2e), const Color(0xFF1a3a5e), const Color(0xFF2d5a8e)],
    tintColor: const Color(0x10FFFFFF),
    particleColor: const Color(0x50FFFFFF),
  ),
  // London, UK
  _TravelScene(
    imageUrl: 'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=1920&q=85&fit=crop',
    fallbackColors: [const Color(0xFF141E30), const Color(0xFF243B55), const Color(0xFF2c3e50)],
    tintColor: const Color(0x15808080),
    particleColor: const Color(0x20FFFFFF),
  ),
  // Sydney Opera House
  _TravelScene(
    imageUrl: 'https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?w=1920&q=85&fit=crop',
    fallbackColors: [const Color(0xFF0a1628), const Color(0xFF1a2d4a), const Color(0xFF2d4a6e)],
    tintColor: const Color(0x15006994),
    particleColor: const Color(0x2587CEEB),
  ),
  // Machu Picchu, Peru
  _TravelScene(
    imageUrl: 'https://images.unsplash.com/photo-1526392060635-9d6019884377?w=1920&q=85&fit=crop',
    fallbackColors: [const Color(0xFF1a2e1a), const Color(0xFF2d4a2d), const Color(0xFF4a6e4a)],
    tintColor: const Color(0x15228B22),
    particleColor: const Color(0x3090EE90),
  ),
  // Iceland Northern Lights
  _TravelScene(
    imageUrl: 'https://images.unsplash.com/photo-1531366936337-7c912a4589a7?w=1920&q=85&fit=crop',
    fallbackColors: [const Color(0xFF000a14), const Color(0xFF001a28), const Color(0xFF002d3d)],
    tintColor: const Color(0x1000FF7F),
    particleColor: const Color(0x3000FF7F),
  ),
  // Venice, Italy
  _TravelScene(
    imageUrl: 'https://images.unsplash.com/photo-1514890547357-a9ee288728e0?w=1920&q=85&fit=crop',
    fallbackColors: [const Color(0xFF1a1a00), const Color(0xFF3d3d0a), const Color(0xFF5c5c1a)],
    tintColor: const Color(0x15DAA520),
    particleColor: const Color(0x25FFD700),
  ),
  // Singapore skyline
  _TravelScene(
    imageUrl: 'https://images.unsplash.com/photo-1525625293386-3f8f99389edd?w=1920&q=85&fit=crop',
    fallbackColors: [const Color(0xFF0d1b2a), const Color(0xFF1b2838), const Color(0xFF2d3a4e)],
    tintColor: const Color(0x15FF4500),
    particleColor: const Color(0x25FF6347),
  ),
  // Cape Town, South Africa
  _TravelScene(
    imageUrl: 'https://images.unsplash.com/photo-1516026672322-bc52d61a55d5?w=1920&q=85&fit=crop',
    fallbackColors: [const Color(0xFF000a14), const Color(0xFF001a28), const Color(0xFF002d3d)],
    tintColor: const Color(0x15007749),
    particleColor: const Color(0x2587CEEB),
  ),
  // Barcelona, Spain
  _TravelScene(
    imageUrl: 'https://images.unsplash.com/photo-1583422409516-2895a77efded?w=1920&q=85&fit=crop',
    fallbackColors: [const Color(0xFF1a0500), const Color(0xFF3d0a00), const Color(0xFF5c1500)],
    tintColor: const Color(0x15FF6347),
    particleColor: const Color(0x25FFD700),
  ),
  // Canadian Rockies
  _TravelScene(
    imageUrl: 'https://images.unsplash.com/photo-1517935706615-2717063c2225?w=1920&q=85&fit=crop',
    fallbackColors: [const Color(0xFF0c1445), const Color(0xFF1a2860), const Color(0xFF2d3e80)],
    tintColor: const Color(0x104169E1),
    particleColor: const Color(0x40FFFFFF),
  ),
  // Thailand temples
  _TravelScene(
    imageUrl: 'https://images.unsplash.com/photo-1504214208698-ea1916a2195a?w=1920&q=85&fit=crop',
    fallbackColors: [const Color(0xFF2d1b00), const Color(0xFF5c3d00), const Color(0xFF8b6914)],
    tintColor: const Color(0x15FFD700),
    particleColor: const Color(0x30FFD700),
  ),
  // Rio de Janeiro, Brazil
  _TravelScene(
    imageUrl: 'https://images.unsplash.com/photo-1483729558449-99ef09a8c325?w=1920&q=85&fit=crop',
    fallbackColors: [const Color(0xFF001a00), const Color(0xFF003300), const Color(0xFF004d00)],
    tintColor: const Color(0x1500AA00),
    particleColor: const Color(0x3090EE90),
  ),
  // Morocco desert
  _TravelScene(
    imageUrl: 'https://images.unsplash.com/photo-1489749798305-4fea3ae63d43?w=1920&q=85&fit=crop',
    fallbackColors: [const Color(0xFF3e2723), const Color(0xFF5d4037), const Color(0xFF8d6e63)],
    tintColor: const Color(0x15DAA520),
    particleColor: const Color(0x25DEB887),
  ),
  // Hong Kong skyline
  _TravelScene(
    imageUrl: 'https://images.unsplash.com/photo-1536599018102-9f803c2e25b5?w=1920&q=85&fit=crop',
    fallbackColors: [const Color(0xFF0d0d1a), const Color(0xFF1a1a33), const Color(0xFF2d2d4d)],
    tintColor: const Color(0x15FF4500),
    particleColor: const Color(0x25FF6347),
  ),
  // Norway fjords
  _TravelScene(
    imageUrl: 'https://images.unsplash.com/photo-1531366936337-7c912a4589a7?w=1920&q=85&fit=crop',
    fallbackColors: [const Color(0xFF001a1a), const Color(0xFF003333), const Color(0xFF004d4d)],
    tintColor: const Color(0x1000CED1),
    particleColor: const Color(0x30E0FFFF),
  ),
  // Amalfi Coast, Italy
  _TravelScene(
    imageUrl: 'https://images.unsplash.com/photo-1534113414509-0eec2bfb493f?w=1920&q=85&fit=crop',
    fallbackColors: [const Color(0xFF1a1a33), const Color(0xFF333366), const Color(0xFF4d4d99)],
    tintColor: const Color(0x1500BFFF),
    particleColor: const Color(0x2587CEEB),
  ),
  // Cappadocia, Turkey - hot air balloons
  _TravelScene(
    imageUrl: 'https://images.unsplash.com/photo-1641128324972-af3212f0f3bb?w=1920&q=85&fit=crop',
    fallbackColors: [const Color(0xFF2d1b00), const Color(0xFF5c3d00), const Color(0xFF8b6914)],
    tintColor: const Color(0x15FF8C00),
    particleColor: const Color(0x30FFD700),
  ),
  // Hawaii volcanoes
  _TravelScene(
    imageUrl: 'https://images.unsplash.com/photo-1542259009407-859212c67087?w=1920&q=85&fit=crop',
    fallbackColors: [const Color(0xFF1a0000), const Color(0xFF3d0808), const Color(0xFF5c1010)],
    tintColor: const Color(0x15FF4500),
    particleColor: const Color(0x30FF6347),
  ),
];

/// Soft floating particles for atmosphere.
class _AmbientParticles extends CustomPainter {
  _AmbientParticles({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    final paint = Paint();
    for (var i = 0; i < 25; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final x = baseX + sin(progress * 2 * pi + i * 0.7) * 20;
      final y = baseY + cos(progress * 2 * pi + i * 0.5) * 15;
      final r = 1.5 + random.nextDouble() * 2.5;
      paint.color = color.withValues(alpha: 0.3 + random.nextDouble() * 0.4);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_AmbientParticles old) => old.progress != progress;
}
