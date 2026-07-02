import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/controllers/agent_portal_provider.dart';

class AgentDashboardScreen extends ConsumerStatefulWidget {
  const AgentDashboardScreen({super.key});

  @override
  ConsumerState<AgentDashboardScreen> createState() => _AgentDashboardScreenState();
}

class _AgentDashboardScreenState extends ConsumerState<AgentDashboardScreen> {
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
    final summary = controller.summary;
    final performance = controller.performance;

    if (controller.isLoading && controller.workspace.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard('Today follow-ups', '${summary['todaysFollowUps'] ?? 0}'),
            _MetricCard('Pending registrations', '${summary['pendingRegistrations'] ?? 0}'),
            _MetricCard('Appointments today', '${summary['appointmentsToday'] ?? 0}'),
            _MetricCard('New referrals', '${summary['newReferrals'] ?? 0}'),
            _MetricCard('Monthly adds', '${performance['customersAdded'] ?? 0}'),
            _MetricCard('Retention %', '${performance['retentionRate'] ?? 0}'),
          ],
        ),
        const SizedBox(height: 20),
        _ListSection(
          title: 'Recent activity',
          items: controller.recentActivity,
          titleKey: 'activityType',
          subtitleKey: 'customerName',
          metaKey: 'notes',
          trailingKey: 'createdAt',
        ),
        const SizedBox(height: 20),
        _ListSection(
          title: 'Upcoming appointments',
          items: controller.upcomingAppointments,
          titleKey: 'customerName',
          subtitleKey: 'providerName',
          metaKey: 'appointmentType',
          trailingKey: 'status',
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListSection extends StatelessWidget {
  const _ListSection({
    required this.title,
    required this.items,
    required this.titleKey,
    required this.subtitleKey,
    required this.metaKey,
    required this.trailingKey,
  });

  final String title;
  final List<Map<String, dynamic>> items;
  final String titleKey;
  final String subtitleKey;
  final String metaKey;
  final String trailingKey;

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
            if (items.isEmpty)
              const Text('No records yet.')
            else
              ...items.take(6).map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${item[titleKey] ?? ''}'),
                  subtitle: Text('${item[subtitleKey] ?? ''}'),
                  leading: Text('${item[metaKey] ?? ''}'),
                  trailing: Text('${item[trailingKey] ?? ''}'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
