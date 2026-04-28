import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

/// Animated shimmer loading placeholder
class LoadingShimmer extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const LoadingShimmer({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
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
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
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
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: const [
                AppColors.border,
                Color(0xFFEDF2F7),
                AppColors.border,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Shimmer row for table loading
class ShimmerRow extends StatelessWidget {
  final int columns;
  final double height;

  const ShimmerRow({
    super.key,
    this.columns = 5,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: List.generate(
          columns,
          (i) => const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: LoadingShimmer(
                height: 16,
                width: double.infinity,
                borderRadius: 4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
