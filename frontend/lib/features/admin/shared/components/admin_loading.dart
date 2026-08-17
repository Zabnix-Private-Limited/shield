import 'package:flutter/material.dart';

import '../../../../shared/widgets/shimmer_loading.dart';

class AdminLoading extends StatelessWidget {
  const AdminLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: ShimmerListLoading(itemCount: 4),
    );
  }
}
