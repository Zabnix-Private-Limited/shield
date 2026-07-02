import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/presentation/controllers/agent_portal_provider.dart';
import '../../../shared/presentation/widgets/agent_experience_widgets.dart';
import '../../../shared/presentation/widgets/agent_section_header.dart';

class AgentPerformanceScreen extends ConsumerStatefulWidget {
  const AgentPerformanceScreen({super.key});

  @override
  ConsumerState<AgentPerformanceScreen> createState() =>
      _AgentPerformanceScreenState();
}

class _AgentPerformanceScreenState
    extends ConsumerState<AgentPerformanceScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(agentPortalControllerProvider).ensureLoaded(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(agentPortalControllerProvider);
    final performance = controller.performance;
    final summary = controller.summary;
    final completedFollowUps =
        (performance['completedFollowUps'] as num?)?.toInt() ?? 0;
    final customersAdded = (performance['customersAdded'] as num?)?.toInt() ?? 0;
    final customersActive =
        (performance['customersActive'] as num?)?.toInt() ?? 0;
    final pendingFollowUps =
        customersAdded - completedFollowUps < 0 ? 0 : customersAdded - completedFollowUps;
    final appointments = (performance['appointmentsGenerated'] as num?)?.toInt() ?? 0;
    final retentionRate = (performance['retentionRate'] as num?)?.toDouble() ?? 0;
    final conversionRate = (performance['conversionRate'] as num?)?.toDouble() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AgentSectionHeader(
          title: 'Performance',
          description:
              'This page now reads more like a performance review than a row of placeholder cards, using daily and monthly summaries plus simple progress visuals.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            AgentMetricCard(
              value: '${summary['todaysFollowUps'] ?? 0}',
              label: 'Daily follow-ups',
              helper: 'Tasks actively scheduled today.',
              icon: Icons.today_outlined,
              color: Colors.blue.shade700,
              onTap: () => context.go('/portal/agent/followups'),
            ),
            AgentMetricCard(
              value: '${summary['appointmentsToday'] ?? 0}',
              label: 'Daily visits',
              helper: 'Appointments scheduled for the day.',
              icon: Icons.event_available_outlined,
              color: Colors.green.shade700,
              onTap: () => context.go('/portal/agent/appointments'),
            ),
            AgentMetricCard(
              value: '$customersAdded',
              label: 'Monthly customers',
              helper: 'Customers added in the current month view.',
              icon: Icons.person_add_alt_1_outlined,
              color: Colors.indigo.shade700,
              onTap: () => context.go('/portal/agent/customers'),
            ),
            AgentMetricCard(
              value: '${summary['pendingDocuments'] ?? 0}',
              label: 'Document backlog',
              helper: 'Customer documents still waiting for upload.',
              icon: Icons.folder_open_outlined,
              color: Colors.orange.shade700,
              onTap: () => context.go('/portal/agent/documents'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final stack = constraints.maxWidth < 960;
            final left = Column(
              children: [
                AgentPanelCard(
                  title: 'Monthly Overview',
                  subtitle:
                      'The high-level measures that describe how the current month is moving.',
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _MiniPerformanceCard(
                        label: 'Customers Added',
                        value: '$customersAdded',
                        route: '/portal/agent/customers',
                      ),
                      _MiniPerformanceCard(
                        label: 'Active Customers',
                        value: '$customersActive',
                        route: '/portal/agent/customers',
                      ),
                      _MiniPerformanceCard(
                        label: 'Pending Follow-Ups',
                        value: '$pendingFollowUps',
                        route: '/portal/agent/followups',
                      ),
                      _MiniPerformanceCard(
                        label: 'Completed Follow-Ups',
                        value: '$completedFollowUps',
                        route: '/portal/agent/followups',
                      ),
                      _MiniPerformanceCard(
                        label: 'Visits',
                        value: '$appointments',
                        route: '/portal/agent/appointments',
                      ),
                      _MiniPerformanceCard(
                        label: 'Retention',
                        value: '${retentionRate.toStringAsFixed(0)}%',
                        route: '/portal/agent/customers',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AgentPanelCard(
                  title: 'Progress',
                  subtitle:
                      'Simple visual progress indicators replace dead placeholder analytics.',
                  child: Column(
                    children: [
                      _ProgressLine(
                        label: 'Retention',
                        value: retentionRate,
                        helper:
                            'How well the current customer portfolio is being retained.',
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(height: 12),
                      _ProgressLine(
                        label: 'Conversion',
                        value: conversionRate,
                        helper:
                            'Current conversion pace toward monthly acquisition goals.',
                        color: Colors.indigo.shade700,
                      ),
                    ],
                  ),
                ),
              ],
            );
            final right = Column(
              children: [
                AgentPanelCard(
                  title: 'Operational Breakdown',
                  subtitle:
                      'A cleaner view of where the agent effort is being spent.',
                  child: Column(
                    children: [
                      _BreakdownTile(
                        label: 'Customer activity',
                        value: '$customersActive active / $customersAdded added',
                        helper: 'Portfolio health and acquisition balance.',
                      ),
                      _BreakdownTile(
                        label: 'Follow-up completion',
                        value: '$completedFollowUps completed / $pendingFollowUps pending',
                        helper: 'Workload and completion discipline.',
                      ),
                      _BreakdownTile(
                        label: 'Visits',
                        value: '$appointments scheduled',
                        helper: 'Operational visit generation this month.',
                      ),
                      _BreakdownTile(
                        label: 'Document backlog',
                        value: '${summary['pendingDocuments'] ?? 0} pending files',
                        helper: 'Customer documentation still waiting for action.',
                      ),
                    ],
                  ),
                ),
              ],
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
        ),
      ],
    );
  }
}

class _MiniPerformanceCard extends StatelessWidget {
  const _MiniPerformanceCard({
    required this.label,
    required this.value,
    required this.route,
  });

  final String label;
  final String value;
  final String route;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(16),
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                Text(value, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({
    required this.label,
    required this.value,
    required this.helper,
    required this.color,
  });

  final String label;
  final double value;
  final String helper;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final normalized = (value / 100).clamp(0, 1).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.titleSmall),
            ),
            Text('${value.toStringAsFixed(0)}%'),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: normalized,
            minHeight: 10,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Text(helper, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _BreakdownTile extends StatelessWidget {
  const _BreakdownTile({
    required this.label,
    required this.value,
    required this.helper,
  });

  final String label;
  final String value;
  final String helper;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(value),
            const SizedBox(height: 4),
            Text(helper, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
