import 'package:flutter/material.dart';

import '../../../shared/exports.dart';

class AdminDashboardModule extends StatelessWidget {
  const AdminDashboardModule({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      eyebrow: 'Executive and operational control',
      title: 'SHIELD command center',
      description:
          'One workspace for daily operational pressure, verification backlogs, branch health, provider readiness, and growth signals.',
      primaryAction: const AdminActionItem(
        label: 'Create customer',
        icon: Icons.person_add_alt_1_outlined,
      ),
      secondaryAction: const AdminActionItem(
        label: 'Broadcast update',
        icon: Icons.campaign_outlined,
      ),
      metrics: const [
        AdminMetric(
          label: 'Active customers',
          value: '18,426',
          note: '+312 this week',
          color: AdminColors.secondary,
          icon: Icons.groups_2_outlined,
        ),
        AdminMetric(
          label: 'Pending verification',
          value: '74',
          note: '22 require review today',
          color: AdminColors.warning,
          icon: Icons.verified_user_outlined,
        ),
        AdminMetric(
          label: 'Today visits',
          value: '268',
          note: '17 need rescheduling',
          color: AdminColors.visits,
          icon: Icons.event_available_outlined,
        ),
        AdminMetric(
          label: 'Active agents',
          value: '62',
          note: '7 over SLA on follow-ups',
          color: AdminColors.success,
          icon: Icons.badge_outlined,
        ),
        AdminMetric(
          label: 'Provider alerts',
          value: '13',
          note: 'documents or availability issues',
          color: AdminColors.danger,
          icon: Icons.local_hospital_outlined,
        ),
        AdminMetric(
          label: 'Reward liability',
          value: '2.8L pts',
          note: 'watch redemption pacing',
          color: AdminColors.rewards,
          icon: Icons.stars_outlined,
        ),
      ],
      child: const Column(
        children: [
          _DashboardTopRow(),
          SizedBox(height: 20),
          _DashboardBottomRow(),
        ],
      ),
    );
  }
}

class _DashboardTopRow extends StatelessWidget {
  const _DashboardTopRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: AdminStatCard(
            title: 'Operations panel',
            subtitle: 'What deserves action before more feature expansion.',
            child: Column(
              children: [
                AdminQueueTile(
                  title: 'Document verification queue',
                  subtitle:
                      '41 pending, 9 expiring documents, 6 rejected waiting resubmission',
                  status: 'Needs action',
                  color: AdminColors.warning,
                ),
                AdminQueueTile(
                  title: 'Overdue follow-ups',
                  subtitle:
                      '19 customers are past promised callback windows across 4 branches',
                  status: 'Escalate',
                  color: AdminColors.danger,
                ),
                AdminQueueTile(
                  title: 'Expiring memberships',
                  subtitle:
                      '76 memberships expire in the next 7 days and need renewal nudges',
                  status: 'Review',
                  color: AdminColors.visits,
                ),
                AdminQueueTile(
                  title: 'Wallet integrity watch',
                  subtitle:
                      '3 manual adjustments and 2 pricing audit outliers require supervisor eyes',
                  status: 'Check',
                  color: AdminColors.rewards,
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          flex: 5,
          child: AdminStatCard(
            title: 'Quick actions',
            subtitle:
                'High-leverage command shortcuts for central operations.',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _QuickAction(label: 'New customer', icon: Icons.person_add_alt_1_outlined, color: AdminColors.secondary),
                _QuickAction(label: 'New agent', icon: Icons.badge_outlined, color: AdminColors.success),
                _QuickAction(label: 'New provider', icon: Icons.local_hospital_outlined, color: AdminColors.visits),
                _QuickAction(label: 'Membership plan', icon: Icons.credit_card_outlined, color: AdminColors.warning),
                _QuickAction(label: 'Book visit', icon: Icons.event_available_outlined, color: AdminColors.visits),
                _QuickAction(label: 'Referral campaign', icon: Icons.account_tree_outlined, color: AdminColors.rewards),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardBottomRow extends StatelessWidget {
  const _DashboardBottomRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: AdminStatCard(
            title: 'Live activity feed',
            subtitle: 'Platform events in the order operators experience them.',
            child: AdminActivityFeed(
              items: [
                AdminTimelineItem(
                  time: '09:41',
                  title: 'Customer registered',
                  description:
                      'Anita Joseph was onboarded through Kochi Central and is waiting card issuance.',
                  accent: AdminColors.secondary,
                ),
                AdminTimelineItem(
                  time: '09:46',
                  title: 'Document approved',
                  description:
                      'Aadhaar verification completed for two high-priority customers.',
                  accent: AdminColors.success,
                ),
                AdminTimelineItem(
                  time: '09:49',
                  title: 'Wallet adjusted',
                  description:
                      'Manual commercial credit correction posted with pricing audit note.',
                  accent: AdminColors.rewards,
                ),
                AdminTimelineItem(
                  time: '10:03',
                  title: 'Provider schedule risk',
                  description:
                      'Three dermatology slots were blocked after staffing changes at Calicut North.',
                  accent: AdminColors.danger,
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          flex: 5,
          child: AdminStatCard(
            title: 'Branch comparison',
            subtitle: 'Operational performance snapshot across active locations.',
            child: Column(
              children: [
                AdminHealthRow(
                  item: AdminHealthItem(
                    label: 'Kochi Central',
                    value: '94%',
                    meta: 'verification and follow-up SLA',
                    color: AdminColors.success,
                  ),
                ),
                AdminHealthRow(
                  item: AdminHealthItem(
                    label: 'Trivandrum City',
                    value: '87%',
                    meta: 'document review backlog rising',
                    color: AdminColors.warning,
                  ),
                ),
                AdminHealthRow(
                  item: AdminHealthItem(
                    label: 'Calicut North',
                    value: '82%',
                    meta: 'provider capacity under stress',
                    color: AdminColors.danger,
                  ),
                ),
                AdminHealthRow(
                  item: AdminHealthItem(
                    label: 'Thrissur Hub',
                    value: '91%',
                    meta: 'best referral conversion this month',
                    color: AdminColors.rewards,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AdminTypography.small.copyWith(
                color: AdminColors.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
