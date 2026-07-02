import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/presentation/controllers/agent_portal_provider.dart';
import '../../../shared/presentation/widgets/agent_section_header.dart';

class AgentPerformanceScreen extends ConsumerStatefulWidget {
  const AgentPerformanceScreen({super.key});

  @override
  ConsumerState<AgentPerformanceScreen> createState() =>
      _AgentPerformanceScreenState();
}

class _AgentPerformanceScreenState extends ConsumerState<AgentPerformanceScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(agentPortalControllerProvider).ensureLoaded(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final performance = ref.watch(agentPortalControllerProvider).performance;
    final cards = [
      _PerformanceCardData(
        label: 'Customers Added',
        value: '${performance['customersAdded'] ?? 0}',
        helper: 'New customers registered this month.',
        route: '/portal/agent/customers',
      ),
      _PerformanceCardData(
        label: 'Active Customers',
        value: '${performance['customersActive'] ?? 0}',
        helper: 'Customers still actively engaged in your portfolio.',
        route: '/portal/agent/customers',
      ),
      _PerformanceCardData(
        label: 'Pending Follow-Ups',
        value:
            '${((performance['customersAdded'] as num?) ?? 0) - ((performance['completedFollowUps'] as num?) ?? 0) < 0 ? 0 : (((performance['customersAdded'] as num?) ?? 0) - ((performance['completedFollowUps'] as num?) ?? 0)).round()}',
        helper: 'Remaining follow-up load this month.',
        route: '/portal/agent/followups',
      ),
      _PerformanceCardData(
        label: 'Completed Follow-Ups',
        value: '${performance['completedFollowUps'] ?? 0}',
        helper: 'Follow-ups successfully closed this month.',
        route: '/portal/agent/followups',
      ),
      _PerformanceCardData(
        label: 'Appointments',
        value: '${performance['appointmentsGenerated'] ?? 0}',
        helper: 'Visits created from the Agent Portal.',
        route: '/portal/agent/appointments',
      ),
      _PerformanceCardData(
        label: 'Retention',
        value: '${performance['retentionRate'] ?? 0}%',
        helper: 'Current retention across your customer base.',
        route: '/portal/agent/customers',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AgentSectionHeader(
          title: 'My Performance',
          description:
              'A simple month view of customer growth, follow-through, visits, and retention without empty dashboard-style placeholders.',
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('This Month', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: cards
                      .map(
                        (card) => SizedBox(
                          width: 260,
                          child: InkWell(
                            onTap: () => context.go(card.route),
                            borderRadius: BorderRadius.circular(16),
                            child: Card(
                              margin: EdgeInsets.zero,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(card.label),
                                    const SizedBox(height: 8),
                                    Text(
                                      card.value,
                                      style: Theme.of(context).textTheme.headlineSmall,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      card.helper,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PerformanceCardData {
  const _PerformanceCardData({
    required this.label,
    required this.value,
    required this.helper,
    required this.route,
  });

  final String label;
  final String value;
  final String helper;
  final String route;
}
