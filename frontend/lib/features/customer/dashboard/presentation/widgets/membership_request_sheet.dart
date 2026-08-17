import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/models/customer.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/portal_support.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../controllers/dashboard_controller.dart';

Future<void> showMembershipRequestSheet(
  BuildContext context, {
  required Customer customer,
  required DashboardController controller,
  MembershipApplicationEntity? existingApplication,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _MembershipRequestSheet(
      customer: customer,
      controller: controller,
      existingApplication: existingApplication,
    ),
  );
}

class _MembershipRequestSheet extends StatefulWidget {
  final Customer customer;
  final DashboardController controller;
  final MembershipApplicationEntity? existingApplication;

  const _MembershipRequestSheet({
    required this.customer,
    required this.controller,
    this.existingApplication,
  });

  @override
  State<_MembershipRequestSheet> createState() =>
      _MembershipRequestSheetState();
}

class _MembershipRequestSheetState extends State<_MembershipRequestSheet> {
  bool _isSubmitting = false;
  MembershipApplicationEntity? _submittedApplication;

  @override
  void initState() {
    super.initState();
    _submittedApplication = widget.existingApplication;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.controller.submitMembershipApplication();
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _submittedApplication =
            widget.controller.dashboard?.membershipApplication ??
            MembershipApplicationEntity(
              id: 'new',
              reference:
                  'MAP-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
              status: 'PENDING',
              submittedAt: DateTime.now(),
            );
      });

      showPortalSnackBar(
        context,
        'Membership application submitted successfully.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      showPortalSnackBar(
        context,
        'Unable to submit membership application. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final application = _submittedApplication;
    final isAlreadySubmitted = application != null;

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isAlreadySubmitted
                            ? AppColors.shieldGreen.withValues(alpha: .15)
                            : AppColors.shieldNavy.withValues(alpha: .1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isAlreadySubmitted
                            ? Icons.check_circle_outline_rounded
                            : Icons.card_membership_rounded,
                        color: isAlreadySubmitted
                            ? AppColors.shieldGreen
                            : AppColors.shieldNavy,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAlreadySubmitted
                                ? 'Membership Request Submitted'
                                : 'Request SHIELD Membership',
                            style: AppTypography.h4,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isAlreadySubmitted
                                ? 'Your application is under review by Operations.'
                                : 'Apply for your digital privilege card & benefits.',
                            style: AppTypography.small.copyWith(
                              color: AppColors.gray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (isAlreadySubmitted) ...[
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Application Ref',
                              style: AppTypography.tiny.copyWith(
                                color: AppColors.gray,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.shieldNavy.withValues(
                                  alpha: .1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                application.status.toUpperCase(),
                                style: AppTypography.tiny.copyWith(
                                  color: AppColors.shieldNavy,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          application.reference,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.shieldNavy,
                          ),
                        ),
                        const Divider(height: 24),
                        _InfoRow(
                          label: 'Applicant Name',
                          value: widget.customer.fullName,
                        ),
                        const SizedBox(height: 6),
                        _InfoRow(
                          label: 'Mobile Number',
                          value: widget.customer.mobile,
                        ),
                        const SizedBox(height: 6),
                        _InfoRow(
                          label: 'Submitted Date',
                          value:
                              '${application.submittedAt.day.toString().padLeft(2, '0')}/${application.submittedAt.month.toString().padLeft(2, '0')}/${application.submittedAt.year}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.lightGray,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 20,
                          color: AppColors.shieldNavy,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'SHIELD Operations will process your request and issue your digital privilege card upon approval.',
                            style: AppTypography.small.copyWith(
                              color: AppColors.shieldNavy,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: 'Got it',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ] else ...[
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Applicant Info',
                          style: AppTypography.small.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.gray,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Name',
                          value: widget.customer.fullName,
                        ),
                        const SizedBox(height: 6),
                        _InfoRow(
                          label: 'Mobile',
                          value: widget.customer.mobile,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Included Membership Benefits',
                          style: AppTypography.small.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.gray,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const _BenefitItem(
                          icon: Icons.credit_card_rounded,
                          title: 'Digital Privilege Card',
                          subtitle:
                              'Issued upon approval for identity verification.',
                        ),
                        const SizedBox(height: 10),
                        const _BenefitItem(
                          icon: Icons.local_pharmacy_outlined,
                          title: 'Healthcare & Pharmacy Discounts',
                          subtitle:
                              'Special rates across partner clinics & stores.',
                        ),
                        const SizedBox(height: 10),
                        const _BenefitItem(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'Wallet & Cashback Privileges',
                          subtitle:
                              'Earn reward points on orders and wallet recharges.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'Cancel',
                          onPressed: () => Navigator.of(context).pop(),
                          type: AppButtonType.secondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          text: 'Submit Request',
                          onPressed: _submit,
                          isLoading: _isSubmitting,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: AppTypography.tiny.copyWith(color: AppColors.gray),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.small.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.shieldNavy,
            ),
          ),
        ),
      ],
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.shieldNavy.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.shieldNavy),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.small.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: AppTypography.tiny.copyWith(color: AppColors.gray),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
