import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/utils/shield_date_utils.dart';
import '../../../../../shared/widgets/shield_date_picker.dart';
import '../../../shared/presentation/controllers/agent_portal_provider.dart';
import '../../../shared/presentation/widgets/agent_design_system.dart';
import '../../../shared/presentation/widgets/agent_experience_widgets.dart';
import '../../../shared/presentation/widgets/agent_section_header.dart';

class AgentFollowUpsScreen extends ConsumerStatefulWidget {
  const AgentFollowUpsScreen({super.key});

  @override
  ConsumerState<AgentFollowUpsScreen> createState() =>
      _AgentFollowUpsScreenState();
}

class _AgentFollowUpsScreenState extends ConsumerState<AgentFollowUpsScreen> {
  final GlobalKey _composerKey = GlobalKey();
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
      (task) =>
          _isOverdue(task['dueDate']) &&
          (task['status'] ?? '').toString().toUpperCase() != 'COMPLETED',
    );
    final upcomingTasks = controller.tasks.where(
      (task) => !_sameDay(task['dueDate']) && !_isOverdue(task['dueDate']),
    );
    final completedHistory = controller.customerActivities.where(
      (item) => (item['activityType'] ?? '').toString().toUpperCase().contains(
        'COMPLETED',
      ),
    );
    final taskSections = <_TaskSectionConfig>[
      if (overdueTasks.isNotEmpty)
        _TaskSectionConfig(
          title: 'Overdue',
          tasks: overdueTasks.toList(),
          badgeColor: AgentColors.danger,
        ),
      if (todayTasks.isNotEmpty)
        _TaskSectionConfig(
          title: 'Today',
          tasks: todayTasks.toList(),
          badgeColor: AgentColors.accentBlue,
        ),
      if (upcomingTasks.isNotEmpty)
        _TaskSectionConfig(
          title: 'Upcoming',
          tasks: upcomingTasks.toList(),
          badgeColor: AgentColors.success,
        ),
    ];
    final hasHistory = controller.customerActivities.isNotEmpty;
    final hasFollowUpContent = taskSections.isNotEmpty || hasHistory;

    if (controller.isLoading && controller.workspace.isEmpty) {
      return _buildLoadingState(context);
    }

    if ((controller.error ?? '').trim().isNotEmpty &&
        controller.workspace.isEmpty) {
      return _buildLoadErrorState(
        context,
        controller.error!,
        onRetry: () =>
            ref.read(agentPortalControllerProvider).refreshWorkspace(),
      );
    }

    final bodyHeight = (MediaQuery.sizeOf(context).height - 360).clamp(
      320.0,
      1200.0,
    );
    final prefersLargeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;

    return AgentWorkspaceSurface(
      padding: AgentUi.compactPanelPadding,
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
                color: AgentColors.accentBlue,
              ),
              AgentMetricCard(
                value: '${overdueTasks.length}',
                label: 'Overdue',
                helper: 'Items needing immediate attention.',
                icon: Icons.warning_amber_rounded,
                color: AgentColors.danger,
              ),
              AgentMetricCard(
                value: '${upcomingTasks.length}',
                label: 'Upcoming',
                helper: 'Future follow-up commitments.',
                icon: Icons.upcoming_outlined,
                color: AgentColors.success,
              ),
              AgentMetricCard(
                value: '${completedHistory.length}',
                label: 'Completed',
                helper: 'Logged completion outcomes for this customer.',
                icon: Icons.task_alt_outlined,
                color: AgentColors.accentTeal,
              ),
            ],
          ),
          AgentUi.gapH(AgentUi.space12),
          SizedBox(
            height: bodyHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stack = prefersLargeText || constraints.maxWidth < 980;
                final composer = _buildComposer(
                  context,
                  controller,
                  customerId,
                  customerName,
                );
                final detailPane = _buildDetailPane(
                  context,
                  controller: controller,
                  customerId: customerId,
                  hasFollowUpContent: hasFollowUpContent,
                  taskSections: taskSections,
                );

                if (stack) {
                  return ListView(
                    children: [
                      composer,
                      const SizedBox(height: 16),
                      detailPane,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: SingleChildScrollView(child: composer)),
                    AgentUi.gapW(AgentUi.space16),
                    Expanded(child: SingleChildScrollView(child: detailPane)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer(
    BuildContext context,
    dynamic controller,
    String? customerId,
    String customerName,
  ) {
    final lastActivity = controller.customerActivities.isNotEmpty
        ? controller.customerActivities.first
        : null;
    return AgentPanelCard(
      title: 'Add New Follow-Up',
      subtitle:
          'Start with the customer, then record remarks, status, and the next follow-up date in one compact flow.',
      child: Column(
        key: _composerKey,
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
              color: AgentColors.accentIndigo,
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
                child: AgentSecondaryButton(
                  onPressed: () async {
                    final picked = await showShieldDatePicker(
                      context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 1),
                      ),
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
                  label: _selectedDueDate == null
                      ? 'Choose next follow-up'
                      : ShieldDateUtils.formatShortMonthDate(_selectedDueDate!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: AgentPrimaryButton(
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
              label: 'Save Follow-Up',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPane(
    BuildContext context, {
    required dynamic controller,
    required String? customerId,
    required bool hasFollowUpContent,
    required List<_TaskSectionConfig> taskSections,
  }) {
    if (controller.isCustomerLoading) {
      return _buildCustomerLoadingState();
    }

    if ((controller.error ?? '').trim().isNotEmpty &&
        customerId != null &&
        controller.selectedCustomerWorkspace.isEmpty) {
      return _buildLoadErrorState(
        context,
        controller.error!,
        onRetry: () =>
            ref.read(agentPortalControllerProvider).selectCustomer(customerId),
      );
    }

    if (customerId == null) {
      return AgentPanelCard(
        title: 'No Customer Selected',
        subtitle:
            'Follow-up actions open once a customer workspace is selected from the customer list.',
        child: AgentEmptyState(
          icon: Icons.people_alt_outlined,
          title: 'Choose a customer first',
          message:
              'Open the customer workspace to schedule the next follow-up, review history, and close overdue actions without leaving dead space on the page.',
          actionLabel: 'Open Customers',
          onAction: () => context.go('/portal/agent/customers'),
          secondaryActionLabel: 'Refresh',
          onSecondaryAction: () =>
              ref.read(agentPortalControllerProvider).refreshWorkspace(),
        ),
      );
    }

    if (!hasFollowUpContent) {
      return AgentPanelCard(
        title: 'Follow-Up Queue',
        subtitle:
            'This customer does not have any open or completed follow-up activity yet.',
        child: AgentEmptyState(
          icon: Icons.event_note_outlined,
          title: 'No Follow-Ups Yet',
          message:
              'Schedule the first follow-up for this customer to create reminders, timelines, and completion history here.',
          actionLabel: 'Schedule Follow-Up',
          onAction: _scrollToComposer,
          secondaryActionLabel: 'Open Customers',
          onSecondaryAction: () => context.go('/portal/agent/customers'),
        ),
      );
    }

    return ListView(
      children: [
        ...taskSections.map(
          (section) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildTaskSection(
              title: section.title,
              tasks: section.tasks,
              badgeColor: section.badgeColor,
            ),
          ),
        ),
        if (controller.customerActivities.isNotEmpty)
          _HistoryCard(items: controller.customerActivities),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return AgentWorkspaceSurface(
      padding: AgentSpacing.contentInsets,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AgentSectionHeader(
            title: 'Follow-Ups',
            description:
                'Loading the follow-up workspace so today, overdue, and historical activity render in one production state.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(
              4,
              (index) => SizedBox(
                width: 220,
                child: AgentPanelCard(
                  title: 'Loading',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      LinearProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Loading follow-up metrics...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerLoadingState() {
    return const AgentPanelCard(
      title: 'Loading Follow-Up Activity',
      subtitle:
          'Fetching the selected customer follow-up queue and recent activity.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(),
          SizedBox(height: 12),
          Text('Loading follow-up tasks and history...'),
        ],
      ),
    );
  }

  Widget _buildLoadErrorState(
    BuildContext context,
    String message, {
    required VoidCallback onRetry,
  }) {
    return AgentPanelCard(
      title: 'Follow-Ups Unavailable',
      subtitle:
          'The follow-up workspace could not be rendered correctly, so SHIELD is showing a recoverable error state instead of an empty panel.',
      child: AgentErrorState(
        title: 'We could not load the follow-up workflow',
        message: _resolveFollowUpError(message),
        onRetry: onRetry,
      ),
    );
  }

  Widget _buildTaskSection({
    required String title,
    required List<Map<String, dynamic>> tasks,
    required Color badgeColor,
  }) {
    return AgentPanelCard(
      title: title,
      child: Column(
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
                    Text(
                      task['notes']?.toString().ifBlank('No remarks') ??
                          'No remarks',
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AgentStatusBadge(
                          label: _formatDate(task['dueDate']),
                          color: AgentColors.accentIndigo,
                          icon: Icons.schedule_outlined,
                        ),
                        AgentGhostButton(
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
                          label: 'Complete',
                        ),
                        AgentGhostButton(
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
                          label: 'Cancel',
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

  Future<void> _scrollToComposer() async {
    final context = _composerKey.currentContext;
    if (context == null) {
      return;
    }
    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
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
      child: Column(
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
                          Text(
                            item['notes']?.toString().ifBlank('No remarks') ??
                                'No remarks',
                          ),
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

class _TaskSectionConfig {
  const _TaskSectionConfig({
    required this.title,
    required this.tasks,
    required this.badgeColor,
  });

  final String title;
  final List<Map<String, dynamic>> tasks;
  final Color badgeColor;
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
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
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

String _resolveFollowUpError(String message) {
  final normalized = message.trim();
  final lowered = normalized.toLowerCase();
  if (lowered.contains('401') || lowered.contains('unauthorized')) {
    return 'Your SHIELD session expired before follow-up data could load. Sign in again and retry.';
  }
  if (lowered.contains('403') || lowered.contains('forbidden')) {
    return 'This SHIELD role does not have permission to open the requested follow-up workspace.';
  }
  if (lowered.contains('network') || lowered.contains('socket')) {
    return 'The follow-up workspace could not reach the server. Check the connection and retry.';
  }
  return normalized.isEmpty
      ? 'The follow-up workspace could not be loaded right now.'
      : normalized;
}

extension on String {
  String ifBlank(String fallback) => trim().isEmpty ? fallback : this;
}
