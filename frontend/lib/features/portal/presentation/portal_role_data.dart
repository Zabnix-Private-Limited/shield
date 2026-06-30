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
    route: '/portal/provider/$key',
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
  final rawModules = (workspaceMeta['moduleRegistry'] as List? ??
          const <dynamic>[])
      .map((item) => Map<String, dynamic>.from(item as Map))
      .toList();
  final modulesById = <String, Map<String, dynamic>>{
    for (final module in rawModules)
      if ((module['id']?.toString().trim() ?? '').isNotEmpty)
        module['id']!.toString(): module,
  };
  final rawSections = (workspaceMeta['navigationSections'] as List? ??
          const <dynamic>[])
      .map((item) => Map<String, dynamic>.from(item as Map))
      .toList()
    ..sort(
      (left, right) => (left['order'] as num? ?? 0).compareTo(
        right['order'] as num? ?? 0,
      ),
    );

  final sections = rawSections
      .map(
        (item) {
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
                module?['renderer']?.toString() ??
                item['renderer']?.toString(),
            route: item['route']?.toString(),
            permission:
                item['permission']?.toString() ??
                module?['permission']?.toString(),
            badgeCount:
                item['badge'] is num ? (item['badge'] as num).toInt() : 0,
            order: item['order'] is num ? (item['order'] as num).toInt() : 0,
            actions: List<String>.from(item['actions'] ?? const <String>[]),
            metrics: const <PortalMetric>[],
            queueItems: const <PortalListItem>[],
            recentItems: const <PortalListItem>[],
            insightItems: const <PortalListItem>[],
          );
        },
      )
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
        workflowProfile['title']?.toString() ??
        'Unified provider care portal',
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
          _PortalSectionFactory.customerServices,
          _PortalSectionFactory.customerAppointments,
          _PortalSectionFactory.customerDocuments,
          _PortalSectionFactory.customerProfile,
          _PortalSectionFactory.customerMembership,
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
    case SHIELDRole.pharmacyStaff:
      return PortalRoleData(
        role: role,
        operatorName: 'Pharmacy Workspace',
        headline: 'Live pharmacy operations across customers and documents',
        regionLabel: 'Provider-side fulfillment workspace',
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
        operatorName: 'Clinic Workspace',
        headline: 'Patient flow, appointments, and consultation records',
        regionLabel: 'Clinic-side care delivery workspace',
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
        operatorName: 'Dental Workspace',
        headline: 'Dental care scheduling, treatments, and reports',
        regionLabel: 'Dental provider workspace',
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
        operatorName: 'Super Admin Workspace',
        headline: 'Platform governance, master data, and audit visibility',
        regionLabel: 'System-wide administrative workspace',
        icon: Icons.security_outlined,
        accentColor: AppColors.shieldNavy,
        sections: [
          _section('dashboard'),
          _section('users'),
          _section('roles'),
          _section('businesses'),
          _section('audit'),
          _section('system'),
          _section('membership-plans'),
          _section('reports'),
          _section('notification-center'),
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
    actions: const ['Recharge', 'View statement'],
  );

  static final PortalSectionData customerServices = _section(
    'services',
    summary: 'Browse active SHIELD services and provider availability.',
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
    summary: 'Patient profile, appointments, medical records, membership, and payments.',
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
}
