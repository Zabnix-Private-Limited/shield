import 'package:flutter/material.dart';

import '../../../../../shared/widgets/app_skeleton.dart';

class WalletShimmer extends StatelessWidget {
  const WalletShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPortalSectionSkeleton(
      showHero: true,
      statCards: 4,
      listItems: 5,
    );
  }
}
