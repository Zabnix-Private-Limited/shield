import 'package:flutter/material.dart';

import '../../../../../shared/widgets/app_skeleton.dart';

class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPortalSectionSkeleton(
      showHero: true,
      statCards: 4,
      listItems: 4,
    );
  }
}
