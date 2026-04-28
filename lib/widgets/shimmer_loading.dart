import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Animated shimmer loading placeholder.
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
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
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
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
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
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

/// Shimmer loading for stat cards row.
class StatCardsShimmer extends StatelessWidget {
  const StatCardsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        4,
        (i) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 3 ? 16 : 0),
            child: const ShimmerBox(height: 100, width: double.infinity),
          ),
        ),
      ),
    );
  }
}

/// Shimmer loading for table rows.
class TableShimmer extends StatelessWidget {
  final int rowCount;

  const TableShimmer({super.key, this.rowCount = 6});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        rowCount,
        (i) => Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: i.isEven ? AppColors.surface : AppColors.tableRowAlt,
            border: const Border(
              bottom: BorderSide(color: AppColors.border),
            ),
          ),
          child: const Row(
            children: [
              ShimmerBox(width: 60, height: 14, borderRadius: 4),
              SizedBox(width: 16),
              ShimmerBox(width: 100, height: 14, borderRadius: 4),
              SizedBox(width: 16),
              ShimmerBox(width: 80, height: 14, borderRadius: 4),
              Spacer(),
              ShimmerBox(width: 70, height: 24, borderRadius: 12),
            ],
          ),
        ),
      ),
    );
  }
}
