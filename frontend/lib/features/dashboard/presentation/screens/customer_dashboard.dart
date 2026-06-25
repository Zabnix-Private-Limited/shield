import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/models/customer.dart';
import '../../../../shared/models/wallet.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_page_frame.dart';
import '../../../../shared/widgets/app_responsive.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/widgets/portal_support.dart';
import '../../../../shared/services/api_service.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  late Future<Customer> _customerFuture;
  late Future<Map<String, dynamic>> _walletProfileFuture;
  late Future<List<WalletTransaction>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  void _loadDashboardData() {
    setState(() {
      _customerFuture = ApiService.getCustomerProfile('1');
      _walletProfileFuture = ApiService.getWalletProfile('1');
      _transactionsFuture = _walletProfileFuture.then((profile) {
        final walletId = profile['walletId'].toString();
        return ApiService.getWalletTransactions(walletId);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SHIELD'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              context.go('/notifications');
            },
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          _customerFuture,
          _walletProfileFuture,
          _transactionsFuture,
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppCustomerSectionSkeleton(
              showHero: true,
              showActionRow: true,
              statCards: 2,
              listItems: 5,
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text('Failed to load dashboard', style: AppTypography.h3),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: 16),
                    AppButton(text: 'Retry', onPressed: _loadDashboardData),
                  ],
                ),
              ),
            );
          }

          final customer = snapshot.data![0] as Customer;
          final walletProfile = snapshot.data![1] as Map<String, dynamic>;
          final txns = snapshot.data![2] as List<WalletTransaction>;

          final balance =
              double.tryParse(walletProfile['balance']?.toString() ?? '0') ??
              0.0;
          final pointsBalance =
              double.tryParse(
                walletProfile['pointsBalance']?.toString() ?? '0',
              ) ??
              0.0;
          final upcomingCount = txns.isEmpty
              ? 0
              : txns.where((txn) => txn.transactionType == 'DEBIT').length;
          final recommendedServices = [
            {
              'name': 'Pharmacy Reorder',
              'subtitle': 'Frequently purchased medicines ready',
            },
            {
              'name': 'Lab Follow-up',
              'subtitle': 'HbA1c and CBC packages available',
            },
            {
              'name': 'Dietitian Plan',
              'subtitle': 'Nutrition programs with loyalty rewards',
            },
          ];

          return RefreshIndicator(
            onRefresh: () async => _loadDashboardData(),
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              child: AppPageFrame(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${customer.firstName}!',
                      style: AppTypography.h3,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome back',
                      style: AppTypography.small.copyWith(
                        color: AppColors.gray,
                      ),
                    ),
                    const SizedBox(height: 18),
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Membership Card',
                                    style: AppTypography.small.copyWith(
                                      color: AppColors.gray,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    customer.customerCode,
                                    style: AppTypography.h4,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Founding Member • Perinthalmanna cluster',
                                    style: AppTypography.tiny.copyWith(
                                      color: AppColors.gray,
                                    ),
                                  ),
                                ],
                              ),
                              AppButton(
                                text: 'View Card',
                                height: 40,
                                onPressed: () => context.go('/membership'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _DashboardSummaryCard(
                            title: 'Wallet',
                            value: '₹${balance.toStringAsFixed(0)}',
                            subtitle: 'Available cash',
                            icon: Icons.account_balance_wallet_outlined,
                            color: AppColors.shieldNavy,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DashboardSummaryCard(
                            title: 'Points',
                            value: '${pointsBalance.toStringAsFixed(0)} pts',
                            subtitle: 'Rewards balance',
                            icon: Icons.stars_rounded,
                            color: AppColors.shieldBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.bolt_rounded,
                                color: AppColors.shieldBlue,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Quick wallet actions',
                                style: AppTypography.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  text: 'Recharge',
                                  type: AppButtonType.outline,
                                  onPressed: () {
                                    context.go('/portal/customer/recharge');
                                  },
                                  height: 42,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppButton(
                                  text: 'View Wallet',
                                  onPressed: () {
                                    context.go('/wallet');
                                  },
                                  height: 42,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Upcoming & Highlights', style: AppTypography.h4),
                        Text(
                          '$upcomingCount active actions',
                          style: AppTypography.tiny.copyWith(
                            color: AppColors.gray,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          _MiniInfoRow(
                            icon: Icons.event_available,
                            title: 'Upcoming Appointments',
                            subtitle:
                                'Track booked visits and upcoming care reminders.',
                            trailing: 'Open',
                            onTap: () => context.go('/appointments'),
                          ),
                          const Divider(height: 20),
                          _MiniInfoRow(
                            icon: Icons.notifications_active_outlined,
                            title: 'Notifications',
                            subtitle:
                                'Wallet credits, reports, and appointment alerts.',
                            trailing: 'View',
                            onTap: () => context.go('/notifications'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Recommended Services', style: AppTypography.h4),
                    const SizedBox(height: 12),
                    ...recommendedServices.map((service) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppCard(
                          onTap: () => context.go('/services'),
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.local_hospital_outlined,
                                color: AppColors.shieldBlue,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      service['name']!,
                                      style: AppTypography.body.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      service['subtitle']!,
                                      style: AppTypography.tiny.copyWith(
                                        color: AppColors.gray,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                    Text('Quick Actions', style: AppTypography.h4),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: AppResponsive.adaptiveGridCount(
                        context,
                        phoneCount: 2,
                        tabletCount: 3,
                        desktopCount: 3,
                        wideCount: 6,
                      ),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: AppResponsive.isPhone(context)
                          ? 1.45
                          : 1.35,
                      children: [
                        QuickActionCard(
                          icon: Icons.qr_code_scanner,
                          label: 'QR Card',
                          onTap: () {
                            context.go('/membership');
                          },
                        ),
                        QuickActionCard(
                          icon: Icons.receipt_long,
                          label: 'Recharge',
                          onTap: () {
                            context.go('/portal/customer/recharge');
                          },
                        ),
                        QuickActionCard(
                          icon: Icons.event_available,
                          label: 'Appointments',
                          onTap: () {
                            context.go('/appointments');
                          },
                        ),
                        QuickActionCard(
                          icon: Icons.description,
                          label: 'Documents',
                          onTap: () {
                            context.go('/documents');
                          },
                        ),
                        QuickActionCard(
                          icon: Icons.medical_services,
                          label: 'Prescriptions',
                          onTap: () {
                            context.go('/prescriptions');
                          },
                        ),
                        QuickActionCard(
                          icon: Icons.grid_view_rounded,
                          label: 'Services',
                          onTap: () {
                            context.go('/services');
                          },
                        ),
                        QuickActionCard(
                          icon: Icons.support_agent,
                          label: 'Support',
                          onTap: () {
                            showPortalSnackBar(
                              context,
                              'Support is available in the customer settings and SHIELD support portal pages.',
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Transactions', style: AppTypography.h5),
                        TextButton(
                          onPressed: () {
                            context.go('/transactions');
                          },
                          child: Text(
                            'View All',
                            style: AppTypography.small.copyWith(
                              color: AppColors.shieldBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...txns.take(3).map((txn) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: txn.transactionType == 'CREDIT'
                                      ? AppColors.shieldGreen.withValues(
                                          alpha: 0.1,
                                        )
                                      : AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  txn.transactionType == 'CREDIT'
                                      ? Icons.add
                                      : Icons.remove,
                                  color: txn.transactionType == 'CREDIT'
                                      ? AppColors.shieldGreen
                                      : AppColors.error,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      txn.remarks ?? 'Transaction',
                                      style: AppTypography.body.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${txn.createdAt.day}/${txn.createdAt.month}/${txn.createdAt.year}',
                                      style: AppTypography.tiny.copyWith(
                                        color: AppColors.gray,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${txn.transactionType == 'CREDIT' ? '+' : '-'}₹${txn.amount.toStringAsFixed(2)}',
                                style: AppTypography.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: txn.transactionType == 'CREDIT'
                                      ? AppColors.shieldGreen
                                      : AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MiniInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;
  final VoidCallback onTap;

  const _MiniInfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.shieldBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.tiny.copyWith(color: AppColors.gray),
                ),
              ],
            ),
          ),
          Text(
            trailing,
            style: AppTypography.small.copyWith(
              color: AppColors.shieldBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _DashboardSummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.tiny.copyWith(color: AppColors.gray),
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.h4.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.tiny.copyWith(color: AppColors.gray),
          ),
        ],
      ),
    );
  }
}

class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: AppColors.shieldBlue),
          const SizedBox(height: 6),
          Text(label, style: AppTypography.tiny, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
