import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_radius.dart';
import 'package:shield/shared/widgets/app_responsive.dart';

class PharmacySkeletonBlock extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const PharmacySkeletonBlock({
    super.key,
    required this.height,
    this.width,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE2E8F0),
      highlightColor: const Color(0xFFF8FAFC),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: borderRadius ?? BorderRadius.circular(PharmacyRadius.card),
        ),
      ),
    );
  }
}

class PharmacyDashboardSkeleton extends StatelessWidget {
  const PharmacyDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final gridCount = AppResponsive.adaptiveGridCount(
      context,
      phoneCount: 1,
      tabletCount: 2,
      desktopCount: 4,
    );

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Skeleton
          const PharmacySkeletonBlock(height: 28, width: 260),
          const SizedBox(height: 6),
          const PharmacySkeletonBlock(height: 16, width: 380),
          const SizedBox(height: 20),

          // 4 KPI Cards Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridCount,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: gridCount == 1 ? 2.8 : 2.1,
            ),
            itemBuilder: (context, index) =>
                const PharmacySkeletonBlock(height: 96),
          ),
          const SizedBox(height: 20),

          // Financial Metrics & Banner Skeleton
          const PharmacySkeletonBlock(height: 110),
          const SizedBox(height: 20),

          // Recent Orders Section
          if (isDesktop)
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PharmacySkeletonBlock(height: 22, width: 160),
                      SizedBox(height: 12),
                      PharmacySkeletonBlock(height: 68),
                      SizedBox(height: 10),
                      PharmacySkeletonBlock(height: 68),
                      SizedBox(height: 10),
                      PharmacySkeletonBlock(height: 68),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PharmacySkeletonBlock(height: 22, width: 220),
                      SizedBox(height: 12),
                      PharmacySkeletonBlock(height: 68),
                      SizedBox(height: 10),
                      PharmacySkeletonBlock(height: 68),
                      SizedBox(height: 10),
                      PharmacySkeletonBlock(height: 68),
                    ],
                  ),
                ),
              ],
            )
          else ...[
            const PharmacySkeletonBlock(height: 22, width: 160),
            const SizedBox(height: 12),
            const PharmacySkeletonBlock(height: 68),
            const SizedBox(height: 10),
            const PharmacySkeletonBlock(height: 68),
            const SizedBox(height: 10),
            const PharmacySkeletonBlock(height: 68),
          ],
        ],
      ),
    );
  }
}

class PharmacyOrdersSkeleton extends StatelessWidget {
  const PharmacyOrdersSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Order Queue List Skeleton
          SizedBox(
            width: 380,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PharmacySkeletonBlock(height: 44),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(child: PharmacySkeletonBlock(height: 36)),
                    SizedBox(width: 8),
                    Expanded(child: PharmacySkeletonBlock(height: 36)),
                  ],
                ),
                const SizedBox(height: 16),
                ...List.generate(
                  4,
                  (idx) => const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: PharmacySkeletonBlock(height: 110),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Right Order Detail Pane Skeleton
          const Expanded(
            child: PharmacyFulfillmentDetailSkeleton(),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PharmacySkeletonBlock(height: 44),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(child: PharmacySkeletonBlock(height: 36)),
            SizedBox(width: 8),
            Expanded(child: PharmacySkeletonBlock(height: 36)),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(
          4,
          (idx) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: PharmacySkeletonBlock(height: 130),
          ),
        ),
      ],
    );
  }
}

class PharmacyFulfillmentDetailSkeleton extends StatelessWidget {
  const PharmacyFulfillmentDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PharmacySkeletonBlock(height: 80),
        const SizedBox(height: 16),
        const PharmacySkeletonBlock(height: 100),
        const SizedBox(height: 16),
        const PharmacySkeletonBlock(height: 22, width: 220),
        const SizedBox(height: 12),
        const PharmacySkeletonBlock(height: 90),
        const SizedBox(height: 10),
        const PharmacySkeletonBlock(height: 90),
        const SizedBox(height: 16),
        const Row(
          children: [
            Expanded(child: PharmacySkeletonBlock(height: 140)),
            SizedBox(width: 16),
            Expanded(child: PharmacySkeletonBlock(height: 140)),
          ],
        ),
        const SizedBox(height: 16),
        const PharmacySkeletonBlock(height: 60),
      ],
    );
  }
}

class PharmacyPaymentsSkeleton extends StatelessWidget {
  const PharmacyPaymentsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PharmacySkeletonBlock(height: 80),
        const SizedBox(height: 16),
        const Row(
          children: [
            Expanded(child: PharmacySkeletonBlock(height: 38)),
            SizedBox(width: 8),
            Expanded(child: PharmacySkeletonBlock(height: 38)),
            SizedBox(width: 8),
            Expanded(child: PharmacySkeletonBlock(height: 38)),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(
          4,
          (idx) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: PharmacySkeletonBlock(height: 120),
          ),
        ),
      ],
    );
  }
}

class PharmacyPaymentDetailsSkeleton extends StatelessWidget {
  const PharmacyPaymentDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PharmacySkeletonBlock(height: 60),
        const SizedBox(height: 16),
        const PharmacySkeletonBlock(height: 170),
        const SizedBox(height: 16),
        const PharmacySkeletonBlock(height: 140),
        const SizedBox(height: 16),
        const PharmacySkeletonBlock(height: 140),
      ],
    );
  }
}

class PharmacyOrderHistorySkeleton extends StatelessWidget {
  const PharmacyOrderHistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PharmacySkeletonBlock(height: 80),
        const SizedBox(height: 16),
        const PharmacySkeletonBlock(height: 44),
        const SizedBox(height: 16),
        ...List.generate(
          5,
          (idx) => const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: PharmacySkeletonBlock(height: 84),
          ),
        ),
      ],
    );
  }
}

class PharmacyProfileSkeleton extends StatelessWidget {
  const PharmacyProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) ...[
            const PharmacySkeletonBlock(height: 80),
            const SizedBox(height: 16),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 1, child: PharmacySkeletonBlock(height: 380)),
                SizedBox(width: 16),
                Expanded(flex: 2, child: PharmacySkeletonBlock(height: 380)),
              ],
            ),
          ] else ...[
            const PharmacySkeletonBlock(height: 180),
            const SizedBox(height: 16),
            const PharmacySkeletonBlock(height: 220),
          ],
        ],
      ),
    );
  }
}

class PharmacySettingsSkeleton extends StatelessWidget {
  const PharmacySettingsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) ...[
            const PharmacySkeletonBlock(height: 80),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(child: PharmacySkeletonBlock(height: 180)),
                SizedBox(width: 16),
                Expanded(child: PharmacySkeletonBlock(height: 180)),
                SizedBox(width: 16),
                Expanded(child: PharmacySkeletonBlock(height: 180)),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(child: PharmacySkeletonBlock(height: 180)),
                SizedBox(width: 16),
                Expanded(child: PharmacySkeletonBlock(height: 180)),
                SizedBox(width: 16),
                Expanded(child: PharmacySkeletonBlock(height: 180)),
              ],
            ),
          ] else ...[
            const PharmacySkeletonBlock(height: 140),
            const SizedBox(height: 16),
            const PharmacySkeletonBlock(height: 140),
          ],
        ],
      ),
    );
  }
}
