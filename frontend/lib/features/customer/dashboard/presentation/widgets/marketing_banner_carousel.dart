import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';

class MarketingBannerCarousel extends StatefulWidget {
  const MarketingBannerCarousel({super.key});

  @override
  State<MarketingBannerCarousel> createState() =>
      _MarketingBannerCarouselState();
}

class _MarketingBannerCarouselState extends State<MarketingBannerCarousel> {
  static const _banners = <_MarketingBanner>[
    _MarketingBanner(
      imageUrl:
          'https://images.unsplash.com/photo-1576091160399-112ba8d25d1?auto=format&fit=crop&w=1200&q=85',
      eyebrow: 'PREVENTIVE CARE',
      title: 'Make time for your health',
      subtitle: 'Book a consultation when you need it.',
      route: '/portal/customer/appointments',
    ),
    _MarketingBanner(
      imageUrl:
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=1200&q=85',
      eyebrow: 'EVERYDAY WELLNESS',
      title: 'Small choices, lasting change',
      subtitle: 'Explore healthy habits with SHIELD.',
      route: '/portal/customer/services',
    ),
    _MarketingBanner(
      imageUrl:
          'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?auto=format&fit=crop&w=1200&q=85',
      eyebrow: 'MEMBER SUPPORT',
      title: 'Care that stays connected',
      subtitle: 'Keep your records and visits in one place.',
      route: '/portal/customer/documents',
    ),
  ];

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
      final nextIndex = (_activeIndex + 1) % _banners.length;
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
    return SizedBox(
      height: 176,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _banners.length,
            onPageChanged: (index) => setState(() => _activeIndex = index),
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.go(banner.route),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            banner.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const ColoredBox(color: AppColors.shieldNavy),
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
                                  banner.eyebrow,
                                  style: AppTypography.tiny.copyWith(
                                    color: AppColors.white.withValues(
                                      alpha: 0.82,
                                    ),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 5),
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
                              ],
                            ),
                          ),
                        ],
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
                _banners.length,
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

class _MarketingBanner {
  const _MarketingBanner({
    required this.imageUrl,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final String imageUrl;
  final String eyebrow;
  final String title;
  final String subtitle;
  final String route;
}
