import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../shared/presentation/controllers/agent_portal_provider.dart';

class AgentCustomersScreen extends ConsumerStatefulWidget {
  const AgentCustomersScreen({super.key});

  @override
  ConsumerState<AgentCustomersScreen> createState() => _AgentCustomersScreenState();
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
    final filtered = controller.customers.where((customer) {
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
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search assigned customers',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 980,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final list = _CustomerListPane(
                    customers: filtered,
                    selectedCustomerId: controller.selectedCustomerId,
                    onTap: (customerId) {
                      setState(() => _editingProfile = false);
                      ref.read(agentPortalControllerProvider).selectCustomer(customerId);
                    },
                  );
                  final detail = controller.isCustomerLoading
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
                          onCancelEdit: () => setState(() => _editingProfile = false),
                          onSaveProfile: () async {
                            final customerId =
                                controller.selectedCustomer['id']?.toString() ?? '';
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
                                'address_line1': _addressController.text.trim(),
                              },
                            );
                            if (mounted) {
                              setState(() => _editingProfile = false);
                            }
                          },
                        );

                  if (constraints.maxWidth < 980) {
                    return Column(
                      children: [
                        Expanded(flex: 4, child: list),
                        const Divider(height: 24),
                        Expanded(flex: 6, child: detail),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(flex: 4, child: list),
                      const VerticalDivider(),
                      Expanded(flex: 7, child: detail),
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
      return const Center(child: Text('No assigned customers match this search.'));
    }

    return ListView.separated(
      itemCount: customers.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final customer = customers[index];
        final customerId = customer['id']?.toString() ?? '';
        return ListTile(
          selected: selectedCustomerId == customerId,
          title: Text('${customer['fullName'] ?? 'Customer'}'),
          subtitle: Text(
            '${_humanize(customer['status'])} • ${customer['mobile'] ?? 'No mobile'}',
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Referrals ${customer['referralCount'] ?? 0}'),
              Text(
                customer['membershipStatus']?.toString() ?? 'Membership pending',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          onTap: customerId.isEmpty ? null : () => onTap(customerId),
        );
      },
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
      return const Center(
        child: Text('Select a customer to open the full field workspace.'),
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

    return ListView(
      children: [
        Card(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 12,
              spacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${customer['firstName'] ?? ''} ${customer['lastName'] ?? ''}'.trim(),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text('${customer['customerCode'] ?? ''} • ${_humanize(customer['status'])}'),
                    const SizedBox(height: 4),
                    Text('${customer['mobile'] ?? 'No mobile'}'),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: () => context.go('/portal/agent/followups'),
                      child: const Text('Follow-ups'),
                    ),
                    OutlinedButton(
                      onPressed: () => context.go('/portal/agent/appointments'),
                      child: const Text('Appointments'),
                    ),
                    OutlinedButton(
                      onPressed: () => context.go('/portal/agent/documents'),
                      child: const Text('Documents'),
                    ),
                    OutlinedButton(
                      onPressed: editingProfile ? onCancelEdit : onStartEdit,
                      child: Text(editingProfile ? 'Cancel edit' : 'Edit details'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (editingProfile)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Update customer details', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(controller: firstNameController, decoration: const InputDecoration(labelText: 'First name')),
                  const SizedBox(height: 12),
                  TextField(controller: lastNameController, decoration: const InputDecoration(labelText: 'Last name')),
                  const SizedBox(height: 12),
                  TextField(controller: mobileController, decoration: const InputDecoration(labelText: 'Phone')),
                  const SizedBox(height: 12),
                  TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                  const SizedBox(height: 12),
                  TextField(controller: cityController, decoration: const InputDecoration(labelText: 'City')),
                  const SizedBox(height: 12),
                  TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: controller.isSaving ? null : onSaveProfile,
                      child: const Text('Save details'),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final stack = constraints.maxWidth < 900;
              final left = Column(
                children: [
                  _InfoCard(
                    title: 'Profile and contact',
                    lines: [
                      'Email: ${customer['email'] ?? 'Not recorded'}',
                      'Gender: ${_humanize(customer['gender'])}',
                      'Date of birth: ${_formatDate(customer['dob'])}',
                      'Address: ${[
                        customer['addressLine1'],
                        customer['addressLine2'],
                        customer['city'],
                        customer['district'],
                        customer['state'],
                      ].where((item) => (item ?? '').toString().trim().isNotEmpty).join(', ').ifEmpty('Not recorded')}',
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    title: 'Family details',
                    lines: family.isEmpty
                        ? const ['No family contacts are recorded yet.']
                        : family
                            .map(
                              (item) =>
                                  '${item['name']} • ${item['relation']} • ${item['mobile']}',
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    title: 'Membership and wallet',
                    lines: [
                      'Membership: ${membership['membershipType']?['name'] ?? 'Standard'}',
                      'Membership number: ${membership['membershipNumber'] ?? 'Pending'}',
                      'Membership status: ${_humanize(membership['status'])}',
                      'Wallet cash available: ${wallet['cashWallet']?['available'] ?? 0}',
                      'Reward points available: ${wallet['rewardPoints']?['available'] ?? 0}',
                      'Card status: ${_humanize(controller.customerMembership['shieldCard']?['status'])}',
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    title: 'Referral tree',
                    lines: referralSummary.isEmpty
                        ? const ['No referral activity yet.']
                        : referralSummary.entries
                            .map(
                              (entry) =>
                                  '${_humanize(entry.key)}: ${entry.value}',
                            )
                            .toList(),
                  ),
                ],
              );
              final right = Column(
                children: [
                  _ListCard(
                    title: 'Appointments',
                    empty: 'No appointments recorded.',
                    items: appointments
                        .map(
                          (item) => '${_formatDateTime(item['appointmentDate'])} • ${_humanize(item['status'])} • ${item['provider']?['providerName'] ?? item['providerName'] ?? 'Provider'}',
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  _ListCard(
                    title: 'Documents',
                    empty: 'No documents uploaded.',
                    items: documents
                        .map(
                          (item) =>
                              '${item['fileName'] ?? 'Document'} • ${_humanize(item['documentType'])} • ${_humanize(item['status'])}',
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  _ListCard(
                    title: 'Follow-ups and notes',
                    empty: 'No follow-up records yet.',
                    items: [
                      ...tasks.map(
                        (item) =>
                            'Task • ${_humanize(item['status'])} • ${item['notes'] ?? 'No remarks'}',
                      ),
                      ...activities.map(
                        (item) =>
                            'Note • ${_humanize(item['activityType'])} • ${item['notes'] ?? 'No remarks'}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ListCard(
                    title: 'Notifications',
                    empty: 'No notifications for this customer.',
                    items: notifications
                        .map(
                          (item) =>
                              '${item['title'] ?? 'Notification'} • ${_humanize(item['status'])}',
                        )
                        .toList(),
                  ),
                ],
              );
              if (stack) {
                return Column(children: [left, const SizedBox(height: 12), right]);
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
          ),
        const SizedBox(height: 12),
        _ListCard(
          title: 'Medical records',
          empty: 'No viewable medical records are linked yet.',
          items: records
              .map(
                (item) =>
                    '${item['category'] ?? 'Record'} • ${item['title'] ?? 'Entry'} • ${item['status'] ?? ''}',
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        _ListCard(
          title: 'Recent purchases',
          empty: 'No permitted purchases are available.',
          items: purchases
              .map(
                (item) =>
                    '${item['providerName'] ?? 'Provider'} • ${item['invoiceNumber'] ?? 'Invoice'} • ${item['paymentStatus'] ?? 'Pending'}',
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        _ListCard(
          title: 'Timeline',
          empty: 'No activity is recorded in the timeline yet.',
          items: timeline
              .map(
                (item) =>
                    '${_formatDateTime(item['timestamp'])} • ${_humanize(item['type'])} • ${item['description'] ?? item['title'] ?? ''}',
              )
              .toList(),
        ),
        if (customerId.isNotEmpty) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => context.go('/portal/agent/registration'),
                  child: const Text('Open onboarding'),
                ),
                OutlinedButton(
                  onPressed: () => context.go('/portal/agent/referrals'),
                  child: const Text('Open referrals'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...lines.map((line) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(line),
                )),
          ],
        ),
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({
    required this.title,
    required this.empty,
    required this.items,
  });

  final String title;
  final String empty;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Text(empty)
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(item),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
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
      .map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
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
