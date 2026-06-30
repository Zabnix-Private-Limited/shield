import 'package:flutter/material.dart';

import '../../../../../../app/theme/app_colors.dart';
import '../../../../../../app/theme/app_typography.dart';
import '../../../shared/presentation/widgets/provider_workspace_scaffold.dart';

class ProviderDashboardScreen extends StatelessWidget {
  const ProviderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderWorkspaceScaffold(
      builder: (context, ref, controller) {
        final summary = controller.summary;
        final queueCounts = controller.queueStageCounts;
        final schedule = controller.selectedUpcomingAppointments.take(4).toList();
        final urgentItems = controller.urgentQueueItems;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DashboardHero(
              providerName: controller.providerDisplayName,
              roleCode: controller.providerRoleCode,
              appointmentsToday: summary['appointmentsToday'] ?? 0,
              pendingItems:
                  (summary['pendingAppointments'] ?? 0) +
                  (summary['pendingDocuments'] ?? 0),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StageMetricCard(
                  title: 'Urgent',
                  value: '${urgentItems.length}',
                  note: 'needs attention',
                  accent: AppColors.error,
                ),
                _StageMetricCard(
                  title: 'Waiting',
                  value: '${queueCounts['WAITING'] ?? 0}',
                  note: 'customer or review hold',
                  accent: AppColors.warning,
                ),
                _StageMetricCard(
                  title: 'In Progress',
                  value: '${queueCounts['IN_PROGRESS'] ?? 0}',
                  note: 'active operational work',
                  accent: AppColors.shieldBlue,
                ),
                _StageMetricCard(
                  title: 'Ready',
                  value: '${queueCounts['READY'] ?? 0}',
                  note: 'can be completed now',
                  accent: AppColors.shieldGreen,
                ),
              ],
            ),
            const SizedBox(height: 22),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 1040;
                final schedulePanel = _InfoPanel(
                  title: "Today's schedule",
                  subtitle: 'Start from appointments already linked to your workspace.',
                  child: schedule.isEmpty
                      ? _EmptyWorkPanel(
                          message:
                              'No upcoming customer appointments are loaded yet. The queue and customer workspace will populate this area as live assignments grow.',
                        )
                      : Column(
                          children: schedule
                              .map(
                                (appointment) => _ScheduleTile(
                                  timeLabel: _formatTime(
                                    appointment.appointmentDate,
                                  ),
                                  title: appointment.typeLabel,
                                  subtitle:
                                      '${appointment.doctorName ?? 'Provider'} • ${appointment.statusLabel}',
                                ),
                              )
                              .toList(),
                        ),
                );
                final workPanel = _InfoPanel(
                  title: 'Continue current work',
                  subtitle:
                      'The highest-priority queue items should be the first actions in the day.',
                  child: urgentItems.isEmpty
                      ? _EmptyWorkPanel(
                          message:
                              'No urgent queue items are waiting right now. Use the queue to pick the next assigned customer workflow.',
                        )
                      : Column(
                          children: urgentItems
                              .map(
                                (item) => _WorkContinueCard(
                                  stage: item['status']?.toString() ?? 'NEW',
                                  title: item['title']?.toString() ?? 'Work item',
                                  subtitle:
                                      item['subtitle']?.toString() ??
                                      item['meta']?.toString() ??
                                      'Operational task',
                                  type:
                                      item['workflowType']?.toString() ??
                                      'TASK',
                                ),
                              )
                              .toList(),
                        ),
                );

                if (stacked) {
                  return Column(
                    children: [
                      schedulePanel,
                      const SizedBox(height: 16),
                      workPanel,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: schedulePanel),
                    const SizedBox(width: 16),
                    Expanded(child: workPanel),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  static String _formatTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.providerName,
    required this.roleCode,
    required this.appointmentsToday,
    required this.pendingItems,
  });

  final String providerName;
  final String roleCode;
  final Object appointmentsToday;
  final Object pendingItems;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B132B), Color(0xFF173A84)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Provider Operating Workspace',
            style: AppTypography.tiny.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Good day, $providerName',
            style: AppTypography.h2.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            '$roleCode • $appointmentsToday scheduled today • $pendingItems active items needing action',
            style: AppTypography.body.copyWith(
              color: const Color(0xFFD7E3FF),
            ),
          ),
        ],
      ),
    );
  }
}

class _StageMetricCard extends StatelessWidget {
  const _StageMetricCard({
    required this.title,
    required this.value,
    required this.note,
    required this.accent,
  });

  final String title;
  final String value;
  final String note;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(height: 10),
          Text(title, style: AppTypography.small.copyWith(color: AppColors.gray)),
          const SizedBox(height: 8),
          Text(value, style: AppTypography.h3),
          const SizedBox(height: 4),
          Text(note, style: AppTypography.tiny.copyWith(color: AppColors.gray)),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

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
          Text(title, style: AppTypography.h4),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTypography.small.copyWith(color: AppColors.gray),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({
    required this.timeLabel,
    required this.title,
    required this.subtitle,
  });

  final String timeLabel;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text(
              timeLabel,
              style: AppTypography.small.copyWith(
                color: AppColors.shieldNavy,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.body),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.small.copyWith(color: AppColors.gray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkContinueCard extends StatelessWidget {
  const _WorkContinueCard({
    required this.stage,
    required this.title,
    required this.subtitle,
    required this.type,
  });

  final String stage;
  final String title;
  final String subtitle;
  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.shieldBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$type • $stage',
                  style: AppTypography.tiny.copyWith(
                    color: AppColors.shieldBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: AppTypography.body),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTypography.small.copyWith(color: AppColors.gray),
          ),
        ],
      ),
    );
  }
}

class _EmptyWorkPanel extends StatelessWidget {
  const _EmptyWorkPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        style: AppTypography.small.copyWith(color: AppColors.gray),
      ),
    );
  }
}
