import 'package:flutter/material.dart';

import 'responsive_breakpoints.dart';

class AdminSplitWorkspace extends StatelessWidget {
  const AdminSplitWorkspace({
    super.key,
    required this.left,
    required this.center,
    this.right,
  });

  final Widget left;
  final Widget center;
  final Widget? right;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < AdminResponsiveBreakpoints.splitWorkspace) {
      return Column(
        children: [
          left,
          const SizedBox(height: 16),
          center,
          if (right != null) ...[const SizedBox(height: 16), right!],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: left),
        const SizedBox(width: 16),
        Expanded(flex: 5, child: center),
        if (right != null) ...[
          const SizedBox(width: 16),
          Expanded(flex: 4, child: right!),
        ],
      ],
    );
  }
}
