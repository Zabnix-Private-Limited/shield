import 'package:flutter/material.dart';

import '../theme/admin_colors.dart';

class AdminLoading extends StatelessWidget {
  const AdminLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AdminColors.secondary),
    );
  }
}
