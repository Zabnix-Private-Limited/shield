import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../app/theme/app_colors.dart';
import 'app_page_frame.dart';
import 'app_responsive.dart';

class AppSkeletonBlock extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const AppSkeletonBlock({
    super.key,
    required this.height,
    this.width,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.divider,
      highlightColor: AppColors.white,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: borderRadius ?? BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class AppPageSkeleton extends StatelessWidget {
  final bool showSidebar;

  const AppPageSkeleton({super.key, this.showSidebar = false});

  @override
  Widget build(BuildContext context) {
    final gridCount = AppResponsive.adaptiveGridCount(
      context,
      phoneCount: 1,
      tabletCount: 2,
      desktopCount: 3,
    );

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      body: SafeArea(
        child: Row(
          children: [
            if (showSidebar)
              Container(
                width: 280,
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  border: Border(right: BorderSide(color: AppColors.divider)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    AppSkeletonBlock(height: 30, width: 120),
                    SizedBox(height: 10),
                    AppSkeletonBlock(height: 18, width: 140),
                    SizedBox(height: 24),
                    AppSkeletonBlock(height: 60),
                    SizedBox(height: 10),
                    AppSkeletonBlock(height: 60),
                    SizedBox(height: 10),
                    AppSkeletonBlock(height: 60),
                    SizedBox(height: 10),
                    AppSkeletonBlock(height: 60),
                  ],
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                child: AppPageFrame(
                  maxWidth: 1240,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSkeletonBlock(height: 34, width: 220),
                      const SizedBox(height: 10),
                      const AppSkeletonBlock(height: 18, width: 340),
                      const SizedBox(height: 18),
                      const AppSkeletonBlock(height: 48),
                      const SizedBox(height: 18),
                      const AppSkeletonBlock(height: 220),
                      const SizedBox(height: 18),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: gridCount == 1 ? 3 : 6,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: gridCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.8,
                        ),
                        itemBuilder: (context, index) =>
                            const AppSkeletonBlock(height: 150),
                      ),
                      const SizedBox(height: 18),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 900) {
                            return const Column(
                              children: [
                                AppSkeletonBlock(height: 280),
                                SizedBox(height: 16),
                                AppSkeletonBlock(height: 280),
                              ],
                            );
                          }
                          return const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: AppSkeletonBlock(height: 280)),
                              SizedBox(width: 16),
                              Expanded(child: AppSkeletonBlock(height: 280)),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      const AppSkeletonBlock(height: 220),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppCustomerSectionSkeleton extends StatelessWidget {
  final bool showHero;
  final bool showActionRow;
  final int statCards;
  final int listItems;

  const AppCustomerSectionSkeleton({
    super.key,
    this.showHero = true,
    this.showActionRow = true,
    this.statCards = 2,
    this.listItems = 4,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSkeletonBlock(height: 28, width: 170),
          const SizedBox(height: 8),
          const AppSkeletonBlock(height: 16, width: 220),
          const SizedBox(height: 18),
          if (showHero) ...[
            const AppSkeletonBlock(height: 120),
            const SizedBox(height: 14),
          ],
          if (statCards > 0) ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: statCards,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.7,
              ),
              itemBuilder: (context, index) =>
                  const AppSkeletonBlock(height: 96),
            ),
            const SizedBox(height: 14),
          ],
          if (showActionRow) ...[
            const Row(
              children: [
                Expanded(child: AppSkeletonBlock(height: 42)),
                SizedBox(width: 12),
                Expanded(child: AppSkeletonBlock(height: 42)),
              ],
            ),
            const SizedBox(height: 18),
          ],
          const AppSkeletonBlock(height: 22, width: 150),
          const SizedBox(height: 12),
          ...List.generate(
            listItems,
            (index) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: AppSkeletonBlock(height: 82),
            ),
          ),
        ],
      ),
    );
  }
}

class AppPortalSectionSkeleton extends StatelessWidget {
  final bool showHero;
  final int statCards;
  final int listItems;

  const AppPortalSectionSkeleton({
    super.key,
    this.showHero = true,
    this.statCards = 4,
    this.listItems = 4,
  });

  @override
  Widget build(BuildContext context) {
    final gridCount = AppResponsive.adaptiveGridCount(
      context,
      phoneCount: 1,
      tabletCount: 2,
      desktopCount: 2,
    );

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHero) ...[
            const AppSkeletonBlock(height: 172),
            const SizedBox(height: 20),
          ],
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: statCards,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridCount,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: gridCount == 1 ? 3.1 : 2.35,
            ),
            itemBuilder: (context, index) => const AppSkeletonBlock(height: 88),
          ),
          const SizedBox(height: 20),
          const AppSkeletonBlock(height: 24, width: 180),
          const SizedBox(height: 12),
          ...List.generate(
            listItems,
            (index) => const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: AppSkeletonBlock(height: 76),
            ),
          ),
        ],
      ),
    );
  }
}
