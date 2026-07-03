import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_responsive.dart';
import '../../../portal/presentation/portal_role_data.dart';

class AdminPortalWorkspace extends StatelessWidget {
  const AdminPortalWorkspace({
    super.key,
    required this.portal,
    required this.section,
  });

  final PortalRoleData portal;
  final PortalSectionData section;

  @override
  Widget build(BuildContext context) {
    switch (section.key) {
      case 'dashboard':
        return const _AdminDashboardModule();
      case 'customers':
        return const _CustomersModule();
      case 'agents':
        return const _AgentsModule();
      case 'crm':
        return const _CrmModule();
      case 'visits':
        return const _VisitsModule();
      case 'documents':
        return const _DocumentsModule();
      case 'memberships':
        return const _MembershipsModule();
      case 'wallet':
        return const _WalletModule();
      case 'rewards':
        return const _RewardsModule();
      case 'referrals':
        return const _ReferralsModule();
      case 'providers':
        return const _ProvidersModule();
      case 'services':
        return const _ServicesModule();
      case 'availability':
        return const _AvailabilityModule();
      case 'branches':
        return const _BranchesModule();
      case 'employees':
        return const _EmployeesModule();
      case 'roles':
        return const _RolesModule();
      case 'reports':
        return const _ReportsModule();
      case 'insights':
        return const _InsightsModule();
      case 'audit':
        return const _AuditModule();
      case 'notifications':
        return const _NotificationsModule();
      case 'settings':
        return const _SettingsModule();
      case 'platform':
        return const _PlatformModule();
      default:
        return _FallbackModule(section: section);
    }
  }
}

class _AdminDashboardModule extends StatelessWidget {
  const _AdminDashboardModule();

  @override
  Widget build(BuildContext context) {
    return _AdminModuleScaffold(
      eyebrow: 'Executive and operational control',
      title: 'SHIELD command center',
      description:
          'One workspace for daily operational pressure, verification backlogs, branch health, provider readiness, and growth signals.',
      primaryAction: const _AdminAction(label: 'Create customer', icon: Icons.person_add_alt_1_outlined),
      secondaryAction: const _AdminAction(label: 'Broadcast update', icon: Icons.campaign_outlined),
      metrics: const [
        _AdminMetric(
          label: 'Active customers',
          value: '18,426',
          note: '+312 this week',
          color: AppColors.shieldBlue,
          icon: Icons.groups_2_outlined,
        ),
        _AdminMetric(
          label: 'Pending verification',
          value: '74',
          note: '22 require review today',
          color: AppColors.warning,
          icon: Icons.verified_user_outlined,
        ),
        _AdminMetric(
          label: 'Today visits',
          value: '268',
          note: '17 need rescheduling',
          color: Color(0xFF0EA5A8),
          icon: Icons.event_available_outlined,
        ),
        _AdminMetric(
          label: 'Active agents',
          value: '62',
          note: '7 over SLA on follow-ups',
          color: AppColors.success,
          icon: Icons.badge_outlined,
        ),
        _AdminMetric(
          label: 'Provider alerts',
          value: '13',
          note: 'documents or availability issues',
          color: AppColors.error,
          icon: Icons.local_hospital_outlined,
        ),
        _AdminMetric(
          label: 'Reward liability',
          value: '2.8L pts',
          note: 'watch redemption pacing',
          color: Color(0xFF7C3AED),
          icon: Icons.stars_outlined,
        ),
      ],
      child: const Column(
        children: [
          _AdminResponsiveColumns(
            left: _AdminPanel(
              title: 'Operations panel',
              subtitle: 'What deserves action before more feature expansion.',
              child: Column(
                children: [
                  _QueueTile(
                    title: 'Document verification queue',
                    subtitle: '41 pending, 9 expiring documents, 6 rejected waiting resubmission',
                    status: 'Needs action',
                    color: AppColors.warning,
                  ),
                  _QueueTile(
                    title: 'Overdue follow-ups',
                    subtitle: '19 customers are past promised callback windows across 4 branches',
                    status: 'Escalate',
                    color: AppColors.error,
                  ),
                  _QueueTile(
                    title: 'Expiring memberships',
                    subtitle: '76 memberships expire in the next 7 days and need renewal nudges',
                    status: 'Review',
                    color: Color(0xFF0EA5A8),
                  ),
                  _QueueTile(
                    title: 'Wallet integrity watch',
                    subtitle: '3 manual adjustments and 2 pricing audit outliers require supervisor eyes',
                    status: 'Check',
                    color: Color(0xFF7C3AED),
                  ),
                ],
              ),
            ),
            right: _AdminPanel(
              title: 'Quick actions',
              subtitle: 'High-leverage command shortcuts for central operations.',
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _QuickActionCard(icon: Icons.person_add_alt_1_outlined, label: 'New customer', color: AppColors.shieldBlue),
                  _QuickActionCard(icon: Icons.badge_outlined, label: 'New agent', color: AppColors.success),
                  _QuickActionCard(icon: Icons.local_hospital_outlined, label: 'New provider', color: Color(0xFF0EA5A8)),
                  _QuickActionCard(icon: Icons.credit_card_outlined, label: 'Membership plan', color: AppColors.warning),
                  _QuickActionCard(icon: Icons.event_available_outlined, label: 'Book visit', color: Color(0xFF0EA5A8)),
                  _QuickActionCard(icon: Icons.account_tree_outlined, label: 'Referral campaign', color: Color(0xFF7C3AED)),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          _AdminResponsiveColumns(
            left: _AdminPanel(
              title: 'Live activity feed',
              subtitle: 'Platform events in the order operators experience them.',
              child: Column(
                children: [
                  _TimelineEvent(
                    time: '09:41',
                    title: 'Customer registered',
                    description: 'Anita Joseph was onboarded through Kochi Central and is waiting card issuance.',
                    accent: AppColors.shieldBlue,
                  ),
                  _TimelineEvent(
                    time: '09:46',
                    title: 'Document approved',
                    description: 'Aadhaar verification completed for two high-priority customers.',
                    accent: AppColors.success,
                  ),
                  _TimelineEvent(
                    time: '09:49',
                    title: 'Wallet adjusted',
                    description: 'Manual commercial credit correction posted with pricing audit note.',
                    accent: Color(0xFF7C3AED),
                  ),
                  _TimelineEvent(
                    time: '10:03',
                    title: 'Provider schedule risk',
                    description: 'Three dermatology slots were blocked after staffing changes at Calicut North.',
                    accent: AppColors.error,
                  ),
                ],
              ),
            ),
            right: _AdminPanel(
              title: 'Branch comparison',
              subtitle: 'Operational performance snapshot across active locations.',
              child: Column(
                children: [
                  _HealthRow(label: 'Kochi Central', value: '94%', meta: 'verification and follow-up SLA', color: AppColors.success),
                  _HealthRow(label: 'Trivandrum City', value: '87%', meta: 'document review backlog rising', color: AppColors.warning),
                  _HealthRow(label: 'Calicut North', value: '82%', meta: 'provider capacity under stress', color: AppColors.error),
                  _HealthRow(label: 'Thrissur Hub', value: '91%', meta: 'best referral conversion this month', color: Color(0xFF7C3AED)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomersModule extends StatelessWidget {
  const _CustomersModule();

  @override
  Widget build(BuildContext context) {
    return _AdminModuleScaffold(
      eyebrow: 'Operations / Customers',
      title: 'Customer control workspace',
      description:
          'A master-detail CRM for customer identity, timeline, wallet, membership, visits, documents, referrals, and audit visibility.',
      primaryAction: const _AdminAction(label: 'Create customer', icon: Icons.person_add_alt_1_outlined),
      secondaryAction: const _AdminAction(label: 'Advanced filters', icon: Icons.tune_outlined),
      child: _WorkspaceShell(
        tabs: const [
          'Overview',
          'Timeline',
          'Tasks',
          'Documents',
          'Visits',
          'Wallet',
          'Membership',
          'Medical',
          'Referrals',
          'Notes',
          'Activity Log',
        ],
        left: _AdminPanel(
          title: 'Customer list',
          subtitle: 'Global search, branch filters, lifecycle status, and priority queues.',
          child: const Column(
            children: [
              _EntityListTile(
                title: 'Arun Thomas',
                subtitle: 'ID SH-10284 • Gold member • Kochi Central',
                meta: 'Pending visit today',
                status: 'Priority',
                color: AppColors.warning,
              ),
              _EntityListTile(
                title: 'Lakshmi Nair',
                subtitle: 'ID SH-09921 • Verification complete • Thrissur Hub',
                meta: 'Wallet recharge yesterday',
                status: 'Healthy',
                color: AppColors.success,
              ),
              _EntityListTile(
                title: 'Fathima Rahman',
                subtitle: 'ID SH-10602 • Documents pending • Calicut North',
                meta: 'Follow-up overdue',
                status: 'Escalate',
                color: AppColors.error,
              ),
            ],
          ),
        ),
        center: _AdminPanel(
          title: 'Customer workspace',
          subtitle: 'Profile, membership, wallet, provider, branch, and next-step visibility.',
          child: Column(
            children: const [
              _IdentityHero(
                name: 'Arun Thomas',
                code: 'SH-10284',
                primaryMeta: 'Member since 2025-11-12',
                secondaryMeta: 'Kochi Central • +91 98XXXXXX12 • Assigned to Rahul Das',
                badges: ['Gold member', 'Wallet active', 'Visit today'],
              ),
              SizedBox(height: 16),
              _KpiStrip(
                items: [
                  _KpiItem(label: 'Wallet', value: 'Rs. 4,820', note: 'cash + rewards'),
                  _KpiItem(label: 'Next visit', value: '10:30 AM', note: 'Dermatology'),
                  _KpiItem(label: 'Documents', value: '6 / 7', note: 'one pending'),
                  _KpiItem(label: 'Referrals', value: '14', note: '4 rewarded'),
                ],
              ),
              SizedBox(height: 16),
              _DetailRows(rows: [
                _DetailRow(label: 'Membership', value: 'SHIELD Gold Annual'),
                _DetailRow(label: 'Branch', value: 'Kochi Central'),
                _DetailRow(label: 'Primary provider', value: 'Dr. Asha Menon'),
                _DetailRow(label: 'Last wallet adjustment', value: '2026-07-02 18:22'),
                _DetailRow(label: 'Current risk', value: 'Pending follow-up on lab review'),
              ]),
            ],
          ),
        ),
        right: _AdminPanel(
          title: 'Customer timeline',
          subtitle: 'The customer story should be the hero, not a buried tab.',
          child: const Column(
            children: [
              _TimelineEvent(
                time: 'Today',
                title: 'Visit scheduled',
                description: '10:30 AM dermatology consult with branch-level slot lock.',
                accent: Color(0xFF0EA5A8),
              ),
              _TimelineEvent(
                time: 'Yesterday',
                title: 'Aadhaar uploaded',
                description: 'Verification metadata attached and queued for review.',
                accent: AppColors.warning,
              ),
              _TimelineEvent(
                time: 'Yesterday',
                title: 'Follow-up completed',
                description: 'Call outcome captured with prescription note.',
                accent: AppColors.success,
              ),
              _TimelineEvent(
                time: 'Jun 29',
                title: 'Registered',
                description: 'Agent-led onboarding at Kochi Central.',
                accent: AppColors.shieldBlue,
              ),
              _TimelineEvent(
                time: 'Jun 28',
                title: 'Wallet credited',
                description: 'Promotional recharge posted with pricing audit entry.',
                accent: Color(0xFF7C3AED),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgentsModule extends StatelessWidget {
  const _AgentsModule();

  @override
  Widget build(BuildContext context) {
    return _AdminModuleScaffold(
      eyebrow: 'Operations / Agents',
      title: 'Agent performance and assignment center',
      description:
          'Manage branch assignment, territory health, customers, follow-ups, visits, and field productivity without leaving one workspace.',
      primaryAction: const _AdminAction(label: 'Add agent', icon: Icons.badge_outlined),
      secondaryAction: const _AdminAction(label: 'Assign branch', icon: Icons.place_outlined),
      child: _WorkspaceShell(
        tabs: const ['Overview', 'Customers', 'Performance', 'Follow-Ups', 'Visits', 'Attendance', 'Documents', 'Timeline'],
        left: _AdminPanel(
          title: 'Agent list',
          subtitle: 'Sort by region, performance, SLA risk, and active network.',
          child: const Column(
            children: [
              _EntityListTile(title: 'Rahul Das', subtitle: 'Kochi Central • 428 customers', meta: 'Top conversion this month', status: 'High performer', color: AppColors.success),
              _EntityListTile(title: 'Meera S', subtitle: 'Calicut North • 311 customers', meta: '7 overdue follow-ups', status: 'Needs support', color: AppColors.warning),
              _EntityListTile(title: 'Nithin Paul', subtitle: 'Trivandrum City • 288 customers', meta: 'visit completion down this week', status: 'Watch', color: AppColors.error),
            ],
          ),
        ),
        center: _AdminPanel(
          title: 'Agent workspace',
          subtitle: 'Identity, branch, territory, and KPI context in one place.',
          child: Column(
            children: const [
              _IdentityHero(
                name: 'Rahul Das',
                code: 'AG-0012',
                primaryMeta: 'Primary branch Kochi Central',
                secondaryMeta: 'South urban territory • Google-auth internal profile',
                badges: ['Active', 'Primary assignee', 'Field leader'],
              ),
              SizedBox(height: 16),
              _KpiStrip(
                items: [
                  _KpiItem(label: 'Customers', value: '428', note: 'active network'),
                  _KpiItem(label: 'Follow-ups', value: '96%', note: 'completed on time'),
                  _KpiItem(label: 'Visits', value: '124', note: 'this month'),
                  _KpiItem(label: 'Retention', value: '91%', note: 'rolling 30 days'),
                ],
              ),
              SizedBox(height: 16),
              _DetailRows(rows: [
                _DetailRow(label: 'Branch mapping', value: 'Kochi Central, backup Ernakulam South'),
                _DetailRow(label: 'Working mode', value: 'Field-heavy, morning-first onboarding'),
                _DetailRow(label: 'Current escalation', value: '7 pending callbacks over SLA'),
                _DetailRow(label: 'Last attendance sync', value: '2026-07-03 08:31'),
              ]),
            ],
          ),
        ),
        right: _AdminPanel(
          title: 'Timeline and alerts',
          subtitle: 'Who changed what, where agent performance is moving, and which customers are at risk.',
          child: const Column(
            children: [
              _TimelineEvent(time: '09:20', title: 'New customer approved', description: 'Two onboarding profiles cleared after admin review.', accent: AppColors.success),
              _TimelineEvent(time: 'Yesterday', title: 'Visit created', description: 'Scheduled 6 care visits across dermatology and lab.', accent: Color(0xFF0EA5A8)),
              _TimelineEvent(time: 'Yesterday', title: 'Document backlog flagged', description: '3 uploaded KYC packets still missing verification.', accent: AppColors.warning),
              _TimelineEvent(time: 'Jun 30', title: 'Branch transfer requested', description: 'Temporary support request for Ernakulam South workload.', accent: AppColors.shieldBlue),
            ],
          ),
        ),
      ),
    );
  }
}

class _CrmModule extends StatelessWidget {
  const _CrmModule();

  @override
  Widget build(BuildContext context) {
    return _AdminModuleScaffold(
      eyebrow: 'Operations / CRM',
      title: 'CRM workload and escalation board',
      description:
          'Monitor call queues, pending work, escalations, and retention pressure across the CRM organization.',
      primaryAction: const _AdminAction(label: 'Open escalations', icon: Icons.support_agent_outlined),
      secondaryAction: const _AdminAction(label: 'Assign campaign', icon: Icons.campaign_outlined),
      child: _AdminResponsiveColumns(
        left: _AdminPanel(
          title: 'Today work',
          subtitle: 'Queue ownership across inbound and outbound retention activity.',
          child: const Column(
            children: [
              _QueueTile(title: 'Renewal reminders', subtitle: '48 customers due in 3 days across Kochi and Thrissur', status: 'In progress', color: AppColors.shieldBlue),
              _QueueTile(title: 'Missed-visit callbacks', subtitle: '17 customers need rebooking follow-up today', status: 'Urgent', color: AppColors.warning),
              _QueueTile(title: 'Complaint escalations', subtitle: '6 unresolved cases now beyond 24-hour expectation', status: 'Critical', color: AppColors.error),
            ],
          ),
        ),
        right: _AdminPanel(
          title: 'CRM performance',
          subtitle: 'Operators, resolution pace, and handoff quality.',
          child: const Column(
            children: [
              _HealthRow(label: 'Calls completed', value: '182', meta: 'today across all CRM executives', color: AppColors.success),
              _HealthRow(label: 'Average resolution time', value: '11m', meta: 'down 14% week over week', color: AppColors.shieldBlue),
              _HealthRow(label: 'Escalation rate', value: '6.2%', meta: 'slightly above target', color: AppColors.warning),
              _HealthRow(label: 'Missed callbacks', value: '9', meta: '2 require manager review', color: AppColors.error),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisitsModule extends StatelessWidget {
  const _VisitsModule();

  @override
  Widget build(BuildContext context) {
    return _AdminModuleScaffold(
      eyebrow: 'Operations / Visits',
      title: 'Visit operations calendar',
      description:
          'A master view of daily, weekly, and monthly visit execution across customers, agents, branches, and providers.',
      primaryAction: const _AdminAction(label: 'Create visit', icon: Icons.event_available_outlined),
      secondaryAction: const _AdminAction(label: 'Reschedule batch', icon: Icons.swap_horiz_outlined),
      child: const Column(
        children: [
          _SectionTabs(tabs: ['Today', 'Week', 'Month', 'Agenda', 'Provider Schedule']),
          SizedBox(height: 16),
          _AdminResponsiveColumns(
            left: _AdminPanel(
              title: 'Today agenda',
              subtitle: 'Visit sequence with provider, branch, and customer context.',
              child: Column(
                children: [
                  _TimelineEvent(time: '10:30', title: 'Arun Thomas • Dermatology', description: 'Kochi Central • Dr. Asha Menon • booked by Rahul Das', accent: Color(0xFF0EA5A8)),
                  _TimelineEvent(time: '11:15', title: 'Lakshmi Nair • Lab panel', description: 'Thrissur Hub • fasting reminder already sent', accent: AppColors.success),
                  _TimelineEvent(time: '12:00', title: 'Homecare visit at risk', description: 'Provider running late and customer requires re-confirmation', accent: AppColors.warning),
                  _TimelineEvent(time: '02:45', title: 'Dental consult', description: 'Calicut North • records incomplete before visit', accent: AppColors.error),
                ],
              ),
            ),
            right: _AdminPanel(
              title: 'Capacity and filters',
              subtitle: 'Provider load, branch congestion, and at-risk slots.',
              child: Column(
                children: [
                  _HealthRow(label: 'Kochi Central', value: '82%', meta: 'provider utilization', color: AppColors.success),
                  _HealthRow(label: 'Calicut North', value: '97%', meta: 'slot congestion', color: AppColors.error),
                  _HealthRow(label: 'Thrissur Hub', value: '76%', meta: 'healthy spread', color: Color(0xFF0EA5A8)),
                  _HealthRow(label: 'Trivandrum City', value: '88%', meta: 'watch noon surge', color: AppColors.warning),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentsModule extends StatelessWidget {
  const _DocumentsModule();

  @override
  Widget build(BuildContext context) {
    return _AdminModuleScaffold(
      eyebrow: 'Operations / Documents',
      title: 'Document verification command center',
      description:
          'One queue for pending, approved, rejected, expired, and resubmission-required documents with preview, decision, and audit trace.',
      primaryAction: const _AdminAction(label: 'Approve selected', icon: Icons.verified_outlined),
      secondaryAction: const _AdminAction(label: 'Request resubmission', icon: Icons.restart_alt_outlined),
      child: _WorkspaceShell(
        tabs: const ['Pending', 'Approved', 'Rejected', 'Expired', 'Resubmission'],
        left: _AdminPanel(
          title: 'Verification queue',
          subtitle: 'Prioritized by ageing, customer risk, and operational dependency.',
          child: const Column(
            children: [
              _EntityListTile(title: 'Aadhaar • Arun Thomas', subtitle: 'Uploaded today • Kochi Central', meta: 'Needed before afternoon visit', status: 'Priority', color: AppColors.warning),
              _EntityListTile(title: 'Lab report • Lakshmi Nair', subtitle: 'Awaiting metadata validation', meta: 'OCR and record-link check', status: 'Review', color: AppColors.shieldBlue),
              _EntityListTile(title: 'Membership proof • Fathima Rahman', subtitle: 'Previous rejection appealed', meta: 'Resubmitted 20 min ago', status: 'Escalate', color: AppColors.error),
            ],
          ),
        ),
        center: _AdminPanel(
          title: 'Preview and metadata',
          subtitle: 'File preview, extraction context, source branch, and linked customer record.',
          child: Column(
            children: const [
              _PreviewSurface(
                title: 'Aadhaar document preview',
                subtitle: 'Front + back image set • 2 pages • source upload via agent registration',
              ),
              SizedBox(height: 16),
              _DetailRows(rows: [
                _DetailRow(label: 'Customer', value: 'Arun Thomas • SH-10284'),
                _DetailRow(label: 'Source', value: 'Agent registration workflow'),
                _DetailRow(label: 'Branch', value: 'Kochi Central'),
                _DetailRow(label: 'Risk', value: 'Visit blocked until verified'),
              ]),
            ],
          ),
        ),
        right: _AdminPanel(
          title: 'Approval panel',
          subtitle: 'Decision, comments, and audit trail.',
          child: const Column(
            children: [
              _DecisionCard(label: 'Approve and unlock next workflow', icon: Icons.check_circle_outline, color: AppColors.success),
              SizedBox(height: 12),
              _DecisionCard(label: 'Reject with explicit reason', icon: Icons.cancel_outlined, color: AppColors.error),
              SizedBox(height: 12),
              _DecisionCard(label: 'Request upload again', icon: Icons.file_upload_outlined, color: AppColors.warning),
              SizedBox(height: 16),
              _TimelineEvent(time: '09:12', title: 'Uploaded by Rahul Das', description: 'Submitted with registration review context.', accent: AppColors.shieldBlue),
              _TimelineEvent(time: '09:16', title: 'OCR metadata attached', description: 'Name and ID fields extracted for comparison.', accent: Color(0xFF7C3AED)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MembershipsModule extends StatelessWidget {
  const _MembershipsModule();

  @override
  Widget build(BuildContext context) {
    return _AdminModuleScaffold(
      eyebrow: 'Business / Memberships',
      title: 'Membership plans and lifecycle controls',
      description:
          'Manage plan definitions, benefits, pricing posture, renewal pipelines, usage signals, and expiry pressure from one surface.',
      primaryAction: const _AdminAction(label: 'Create plan', icon: Icons.card_membership_outlined),
      secondaryAction: const _AdminAction(label: 'Review renewals', icon: Icons.autorenew_outlined),
      child: _AdminResponsiveColumns(
        left: _AdminPanel(
          title: 'Plan library',
          subtitle: 'Reusable membership products and commercial posture.',
          child: const Column(
            children: [
              _EntityListTile(title: 'SHIELD Gold Annual', subtitle: 'Joining fee Rs. 2,999 • credit eligible', meta: 'Most active plan', status: 'Primary', color: AppColors.shieldBlue),
              _EntityListTile(title: 'SHIELD Family Plus', subtitle: 'Benefit-heavy family bundle', meta: 'Needs pricing review', status: 'Review', color: AppColors.warning),
              _EntityListTile(title: 'SHIELD Senior Care', subtitle: 'High retention, high support intensity', meta: 'Expiry spike next month', status: 'Watch', color: AppColors.error),
            ],
          ),
        ),
        right: _AdminPanel(
          title: 'Renewal and usage signals',
          subtitle: 'Plans only matter when lifecycle pressure is visible.',
          child: const Column(
            children: [
              _HealthRow(label: 'Expiring in 7 days', value: '76', meta: 'renewal pipeline open', color: AppColors.warning),
              _HealthRow(label: 'Renewed this month', value: '418', meta: '83% completion rate', color: AppColors.success),
              _HealthRow(label: 'Dormant high-value members', value: '29', meta: 'target retention campaign', color: Color(0xFF7C3AED)),
              _HealthRow(label: 'Card issuance blocked', value: '11', meta: 'document or approval dependency', color: AppColors.error),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletModule extends StatelessWidget {
  const _WalletModule();

  @override
  Widget build(BuildContext context) {
    return _AdminModuleScaffold(
      eyebrow: 'Business / Wallet',
      title: 'Wallet and ledger operations',
      description:
          'A Stripe-like operational surface for transactions, recharges, adjustments, rewards, and audit-safe ledger visibility.',
      primaryAction: const _AdminAction(label: 'Post adjustment', icon: Icons.account_balance_wallet_outlined),
      secondaryAction: const _AdminAction(label: 'Review audits', icon: Icons.receipt_long_outlined),
      child: _AdminResponsiveColumns(
        left: _AdminPanel(
          title: 'Ledger overview',
          subtitle: 'Wallet health across cash, rewards, and hidden commercial benefit behavior.',
          child: const Column(
            children: [
              _HealthRow(label: 'Cash ledger volume', value: 'Rs. 12.8L', meta: 'rolling 7 days', color: AppColors.shieldBlue),
              _HealthRow(label: 'Reward points issued', value: '84.3k', meta: 'qualified and approved', color: Color(0xFF7C3AED)),
              _HealthRow(label: 'Manual adjustments', value: '13', meta: 'today', color: AppColors.warning),
              _HealthRow(label: 'Pricing audit outliers', value: '2', meta: 'need review', color: AppColors.error),
            ],
          ),
        ),
        right: _AdminPanel(
          title: 'Recent transaction rail',
          subtitle: 'Operational events worth reviewing before finance drift grows.',
          child: const Column(
            children: [
              _TimelineEvent(time: '09:49', title: 'Manual recharge approved', description: 'Rs. 1,000 posted to SH-10284 after central review.', accent: AppColors.success),
              _TimelineEvent(time: '09:52', title: 'Reward redemption applied', description: '2,500 points converted under current redemption rule.', accent: Color(0xFF7C3AED)),
              _TimelineEvent(time: '10:04', title: 'Adjustment flagged', description: 'Mismatch between expected discount and final payable.', accent: AppColors.error),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardsModule extends StatelessWidget {
  const _RewardsModule();

  @override
  Widget build(BuildContext context) {
    return _AdminModuleScaffold(
      eyebrow: 'Business / Rewards',
      title: 'Reward rule and redemption engine',
      description:
          'Control earning rules, redemption rules, active campaigns, and points economics without leaking implementation complexity into other modules.',
      primaryAction: const _AdminAction(label: 'New reward rule', icon: Icons.stars_outlined),
      secondaryAction: const _AdminAction(label: 'Redemption settings', icon: Icons.tune_outlined),
      child: _AdminResponsiveColumns(
        left: _AdminPanel(
          title: 'Rule library',
          subtitle: 'Backend-owned pricing and reward controls surfaced for operators.',
          child: const Column(
            children: [
              _EntityListTile(title: 'Referral qualification reward', subtitle: 'Action-code driven earning rule', meta: 'approval required false', status: 'Active', color: AppColors.success),
              _EntityListTile(title: 'Service visit rewards', subtitle: 'Eligible on defined service types only', meta: 'watch benefit overlap', status: 'Active', color: AppColors.shieldBlue),
              _EntityListTile(title: 'Festival campaign', subtitle: 'Temporary multiplier on selected branches', meta: 'expires in 9 days', status: 'Timed', color: AppColors.warning),
            ],
          ),
        ),
        right: _AdminPanel(
          title: 'Points performance',
          subtitle: 'Economics, liability, and campaign health.',
          child: const Column(
            children: [
              _HealthRow(label: 'Earned this month', value: '184k pts', meta: 'up 12%', color: AppColors.success),
              _HealthRow(label: 'Redeemed this month', value: '63k pts', meta: 'healthy pacing', color: Color(0xFF7C3AED)),
              _HealthRow(label: 'Rule conflicts', value: '1', meta: 'commercial review pending', color: AppColors.warning),
              _HealthRow(label: 'Expired points', value: '8.2k', meta: 'monitor fairness messaging', color: AppColors.error),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReferralsModule extends StatelessWidget {
  const _ReferralsModule();

  @override
  Widget build(BuildContext context) {
    return _AdminModuleScaffold(
      eyebrow: 'Business / Referral network',
      title: 'Referral graph and conversion intelligence',
      description:
          'Track top referrers, pending rewards, qualification progression, campaign performance, and network growth in one growth workspace.',
      primaryAction: const _AdminAction(label: 'Launch campaign', icon: Icons.campaign_outlined),
      secondaryAction: const _AdminAction(label: 'Review rewards', icon: Icons.account_tree_outlined),
      child: _AdminResponsiveColumns(
        left: _AdminPanel(
          title: 'Referral tree',
          subtitle: 'A structured network view instead of a flat list.',
          child: const Column(
            children: [
              _TreeNode(label: 'Arun Thomas', depth: 0, note: '14 referrals • 4 rewarded'),
              _TreeNode(label: 'Nisha B', depth: 1, note: 'Qualified'),
              _TreeNode(label: 'Vipin K', depth: 1, note: 'Pending first visit'),
              _TreeNode(label: 'Sneha R', depth: 2, note: 'Rewarded'),
              _TreeNode(label: 'Jabir P', depth: 1, note: 'Rejected'),
            ],
          ),
        ),
        right: _AdminPanel(
          title: 'Growth and reward signals',
          subtitle: 'Where referral growth is compounding and where it is leaking.',
          child: const Column(
            children: [
              _HealthRow(label: 'Qualified this week', value: '62', meta: 'best from Kochi Central', color: AppColors.success),
              _HealthRow(label: 'Pending qualification', value: '118', meta: 'watch visit completion dependency', color: AppColors.warning),
              _HealthRow(label: 'Top referrer conversion', value: '34%', meta: 'Arun Thomas cluster', color: Color(0xFF7C3AED)),
              _HealthRow(label: 'Rejected chains', value: '9', meta: 'data quality or fraud review', color: AppColors.error),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProvidersModule extends StatelessWidget {
  const _ProvidersModule();

  @override
  Widget build(BuildContext context) {
    return _AdminModuleScaffold(
      eyebrow: 'Providers / Providers',
      title: 'Provider network workspace',
      description:
          'A complete provider CRM for profile, services, availability, bookings, reviews, documents, and timeline history.',
      primaryAction: const _AdminAction(label: 'Add provider', icon: Icons.local_hospital_outlined),
      secondaryAction: const _AdminAction(label: 'Map branch', icon: Icons.place_outlined),
      child: _WorkspaceShell(
        tabs: const ['Profile', 'Availability', 'Services', 'Bookings', 'Reviews', 'Documents', 'Timeline', 'Payments'],
        left: _AdminPanel(
          title: 'Provider list',
          subtitle: 'Find providers by type, branch mapping, and capacity risk.',
          child: const Column(
            children: [
              _EntityListTile(title: 'Dr. Asha Menon', subtitle: 'Dermatology • Kochi Central', meta: '92% slot utilization', status: 'Healthy', color: AppColors.success),
              _EntityListTile(title: 'Lifeline Diagnostics', subtitle: 'Lab partner • Thrissur Hub', meta: 'document renewal due', status: 'Review', color: AppColors.warning),
              _EntityListTile(title: 'SmileCraft Dental', subtitle: 'Dental • Calicut North', meta: 'booking delays rising', status: 'Watch', color: AppColors.error),
            ],
          ),
        ),
        center: _AdminPanel(
          title: 'Provider workspace',
          subtitle: 'Profile, branch mapping, services, and booking pressure.',
          child: Column(
            children: const [
              _IdentityHero(
                name: 'Dr. Asha Menon',
                code: 'PR-041',
                primaryMeta: 'Dermatology specialist',
                secondaryMeta: 'Kochi Central • Google-auth internal user • 3 active branch mappings',
                badges: ['Active', 'High demand', 'Documents valid'],
              ),
              SizedBox(height: 16),
              _KpiStrip(
                items: [
                  _KpiItem(label: 'Bookings', value: '148', note: 'this month'),
                  _KpiItem(label: 'Utilization', value: '92%', note: 'slot fill rate'),
                  _KpiItem(label: 'Rating', value: '4.8', note: 'customer review avg'),
                  _KpiItem(label: 'Pending docs', value: '1', note: 'renewal required'),
                ],
              ),
            ],
          ),
        ),
        right: _AdminPanel(
          title: 'Timeline and health',
          subtitle: 'Provider changes, compliance, and booking quality.',
          child: const Column(
            children: [
              _TimelineEvent(time: 'Today', title: 'Availability updated', description: 'Friday afternoon slots blocked for training.', accent: Color(0xFF0EA5A8)),
              _TimelineEvent(time: 'Yesterday', title: 'Review surge', description: '12 positive care reviews after camp workflow.', accent: AppColors.success),
              _TimelineEvent(time: 'Jun 30', title: 'Document renewal requested', description: 'Registration file expires in 6 days.', accent: AppColors.warning),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServicesModule extends StatelessWidget {
  const _ServicesModule();

  @override
  Widget build(BuildContext context) {
    return _AdminModuleScaffold(
      eyebrow: 'Providers / Services',
      title: 'Service catalog and commercial alignment',
      description:
          'A central catalog for service visibility, provider mapping, benefit eligibility, and pricing-rule awareness.',
      primaryAction: const _AdminAction(label: 'Add service', icon: Icons.medical_services_outlined),
      secondaryAction: const _AdminAction(label: 'Review benefit rules', icon: Icons.rule_outlined),
      child: _AdminResponsiveColumns(
        left: _AdminPanel(
          title: 'Service catalog',
          subtitle: 'Not just labels: provider, benefit, and commercial ownership in one place.',
          child: const Column(
            children: [
              _EntityListTile(title: 'Dermatology consultation', subtitle: 'Benefit eligible • provider-mapped', meta: 'reward earning active', status: 'Live', color: AppColors.success),
              _EntityListTile(title: 'Full body lab panel', subtitle: 'Limited branches • high conversion', meta: 'watch pricing caps', status: 'Watch', color: AppColors.warning),
              _EntityListTile(title: 'Dental follow-up package', subtitle: 'specialized service bundle', meta: 'benefit conflict review', status: 'Review', color: AppColors.error),
            ],
          ),
        ),
        right: _AdminPanel(
          title: 'Rule and provider alignment',
          subtitle: 'Service definitions should stay coupled to backend-owned commercial truth.',
          child: const Column(
            children: [
              _HealthRow(label: 'Mapped providers', value: '46', meta: 'live service coverage', color: AppColors.shieldBlue),
              _HealthRow(label: 'Benefit-enabled services', value: '18', meta: 'pricing-owned config', color: AppColors.success),
              _HealthRow(label: 'Rule gaps', value: '3', meta: 'service types without clean commercial mapping', color: AppColors.warning),
              _HealthRow(label: 'High-risk overlap', value: '1', meta: 'reward plus benefit conflict', color: AppColors.error),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvailabilityModule extends StatelessWidget {
  const _AvailabilityModule();

  @override
  Widget build(BuildContext context) {
    return _AdminModuleScaffold(
      eyebrow: 'Providers / Availability',
      title: 'Availability and capacity board',
      description:
          'Monitor provider schedules, slot health, branch capacity, and care bottlenecks before visit quality degrades.',
      primaryAction: const _AdminAction(label: 'Block slots', icon: Icons.schedule_outlined),
      secondaryAction: const _AdminAction(label: 'Open capacity alerts', icon: Icons.warning_amber_outlined),
      child: _AdminResponsiveColumns(
        left: _AdminPanel(
          title: 'Provider schedule health',
          subtitle: 'This is where availability becomes an operational system, not a profile field.',
          child: const Column(
            children: [
              _HealthRow(label: 'Dermatology', value: '94%', meta: 'Kochi Central near capacity', color: AppColors.warning),
              _HealthRow(label: 'Diagnostics', value: '71%', meta: 'healthy spread', color: AppColors.success),
              _HealthRow(label: 'Homecare', value: '88%', meta: 'travel windows tight', color: Color(0xFF0EA5A8)),
              _HealthRow(label: 'Dental', value: '98%', meta: 'Calicut North overloaded', color: AppColors.error),
            ],
          ),
        ),
        right: _AdminPanel(
          title: 'Escalation queue',
          subtitle: 'Capacity incidents that will affect bookings or customer satisfaction.',
          child: const Column(
            children: [
              _QueueTile(title: 'Calicut North dental overload', subtitle: '4 bookings at risk over the next 48 hours', status: 'Critical', color: AppColors.error),
              _QueueTile(title: 'Homecare travel conflict', subtitle: 'routing gap between two branches', status: 'Needs review', color: AppColors.warning),
              _QueueTile(title: 'Dermatology peak usage', subtitle: 'consider opening overflow slots for Friday', status: 'Plan', color: Color(0xFF0EA5A8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BranchesModule extends StatelessWidget {
  const _BranchesModule();

  @override
  Widget build(BuildContext context) {
    return _AdminModuleScaffold(
      eyebrow: 'Organization / Branches',
      title: 'Branch performance workspace',
      description:
          'Compare operational throughput, customer growth, provider health, visit density, and staff load branch by branch.',
      primaryAction: const _AdminAction(label: 'Add branch', icon: Icons.apartment_outlined),
      secondaryAction: const _AdminAction(label: 'Compare branches', icon: Icons.compare_arrows_outlined),
      child: _WorkspaceShell(
        tabs: const ['Overview', 'Performance', 'Employees', 'Providers', 'Customers', 'Reports'],
        left: _AdminPanel(
          title: 'Branch list',
          subtitle: 'Health and load across the active network.',
          child: const Column(
            children: [
              _EntityListTile(title: 'Kochi Central', subtitle: 'largest active customer base', meta: 'verification and follow-up health strong', status: 'Strong', color: AppColors.success),
              _EntityListTile(title: 'Calicut North', subtitle: 'capacity and documents under stress', meta: 'provider-side attention needed', status: 'Watch', color: AppColors.error),
              _EntityListTile(title: 'Thrissur Hub', subtitle: 'best referral conversion this month', meta: 'stable ops', status: 'Healthy', color: Color(0xFF7C3AED)),
            ],
          ),
        ),
        center: _AdminPanel(
          title: 'Branch workspace',
          subtitle: 'Staff, providers, customers, and performance without switching modules.',
          child: const Column(
            children: [
              _IdentityHero(
                name: 'Kochi Central',
                code: 'BR-001',
                primaryMeta: 'Primary urban branch',
                secondaryMeta: '4820 active customers • 18 providers • 12 internal users',
                badges: ['High growth', 'Healthy verification', 'Top revenue'],
              ),
              SizedBox(height: 16),
              _KpiStrip(
                items: [
                  _KpiItem(label: 'Customers', value: '4,820', note: 'active'),
                  _KpiItem(label: 'Visits', value: '76', note: 'today'),
                  _KpiItem(label: 'Providers', value: '18', note: 'active'),
                  _KpiItem(label: 'Follow-up SLA', value: '94%', note: 'healthy'),
                ],
              ),
            ],
          ),
        ),
        right: _AdminPanel(
          title: 'Operational signals',
          subtitle: 'The branch-level activity and risk story.',
          child: const Column(
            children: [
              _TimelineEvent(time: 'Today', title: 'Membership renewal campaign launched', description: '76 expiring members targeted.', accent: AppColors.shieldBlue),
              _TimelineEvent(time: 'Yesterday', title: 'Provider document verified', description: 'Lab partner compliance restored.', accent: AppColors.success),
              _TimelineEvent(time: 'Jun 30', title: 'Follow-up backlog cleared', description: 'SLA recovered after two-day surge.', accent: AppColors.warning),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmployeesModule extends StatelessWidget {
  const _EmployeesModule();

  @override
  Widget build(BuildContext context) {
    return _AdminModuleScaffold(
      eyebrow: 'Organization / Employees',
      title: 'Employee identity, sessions, and device visibility',
      description:
          'Control internal users, session health, device trust, and operational access without losing RBAC context.',
      primaryAction: const _AdminAction(label: 'Create user', icon: Icons.person_add_alt_outlined),
      secondaryAction: const _AdminAction(label: 'View sessions', icon: Icons.devices_outlined),
      child: _AdminResponsiveColumns(
        left: _AdminPanel(
          title: 'Internal users',
          subtitle: 'Roles, branch scopes, auth provider state, and access posture.',
          child: const Column(
            children: [
              _EntityListTile(title: 'Rahul Das', subtitle: 'SHIELD Agent • Kochi Central', meta: 'Google-auth active session', status: 'Active', color: AppColors.success),
              _EntityListTile(title: 'Anu Jacob', subtitle: 'CRM Executive • Trivandrum City', meta: '2 trusted devices', status: 'Active', color: AppColors.shieldBlue),
              _EntityListTile(title: 'Vivek Menon', subtitle: 'Admin • Global scope', meta: 'passwordless Google auth only', status: 'Privileged', color: AppColors.warning),
            ],
          ),
        ),
        right: _AdminPanel(
          title: 'Session and device health',
          subtitle: 'Access-state visibility that matches the auth subsystem.',
          child: const Column(
            children: [
              _HealthRow(label: 'Current sessions', value: '138', meta: 'active internal sessions', color: AppColors.success),
              _HealthRow(label: 'Trusted devices', value: '214', meta: 'auth_device records', color: AppColors.shieldBlue),
              _HealthRow(label: 'Revoked sessions today', value: '4', meta: 'manual or security-driven', color: AppColors.warning),
              _HealthRow(label: 'Suspicious login attempts', value: '1', meta: 'review login history', color: AppColors.error),
            ],
          ),
        ),
      ),
    );
  }
}

class _RolesModule extends StatelessWidget {
  const _RolesModule();

  @override
  Widget build(BuildContext context) {
    return _AdminModuleScaffold(
      eyebrow: 'Organization / Roles',
      title: 'Role catalog and permission matrix',
      description:
          'A governance surface for backend-authoritative roles, permissions, scopes, and assignment safety.',
      primaryAction: const _AdminAction(label: 'Add role', icon: Icons.admin_panel_settings_outlined),
      secondaryAction: const _AdminAction(label: 'Review matrix', icon: Icons.grid_view_outlined),
      child: _AdminResponsiveColumns(
        left: _AdminPanel(
          title: 'Role catalog',
          subtitle: 'Frontend shell labels must stay secondary to backend RBAC truth.',
          child: const Column(
            children: [
              _EntityListTile(title: 'ADMIN', subtitle: 'Global unrestricted platform governance', meta: 'system role', status: 'Critical', color: AppColors.error),
              _EntityListTile(title: 'SHIELD_AGENT', subtitle: 'Field onboarding, follow-up, visit orchestration', meta: 'branch scoped', status: 'Operational', color: AppColors.shieldBlue),
              _EntityListTile(title: 'CRM_EXECUTIVE', subtitle: 'Retention and complaint workflows', meta: 'assigned-customer scoped', status: 'Operational', color: AppColors.success),
            ],
          ),
        ),
        right: _AdminPanel(
          title: 'Permission matrix',
          subtitle: 'A compact representation of module ownership and access pressure.',
          child: const _PermissionMatrix(),
        ),
      ),
    );
  }
}

class _ReportsModule extends StatelessWidget {
  const _ReportsModule();

  @override
  Widget build(BuildContext context) {
    return _AdminModuleScaffold(
      eyebrow: 'Analytics / Reports',
      title: 'Report builder and export governance',
      description:
          'A structured builder for datasets, filters, columns, grouping, preview, and export history instead of one-click placeholder cards.',
      primaryAction: const _AdminAction(label: 'Run report', icon: Icons.analytics_outlined),
      secondaryAction: const _AdminAction(label: 'Save template', icon: Icons.bookmark_border_outlined),
      child: _AdminResponsiveColumns(
        left: _AdminPanel(
          title: 'Report builder',
          subtitle: 'Choose dataset, filters, columns, grouping, preview, and export.',
          child: const Column(
            children: [
              _BuilderStep(step: '1', label: 'Choose dataset', description: 'Customers, visits, memberships, wallet, referral, provider, branch'),
              _BuilderStep(step: '2', label: 'Add filters', description: 'Branch, provider, role, lifecycle status, date range'),
              _BuilderStep(step: '3', label: 'Choose columns', description: 'Operational and analytical fields only'),
              _BuilderStep(step: '4', label: 'Group and preview', description: 'Verify structure before export'),
              _BuilderStep(step: '5', label: 'Export or schedule', description: 'CSV, XLSX, PDF, or recurring delivery'),
            ],
          ),
        ),
        right: _AdminPanel(
          title: 'Saved and scheduled reports',
          subtitle: 'The report center should feel operational, not decorative.',
          child: const Column(
            children: [
              _QueueTile(title: 'Daily verification backlog', subtitle: 'Scheduled every 08:00 to central ops', status: 'Scheduled', color: AppColors.shieldBlue),
              _QueueTile(title: 'Weekly agent retention performance', subtitle: 'Sent to branch managers on Monday', status: 'Saved', color: AppColors.success),
              _QueueTile(title: 'Monthly wallet audit pack', subtitle: 'Pending review after pricing rule changes', status: 'Review', color: AppColors.warning),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightsModule extends StatelessWidget {
  const _InsightsModule();

  @override
  Widget build(BuildContext context) {
    return _AdminModuleScaffold(
      eyebrow: 'Analytics / Insights',
      title: 'Growth, retention, and compliance insights',
      description:
          'A visual command layer for customer growth, branch comparison, visits, referrals, membership retention, and document compliance.',
      primaryAction: const _AdminAction(label: 'Open dashboard pack', icon: Icons.insights_outlined),
      secondaryAction: const _AdminAction(label: 'Compare branches', icon: Icons.bar_chart_outlined),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: const [
          _ChartCard(title: 'Customer growth', subtitle: 'Rolling growth by branch and acquisition source'),
          _ChartCard(title: 'Retention health', subtitle: 'Renewal and reactivation performance'),
          _ChartCard(title: 'Visit throughput', subtitle: 'Branch and provider execution view'),
          _ChartCard(title: 'Referral conversion', subtitle: 'Top referrer and campaign performance'),
        ],
      ),
    );
  }
}

class _AuditModule extends StatelessWidget {
  const _AuditModule();

  @override
  Widget build(BuildContext context) {
    return _AdminModuleScaffold(
      eyebrow: 'Analytics / Audit logs',
      title: 'Audit, security, and change history',
      description:
          'Every important operational, auth, and configuration action needs a readable history with actor, time, reason, and target.',
      primaryAction: const _AdminAction(label: 'Export audit', icon: Icons.file_download_outlined),
      secondaryAction: const _AdminAction(label: 'Security view', icon: Icons.security_outlined),
      child: _AdminResponsiveColumns(
        left: _AdminPanel(
          title: 'Activity and security feed',
          subtitle: 'One place for approvals, auth, and high-risk actions.',
          child: const Column(
            children: [
              _TimelineEvent(time: '09:41', title: 'Rahul approved document', description: 'Customer SH-10284 Aadhaar verified.', accent: AppColors.success),
              _TimelineEvent(time: '09:46', title: 'Arjun added customer', description: 'New registration from Calicut North.', accent: AppColors.shieldBlue),
              _TimelineEvent(time: '09:47', title: 'System wallet update', description: 'Pricing engine posted reward redemption audit.', accent: Color(0xFF7C3AED)),
              _TimelineEvent(time: '10:02', title: 'Admin revoked session', description: 'Manual security reset for unusual login behavior.', accent: AppColors.error),
            ],
          ),
        ),
        right: _AdminPanel(
          title: 'Audit filters',
          subtitle: 'Slice by actor, entity, action, severity, or branch.',
          child: const Column(
            children: [
              _HealthRow(label: 'Auth events', value: '426', meta: 'today', color: AppColors.shieldBlue),
              _HealthRow(label: 'Approval actions', value: '89', meta: 'documents, membership, wallet', color: AppColors.success),
              _HealthRow(label: 'Configuration changes', value: '7', meta: 'roles, settings, commercial controls', color: AppColors.warning),
              _HealthRow(label: 'Critical security events', value: '1', meta: 'immediate review required', color: AppColors.error),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationsModule extends StatelessWidget {
  const _NotificationsModule();

  @override
  Widget build(BuildContext context) {
    return _AdminModuleScaffold(
      eyebrow: 'System / Notifications',
      title: 'Notification operations inbox',
      description:
          'Internal notifications, delivery health, drafts, broadcasts, and scheduled campaigns should live in one message operations center.',
      primaryAction: const _AdminAction(label: 'Create broadcast', icon: Icons.campaign_outlined),
      secondaryAction: const _AdminAction(label: 'Schedule notification', icon: Icons.schedule_send_outlined),
      child: _AdminResponsiveColumns(
        left: _AdminPanel(
          title: 'Inbox',
          subtitle: 'Today, yesterday, and earlier grouped operational messages.',
          child: const Column(
            children: [
              _QueueTile(title: 'Verification backlog reminder', subtitle: 'Central ops broadcast to document team', status: 'Unread', color: AppColors.warning),
              _QueueTile(title: 'Provider capacity alert', subtitle: 'Calicut North scheduling heads-up', status: 'Actioned', color: AppColors.shieldBlue),
              _QueueTile(title: 'Renewal campaign sent', subtitle: '76 expiring customers targeted', status: 'Delivered', color: AppColors.success),
            ],
          ),
        ),
        right: _AdminPanel(
          title: 'Delivery health',
          subtitle: 'Operational confidence for outbound communication.',
          child: const Column(
            children: [
              _HealthRow(label: 'Sent today', value: '1,842', meta: 'push + in-app', color: AppColors.success),
              _HealthRow(label: 'Scheduled', value: '12', meta: 'next 72 hours', color: AppColors.shieldBlue),
              _HealthRow(label: 'Failed', value: '18', meta: 'device or payload issues', color: AppColors.warning),
              _HealthRow(label: 'Suppressed', value: '3', meta: 'policy or duplication guard', color: AppColors.error),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsModule extends StatelessWidget {
  const _SettingsModule();

  @override
  Widget build(BuildContext context) {
    return _AdminModuleScaffold(
      eyebrow: 'System / Settings',
      title: 'Company, security, and platform settings',
      description:
          'Centralized operational configuration for company details, branding, notifications, security posture, API surfaces, storage, and feature controls.',
      primaryAction: const _AdminAction(label: 'Save configuration', icon: Icons.save_outlined),
      secondaryAction: const _AdminAction(label: 'Review security', icon: Icons.lock_outline),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: const [
          _SettingCard(title: 'Company', subtitle: 'Legal identity, support contacts, regional defaults', icon: Icons.business_outlined),
          _SettingCard(title: 'Branding', subtitle: 'Visual assets, logos, colors, and public-facing consistency', icon: Icons.palette_outlined),
          _SettingCard(title: 'Notifications', subtitle: 'templates, default channels, escalation rules', icon: Icons.notifications_active_outlined),
          _SettingCard(title: 'Security', subtitle: 'session policy, auth posture, revocation defaults', icon: Icons.security_outlined),
          _SettingCard(title: 'API', subtitle: 'integration credentials, outbound callbacks, access policy', icon: Icons.api_outlined),
          _SettingCard(title: 'Storage', subtitle: 'bucket usage, signed URL policy, file retention', icon: Icons.cloud_outlined),
          _SettingCard(title: 'Feature flags', subtitle: 'controlled rollout surfaces and operator toggles', icon: Icons.flag_outlined),
        ],
      ),
    );
  }
}

class _PlatformModule extends StatelessWidget {
  const _PlatformModule();

  @override
  Widget build(BuildContext context) {
    return _AdminModuleScaffold(
      eyebrow: 'System / Platform',
      title: 'Platform runtime and integration health',
      description:
          'A central health board for runtime, queues, integrations, storage, and background workflows that affect operator trust.',
      primaryAction: const _AdminAction(label: 'Open health report', icon: Icons.monitor_heart_outlined),
      secondaryAction: const _AdminAction(label: 'Check integrations', icon: Icons.hub_outlined),
      child: _AdminResponsiveColumns(
        left: _AdminPanel(
          title: 'Runtime health',
          subtitle: 'Core platform availability and operational dependencies.',
          child: const Column(
            children: [
              _HealthRow(label: 'Frontend availability', value: '99.94%', meta: 'last 30 days', color: AppColors.success),
              _HealthRow(label: 'Backend API', value: 'Healthy', meta: 'p95 latency within target', color: AppColors.success),
              _HealthRow(label: 'Storage signing', value: 'Watch', meta: '2 transient failures this morning', color: AppColors.warning),
              _HealthRow(label: 'Background queues', value: 'Lagging', meta: 'document extraction backlog rising', color: AppColors.error),
            ],
          ),
        ),
        right: _AdminPanel(
          title: 'Integration and queue board',
          subtitle: 'The hidden systems operators still depend on every day.',
          child: const Column(
            children: [
              _QueueTile(title: 'Firebase messaging', subtitle: 'Healthy token registration and push send path', status: 'Healthy', color: AppColors.success),
              _QueueTile(title: 'Cloudflare R2 signed URLs', subtitle: 'One burst of retry behavior during peak hour', status: 'Watch', color: AppColors.warning),
              _QueueTile(title: 'Document extraction service', subtitle: 'OCR queue length up after bulk uploads', status: 'Backlog', color: AppColors.error),
            ],
          ),
        ),
      ),
    );
  }
}

class _FallbackModule extends StatelessWidget {
  const _FallbackModule({required this.section});

  final PortalSectionData section;

  @override
  Widget build(BuildContext context) {
    return _AdminModuleScaffold(
      eyebrow: 'Admin module',
      title: section.title,
      description: section.summary,
      child: _AdminPanel(
        title: 'Module placeholder',
        subtitle: 'This section is intentionally reserved for future expansion.',
        child: const _EmptyState(
          title: 'Reserved admin surface',
          description: 'The blueprint includes this module, but the current V1 slice does not need a deeper implementation yet.',
          action: 'Return to dashboard',
        ),
      ),
    );
  }
}

class _AdminModuleScaffold extends StatelessWidget {
  const _AdminModuleScaffold({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.child,
    this.primaryAction,
    this.secondaryAction,
    this.metrics = const <_AdminMetric>[],
  });

  final String eyebrow;
  final String title;
  final String description;
  final Widget child;
  final _AdminAction? primaryAction;
  final _AdminAction? secondaryAction;
  final List<_AdminMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ModuleHeader(
          eyebrow: eyebrow,
          title: title,
          description: description,
          primaryAction: primaryAction,
          secondaryAction: secondaryAction,
        ),
        if (metrics.isNotEmpty) ...[
          const SizedBox(height: 18),
          _MetricGrid(metrics: metrics),
        ],
        const SizedBox(height: 18),
        child,
      ],
    );
  }
}

class _ModuleHeader extends StatelessWidget {
  const _ModuleHeader({
    required this.eyebrow,
    required this.title,
    required this.description,
    this.primaryAction,
    this.secondaryAction,
  });

  final String eyebrow;
  final String title;
  final String description;
  final _AdminAction? primaryAction;
  final _AdminAction? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final narrow =
        AppResponsive.isPhone(context) || MediaQuery.of(context).size.width < 1240;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF8FBFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.divider),
      ),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderText(eyebrow: eyebrow, title: title, description: description),
                const SizedBox(height: 16),
                _HeaderActions(primaryAction: primaryAction, secondaryAction: secondaryAction),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _HeaderText(
                    eyebrow: eyebrow,
                    title: title,
                    description: description,
                  ),
                ),
                const SizedBox(width: 20),
                _HeaderActions(primaryAction: primaryAction, secondaryAction: secondaryAction),
              ],
            ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: AppTypography.tiny.copyWith(
            color: AppColors.gray,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: AppTypography.h1.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.shieldNavy,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Text(
            description,
            style: AppTypography.body.copyWith(
              color: AppColors.darkGray,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderActions extends StatelessWidget {
  const _HeaderActions({
    required this.primaryAction,
    required this.secondaryAction,
  });

  final _AdminAction? primaryAction;
  final _AdminAction? secondaryAction;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.end,
      children: [
        if (secondaryAction != null)
          _ActionButton(
            action: secondaryAction!,
            type: AppButtonType.secondary,
          ),
        if (primaryAction != null)
          _ActionButton(
            action: primaryAction!,
            type: AppButtonType.primary,
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.action,
    required this.type,
  });

  final _AdminAction action;
  final AppButtonType type;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 176,
      child: AppButton(
        text: action.label,
        onPressed: () {},
        type: type,
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<_AdminMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: metrics
          .map(
            (metric) => SizedBox(
              width: _metricWidth(context),
              child: AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: metric.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(metric.icon, color: metric.color, size: 20),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.lightGray,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            metric.label,
                            style: AppTypography.tiny.copyWith(
                              color: AppColors.gray,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      metric.value,
                      style: AppTypography.h2.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.shieldNavy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      metric.note,
                      style: AppTypography.small.copyWith(
                        color: AppColors.darkGray,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  double _metricWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1600) return 190;
    if (width >= 1280) return 180;
    if (width >= 1024) return 220;
    return width - 80;
  }
}

class _AdminPanel extends StatelessWidget {
  const _AdminPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.h3.copyWith(
              color: AppColors.shieldNavy,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTypography.small.copyWith(
              color: AppColors.gray,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _AdminResponsiveColumns extends StatelessWidget {
  const _AdminResponsiveColumns({
    required this.left,
    required this.right,
  });

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 1320;
    if (narrow) {
      return Column(
        children: [
          left,
          const SizedBox(height: 16),
          right,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 7, child: left),
        const SizedBox(width: 16),
        Expanded(flex: 5, child: right),
      ],
    );
  }
}

class _WorkspaceShell extends StatelessWidget {
  const _WorkspaceShell({
    required this.tabs,
    required this.left,
    required this.center,
    required this.right,
  });

  final List<String> tabs;
  final Widget left;
  final Widget center;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final stack = width < 1400;

    return Column(
      children: [
        _SectionTabs(tabs: tabs),
        const SizedBox(height: 16),
        if (stack) ...[
          left,
          const SizedBox(height: 16),
          center,
          const SizedBox(height: 16),
          right,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: left),
              const SizedBox(width: 16),
              Expanded(flex: 5, child: center),
              const SizedBox(width: 16),
              Expanded(flex: 4, child: right),
            ],
          ),
      ],
    );
  }
}

class _SectionTabs extends StatelessWidget {
  const _SectionTabs({required this.tabs});

  final List<String> tabs;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs
            .asMap()
            .entries
            .map(
              (entry) => Container(
                margin: EdgeInsets.only(right: entry.key == tabs.length - 1 ? 0 : 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: entry.key == 0 ? AppColors.shieldNavy : AppColors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: entry.key == 0 ? AppColors.shieldNavy : AppColors.divider,
                  ),
                ),
                child: Text(
                  entry.value,
                  style: AppTypography.small.copyWith(
                    color: entry.key == 0 ? AppColors.white : AppColors.darkGray,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _EntityListTile extends StatelessWidget {
  const _EntityListTile({
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.status,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String meta;
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.shieldNavy,
                  ),
                ),
              ),
              _StatusBadge(label: status, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTypography.small.copyWith(
              color: AppColors.darkGray,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            meta,
            style: AppTypography.tiny.copyWith(
              color: AppColors.gray,
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityHero extends StatelessWidget {
  const _IdentityHero({
    required this.name,
    required this.code,
    required this.primaryMeta,
    required this.secondaryMeta,
    required this.badges,
  });

  final String name;
  final String code;
  final String primaryMeta;
  final String secondaryMeta;
  final List<String> badges;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.shieldNavy,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text(
              (name.isNotEmpty ? name[0] : '?').toUpperCase(),
              style: AppTypography.h2.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.h2.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.shieldNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  code,
                  style: AppTypography.small.copyWith(
                    color: AppColors.gray,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  primaryMeta,
                  style: AppTypography.small.copyWith(
                    color: AppColors.darkGray,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  secondaryMeta,
                  style: AppTypography.tiny.copyWith(
                    color: AppColors.gray,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: badges
                      .map((badge) => _StatusBadge(label: badge, color: AppColors.shieldBlue))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiStrip extends StatelessWidget {
  const _KpiStrip({required this.items});

  final List<_KpiItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map(
            (item) => Container(
              width: 146,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: AppTypography.tiny.copyWith(
                      color: AppColors.gray,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.value,
                    style: AppTypography.body.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.shieldNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.note,
                    style: AppTypography.tiny.copyWith(color: AppColors.gray),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _DetailRows extends StatelessWidget {
  const _DetailRows({required this.rows});

  final List<_DetailRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: rows
          .map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 150,
                    child: Text(
                      row.label,
                      style: AppTypography.small.copyWith(
                        color: AppColors.gray,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      row.value,
                      style: AppTypography.small.copyWith(
                        color: AppColors.darkGray,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.tiny.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TimelineEvent extends StatelessWidget {
  const _TimelineEvent({
    required this.time,
    required this.title,
    required this.description,
    required this.accent,
  });

  final String time;
  final String title;
  final String description;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: AppTypography.tiny.copyWith(
                    color: AppColors.gray,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: AppTypography.small.copyWith(
                    color: AppColors.shieldNavy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.small.copyWith(
                    color: AppColors.darkGray,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueTile extends StatelessWidget {
  const _QueueTile({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppColors.lightGray,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.small.copyWith(
                          color: AppColors.shieldNavy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _StatusBadge(label: status, color: color),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: AppTypography.small.copyWith(
                    color: AppColors.darkGray,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {
  const _HealthRow({
    required this.label,
    required this.value,
    required this.meta,
    required this.color,
  });

  final String label;
  final String value;
  final String meta;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.small.copyWith(
                    color: AppColors.shieldNavy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  meta,
                  style: AppTypography.tiny.copyWith(color: AppColors.gray),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: AppTypography.body.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
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
              style: AppTypography.small.copyWith(
                color: AppColors.shieldNavy,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewSurface extends StatelessWidget {
  const _PreviewSurface({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFFF3F6FB),
        border: Border.all(color: AppColors.divider),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.picture_as_pdf_outlined, size: 42, color: AppColors.shieldNavy),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.shieldNavy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTypography.small.copyWith(color: AppColors.gray),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DecisionCard extends StatelessWidget {
  const _DecisionCard({
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
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTypography.small.copyWith(
                color: AppColors.shieldNavy,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TreeNode extends StatelessWidget {
  const _TreeNode({
    required this.label,
    required this.depth,
    required this.note,
  });

  final String label;
  final int depth;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: depth * 18.0, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: depth == 0 ? Color(0xFF7C3AED) : AppColors.shieldBlue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$label • $note',
              style: AppTypography.small.copyWith(
                color: AppColors.darkGray,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionMatrix extends StatelessWidget {
  const _PermissionMatrix();

  @override
  Widget build(BuildContext context) {
    const headers = ['Role', 'Customers', 'Documents', 'Wallet', 'Audit'];
    const rows = [
      ['ADMIN', 'Full', 'Full', 'Full', 'Full'],
      ['SHIELD_AGENT', 'Scoped', 'Scoped', 'Hidden', 'Hidden'],
      ['CRM_EXECUTIVE', 'Assigned', 'Limited', 'Hidden', 'Hidden'],
      ['PROVIDER', 'Patient only', 'Clinical only', 'Hidden', 'Hidden'],
    ];

    return Column(
      children: [
        Row(
          children: headers
              .map(
                (cell) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      cell,
                      style: AppTypography.tiny.copyWith(
                        color: AppColors.gray,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        ...rows.map(
          (row) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: row
                  .map(
                    (cell) => Expanded(
                      child: Text(
                        cell,
                        style: AppTypography.small.copyWith(
                          color: AppColors.darkGray,
                          fontWeight: cell == row.first ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _BuilderStep extends StatelessWidget {
  const _BuilderStep({
    required this.step,
    required this.label,
    required this.description,
  });

  final String step;
  final String label;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.shieldNavy,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              step,
              style: AppTypography.small.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.small.copyWith(
                    color: AppColors.shieldNavy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.small.copyWith(color: AppColors.darkGray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      child: AppCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.shieldNavy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: AppTypography.small.copyWith(color: AppColors.gray),
            ),
            const SizedBox(height: 16),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F6FB),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: Icon(
                  Icons.show_chart_outlined,
                  color: AppColors.shieldNavy,
                  size: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: AppCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.shieldNavy),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: AppTypography.body.copyWith(
                color: AppColors.shieldNavy,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: AppTypography.small.copyWith(
                color: AppColors.darkGray,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.description,
    required this.action,
  });

  final String title;
  final String description;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.body.copyWith(
              color: AppColors.shieldNavy,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: AppTypography.small.copyWith(
              color: AppColors.darkGray,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          _StatusBadge(label: action, color: AppColors.shieldBlue),
        ],
      ),
    );
  }
}

class _AdminAction {
  const _AdminAction({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

class _AdminMetric {
  const _AdminMetric({
    required this.label,
    required this.value,
    required this.note,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final String note;
  final Color color;
  final IconData icon;
}

class _KpiItem {
  const _KpiItem({
    required this.label,
    required this.value,
    required this.note,
  });

  final String label;
  final String value;
  final String note;
}

class _DetailRow {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}
