import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../domain/entities/dashboard_entity.dart';

class OperationsBannerCarousel extends StatefulWidget {
  const OperationsBannerCarousel({super.key, required this.banners});

  final List<DashboardBannerEntity> banners;

  @override
  State<OperationsBannerCarousel> createState() =>
      _OperationsBannerCarouselState();
}

class _OperationsBannerCarouselState extends State<OperationsBannerCarousel> {
  final _controller = PageController(viewportFraction: 0.96);
  Timer? _timer;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_controller.hasClients) {
        return;
      }
      if (widget.banners.isEmpty) return;
      final nextIndex = (_activeIndex + 1) % widget.banners.length;
      _controller.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 176,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            onPageChanged: (index) => setState(() => _activeIndex = index),
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Material(
                    color: Colors.transparent,
                    child: Semantics(
                      button: true,
                      label:
                          '${banner.altText}. ${banner.title}. ${banner.ctaLabel}',
                      child: InkWell(
                        onTap: () => context.go(banner.ctaRoute),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            banner.imageUrl.startsWith('assets/')
                                ? Image.asset(
                                    banner.imageUrl,
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    banner.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const ColoredBox(
                                      color: AppColors.shieldNavy,
                                    ),
                                  ),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xD90F172A),
                                    Color(0x681E3A8A),
                                    Color(0x1A0F172A),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    banner.title,
                                    style: AppTypography.h4.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    banner.subtitle,
                                    style: AppTypography.small.copyWith(
                                      color: AppColors.white.withValues(
                                        alpha: 0.86,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    '${banner.ctaLabel}  ›',
                                    style: AppTypography.small.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            left: 20,
            bottom: 12,
            child: Row(
              children: List.generate(
                widget.banners.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: index == _activeIndex ? 18 : 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 5),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(
                      alpha: index == _activeIndex ? 0.96 : 0.48,
                    ),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
