import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../app/theme/app_colors.dart';
import '../../../../../../app/theme/app_typography.dart';
import '../../../shared/presentation/controllers/provider_portal_controller.dart';
import '../../../shared/presentation/widgets/provider_workspace_scaffold.dart';

class ProviderQueueScreen extends StatefulWidget {
  const ProviderQueueScreen({super.key});

  @override
  State<ProviderQueueScreen> createState() => _ProviderQueueScreenState();
}

class _ProviderQueueScreenState extends State<ProviderQueueScreen> {
  String? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    return ProviderWorkspaceScaffold(
      builder: (context, ref, controller) {
        final routeFilter = GoRouterState.of(
          context,
        ).uri.queryParameters['filter'];
        final selectedFilter = (_selectedFilter ?? routeFilter)?.trim();
        final queueItems = controller.queueItemsForFilter(selectedFilter);
        final stageBuckets = <String, List<Map<String, dynamic>>>{};
        for (final stage in controller.queueStagesMetadata) {
          final code = stage['code']?.toString() ?? '';
          if (code.isNotEmpty) {
            stageBuckets[code] = <Map<String, dynamic>>[];
          }
        }
        for (final item in queueItems) {
          final stageCode = item['stageCode']?.toString() ?? '';
          stageBuckets
              .putIfAbsent(stageCode, () => <Map<String, dynamic>>[])
              .add(item);
        }
        final counts = {
          for (final entry in stageBuckets.entries)
            entry.key: entry.value.length,
        };
        final hasItems = queueItems.isNotEmpty;
        final stageMetadata = controller.queueStagesMetadata;
        final queueFilters = controller.queueFilters;
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
            if (queueFilters.isNotEmpty) ...[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: queueFilters.map((filter) {
                  final code = filter['code']?.toString() ?? '';
                  final active = selectedFilter == code;
                  return ChoiceChip(
                    label: Text(filter['title']?.toString() ?? 'Filter'),
                    selected: active,
                    onSelected: (_) {
                      setState(() {
                        _selectedFilter = active ? null : code;
                      });
                      final query = active ? '' : '?filter=$code';
                      context.go('/portal/$roleKey/queue$query');
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
            ],
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: stageMetadata
                  .map(
                    (stage) => _StagePill(
                      label: stage['title']?.toString() ?? 'Queue',
                      count: counts[stage['code']?.toString() ?? ''] ?? 0,
                      colorId: stage['color']?.toString() ?? 'blue',
                      onTap: () {
                        final matchingFilter = queueFilters.where((filter) {
                          final stageCodes = List<String>.from(
                            filter['stageCodes'] ?? const <String>[],
                          );
                          return stageCodes.length == 1 &&
                              stageCodes.first == stage['code']?.toString();
                        });
                        final filterCode = matchingFilter.isEmpty
                            ? null
                            : matchingFilter.first['code']?.toString();
                        setState(() {
                          _selectedFilter = filterCode;
                        });
                        final query = filterCode == null
                            ? ''
                            : '?filter=$filterCode';
                        context.go('/portal/$roleKey/queue$query');
                      },
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
                  children: stageMetadata
                      .map(
                        (stage) => Padding(
                          padding: EdgeInsets.only(
                            right: stage == stageMetadata.last ? 0 : 14,
                          ),
                          child: _QueueColumn(
                            label: stage['title']?.toString() ?? 'Queue',
                            iconId: stage['icon']?.toString() ?? 'queue',
                            colorId: stage['color']?.toString() ?? 'blue',
                            emptyStateMessage:
                                stage['emptyStateMessage']?.toString() ??
                                'Everything is up to date.',
                            items:
                                stageBuckets[stage['code']?.toString() ?? ''] ??
                                const [],
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
}

class _StagePill extends StatelessWidget {
  const _StagePill({
    required this.label,
    required this.count,
    required this.colorId,
    required this.onTap,
  });

  final String label;
  final int count;
  final String colorId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(
          '$label • $count',
          style: AppTypography.small.copyWith(
            fontWeight: FontWeight.w700,
            color: _colorForId(colorId),
          ),
        ),
      ),
    );
  }
}

class _QueueColumn extends StatelessWidget {
  const _QueueColumn({
    required this.items,
    required this.label,
    required this.iconId,
    required this.colorId,
    required this.emptyStateMessage,
    required this.controller,
    required this.roleKey,
  });

  final List<Map<String, dynamic>> items;
  final String label;
  final String iconId;
  final String colorId;
  final String emptyStateMessage;
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
              Row(
                children: [
                  Icon(
                    _iconForId(iconId),
                    size: 18,
                    color: _colorForId(colorId),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(label, style: AppTypography.h5)),
                ],
              ),
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
                    emptyStateMessage,
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
    final statusLabel =
        item['stageLabel']?.toString() ??
        item['statusLabel']?.toString() ??
        'Waiting';
    final secondaryActionLabel =
        item['secondaryActionLabel']?.toString() ?? 'Open patient';
    final primaryActionLabel = item['primaryActionLabel']?.toString() ?? 'Open';

    return InkWell(
      onTap: () => _openQueueAction(context, primary: true),
      borderRadius: BorderRadius.circular(18),
      child: Container(
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
                    onPressed: () => _openQueueAction(context, primary: false),
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
                    onPressed: () => _openQueueAction(context, primary: true),
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

IconData _iconForId(String iconId) {
  switch (iconId) {
    case 'people':
    case 'patient':
      return Icons.people_alt_outlined;
    case 'assignment':
      return Icons.assignment_ind_outlined;
    case 'care':
      return Icons.medical_services_outlined;
    case 'payments':
      return Icons.payments_outlined;
    case 'checklist':
      return Icons.checklist_rounded;
    case 'done':
      return Icons.task_alt_outlined;
    case 'queue':
    default:
      return Icons.local_hospital_outlined;
  }
}

Color _colorForId(String colorId) {
  switch (colorId) {
    case 'red':
      return AppColors.error;
    case 'orange':
    case 'amber':
      return AppColors.warning;
    case 'green':
      return AppColors.shieldGreen;
    case 'slate':
      return AppColors.darkGray;
    case 'blue':
    default:
      return AppColors.shieldBlue;
  }
}

class _QueueEmptyState extends StatelessWidget {
  const _QueueEmptyState();

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
