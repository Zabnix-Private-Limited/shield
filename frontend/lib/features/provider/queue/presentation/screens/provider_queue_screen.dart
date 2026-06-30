import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../app/theme/app_colors.dart';
import '../../../../../../app/theme/app_typography.dart';
import '../../../shared/presentation/controllers/provider_portal_controller.dart';
import '../../../shared/presentation/widgets/provider_workspace_scaffold.dart';

class ProviderQueueScreen extends StatelessWidget {
  const ProviderQueueScreen({super.key});

  static const _stageOrder = [
    'NEW',
    'ASSIGNED',
    'IN_PROGRESS',
    'WAITING',
    'READY',
    'COMPLETED',
  ];

  @override
  Widget build(BuildContext context) {
    return ProviderWorkspaceScaffold(
      builder: (context, ref, controller) {
        final stageBuckets = controller.queueByStage;
        final counts = controller.queueStageCounts;
        final hasItems = controller.workflowQueue.isNotEmpty;
        final roleKey =
            GoRouterState.of(context).pathParameters['role'] ?? 'provider';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Today's queue", style: AppTypography.h4),
            const SizedBox(height: 8),
            Text(
              'Keep track of who is waiting, who is under care, and what can be completed next.',
              style: AppTypography.small.copyWith(color: AppColors.gray),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _stageOrder
                  .map(
                    (stage) => _StagePill(
                      label: _stageLabel(stage),
                      count: counts[stage] ?? 0,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 18),
            if (!hasItems)
              _QueueEmptyState()
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _stageOrder
                      .map(
                        (stage) => Padding(
                          padding: EdgeInsets.only(
                            right: stage == _stageOrder.last ? 0 : 14,
                          ),
                          child: _QueueColumn(
                            stage: stage,
                            label: _stageLabel(stage),
                            items: stageBuckets[stage] ?? const [],
                            controller: controller,
                            roleKey: roleKey,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        );
      },
    );
  }

  static String _stageLabel(String stage) {
    switch (stage) {
      case 'NEW':
        return 'Waiting';
      case 'ASSIGNED':
        return 'Accepted';
      case 'IN_PROGRESS':
        return 'In Consultation';
      case 'WAITING':
        return 'Waiting';
      case 'READY':
        return 'Ready to Complete';
      case 'COMPLETED':
        return 'Completed';
      default:
        return stage.replaceAll('_', ' ');
    }
  }
}

class _StagePill extends StatelessWidget {
  const _StagePill({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        '$label • $count',
        style: AppTypography.small.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _QueueColumn extends StatelessWidget {
  const _QueueColumn({
    required this.stage,
    required this.items,
    required this.label,
    required this.controller,
    required this.roleKey,
  });

  final String stage;
  final List<Map<String, dynamic>> items;
  final String label;
  final ProviderPortalController controller;
  final String roleKey;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.divider),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.h5),
              const SizedBox(height: 4),
              Text(
                '${items.length} patients',
                style: AppTypography.tiny.copyWith(color: AppColors.gray),
              ),
              const SizedBox(height: 14),
              if (items.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _emptyStateText(stage),
                    style: AppTypography.small.copyWith(color: AppColors.gray),
                  ),
                )
              else
                ...items.map(
                  (item) => _QueueCard(
                    item: item,
                    controller: controller,
                    roleKey: roleKey,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _emptyStateText(String stage) {
    switch (stage) {
      case 'NEW':
      case 'WAITING':
        return 'No patients are waiting right now.';
      case 'ASSIGNED':
        return 'No accepted patients are queued here.';
      case 'IN_PROGRESS':
        return 'No consultations are in progress.';
      case 'READY':
        return 'Nothing is waiting to be completed.';
      case 'COMPLETED':
        return 'No completed items have been loaded yet.';
      default:
        return 'Everything is up to date.';
    }
  }
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({
    required this.item,
    required this.controller,
    required this.roleKey,
  });

  final Map<String, dynamic> item;
  final ProviderPortalController controller;
  final String roleKey;

  @override
  Widget build(BuildContext context) {
    final type = item['workflowType']?.toString() ?? 'TASK';
    final typeLabel = item['workflowLabel']?.toString() ?? type;
    final title = item['title']?.toString() ?? 'Workflow item';
    final subtitle = item['subtitle']?.toString() ?? 'Operational work';
    final meta = item['meta']?.toString();
    final statusLabel = item['stageLabel']?.toString() ?? item['statusLabel']?.toString() ?? 'Waiting';
    final secondaryActionLabel = item['secondaryActionLabel']?.toString() ?? 'Open patient';
    final primaryActionLabel = item['primaryActionLabel']?.toString() ?? 'Open';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.shieldNavy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              typeLabel,
              style: AppTypography.tiny.copyWith(
                color: AppColors.shieldNavy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(title, style: AppTypography.body),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTypography.small.copyWith(color: AppColors.darkGray),
          ),
          const SizedBox(height: 8),
          Text(
            statusLabel,
            style: AppTypography.tiny.copyWith(
              color: AppColors.shieldBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (meta != null && meta.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              meta,
              style: AppTypography.tiny.copyWith(color: AppColors.gray),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _openQueueAction(
                    context,
                    primary: false,
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(secondaryActionLabel),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => _openQueueAction(
                    context,
                    primary: true,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.shieldBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(primaryActionLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openQueueAction(
    BuildContext context, {
    required bool primary,
  }) async {
    final targetSection = controller.queueTargetSection(item, primary: primary);
    final targetTab = controller.queueTargetTab(item, primary: primary);
    final hasPatient = await controller.prepareQueuePatient(item);
    if (!context.mounted) {
      return;
    }

    context.go('/portal/$roleKey/$targetSection?tab=$targetTab');

    if (!hasPatient) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This queue item is not linked to a patient record yet.',
          ),
        ),
      );
    }
  }
}

class _QueueEmptyState extends StatelessWidget {
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
      child: Text(
        'No patients or payment items are assigned right now. New appointments and care activity will appear here as the day progresses.',
        style: AppTypography.body.copyWith(color: AppColors.gray),
      ),
    );
  }
}
