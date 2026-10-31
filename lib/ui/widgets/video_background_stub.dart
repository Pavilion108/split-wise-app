import 'dart:async';
import 'package:flutter/material.dart';

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
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        widget.onLoopComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
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
        widget.child,
      ],
    );
  }
}
