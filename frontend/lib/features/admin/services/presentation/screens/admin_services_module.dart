import 'package:flutter/material.dart';

import '../../../shared/exports.dart';

class AdminServicesModule extends StatelessWidget {
  const AdminServicesModule({super.key});

  @override
  Widget build(BuildContext context) {
    return const TwoPanelModule(
      eyebrow: 'Providers / Services',
      title: 'Service catalog and commercial alignment',
      description:
          'A central catalog for service visibility, provider mapping, benefit eligibility, and pricing-rule awareness.',
      primaryAction: AdminActionItem(label: 'Add service', icon: Icons.medical_services_outlined),
      secondaryAction: AdminActionItem(label: 'Review benefit rules', icon: Icons.rule_outlined),
      leftTitle: 'Service catalog',
      leftSubtitle: 'Not just labels: provider, benefit, and commercial ownership in one place.',
      leftChild: Column(
        children: [
          AdminEntityCard(item: AdminEntityItem(title: 'Dermatology consultation', subtitle: 'Benefit eligible • provider-mapped', meta: 'reward earning active', status: 'Live', color: AdminColors.success)),
          AdminEntityCard(item: AdminEntityItem(title: 'Full body lab panel', subtitle: 'Limited branches • high conversion', meta: 'watch pricing caps', status: 'Watch', color: AdminColors.warning)),
          AdminEntityCard(item: AdminEntityItem(title: 'Dental follow-up package', subtitle: 'specialized service bundle', meta: 'benefit conflict review', status: 'Review', color: AdminColors.danger)),
        ],
      ),
      rightTitle: 'Rule and provider alignment',
      rightSubtitle: 'Service definitions should stay coupled to backend-owned commercial truth.',
      rightChild: Column(
        children: [
          AdminHealthRow(item: AdminHealthItem(label: 'Mapped providers', value: '46', meta: 'live service coverage', color: AdminColors.secondary)),
          AdminHealthRow(item: AdminHealthItem(label: 'Benefit-enabled services', value: '18', meta: 'pricing-owned config', color: AdminColors.success)),
          AdminHealthRow(item: AdminHealthItem(label: 'Rule gaps', value: '3', meta: 'service types without clean commercial mapping', color: AdminColors.warning)),
          AdminHealthRow(item: AdminHealthItem(label: 'High-risk overlap', value: '1', meta: 'reward plus benefit conflict', color: AdminColors.danger)),
        ],
      ),
    );
  }
}
