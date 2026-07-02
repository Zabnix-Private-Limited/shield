import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/presentation/controllers/agent_portal_provider.dart';

class AgentAppointmentsScreen extends ConsumerStatefulWidget {
  const AgentAppointmentsScreen({super.key});

  @override
  ConsumerState<AgentAppointmentsScreen> createState() => _AgentAppointmentsScreenState();
}

class _AgentAppointmentsScreenState extends ConsumerState<AgentAppointmentsScreen> {
  String? _providerId;
  String _appointmentType = 'CONSULTATION';
  DateTime? _appointmentDate;
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
    final providers = controller.providers;

    _providerId ??= providers.isNotEmpty ? providers.first['id']?.toString() : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Appointment workflow', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final stack = constraints.maxWidth < 940;
                final composer = _buildComposer(
                  context,
                  controller,
                  selectedCustomerId,
                  providers,
                );
                final list = _buildAppointmentList(controller);
                if (stack) {
                  return Column(
                    children: [composer, const SizedBox(height: 16), list],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: composer),
                    const SizedBox(width: 16),
                    Expanded(child: list),
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
    dynamic controller,
    String? selectedCustomerId,
    List<Map<String, dynamic>> providers,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Book an appointment', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(_providerId),
              initialValue: _providerId,
              items: providers
                  .map(
                    (provider) => DropdownMenuItem<String>(
                      value: provider['id']?.toString(),
                      child: Text(
                        provider['providerName']?.toString() ?? 'Provider',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _providerId = value),
              decoration: const InputDecoration(labelText: 'Provider'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(_appointmentType),
              initialValue: _appointmentType,
              items: const [
                DropdownMenuItem(value: 'CONSULTATION', child: Text('Consultation')),
                DropdownMenuItem(value: 'HOME_VISIT', child: Text('Home visit')),
                DropdownMenuItem(value: 'CLINIC_VISIT', child: Text('Clinic visit')),
                DropdownMenuItem(value: 'LAB', child: Text('Lab test')),
              ],
              onChanged: (value) => setState(() => _appointmentType = value ?? 'CONSULTATION'),
              decoration: const InputDecoration(labelText: 'Visit type'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() {
                    _appointmentDate = picked.add(const Duration(hours: 10));
                  });
                }
              },
              child: Text(
                _appointmentDate == null
                    ? 'Choose appointment date'
                    : DateFormat('dd MMM yyyy').format(_appointmentDate!),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _remarksController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Visit notes',
                hintText: 'Reason for visit, reminder, or coordination note',
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: selectedCustomerId == null ||
                        _providerId == null ||
                        _appointmentDate == null
                    ? null
                    : () async {
                        await ref.read(agentPortalControllerProvider).createAppointment(
                              customerId: selectedCustomerId,
                              providerId: _providerId!,
                              appointmentType: _appointmentType,
                              appointmentDate: _appointmentDate!,
                              remarks: _remarksController.text.trim(),
                            );
                        _remarksController.clear();
                        setState(() => _appointmentDate = null);
                      },
                child: const Text('Book appointment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentList(dynamic controller) {
    final appointments = controller.customerAppointments.isNotEmpty
        ? controller.customerAppointments
        : controller.upcomingAppointments;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Appointment history', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (appointments.isEmpty)
              const Text('No appointments are available.')
            else
              ...appointments.take(12).map<Widget>((appointment) {
                final appointmentId = appointment['id']?.toString() ?? '';
                final customerId =
                    appointment['customerId']?.toString() ?? controller.selectedCustomerId ?? '';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    appointment['customerName']?.toString() ??
                        appointment['customer']?['firstName']?.toString() ??
                        'Customer',
                  ),
                  subtitle: Text(
                    '${_formatDate(appointment['appointmentDate'])} • ${_humanize(appointment['appointmentType'])}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'CONFIRM') {
                        await ref.read(agentPortalControllerProvider).confirmAppointment(
                              appointmentId: appointmentId,
                              customerId: customerId,
                            );
                      } else if (value == 'CANCEL') {
                        await ref.read(agentPortalControllerProvider).cancelAppointment(
                              appointmentId: appointmentId,
                              customerId: customerId,
                            );
                      } else if (value == 'RESCHEDULE') {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          await ref
                              .read(agentPortalControllerProvider)
                              .rescheduleAppointment(
                            appointmentId: appointmentId,
                            customerId: customerId,
                            appointmentDate: picked.add(const Duration(hours: 10)),
                            remarks: 'Rescheduled from Agent Portal',
                          );
                        }
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'CONFIRM', child: Text('Confirm')),
                      PopupMenuItem(value: 'RESCHEDULE', child: Text('Reschedule')),
                      PopupMenuItem(value: 'CANCEL', child: Text('Cancel')),
                    ],
                    child: Chip(label: Text(_humanize(appointment['status']))),
                  ),
                );
              }),
          ],
        ),
      ),
    );
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
      .map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _formatDate(dynamic value) {
  final parsed = DateTime.tryParse((value ?? '').toString());
  if (parsed == null) {
    return 'Not scheduled';
  }
  return DateFormat('dd MMM, h:mm a').format(parsed.toLocal());
}
