import 'package:flutter/material.dart';

import 'balance_card.dart';

class RewardPointsCard extends StatelessWidget {
  const RewardPointsCard({
    super.key,
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
    this.dark = false,
  });

  final String title;
  final String value;
  final String caption;
  final IconData icon;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return BalanceCard(
      title: title,
      value: value,
      caption: caption,
      icon: icon,
      dark: dark,
    );
  }
}
