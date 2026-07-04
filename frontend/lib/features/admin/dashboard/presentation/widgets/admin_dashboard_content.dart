import 'package:flutter/material.dart';

import '../../../shared/exports.dart';
import '../../domain/entities/admin_dashboard_entity.dart';

class AdminDashboardContent extends StatelessWidget {
  const AdminDashboardContent({
    super.key,
    required this.dashboard,
  });

  final AdminDashboardEntity dashboard;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: AdminStatCard(
                title: 'Operational queue',
                subtitle:
                    'Live workload returned by the backend workspace contract for the admin dashboard.',
                child: _RecordList(
                  items: dashboard.queueItems,
                  emptyTitle: 'No operational queue items',
                  emptyDescription:
                      'The dashboard API returned no queue workload for this admin section right now.',
                  emptyAction: 'Connect the next workflow once the backend emits it',
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 5,
              child: AdminStatCard(
                title: 'Quick actions',
                subtitle:
                    'Action labels are owned by backend metadata and surfaced here without module-local branching.',
                child: _ActionList(actions: dashboard.actions),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: AdminStatCard(
                title: 'Recent activity',
                subtitle:
                    'Latest records returned by the live admin dashboard feed.',
                child: _RecordList(
                  items: dashboard.recentItems,
                  emptyTitle: 'No recent activity yet',
                  emptyDescription:
                      'This admin dashboard response did not include recent activity records.',
                  emptyAction: 'Next backend slice can enrich this feed',
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 5,
              child: AdminStatCard(
                title: 'Operational insights',
                subtitle:
                    'Backend-generated insight summaries and freshness indicators.',
                child: _RecordList(
                  items: dashboard.insightItems,
                  emptyTitle: 'No insights returned',
                  emptyDescription:
                      'The admin dashboard backend has not emitted insight cards for this section yet.',
                  emptyAction: 'Use this slot for branch health and KPI narratives next',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RecordList extends StatelessWidget {
  const _RecordList({
    required this.items,
    required this.emptyTitle,
    required this.emptyDescription,
    required this.emptyAction,
  });

  final List<AdminDashboardRecordEntity> items;
  final String emptyTitle;
  final String emptyDescription;
  final String emptyAction;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return AdminEmptyState(
        title: emptyTitle,
        description: emptyDescription,
        actionLabel: emptyAction,
      );
    }

    return Column(
      children: items
          .map(
            (item) => AdminEntityCard(
              item: AdminEntityItem(
                title: item.title,
                subtitle: item.subtitle,
                meta: item.meta,
                status: item.status,
                color: _statusColor(item.status),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ActionList extends StatelessWidget {
  const _ActionList({required this.actions});

  final List<String> actions;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const AdminEmptyState(
        title: 'No backend action labels yet',
        description:
            'The admin dashboard route is live, but it has not published explicit action labels for this section.',
        actionLabel: 'Keep action definitions backend-driven as new workflows ship',
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: actions
          .map(
            (action) => Container(
              width: 180,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _statusColor(action).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _statusColor(action).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _actionIcon(action),
                      color: _statusColor(action),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      action,
                      style: AdminTypography.small.copyWith(
                        color: AdminColors.text,
                        fontWeight: FontWeight.w800,
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

Color _statusColor(String value) {
  final normalized = value.toLowerCase();
  if (normalized.contains('danger') ||
      normalized.contains('error') ||
      normalized.contains('critical') ||
      normalized.contains('overdue') ||
      normalized.contains('blocked')) {
    return AdminColors.danger;
  }
  if (normalized.contains('warning') ||
      normalized.contains('pending') ||
      normalized.contains('review') ||
      normalized.contains('watch')) {
    return AdminColors.warning;
  }
  if (normalized.contains('reward') || normalized.contains('point')) {
    return AdminColors.rewards;
  }
  if (normalized.contains('visit') || normalized.contains('appointment')) {
    return AdminColors.visits;
  }
  if (normalized.contains('success') ||
      normalized.contains('healthy') ||
      normalized.contains('active') ||
      normalized.contains('ok') ||
      normalized.contains('complete')) {
    return AdminColors.success;
  }
  return AdminColors.secondary;
}

IconData _actionIcon(String action) {
  final normalized = action.toLowerCase();
  if (normalized.contains('customer')) {
    return Icons.person_add_alt_1_outlined;
  }
  if (normalized.contains('agent')) {
    return Icons.badge_outlined;
  }
  if (normalized.contains('provider')) {
    return Icons.local_hospital_outlined;
  }
  if (normalized.contains('membership')) {
    return Icons.credit_card_outlined;
  }
  if (normalized.contains('visit') || normalized.contains('appointment')) {
    return Icons.event_available_outlined;
  }
  if (normalized.contains('wallet') || normalized.contains('credit')) {
    return Icons.account_balance_wallet_outlined;
  }
  if (normalized.contains('document')) {
    return Icons.description_outlined;
  }
  if (normalized.contains('report')) {
    return Icons.analytics_outlined;
  }
  return Icons.bolt_outlined;
}
