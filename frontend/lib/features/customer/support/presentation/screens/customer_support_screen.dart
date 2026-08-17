import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../shared/widgets/shimmer_loading.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/services/api_service.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/customer_support_sheet.dart';
import '../../../../customer/shared/widgets/error_card.dart';

class CustomerSupportScreen extends StatefulWidget {
  const CustomerSupportScreen({super.key});

  @override
  State<CustomerSupportScreen> createState() => _CustomerSupportScreenState();
}

class _CustomerSupportScreenState extends State<CustomerSupportScreen> {
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = ApiService.getCustomerSupportHistory();
  }

  void _reload() => setState(() {
    _historyFuture = ApiService.getCustomerSupportHistory();
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _historyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: ShimmerListLoading(),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return ErrorCard(
            title: 'Support history unavailable',
            message: 'Your submitted support requests could not be loaded.',
            onRetry: _reload,
          );
        }
        final requests = snapshot.data!;
        return RefreshIndicator(
          color: AppColors.shieldBlue,
          onRefresh: () async => _reload(),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: requests.length + 2,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) return _SupportIntro(onSubmitted: _reload);
              if (index == 1 && requests.isEmpty) return const _SupportEmpty();
              if (requests.isEmpty) return const SizedBox.shrink();
              return _SupportRequestCard(request: requests[index - 2]);
            },
          ),
        );
      },
    );
  }
}

class _SupportIntro extends StatelessWidget {
  const _SupportIntro({required this.onSubmitted});
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Row(
      children: [
        const Icon(Icons.support_agent_outlined, color: AppColors.shieldBlue),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Support requests', style: AppTypography.h4),
              SizedBox(height: 4),
              Text(
                'Send a request and track its current status here.',
                style: AppTypography.small,
              ),
            ],
          ),
        ),
        AppButton(
          text: 'New request',
          onPressed: () async {
            await showCustomerSupportSheet(
              context,
              type: SupportSheetType.contact,
            );
            onSubmitted();
          },
        ),
      ],
    ),
  );
}

class _SupportEmpty extends StatelessWidget {
  const _SupportEmpty();
  @override
  Widget build(BuildContext context) => const AppCard(
    child: Padding(
      padding: EdgeInsets.all(8),
      child: Text(
        'You have not submitted any support requests yet.',
        style: AppTypography.body,
      ),
    ),
  );
}

class _SupportRequestCard extends StatelessWidget {
  const _SupportRequestCard({required this.request});
  final Map<String, dynamic> request;

  @override
  Widget build(BuildContext context) {
    final status = (request['status'] ?? 'SUBMITTED').toString();
    final createdAt = DateTime.tryParse(
      (request['createdAt'] ?? '').toString(),
    );
    return InkWell(
      onTap: () => _openDetail(context),
      borderRadius: BorderRadius.circular(16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    (request['complaintType'] ?? 'Support request')
                        .toString()
                        .replaceAll('_', ' '),
                    style: AppTypography.h4,
                  ),
                ),
                _StatusChip(status: status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              (request['description'] ?? '').toString(),
              style: AppTypography.body,
            ),
            if (createdAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Submitted ${DateFormat('dd MMM yyyy, hh:mm a').format(createdAt.toLocal())}',
                style: AppTypography.small,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Open request',
              style: AppTypography.small.copyWith(color: AppColors.shieldBlue),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDetail(BuildContext context) async {
    final id = request['id']?.toString();
    if (id == null || id.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SupportDetailSheet(complaintId: id),
    );
  }
}

class _SupportDetailSheet extends StatefulWidget {
  const _SupportDetailSheet({required this.complaintId});
  final String complaintId;
  @override
  State<_SupportDetailSheet> createState() => _SupportDetailSheetState();
}

class _SupportDetailSheetState extends State<_SupportDetailSheet> {
  late Future<Map<String, dynamic>> _future;
  @override
  void initState() {
    super.initState();
    _future = ApiService.getCustomerSupportDetail(widget.complaintId);
  }

  void _retry() => setState(
    () => _future = ApiService.getCustomerSupportDetail(widget.complaintId),
  );
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return ErrorCard(
              title: 'Support request unavailable',
              message: 'Please refresh and try again.',
              onRetry: _retry,
            );
          }
          final data = snapshot.data!;
          final events = List<Map<String, dynamic>>.from(
            data['lifecycleEvents'] ?? const [],
          );
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Support request', style: AppTypography.h3),
                const SizedBox(height: 8),
                _StatusChip(status: (data['status'] ?? 'SUBMITTED').toString()),
                const SizedBox(height: 16),
                Text(
                  (data['description'] ?? '').toString(),
                  style: AppTypography.body,
                ),
                if ((data['resolutionNote'] ?? '')
                    .toString()
                    .trim()
                    .isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Resolution', style: AppTypography.h4),
                  const SizedBox(height: 6),
                  Text(
                    data['resolutionNote'].toString(),
                    style: AppTypography.body,
                  ),
                ],
                if (events.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Updates from SHIELD', style: AppTypography.h4),
                  const SizedBox(height: 8),
                  ...events.map(
                    (event) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        (event['note'] ?? '').toString(),
                        style: AppTypography.body,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) => Chip(
    label: Text(status.replaceAll('_', ' ')),
    backgroundColor: AppColors.shieldBlue.withValues(alpha: 0.10),
  );
}
