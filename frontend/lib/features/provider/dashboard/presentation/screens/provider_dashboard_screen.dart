import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
        final schedule = controller.workspaceAppointmentsToday.take(4).toList();
        final urgentItems = controller.urgentQueueItems;
        final dashboardHighlights = controller.dashboardHighlights;
        final roleKey =
            GoRouterState.of(context).pathParameters['role'] ?? 'provider';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DashboardHero(
              providerName: controller.providerDisplayName,
              roleLabel: controller.providerRoleLabel,
              branchLabel: controller.providerBranchLabel,
              appointmentsToday: summary['appointmentsToday'] ?? 0,
              waitingPatients: controller.queueCountForStages(const [
                'WAITING',
                'WAITING_PAYMENT',
              ]),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: dashboardHighlights
                  .map(
                    (meta) => _StageMetricCard(
                      title: meta['title']?.toString() ?? 'Queue',
                      value: '${controller.dashboardHighlightValue(meta)}',
                      note: meta['note']?.toString() ?? '',
                      accent: _dashboardColorForId(
                        meta['color']?.toString() ?? 'blue',
                      ),
                      icon: _dashboardIconForId(
                        meta['icon']?.toString() ?? 'queue',
                      ),
                      onTap: () {
                        final filterCode = _queueFilterForHighlight(meta);
                        final query = filterCode == null || filterCode.isEmpty
                            ? ''
                            : '?filter=$filterCode';
                        context.go('/portal/$roleKey/queue$query');
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 22),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 1040;
                final schedulePanel = _InfoPanel(
                  title: "Today's appointments",
                  subtitle:
                      'Patients already scheduled for today appear here first.',
                  child: schedule.isEmpty
                      ? _EmptyWorkPanel(
                          message:
                              'No upcoming appointments are loaded yet. As patients are assigned, today\'s appointments will appear here.',
                        )
                      : Column(
                          children: schedule
                              .map(
                                (appointment) => _ScheduleTile(
                                  item: appointment,
                                  onOpenPatient: () async {
                                    final customerId =
                                        appointment['customerId']
                                            ?.toString()
                                            .trim() ??
                                        '';
                                    if (customerId.isEmpty) {
                                      return;
                                    }
                                    await controller.selectCustomer(customerId);
                                    if (!context.mounted) {
                                      return;
                                    }
                                    context.go(
                                      '/portal/$roleKey/customers?tab=overview',
                                    );
                                  },
                                  onOpenVisit: () async {
                                    final customerId =
                                        appointment['customerId']
                                            ?.toString()
                                            .trim() ??
                                        '';
                                    if (customerId.isEmpty) {
                                      return;
                                    }
                                    await controller.selectCustomer(customerId);
                                    final appointmentId =
                                        appointment['id']?.toString().trim() ??
                                        '';
                                    if (appointmentId.isNotEmpty) {
                                      await controller
                                          .loadConsultationWorkspace(
                                            appointmentId,
                                          );
                                    }
                                    if (!context.mounted) {
                                      return;
                                    }
                                    context.go(
                                      '/portal/$roleKey/customers?tab=today-visit',
                                    );
                                  },
                                ),
                              )
                              .toList(),
                        ),
                );
                final workPanel = _InfoPanel(
                  title: 'Patients needing attention',
                  subtitle:
                      'Start with the patients and payment items that need action next.',
                  child: urgentItems.isEmpty
                      ? _EmptyWorkPanel(
                          message:
                              'Everything is up to date right now. New patient activity will appear here automatically.',
                        )
                      : Column(
                          children: urgentItems
                              .map(
                                (item) => _WorkContinueCard(
                                  item: item,
                                  stage:
                                      item['stageLabel']?.toString() ??
                                      'Waiting',
                                  title:
                                      item['title']?.toString() ?? 'Work item',
                                  subtitle:
                                      item['subtitle']?.toString() ??
                                      item['meta']?.toString() ??
                                      'Patient care activity',
                                  type:
                                      item['workflowLabel']?.toString() ??
                                      'Task',
                                  onOpen: () async {
                                    final customerId =
                                        item['customerId']?.toString().trim() ??
                                        '';
                                    if (customerId.isEmpty) {
                                      context.go('/portal/$roleKey/queue');
                                      return;
                                    }
                                    await controller.selectCustomer(customerId);
                                    if (!context.mounted) {
                                      return;
                                    }
                                    final tab =
                                        item['primaryTargetTab']
                                                ?.toString()
                                                .trim()
                                                .isNotEmpty ==
                                            true
                                        ? item['primaryTargetTab'].toString()
                                        : 'overview';
                                    context.go(
                                      '/portal/$roleKey/customers?tab=$tab',
                                    );
                                  },
                                  onSecondaryOpen: () async {
                                    final customerId =
                                        item['customerId']?.toString().trim() ??
                                        '';
                                    if (customerId.isEmpty) {
                                      return;
                                    }
                                    await controller.selectCustomer(customerId);
                                    if (!context.mounted) {
                                      return;
                                    }
                                    context.go(
                                      '/portal/$roleKey/customers?tab=payments',
                                    );
                                  },
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
    required this.roleLabel,
    required this.branchLabel,
    required this.appointmentsToday,
    required this.waitingPatients,
  });

  final String providerName;
  final String roleLabel;
  final String branchLabel;
  final Object appointmentsToday;
  final Object waitingPatients;

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
            'SHIELD Provider Access',
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
            '$roleLabel • $branchLabel',
            style: AppTypography.body.copyWith(color: const Color(0xFFD7E3FF)),
          ),
          const SizedBox(height: 6),
          Text(
            '$appointmentsToday appointments today • $waitingPatients waiting for attention',
            style: AppTypography.body.copyWith(color: const Color(0xFFD7E3FF)),
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
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String value;
  final String note;
  final Color accent;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
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
            Icon(icon, color: accent, size: 18),
            const SizedBox(height: 10),
            Text(
              title,
              style: AppTypography.small.copyWith(color: AppColors.gray),
            ),
            const SizedBox(height: 8),
            Text(value, style: AppTypography.h3),
            const SizedBox(height: 4),
            Text(
              note,
              style: AppTypography.tiny.copyWith(color: AppColors.gray),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _dashboardIconForId(String iconId) {
  switch (iconId) {
    case 'priority':
      return Icons.priority_high_rounded;
    case 'care':
      return Icons.medical_services_outlined;
    case 'checklist':
      return Icons.checklist_rounded;
    case 'queue':
    default:
      return Icons.people_alt_outlined;
  }
}

Color _dashboardColorForId(String colorId) {
  switch (colorId) {
    case 'red':
      return AppColors.error;
    case 'orange':
      return AppColors.warning;
    case 'green':
      return AppColors.shieldGreen;
    case 'blue':
    default:
      return AppColors.shieldBlue;
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
    required this.item,
    required this.onOpenPatient,
    required this.onOpenVisit,
  });

  final Map<String, dynamic> item;
  final VoidCallback onOpenPatient;
  final VoidCallback onOpenVisit;

  @override
  Widget build(BuildContext context) {
    final title = item['title']?.toString() ?? 'Appointment';
    final subtitle = item['subtitle']?.toString() ?? 'Patient care visit';
    final meta = item['meta']?.toString() ?? '';
    final status =
        item['stageLabel']?.toString() ??
        item['statusLabel']?.toString() ??
        'Scheduled';
    final timeLabel = _timeFromMeta(meta);
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
                  '$subtitle • $status',
                  style: AppTypography.small.copyWith(color: AppColors.gray),
                ),
                if (meta.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    meta,
                    style: AppTypography.tiny.copyWith(color: AppColors.gray),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: onOpenPatient,
                      child: const Text('Open Patient'),
                    ),
                    FilledButton(
                      onPressed: onOpenVisit,
                      child: const Text('Open Visit'),
                    ),
                  ],
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
    required this.item,
    required this.stage,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.onOpen,
    required this.onSecondaryOpen,
  });

  final Map<String, dynamic> item;
  final String stage;
  final String title;
  final String subtitle;
  final String type;
  final VoidCallback onOpen;
  final VoidCallback onSecondaryOpen;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(18),
      child: Container(
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
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
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: onSecondaryOpen,
                  child: Text(
                    item['secondaryActionLabel']?.toString() ?? 'Open patient',
                  ),
                ),
                FilledButton(
                  onPressed: onOpen,
                  child: Text(item['primaryActionLabel']?.toString() ?? 'Open'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _timeFromMeta(String meta) {
  final parts = meta.split('•');
  if (parts.length < 2) {
    return 'Today';
  }
  final datePortion = parts.last.trim();
  final parsed = DateTime.tryParse(datePortion);
  if (parsed == null) {
    return datePortion;
  }
  return ProviderDashboardScreen._formatTime(parsed);
}

String? _queueFilterForHighlight(Map<String, dynamic> meta) {
  final code = meta['code']?.toString().trim().toUpperCase() ?? '';
  switch (code) {
    case 'WAITING':
      return 'waiting';
    case 'CONSULTATION':
    case 'READY_TO_COMPLETE':
      return 'active-care';
    case 'URGENT':
      return 'all-open';
    default:
      return null;
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
