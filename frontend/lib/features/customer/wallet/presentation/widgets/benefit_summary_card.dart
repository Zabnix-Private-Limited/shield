import 'package:flutter/material.dart';

import 'balance_card.dart';

class BenefitSummaryCard extends StatelessWidget {
  const BenefitSummaryCard({
    super.key,
    required this.value,
    required this.caption,
  });

  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return BalanceCard(
      title: 'Benefits used',
      value: value,
      caption: caption,
      icon: Icons.local_offer_outlined,
    );
  }
}
