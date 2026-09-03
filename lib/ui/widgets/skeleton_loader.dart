import 'package:flutter/material.dart';
import '../../core/theme.dart';

class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({super.key, this.width, this.height, this.borderRadius});

  final double? width;
  final double? height;
  final double? borderRadius;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height ?? 16,
          decoration: BoxDecoration(
            color: AppColors.cardBorder.withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius ?? 8),
          ),
        );
      },
    );
  }
}

class OverviewSkeleton extends StatelessWidget {
  const OverviewSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary card skeleton
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonLoader(width: 140, height: 14),
              const SizedBox(height: 8),
              const SkeletonLoader(width: 180, height: 28),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SkeletonLoader(width: 70, height: 12),
                        const SizedBox(height: 4),
                        const SkeletonLoader(width: 100, height: 18),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SkeletonLoader(width: 70, height: 12),
                        const SizedBox(height: 4),
                        const SkeletonLoader(width: 100, height: 18),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const SkeletonLoader(width: double.infinity, height: 48, borderRadius: 12),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Balances table skeleton
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonLoader(width: 100, height: 18),
              const SizedBox(height: 16),
              ...List.generate(
                3,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const SkeletonLoader(width: 80, height: 14),
                      const Spacer(),
                      const SkeletonLoader(width: 60, height: 14),
                      const SizedBox(width: 16),
                      const SkeletonLoader(width: 60, height: 14),
                      const SizedBox(width: 16),
                      const SkeletonLoader(width: 60, height: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
