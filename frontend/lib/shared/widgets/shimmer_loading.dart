import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

// ---------------------------------------------------------------------------
// Shimmer animation — a single linear gradient sweep that loops forever.
// ---------------------------------------------------------------------------

class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final shimmerWidth = size.width * 0.5;
    final dx = -shimmerWidth + (size.width + shimmerWidth * 2) * progress;
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [
        Color(0xFFEEEEEE),
        Color(0xFFF5F5F5),
        Color(0xFFEEEEEE),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(dx, 0, shimmerWidth, size.height),
      );

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_ShimmerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ShimmerAnimation extends StatefulWidget {
  const _ShimmerAnimation({required this.child});

  final Widget child;

  @override
  State<_ShimmerAnimation> createState() => _ShimmerAnimationState();
}

class _ShimmerAnimationState extends State<_ShimmerAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) => CustomPaint(
      painter: _ShimmerPainter(progress: _controller.value),
      child: child,
    ),
    child: widget.child,
  );
}

// ---------------------------------------------------------------------------
// Primitive building blocks
// ---------------------------------------------------------------------------

/// A single shimmering rectangle — the lowest-level building block.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius = 6,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) => _ShimmerAnimation(
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    ),
  );
}

/// A circular shimmer placeholder (e.g. for avatars).
class ShimmerAvatar extends StatelessWidget {
  const ShimmerAvatar({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) => _ShimmerAnimation(
    child: Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFEEEEEE),
        shape: BoxShape.circle,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Composed loading placeholders
// ---------------------------------------------------------------------------

/// Mimics a list tile with an icon placeholder + two text lines.
class ShimmerListTile extends StatelessWidget {
  const ShimmerListTile({super.key, this.showAvatar = true});

  final bool showAvatar;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        if (showAvatar) ...[
          const ShimmerAvatar(size: 40),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(width: 140 + (showAvatar ? 0 : 60), height: 14),
              const SizedBox(height: 8),
              const ShimmerBox(height: 10),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const ShimmerBox(width: 60, height: 12),
      ],
    ),
  );
}

/// Mimics a card with a title area and a few content lines.
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key, this.lines = 3, this.showHeader = true});

  final int lines;
  final bool showHeader;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.lightGray),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          const ShimmerBox(width: 120, height: 16),
          const SizedBox(height: 14),
        ],
        for (int i = 0; i < lines; i++) ...[
          ShimmerBox(
            height: 12,
            width: i == lines - 1 ? 180 : null,
          ),
          if (i < lines - 1) const SizedBox(height: 10),
        ],
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Screen-level loading presets
// ---------------------------------------------------------------------------

/// A generic list loading placeholder — N shimmer list tiles.
class ShimmerListLoading extends StatelessWidget {
  const ShimmerListLoading({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(
      itemCount,
      (_) => const ShimmerListTile(),
    ),
  );
}

/// A card-based loading placeholder — header card + N content cards.
class ShimmerCardLoading extends StatelessWidget {
  const ShimmerCardLoading({super.key, this.cardCount = 3});

  final int cardCount;

  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(
      cardCount,
      (index) => ShimmerCard(
        showHeader: index == 0,
        lines: index == 0 ? 2 : 3,
      ),
    ),
  );
}

/// Dashboard-style loading — metrics row + card list.
class ShimmerDashboardLoading extends StatelessWidget {
  const ShimmerDashboardLoading({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: List.generate(
          3,
          (i) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
              child: const ShimmerCard(lines: 1, showHeader: true),
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      const ShimmerCard(lines: 4, showHeader: true),
      const ShimmerCard(lines: 3, showHeader: true),
    ],
  );
}

/// Provider list loading — mimics the services screen layout.
class ShimmerProviderListLoading extends StatelessWidget {
  const ShimmerProviderListLoading({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: List.generate(
          4,
          (i) => Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
            child: ShimmerBox(width: 70 + (i * 10), height: 32, borderRadius: 16),
          ),
        ),
      ),
      const SizedBox(height: 20),
      for (int i = 0; i < 4; i++) ...[
        const ShimmerListTile(),
      ],
    ],
  );
}
