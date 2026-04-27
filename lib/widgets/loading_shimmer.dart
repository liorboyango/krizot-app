import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Shimmer loading placeholder for tables and cards.
///
/// Provides a pulsing animation to indicate loading state.
class LoadingShimmer extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const LoadingShimmer({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius,
  });

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
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
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius:
                  widget.borderRadius ?? BorderRadius.circular(4),
            ),
          ),
        );
      },
    );
  }
}

/// Shimmer placeholder for a table row.
class TableRowShimmer extends StatelessWidget {
  const TableRowShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          const LoadingShimmer(width: 80, height: 14),
          const SizedBox(width: 16),
          const Expanded(child: LoadingShimmer(height: 14)),
          const SizedBox(width: 16),
          const Expanded(child: LoadingShimmer(height: 14)),
          const SizedBox(width: 16),
          const LoadingShimmer(width: 40, height: 14),
          const SizedBox(width: 16),
          LoadingShimmer(
            width: 60,
            height: 22,
            borderRadius: BorderRadius.circular(20),
          ),
          const SizedBox(width: 16),
          const LoadingShimmer(width: 60, height: 14),
        ],
      ),
    );
  }
}

/// Shimmer placeholder for a station card.
class StationCardShimmer extends StatelessWidget {
  const StationCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const LoadingShimmer(width: 70, height: 20),
              const SizedBox(width: 12),
              const Expanded(child: LoadingShimmer(height: 16)),
              const SizedBox(width: 12),
              LoadingShimmer(
                width: 60,
                height: 22,
                borderRadius: BorderRadius.circular(20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              LoadingShimmer(width: 120, height: 14),
              SizedBox(width: 24),
              LoadingShimmer(width: 80, height: 14),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              LoadingShimmer(width: 60, height: 32),
              SizedBox(width: 8),
              LoadingShimmer(width: 70, height: 32),
            ],
          ),
        ],
      ),
    );
  }
}
