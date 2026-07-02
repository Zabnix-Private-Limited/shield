import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/presentation/controllers/agent_portal_provider.dart';
import '../../../shared/presentation/widgets/agent_section_header.dart';

class AgentReferralsScreen extends ConsumerStatefulWidget {
  const AgentReferralsScreen({super.key});

  @override
  ConsumerState<AgentReferralsScreen> createState() => _AgentReferralsScreenState();
}

class _AgentReferralsScreenState extends ConsumerState<AgentReferralsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(agentPortalControllerProvider).ensureLoaded(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workspace =
        ref.watch(agentPortalControllerProvider).selectedCustomerWorkspace;
    final referralSummary =
        Map<String, dynamic>.from(workspace['referralSummary'] ?? const {});
    final referralTree =
        Map<String, dynamic>.from(workspace['referralTree'] ?? const {});
    final history = List<Map<String, dynamic>>.from(
      (referralSummary['history'] as List? ?? const <dynamic>[]).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );
    final statuses = Map<String, dynamic>.from(
      referralSummary['statuses'] ?? const {},
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AgentSectionHeader(
              title: 'Customer Network',
              description:
                  'Relationship growth should feel like customer-community building, not referral administration.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ReferralStatCard(
                  label: 'Direct customers',
                  value: '${referralSummary['directReferrals'] ?? 0}',
                ),
                _ReferralStatCard(
                  label: 'Total network',
                  value: '${referralSummary['totalReferrals'] ?? 0}',
                ),
                _ReferralStatCard(
                  label: 'Network rewards',
                  value: '${referralSummary['availablePoints'] ?? 0}',
                ),
                _ReferralStatCard(
                  label: 'Earned rewards',
                  value: '${referralSummary['earnedPoints'] ?? 0}',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer growth status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (statuses.isEmpty)
                      const Text('No customer network events have been recorded yet.')
                    else
                      ...statuses.entries.map(
                        (entry) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(_humanize(entry.key)),
                          trailing: Text('${entry.value}'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final stack = constraints.maxWidth < 900;
                final treeCard = _ReferralTreeCard(tree: referralTree);
                final historyCard = _ReferralHistoryCard(history: history);
                if (stack) {
                  return Column(
                    children: [treeCard, const SizedBox(height: 16), historyCard],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: treeCard),
                    const SizedBox(width: 16),
                    Expanded(child: historyCard),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferralStatCard extends StatelessWidget {
  const _ReferralStatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReferralTreeCard extends StatelessWidget {
  const _ReferralTreeCard({required this.tree});

  final Map<String, dynamic> tree;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer tree', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (tree.isEmpty)
              const Text('No customer tree is available for this customer yet.')
            else
              _ReferralTreeNode(node: tree, depth: 0),
          ],
        ),
      ),
    );
  }
}

class _ReferralTreeNode extends StatelessWidget {
  const _ReferralTreeNode({required this.node, required this.depth});

  final Map<String, dynamic> node;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final children = List<Map<String, dynamic>>.from(
      (node['children'] as List? ?? const <dynamic>[]).whereType<Map>().map(
        (item) => Map<String, dynamic>.from(item),
      ),
    );
    final indent = depth * 20.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: indent, bottom: 8),
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(node['name']?.toString().trim().isNotEmpty == true
                ? node['name'].toString()
                : 'Customer'),
            subtitle: Text(
              'Joined ${_formatDate(node['registrationDate'])} • ${node['active'] == true ? 'Active' : 'Inactive'} • Rewards ${node['rewardPoints'] ?? 0}',
            ),
          ),
        ),
        ...children.map((child) => _ReferralTreeNode(node: child, depth: depth + 1)),
      ],
    );
  }
}

class _ReferralHistoryCard extends StatelessWidget {
  const _ReferralHistoryCard({required this.history});

  final List<Map<String, dynamic>> history;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer growth activity', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (history.isEmpty)
              const Text('No customer network activity has been recorded yet.')
            else
              ...history.take(12).map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${_humanize(item['status'])} • ${item['rewardPoints'] ?? 0} reward points',
                  ),
                  subtitle: Text(
                    'Linked customer ${item['referredCustomerId'] ?? '-'}',
                  ),
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
    return 'Date not recorded';
  }
  return DateFormat('dd MMM yyyy').format(parsed.toLocal());
}
