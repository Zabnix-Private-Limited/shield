import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../shared/services/platform_file_actions.dart';
import '../../../shared/presentation/controllers/agent_portal_provider.dart';
import '../../../shared/presentation/widgets/agent_section_header.dart';

class AgentCustomersScreen extends ConsumerStatefulWidget {
  const AgentCustomersScreen({super.key});

  @override
  ConsumerState<AgentCustomersScreen> createState() =>
      _AgentCustomersScreenState();
}

class _AgentCustomersScreenState extends ConsumerState<AgentCustomersScreen> {
  String _query = '';
  bool _editingProfile = false;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(agentPortalControllerProvider).ensureLoaded(),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _loadProfileDraft(Map<String, dynamic> customer) {
    _firstNameController.text = customer['firstName']?.toString() ?? '';
    _lastNameController.text = customer['lastName']?.toString() ?? '';
    _mobileController.text = customer['mobile']?.toString() ?? '';
    _emailController.text = customer['email']?.toString() ?? '';
    _cityController.text = customer['city']?.toString() ?? '';
    _addressController.text = customer['addressLine1']?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(agentPortalControllerProvider);
    final filteredCustomers = controller.customers.where((customer) {
      final combined =
          '${customer['fullName'] ?? ''} ${customer['mobile'] ?? ''} ${customer['customerCode'] ?? ''} ${customer['status'] ?? ''}'
              .toLowerCase();
      return combined.contains(_query.toLowerCase());
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AgentSectionHeader(
              title: 'Customers',
              description:
                  'Search your assigned customers, open one operational workspace at a time, and keep follow-ups, visits, documents, wallet, and timeline inside tabs instead of one long scrolling page.',
              actions: [
                FilledButton.icon(
                  onPressed: () => context.go('/portal/agent/registration'),
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('Register Customer'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search by name, phone, SHIELD ID, or status',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 920,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final stack = constraints.maxWidth < 1080;
                  final listPane = _CustomerListPane(
                    customers: filteredCustomers,
                    selectedCustomerId: controller.selectedCustomerId,
                    onTap: (customerId) {
                      setState(() => _editingProfile = false);
                      ref
                          .read(agentPortalControllerProvider)
                          .selectCustomer(customerId);
                    },
                  );
                  final detailPane = controller.isCustomerLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _CustomerWorkspaceDetail(
                          controller: controller,
                          editingProfile: _editingProfile,
                          firstNameController: _firstNameController,
                          lastNameController: _lastNameController,
                          mobileController: _mobileController,
                          emailController: _emailController,
                          cityController: _cityController,
                          addressController: _addressController,
                          onStartEdit: () {
                            _loadProfileDraft(controller.selectedCustomer);
                            setState(() => _editingProfile = true);
                          },
                          onCancelEdit: () =>
                              setState(() => _editingProfile = false),
                          onSaveProfile: () async {
                            final customerId = controller
                                    .selectedCustomer['id']
                                    ?.toString() ??
                                '';
                            if (customerId.isEmpty) {
                              return;
                            }
                            await ref
                                .read(agentPortalControllerProvider)
                                .updateCustomer(
                              customerId: customerId,
                              payload: {
                                'first_name': _firstNameController.text.trim(),
                                'last_name': _lastNameController.text.trim(),
                                'mobile': _mobileController.text.trim(),
                                'email': _emailController.text.trim(),
                                'city': _cityController.text.trim(),
                                'address_line1':
                                    _addressController.text.trim(),
                              },
                            );
                            if (mounted) {
                              setState(() => _editingProfile = false);
                            }
                          },
                        );

                  if (stack) {
                    return Column(
                      children: [
                        SizedBox(height: 280, child: listPane),
                        const SizedBox(height: 12),
                        Expanded(child: detailPane),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      SizedBox(width: 320, child: listPane),
                      const SizedBox(width: 16),
                      Expanded(child: detailPane),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerListPane extends StatelessWidget {
  const _CustomerListPane({
    required this.customers,
    required this.selectedCustomerId,
    required this.onTap,
  });

  final List<Map<String, dynamic>> customers;
  final String? selectedCustomerId;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    if (customers.isEmpty) {
      return const Card(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('No assigned customers match this search.'),
          ),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: customers.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final customer = customers[index];
          final customerId = customer['id']?.toString() ?? '';
          final selected = selectedCustomerId == customerId;
          final fullName = customer['fullName']?.toString().trim().isNotEmpty ==
                  true
              ? customer['fullName'].toString()
              : '${customer['firstName'] ?? ''} ${customer['lastName'] ?? ''}'
                  .trim();
          return InkWell(
            onTap: customerId.isEmpty ? null : () => onTap(customerId),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: selected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerLowest,
                border: Border.all(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          fullName.isEmpty ? 'Customer' : fullName,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      _StatusBadge(
                        label: _humanize(customer['status']),
                        color: _statusColor(
                          context,
                          customer['status']?.toString(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    customer['mobile']?.toString() ?? 'No mobile recorded',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaChip(
                        label: customer['customerCode']?.toString().isNotEmpty ==
                                true
                            ? customer['customerCode'].toString()
                            : 'Pending ID',
                        icon: Icons.badge_outlined,
                      ),
                      _MetaChip(
                        label: customer['membershipStatus']?.toString() ??
                            'Membership pending',
                        icon: Icons.workspace_premium_outlined,
                      ),
                      _MetaChip(
                        label: 'Network ${customer['referralCount'] ?? 0}',
                        icon: Icons.account_tree_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CustomerWorkspaceDetail extends ConsumerWidget {
  const _CustomerWorkspaceDetail({
    required this.controller,
    required this.editingProfile,
    required this.firstNameController,
    required this.lastNameController,
    required this.mobileController,
    required this.emailController,
    required this.cityController,
    required this.addressController,
    required this.onStartEdit,
    required this.onCancelEdit,
    required this.onSaveProfile,
  });

  final dynamic controller;
  final bool editingProfile;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController mobileController;
  final TextEditingController emailController;
  final TextEditingController cityController;
  final TextEditingController addressController;
  final VoidCallback onStartEdit;
  final VoidCallback onCancelEdit;
  final Future<void> Function() onSaveProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customer = controller.selectedCustomer;
    if (customer.isEmpty) {
      return const Card(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Select a customer to open the workspace.'),
          ),
        ),
      );
    }

    final membership = Map<String, dynamic>.from(
      controller.customerMembership['membership'] ?? const {},
    );
    final wallet = controller.customerWallet;
    final referralSummary = controller.customerReferralSummary;
    final family = controller.customerFamilyDetails;
    final appointments = controller.customerAppointments;
    final documents = controller.customerDocuments;
    final activities = controller.customerActivities;
    final tasks = controller.customerTasks;
    final notifications = controller.customerNotifications;
    final purchases = controller.customerPurchases;
    final records = controller.customerMedicalRecords;
    final timeline = controller.customerTimeline;
    final customerId = customer['id']?.toString() ?? '';
    final fullName =
        '${customer['firstName'] ?? ''} ${customer['lastName'] ?? ''}'.trim();
    final membershipName = membership['membershipType'] is Map
        ? (membership['membershipType'] as Map)['name']?.toString() ?? 'Standard'
        : 'Standard';
    final activeWallet = wallet['cashWallet'] is Map
        ? (wallet['cashWallet'] as Map)['available']
        : 0;
    final rewardPoints = wallet['rewardPoints'] is Map
        ? (wallet['rewardPoints'] as Map)['available']
        : 0;

    return DefaultTabController(
      length: 8,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _CustomerHero(
                customer: customer,
                appointments: appointments,
                documents: documents,
                tasks: tasks,
                onEdit: editingProfile ? onCancelEdit : onStartEdit,
                onFollowUp: () => context.go('/portal/agent/followups'),
                onVisit: () => context.go('/portal/agent/appointments'),
                onDocuments: () => context.go('/portal/agent/documents'),
                onMenuAction: (action) async {
                  if (action == 'print') {
                    await _downloadPrint(
                      context,
                      ref,
                      'PATIENT_SUMMARY',
                    );
                    return;
                  }
                  if (action == 'onboarding') {
                    context.go('/portal/agent/registration');
                    return;
                  }
                  if (action == 'network') {
                    context.go('/portal/agent/referrals');
                  }
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _CompactMetricCard(
                    value: '${tasks.length}',
                    label: 'Pending follow-ups',
                    helper: 'Tasks still open for this customer.',
                    icon: Icons.assignment_late_outlined,
                  ),
                  _CompactMetricCard(
                    value: '${documents.length}',
                    label: 'Uploaded documents',
                    helper: 'Files currently linked to the customer.',
                    icon: Icons.folder_open_outlined,
                  ),
                  _CompactMetricCard(
                    value: '${appointments.length}',
                    label: 'Visits',
                    helper: 'Upcoming and historical appointments.',
                    icon: Icons.event_available_outlined,
                  ),
                  _CompactMetricCard(
                    value: '${rewardPoints ?? 0}',
                    label: 'Reward points',
                    helper: 'Visible rewards in the wallet.',
                    icon: Icons.stars_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: 'Overview'),
                  Tab(text: 'Profile'),
                  Tab(text: 'Documents'),
                  Tab(text: 'Visits'),
                  Tab(text: 'Follow-ups'),
                  Tab(text: 'Medical'),
                  Tab(text: 'Wallet'),
                  Tab(text: 'Timeline'),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          _TwoColumnOverview(
                            leftChildren: [
                              _SummarySection(
                                title: 'Customer overview',
                                items: [
                                  _SummaryItem(
                                    label: 'SHIELD ID',
                                    value: customer['customerCode']
                                            ?.toString()
                                            .ifBlank('Pending generation') ??
                                        'Pending generation',
                                  ),
                                  _SummaryItem(
                                    label: 'Phone',
                                    value: customer['mobile']
                                            ?.toString()
                                            .ifBlank('Not recorded') ??
                                        'Not recorded',
                                  ),
                                  _SummaryItem(
                                    label: 'Membership',
                                    value: membershipName,
                                  ),
                                  _SummaryItem(
                                    label: 'Status',
                                    value: _humanize(customer['status']),
                                  ),
                                ],
                              ),
                              _SummarySection(
                                title: 'Documents and onboarding',
                                items: [
                                  _SummaryItem(
                                    label: 'Documents uploaded',
                                    value: '${documents.length}',
                                  ),
                                  _SummaryItem(
                                    label: 'Membership number',
                                    value: membership['membershipNumber']
                                            ?.toString()
                                            .ifBlank('Pending') ??
                                        'Pending',
                                  ),
                                  _SummaryItem(
                                    label: 'Card status',
                                    value: _humanize(
                                      controller.customerMembership['shieldCard']
                                          ?['status'],
                                    ),
                                  ),
                                  _SummaryItem(
                                    label: 'Notifications',
                                    value: '${notifications.length}',
                                  ),
                                ],
                              ),
                            ],
                            rightChildren: [
                              _SummarySection(
                                title: 'Recent activity',
                                items: [
                                  _SummaryItem(
                                    label: 'Next visit',
                                    value: appointments.isEmpty
                                        ? 'Not scheduled'
                                        : _formatDateTime(
                                            appointments.first['appointmentDate'],
                                          ),
                                  ),
                                  _SummaryItem(
                                    label: 'Latest follow-up',
                                    value: activities.isEmpty
                                        ? 'No notes yet'
                                        : activities.first['notes']
                                                ?.toString()
                                                .ifBlank('No remarks') ??
                                            'No remarks',
                                  ),
                                  _SummaryItem(
                                    label: 'Network rewards',
                                    value:
                                        '${referralSummary['rewardPoints'] ?? 0}',
                                  ),
                                  _SummaryItem(
                                    label: 'Recent purchase',
                                    value: purchases.isEmpty
                                        ? 'No purchases'
                                        : purchases.first['providerName']
                                                ?.toString()
                                                .ifBlank('Provider') ??
                                            'Provider',
                                  ),
                                ],
                              ),
                              _TimelineCard(
                                title: 'Today and next',
                                emptyLabel:
                                    'No visits, follow-ups, or alerts are queued right now.',
                                entries: [
                                  ...tasks.take(3).map(
                                    (item) => _TimelineEntry(
                                      title: _humanize(item['status']),
                                      subtitle:
                                          item['notes']?.toString().ifBlank(
                                                'Follow-up scheduled',
                                              ) ??
                                              'Follow-up scheduled',
                                      timeLabel:
                                          _formatDateTime(item['dueDate']),
                                      icon: Icons.assignment_outlined,
                                    ),
                                  ),
                                  ...appointments.take(2).map(
                                    (item) => _TimelineEntry(
                                      title: item['provider']?['providerName']
                                              ?.toString()
                                              .ifBlank('Visit scheduled') ??
                                          'Visit scheduled',
                                      subtitle:
                                          _humanize(item['appointmentType']),
                                      timeLabel: _formatDateTime(
                                        item['appointmentDate'],
                                      ),
                                      icon: Icons.event_available_outlined,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          if (editingProfile)
                            _EditableProfileCard(
                              firstNameController: firstNameController,
                              lastNameController: lastNameController,
                              mobileController: mobileController,
                              emailController: emailController,
                              cityController: cityController,
                              addressController: addressController,
                              isSaving: controller.isSaving,
                              onCancel: onCancelEdit,
                              onSave: onSaveProfile,
                            )
                          else
                            _TwoColumnOverview(
                              leftChildren: [
                                _SummarySection(
                                  title: 'Profile',
                                  items: [
                                    _SummaryItem(
                                      label: 'Name',
                                      value: fullName.ifBlank('Not recorded'),
                                    ),
                                    _SummaryItem(
                                      label: 'Email',
                                      value: customer['email']
                                              ?.toString()
                                              .ifBlank('Not recorded') ??
                                          'Not recorded',
                                    ),
                                    _SummaryItem(
                                      label: 'Gender',
                                      value: _humanize(customer['gender']),
                                    ),
                                    _SummaryItem(
                                      label: 'Date of birth',
                                      value: _formatDate(customer['dob']),
                                    ),
                                  ],
                                ),
                                _SummarySection(
                                  title: 'Contact and address',
                                  items: [
                                    _SummaryItem(
                                      label: 'Phone',
                                      value: customer['mobile']
                                              ?.toString()
                                              .ifBlank('Not recorded') ??
                                          'Not recorded',
                                    ),
                                    _SummaryItem(
                                      label: 'City',
                                      value: customer['city']
                                              ?.toString()
                                              .ifBlank('Not recorded') ??
                                          'Not recorded',
                                    ),
                                    _SummaryItem(
                                      label: 'Address',
                                      value: [
                                        customer['addressLine1'],
                                        customer['addressLine2'],
                                        customer['city'],
                                        customer['district'],
                                        customer['state'],
                                      ]
                                          .where(
                                            (item) => (item ?? '')
                                                .toString()
                                                .trim()
                                                .isNotEmpty,
                                          )
                                          .join(', ')
                                          .ifBlank('Not recorded'),
                                    ),
                                  ],
                                ),
                              ],
                              rightChildren: [
                                _TimelineCard(
                                  title: 'Family and contacts',
                                  emptyLabel:
                                      'No family contacts are recorded yet.',
                                  entries: family
                                      .map(
                                        (item) => _TimelineEntry(
                                          title: item['name']
                                                  ?.toString()
                                                  .ifBlank('Contact') ??
                                              'Contact',
                                          subtitle:
                                              item['relation']?.toString() ??
                                                  'Relation',
                                          timeLabel:
                                              item['mobile']?.toString() ?? '',
                                          icon: Icons.family_restroom_outlined,
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    _SimpleListView(
                      title: 'Uploaded Documents',
                      emptyLabel:
                          'No documents are linked yet. Upload the required files from the Customer Documents flow.',
                      items: documents
                          .map(
                            (item) => _TimelineEntry(
                              title: item['fileName']?.toString().ifBlank(
                                    'Document',
                                  ) ??
                                  'Document',
                              subtitle:
                                  '${_humanize(item['documentType'])} • ${_humanize(item['status'])}',
                              timeLabel: _formatDateTime(item['createdAt']),
                              icon: Icons.description_outlined,
                            ),
                          )
                          .toList(),
                    ),
                    _SimpleListView(
                      title: 'Visits',
                      emptyLabel: 'No visits scheduled or completed yet.',
                      items: appointments
                          .map(
                            (item) => _TimelineEntry(
                              title: item['provider']?['providerName']
                                      ?.toString()
                                      .ifBlank('Provider') ??
                                  'Provider',
                              subtitle:
                                  '${_humanize(item['appointmentType'])} • ${_humanize(item['status'])}',
                              timeLabel: _formatDateTime(
                                item['appointmentDate'],
                              ),
                              icon: Icons.event_note_outlined,
                            ),
                          )
                          .toList(),
                    ),
                    _SimpleListView(
                      title: 'Follow-ups',
                      emptyLabel: 'No follow-up activity is recorded yet.',
                      items: [
                        ...tasks.map(
                          (item) => _TimelineEntry(
                            title: _humanize(item['status']),
                            subtitle: item['notes']
                                    ?.toString()
                                    .ifBlank('No remarks') ??
                                'No remarks',
                            timeLabel: _formatDateTime(item['dueDate']),
                            icon: Icons.assignment_outlined,
                          ),
                        ),
                        ...activities.map(
                          (item) => _TimelineEntry(
                            title: _humanize(item['activityType']),
                            subtitle: item['notes']
                                    ?.toString()
                                    .ifBlank('No remarks') ??
                                'No remarks',
                            timeLabel: _formatDateTime(item['createdAt']),
                            icon: Icons.sticky_note_2_outlined,
                          ),
                        ),
                      ],
                    ),
                    _SimpleListView(
                      title: 'Medical Records',
                      emptyLabel: 'No medical records are linked yet.',
                      items: records
                          .map(
                            (item) => _TimelineEntry(
                              title: item['title']?.toString().ifBlank(
                                    'Record',
                                  ) ??
                                  'Record',
                              subtitle:
                                  '${item['category'] ?? 'Record'} • ${item['status'] ?? 'Pending'}',
                              timeLabel: _formatDateTime(item['createdAt']),
                              icon: Icons.medical_information_outlined,
                            ),
                          )
                          .toList(),
                    ),
                    SingleChildScrollView(
                      child: _TwoColumnOverview(
                        leftChildren: [
                          _SummarySection(
                            title: 'Wallet',
                            items: [
                              _SummaryItem(
                                label: 'Cash available',
                                value: '${activeWallet ?? 0}',
                              ),
                              _SummaryItem(
                                label: 'Reward points',
                                value: '${rewardPoints ?? 0}',
                              ),
                              _SummaryItem(
                                label: 'Membership status',
                                value: _humanize(membership['status']),
                              ),
                            ],
                          ),
                        ],
                        rightChildren: [
                          _SummarySection(
                            title: 'Customer network',
                            items: [
                              _SummaryItem(
                                label: 'Direct customers',
                                value:
                                    '${referralSummary['directReferrals'] ?? 0}',
                              ),
                              _SummaryItem(
                                label: 'Total network',
                                value:
                                    '${referralSummary['totalReferrals'] ?? 0}',
                              ),
                              _SummaryItem(
                                label: 'Network rewards',
                                value:
                                    '${referralSummary['rewardPoints'] ?? 0}',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _SimpleListView(
                      title: 'Timeline',
                      emptyLabel: 'No activity is recorded in the timeline yet.',
                      items: timeline
                          .map(
                            (item) => _TimelineEntry(
                              title: _humanize(item['type']),
                              subtitle: item['description']
                                      ?.toString()
                                      .ifBlank(item['title']?.toString() ?? '') ??
                                  '',
                              timeLabel:
                                  _formatDateTime(item['timestamp']),
                              icon: Icons.timeline_outlined,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              if (customerId.isNotEmpty) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () => context.go('/portal/agent/registration'),
                        child: const Text('Continue Onboarding'),
                      ),
                      OutlinedButton(
                        onPressed: () => context.go('/portal/agent/referrals'),
                        child: const Text('Open Network'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerHero extends StatelessWidget {
  const _CustomerHero({
    required this.customer,
    required this.appointments,
    required this.documents,
    required this.tasks,
    required this.onEdit,
    required this.onFollowUp,
    required this.onVisit,
    required this.onDocuments,
    required this.onMenuAction,
  });

  final Map<String, dynamic> customer;
  final List<Map<String, dynamic>> appointments;
  final List<Map<String, dynamic>> documents;
  final List<Map<String, dynamic>> tasks;
  final VoidCallback onEdit;
  final VoidCallback onFollowUp;
  final VoidCallback onVisit;
  final VoidCallback onDocuments;
  final ValueChanged<String> onMenuAction;

  @override
  Widget build(BuildContext context) {
    final fullName =
        '${customer['firstName'] ?? ''} ${customer['lastName'] ?? ''}'.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName.ifBlank('Customer'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatusBadge(
                        label: _humanize(customer['status']),
                        color:
                            _statusColor(context, customer['status']?.toString()),
                      ),
                      _MetaChip(
                        label: customer['customerCode']
                                ?.toString()
                                .ifBlank('Pending ID') ??
                            'Pending ID',
                        icon: Icons.badge_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    customer['mobile']?.toString() ?? 'No mobile recorded',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(
                    onPressed: onEdit,
                    child: const Text('Edit'),
                  ),
                  OutlinedButton(
                    onPressed: onFollowUp,
                    child: const Text('Follow-up'),
                  ),
                  OutlinedButton(
                    onPressed: onDocuments,
                    child: const Text('Documents'),
                  ),
                  OutlinedButton(
                    onPressed: onVisit,
                    child: const Text('Visit'),
                  ),
                  PopupMenuButton<String>(
                    onSelected: onMenuAction,
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'print',
                        child: Text('Print Summary'),
                      ),
                      PopupMenuItem(
                        value: 'onboarding',
                        child: Text('Continue Onboarding'),
                      ),
                      PopupMenuItem(
                        value: 'network',
                        child: Text('Open Network'),
                      ),
                    ],
                    child: const OutlinedButton(
                      onPressed: null,
                      child: Text('More'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetaChip(
                label: '${tasks.length} follow-ups open',
                icon: Icons.assignment_late_outlined,
              ),
              _MetaChip(
                label: '${appointments.length} visits tracked',
                icon: Icons.event_available_outlined,
              ),
              _MetaChip(
                label: '${documents.length} docs uploaded',
                icon: Icons.folder_open_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditableProfileCard extends StatelessWidget {
  const _EditableProfileCard({
    required this.firstNameController,
    required this.lastNameController,
    required this.mobileController,
    required this.emailController,
    required this.cityController,
    required this.addressController,
    required this.isSaving,
    required this.onCancel,
    required this.onSave,
  });

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController mobileController;
  final TextEditingController emailController;
  final TextEditingController cityController;
  final TextEditingController addressController;
  final bool isSaving;
  final VoidCallback onCancel;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit profile',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _AdaptiveField(
                  child: TextField(
                    controller: firstNameController,
                    decoration:
                        const InputDecoration(labelText: 'First name'),
                  ),
                ),
                _AdaptiveField(
                  child: TextField(
                    controller: lastNameController,
                    decoration: const InputDecoration(labelText: 'Last name'),
                  ),
                ),
                _AdaptiveField(
                  child: TextField(
                    controller: mobileController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                  ),
                ),
                _AdaptiveField(
                  child: TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                ),
                _AdaptiveField(
                  child: TextField(
                    controller: cityController,
                    decoration: const InputDecoration(labelText: 'City'),
                  ),
                ),
                _AdaptiveField(
                  wide: true,
                  child: TextField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: isSaving ? null : onCancel,
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: isSaving ? null : onSave,
                    child: Text(isSaving ? 'Saving...' : 'Save Details'),
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

class _TwoColumnOverview extends StatelessWidget {
  const _TwoColumnOverview({
    required this.leftChildren,
    required this.rightChildren,
  });

  final List<Widget> leftChildren;
  final List<Widget> rightChildren;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 920;
        final left = Column(
          children: leftChildren
              .expand((child) => [child, const SizedBox(height: 12)])
              .toList()
            ..removeLast(),
        );
        final right = Column(
          children: rightChildren
              .expand((child) => [child, const SizedBox(height: 12)])
              .toList()
            ..removeLast(),
        );

        if (stack) {
          return Column(
            children: [
              left,
              const SizedBox(height: 12),
              right,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<_SummaryItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(
                        item.label,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(item.value)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleListView extends StatelessWidget {
  const _SimpleListView({
    required this.title,
    required this.emptyLabel,
    required this.items,
  });

  final String title;
  final String emptyLabel;
  final List<_TimelineEntry> items;

  @override
  Widget build(BuildContext context) {
    return _TimelineCard(
      title: title,
      emptyLabel: emptyLabel,
      entries: items,
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.title,
    required this.emptyLabel,
    required this.entries,
  });

  final String title;
  final String emptyLabel;
  final List<_TimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              Text(emptyLabel)
            else
              ...entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        child: Icon(entry.icon, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.title,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 2),
                            Text(entry.subtitle),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        entry.timeLabel,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CompactMetricCard extends StatelessWidget {
  const _CompactMetricCard({
    required this.value,
    required this.label,
    required this.helper,
    required this.icon,
  });

  final String value;
  final String label;
  final String helper;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const SizedBox(height: 10),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(helper, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdaptiveField extends StatelessWidget {
  const _AdaptiveField({
    required this.child,
    this.wide = false,
  });

  final Widget child;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: wide ? 572 : 280,
      child: child,
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _SummaryItem {
  const _SummaryItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class _TimelineEntry {
  const _TimelineEntry({
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String timeLabel;
  final IconData icon;
}

Future<void> _downloadPrint(
  BuildContext context,
  WidgetRef ref,
  String templateId,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final result = await ref
        .read(agentPortalControllerProvider)
        .generateCustomerPrint(templateId);
    final downloaded = await downloadPlatformFile(
      fileName: result['fileName']?.toString() ?? '$templateId.pdf',
      mimeType: result['mimeType']?.toString() ?? 'application/pdf',
      contentBase64: result['contentBase64']?.toString() ?? '',
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          downloaded
              ? 'Document ready: ${result['fileName'] ?? templateId}'
              : 'The document is ready, but automatic download is not available on this device.',
        ),
      ),
    );
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('We could not generate that document right now.'),
      ),
    );
  }
}

Color _statusColor(BuildContext context, String? rawStatus) {
  switch ((rawStatus ?? '').toUpperCase()) {
    case 'ACTIVE':
    case 'COMPLETED':
    case 'APPROVED':
    case 'VERIFIED':
      return Colors.green.shade700;
    case 'PENDING':
    case 'INCOMPLETE':
    case 'DRAFT':
      return Colors.orange.shade700;
    case 'REJECTED':
    case 'CANCELLED':
    case 'SUSPENDED':
      return Theme.of(context).colorScheme.error;
    default:
      return Theme.of(context).colorScheme.primary;
  }
}

String _humanize(dynamic value) {
  final text = (value ?? '').toString().trim();
  if (text.isEmpty) {
    return 'Not recorded';
  }
  return text
      .replaceAll('_', ' ')
      .toLowerCase()
      .split(' ')
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}

String _formatDate(dynamic value) {
  final parsed = DateTime.tryParse((value ?? '').toString());
  if (parsed == null) {
    return 'Not recorded';
  }
  return DateFormat('dd MMM yyyy').format(parsed.toLocal());
}

String _formatDateTime(dynamic value) {
  final parsed = DateTime.tryParse((value ?? '').toString());
  if (parsed == null) {
    return 'Not scheduled';
  }
  return DateFormat('dd MMM, h:mm a').format(parsed.toLocal());
}

extension on String {
  String ifBlank(String fallback) => trim().isEmpty ? fallback : this;
}
