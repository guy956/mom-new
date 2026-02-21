import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

/// Enhanced shimmer loading widget with animated gradient effect
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Widget? child;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoading({
    super.key,
    this.width = double.infinity,
    this.height = 100,
    this.borderRadius = 12,
    this.child,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.animationSlow * 2,
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.baseColor ?? AppColors.surfaceVariant;
    final highlight = widget.highlightColor ?? Colors.white.withValues(alpha: 0.5);

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
              colors: [
                base,
                highlight,
                base,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// Shimmer card loading placeholder with animated shimmer effect
class ShimmerCard extends StatelessWidget {
  final int itemCount;
  final EdgeInsets padding;

  const ShimmerCard({
    super.key,
    this.itemCount = 3,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      itemCount: itemCount,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header shimmer
              Row(
                children: [
                  const ShimmerLoading(
                    width: 44,
                    height: 44,
                    borderRadius: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ShimmerLoading(
                          width: 120,
                          height: 14,
                          borderRadius: 4,
                        ),
                        const SizedBox(height: 6),
                        ShimmerLoading(
                          width: 80,
                          height: 10,
                          borderRadius: 4,
                          baseColor: AppColors.surfaceVariant.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Content shimmer
              const ShimmerLoading(
                width: double.infinity,
                height: 12,
                borderRadius: 4,
              ),
              const SizedBox(height: 8),
              ShimmerLoading(
                width: MediaQuery.of(context).size.width * 0.7,
                height: 12,
                borderRadius: 4,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// List shimmer loading placeholder with animated shimmer effect
class ShimmerList extends StatelessWidget {
  final int itemCount;
  final bool hasAvatar;
  final double itemHeight;

  const ShimmerList({
    super.key,
    this.itemCount = 5,
    this.hasAvatar = true,
    this.itemHeight = 72,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          height: itemHeight,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              if (hasAvatar) ...[
                const ShimmerLoading(
                  width: 48,
                  height: 48,
                  borderRadius: 24,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const ShimmerLoading(
                      width: 140,
                      height: 14,
                      borderRadius: 4,
                    ),
                    const SizedBox(height: 8),
                    ShimmerLoading(
                      width: 100,
                      height: 10,
                      borderRadius: 4,
                      baseColor: AppColors.surfaceVariant.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Grid shimmer loading placeholder with animated shimmer effect
class ShimmerGrid extends StatelessWidget {
  final int crossAxisCount;
  final int itemCount;
  final double childAspectRatio;
  final EdgeInsets padding;

  const ShimmerGrid({
    super.key,
    this.crossAxisCount = 2,
    this.itemCount = 4,
    this.childAspectRatio = 1,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: itemCount,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        return const ShimmerLoading(
          borderRadius: 16,
        );
      },
    );
  }
}
