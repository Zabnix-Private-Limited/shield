import 'package:flutter/material.dart';

import '../../exports.dart';

class TwoPanelModule extends StatelessWidget {
  const TwoPanelModule({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.primaryAction,
    required this.secondaryAction,
    required this.leftTitle,
    required this.leftSubtitle,
    required this.leftChild,
    required this.rightTitle,
    required this.rightSubtitle,
    required this.rightChild,
  });

  final String eyebrow;
  final String title;
  final String description;
  final AdminActionItem primaryAction;
  final AdminActionItem secondaryAction;
  final String leftTitle;
  final String leftSubtitle;
  final Widget leftChild;
  final String rightTitle;
  final String rightSubtitle;
  final Widget rightChild;

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      eyebrow: eyebrow,
      title: title,
      description: description,
      primaryAction: primaryAction,
      secondaryAction: secondaryAction,
      child: TwoColumnBody(
        leftTitle: leftTitle,
        leftSubtitle: leftSubtitle,
        leftChild: leftChild,
        rightTitle: rightTitle,
        rightSubtitle: rightSubtitle,
        rightChild: rightChild,
      ),
    );
  }
}

class TwoColumnBody extends StatelessWidget {
  const TwoColumnBody({
    super.key,
    required this.leftTitle,
    required this.leftSubtitle,
    required this.leftChild,
    required this.rightTitle,
    required this.rightSubtitle,
    required this.rightChild,
  });

  final String leftTitle;
  final String leftSubtitle;
  final Widget leftChild;
  final String rightTitle;
  final String rightSubtitle;
  final Widget rightChild;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: Panel(
            title: leftTitle,
            subtitle: leftSubtitle,
            child: leftChild,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 5,
          child: Panel(
            title: rightTitle,
            subtitle: rightSubtitle,
            child: rightChild,
          ),
        ),
      ],
    );
  }
}

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AdminStatCard(title: title, subtitle: subtitle, child: child);
  }
}
