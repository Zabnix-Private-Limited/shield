import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/presentation/controllers/agent_portal_provider.dart';
import '../../../shared/presentation/widgets/agent_section_header.dart';

class AgentFollowUpsScreen extends ConsumerStatefulWidget {
  const AgentFollowUpsScreen({super.key});

  @override
  ConsumerState<AgentFollowUpsScreen> createState() =>
      _AgentFollowUpsScreenState();
}

class _AgentFollowUpsScreenState extends ConsumerState<AgentFollowUpsScreen> {
  final _noteController = TextEditingController();
  DateTime? _selectedDueDate;
  String _selectedStatus = 'PENDING';

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(agentPortalControllerProvider).ensureLoaded(),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(agentPortalControllerProvider);
    final customerId = controller.selectedCustomerId;
    final selectedCustomer = controller.selectedCustomer;
    final customerName =
        selectedCustomer['firstName']?.toString().isNotEmpty == true
            ? '${selectedCustomer['firstName']} ${selectedCustomer['lastName'] ?? ''}'
                .trim()
            : 'Select a customer from My Customers';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AgentSectionHeader(
              title: 'Customer Follow-Up',
              description:
                  'Start with the customer, record the latest outcome, and schedule the next follow-up without hunting through generic task fields.',
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final stack = constraints.maxWidth < 920;
                final composer = _buildComposer(context, controller, customerId, customerName);
                final taskList = _buildTaskList(controller);
                if (stack) {
                  return Column(
                    children: [composer, const SizedBox(height: 16), taskList],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: composer),
                    const SizedBox(width: 16),
                    Expanded(child: taskList),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            _HistoryCard(items: controller.customerActivities),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer(
    BuildContext context,
    dynamic controller,
    String? customerId,
    String customerName,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Next follow-up', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(customerName),
              subtitle: Text(
                customerId == null
                    ? 'Choose a customer before creating a follow-up.'
                    : 'Customer selected for the next action.',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Remarks',
                hintText: 'What happened, what matters next, and what the agent should remember.',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(_selectedStatus),
                    initialValue: _selectedStatus,
                    items: const [
                      DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
                      DropdownMenuItem(
                        value: 'COMPLETED',
                        child: Text('Completed'),
                      ),
                      DropdownMenuItem(
                        value: 'CANCELLED',
                        child: Text('Cancelled'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedStatus = value ?? 'PENDING'),
                    decoration: const InputDecoration(labelText: 'Status'),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: OutlinedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now().subtract(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => _selectedDueDate = picked);
                      }
                    },
                    child: Text(
                      _selectedDueDate == null
                          ? 'Choose next follow-up'
                          : DateFormat('dd MMM yyyy').format(_selectedDueDate!),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: customerId == null || _selectedDueDate == null
                    ? null
                    : () async {
                        await ref.read(agentPortalControllerProvider).addFollowUpActivity(
                              customerId: customerId,
                              activityType: _selectedStatus == 'COMPLETED'
                                  ? 'FOLLOW_UP_COMPLETED'
                                  : 'FOLLOW_UP',
                              notes: _noteController.text.trim(),
                            );
                        await ref.read(agentPortalControllerProvider).scheduleFollowUp(
                              customerId: customerId,
                              dueDate: _selectedDueDate!,
                              notes: _noteController.text.trim(),
                            );
                        _noteController.clear();
                        setState(() {
                          _selectedDueDate = null;
                          _selectedStatus = 'PENDING';
                        });
                      },
                child: const Text('Save Follow-Up'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(dynamic controller) {
    final tasks = controller.tasks;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scheduled follow-ups',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (tasks.isEmpty)
              const Text('No scheduled follow-ups right now.')
            else
              ...tasks.take(12).map<Widget>(
                (task) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${task['customerName'] ?? 'Customer'}'),
                  subtitle: Text(
                    '${_formatDate(task['dueDate'])} • ${task['notes'] ?? 'No remarks'}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      await ref.read(agentPortalControllerProvider).updateFollowUpTask(
                            taskId: task['id']?.toString() ?? '',
                            customerId: task['customerId']?.toString() ?? '',
                            status: value,
                            notes: task['notes']?.toString(),
                          );
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'PENDING', child: Text('Keep pending')),
                      PopupMenuItem(
                        value: 'COMPLETED',
                        child: Text('Mark completed'),
                      ),
                      PopupMenuItem(
                        value: 'CANCELLED',
                        child: Text('Cancel'),
                      ),
                    ],
                    child: Chip(label: Text(_humanize(task['status']))),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.items});

  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent outcomes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Text('No follow-up history is recorded for the selected customer.')
            else
              ...items.take(10).map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_humanize(item['activityType'])),
                  subtitle: Text('${item['notes'] ?? 'No remarks'}'),
                  trailing: Text(_formatDate(item['createdAt'])),
                ),
              ),
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
    return 'Date not set';
  }
  return DateFormat('dd MMM, h:mm a').format(parsed.toLocal());
}
