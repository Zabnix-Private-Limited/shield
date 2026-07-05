import 'package:flutter/material.dart';

import '../../../portal/presentation/portal_role_data.dart';
import '../../../../shared/models/shield_role.dart';
import '../../agents/presentation/screens/admin_agents_module.dart';
import '../../analytics/presentation/screens/admin_insights_module.dart';
import '../../audit/presentation/screens/admin_audit_module.dart';
import '../../availability/presentation/screens/admin_availability_module.dart';
import '../../crm/presentation/screens/admin_crm_module.dart';
import '../../customers/presentation/screens/admin_customers_module.dart';
import '../../dashboard/presentation/screens/admin_dashboard_module.dart';
import '../../documents/presentation/screens/admin_documents_module.dart';
import '../../memberships/presentation/screens/admin_memberships_module.dart';
import '../../notifications/presentation/screens/admin_notifications_module.dart';
import '../../organization/presentation/screens/admin_branches_module.dart';
import '../../organization/presentation/screens/admin_employees_module.dart';
import '../../organization/presentation/screens/admin_roles_module.dart';
import '../../providers/presentation/screens/admin_providers_module.dart';
import '../../referrals/presentation/screens/admin_referrals_module.dart';
import '../../reports/presentation/screens/admin_reports_module.dart';
import '../../rewards/presentation/screens/admin_rewards_module.dart';
import '../../services/presentation/screens/admin_services_module.dart';
import '../../settings/presentation/screens/admin_platform_module.dart';
import '../../settings/presentation/screens/admin_settings_module.dart';
import '../../governance/data/admin_governance_remote_data_source.dart';
import '../../governance/data/admin_governance_workspace_repository.dart';
import '../../governance/data/admin_governance_workspace_schema_repository.dart';
import '../../shared/engine/exports.dart';
import '../../visits/presentation/screens/admin_visits_module.dart';
import '../../wallet/presentation/screens/admin_wallet_module.dart';
import 'admin_platform_runtime.dart';

class AdminWorkspaceCatalog {
  AdminWorkspaceCatalog._();

  static const Set<String> backendWorkspaceIds = <String>{
    'dashboard',
    'customers',
    'settings',
    'platform',
    'audit',
    'notifications',
  };

  static final List<AdminWorkspaceRegistration> registrations =
      _buildRegistrations();

  static final Map<String, AdminWorkspaceRegistration> _registrationMap =
      <String, AdminWorkspaceRegistration>{
        for (final registration in registrations)
          registration.workspace.id: registration,
      };

  static final AdminGovernanceRemoteDataSource _governanceRemoteDataSource =
      AdminGovernanceRemoteDataSource();

  static final AdminWorkspaceSchemaRepository _schemaRepository =
      AdminGovernanceWorkspaceSchemaRepository(
        remoteDataSource: _governanceRemoteDataSource,
        fallbackSchemas: <String, AdminWorkspaceSchemaDefinition>{
          for (final registration in registrations)
            registration.workspace.id: registration.schema,
        },
        governanceWorkspaceIds: backendWorkspaceIds,
      );

  static final AdminPlatformRuntime runtime = AdminPlatformRuntime.bootstrap(
    registrations: registrations,
    schemaRepository: _schemaRepository,
    repositoryResolver: _repositoryResolver,
  );

  static AdminWorkspaceRegistration? registrationFor(String workspaceId) {
    return _registrationMap[workspaceId];
  }

  static List<AdminWorkspaceRegistration> _buildRegistrations() {
    final sections = <String, PortalSectionData>{
      for (final section in portalDataForRole(SHIELDRole.superAdmin).sections)
        section.key: section,
    };

    return _workspaceSeeds
        .map((seed) => seed.toRegistration(sections[seed.id]))
        .toList(growable: false);
  }
}

final List<_AdminWorkspaceSeed> _workspaceSeeds = <_AdminWorkspaceSeed>[
  _AdminWorkspaceSeed(
    id: 'dashboard',
    capabilities: {'metrics', 'timeline', 'activity'},
    defaultViewType: AdminViewType.split,
    builder: _buildDashboardWorkspace,
  ),
  _AdminWorkspaceSeed(
    id: 'customers',
    capabilities: {'tables', 'search', 'filters', 'timeline'},
    defaultViewType: AdminViewType.split,
    builder: _buildCustomersWorkspace,
  ),
  _AdminWorkspaceSeed(
    id: 'agents',
    capabilities: {'tables', 'search', 'filters'},
    defaultViewType: AdminViewType.table,
    builder: _buildAgentsWorkspace,
  ),
  _AdminWorkspaceSeed(
    id: 'crm',
    capabilities: {'tables', 'search', 'filters', 'workflow'},
    defaultViewType: AdminViewType.table,
    builder: _buildCrmWorkspace,
  ),
  _AdminWorkspaceSeed(
    id: 'visits',
    capabilities: {'tables', 'search', 'filters'},
    defaultViewType: AdminViewType.table,
    builder: _buildVisitsWorkspace,
  ),
  _AdminWorkspaceSeed(
    id: 'documents',
    capabilities: {'tables', 'search', 'filters', 'files'},
    defaultViewType: AdminViewType.table,
    builder: _buildDocumentsWorkspace,
  ),
  _AdminWorkspaceSeed(
    id: 'memberships',
    capabilities: {'tables', 'search', 'filters'},
    defaultViewType: AdminViewType.table,
    builder: _buildMembershipsWorkspace,
  ),
  _AdminWorkspaceSeed(
    id: 'wallet',
    capabilities: {'tables', 'search', 'filters', 'timeline'},
    defaultViewType: AdminViewType.table,
    builder: _buildWalletWorkspace,
  ),
  _AdminWorkspaceSeed(
    id: 'rewards',
    capabilities: {'tables', 'search', 'filters'},
    defaultViewType: AdminViewType.table,
    builder: _buildRewardsWorkspace,
  ),
  _AdminWorkspaceSeed(
    id: 'referrals',
    capabilities: {'tables', 'search', 'filters', 'timeline'},
    defaultViewType: AdminViewType.table,
    builder: _buildReferralsWorkspace,
  ),
  _AdminWorkspaceSeed(
    id: 'providers',
    capabilities: {'tables', 'search', 'filters'},
    defaultViewType: AdminViewType.table,
    builder: _buildProvidersWorkspace,
  ),
  _AdminWorkspaceSeed(
    id: 'services',
    capabilities: {'tables', 'search', 'filters'},
    defaultViewType: AdminViewType.table,
    builder: _buildServicesWorkspace,
  ),
  _AdminWorkspaceSeed(
    id: 'availability',
    capabilities: {'tables', 'filters'},
    defaultViewType: AdminViewType.table,
    builder: _buildAvailabilityWorkspace,
  ),
  _AdminWorkspaceSeed(
    id: 'branches',
    capabilities: {'tables', 'search', 'filters'},
    defaultViewType: AdminViewType.table,
    builder: _buildBranchesWorkspace,
  ),
  _AdminWorkspaceSeed(
    id: 'employees',
    capabilities: {'tables', 'search', 'filters'},
    defaultViewType: AdminViewType.table,
    builder: _buildEmployeesWorkspace,
  ),
  _AdminWorkspaceSeed(
    id: 'roles',
    capabilities: {'tables', 'search', 'filters', 'permissions'},
    defaultViewType: AdminViewType.table,
    builder: _buildRolesWorkspace,
  ),
  _AdminWorkspaceSeed(
    id: 'reports',
    capabilities: {'tables', 'search', 'filters', 'export'},
    defaultViewType: AdminViewType.table,
    builder: _buildReportsWorkspace,
  ),
  _AdminWorkspaceSeed(
    id: 'insights',
    capabilities: {'metrics', 'tables', 'filters'},
    defaultViewType: AdminViewType.metrics,
    builder: _buildInsightsWorkspace,
  ),
  _AdminWorkspaceSeed(
    id: 'audit',
    capabilities: {'tables', 'search', 'filters', 'timeline'},
    defaultViewType: AdminViewType.table,
    builder: _buildAuditWorkspace,
  ),
  _AdminWorkspaceSeed(
    id: 'notifications',
    capabilities: {'tables', 'search', 'filters', 'actions'},
    defaultViewType: AdminViewType.table,
    builder: _buildNotificationsWorkspace,
  ),
  _AdminWorkspaceSeed(
    id: 'settings',
    capabilities: {'forms', 'search', 'permissions'},
    defaultViewType: AdminViewType.detail,
    builder: _buildSettingsWorkspace,
  ),
  _AdminWorkspaceSeed(
    id: 'platform',
    capabilities: {'tables', 'search', 'filters', 'realtime'},
    defaultViewType: AdminViewType.table,
    builder: _buildPlatformWorkspace,
  ),
];

class _AdminWorkspaceSeed {
  const _AdminWorkspaceSeed({
    required this.id,
    required this.capabilities,
    required this.defaultViewType,
    required this.builder,
  });

  final String id;
  final Set<String> capabilities;
  final AdminViewType defaultViewType;
  final AdminWorkspaceRenderer builder;

  AdminWorkspaceRegistration toRegistration(PortalSectionData? section) {
    final title = section?.title ?? _humanizeKey(id);
    final permissionKey =
        section?.permission ??
        _workspacePermissionOverrides[id] ??
        'admin.$id.read';
    final route = section?.route ?? '/portal/super-admin/$id';
    final iconKey = section?.iconKey ?? id;
    final schema = _buildSchema(title);
    final workspace = AdminWorkspaceDefinition(
      id: id,
      title: title,
      iconKey: iconKey,
      permissionKey: permissionKey,
      dataSource: AdminDataSourceDefinition(scope: id, endpoint: '/admin/$id'),
      views: schema.views,
    );

    return AdminWorkspaceRegistration(
      workspace: workspace,
      navigation: AdminNavigationDefinition(
        workspaceId: id,
        route: route,
        title: title,
        iconKey: iconKey,
        permissionKey: permissionKey,
        breadcrumbs: ['Super Admin', title],
        defaultViewId: schema.defaultViewId,
      ),
      schema: schema,
      capabilities: capabilities,
      builder: builder,
    );
  }

  AdminWorkspaceSchemaDefinition _buildSchema(String title) {
    final defaultViewId = switch (defaultViewType) {
      AdminViewType.table => 'table',
      AdminViewType.metrics => 'overview',
      AdminViewType.detail => 'detail',
      AdminViewType.cards => 'cards',
      AdminViewType.timeline => 'timeline',
      AdminViewType.split => 'split',
    };

    return AdminWorkspaceSchemaDefinition(
      workspaceId: id,
      defaultViewId: defaultViewId,
      views: [
        AdminViewDefinition(
          id: defaultViewId,
          type: defaultViewType,
          title: title,
          table: defaultViewType == AdminViewType.table
              ? AdminTableDefinition(
                  entity: id,
                  columns: const [
                    AdminTableColumnDefinition(
                      key: 'name',
                      label: 'Name',
                      valueType: AdminColumnValueType.text,
                    ),
                    AdminTableColumnDefinition(
                      key: 'status',
                      label: 'Status',
                      valueType: AdminColumnValueType.status,
                    ),
                    AdminTableColumnDefinition(
                      key: 'updatedAt',
                      label: 'Updated',
                      valueType: AdminColumnValueType.date,
                    ),
                  ],
                  filters: const [
                    AdminFilterDefinition(
                      key: 'status',
                      label: 'Status',
                      type: AdminFilterType.select,
                    ),
                  ],
                  sorting: const [
                    AdminSortDefinition(key: 'updatedAt', label: 'Updated'),
                  ],
                  actions: [
                    AdminActionDefinition(
                      id: 'refresh-$id',
                      type: AdminActionType.refresh,
                      label: 'Refresh',
                    ),
                    if (capabilities.contains('export'))
                      AdminActionDefinition(
                        id: 'export-$id',
                        type: AdminActionType.export,
                        label: 'Export',
                      ),
                  ],
                )
              : null,
          form: defaultViewType == AdminViewType.detail
              ? AdminFormDefinition(
                  entity: id,
                  sections: const [
                    AdminFormSectionDefinition(
                      id: 'primary',
                      title: 'Primary',
                      fields: [
                        AdminFormFieldDefinition(
                          key: 'title',
                          label: 'Title',
                          type: AdminFormFieldType.text,
                          required: true,
                        ),
                        AdminFormFieldDefinition(
                          key: 'notes',
                          label: 'Notes',
                          type: AdminFormFieldType.textarea,
                        ),
                      ],
                    ),
                  ],
                )
              : null,
          actions: [
            AdminActionDefinition(
              id: 'refresh-$id',
              type: AdminActionType.refresh,
              label: 'Refresh',
            ),
          ],
        ),
      ],
    );
  }
}

AdminWorkspaceRepository _repositoryResolver(
  AdminWorkspaceDefinition workspace,
) {
  if (AdminWorkspaceCatalog.backendWorkspaceIds.contains(workspace.id)) {
    return AdminGovernanceWorkspaceRepository(
      remoteDataSource: AdminWorkspaceCatalog._governanceRemoteDataSource,
    );
  }
  return const _CatalogNoopAdminWorkspaceRepository();
}

const Map<String, String> _workspacePermissionOverrides = <String, String>{
  'dashboard': 'analytics.view',
  'customers': 'customers.view',
  'settings': 'settings.view',
  'platform': 'platform.view',
  'audit': 'audit.view',
  'notifications': 'notifications.view',
};

class _CatalogNoopAdminWorkspaceRepository implements AdminWorkspaceRepository {
  const _CatalogNoopAdminWorkspaceRepository();

  @override
  Future<Object?> loadWorkspaceData(
    AdminWorkspaceDefinition workspace, {
    AdminWorkspaceQuery query = const AdminWorkspaceQuery(),
    bool forceRefresh = false,
  }) async {
    return null;
  }
}

String _humanizeKey(String value) {
  return value
      .split('-')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

Widget _buildDashboardWorkspace(
  BuildContext context,
  AdminWorkspaceSnapshot snapshot,
) => AdminDashboardModule(snapshot: snapshot);

Widget _buildCustomersWorkspace(
  BuildContext context,
  AdminWorkspaceSnapshot snapshot,
) => AdminCustomersModule(snapshot: snapshot);

Widget _buildAgentsWorkspace(
  BuildContext context,
  AdminWorkspaceSnapshot snapshot,
) => const AdminAgentsModule();

Widget _buildCrmWorkspace(
  BuildContext context,
  AdminWorkspaceSnapshot snapshot,
) => const AdminCrmModule();

Widget _buildVisitsWorkspace(
  BuildContext context,
  AdminWorkspaceSnapshot snapshot,
) => const AdminVisitsModule();

Widget _buildDocumentsWorkspace(
  BuildContext context,
  AdminWorkspaceSnapshot snapshot,
) => const AdminDocumentsModule();

Widget _buildMembershipsWorkspace(
  BuildContext context,
  AdminWorkspaceSnapshot snapshot,
) => const AdminMembershipsModule();

Widget _buildWalletWorkspace(
  BuildContext context,
  AdminWorkspaceSnapshot snapshot,
) => const AdminWalletModule();

Widget _buildRewardsWorkspace(
  BuildContext context,
  AdminWorkspaceSnapshot snapshot,
) => const AdminRewardsModule();

Widget _buildReferralsWorkspace(
  BuildContext context,
  AdminWorkspaceSnapshot snapshot,
) => const AdminReferralsModule();

Widget _buildProvidersWorkspace(
  BuildContext context,
  AdminWorkspaceSnapshot snapshot,
) => const AdminProvidersModule();

Widget _buildServicesWorkspace(
  BuildContext context,
  AdminWorkspaceSnapshot snapshot,
) => const AdminServicesModule();

Widget _buildAvailabilityWorkspace(
  BuildContext context,
  AdminWorkspaceSnapshot snapshot,
) => const AdminAvailabilityModule();

Widget _buildBranchesWorkspace(
  BuildContext context,
  AdminWorkspaceSnapshot snapshot,
) => const AdminBranchesModule();

Widget _buildEmployeesWorkspace(
  BuildContext context,
  AdminWorkspaceSnapshot snapshot,
) => const AdminEmployeesModule();

Widget _buildRolesWorkspace(
  BuildContext context,
  AdminWorkspaceSnapshot snapshot,
) => const AdminRolesModule();

Widget _buildReportsWorkspace(
  BuildContext context,
  AdminWorkspaceSnapshot snapshot,
) => const AdminReportsModule();

Widget _buildInsightsWorkspace(
  BuildContext context,
  AdminWorkspaceSnapshot snapshot,
) => const AdminInsightsModule();

Widget _buildAuditWorkspace(
  BuildContext context,
  AdminWorkspaceSnapshot snapshot,
) => AdminAuditModule(snapshot: snapshot);

Widget _buildNotificationsWorkspace(
  BuildContext context,
  AdminWorkspaceSnapshot snapshot,
) => AdminNotificationsModule(snapshot: snapshot);

Widget _buildSettingsWorkspace(
  BuildContext context,
  AdminWorkspaceSnapshot snapshot,
) => AdminSettingsModule(snapshot: snapshot);

Widget _buildPlatformWorkspace(
  BuildContext context,
  AdminWorkspaceSnapshot snapshot,
) => AdminPlatformModule(snapshot: snapshot);
