import 'package:flutter/material.dart';

import '../../../../../../app/theme/app_colors.dart';
import '../../../../../../app/theme/app_typography.dart';
import '../../../shared/presentation/widgets/provider_workspace_scaffold.dart';

class ProviderCustomersScreen extends StatefulWidget {
  const ProviderCustomersScreen({super.key});

  @override
  State<ProviderCustomersScreen> createState() => _ProviderCustomersScreenState();
}

class _ProviderCustomersScreenState extends State<ProviderCustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeTab = 'overview';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProviderWorkspaceScaffold(
      builder: (context, ref, controller) {
        final selected = controller.selectedCustomer;
        final matchingCustomers = controller.customers.where((customer) {
          final query = _searchQuery.trim().toLowerCase();
          if (query.isEmpty) {
            return true;
          }
          final haystack = [
            customer['fullName'],
            customer['customerCode'],
            customer['mobile'],
            customer['membershipNumber'],
            customer['shieldCardNumber'],
            customer['city'],
          ].map((value) => value?.toString().toLowerCase() ?? '').join(' ');
          return haystack.contains(query);
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer workspace', style: AppTypography.h4),
            const SizedBox(height: 8),
            Text(
              'Search once and keep the entire member context in one operational workspace.',
              style: AppTypography.small.copyWith(color: AppColors.gray),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by name, customer code, phone, membership, or card',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  if (matchingCustomers.isEmpty)
                    Text(
                      'No provider-linked customers match this search yet.',
                      style: AppTypography.small.copyWith(color: AppColors.gray),
                    )
                  else
                    ...matchingCustomers.map(
                      (customer) => _CustomerResultTile(
                        title:
                            customer['fullName']?.toString() ?? 'SHIELD Member',
                        customerCode:
                            customer['customerCode']?.toString() ?? 'Customer',
                        mobile: customer['mobile']?.toString() ?? 'No mobile',
                        membership:
                            customer['membershipPlan']?.toString() ??
                            customer['membershipStatus']?.toString() ??
                            'Membership pending',
                        selected:
                            controller.selectedCustomerId ==
                            customer['id']?.toString(),
                        onTap: () => controller.selectCustomer(
                          customer['id']?.toString() ?? '',
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (controller.isCustomerLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (selected == null)
              _WorkspaceEmptyState()
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WorkspaceHeader(
                      name: selected.fullName,
                      customerCode: selected.customerCode,
                      mobile: selected.mobile,
                      membership: (((controller.selectedMembership?['membership']
                                          as Map<String, dynamic>?) ??
                                      const <String, dynamic>{})['membershipNumber'])
                                  ?.toString() ??
                              'Membership not issued',
                      cardNumber:
                          selected.shieldCardNumber ?? 'Card pending issuance',
                      bloodGroup: selected.bloodGroup ?? 'Not recorded',
                      location:
                          [selected.city, selected.district]
                              .whereType<String>()
                              .where((value) => value.trim().isNotEmpty)
                              .join(', ')
                              .ifEmpty('Location not recorded'),
                    ),
                    const SizedBox(height: 18),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final tab in const [
                            'overview',
                            'timeline',
                            'appointments',
                            'documents',
                            'wallet',
                            'membership',
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: ChoiceChip(
                                label: Text(_labelForTab(tab)),
                                selected: _activeTab == tab,
                                onSelected: (_) {
                                  setState(() {
                                    _activeTab = tab;
                                  });
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildTabContent(controller),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTabContent(dynamic controller) {
    switch (_activeTab) {
      case 'timeline':
        final timeline = controller.selectedTimeline as List<Map<String, dynamic>>;
        if (timeline.isEmpty) {
          return _PanelText(
            'No timeline events are available yet for this customer.',
          );
        }
        return Column(
          children: timeline
              .take(10)
              .map(
                (entry) => _TimelineTile(
                  kind: entry['kind']?.toString() ?? 'EVENT',
                  title: entry['title']?.toString() ?? 'Activity',
                  subtitle: entry['subtitle']?.toString() ?? '',
                  timestamp: entry['timestamp'] as DateTime,
                ),
              )
              .toList(),
        );
      case 'appointments':
        final appointments = controller.selectedAppointments as List<dynamic>;
        if (appointments.isEmpty) {
          return _PanelText(
            'No appointments are linked to this customer yet. New provider-facing scheduling and check-in workflows will land here.',
          );
        }
        return Column(
          children: appointments
              .map(
                (appointment) => _SummaryCard(
                  title: appointment.typeLabel,
                  subtitle:
                      '${appointment.statusLabel} • ${appointment.doctorName ?? 'Provider'}',
                  meta: appointment.appointmentDate.toString(),
                ),
              )
              .toList(),
        );
      case 'documents':
        final documents = controller.selectedRecentDocuments as List<dynamic>;
        if (documents.isEmpty) {
          return _PanelText(
            'No documents are uploaded yet. Prescription review, reports, and supporting files will appear here.',
          );
        }
        return Column(
          children: documents
              .map(
                (document) => _SummaryCard(
                  title: document.fileName,
                  subtitle: '${document.typeLabel} • ${document.statusLabel}',
                  meta: document.extractionPreview ?? 'No extracted preview yet',
                ),
              )
              .toList(),
        );
      case 'wallet':
        final cashWallet =
            controller.selectedWallet?['cashWallet'] as Map<String, dynamic>? ??
            const <String, dynamic>{};
        final rewardWallet =
            controller.selectedWallet?['rewardPoints'] as Map<String, dynamic>? ??
            const <String, dynamic>{};
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(
              label: 'Cash available',
              value: 'Rs ${cashWallet['available'] ?? 0}',
            ),
            _MetricCard(
              label: 'Reward points',
              value: '${rewardWallet['available'] ?? 0}',
            ),
            _MetricCard(
              label: 'Credit available',
              value:
                  'Rs ${controller.selectedWallet?['creditAvailable'] ?? 0}',
            ),
          ],
        );
      case 'membership':
        final membership =
            controller.selectedMembership?['membership'] as Map<String, dynamic>? ??
            const <String, dynamic>{};
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(
              label: 'Membership number',
              value: membership['membershipNumber']?.toString() ?? 'Pending',
            ),
            _MetricCard(
              label: 'Status',
              value: membership['status']?.toString() ?? 'Pending',
            ),
            _MetricCard(
              label: 'Plan',
              value:
                  membership['membershipType']?['name']?.toString() ??
                  'Not assigned',
            ),
          ],
        );
      case 'overview':
      default:
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(
              label: 'Upcoming appointments',
              value: '${controller.selectedUpcomingAppointments.length}',
            ),
            _MetricCard(
              label: 'Document count',
              value: '${controller.selectedDocuments.length}',
            ),
            _MetricCard(
              label: 'Completed visits',
              value: '${controller.selectedCompletedAppointments.length}',
            ),
            _MetricCard(
              label: 'Card',
              value: controller.selectedCustomer?.shieldCardNumber ?? 'Pending',
            ),
          ],
        );
    }
  }

  String _labelForTab(String value) {
    switch (value) {
      case 'timeline':
        return 'Timeline';
      case 'appointments':
        return 'Appointments';
      case 'documents':
        return 'Documents';
      case 'wallet':
        return 'Wallet';
      case 'membership':
        return 'Membership';
      case 'overview':
      default:
        return 'Overview';
    }
  }
}

class _CustomerResultTile extends StatelessWidget {
  const _CustomerResultTile({
    required this.title,
    required this.customerCode,
    required this.mobile,
    required this.membership,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String customerCode;
  final String mobile;
  final String membership;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.shieldBlue.withValues(alpha: 0.08)
              : AppColors.lightGray,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.shieldBlue : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.body),
                  const SizedBox(height: 4),
                  Text(
                    '$customerCode • $mobile',
                    style: AppTypography.small.copyWith(color: AppColors.gray),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    membership,
                    style: AppTypography.tiny.copyWith(color: AppColors.darkGray),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              selected ? 'Open' : 'Workspace',
              style: AppTypography.small.copyWith(
                color: AppColors.shieldBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceHeader extends StatelessWidget {
  const _WorkspaceHeader({
    required this.name,
    required this.customerCode,
    required this.mobile,
    required this.membership,
    required this.cardNumber,
    required this.bloodGroup,
    required this.location,
  });

  final String name;
  final String customerCode;
  final String mobile;
  final String membership;
  final String cardNumber;
  final String bloodGroup;
  final String location;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.shieldNavy, Color(0xFF21438C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: AppTypography.h3.copyWith(color: Colors.white)),
          const SizedBox(height: 6),
          Text(
            '$customerCode • $mobile',
            style: AppTypography.small.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeaderChip(label: membership),
              _HeaderChip(label: cardNumber),
              _HeaderChip(label: 'Blood group: $bloodGroup'),
              _HeaderChip(label: location),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.tiny.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.small.copyWith(color: AppColors.gray)),
          const SizedBox(height: 8),
          Text(value, style: AppTypography.h5),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.subtitle,
    required this.meta,
  });

  final String title;
  final String subtitle;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.body),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTypography.small),
          const SizedBox(height: 6),
          Text(meta, style: AppTypography.tiny.copyWith(color: AppColors.gray)),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.timestamp,
  });

  final String kind;
  final String title;
  final String subtitle;
  final DateTime timestamp;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 68,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              kind,
              style: AppTypography.tiny.copyWith(
                color: AppColors.shieldBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 6),
                Text(
                  timestamp.toString(),
                  style: AppTypography.tiny.copyWith(color: AppColors.gray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelText extends StatelessWidget {
  const _PanelText(this.message);

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

class _WorkspaceEmptyState extends StatelessWidget {
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
        'Select a provider-linked customer to open the single workspace view. This screen is intended to become the main surface for appointments, documents, prescriptions, timeline, wallet, and membership context.',
        style: AppTypography.body.copyWith(color: AppColors.gray),
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}
