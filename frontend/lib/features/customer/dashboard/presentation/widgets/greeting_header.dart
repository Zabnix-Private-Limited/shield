import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/models/customer.dart';
import '../../../../../shared/models/membership.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../controllers/dashboard_controller.dart';
import 'membership_request_sheet.dart';

enum MembershipDashboardState {
  noApplication,
  applicationPending,
  approvedAwaitingActivation,
  activeMember,
  applicationRejected,
  membershipInactive,
}

MembershipDashboardState resolveMembershipDashboardState({
  required Membership? membership,
  required MembershipApplicationEntity? application,
}) {
  final membershipStatus = membership?.membershipStatus.trim().toUpperCase();
  if (membershipStatus == 'ACTIVE') {
    return MembershipDashboardState.activeMember;
  }
  if (membership != null) return MembershipDashboardState.membershipInactive;
  switch (application?.status.trim().toUpperCase()) {
    case 'PENDING':
      return MembershipDashboardState.applicationPending;
    case 'APPROVED':
      return MembershipDashboardState.approvedAwaitingActivation;
    case 'REJECTED':
      return MembershipDashboardState.applicationRejected;
    default:
      return MembershipDashboardState.noApplication;
  }
}

class GreetingHeader extends StatelessWidget {
  const GreetingHeader({
    super.key,
    required this.customer,
    required this.membership,
    required this.application,
    required this.controller,
  });

  final Customer customer;
  final Membership? membership;
  final MembershipApplicationEntity? application;
  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final state = resolveMembershipDashboardState(
      membership: membership,
      application: application,
    );
    final status = switch (state) {
      MembershipDashboardState.noApplication => 'MEMBERSHIP',
      MembershipDashboardState.applicationPending => 'PENDING',
      MembershipDashboardState.approvedAwaitingActivation => 'APPROVED',
      MembershipDashboardState.activeMember => 'ACTIVE',
      MembershipDashboardState.applicationRejected => 'REJECTED',
      MembershipDashboardState.membershipInactive =>
        membership?.membershipStatus.toUpperCase() ?? 'INACTIVE',
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.shieldNavy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  state == MembershipDashboardState.activeMember
                      ? customer.fullName.toUpperCase()
                      : 'Membership',
                  style: AppTypography.body.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _StatusChip(label: status),
            ],
          ),
          const SizedBox(height: 12),
          _content(context, state),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, MembershipDashboardState state) {
    final copy = AppTypography.small.copyWith(
      color: AppColors.white.withValues(alpha: .85),
    );
    if (state == MembershipDashboardState.noApplication) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No active membership card',
            style: AppTypography.h4.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Apply for a SHIELD membership card to access digital card privileges and healthcare discounts.',
            style: copy,
          ),
          const SizedBox(height: 14),
          _Action(
            label: 'Request membership',
            onTap: () => _openRequestFlow(context),
          ),
        ],
      );
    }
    if (state == MembershipDashboardState.applicationPending) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ApplicationDetails(
            title: 'Membership application',
            message: 'Your membership application is being reviewed.',
            application: application!,
          ),
          const SizedBox(height: 10),
          _Action(
            label: 'View application status',
            onTap: () => _openRequestFlow(context, existingApplication: application),
          ),
        ],
      );
    }
    if (state == MembershipDashboardState.approvedAwaitingActivation) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ApplicationDetails(
            title: 'Membership approved',
            message:
                'Your membership has been approved and is awaiting activation/card issuance.',
            application: application!,
          ),
          const SizedBox(height: 10),
          _Action(
            label: 'Track card issuance',
            onTap: () => _openRequestFlow(context, existingApplication: application),
          ),
        ],
      );
    }
    if (state == MembershipDashboardState.applicationRejected) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Membership application',
            style: AppTypography.h4.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: 4),
          Text(
            application?.reason?.trim().isNotEmpty == true
                ? application!.reason!
                : 'Your application was not approved.',
            style: copy,
          ),
          const SizedBox(height: 14),
          _Action(
            label: 'Request membership again',
            onTap: () => _openRequestFlow(context),
          ),
        ],
      );
    }
    if (state == MembershipDashboardState.activeMember) {
      final item = membership!;
      final hasActiveCard =
          item.cardStatus?.trim().toUpperCase() == 'ACTIVE' ||
          item.cardStatus?.trim().toUpperCase() == 'ISSUED';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Detail(label: 'Membership no.', value: item.customerCode),
          _Detail(label: 'Plan', value: item.tierLabel),
          _Detail(
            label: 'Valid until',
            value:
                '${item.endDate.day.toString().padLeft(2, '0')}/${item.endDate.month.toString().padLeft(2, '0')}/${item.endDate.year}',
          ),
          const SizedBox(height: 10),
          _Action(
            label: hasActiveCard
                ? 'View membership card'
                : 'Request membership card',
            onTap: () {
              if (hasActiveCard) {
                context.go('/portal/customer/membership');
              } else {
                _openRequestFlow(context, existingApplication: application);
              }
            },
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your membership is ${membership?.membershipStatus.toLowerCase() ?? 'inactive'}.',
          style: copy,
        ),
        const SizedBox(height: 14),
        _Action(
          label: 'Request membership',
          onTap: () => _openRequestFlow(context),
        ),
      ],
    );
  }

  void _openRequestFlow(
    BuildContext context, {
    MembershipApplicationEntity? existingApplication,
  }) {
    showMembershipRequestSheet(
      context,
      customer: customer,
      controller: controller,
      existingApplication: existingApplication,
    );
  }
}

class _ApplicationDetails extends StatelessWidget {
  const _ApplicationDetails({
    required this.title,
    required this.message,
    required this.application,
  });
  final String title;
  final String message;
  final MembershipApplicationEntity application;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: AppTypography.h4.copyWith(color: AppColors.white)),
      const SizedBox(height: 4),
      Text(
        message,
        style: AppTypography.small.copyWith(
          color: AppColors.white.withValues(alpha: .85),
        ),
      ),
      const SizedBox(height: 12),
      _Detail(label: 'Application reference', value: application.reference),
      _Detail(
        label: 'Applied',
        value:
            '${application.submittedAt.day.toString().padLeft(2, '0')}/${application.submittedAt.month.toString().padLeft(2, '0')}/${application.submittedAt.year}',
      ),
    ],
  );
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      children: [
        SizedBox(
          width: 132,
          child: Text(
            label,
            style: AppTypography.tiny.copyWith(
              color: AppColors.white.withValues(alpha: .7),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.small.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.white.withValues(alpha: .15),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      child: Text(
        label,
        style: AppTypography.tiny.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _Action extends StatelessWidget {
  const _Action({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onTap,
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.shieldNavy,
    ),
    child: Text(label),
  );
}
