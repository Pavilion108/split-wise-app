import 'dart:async';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Full-page video background that plays once then freezes.
/// After [duration] seconds, calls [onLoopComplete].
class VideoBackground extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final VoidCallback? onLoopComplete;

  const VideoBackground({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 10),
    this.onLoopComplete,
  });

  @override
  State<VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<VideoBackground> {
  web.HTMLVideoElement? _videoElement;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _injectVideo();
    });
  }

  void _injectVideo() {
    if (!mounted) return;

    // Remove any existing video background
    final existing = web.document.getElementById('spliti5-video-bg');
    existing?.remove();

    final video = web.HTMLVideoElement()
      ..id = 'spliti5-video-bg'
      ..autoplay = true
      ..loop = false
      ..muted = true
      ..playsInline = true
      ..setAttribute('playsinline', '')
      ..style.cssText = 'position:fixed;top:0;left:0;width:100vw;height:100vh;object-fit:cover;z-index:0;pointer-events:none;';

    // WebM source (Chrome, Firefox)
    final webmSource = web.HTMLSourceElement()
      ..src = 'assets/assets/animations/airplane_bg.webm'
      ..type = 'video/webm';
    video.appendChild(webmSource);

    // MP4 source (Safari fallback)
    final mp4Source = web.HTMLSourceElement()
      ..src = 'assets/assets/animations/airplane_bg.mp4'
      ..type = 'video/mp4';
    video.appendChild(mp4Source);

    web.document.body?.appendChild(video);
    _videoElement = video;

    video.play();

    // After duration, freeze the video and notify
    _timer = Timer(widget.duration, () {
      if (mounted) {
        video.pause();
        widget.onLoopComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _videoElement?.pause();
    _videoElement?.remove();
    _videoElement = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient fallback while video loads
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0a0a1a), Color(0xFF0f0c29), Color(0xFF0a0a1a)],
            ),
          ),
        ),
        // Dark overlay for text readability over video
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.4),
                Colors.black.withValues(alpha: 0.55),
                Colors.black.withValues(alpha: 0.4),
              ],
            ),
          ),
        ),
        // Content on top
        widget.child,
      ],
    );
  }
}
