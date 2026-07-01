import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../app/theme/app_colors.dart';
import '../../../../../../app/theme/app_typography.dart';
import '../../../../../../shared/models/appointment.dart';
import '../../../../../../shared/services/platform_file_actions.dart';
import '../../../shared/presentation/widgets/provider_workspace_scaffold.dart';

class ProviderCustomersScreen extends StatefulWidget {
  const ProviderCustomersScreen({
    super.key,
    this.forcedTab,
  });

  final String? forcedTab;

  @override
  State<ProviderCustomersScreen> createState() => _ProviderCustomersScreenState();
}

class _ProviderCustomersScreenState extends State<ProviderCustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _chiefComplaintController = TextEditingController();
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _clinicalFindingsController =
      TextEditingController();
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _adviceController = TextEditingController();
  final TextEditingController _proceduresController = TextEditingController();
  final TextEditingController _labOrdersController = TextEditingController();
  final TextEditingController _followUpController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _searchQuery = '';
  String? _syncedConsultationKey;

  @override
  void dispose() {
    _searchController.dispose();
    _chiefComplaintController.dispose();
    _symptomsController.dispose();
    _clinicalFindingsController.dispose();
    _diagnosisController.dispose();
    _adviceController.dispose();
    _proceduresController.dispose();
    _labOrdersController.dispose();
    _followUpController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProviderWorkspaceScaffold(
      builder: (context, ref, controller) {
        final roleKey =
            GoRouterState.of(context).pathParameters['role'] ?? 'provider';
        final activeTab =
            controller.resolvePatientTab(widget.forcedTab ?? _routeTab(context));
        final selected = controller.selectedCustomer;
        final workspaceTabs = controller.patientWorkspaceTabs;
        _syncConsultationEditors(controller);
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
                    _buildTabContent(
                      context,
                      controller,
                      activeTab,
                      roleKey: roleKey,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    dynamic controller,
    String activeTab, {
    required String roleKey,
  }) {
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
        if (controller.activeVisitAppointmentId == null) {
          return _PanelText(controller.patientTabEmptyState(activeTab));
        }
        return _buildTodayVisitContent(context, controller);
      case 'appointments':
        final appointments = controller.selectedAppointments as List<dynamic>;
        if (appointments.isEmpty) {
          return _PanelText(controller.patientTabEmptyState(activeTab));
        }
        return Column(
          children: appointments
              .map(
                (appointment) => Container(
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
                      Text(appointment.typeLabel, style: AppTypography.body),
                      const SizedBox(height: 4),
                      Text(
                        '${appointment.statusLabel} • ${appointment.doctorName ?? 'Provider'}',
                        style: AppTypography.small,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatTimelineDate(appointment.appointmentDate),
                        style: AppTypography.tiny.copyWith(color: AppColors.gray),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () async {
                              await controller.openAppointmentWorkflow(
                                appointment,
                                loadConsultation: false,
                              );
                              if (!context.mounted) {
                                return;
                              }
                              context.go('/portal/$roleKey/customers?tab=overview');
                            },
                            child: const Text('Open Patient'),
                          ),
                          FilledButton(
                            onPressed: controller.isConsultationSaving
                                ? null
                                : () async {
                                    await controller.openAppointmentWorkflow(
                                      appointment,
                                      loadConsultation: true,
                                    );
                                    if (!context.mounted) {
                                      return;
                                    }
                                    context.go('/portal/$roleKey/customers?tab=today-visit');
                                  },
                            child: Text(
                              appointment.status == AppointmentStatus.completed
                                  ? 'View Visit'
                                  : 'Open Visit',
                            ),
                          ),
                          if (appointment.status == AppointmentStatus.scheduled)
                            OutlinedButton(
                              onPressed: controller.isConsultationSaving
                                  ? null
                                  : () => _handleAppointmentMutation(
                                        context,
                                        controller: controller,
                                        actionLabel: 'Appointment confirmed',
                                        action: () => controller.confirmAppointment(
                                          appointment.id,
                                        ),
                                      ),
                              child: const Text('Accept'),
                            ),
                          if (appointment.status != AppointmentStatus.completed &&
                              appointment.status != AppointmentStatus.cancelled)
                            OutlinedButton(
                              onPressed: controller.isConsultationSaving
                                  ? null
                                  : () => _handleAppointmentMutation(
                                        context,
                                        controller: controller,
                                        actionLabel: 'Appointment cancelled',
                                        action: () => controller.cancelAppointment(
                                          appointment.id,
                                        ),
                                      ),
                              child: const Text('Cancel'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        );
      case 'records':
        final prescriptions =
            controller.selectedPrescriptionDocuments as List<dynamic>;
        final labReports =
            controller.selectedLabReportDocuments as List<dynamic>;
        final invoices = controller.selectedInvoiceDocuments as List<dynamic>;
        final otherDocuments = controller.selectedOtherDocuments as List<dynamic>;
        final documents = [
          ...prescriptions,
          ...labReports,
          ...invoices,
          ...otherDocuments,
        ];
        if (documents.isEmpty) {
          return _PanelText(controller.patientTabEmptyState(activeTab));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDocumentGroup(
              context: context,
              controller: controller,
              title: 'Prescriptions',
              documents: prescriptions,
              emptyMessage: 'No prescription files are linked to this patient yet.',
            ),
            const SizedBox(height: 14),
            _buildDocumentGroup(
              context: context,
              controller: controller,
              title: 'Lab Reports',
              documents: labReports,
              emptyMessage: 'No lab reports have been uploaded yet.',
            ),
            const SizedBox(height: 14),
            _buildDocumentGroup(
              context: context,
              controller: controller,
              title: 'Invoices',
              documents: invoices,
              emptyMessage: 'No invoice files are available yet.',
            ),
            const SizedBox(height: 14),
            _buildDocumentGroup(
              context: context,
              controller: controller,
              title: 'Other Records',
              documents: otherDocuments,
              emptyMessage: 'No additional medical records are available yet.',
            ),
          ],
        );
      case 'activity':
        final notifications = controller.selectedNotifications as List<dynamic>;
        if (notifications.isEmpty) {
          return _ActionEmptyState(
            title: 'No recent updates yet',
            message:
                'Patient alerts, payment updates, prescriptions, and follow-up reminders will appear here as activity happens.',
            actionLabel: 'Open Timeline',
            onAction: () => _openTab(context, 'timeline'),
          );
        }
        return Column(
          children: notifications
              .take(8)
              .map(
                (notification) => _SummaryCard(
                  title: notification.title,
                  subtitle:
                      '${notification.typeLabel} • ${notification.isRead ? 'Read' : 'Unread'}',
                  meta:
                      '${notification.body} • ${_formatTimelineDate(notification.createdAt)}',
                ),
              )
              .toList(),
        );
      case 'print':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TabSectionHeader(
              title: 'Printable Documents',
              subtitle:
                  'Generate visit-ready documents directly from the patient record.',
            ),
            const SizedBox(height: 10),
            _buildPrintActions(context, controller),
          ],
        );
      case 'reports':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TabSectionHeader(
              title: 'Care Reports',
              subtitle:
                  'Export patient and provider care summaries without leaving this record.',
            ),
            const SizedBox(height: 10),
            _buildReportActions(context, controller),
          ],
        );
      case 'payments':
        final cashWallet =
            controller.selectedWallet?['cashWallet'] as Map<String, dynamic>? ??
            const <String, dynamic>{};
        final rewardWallet =
            controller.selectedWallet?['rewardPoints'] as Map<String, dynamic>? ??
            const <String, dynamic>{};
        final benefitSummary =
            controller.selectedBenefitSummary as Map<String, dynamic>;
        final walletStatistics =
            controller.selectedWalletStatistics as Map<String, dynamic>;
        final purchases = controller.selectedPurchases as List<dynamic>;
        final walletTransactions =
            controller.selectedWalletTransactions as List<dynamic>;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
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
                _MetricCard(
                  label: 'Benefits used',
                  value: controller.formatCurrency(
                    benefitSummary['benefitsUsed'],
                  ),
                ),
                _MetricCard(
                  label: 'Monthly spend',
                  value: controller.formatCurrency(
                    walletStatistics['monthlySpend'],
                  ),
                ),
                _MetricCard(
                  label: 'Invoices',
                  value: '${purchases.length}',
                ),
              ],
            ),
            const SizedBox(height: 18),
            _TabSectionHeader(
              title: 'Recent Billing',
              subtitle:
                  'Latest invoices, wallet deductions, and benefit usage linked to this patient.',
            ),
            const SizedBox(height: 10),
            if (purchases.isEmpty)
              _PanelText('No patient billing details are available yet.')
            else
              Column(
                children: purchases.take(5).map((purchase) {
                  final items =
                      (purchase['purchaseItems'] as List? ?? const <dynamic>[]);
                  final itemCount = items.length;
                  return _SummaryCard(
                    title:
                        purchase['invoiceNumber']?.toString() ??
                        purchase['invoice_number']?.toString() ??
                        'Invoice',
                    subtitle:
                        '${itemCount.toString()} line item${itemCount == 1 ? '' : 's'} • ${controller.formatCurrency(purchase['payableAmount'] ?? purchase['payable_amount'])}',
                    meta:
                        'Discount ${controller.formatCurrency(purchase['discountAmount'] ?? purchase['discount_amount'])}',
                  );
                }).toList(),
              ),
            const SizedBox(height: 18),
            _TabSectionHeader(
              title: 'Recent Wallet Activity',
              subtitle:
                  'Latest credits and debits that affected this patient during care.',
            ),
            const SizedBox(height: 10),
            if (walletTransactions.isEmpty)
              _PanelText('No wallet activity has been recorded yet.')
            else
              Column(
                children: walletTransactions.take(5).map((transaction) {
                  return _SummaryCard(
                    title: transaction.remarks?.toString().trim().isNotEmpty == true
                        ? transaction.remarks.toString()
                        : transaction.isCredit
                        ? 'Wallet credit'
                        : 'Wallet debit',
                    subtitle:
                        '${transaction.subLedgerType} • ${transaction.isCredit ? 'Credit' : 'Debit'}',
                    meta:
                        '${controller.formatCurrency(transaction.amount)} • ${_formatTimelineDate(transaction.createdAt)}',
                  );
                }).toList(),
              ),
            const SizedBox(height: 18),
            _TabSectionHeader(
              title: 'Documents and Exports',
              subtitle:
                  'Generate patient-ready documents and exports from the current care record.',
            ),
            const SizedBox(height: 10),
            _buildPrintAndReportActions(context, controller, includeReports: true),
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
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
                  value:
                      controller.selectedCustomer?.shieldCardNumber ?? 'Pending',
                ),
                _MetricCard(
                  label: 'Prescriptions',
                  value: '${controller.selectedPrescriptionDocuments.length}',
                ),
                _MetricCard(
                  label: 'Notifications',
                  value: '${controller.selectedNotifications.length}',
                ),
                _MetricCard(
                  label: 'Live Updates',
                  value:
                      controller.isRealtimeConnected
                          ? 'Live'
                          : 'Connecting',
                ),
                _MetricCard(
                  label: 'Billing total',
                  value: controller.formatCurrency(
                    controller.selectedTotalPurchaseValue,
                  ),
                ),
                _MetricCard(
                  label: 'Benefits used',
                  value: controller.formatCurrency(
                    controller.selectedBenefitSummary['benefitsUsed'],
                  ),
                ),
                _MetricCard(
                  label: 'Printable Forms',
                  value: '${controller.availablePrintTemplates.length}',
                ),
                _MetricCard(
                  label: 'Reports',
                  value: '${controller.availableReports.length}',
                ),
              ],
            ),
            const SizedBox(height: 18),
            _TabSectionHeader(
              title: 'Print and Export',
              subtitle:
                  'Generate patient documents, visit summaries, and exports from this record.',
            ),
            const SizedBox(height: 10),
            _buildPrintAndReportActions(context, controller, includeReports: true),
          ],
        );
      default:
        return _PanelText(controller.patientTabEmptyState(activeTab));
    }
  }

  Widget _buildTodayVisitContent(BuildContext context, dynamic controller) {
    if (controller.isConsultationLoading &&
        controller.consultationWorkspace.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final visit = controller.activeVisitSummary as Map<String, dynamic>;
    final statusSummary =
        controller.activeVisitStatusSummary as Map<String, dynamic>;
    final billing = controller.activeVisitBilling as Map<String, dynamic>;
    final actions = controller.consultationActions as List<Map<String, dynamic>>;
    final sections =
        controller.consultationFormSections as List<Map<String, dynamic>>;
    final timeline = controller.activeVisitTimeline as List<Map<String, dynamic>>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _VisitSummaryCard(
          title: visit['title']?.toString() ?? 'Current Visit',
          subtitle:
              visit['subtitle']?.toString() ?? 'Care activity is in progress for this patient.',
          appointmentDateLabel:
              visit['appointmentDateLabel']?.toString() ?? 'Time not scheduled',
          statusLabel: controller.activeVisitStatusLabel,
          reason: visit['reason']?.toString() ?? 'Visit reason not recorded yet.',
          prescriptionCount: visit['prescriptionCount']?.toString() ?? '0',
        ),
        const SizedBox(height: 16),
        _VisitStatusSummaryCard(statusSummary: statusSummary),
        const SizedBox(height: 16),
        if (actions.isNotEmpty)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: actions
                .map(
                  (action) => _ConsultationActionButton(
                    label: action['title']?.toString() ?? 'Continue',
                    primary:
                        (action['emphasis']?.toString() ?? '').toLowerCase() ==
                        'primary',
                    loading: controller.isConsultationSaving as bool,
                    onTap: () => _handleConsultationAction(
                      context,
                      controller,
                      action['code']?.toString() ?? '',
                    ),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 18),
        ...sections.map(
          (section) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _ConsultationField(
              title: section['title']?.toString() ?? 'Notes',
              placeholder:
                  section['placeholder']?.toString() ?? 'Add visit notes',
              controller: _controllerForConsultationField(
                section['code']?.toString() ?? '',
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        _VisitBillingCard(
          billing: billing,
          busy: controller.isConsultationSaving as bool,
          onEditBilling: () => _showBillingDraftDialog(
            context,
            controller,
            generateInvoiceAfterSave: false,
          ),
          onGenerateInvoice: () => _showBillingDraftDialog(
            context,
            controller,
            generateInvoiceAfterSave: true,
          ),
          onRecordPayment: () => _showPaymentDialog(context, controller),
        ),
        const SizedBox(height: 18),
        Text('Visit timeline', style: AppTypography.h5),
        const SizedBox(height: 10),
        if (timeline.isEmpty)
          _ActionEmptyState(
            title: 'No visit updates yet',
            message:
                'Start the visit or save consultation progress to build the care timeline here.',
            actionLabel: 'Save Progress',
            onAction: () => _handleConsultationAction(
              context,
              controller,
              'SAVE_PROGRESS',
            ),
          )
        else
          Column(
            children: timeline
                .map(
                  (entry) => _TimelineTile(
                    kind: _timelineLabel(entry['code']?.toString()),
                    title: entry['title']?.toString() ?? 'Visit update',
                    subtitle: entry['subtitle']?.toString() ?? '',
                    timestamp:
                        DateTime.tryParse(
                          entry['timestamp']?.toString() ?? '',
                        ) ??
                        DateTime.now(),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Future<void> _handleConsultationAction(
    BuildContext context,
    dynamic controller,
    String actionCode,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final payload = _consultationFormPayload();
    var performed = true;
    switch (actionCode) {
      case 'START_CONSULTATION':
        await controller.startConsultationForActiveVisit();
        break;
      case 'SAVE_BILLING':
        performed = await _showBillingDraftDialog(
          context,
          controller,
          generateInvoiceAfterSave: false,
        );
        break;
      case 'GENERATE_INVOICE':
        performed = await _showBillingDraftDialog(
          context,
          controller,
          generateInvoiceAfterSave: true,
        );
        break;
      case 'RECORD_PAYMENT':
        performed = await _showPaymentDialog(context, controller);
        break;
      case 'COMPLETE_VISIT':
        await controller.completeActiveConsultation(payload);
        break;
      case 'SAVE_PROGRESS':
      default:
        await controller.saveActiveConsultation(payload);
        break;
    }

    if (!mounted) {
      return;
    }

    if (!performed) {
      return;
    }

    final error = controller.error?.toString().trim();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error != null && error.isNotEmpty
              ? _friendlyProviderError(error)
              : _consultationActionMessage(actionCode),
        ),
      ),
    );
  }

  Widget _buildPrintAndReportActions(
    BuildContext context,
    dynamic controller, {
    required bool includeReports,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton(
                onPressed: () => _downloadPrintArtifact(
                  context,
                  controller,
                  'VISIT_SUMMARY',
                ),
                child: const Text('Visit Summary'),
              ),
              OutlinedButton(
                onPressed: () => _downloadPrintArtifact(
                  context,
                  controller,
                  'PRESCRIPTION',
                ),
                child: const Text('Prescription'),
              ),
              OutlinedButton(
                onPressed: () => _downloadPrintArtifact(
                  context,
                  controller,
                  'INVOICE',
                ),
                child: const Text('Invoice'),
              ),
            ],
          ),
          if (includeReports) ...[
            const SizedBox(height: 12),
            _buildReportButtons(context, controller),
          ],
          const SizedBox(height: 12),
          Text(
            controller.isRealtimeConnected
                ? 'Live updates are active${controller.lastPlatformEventType != null ? ' • Last update: ${controller.lastPlatformEventType}' : ''}'
                : 'Live updates are connecting for this patient record.',
            style: AppTypography.tiny.copyWith(color: AppColors.gray),
          ),
        ],
      ),
    );
  }

  Widget _buildPrintActions(BuildContext context, dynamic controller) {
    return _buildPrintAndReportActions(
      context,
      controller,
      includeReports: false,
    );
  }

  Widget _buildReportActions(BuildContext context, dynamic controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: _buildReportButtons(context, controller),
    );
  }

  Widget _buildReportButtons(BuildContext context, dynamic controller) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        FilledButton(
          onPressed: () => _exportReportArtifact(
            context,
            controller,
            'PROVIDER_DAILY_REVENUE',
            'PDF',
          ),
          child: const Text('Daily Revenue PDF'),
        ),
        OutlinedButton(
          onPressed: () => _exportReportArtifact(
            context,
            controller,
            'PROVIDER_APPOINTMENTS',
            'CSV',
          ),
          child: const Text('Appointments CSV'),
        ),
        OutlinedButton(
          onPressed: () => _exportReportArtifact(
            context,
            controller,
            'PROVIDER_PRESCRIPTION_STATISTICS',
            'EXCEL',
          ),
          child: const Text('Prescriptions Excel'),
        ),
      ],
    );
  }

  Future<void> _downloadPrintArtifact(
    BuildContext context,
    dynamic controller,
    String templateId,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await controller.generatePatientPrint(templateId)
          as Map<String, dynamic>;
      final downloaded = await downloadPlatformFile(
        fileName: result['fileName']?.toString() ?? '$templateId.pdf',
        mimeType: result['mimeType']?.toString() ?? 'application/pdf',
        contentBase64: result['contentBase64']?.toString() ?? '',
      );
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            downloaded
                ? 'Document ready: ${result['fileName'] ?? templateId}'
                : 'The document is ready, but automatic download is not available on this device.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(
          content: Text('We could not generate that document right now.'),
        ),
      );
    }
  }

  Future<void> _exportReportArtifact(
    BuildContext context,
    dynamic controller,
    String reportId,
    String format,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await controller.runProviderReport(
            reportId,
            format: format,
          )
          as Map<String, dynamic>;
      final exportFile =
          result['exportFile'] is Map
              ? Map<String, dynamic>.from(result['exportFile'] as Map)
              : const <String, dynamic>{};
      if (exportFile.isEmpty) {
        throw StateError('The shared report export is empty.');
      }
      final downloaded = await downloadPlatformFile(
        fileName: exportFile['fileName']?.toString() ?? '$reportId.$format',
        mimeType:
            exportFile['mimeType']?.toString() ?? 'application/octet-stream',
        contentBase64: exportFile['contentBase64']?.toString() ?? '',
      );
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            downloaded
                ? 'Report ready: ${exportFile['fileName'] ?? reportId}'
                : 'The report is ready, but automatic download is not available on this device.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(
          content: Text('We could not export that report right now.'),
        ),
      );
    }
  }

  Map<String, String> _consultationFormPayload() => {
    'chiefComplaint': _chiefComplaintController.text,
    'symptoms': _symptomsController.text,
    'clinicalFindings': _clinicalFindingsController.text,
    'diagnosis': _diagnosisController.text,
    'advice': _adviceController.text,
    'procedures': _proceduresController.text,
    'labOrders': _labOrdersController.text,
    'followUp': _followUpController.text,
    'providerNotes': _notesController.text,
  };

  TextEditingController _controllerForConsultationField(String code) {
    switch (code) {
      case 'chiefComplaint':
        return _chiefComplaintController;
      case 'symptoms':
        return _symptomsController;
      case 'clinicalFindings':
        return _clinicalFindingsController;
      case 'diagnosis':
        return _diagnosisController;
      case 'advice':
        return _adviceController;
      case 'procedures':
        return _proceduresController;
      case 'labOrders':
        return _labOrdersController;
      case 'followUp':
        return _followUpController;
      case 'providerNotes':
      default:
        return _notesController;
    }
  }

  void _syncConsultationEditors(dynamic controller) {
    final appointmentId = controller.activeVisitAppointmentId?.toString() ?? '';
    final consultationId =
        controller.consultationWorkspace['consultationId']?.toString() ?? '';
    final statusCode =
        controller.consultationWorkspace['statusCode']?.toString() ?? '';
    final syncKey = '$appointmentId|$consultationId|$statusCode';
    if (_syncedConsultationKey == syncKey || appointmentId.isEmpty) {
      return;
    }

    _chiefComplaintController.text =
        controller.consultationFieldValue('chiefComplaint');
    _symptomsController.text = controller.consultationFieldValue('symptoms');
    _clinicalFindingsController.text =
        controller.consultationFieldValue('clinicalFindings');
    _diagnosisController.text = controller.consultationFieldValue('diagnosis');
    _adviceController.text = controller.consultationFieldValue('advice');
    _proceduresController.text = controller.consultationFieldValue('procedures');
    _labOrdersController.text = controller.consultationFieldValue('labOrders');
    _followUpController.text = controller.consultationFieldValue('followUp');
    _notesController.text = controller.consultationFieldValue('providerNotes');
    _syncedConsultationKey = syncKey;
  }

  String _consultationActionMessage(String actionCode) {
    switch (actionCode) {
      case 'START_CONSULTATION':
        return 'Consultation started.';
      case 'COMPLETE_VISIT':
        return 'Visit completed and saved.';
      case 'SAVE_BILLING':
        return 'Visit billing saved.';
      case 'GENERATE_INVOICE':
        return 'Invoice generated for this visit.';
      case 'RECORD_PAYMENT':
        return 'Payment recorded for this visit.';
      case 'SAVE_PROGRESS':
      default:
        return 'Visit notes saved.';
    }
  }

  Future<bool> _showBillingDraftDialog(
    BuildContext context,
    dynamic controller, {
    required bool generateInvoiceAfterSave,
  }) async {
    final draft = Map<String, dynamic>.from(
      controller.activeVisitBilling['draft'] as Map? ?? const {},
    );
    final consultationFeeController = TextEditingController(
      text: '${draft['consultationFee'] ?? 0}',
    );
    final proceduresAmountController = TextEditingController(
      text: '${draft['proceduresAmount'] ?? 0}',
    );
    final medicinesAmountController = TextEditingController(
      text: '${draft['medicinesAmount'] ?? 0}',
    );
    final labTestsAmountController = TextEditingController(
      text: '${draft['labTestsAmount'] ?? 0}',
    );
    final otherServicesAmountController = TextEditingController(
      text: '${draft['otherServicesAmount'] ?? 0}',
    );
    final otherServicesLabelController = TextEditingController(
      text: draft['otherServicesLabel']?.toString() ?? 'Other Services',
    );
    final manualDiscountController = TextEditingController(
      text: '${draft['manualDiscountAmount'] ?? 0}',
    );
    final taxPercentController = TextEditingController(
      text: '${draft['taxPercent'] ?? 0}',
    );

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            generateInvoiceAfterSave ? 'Generate Invoice' : 'Save Visit Billing',
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DialogAmountField(
                    controller: consultationFeeController,
                    label: 'Consultation Fee',
                  ),
                  _DialogAmountField(
                    controller: proceduresAmountController,
                    label: 'Procedures',
                  ),
                  _DialogAmountField(
                    controller: medicinesAmountController,
                    label: 'Medicines',
                  ),
                  _DialogAmountField(
                    controller: labTestsAmountController,
                    label: 'Lab Tests',
                  ),
                  TextField(
                    controller: otherServicesLabelController,
                    decoration: const InputDecoration(
                      labelText: 'Other Service Label',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DialogAmountField(
                    controller: otherServicesAmountController,
                    label: 'Other Services',
                  ),
                  _DialogAmountField(
                    controller: manualDiscountController,
                    label: 'Manual Discount',
                  ),
                  _DialogAmountField(
                    controller: taxPercentController,
                    label: 'Tax Percentage',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(generateInvoiceAfterSave ? 'Generate' : 'Save'),
            ),
          ],
        );
      },
    );

    if (shouldSubmit != true) {
      return false;
    }

    final billingDraft = {
      'consultationFee': _parseAmount(consultationFeeController.text),
      'proceduresAmount': _parseAmount(proceduresAmountController.text),
      'medicinesAmount': _parseAmount(medicinesAmountController.text),
      'labTestsAmount': _parseAmount(labTestsAmountController.text),
      'otherServicesAmount': _parseAmount(otherServicesAmountController.text),
      'otherServicesLabel': otherServicesLabelController.text.trim(),
      'manualDiscountAmount': _parseAmount(manualDiscountController.text),
      'taxPercent': _parseAmount(taxPercentController.text),
    };

    final payload = {
      ..._consultationFormPayload(),
      'billing_draft': billingDraft,
    };

    if (generateInvoiceAfterSave) {
      await controller.generateActiveVisitInvoice(payload);
    } else {
      await controller.saveActiveVisitBilling(payload);
    }

    return true;
  }

  Future<bool> _showPaymentDialog(BuildContext context, dynamic controller) async {
    final draft = Map<String, dynamic>.from(
      controller.activeVisitBilling['draft'] as Map? ?? const {},
    );
    final walletController = TextEditingController(
      text: '${draft['walletUseAmount'] ?? 0}',
    );
    final cashController = TextEditingController(
      text: '${draft['cashAmount'] ?? 0}',
    );
    final upiController = TextEditingController(
      text: '${draft['upiAmount'] ?? 0}',
    );
    final cardController = TextEditingController(
      text: '${draft['cardAmount'] ?? 0}',
    );
    final refundController = TextEditingController(
      text: '${draft['refundAmount'] ?? 0}',
    );

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Record Payment'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DialogAmountField(
                    controller: walletController,
                    label: 'Wallet Used',
                  ),
                  _DialogAmountField(
                    controller: cashController,
                    label: 'Cash',
                  ),
                  _DialogAmountField(
                    controller: upiController,
                    label: 'UPI',
                  ),
                  _DialogAmountField(
                    controller: cardController,
                    label: 'Card',
                  ),
                  _DialogAmountField(
                    controller: refundController,
                    label: 'Refund',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Save Payment'),
            ),
          ],
        );
      },
    );

    if (shouldSubmit != true) {
      return false;
    }

    final billingDraft = {
      'walletUseAmount': _parseAmount(walletController.text),
      'cashAmount': _parseAmount(cashController.text),
      'upiAmount': _parseAmount(upiController.text),
      'cardAmount': _parseAmount(cardController.text),
      'refundAmount': _parseAmount(refundController.text),
    };

    await controller.recordActiveVisitPayment({
      ..._consultationFormPayload(),
      'billing_draft': billingDraft,
    });
    return true;
  }

  double _parseAmount(String value) => double.tryParse(value.trim()) ?? 0;

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

  Future<void> _handleAppointmentMutation(
    BuildContext context, {
    required dynamic controller,
    required String actionLabel,
    required Future<void> Function() action,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    await action();
    if (!mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          controller.error?.toString().trim().isNotEmpty == true
              ? _friendlyProviderError(controller.error.toString())
              : actionLabel,
        ),
      ),
    );
  }

  String _friendlyProviderError(String error) {
    final normalized = error.toLowerCase();
    if (normalized.contains('500')) {
      return 'We could not complete that action because the server ran into a problem.';
    }
    if (normalized.contains('network') || normalized.contains('socket')) {
      return 'The connection was interrupted. Please try again.';
    }
    if (normalized.contains('forbidden') || normalized.contains('unauthorized')) {
      return 'You do not have permission to complete that action.';
    }
    if (normalized.contains('not found')) {
      return 'The latest patient record could not be found. Refresh and try again.';
    }
    return 'We could not complete that action right now.';
  }

  String _tabSubtitle(dynamic controller, String activeTab) {
    switch (activeTab) {
      case 'today-visit':
        return 'Keep the active visit, consultation, billing, and next steps together for this patient.';
      case 'timeline':
        return controller.timelineSubtitle as String;
      case 'appointments':
        return 'Review upcoming and past appointments without leaving the patient record.';
      case 'records':
        return 'Open the latest uploaded records, reports, and supporting files for this patient.';
      case 'activity':
        return 'Follow patient alerts, care updates, reminders, and recent communication in one place.';
      case 'print':
        return 'Generate patient-facing documents directly from the latest visit and billing data.';
      case 'reports':
        return 'Export provider-ready care and billing reports from the shared reporting service.';
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

  Widget _buildDocumentGroup({
    required BuildContext context,
    required dynamic controller,
    required String title,
    required List<dynamic> documents,
    required String emptyMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.h5),
        const SizedBox(height: 8),
        if (documents.isEmpty)
          _ActionEmptyState(
            title: title,
            message: emptyMessage,
            actionLabel: 'Open Current Visit',
            onAction: () => _openTab(context, 'today-visit'),
          )
        else
          Column(
            children: documents.take(4).map((document) {
              return _DocumentSummaryCard(
                document: document,
                meta:
                    document.extractionPreview ??
                    _formatTimelineDate(document.uploadedAt),
                onOpen: () => _openPatientDocument(
                  context,
                  controller,
                  document.id,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Future<void> _openPatientDocument(
    BuildContext context,
    dynamic controller,
    String documentId,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final url = await controller.getPatientDocumentDownloadUrl(documentId)
          as String;
      if (url.trim().isEmpty) {
        throw StateError('Document link unavailable');
      }
      final opened = await openPlatformUrl(url);
      if (!mounted) {
        return;
      }
      if (!opened) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'This device cannot open the document automatically yet.',
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(
          content: Text('We could not open that document right now.'),
        ),
      );
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

class _ActionEmptyState extends StatelessWidget {
  const _ActionEmptyState({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.body),
          const SizedBox(height: 6),
          Text(
            message,
            style: AppTypography.small.copyWith(color: AppColors.gray),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
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

class _VisitSummaryCard extends StatelessWidget {
  const _VisitSummaryCard({
    required this.title,
    required this.subtitle,
    required this.appointmentDateLabel,
    required this.statusLabel,
    required this.reason,
    required this.prescriptionCount,
  });

  final String title;
  final String subtitle;
  final String appointmentDateLabel;
  final String statusLabel;
  final String reason;
  final String prescriptionCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.h5),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: AppTypography.small.copyWith(color: AppColors.gray),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _StatusBadge(label: statusLabel),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(label: appointmentDateLabel),
              _InfoChip(label: 'Prescriptions: $prescriptionCount'),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            reason,
            style: AppTypography.body.copyWith(color: AppColors.darkGray),
          ),
        ],
      ),
    );
  }
}

class _DocumentSummaryCard extends StatelessWidget {
  const _DocumentSummaryCard({
    required this.document,
    required this.meta,
    required this.onOpen,
  });

  final dynamic document;
  final String meta;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(document.fileName, style: AppTypography.body),
          const SizedBox(height: 4),
          Text(
            '${document.typeLabel} • ${document.statusLabel}',
            style: AppTypography.small.copyWith(color: AppColors.gray),
          ),
          const SizedBox(height: 6),
          Text(
            meta,
            style: AppTypography.tiny.copyWith(color: AppColors.gray),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: onOpen,
                child: const Text('Open File'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VisitStatusSummaryCard extends StatelessWidget {
  const _VisitStatusSummaryCard({required this.statusSummary});

  final Map<String, dynamic> statusSummary;

  @override
  Widget build(BuildContext context) {
    final rows = [
      _VisitStatusTileData(
        title: 'Consultation',
        label:
            (statusSummary['consultationStatus'] as Map?)?['label']?.toString() ??
            'Waiting',
      ),
      _VisitStatusTileData(
        title: 'Visit',
        label: (statusSummary['visitStatus'] as Map?)?['label']?.toString() ?? '',
      ),
      _VisitStatusTileData(
        title: 'Billing',
        label:
            (statusSummary['billingStatus'] as Map?)?['label']?.toString() ?? '',
      ),
      _VisitStatusTileData(
        title: 'Payment',
        label:
            (statusSummary['paymentStatus'] as Map?)?['label']?.toString() ?? '',
      ),
      _VisitStatusTileData(
        title: 'Prescription',
        label:
            (statusSummary['prescriptionStatus'] as Map?)?['label']?.toString() ??
            '',
      ),
      _VisitStatusTileData(
        title: 'Lab',
        label: (statusSummary['labStatus'] as Map?)?['label']?.toString() ?? '',
      ),
      _VisitStatusTileData(
        title: 'Follow-up',
        label:
            (statusSummary['followUpStatus'] as Map?)?['label']?.toString() ?? '',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Visit Summary', style: AppTypography.h5),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: rows
                .map((row) => _VisitStatusTile(data: row))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _VisitStatusTileData {
  const _VisitStatusTileData({required this.title, required this.label});

  final String title;
  final String label;
}

class _VisitStatusTile extends StatelessWidget {
  const _VisitStatusTile({required this.data});

  final _VisitStatusTileData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 176,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.title,
            style: AppTypography.tiny.copyWith(color: AppColors.gray),
          ),
          const SizedBox(height: 6),
          Text(data.label, style: AppTypography.body),
        ],
      ),
    );
  }
}

class _VisitBillingCard extends StatelessWidget {
  const _VisitBillingCard({
    required this.billing,
    required this.busy,
    required this.onEditBilling,
    required this.onGenerateInvoice,
    required this.onRecordPayment,
  });

  final Map<String, dynamic> billing;
  final bool busy;
  final VoidCallback onEditBilling;
  final VoidCallback onGenerateInvoice;
  final VoidCallback onRecordPayment;

  @override
  Widget build(BuildContext context) {
    final lineItems =
        (billing['lineItems'] as List? ?? const <dynamic>[])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
    final totals = Map<String, dynamic>.from(billing['totals'] as Map? ?? const {});
    final payment =
        Map<String, dynamic>.from(billing['payment'] as Map? ?? const {});
    final invoice =
        billing['invoice'] is Map ? Map<String, dynamic>.from(billing['invoice']) : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Visit Billing', style: AppTypography.h5),
                    const SizedBox(height: 6),
                    Text(
                      billing['statusLabel']?.toString() ?? 'Billing In Progress',
                      style: AppTypography.small.copyWith(color: AppColors.gray),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: busy ? null : onEditBilling,
                    child: const Text('Edit Charges'),
                  ),
                  FilledButton(
                    onPressed: busy ? null : onGenerateInvoice,
                    child: Text(invoice == null ? 'Generate Invoice' : 'Refresh Invoice'),
                  ),
                  OutlinedButton(
                    onPressed: busy ? null : onRecordPayment,
                    child: const Text('Record Payment'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (invoice != null) ...[
            _InfoChip(
              label:
                  '${invoice['invoiceNumber']?.toString() ?? 'Visit invoice'} • ${invoice['generatedAtLabel']?.toString() ?? ''}',
            ),
            const SizedBox(height: 12),
          ],
          if (lineItems.isEmpty)
            const _PanelText('No visit charges have been added yet.')
          else
            Column(
              children: lineItems
                  .map(
                    (item) => _BillingLineItemTile(
                      title: item['title']?.toString() ?? 'Charge',
                      subtitle: item['description']?.toString() ?? '',
                      amountLabel: item['amountLabel']?.toString() ?? 'Rs 0.00',
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _BillingMetricTile(
                title: 'Subtotal',
                value: totals['subtotalLabel']?.toString() ?? 'Rs 0.00',
              ),
              _BillingMetricTile(
                title: 'Discounts',
                value:
                    '${totals['manualDiscountLabel'] ?? 'Rs 0.00'} + ${totals['membershipDiscountLabel'] ?? 'Rs 0.00'}',
              ),
              _BillingMetricTile(
                title: 'Benefits Applied',
                value: totals['benefitAppliedLabel']?.toString() ?? 'Rs 0.00',
              ),
              _BillingMetricTile(
                title: 'Tax',
                value:
                    '${totals['taxAmountLabel'] ?? 'Rs 0.00'} (${totals['taxPercentLabel'] ?? '0%'})',
              ),
              _BillingMetricTile(
                title: 'Grand Total',
                value: totals['grandTotalLabel']?.toString() ?? 'Rs 0.00',
              ),
              _BillingMetricTile(
                title: 'Balance Due',
                value: payment['balanceDueLabel']?.toString() ?? 'Rs 0.00',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('Payment Summary', style: AppTypography.body),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(label: 'Wallet: ${payment['walletUsedLabel'] ?? 'Rs 0.00'}'),
              _InfoChip(label: 'Cash: ${payment['cashLabel'] ?? 'Rs 0.00'}'),
              _InfoChip(label: 'UPI: ${payment['upiLabel'] ?? 'Rs 0.00'}'),
              _InfoChip(label: 'Card: ${payment['cardLabel'] ?? 'Rs 0.00'}'),
              _InfoChip(
                label:
                    'Status: ${payment['statusLabel']?.toString() ?? 'Payment Pending'}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConsultationActionButton extends StatelessWidget {
  const _ConsultationActionButton({
    required this.label,
    required this.primary,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final bool primary;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return FilledButton(
        onPressed: loading ? null : onTap,
        child: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      );
    }

    return OutlinedButton(
      onPressed: loading ? null : onTap,
      child: loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}

class _ConsultationField extends StatelessWidget {
  const _ConsultationField({
    required this.title,
    required this.placeholder,
    required this.controller,
  });

  final String title;
  final String placeholder;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.body),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: placeholder,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.shieldBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.tiny.copyWith(
          color: AppColors.shieldBlue,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.tiny.copyWith(color: AppColors.darkGray),
      ),
    );
  }
}

class _BillingLineItemTile extends StatelessWidget {
  const _BillingLineItemTile({
    required this.title,
    required this.subtitle,
    required this.amountLabel,
  });

  final String title;
  final String subtitle;
  final String amountLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.body),
                if (subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.small.copyWith(color: AppColors.gray),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            amountLabel,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _BillingMetricTile extends StatelessWidget {
  const _BillingMetricTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.tiny.copyWith(color: AppColors.gray),
          ),
          const SizedBox(height: 6),
          Text(value, style: AppTypography.body),
        ],
      ),
    );
  }
}

class _DialogAmountField extends StatelessWidget {
  const _DialogAmountField({
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
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
    case 'CONSULTATION':
      return 'Care';
    case 'DIAGNOSIS':
      return 'Diagnosis';
    case 'ADVICE':
      return 'Advice';
    case 'FOLLOW_UP':
      return 'Follow-up';
    case 'COMPLETED':
      return 'Done';
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
