import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/models/shield_role.dart';

class PortalMetric {
  final String label;
  final String value;
  final String note;

  const PortalMetric({
    required this.label,
    required this.value,
    required this.note,
  });

  factory PortalMetric.fromJson(Map<String, dynamic> json) {
    return PortalMetric(
      label: (json['label'] ?? '').toString(),
      value: (json['value'] ?? '').toString(),
      note: (json['note'] ?? '').toString(),
    );
  }
}

class PortalListItem {
  final String title;
  final String subtitle;
  final String meta;
  final String status;

  const PortalListItem({
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.status,
  });

  factory PortalListItem.fromJson(Map<String, dynamic> json) {
    return PortalListItem(
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      meta: (json['meta'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
    );
  }
}

class PortalSectionData {
  final String key;
  final String title;
  final String summary;
  final String? iconKey;
  final String? moduleId;
  final String? rendererKey;
  final String? route;
  final String? permission;
  final int badgeCount;
  final int order;
  final List<String> actions;
  final List<PortalMetric> metrics;
  final List<PortalListItem> queueItems;
  final List<PortalListItem> recentItems;
  final List<PortalListItem> insightItems;

  const PortalSectionData({
    required this.key,
    required this.title,
    required this.summary,
    this.iconKey,
    this.moduleId,
    this.rendererKey,
    this.route,
    this.permission,
    this.badgeCount = 0,
    this.order = 0,
    required this.actions,
    required this.metrics,
    required this.queueItems,
    required this.recentItems,
    required this.insightItems,
  });

  factory PortalSectionData.fromJson(Map<String, dynamic> json) {
    return PortalSectionData(
      key: (json['key'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      iconKey: json['iconKey']?.toString() ?? json['icon']?.toString(),
      moduleId: json['moduleId']?.toString(),
      rendererKey: json['rendererKey']?.toString(),
      route: json['route']?.toString(),
      permission: json['permission']?.toString(),
      badgeCount: json['badgeCount'] as int? ?? json['badge'] as int? ?? 0,
      order: json['order'] as int? ?? 0,
      actions: List<String>.from(json['actions'] ?? const <String>[]),
      metrics: (json['metrics'] as List? ?? const <dynamic>[])
          .map((item) => PortalMetric.fromJson(item as Map<String, dynamic>))
          .toList(),
      queueItems: (json['queueItems'] as List? ?? const <dynamic>[])
          .map((item) => PortalListItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      recentItems: (json['recentItems'] as List? ?? const <dynamic>[])
          .map((item) => PortalListItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      insightItems: (json['insightItems'] as List? ?? const <dynamic>[])
          .map((item) => PortalListItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PortalRoleData {
  final SHIELDRole role;
  final String operatorName;
  final String headline;
  final String regionLabel;
  final IconData icon;
  final Color accentColor;
  final List<PortalSectionData> sections;

  const PortalRoleData({
    required this.role,
    required this.operatorName,
    required this.headline,
    required this.regionLabel,
    required this.icon,
    required this.accentColor,
    required this.sections,
  });

  PortalSectionData get defaultSection => sections.first;

  PortalSectionData sectionFor(String? key) {
    return sections.firstWhere(
      (section) => section.key == key,
      orElse: () => defaultSection,
    );
  }
}

PortalSectionData _section(
  String key, {
  String? title,
  String? summary,
  String? moduleId,
  String? rendererKey,
  List<String> actions = const <String>[],
}) {
  final resolvedTitle = title ?? _humanizeKey(key);
  return PortalSectionData(
    key: key,
    title: resolvedTitle,
    summary: summary ?? 'Live $resolvedTitle records for this workspace.',
    iconKey: key,
    moduleId: moduleId ?? key,
    rendererKey: rendererKey ?? key,
    actions: actions,
    metrics: const <PortalMetric>[],
    queueItems: const <PortalListItem>[],
    recentItems: const <PortalListItem>[],
    insightItems: const <PortalListItem>[],
  );
}

String _humanizeKey(String value) {
  const overrides = <String, String>{
    'qr-scan': 'QR Scan',
    'book-appointment': 'Book Appointment',
    'home-visits': 'Home Visits',
    'wallet-ops': 'Wallet Operations',
    'membership-plans': 'Membership Plans',
    'notification-center': 'Notification Center',
    'follow-ups': 'Follow-Ups',
    'crm': 'CRM',
    'referrals': 'Referral Network',
  };
  if (overrides.containsKey(value)) {
    return overrides[value]!;
  }
  return value
      .split('-')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

PortalRoleData portalDataForProviderWorkspaceMeta(
  Map<String, dynamic> workspaceMeta,
) {
  final workflowProfile =
      workspaceMeta['workflowProfile'] as Map<String, dynamic>? ??
      const <String, dynamic>{};
  final providerContext =
      workspaceMeta['providerContext'] as Map<String, dynamic>? ??
      const <String, dynamic>{};
  final rawModules =
      (workspaceMeta['moduleRegistry'] as List? ?? const <dynamic>[])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
  final modulesById = <String, Map<String, dynamic>>{
    for (final module in rawModules)
      if ((module['id']?.toString().trim() ?? '').isNotEmpty)
        module['id']!.toString(): module,
  };
  final rawSections =
      (workspaceMeta['navigationSections'] as List? ?? const <dynamic>[])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList()
        ..sort(
          (left, right) => (left['order'] as num? ?? 0).compareTo(
            right['order'] as num? ?? 0,
          ),
        );

  final sections = rawSections
      .map((item) {
        final moduleId = item['moduleId']?.toString();
        final module = moduleId == null ? null : modulesById[moduleId];
        final resolvedTitle =
            item['title']?.toString() ??
            module?['title']?.toString() ??
            'Section';
        return PortalSectionData(
          key:
              module?['sectionKey']?.toString() ??
              item['id']?.toString() ??
              item['code']?.toString() ??
              '',
          title: resolvedTitle,
          summary:
              item['summary']?.toString() ??
              module?['summary']?.toString() ??
              'Live $resolvedTitle records.',
          iconKey: item['icon']?.toString(),
          moduleId: moduleId,
          rendererKey:
              module?['renderer']?.toString() ?? item['renderer']?.toString(),
          route: item['route']?.toString(),
          permission:
              item['permission']?.toString() ??
              module?['permission']?.toString(),
          badgeCount: item['badge'] is num ? (item['badge'] as num).toInt() : 0,
          order: item['order'] is num ? (item['order'] as num).toInt() : 0,
          actions: List<String>.from(item['actions'] ?? const <String>[]),
          metrics: const <PortalMetric>[],
          queueItems: const <PortalListItem>[],
          recentItems: const <PortalListItem>[],
          insightItems: const <PortalListItem>[],
        );
      })
      .where((section) => section.key.trim().isNotEmpty)
      .toList();

  return PortalRoleData(
    role: SHIELDRole.provider,
    operatorName:
        providerContext['workspaceTitle']?.toString() ?? 'Provider Care Hub',
    headline:
        providerContext['headline']?.toString() ??
        'Patients, appointments, records, and payments in one place',
    regionLabel:
        workflowProfile['title']?.toString() ?? 'Unified provider care portal',
    icon: Icons.local_hospital_outlined,
    accentColor: AppColors.shieldGreen,
    sections: sections.isEmpty
        ? portalDataForRole(SHIELDRole.provider).sections
        : sections,
  );
}

PortalRoleData portalDataForRole(SHIELDRole role) {
  switch (role) {
    case SHIELDRole.customer:
      return PortalRoleData(
        role: role,
        operatorName: 'Customer',
        headline: 'Personal healthcare wallet and records',
        regionLabel: 'Authenticated SHIELD account',
        icon: Icons.person_outline_rounded,
        accentColor: AppColors.shieldBlue,
        sections: [
          _PortalSectionFactory.customerDashboard,
          _PortalSectionFactory.customerWallet,
          _PortalSectionFactory.customerWalletHistory,
          _PortalSectionFactory.customerRewards,
          _PortalSectionFactory.customerServices,
          _PortalSectionFactory.customerOrders,
          _PortalSectionFactory.customerReferrals,
          _PortalSectionFactory.customerAppointments,
          _PortalSectionFactory.customerDocuments,
          _PortalSectionFactory.customerProfile,
          _PortalSectionFactory.customerMembership,
          _PortalSectionFactory.customerPrivilegeCard,
          _PortalSectionFactory.customerPrescriptions,
          _PortalSectionFactory.customerRecharge,
          _PortalSectionFactory.customerBooking,
          _PortalSectionFactory.customerSettings,
          _PortalSectionFactory.customerNotifications,
        ],
      );
    case SHIELDRole.provider:
      return PortalRoleData(
        role: role,
        operatorName: 'Provider Care Hub',
        headline: 'Patients, appointments, records, and payments in one place',
        regionLabel: 'Unified provider care portal',
        icon: Icons.local_hospital_outlined,
        accentColor: AppColors.shieldGreen,
        sections: [
          _PortalSectionFactory.providerDashboard,
          _PortalSectionFactory.providerQueue,
          _PortalSectionFactory.providerCustomers,
          _PortalSectionFactory.providerAppointments,
          _PortalSectionFactory.providerDocuments,
          _PortalSectionFactory.providerPrescriptions,
          _PortalSectionFactory.providerProfile,
          _PortalSectionFactory.providerSettings,
        ],
      );
    case SHIELDRole.agent:
      return PortalRoleData(
        role: role,
        operatorName: 'Field Agent Workspace',
        headline:
            'Daily customer care, registrations, follow-ups, and visit coordination',
        regionLabel: 'Mobile-first customer growth and retention workspace',
        icon: Icons.badge_outlined,
        accentColor: AppColors.shieldBlue,
        sections: [
          _PortalSectionFactory.agentDashboard,
          _PortalSectionFactory.agentCustomers,
          _PortalSectionFactory.agentRegistration,
          _PortalSectionFactory.agentFollowUps,
          _PortalSectionFactory.agentAppointments,
          _PortalSectionFactory.agentReferrals,
          _PortalSectionFactory.agentDocuments,
          _PortalSectionFactory.agentNotifications,
          _PortalSectionFactory.agentPerformance,
          _PortalSectionFactory.agentReports,
          _PortalSectionFactory.agentProfile,
          _PortalSectionFactory.agentSettings,
        ],
      );
    case SHIELDRole.pharmacyStaff:
      return PortalRoleData(
        role: role,
        operatorName: 'Pharmacy Operations',
        headline: 'Live pharmacy operations across customers and documents',
        regionLabel: 'Provider-side fulfillment center',
        icon: Icons.local_pharmacy_outlined,
        accentColor: AppColors.shieldGreen,
        sections: [
          _section('dashboard'),
          _section('customers'),
          _section('verification'),
          _section('bills'),
          _section('prescriptions'),
          _section('qr-scan'),
          _section('history'),
        ],
      );
    case SHIELDRole.clinicStaff:
      return PortalRoleData(
        role: role,
        operatorName: 'Clinic Operations',
        headline: 'Patient flow, appointments, and consultation records',
        regionLabel: 'Clinic-side care delivery center',
        icon: Icons.local_hospital_outlined,
        accentColor: AppColors.shieldNavy,
        sections: [
          _section('dashboard'),
          _section('patients'),
          _section('appointments'),
          _section('consultations'),
          _section('reports'),
          _section('home-visits'),
        ],
      );
    case SHIELDRole.dentalStaff:
      return PortalRoleData(
        role: role,
        operatorName: 'Dental Operations',
        headline: 'Dental care scheduling, treatments, and reports',
        regionLabel: 'Dental care center',
        icon: Icons.medical_services_outlined,
        accentColor: AppColors.warning,
        sections: [
          _section('dashboard'),
          _section('patients'),
          _section('appointments'),
          _section('treatments'),
          _section('reports'),
          _section('history'),
        ],
      );
    case SHIELDRole.crmExecutive:
      return PortalRoleData(
        role: role,
        operatorName: 'CRM Workspace',
        headline: 'Follow-ups, escalations, and customer retention activity',
        regionLabel: 'Assigned customer engagement workspace',
        icon: Icons.support_agent_outlined,
        accentColor: AppColors.shieldNavy,
        sections: [
          _section('dashboard'),
          _section('customers'),
          _section('tasks'),
          _section('follow-ups'),
          _section('complaints'),
          _section('campaigns'),
        ],
      );
    case SHIELDRole.shieldExecutive:
      return PortalRoleData(
        role: role,
        operatorName: 'Executive Workspace',
        headline: 'Approvals, memberships, wallet operations, and support',
        regionLabel: 'Operational oversight workspace',
        icon: Icons.admin_panel_settings_outlined,
        accentColor: AppColors.shieldBlue,
        sections: [
          _section('dashboard'),
          _section('approvals'),
          _section('memberships'),
          _section('wallet-ops'),
          _section('reversals'),
          _section('support'),
        ],
      );
    case SHIELDRole.manager:
      return PortalRoleData(
        role: role,
        operatorName: 'Manager Workspace',
        headline: 'Performance, approvals, credit, and retention oversight',
        regionLabel: 'Management decision workspace',
        icon: Icons.insights_outlined,
        accentColor: AppColors.shieldBlue,
        sections: [
          _section('dashboard'),
          _section('approvals'),
          _section('reports'),
          _section('analytics'),
          _section('credit'),
          _section('retention'),
        ],
      );
    case SHIELDRole.superAdmin:
      return PortalRoleData(
        role: role,
        operatorName: 'SHIELD Admin Portal',
        headline:
            'Platform command center for operations, growth, governance, and system control',
        regionLabel: 'System-wide administrative workspace',
        icon: Icons.security_outlined,
        accentColor: AppColors.shieldNavy,
        sections: [
          _section(
            'dashboard',
            title: 'Dashboard',
            summary:
                'Executive dashboard, operations panel, alerts, and live activity feed.',
          ),
          _section(
            'customers',
            title: 'Customers',
            summary:
                'Master customer workspace across profile, timeline, visits, wallet, and documents.',
          ),
          _section(
            'agents',
            title: 'Agents',
            summary:
                'Agent directory, assignments, KPIs, follow-ups, and territory performance.',
          ),
          _section(
            'crm',
            title: 'CRM',
            summary:
                'Call queues, escalations, retention work, and CRM execution health.',
          ),
          _section(
            'visits',
            title: 'Visits',
            summary:
                'Master visit calendar across provider, branch, agent, and customer schedules.',
          ),
          _section(
            'documents',
            title: 'Documents',
            summary:
                'Verification queue, file preview, approval workflow, and audit history.',
          ),
          _section(
            'memberships',
            title: 'Memberships',
            summary:
                'Plans, benefits, renewal pipelines, usage, and expiry oversight.',
          ),
          _section(
            'wallet',
            title: 'Wallet',
            summary:
                'Ledger, transactions, recharge operations, and adjustment monitoring.',
          ),
          _section(
            'rewards',
            title: 'Rewards',
            summary:
                'Reward rules, redemption settings, campaigns, and points economics.',
          ),
          _section(
            'referrals',
            title: 'Referral Network',
            summary:
                'Referral tree, pending rewards, campaigns, and conversion intelligence.',
          ),
          _section(
            'providers',
            title: 'Providers',
            summary:
                'Provider profiles, services, availability, bookings, and compliance.',
          ),
          _section(
            'services',
            title: 'Services',
            summary:
                'Central service catalog, provider mapping, and commercial alignment.',
          ),
          _section(
            'availability',
            title: 'Availability',
            summary:
                'Provider capacity, schedule health, and branch-level slot pressure.',
          ),
          _section(
            'branches',
            title: 'Branches',
            summary:
                'Branch performance, customers, staff, providers, and local operations.',
          ),
          _section(
            'employees',
            title: 'Employees',
            summary:
                'Internal users, sessions, devices, and access-state visibility.',
          ),
          _section(
            'roles',
            title: 'Roles',
            summary:
                'Role catalog, permissions, scopes, and assignment governance.',
          ),
          _section(
            'reports',
            title: 'Reports',
            summary:
                'Report builder, saved exports, schedules, and delivery history.',
          ),
          _section(
            'insights',
            title: 'Insights',
            summary:
                'Growth, retention, branch, referral, and compliance analytics.',
          ),
          _section(
            'audit',
            title: 'Audit Logs',
            summary:
                'Operational activity, security events, login history, and change tracking.',
          ),
          _section(
            'notifications',
            title: 'Notifications',
            summary:
                'Internal inbox, broadcasts, scheduled messaging, and delivery health.',
          ),
          _section(
            'settings',
            title: 'Settings',
            summary:
                'Company, branding, security, API, storage, and feature-flag configuration.',
          ),
          _section(
            'platform',
            title: 'Platform',
            summary:
                'Runtime health, integrations, storage, and background workflow status.',
          ),
        ],
      );
  }
}

class _PortalSectionFactory {
  static final PortalSectionData customerDashboard = _section(
    'dashboard',
    summary: 'Live membership, wallet, appointment, and notification overview.',
    actions: const ['View card', 'Book visit', 'Open wallet'],
  );

  static final PortalSectionData customerWallet = _section(
    'wallet',
    summary: 'Live wallet balances, credits, and transaction history.',
  );

  static final PortalSectionData customerWalletHistory = _section(
    'wallet-history',
    title: 'Wallet History',
    summary: 'Full customer-scoped wallet ledger history.',
  );

  static final PortalSectionData customerRewards = _section(
    'rewards',
    title: 'Reward Points',
    summary: 'Available customer reward points and ledger activity.',
  );

  static final PortalSectionData customerServices = _section(
    'services',
    summary: 'Browse active SHIELD services and provider availability.',
  );

  static final PortalSectionData customerOrders = _section(
    'orders',
    title: 'My Orders',
    summary: 'Customer-scoped pharmacy purchase history.',
  );

  static final PortalSectionData customerReferrals = _section(
    'referrals',
    title: 'Referral & Rewards',
    summary: 'Customer referral lifecycle and reward status.',
  );

  static final PortalSectionData customerAppointments = _section(
    'appointments',
    summary: 'Scheduled, completed, and pending care visits.',
  );

  static final PortalSectionData customerDocuments = _section(
    'documents',
    summary: 'Medical records, uploads, and extracted document history.',
  );

  static final PortalSectionData customerProfile = _section(
    'profile',
    summary: 'Verified customer profile and account details.',
  );

  static final PortalSectionData customerMembership = _section(
    'membership',
    summary: 'Issued membership details and card access.',
  );

  static final PortalSectionData customerPrivilegeCard = _section(
    'privilege-card',
    title: 'Privilege Card',
    summary: 'Digital membership card and verification QR.',
  );

  static final PortalSectionData customerPrescriptions = _section(
    'prescriptions',
    summary: 'Prescription review, uploads, and pharmacy linkage.',
  );

  static final PortalSectionData customerRecharge = _section(
    'recharge',
    summary: 'Wallet recharge requests and approval trail.',
  );

  static final PortalSectionData customerBooking = _section(
    'book-appointment',
    summary: 'Live appointment booking across available providers.',
  );

  static final PortalSectionData customerSettings = _section(
    'settings',
    summary: 'Account preferences, support, and session controls.',
  );

  static final PortalSectionData customerNotifications = _section(
    'notifications',
    summary: 'Live alerts, approvals, and engagement messages.',
  );

  static final PortalSectionData providerDashboard = _section(
    'dashboard',
    summary: 'Daily appointments, waiting patients, and care activity summary.',
    actions: const ['Open patient queue', 'Open patient search'],
  );

  static final PortalSectionData providerQueue = _section(
    'queue',
    summary: 'Waiting patients, payments, and care activity for today.',
  );

  static final PortalSectionData providerCustomers = _section(
    'customers',
    title: 'Patients',
    summary:
        'Patient profile, appointments, medical records, membership, and payments.',
    moduleId: 'patient-workspace',
    rendererKey: 'patient-workspace',
  );

  static final PortalSectionData providerAppointments = _section(
    'appointments',
    summary: 'Assigned appointment activity and customer visit timeline.',
  );

  static final PortalSectionData providerDocuments = _section(
    'documents',
    title: 'Medical Records',
    summary: 'Patient records, uploads, and linked care documents.',
  );

  static final PortalSectionData providerPrescriptions = _section(
    'prescriptions',
    summary: 'Prescription-linked customer records and care continuity.',
  );

  static final PortalSectionData providerProfile = _section(
    'profile',
    summary: 'Provisioned provider identity, branch scope, and role context.',
  );

  static final PortalSectionData providerSettings = _section(
    'settings',
    summary: 'Session visibility, device history, and sign-out controls.',
  );
  static final PortalSectionData agentDashboard = _section(
    'dashboard',
    summary:
        'Today tasks, registrations, visits, customer network activity, and recent actions.',
    actions: const ['Register customer', 'Open follow-ups'],
  );
  static final PortalSectionData agentCustomers = _section(
    'customers',
    title: 'Customers',
    summary:
        'Assigned customers only, with onboarding, card, wallet, and appointment context.',
  );
  static final PortalSectionData agentRegistration = _section(
    'registration',
    title: 'Register Customer',
    summary:
        'Step-based customer registration with branch, membership, and document readiness.',
  );
  static final PortalSectionData agentFollowUps = _section(
    'followups',
    title: 'Follow-Ups',
    summary:
        'Customer-first follow-up planning, outcomes, reminders, and next actions.',
  );
  static final PortalSectionData agentAppointments = _section(
    'appointments',
    title: 'Visits',
    summary:
        'Customer visit booking, provider selection, preferred slots, and visit status tracking.',
  );
  static final PortalSectionData agentReferrals = _section(
    'referrals',
    title: 'Network',
    summary:
        'Customer network growth, relationship tree, and conversion progress in the scoped graph.',
  );
  static final PortalSectionData agentDocuments = _section(
    'documents',
    title: 'Documents',
    summary:
        'Required onboarding and customer documents limited to this agent assignment.',
  );
  static final PortalSectionData agentNotifications = _section(
    'notifications',
    summary:
        'Assigned customer notifications and updates with read-state visibility.',
  );
  static final PortalSectionData agentPerformance = _section(
    'performance',
    title: 'Performance',
    summary:
        'This month customer growth, retention, follow-up completion, visits, and incentives.',
  );
  static final PortalSectionData agentReports = _section(
    'reports',
    summary:
        'Export customer, follow-up, referral, document, and performance reports.',
  );
  static final PortalSectionData agentProfile = _section(
    'profile',
    title: 'Profile',
    summary: 'Agent identity, contact info, and employee assignment details.',
  );
  static final PortalSectionData agentSettings = _section(
    'settings',
    summary:
        'Portal preferences, workspace behavior, devices, and session security.',
  );
}
