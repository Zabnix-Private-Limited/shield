import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
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
    final controller = ref.watch(agentPortalControllerProvider);
    final agentWorkspace = controller.workspace;
    final customerWorkspace = controller.selectedCustomerWorkspace;

    final referralSummary = Map<String, dynamic>.from(
      (agentWorkspace['referralSummary'] != null &&
              (agentWorkspace['referralSummary'] as Map).isNotEmpty)
          ? agentWorkspace['referralSummary']
          : (customerWorkspace['referralSummary'] ?? const {}),
    );

    final referralTree = Map<String, dynamic>.from(
      (agentWorkspace['referralTree'] != null &&
              (agentWorkspace['referralTree'] as Map).isNotEmpty)
          ? agentWorkspace['referralTree']
          : (customerWorkspace['referralTree'] ?? const {}),
    );

    final history = List<Map<String, dynamic>>.from(
      (referralSummary['history'] as List? ?? const <dynamic>[]).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );
    final statuses = Map<String, dynamic>.from(
      referralSummary['statuses'] ?? const {},
    );

    final referralCode = referralSummary['referralCode']?.toString() ?? '';
    final referralLink = referralSummary['referralLink']?.toString() ?? '';
    final formulaText = referralSummary['formulaText']?.toString() ?? '';
    final totalEarnings = referralSummary['earnedEarningsFormatted']?.toString() ?? '₹0';

    return AgentWorkspaceSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AgentSectionHeader(
            title: 'Customer Network',
            description:
                'Track customer growth, reward status, child referral tree, and calculated earnings through one shared network workspace.',
          ),
          if (referralLink.isNotEmpty) ...[
            AgentUi.gapH(AgentUi.space16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.shieldBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.shieldBlue.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.link_rounded,
                    color: AppColors.shieldBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Your Agent Referral Link',
                              style: AppTypography.body.copyWith(
                                color: AppColors.shieldNavy,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (referralCode.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.shieldBlue,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  referralCode,
                                  style: AppTypography.tiny.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        SelectableText(
                          referralLink,
                          style: AppTypography.small.copyWith(
                            color: AppColors.darkGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.shieldBlue,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Agent referral link copied to clipboard!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy Link'),
                  ),
                ],
              ),
            ),
          ],
          AgentUi.gapH(AgentUi.space16),
          AgentMetricGrid(
            children: [
              AgentMetricCard(
                value: '${referralSummary['directReferrals'] ?? 0}',
                label: 'Direct Customers',
                helper: 'Customers directly onboarded by this agent.',
                icon: Icons.people_alt_outlined,
              ),
              AgentMetricCard(
                value: '${referralSummary['totalReferrals'] ?? 0}',
                label: 'Total Network',
                helper:
                    'All connected direct & child referral customers.',
                icon: Icons.account_tree_outlined,
              ),
              AgentMetricCard(
                value: '${referralSummary['activeMemberships'] ?? 0}',
                label: 'Active Memberships',
                helper: 'Active membership count in the network.',
                icon: Icons.card_membership_outlined,
              ),
              AgentMetricCard(
                value: totalEarnings,
                label: 'Calculated Earnings',
                helper: 'Total agent network earnings & commission.',
                icon: Icons.account_balance_wallet_outlined,
              ),
            ],
          ),
          if (formulaText.isNotEmpty) ...[
            AgentUi.gapH(AgentUi.space12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calculate_outlined,
                    color: Colors.amber.shade900,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Commission Rate & Earnings Formula',
                          style: AppTypography.tiny.copyWith(
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formulaText,
                          style: AppTypography.tiny.copyWith(
                            color: AppColors.shieldNavy,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    final indent = depth * 22.0;
    final statusStr = (node['status']?.toString() ?? 'ACTIVE').toUpperCase();
    final isActive = statusStr == 'ACTIVE' || node['active'] == true;
    final roleStr = node['role']?.toString() ?? '';
    final isAgent = roleStr == 'AGENT';
    final isChild = roleStr == 'CHILD_REFERRAL';

    final nameText = node['name']?.toString().trim().isNotEmpty == true
        ? node['name'].toString()
        : (isAgent ? 'SHIELD Agent' : 'Customer');

    final codeText = node['code']?.toString() ?? '';
    final parentName = node['parentName']?.toString() ?? '';

    String subtitleText = '';
    if (isAgent) {
      subtitleText = 'Agent Root • Code: $codeText';
    } else {
      final joinedRaw = node['joinedAt'] ?? node['registrationDate'];
      final joinedStr = joinedRaw != null ? _formatDate(joinedRaw) : 'Active';
      subtitleText = '$codeText • Joined $joinedStr';
      if (parentName.isNotEmpty) {
        subtitleText += ' • Referred by $parentName';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(left: indent, bottom: AgentUi.space12),
          padding: AgentUi.cardBodyPadding,
          decoration: BoxDecoration(
            color: isAgent
                ? AppColors.shieldBlue.withValues(alpha: 0.06)
                : Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: AgentUi.radius(AgentUi.radiusMedium),
            border: Border.all(
              color: isAgent
                  ? AppColors.shieldBlue.withValues(alpha: 0.2)
                  : AppColors.divider,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isAgent
                      ? AppColors.shieldBlue
                      : (isChild
                          ? AppColors.shieldBlue.withValues(alpha: 0.12)
                          : Theme.of(context).colorScheme.primaryContainer),
                  borderRadius: AgentUi.radius(AgentUi.radiusMedium),
                ),
                child: Icon(
                  isAgent
                      ? Icons.badge_outlined
                      : (isChild
                          ? Icons.share_outlined
                          : Icons.person_outline),
                  color: isAgent ? AppColors.white : AppColors.shieldBlue,
                  size: 20,
                ),
              ),
              AgentUi.gapW(AgentUi.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          nameText,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        if (isChild) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.shieldBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Child Referral',
                              style: AppTypography.tiny.copyWith(
                                color: AppColors.shieldBlue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    AgentUi.gapH(AgentUi.space4),
                    Text(
                      subtitleText,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              AgentStatusBadge(
                label: isActive ? 'Active' : 'Pending',
                color: AgentUi.statusColor(
                  context,
                  isActive ? 'ACTIVE' : 'PENDING',
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
