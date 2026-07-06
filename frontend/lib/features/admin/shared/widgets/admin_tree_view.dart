import 'package:flutter/material.dart';

import '../theme/admin_colors.dart';
import '../theme/admin_typography.dart';

class AdminTreeNodeData {
  const AdminTreeNodeData({
    required this.label,
    required this.depth,
    required this.note,
  });

  final String label;
  final int depth;
  final String note;
}

class AdminTreeView extends StatelessWidget {
  const AdminTreeView({super.key, required this.nodes});

  final List<AdminTreeNodeData> nodes;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: nodes
          .map(
            (node) => Padding(
              padding: EdgeInsets.only(left: node.depth * 18.0, bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: node.depth == 0
                          ? AdminColors.rewards
                          : AdminColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${node.label} • ${node.note}',
                      style: AdminTypography.small.copyWith(
                        color: AdminColors.subtext,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
