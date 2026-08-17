import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../shared/widgets/shimmer_loading.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/services/api_service.dart';
import '../../../../../shared/utils/app_display_formatters.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../customer/shared/widgets/error_card.dart';
import '../../domain/customer_referral_summary.dart';

class CustomerReferralsScreen extends StatefulWidget {
  const CustomerReferralsScreen({super.key});

  @override
  State<CustomerReferralsScreen> createState() =>
      _CustomerReferralsScreenState();
}

class _CustomerReferralsScreenState extends State<CustomerReferralsScreen> {
  late Future<CustomerReferralSummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  void _loadSummary() {
    _summaryFuture = ApiService.getCustomerReferralSummary().then(
      CustomerReferralSummary.fromJson,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CustomerReferralSummary>(
      future: _summaryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: ShimmerCardLoading(),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return ErrorCard(
            title: 'Referrals unavailable',
            message: 'Your referral status could not be loaded.',
            onRetry: () => setState(_loadSummary),
          );
        }
        final summary = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async => setState(_loadSummary),
          color: AppColors.shieldBlue,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              Text('Referral & rewards', style: AppTypography.h3),
              const SizedBox(height: 6),
              Text(
                'Referral rewards remain pending until the backend qualification lifecycle completes.',
                style: AppTypography.small,
              ),
              const SizedBox(height: 18),
              _ReferralCodeCard(code: summary.referralCode),
              const SizedBox(height: 12),
              _SummaryGrid(summary: summary),
              const SizedBox(height: 22),
              Text('Referral activity', style: AppTypography.h4),
              const SizedBox(height: 10),
              if (summary.events.isEmpty)
                const AppCard(
                  child: Text(
                    'No referral activity yet. Qualified and rewarded referrals will appear here.',
                    style: AppTypography.small,
                  ),
                )
              else
                ...summary.events.map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ReferralEventCard(event: event),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ReferralCodeCard extends StatelessWidget {
  const _ReferralCodeCard({required this.code});

  final String code;

  String get _referralLink =>
      'https://shield-zabnix.vercel.app/#/customer/register?ref=$code';

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_tree_outlined, color: AppColors.shieldBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your referral code', style: AppTypography.small),
                      const SizedBox(height: 4),
                      Text(
                        code.isEmpty ? 'Not available' : code,
                        style: AppTypography.h4.copyWith(color: AppColors.shieldNavy),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: code.isEmpty
                      ? null
                      : () async {
                          await Clipboard.setData(ClipboardData(text: code));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Referral code copied.')),
                            );
                          }
                        },
                  icon: const Icon(Icons.copy_outlined),
                  tooltip: 'Copy referral code',
                ),
              ],
            ),
            if (code.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Referral Signup Link',
                style: AppTypography.tiny.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.shieldNavy,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                _referralLink,
                style: AppTypography.small.copyWith(color: AppColors.shieldBlue),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: _referralLink));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Referral signup link copied to clipboard!',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.link_rounded, size: 18),
                    label: const Text('Copy Link'),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Tracked & assigned to your agent',
                    style: AppTypography.tiny.copyWith(color: AppColors.gray),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});

  final CustomerReferralSummary summary;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => GridView.count(
      crossAxisCount: constraints.maxWidth >= 460 ? 3 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.65,
      children: [
        _SummaryTile(
          label: 'Direct referrals',
          value: '${summary.directReferrals}',
        ),
        _SummaryTile(
          label: 'Total referrals',
          value: '${summary.totalReferrals}',
        ),
        _SummaryTile(
          label: 'Available points',
          value: '${summary.availablePoints.toStringAsFixed(0)} pts',
        ),
      ],
    ),
  );
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: AppTypography.tiny.copyWith(color: AppColors.gray)),
        const SizedBox(height: 5),
        Text(
          value,
          style: AppTypography.h4.copyWith(color: AppColors.shieldNavy),
        ),
      ],
    ),
  );
}

class _ReferralEventCard extends StatelessWidget {
  const _ReferralEventCard({required this.event});

  final CustomerReferralEvent event;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Row(
      children: [
        const Icon(Icons.workspace_premium_outlined, color: AppColors.warning),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.status.isEmpty
                    ? 'Referral update'
                    : AppDisplayFormatters.formatStatusLabel(event.status),
                style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
              ),
              if (event.createdAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  AppDisplayFormatters.formatDateOrDateTime(
                    event.createdAt!.toIso8601String(),
                  ),
                  style: AppTypography.small.copyWith(color: AppColors.gray),
                ),
              ],
            ],
          ),
        ),
        Text(
          '${event.rewardPoints.toStringAsFixed(0)} pts',
          style: AppTypography.small,
        ),
      ],
    ),
  );
}
