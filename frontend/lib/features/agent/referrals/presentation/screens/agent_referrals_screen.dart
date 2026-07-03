import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/presentation/controllers/agent_portal_provider.dart';
import '../../../shared/presentation/widgets/agent_design_system.dart';
import '../../../shared/presentation/widgets/agent_experience_widgets.dart';
import '../../../shared/presentation/widgets/agent_section_header.dart';

class AgentReferralsScreen extends ConsumerStatefulWidget {
  const AgentReferralsScreen({super.key});

  @override
  ConsumerState<AgentReferralsScreen> createState() =>
      _AgentReferralsScreenState();
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
    final workspace = ref
        .watch(agentPortalControllerProvider)
        .selectedCustomerWorkspace;
    final referralSummary = Map<String, dynamic>.from(
      workspace['referralSummary'] ?? const {},
    );
    final referralTree = Map<String, dynamic>.from(
      workspace['referralTree'] ?? const {},
    );
    final history = List<Map<String, dynamic>>.from(
      (referralSummary['history'] as List? ?? const <dynamic>[]).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );
    final statuses = Map<String, dynamic>.from(
      referralSummary['statuses'] ?? const {},
    );

    return AgentWorkspaceSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AgentSectionHeader(
            title: 'Customer Network',
            description:
                'Track customer growth, reward status, and referral activity through one shared network workspace instead of a collection of unrelated cards.',
          ),
          AgentUi.gapH(AgentUi.space16),
          AgentMetricGrid(
            children: [
              AgentMetricCard(
                value: '${referralSummary['directReferrals'] ?? 0}',
                label: 'Direct Customers',
                helper: 'Customers directly linked to this member.',
                icon: Icons.people_alt_outlined,
              ),
              AgentMetricCard(
                value: '${referralSummary['totalReferrals'] ?? 0}',
                label: 'Total Network',
                helper:
                    'All connected customers in the visible referral graph.',
                icon: Icons.account_tree_outlined,
              ),
              AgentMetricCard(
                value: '${referralSummary['availablePoints'] ?? 0}',
                label: 'Network Rewards',
                helper: 'Reward points still available in the network.',
                icon: Icons.card_giftcard_outlined,
              ),
              AgentMetricCard(
                value: '${referralSummary['earnedPoints'] ?? 0}',
                label: 'Earned Rewards',
                helper: 'Reward points already claimed or earned.',
                icon: Icons.emoji_events_outlined,
              ),
            ],
          ),
          AgentUi.gapH(AgentUi.space16),
          Column(
            children: [
              AgentPanelCard(
                title: 'Customer Growth Status',
                subtitle:
                    'A normalized view of the status counts currently driving the network.',
                child: statuses.isEmpty
                    ? const AgentEmptyState(
                        icon: Icons.insights_outlined,
                        title: 'No network status data',
                        message:
                            'Status totals will appear here once referral activity is recorded for this customer.',
                      )
                    : Wrap(
                        spacing: AgentUi.space12,
                        runSpacing: AgentUi.space12,
                        children: statuses.entries
                            .map(
                              (entry) => SizedBox(
                                width: 220,
                                child: AgentKeyValueItem(
                                  label: _humanize(entry.key),
                                  value: '${entry.value}',
                                  icon: Icons.flag_outlined,
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
              AgentUi.gapH(AgentUi.space12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stack = constraints.maxWidth < 900;
                  final treeCard = _ReferralTreeCard(tree: referralTree);
                  final historyCard = _ReferralHistoryCard(history: history);
                  if (stack) {
                    return Column(
                      children: [
                        treeCard,
                        AgentUi.gapH(AgentUi.space12),
                        historyCard,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: treeCard),
                      AgentUi.gapW(AgentUi.space12),
                      Expanded(child: historyCard),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReferralTreeCard extends StatelessWidget {
  const _ReferralTreeCard({required this.tree});

  final Map<String, dynamic> tree;

  @override
  Widget build(BuildContext context) {
    return AgentPanelCard(
      title: 'Network Tree',
      subtitle:
          'A consistent tree view of customer relationships and reward-bearing nodes.',
      child: tree.isEmpty
          ? const AgentEmptyState(
              icon: Icons.account_tree_outlined,
              title: 'No customer tree yet',
              message:
                  'The referral network tree will render here after SHIELD records linked customer relationships.',
            )
          : _ReferralTreeNode(node: tree, depth: 0),
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
    final isActive = node['active'] == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(left: indent, bottom: AgentUi.space12),
          padding: AgentUi.cardBodyPadding,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: AgentUi.radius(AgentUi.radiusMedium),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: AgentUi.radius(AgentUi.radiusMedium),
                ),
                child: const Icon(Icons.person_outline),
              ),
              AgentUi.gapW(AgentUi.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node['name']?.toString().trim().isNotEmpty == true
                          ? node['name'].toString()
                          : 'Customer',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    AgentUi.gapH(AgentUi.space4),
                    Text(
                      'Joined ${_formatDate(node['registrationDate'])} • Rewards ${node['rewardPoints'] ?? 0}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              AgentStatusBadge(
                label: isActive ? 'Active' : 'Inactive',
                color: AgentUi.statusColor(
                  context,
                  isActive ? 'ACTIVE' : 'INACTIVE',
                ),
                icon: isActive
                    ? Icons.check_circle_outline
                    : Icons.pause_circle_outline,
              ),
            ],
          ),
        ),
        ...children.map(
          (child) => _ReferralTreeNode(node: child, depth: depth + 1),
        ),
      ],
    );
  }
}

class _ReferralHistoryCard extends StatelessWidget {
  const _ReferralHistoryCard({required this.history});

  final List<Map<String, dynamic>> history;

  @override
  Widget build(BuildContext context) {
    return AgentPanelCard(
      title: 'Customer Growth Activity',
      subtitle:
          'A shared activity list for reward events and customer network changes.',
      child: history.isEmpty
          ? const AgentEmptyState(
              icon: Icons.history_outlined,
              title: 'No network activity yet',
              message:
                  'Reward and referral events will appear here once the customer network starts growing.',
            )
          : Column(
              children: history
                  .take(12)
                  .map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.timeline_outlined),
                      title: Text(
                        '${_humanize(item['status'])} • ${item['rewardPoints'] ?? 0} reward points',
                      ),
                      subtitle: Text(
                        'Linked customer ${item['referredCustomerId'] ?? '-'}',
                      ),
                      trailing: Text(_formatDate(item['createdAt'])),
                    ),
                  )
                  .toList(),
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
    return 'Date not recorded';
  }
  return DateFormat('dd MMM yyyy').format(parsed.toLocal());
}
