import 'package:flutter/material.dart';

import '../../../../../../app/theme/app_colors.dart';
import '../../../../../../app/theme/app_typography.dart';
import '../../../../../../shared/models/customer.dart';

class PatientHeaderStrip extends StatelessWidget {
  const PatientHeaderStrip({
    super.key,
    required this.customer,
    required this.selectedMembershipLabel,
    required this.cardStatusLabel,
    required this.walletSummaryLabel,
    required this.locationLabel,
    required this.bloodGroupLabel,
    required this.upcomingVisitLabel,
    required this.onOpenTab,
  });

  final Customer customer;
  final String selectedMembershipLabel;
  final String cardStatusLabel;
  final String walletSummaryLabel;
  final String locationLabel;
  final String bloodGroupLabel;
  final String upcomingVisitLabel;
  final ValueChanged<String> onOpenTab;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.fullName, style: AppTypography.h4),
                    const SizedBox(height: 6),
                    Text(
                      '${customer.customerCode} • ${customer.mobile}',
                      style: AppTypography.small.copyWith(
                        color: AppColors.gray,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeaderPill(label: selectedMembershipLabel),
                  _HeaderPill(label: cardStatusLabel),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _HeaderMetric(title: 'Visible cash', value: walletSummaryLabel),
              _HeaderMetric(title: 'Location', value: locationLabel),
              _HeaderMetric(title: 'Blood group', value: bloodGroupLabel),
              _HeaderMetric(title: 'Next visit', value: upcomingVisitLabel),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                [
                      const ('documents', 'Documents'),
                      const ('clinical-notes', 'Clinical Notes'),
                      const ('billing-wallet', 'Billing & Wallet'),
                      const ('timeline', 'Timeline'),
                      const ('prescriptions', 'Prescriptions'),
                    ]
                    .map(
                      (tab) => ActionChip(
                        label: Text(tab.$2),
                        onPressed: () => onOpenTab(tab.$1),
                      ),
                    )
                    .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.tiny.copyWith(color: AppColors.gray),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.shieldBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.tiny.copyWith(
          color: AppColors.shieldBlue,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
