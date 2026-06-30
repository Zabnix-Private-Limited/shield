import 'package:flutter/material.dart';

import '../../../../../../app/theme/app_colors.dart';
import '../../../../../../app/theme/app_typography.dart';
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Smart operations queue', style: AppTypography.h4),
            const SizedBox(height: 8),
            Text(
              'Every provider workflow should move through a clear operational stage instead of hiding inside separate pages.',
              style: AppTypography.small.copyWith(color: AppColors.gray),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _stageOrder
                  .map(
                    (stage) => _StagePill(
                      label: stage.replaceAll('_', ' '),
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
                            items: stageBuckets[stage] ?? const [],
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
  const _QueueColumn({required this.stage, required this.items});

  final String stage;
  final List<Map<String, dynamic>> items;

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
              Text(stage.replaceAll('_', ' '), style: AppTypography.h5),
              const SizedBox(height: 4),
              Text(
                '${items.length} items',
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
                    'No workflow cards in this stage.',
                    style: AppTypography.small.copyWith(color: AppColors.gray),
                  ),
                )
              else
                ...items.map((item) => _QueueCard(item: item)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final type = item['workflowType']?.toString() ?? 'TASK';
    final title = item['title']?.toString() ?? 'Workflow item';
    final subtitle = item['subtitle']?.toString() ?? 'Operational work';
    final meta = item['meta']?.toString();

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
              type,
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
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Review'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.shieldBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Start'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
        'No active operational items are assigned right now. As appointments, billing work, and provider actions enter SHIELD, this board will become the live center of daily work.',
        style: AppTypography.body.copyWith(color: AppColors.gray),
      ),
    );
  }
}
