import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProviderWorkspaceScaffold(
      builder: (context, ref, controller) {
        final activeTab = controller.resolvePatientTab(_routeTab(context));
        final selected = controller.selectedCustomer;
        final workspaceTabs = controller.patientWorkspaceTabs;
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
            Text(controller.patientSearchTitle, style: AppTypography.h4),
            const SizedBox(height: 8),
            Text(
              controller.patientSearchSubtitle,
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
                hintText: controller.patientSearchPlaceholder,
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
            if (controller.patientSearchSupportedQueries.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: controller.patientSearchSupportedQueries
                    .map((query) => _SearchHintChip(label: query))
                    .toList(),
              ),
            ],
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
                      controller.patientSearchEmptyStateMessage,
                      style: AppTypography.small.copyWith(color: AppColors.gray),
                    )
                  else
                    ...matchingCustomers.map(
                      (customer) => _CustomerResultTile(
                        title:
                            customer['fullName']?.toString() ?? 'SHIELD Member',
                        patientLabel: _patientLabel(customer),
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
              _WorkspaceEmptyState(
                message: controller.patientWorkspaceEmptyStateMessage,
              )
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
                    Text(controller.patientWorkspaceTitle, style: AppTypography.h4),
                    const SizedBox(height: 8),
                    Text(
                      controller.patientWorkspaceDescription,
                      style: AppTypography.small.copyWith(color: AppColors.gray),
                    ),
                    const SizedBox(height: 16),
                    _WorkspaceHeader(
                      name: selected.fullName,
                      subtitle:
                          'Patient ID: ${selected.customerCode} • ${selected.mobile}',
                      headerFields: controller.patientWorkspaceHeaderFields
                          .map(
                            (field) => <String, String>{
                              'title': field['title']?.toString() ?? '',
                              'value': controller.patientHeaderFieldValue(
                                field['code']?.toString() ?? '',
                              ),
                            },
                          )
                          .where((field) => field['value']?.trim().isNotEmpty ?? false)
                          .toList(),
                    ),
                    if (controller.patientWorkspaceQuickActions.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: controller.patientWorkspaceQuickActions
                            .map(
                              (action) => _QuickActionButton(
                                label: action['title']?.toString() ?? 'Open',
                                onTap: () => _openTab(
                                  context,
                                  controller.patientQuickActionTargetTab(action),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final tab in workspaceTabs)
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: ChoiceChip(
                                label: Text(
                                  tab['title']?.toString() ?? 'Section',
                                ),
                                selected:
                                    activeTab == tab['code']?.toString(),
                                onSelected: (_) {
                                  _openTab(
                                    context,
                                    tab['code']?.toString() ?? 'overview',
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _TabSectionHeader(
                      title: activeTab == 'timeline'
                          ? controller.timelineTitle
                          : controller.patientTabTitle(activeTab),
                      subtitle: _tabSubtitle(controller, activeTab),
                    ),
                    const SizedBox(height: 14),
                    _buildTabContent(controller, activeTab),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTabContent(dynamic controller, String activeTab) {
    switch (activeTab) {
      case 'timeline':
        final timeline = controller.selectedTimeline as List<Map<String, dynamic>>;
        if (timeline.isEmpty) {
          return _PanelText(controller.patientTabEmptyState(activeTab));
        }
        return Column(
          children: timeline
              .take(10)
              .map(
                (entry) => _TimelineTile(
                  kind: _timelineLabel(entry['kind']?.toString()),
                  title: entry['title']?.toString() ?? 'Activity',
                  subtitle: entry['subtitle']?.toString() ?? '',
                  timestamp: entry['timestamp'] as DateTime,
                ),
              )
              .toList(),
        );
      case 'today-visit':
        final upcoming = controller.selectedUpcomingAppointments as List<dynamic>;
        if (upcoming.isEmpty) {
          return _PanelText(controller.patientTabEmptyState(activeTab));
        }
        return Column(
          children: upcoming
              .take(3)
              .map(
                (appointment) => _SummaryCard(
                  title: appointment.typeLabel,
                  subtitle:
                      '${appointment.statusLabel} • ${appointment.doctorName ?? 'Provider'}',
                  meta: _formatTimelineDate(appointment.appointmentDate),
                ),
              )
              .toList(),
        );
      case 'appointments':
        final appointments = controller.selectedAppointments as List<dynamic>;
        if (appointments.isEmpty) {
          return _PanelText(controller.patientTabEmptyState(activeTab));
        }
        return Column(
          children: appointments
              .map(
                (appointment) => _SummaryCard(
                  title: appointment.typeLabel,
                  subtitle:
                      '${appointment.statusLabel} • ${appointment.doctorName ?? 'Provider'}',
                  meta: _formatTimelineDate(appointment.appointmentDate),
                ),
              )
              .toList(),
        );
      case 'records':
        final documents = controller.selectedRecentDocuments as List<dynamic>;
        if (documents.isEmpty) {
          return _PanelText(controller.patientTabEmptyState(activeTab));
        }
        return Column(
          children: documents
              .map(
                (document) => _SummaryCard(
                  title: document.fileName,
                  subtitle: '${document.typeLabel} • ${document.statusLabel}',
                  meta: document.extractionPreview ?? 'No preview available yet',
                ),
              )
              .toList(),
        );
      case 'payments':
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
              label: 'Wallet balance',
              value: controller.formatCurrency(cashWallet['available']),
            ),
            _MetricCard(
              label: 'Reward points',
              value: '${rewardWallet['available'] ?? 0}',
            ),
            _MetricCard(
              label: 'Credit available',
              value: controller.formatCurrency(
                controller.selectedWallet?['creditAvailable'],
              ),
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
      case 'history':
        final completed = controller.selectedCompletedAppointments as List<dynamic>;
        if (completed.isEmpty && activeTab == 'history') {
          return _PanelText(controller.patientTabEmptyState(activeTab));
        }
        if (activeTab == 'history') {
          return Column(
            children: completed
                .map(
                  (appointment) => _SummaryCard(
                    title: appointment.typeLabel,
                    subtitle:
                        '${appointment.statusLabel} • ${appointment.doctorName ?? 'Provider'}',
                    meta: _formatTimelineDate(appointment.appointmentDate),
                  ),
                )
                .toList(),
          );
        }
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(
              label: 'Upcoming appointments',
              value: '${controller.selectedUpcomingAppointments.length}',
            ),
            _MetricCard(
              label: 'Medical records',
              value: '${controller.selectedDocuments.length}',
            ),
            _MetricCard(
              label: 'Completed visits',
              value: '${controller.selectedCompletedAppointments.length}',
            ),
            _MetricCard(
              label: 'SHIELD card',
              value: controller.selectedCustomer?.shieldCardNumber ?? 'Pending',
            ),
          ],
        );
      default:
        return _PanelText(controller.patientTabEmptyState(activeTab));
    }
  }

  String _patientLabel(Map<String, dynamic> customer) {
    final customerCode = customer['customerCode']?.toString().trim() ?? '';
    if (customerCode.isNotEmpty) {
      return 'Patient ID: $customerCode';
    }
    return 'Patient';
  }

  String? _routeTab(BuildContext context) {
    return GoRouterState.of(context).uri.queryParameters['tab'];
  }

  void _openTab(BuildContext context, String tab) {
    final roleKey =
        GoRouterState.of(context).pathParameters['role'] ?? 'provider';
    context.go('/portal/$roleKey/customers?tab=$tab');
  }

  String _tabSubtitle(dynamic controller, String activeTab) {
    switch (activeTab) {
      case 'today-visit':
        return 'Keep the current visit, next steps, and live care work together for this patient.';
      case 'timeline':
        return controller.timelineSubtitle as String;
      case 'appointments':
        return 'Review upcoming and past appointments without leaving the patient workspace.';
      case 'records':
        return 'Open the latest uploaded records, reports, and supporting files for this patient.';
      case 'payments':
        return 'Check billing, wallet, and available credit in the same care view.';
      case 'membership':
        return 'Review membership details and coverage before continuing care.';
      case 'history':
        return 'See recently completed visits and the patient care history in one place.';
      case 'overview':
      default:
        return controller.patientWorkspaceDescription as String;
    }
  }
}

class _CustomerResultTile extends StatelessWidget {
  const _CustomerResultTile({
    required this.title,
    required this.patientLabel,
    required this.mobile,
    required this.membership,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String patientLabel;
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
                    '$patientLabel • $mobile',
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
              selected ? 'Open patient' : 'Patient details',
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
    required this.subtitle,
    required this.headerFields,
  });

  final String name;
  final String subtitle;
  final List<Map<String, String>> headerFields;

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
            subtitle,
            style: AppTypography.small.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: headerFields
                .map(
                  (field) => _HeaderChip(
                    label:
                        '${field['title'] ?? ''}: ${field['value'] ?? ''}',
                  ),
                )
                .toList(),
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

class _TabSectionHeader extends StatelessWidget {
  const _TabSectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.h5),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: AppTypography.small.copyWith(color: AppColors.gray),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.shieldBlue.withValues(alpha: 0.1),
        foregroundColor: AppColors.shieldBlue,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(label),
    );
  }
}

class _SearchHintChip extends StatelessWidget {
  const _SearchHintChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        label,
        style: AppTypography.tiny.copyWith(color: AppColors.darkGray),
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
            width: 88,
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
                  _formatTimelineDate(timestamp),
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
  const _WorkspaceEmptyState({required this.message});

  final String message;

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
        message,
        style: AppTypography.body.copyWith(color: AppColors.gray),
      ),
    );
  }
}

String _timelineLabel(String? rawKind) {
  switch ((rawKind ?? '').toUpperCase()) {
    case 'APPOINTMENT':
      return 'Visit';
    case 'DOCUMENT':
      return 'Record';
    default:
      return 'Activity';
  }
}

String _formatTimelineDate(DateTime timestamp) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final day = timestamp.day.toString().padLeft(2, '0');
  final month = months[timestamp.month - 1];
  final year = timestamp.year;
  final hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
  final minute = timestamp.minute.toString().padLeft(2, '0');
  final suffix = timestamp.hour >= 12 ? 'PM' : 'AM';
  return '$day $month $year • $hour:$minute $suffix';
}
