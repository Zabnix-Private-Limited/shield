import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/utils/shield_date_utils.dart';
import '../../../../../shared/widgets/shield_date_picker.dart';
import '../../../shared/presentation/controllers/agent_portal_provider.dart';
import '../../../shared/presentation/widgets/agent_design_system.dart';
import '../../../shared/presentation/widgets/agent_experience_widgets.dart';
import '../../../shared/presentation/widgets/agent_section_header.dart';

class AgentAppointmentsScreen extends ConsumerStatefulWidget {
  const AgentAppointmentsScreen({super.key});

  @override
  ConsumerState<AgentAppointmentsScreen> createState() =>
      _AgentAppointmentsScreenState();
}

class _AgentAppointmentsScreenState
    extends ConsumerState<AgentAppointmentsScreen> {
  final GlobalKey _composerKey = GlobalKey();
  String? _providerId;
  String _appointmentType = 'CONSULTATION';
  DateTime? _appointmentDate;
  String _slot = 'MORNING';
  final _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(agentPortalControllerProvider).ensureLoaded(),
    );
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(agentPortalControllerProvider);
    final selectedCustomerId = controller.selectedCustomerId;
    final selectedCustomer = controller.selectedCustomer;
    final customerName =
        selectedCustomer['firstName']?.toString().isNotEmpty == true
        ? '${selectedCustomer['firstName']} ${selectedCustomer['lastName'] ?? ''}'
              .trim()
        : 'Select a customer from Customers';
    final providerLookupError = controller.providerLookupError;
    final isProviderLookupLoading = controller.isReferenceDataLoading;
    final providers = controller.providers;
    _providerId ??= providers.isNotEmpty
        ? providers.first['id']?.toString()
        : null;

    final visitHistory = controller.customerAppointments.isNotEmpty
        ? controller.customerAppointments
        : controller.upcomingAppointments;

    final upcoming = visitHistory.where(
      (item) =>
          (item['status'] ?? '').toString().toUpperCase() != 'COMPLETED' &&
          (item['status'] ?? '').toString().toUpperCase() != 'CANCELLED',
    );
    final completed = visitHistory.where(
      (item) => (item['status'] ?? '').toString().toUpperCase() == 'COMPLETED',
    );
    final cancelled = visitHistory.where(
      (item) => (item['status'] ?? '').toString().toUpperCase() == 'CANCELLED',
    );

    return Card(
      child: Padding(
        padding: AgentUi.panelPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AgentSectionHeader(
              title: 'Visits',
              description:
                  'Booking now follows a clearer customer → provider → service → date → time → confirmation flow, with visit history split by status instead of one flat list.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AgentMetricCard(
                  value: '${upcoming.length}',
                  label: 'Upcoming',
                  helper: 'Visits still waiting to happen.',
                  icon: Icons.upcoming_outlined,
                  color: Colors.blue.shade700,
                ),
                AgentMetricCard(
                  value: '${completed.length}',
                  label: 'Completed',
                  helper: 'Visits already delivered.',
                  icon: Icons.task_alt_outlined,
                  color: Colors.green.shade700,
                ),
                AgentMetricCard(
                  value: '${cancelled.length}',
                  label: 'Cancelled',
                  helper: 'Visits cancelled or dropped.',
                  icon: Icons.event_busy_outlined,
                  color: Colors.red.shade700,
                ),
              ],
            ),
            AgentUi.gapH(AgentUi.space12),
            LayoutBuilder(
              builder: (context, constraints) {
                final stack = constraints.maxWidth < 980;
                final composer = _buildComposer(
                  context,
                  selectedCustomerId,
                  customerName,
                  providers,
                  providerLookupError: providerLookupError,
                  isProviderLookupLoading: isProviderLookupLoading,
                );
                final history = _buildHistory(visitHistory.toList());
                if (stack) {
                  return Column(
                    children: [
                      composer,
                      AgentUi.gapH(AgentUi.space16),
                      history,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: composer),
                    AgentUi.gapW(AgentUi.space16),
                    Expanded(child: history),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer(
    BuildContext context,
    String? selectedCustomerId,
    String customerName,
    List<Map<String, dynamic>> providers, {
    required String? providerLookupError,
    required bool isProviderLookupLoading,
  }) {
    final selectedProvider = providers.firstWhere(
      (provider) => provider['id']?.toString() == _providerId,
      orElse: () => <String, dynamic>{},
    );
    return AgentPanelCard(
      title: 'Book a Visit',
      subtitle:
          'The visit setup is sequenced so the agent always knows the next decision to make.',
      child: Column(
        key: _composerKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(customerName),
            subtitle: Text(
              selectedCustomerId == null
                  ? 'Choose a customer before booking a visit.'
                  : 'Customer selected for visit booking.',
            ),
          ),
          const SizedBox(height: 12),
          _FlowStep(
            step: '1',
            label: 'Provider',
            child: _buildProviderSelector(
              providers,
              providerLookupError: providerLookupError,
              isProviderLookupLoading: isProviderLookupLoading,
            ),
          ),
          const SizedBox(height: 12),
          _FlowStep(
            step: '2',
            label: 'Service',
            child: DropdownButtonFormField<String>(
              initialValue: _appointmentType,
              items: const [
                DropdownMenuItem(
                  value: 'CONSULTATION',
                  child: Text('Consultation'),
                ),
                DropdownMenuItem(
                  value: 'HOME_VISIT',
                  child: Text('Home Visit'),
                ),
                DropdownMenuItem(
                  value: 'CLINIC_VISIT',
                  child: Text('Clinic Visit'),
                ),
                DropdownMenuItem(value: 'LAB', child: Text('Lab Test')),
              ],
              onChanged: (value) =>
                  setState(() => _appointmentType = value ?? 'CONSULTATION'),
              decoration: const InputDecoration(labelText: 'Select service'),
            ),
          ),
          const SizedBox(height: 12),
          _FlowStep(
            step: '3',
            label: 'Date',
            child: OutlinedButton.icon(
              onPressed: () async {
                final picked = await showShieldDatePicker(
                  context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  title: 'Choose visit date',
                  helperText:
                      'Select the visit date before choosing the final slot.',
                  autoCloseOnSelect: true,
                );
                if (picked != null) {
                  setState(() {
                    _appointmentDate = _slotDate(picked, _slot);
                  });
                }
              },
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(
                _appointmentDate == null
                    ? 'Choose visit date'
                    : ShieldDateUtils.formatShortMonthDate(_appointmentDate!),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _FlowStep(
            step: '4',
            label: 'Available slots',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  const [
                    _SlotChip(slot: 'MORNING'),
                    _SlotChip(slot: 'AFTERNOON'),
                    _SlotChip(slot: 'EVENING'),
                  ].map((chip) {
                    final selected = chip.slot == _slot;
                    return ChoiceChip(
                      label: Text(_slotLabel(chip.slot)),
                      selected: selected,
                      onSelected: (_) => setState(() {
                        _slot = chip.slot;
                        if (_appointmentDate != null) {
                          _appointmentDate = _slotDate(
                            _appointmentDate!,
                            _slot,
                          );
                        }
                      }),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          _FlowStep(
            step: '5',
            label: 'Confirmation note',
            child: TextField(
              controller: _remarksController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Visit notes',
                hintText:
                    'Reason for visit, customer expectation, or coordination note',
              ),
            ),
          ),
          const SizedBox(height: 16),
          AgentPanelCard(
            title: 'Confirmation',
            subtitle:
                'A quick summary before the agent confirms the visit booking.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer: $customerName'),
                const SizedBox(height: 4),
                Text(
                  'Provider: ${selectedProvider['providerName'] ?? 'Not selected'}',
                ),
                const SizedBox(height: 4),
                Text('Service: ${_humanize(_appointmentType)}'),
                const SizedBox(height: 4),
                Text(
                  'Date and slot: ${_appointmentDate == null ? 'Not selected' : _formatDate(_appointmentDate)} • ${_slotLabel(_slot)}',
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: AgentPrimaryButton(
                    onPressed:
                        selectedCustomerId == null ||
                            _providerId == null ||
                            _appointmentDate == null
                        ? null
                        : () async {
                            await ref
                                .read(agentPortalControllerProvider)
                                .createAppointment(
                                  customerId: selectedCustomerId,
                                  providerId: _providerId!,
                                  appointmentType: _appointmentType,
                                  appointmentDate: _appointmentDate!,
                                  remarks: _remarksController.text.trim(),
                                );
                            _remarksController.clear();
                            if (!context.mounted) {
                              return;
                            }
                            setState(() {
                              _appointmentDate = null;
                              _slot = 'MORNING';
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Visit booked successfully.'),
                              ),
                            );
                          },
                    label: 'Confirm Visit',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory(List<Map<String, dynamic>> appointments) {
    final grouped = {
      'Upcoming': appointments
          .where(
            (item) =>
                (item['status'] ?? '').toString().toUpperCase() !=
                    'COMPLETED' &&
                (item['status'] ?? '').toString().toUpperCase() != 'CANCELLED',
          )
          .toList(),
      'Completed': appointments
          .where(
            (item) =>
                (item['status'] ?? '').toString().toUpperCase() == 'COMPLETED',
          )
          .toList(),
      'Cancelled': appointments
          .where(
            (item) =>
                (item['status'] ?? '').toString().toUpperCase() == 'CANCELLED',
          )
          .toList(),
    };

    if (appointments.isEmpty) {
      return AgentPanelCard(
        title: 'Visit History',
        subtitle:
            'Once visits are created for the selected customer, they appear here with status-aware actions.',
        child: AgentEmptyState(
          icon: Icons.event_available_outlined,
          title: 'No visits booked yet',
          message:
              'Use the booking flow to create the first appointment for this customer. Upcoming, completed, and cancelled visits will then stay separated here.',
          actionLabel: 'Book the first visit',
          onAction: _scrollComposerIntoView,
        ),
      );
    }

    return AgentPanelCard(
      title: 'Visit History',
      subtitle:
          'Status-split history keeps upcoming, completed, and cancelled visits readable inside one workspace.',
      child: Column(
        children: grouped.entries
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AgentPanelCard(
                  title: entry.key,
                  child: entry.value.isEmpty
                      ? AgentEmptyState(
                          icon: Icons.event_note_outlined,
                          title: 'No ${entry.key.toLowerCase()} visits',
                          message:
                              'This visit section will fill once more appointments move into ${entry.key.toLowerCase()}.',
                        )
                      : Column(
                          children: entry.value.take(10).map<Widget>((
                            appointment,
                          ) {
                            final appointmentId =
                                appointment['id']?.toString() ?? '';
                            final customerId =
                                appointment['customerId']?.toString() ??
                                ref
                                    .read(agentPortalControllerProvider)
                                    .selectedCustomerId ??
                                '';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerLowest,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          appointment['customerName']
                                                  ?.toString() ??
                                              appointment['customer']?['firstName']
                                                  ?.toString() ??
                                              'Customer',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleSmall,
                                        ),
                                      ),
                                      AgentStatusBadge(
                                        label: _humanize(appointment['status']),
                                        color: _statusColor(
                                          appointment['status']?.toString(),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${_formatDate(appointment['appointmentDate'])} • ${_humanize(appointment['appointmentType'])}',
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    appointment['provider']?['providerName']
                                            ?.toString() ??
                                        appointment['providerName']
                                            ?.toString() ??
                                        'Provider',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      AgentGhostButton(
                                        onPressed: () async {
                                          await ref
                                              .read(
                                                agentPortalControllerProvider,
                                              )
                                              .confirmAppointment(
                                                appointmentId: appointmentId,
                                                customerId: customerId,
                                              );
                                        },
                                        label: 'Confirm',
                                      ),
                                      AgentGhostButton(
                                        onPressed: () async {
                                          final picked = await showShieldDatePicker(
                                            context,
                                            initialDate: DateTime.now().add(
                                              const Duration(days: 1),
                                            ),
                                            firstDate: DateTime.now(),
                                            lastDate: DateTime.now().add(
                                              const Duration(days: 365),
                                            ),
                                            title: 'Reschedule visit',
                                            helperText:
                                                'Choose the replacement date for this appointment.',
                                            autoCloseOnSelect: true,
                                          );
                                          if (picked != null) {
                                            await ref
                                                .read(
                                                  agentPortalControllerProvider,
                                                )
                                                .rescheduleAppointment(
                                                  appointmentId: appointmentId,
                                                  customerId: customerId,
                                                  appointmentDate: _slotDate(
                                                    picked,
                                                    _slot,
                                                  ),
                                                  remarks:
                                                      'Rescheduled from Agent Portal',
                                                );
                                          }
                                        },
                                        label: 'Reschedule',
                                      ),
                                      AgentGhostButton(
                                        onPressed: () async {
                                          await ref
                                              .read(
                                                agentPortalControllerProvider,
                                              )
                                              .cancelAppointment(
                                                appointmentId: appointmentId,
                                                customerId: customerId,
                                              );
                                        },
                                        label: 'Cancel',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildProviderSelector(
    List<Map<String, dynamic>> providers, {
    required String? providerLookupError,
    required bool isProviderLookupLoading,
  }) {
    if (isProviderLookupLoading && providers.isEmpty) {
      return const ListTile(
        contentPadding: EdgeInsets.zero,
        leading: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text('Loading providers'),
        subtitle: Text('Fetching the live provider directory for booking.'),
      );
    }

    if (providerLookupError != null && providers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(
            context,
          ).colorScheme.errorContainer.withValues(alpha: 0.32),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Provider directory unavailable',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(providerLookupError),
            const SizedBox(height: 10),
            AgentSecondaryButton(
              onPressed: () => ref
                  .read(agentPortalControllerProvider)
                  .reloadReferenceData(force: true),
              label: 'Retry provider list',
            ),
          ],
        ),
      );
    }

    if (providers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
        ),
        child: const Text(
          'No active providers are available for booking right now. Try again later or ask an administrator to verify provider access.',
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: _providerId,
      items: providers
          .map(
            (provider) => DropdownMenuItem<String>(
              value: provider['id']?.toString(),
              child: Text(provider['providerName']?.toString() ?? 'Provider'),
            ),
          )
          .toList(),
      onChanged: (value) => setState(() => _providerId = value),
      decoration: const InputDecoration(labelText: 'Select provider'),
    );
  }

  Future<void> _scrollComposerIntoView() async {
    final currentContext = _composerKey.currentContext;
    if (currentContext == null) {
      return;
    }
    await Scrollable.ensureVisible(
      currentContext,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }
}

class _FlowStep extends StatelessWidget {
  const _FlowStep({
    required this.step,
    required this.label,
    required this.child,
  });

  final String step;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(radius: 16, child: Text(step)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ],
    );
  }
}

class _SlotChip {
  const _SlotChip({required this.slot});

  final String slot;
}

String _slotLabel(String slot) {
  switch (slot) {
    case 'AFTERNOON':
      return 'Afternoon';
    case 'EVENING':
      return 'Evening';
    default:
      return 'Morning';
  }
}

DateTime _slotDate(DateTime date, String slot) {
  switch (slot) {
    case 'AFTERNOON':
      return DateTime(date.year, date.month, date.day, 14);
    case 'EVENING':
      return DateTime(date.year, date.month, date.day, 17);
    default:
      return DateTime(date.year, date.month, date.day, 10);
  }
}

Color _statusColor(String? rawStatus) {
  switch ((rawStatus ?? '').toUpperCase()) {
    case 'COMPLETED':
    case 'CONFIRMED':
      return Colors.green.shade700;
    case 'CANCELLED':
      return Colors.red.shade700;
    default:
      return Colors.blue.shade700;
  }
}

String _humanize(dynamic value) {
  final text = (value ?? '').toString().trim();
  if (text.isEmpty) {
    return 'Pending';
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
  final parsed = value is DateTime
      ? value
      : DateTime.tryParse((value ?? '').toString());
  if (parsed == null) {
    return 'Not scheduled';
  }
  return ShieldDateUtils.formatShortMonthDateTime(parsed);
}
