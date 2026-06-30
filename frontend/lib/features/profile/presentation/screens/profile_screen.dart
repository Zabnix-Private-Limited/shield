import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/models/customer.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_page_frame.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Customer> _customerFuture;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    setState(() {
      _customerFuture = ApiService.getCustomerProfile(
        ApiService.requireAuthenticatedCustomerId(),
      );
    });
  }

  String _calculateAge(DateTime? dob) {
    if (dob == null) return 'N/A';
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return '$age years';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.go('/settings');
            },
          ),
        ],
      ),
      body: FutureBuilder<Customer>(
        future: _customerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppCustomerSectionSkeleton(
              showHero: true,
              showActionRow: false,
              statCards: 2,
              listItems: 4,
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
                    Text('Failed to load profile', style: AppTypography.h3),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: 16),
                    AppButton(text: 'Retry', onPressed: _loadProfile),
                  ],
                ),
              ),
            );
          }

          final customer = snapshot.data!;

          return SingleChildScrollView(
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            child: AppPageFrame(
              child: Column(
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppColors.shieldBlue.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 48,
                              color: AppColors.shieldBlue,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(customer.fullName, style: AppTypography.h3),
                          const SizedBox(height: 4),
                          Text(
                            customer.customerCode,
                            style: AppTypography.small.copyWith(
                              color: AppColors.gray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            'Personal Information',
                            style: AppTypography.h4,
                          ),
                        ),
                        _InfoRow(label: 'Mobile', value: customer.mobile),
                        const Divider(height: 32),
                        _InfoRow(
                          label: 'Email',
                          value: customer.email ?? 'Not provided',
                        ),
                        const Divider(height: 32),
                        _InfoRow(
                          label: 'Date of Birth',
                          value: customer.dob != null
                              ? '${customer.dob!.day}/${customer.dob!.month}/${customer.dob!.year} (${_calculateAge(customer.dob)})'
                              : 'Not provided',
                        ),
                        const Divider(height: 32),
                        _InfoRow(
                          label: 'Gender',
                          value: customer.gender ?? 'Not provided',
                        ),
                        const Divider(height: 32),
                        _InfoRow(
                          label: 'Blood Group',
                          value: customer.bloodGroup ?? 'Not provided',
                        ),
                        const Divider(height: 32),
                        _InfoRow(
                          label: 'Aadhaar',
                          value: customer.aadhaarNumber.length >= 4
                              ? '****${customer.aadhaarNumber.substring(customer.aadhaarNumber.length - 4)}'
                              : customer.aadhaarNumber,
                        ),
                        const Divider(height: 32),
                        _InfoRow(
                          label: 'Onboarding Agent Code',
                          value: customer.agentCode ?? 'Not provided',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text('Address', style: AppTypography.h4),
                        ),
                        Text(
                          [
                            customer.addressLine1,
                            customer.addressLine2,
                            customer.city,
                            customer.district,
                            customer.state,
                            customer.pincode,
                          ].where((e) => e != null && e.isNotEmpty).join(', '),
                          style: AppTypography.body,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppCard(
                    onTap: () {
                      context.go('/membership');
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Text(
                                  'Membership',
                                  style: AppTypography.h4,
                                ),
                              ),
                              _InfoRow(
                                label: 'Status',
                                value: customer.status,
                                isStatus: true,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppColors.gray,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isStatus;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.small.copyWith(color: AppColors.gray)),
        Text(
          value,
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w500,
            color: isStatus
                ? value == 'ACTIVE'
                      ? AppColors.shieldGreen
                      : AppColors.warning
                : null,
          ),
        ),
      ],
    );
  }
}
