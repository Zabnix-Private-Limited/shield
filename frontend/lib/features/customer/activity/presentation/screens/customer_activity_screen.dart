import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/services/api_service.dart';
import '../../../../customer/shared/widgets/error_card.dart';
import '../../../../../shared/widgets/app_card.dart';

class CustomerActivityScreen extends StatefulWidget {
  const CustomerActivityScreen({super.key});

  @override
  State<CustomerActivityScreen> createState() => _CustomerActivityScreenState();
}

class _CustomerActivityScreenState extends State<CustomerActivityScreen> {
  late Future<List<Map<String, dynamic>>> _timelineFuture;

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  void _loadTimeline() {
    _timelineFuture = ApiService.getCustomerTimeline();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _timelineFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return ErrorCard(
            title: 'Activity unavailable',
            message: 'Your customer activity timeline could not be loaded.',
            onRetry: () => setState(_loadTimeline),
          );
        }

        final events = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async => setState(_loadTimeline),
          color: AppColors.shieldBlue,
          child: events.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [_ActivityEmptyState()],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: events.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index == 0) return const _ActivityIntro();
                    return _ActivityEventCard(event: events[index - 1]);
                  },
                ),
        );
      },
    );
  }
}

class _ActivityIntro extends StatelessWidget {
  const _ActivityIntro();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.shieldBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.timeline_outlined,
                color: AppColors.shieldBlue,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Activity timeline', style: AppTypography.h4),
                  SizedBox(height: 4),
                  Text(
                    'Your membership, visits, documents, wallet and notification activity.',
                    style: AppTypography.small,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityEmptyState extends StatelessWidget {
  const _ActivityEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 36),
      child: AppCard(
        child: Column(
          children: [
            Icon(Icons.timeline_outlined, size: 42, color: AppColors.gray),
            SizedBox(height: 12),
            Text('No activity yet', style: AppTypography.h4),
            SizedBox(height: 6),
            Text(
              'Membership, visits, documents and wallet activity will appear here when recorded.',
              textAlign: TextAlign.center,
              style: AppTypography.body,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityEventCard extends StatelessWidget {
  const _ActivityEventCard({required this.event});

  final Map<String, dynamic> event;

  @override
  Widget build(BuildContext context) {
    final category = event['category']?.toString() ?? 'ACTIVITY';
    final timestamp = DateTime.tryParse(event['timestamp']?.toString() ?? '');
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _colorFor(category).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_iconFor(category), color: _colorFor(category)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['displayTitle']?.toString() ?? 'Activity recorded',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event['description']?.toString() ?? 'SHIELD activity update',
                  style: AppTypography.small.copyWith(
                    color: AppColors.darkGray,
                  ),
                ),
                if (timestamp != null) ...[
                  const SizedBox(height: 7),
                  Text(
                    DateFormat('dd MMM yyyy • hh:mm a').format(timestamp),
                    style: AppTypography.tiny.copyWith(color: AppColors.gray),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(String category) => switch (category.toUpperCase()) {
    'MEMBERSHIP' => AppColors.shieldBlue,
    'WALLET' => AppColors.shieldGreen,
    'DOCUMENT' || 'PRESCRIPTION' => AppColors.shieldLightBlue,
    'LAB' => AppColors.shieldLightBlue,
    'BILLING' => AppColors.warning,
    'NOTIFICATION' => AppColors.shieldBlue,
    'APPOINTMENT' || 'VISIT' => AppColors.warning,
    _ => AppColors.shieldNavy,
  };

  IconData _iconFor(String category) => switch (category.toUpperCase()) {
    'MEMBERSHIP' => Icons.workspace_premium_outlined,
    'WALLET' => Icons.account_balance_wallet_outlined,
    'DOCUMENT' || 'PRESCRIPTION' => Icons.description_outlined,
    'LAB' => Icons.science_outlined,
    'BILLING' => Icons.receipt_long_outlined,
    'NOTIFICATION' => Icons.notifications_active_outlined,
    'APPOINTMENT' || 'VISIT' => Icons.calendar_month_outlined,
    _ => Icons.timeline_outlined,
  };
}
