import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/controllers/agent_portal_provider.dart';
import '../../../shared/presentation/widgets/agent_experience_widgets.dart';
import '../../../shared/presentation/widgets/agent_section_header.dart';
import '../../../../../shared/utils/shield_date_utils.dart';
import '../../../../../shared/widgets/shield_date_picker.dart';

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
            : 'Select a customer from Customers';

    final todayTasks = controller.tasks.where(
      (task) => _sameDay(task['dueDate']),
    );
    final overdueTasks = controller.tasks.where(
      (task) => _isOverdue(task['dueDate']) &&
          (task['status'] ?? '').toString().toUpperCase() != 'COMPLETED',
    );
    final upcomingTasks = controller.tasks.where(
      (task) => !_sameDay(task['dueDate']) && !_isOverdue(task['dueDate']),
    );
    final completedHistory = controller.customerActivities.where(
      (item) => (item['activityType'] ?? '')
          .toString()
          .toUpperCase()
          .contains('COMPLETED'),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AgentSectionHeader(
              title: 'Follow-Ups',
              description:
                  'Today, overdue, and upcoming follow-ups are separated clearly so agents can act first and log details second.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AgentMetricCard(
                  value: '${todayTasks.length}',
                  label: 'Today',
                  helper: 'Follow-ups scheduled for today.',
                  icon: Icons.today_outlined,
                  color: Colors.blue.shade700,
                ),
                AgentMetricCard(
                  value: '${overdueTasks.length}',
                  label: 'Overdue',
                  helper: 'Items needing immediate attention.',
                  icon: Icons.warning_amber_rounded,
                  color: Colors.red.shade700,
                ),
                AgentMetricCard(
                  value: '${upcomingTasks.length}',
                  label: 'Upcoming',
                  helper: 'Future follow-up commitments.',
                  icon: Icons.upcoming_outlined,
                  color: Colors.green.shade700,
                ),
                AgentMetricCard(
                  value: '${completedHistory.length}',
                  label: 'Completed',
                  helper: 'Logged completion outcomes for this customer.',
                  icon: Icons.task_alt_outlined,
                  color: Colors.teal.shade700,
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final stack = constraints.maxWidth < 980;
                final composer = _buildComposer(
                  context,
                  controller,
                  customerId,
                  customerName,
                );
                final lists = Column(
                  children: [
                    _buildTaskSection(
                      title: 'Overdue',
                      emptyMessage:
                          'No overdue follow-ups. The urgent queue is clear.',
                      tasks: overdueTasks.toList(),
                      badgeColor: Colors.red.shade700,
                    ),
                    const SizedBox(height: 12),
                    _buildTaskSection(
                      title: 'Today',
                      emptyMessage:
                          'Nothing is scheduled for today yet.',
                      tasks: todayTasks.toList(),
                      badgeColor: Colors.blue.shade700,
                    ),
                    const SizedBox(height: 12),
                    _buildTaskSection(
                      title: 'Upcoming',
                      emptyMessage: 'No upcoming follow-ups are scheduled.',
                      tasks: upcomingTasks.toList(),
                      badgeColor: Colors.green.shade700,
                    ),
                  ],
                );

                if (stack) {
                  return Expanded(
                    child: ListView(
                      children: [
                        composer,
                        const SizedBox(height: 16),
                        lists,
                        const SizedBox(height: 16),
                        _HistoryCard(items: controller.customerActivities),
                      ],
                    ),
                  );
                }

                return Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: composer),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ListView(
                          children: [
                            lists,
                            const SizedBox(height: 12),
                            _HistoryCard(items: controller.customerActivities),
                          ],
                        ),
                      ),
                    ],
                  ),
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
    String? customerId,
    String customerName,
  ) {
    final lastActivity =
        controller.customerActivities.isNotEmpty ? controller.customerActivities.first : null;
    return AgentPanelCard(
      title: 'Add New Follow-Up',
      subtitle:
          'Start with the customer, then record remarks, status, and the next follow-up date in one compact flow.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(customerName),
            subtitle: Text(
              customerId == null
                  ? 'Choose a customer before creating a follow-up.'
                  : 'Customer selected for the next follow-up.',
            ),
          ),
          if (lastActivity != null) ...[
            const SizedBox(height: 8),
            AgentStatusBadge(
              label:
                  'Last follow-up: ${_formatDate(lastActivity['createdAt'])}',
              color: Colors.indigo.shade700,
              icon: Icons.history_outlined,
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _noteController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Remarks',
              hintText:
                  'What happened, what matters next, and what the agent should remember.',
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
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showShieldDatePicker(
                      context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      title: 'Schedule follow-up',
                      helperText:
                          'Choose the next follow-up date for this customer.',
                      autoCloseOnSelect: true,
                    );
                    if (picked != null) {
                      setState(() => _selectedDueDate = picked);
                    }
                  },
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(
                    _selectedDueDate == null
                        ? 'Choose next follow-up'
                        : ShieldDateUtils.formatShortMonthDate(
                            _selectedDueDate!,
                          ),
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
                      await ref
                          .read(agentPortalControllerProvider)
                          .addFollowUpActivity(
                            customerId: customerId,
                            activityType: _selectedStatus == 'COMPLETED'
                                ? 'FOLLOW_UP_COMPLETED'
                                : 'FOLLOW_UP',
                            notes: _noteController.text.trim(),
                          );
                      await ref
                          .read(agentPortalControllerProvider)
                          .scheduleFollowUp(
                            customerId: customerId,
                            dueDate: _selectedDueDate!,
                            notes: _noteController.text.trim(),
                          );
                      _noteController.clear();
                      if (!context.mounted) {
                        return;
                      }
                      setState(() {
                        _selectedDueDate = null;
                        _selectedStatus = 'PENDING';
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Follow-up saved successfully.'),
                        ),
                      );
                    },
              child: const Text('Save Follow-Up'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskSection({
    required String title,
    required String emptyMessage,
    required List<Map<String, dynamic>> tasks,
    required Color badgeColor,
  }) {
    return AgentPanelCard(
      title: title,
      child: tasks.isEmpty
          ? AgentEmptyState(
              icon: Icons.assignment_turned_in_outlined,
              title: 'Nothing here',
              message: emptyMessage,
            )
          : Column(
              children: tasks
                  .take(8)
                  .map<Widget>(
                    (task) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Theme.of(context).colorScheme.surfaceContainerLowest,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  task['customerName']?.toString() ?? 'Customer',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                              AgentStatusBadge(
                                label: _humanize(task['status']),
                                color: badgeColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(task['notes']?.toString().ifBlank('No remarks') ??
                              'No remarks'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              AgentStatusBadge(
                                label: _formatDate(task['dueDate']),
                                color: Colors.indigo.shade700,
                                icon: Icons.schedule_outlined,
                              ),
                              TextButton(
                                onPressed: () async {
                                  await ref
                                      .read(agentPortalControllerProvider)
                                      .updateFollowUpTask(
                                        taskId: task['id']?.toString() ?? '',
                                        customerId:
                                            task['customerId']?.toString() ?? '',
                                        status: 'COMPLETED',
                                        notes: task['notes']?.toString(),
                                      );
                                },
                                child: const Text('Complete'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await ref
                                      .read(agentPortalControllerProvider)
                                      .updateFollowUpTask(
                                        taskId: task['id']?.toString() ?? '',
                                        customerId:
                                            task['customerId']?.toString() ?? '',
                                        status: 'CANCELLED',
                                        notes: task['notes']?.toString(),
                                      );
                                },
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.items});

  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    return AgentPanelCard(
      title: 'Follow-Up History',
      subtitle:
          'A simple timeline of recorded outcomes so follow-up notes feel operational rather than form-only.',
      child: items.isEmpty
          ? const AgentEmptyState(
              icon: Icons.history_outlined,
              title: 'No history yet',
              message:
                  'Once follow-up outcomes are recorded, they appear here as a timeline.',
            )
          : Column(
              children: items
                  .take(10)
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            child: Icon(Icons.history_outlined, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _humanize(item['activityType']),
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 2),
                                Text(item['notes']?.toString().ifBlank('No remarks') ??
                                    'No remarks'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _formatDate(item['createdAt']),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

bool _sameDay(dynamic value) {
  final parsed = DateTime.tryParse((value ?? '').toString())?.toLocal();
  if (parsed == null) {
    return false;
  }
  final now = DateTime.now();
  return parsed.year == now.year &&
      parsed.month == now.month &&
      parsed.day == now.day;
}

bool _isOverdue(dynamic value) {
  final parsed = DateTime.tryParse((value ?? '').toString())?.toLocal();
  if (parsed == null) {
    return false;
  }
  return parsed.isBefore(DateTime.now());
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
        (part) =>
            part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}

String _formatDate(dynamic value) {
  final parsed = DateTime.tryParse((value ?? '').toString());
  if (parsed == null) {
    return 'Date not set';
  }
  return ShieldDateUtils.formatShortMonthDateTime(parsed);
}

extension on String {
  String ifBlank(String fallback) => trim().isEmpty ? fallback : this;
}
