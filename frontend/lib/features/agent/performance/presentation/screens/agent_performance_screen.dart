import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/presentation/controllers/agent_portal_provider.dart';

class AgentPerformanceScreen extends ConsumerStatefulWidget {
  const AgentPerformanceScreen({super.key});

  @override
  ConsumerState<AgentPerformanceScreen> createState() => _AgentPerformanceScreenState();
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
        label: 'Customers added',
        value: '${performance['customersAdded'] ?? 0}',
        progress: _toProgress(performance['customersAdded']),
        route: '/portal/agent/customers',
      ),
      _PerformanceCardData(
        label: 'Active customers',
        value: '${performance['customersActive'] ?? 0}',
        progress: _toProgress(performance['customersActive']),
        route: '/portal/agent/customers',
      ),
      _PerformanceCardData(
        label: 'Retention',
        value: '${performance['retentionRate'] ?? 0}%',
        progress: ((performance['retentionRate'] as num?) ?? 0) / 100,
        route: '/portal/agent/customers',
      ),
      _PerformanceCardData(
        label: 'Referral conversion',
        value: '${performance['conversionRate'] ?? 0}%',
        progress: ((performance['conversionRate'] as num?) ?? 0) / 100,
        route: '/portal/agent/referrals',
      ),
      _PerformanceCardData(
        label: 'Appointments booked',
        value: '${performance['appointmentsGenerated'] ?? 0}',
        progress: _toProgress(performance['appointmentsGenerated']),
        route: '/portal/agent/appointments',
      ),
      _PerformanceCardData(
        label: 'Completed follow-ups',
        value: '${performance['completedFollowUps'] ?? 0}',
        progress: _toProgress(performance['completedFollowUps']),
        route: '/portal/agent/followups',
      ),
      _PerformanceCardData(
        label: 'Monthly incentives',
        value: '${performance['monthlyIncentives'] ?? 0}',
        progress: _toProgress(performance['monthlyIncentives']),
        route: '/portal/agent/referrals',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                            const SizedBox(height: 10),
                            LinearProgressIndicator(value: card.progress.clamp(0, 1)),
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
    );
  }
}

class _PerformanceCardData {
  const _PerformanceCardData({
    required this.label,
    required this.value,
    required this.progress,
    required this.route,
  });

  final String label;
  final String value;
  final double progress;
  final String route;
}

double _toProgress(dynamic value) {
  final number = (value as num?)?.toDouble() ?? 0;
  return number <= 0 ? 0 : number / (number + 10);
}
