import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../agent/appointments/presentation/screens/agent_appointments_screen.dart';
import '../../../agent/customers/presentation/screens/agent_customers_screen.dart';
import '../../../agent/dashboard/presentation/screens/agent_dashboard_screen.dart';
import '../../../agent/documents/presentation/screens/agent_documents_screen.dart';
import '../../../agent/followups/presentation/screens/agent_followups_screen.dart';
import '../../../agent/notifications/presentation/screens/agent_notifications_screen.dart';
import '../../../agent/performance/presentation/screens/agent_performance_screen.dart';
import '../../../agent/referrals/presentation/screens/agent_referrals_screen.dart';
import '../../../agent/registration/presentation/screens/agent_registration_screen.dart';
import '../../../agent/reports/presentation/screens/agent_reports_screen.dart';
import '../../../agent/settings/presentation/screens/agent_settings_screen.dart';
import '../../../agent/store_change/presentation/screens/agent_store_change_screen.dart';
import '../../../admin/presentation/screens/admin_portal_workspace.dart';
import '../../../customer/dashboard/presentation/screens/dashboard_screen.dart';
import '../../../customer/activity/presentation/screens/customer_activity_screen.dart';
import '../../../customer/account/presentation/screens/customer_account_screen.dart';
import '../../../customer/account/presentation/screens/store_change_screen.dart';
import '../../../customer/account/data/customer_account_repository.dart';
import '../../../customer/documents/presentation/screens/customer_documents_screen.dart';
import '../../../customer/membership/data/models/membership_model.dart';
import '../../../customer/membership/presentation/screens/membership_screen.dart';
import '../../../customer/membership/presentation/screens/privilege_card_screen.dart';
import '../../../customer/orders/presentation/screens/customer_orders_screen.dart';
import '../../../customer/referrals/presentation/screens/customer_referrals_screen.dart';
import '../../../customer/prescriptions/presentation/screens/customer_prescriptions_screen.dart';
import '../../../customer/shared/domain/customer_access_state.dart';
import '../../../customer/wallet/presentation/screens/wallet_screen.dart';
import '../../../customer/wallet/presentation/screens/reward_points_screen.dart';
import '../../../crm/complaints/presentation/screens/crm_complaints_screen.dart';
import '../../../provider/customers/presentation/screens/provider_customers_screen.dart';
import '../../../provider/dashboard/presentation/screens/provider_dashboard_screen.dart';
import '../../../provider/profile/presentation/screens/provider_profile_screen.dart';
import '../../../provider/queue/presentation/screens/provider_queue_screen.dart';
import '../../../provider/settings/presentation/screens/provider_settings_screen.dart';
import '../../../customer/shared/widgets/customer_scaffold.dart';
import '../../../customer/shared/widgets/error_card.dart';
import '../../../customer/shared/widgets/loading_card.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/models/appointment.dart';
import '../../../../shared/models/customer.dart';
import '../../../../shared/models/membership.dart';
import '../../../../shared/models/notification.dart';
import '../../../../shared/models/shield_role.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_page_frame.dart';
import '../../../../shared/widgets/app_responsive.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/widgets/shield_date_input_field.dart';
import '../../../../shared/widgets/shield_brand_lockup.dart';
import '../../../../shared/services/api_service.dart';
import '../../../../shared/services/app_policy_links.dart';
import '../../../../shared/services/customer_auth_session.dart';
import '../../../../shared/services/internal_auth_session.dart';
import '../../../../shared/services/portal_resolver.dart';
import '../../../customer/services/presentation/screens/customer_services_screen.dart';
import '../../../customer/support/presentation/screens/customer_support_screen.dart';
import '../../../customer/booking/presentation/customer_booking_screen.dart';
import '../../../customer/visits/presentation/customer_visits_screen.dart';
import '../../../../shared/utils/prescription_file_picker.dart';
import '../../../../shared/widgets/customer_support_sheet.dart';
import '../../../../shared/widgets/portal_support.dart';
import '../portal_role_data.dart';

Future<_CustomerAccessContext> _loadCustomerAccessContext() async {
  final customerId = ApiService.requireAuthenticatedCustomerId();
  final results = await Future.wait<Object>([
    ApiService.getMyCustomerProfile(),
    ApiService.getCustomerMembershipBundle(customerId),
  ]);

  return _CustomerAccessContext(
    customer: results[0] as Customer,
    membership: MembershipModel.fromJson(
      Map<String, dynamic>.from(results[1] as Map),
    ),
  );
}

class PortalShell extends StatefulWidget {
  final SHIELDRole role;
  final String? sectionKey;
  final String? customerId;

  const PortalShell({
    super.key,
    required this.role,
    required this.sectionKey,
    this.customerId,
  });

  @override
  State<PortalShell> createState() => _PortalShellState();
}

class _PortalShellState extends State<PortalShell> {
  bool _isLoading = true;
  PortalRoleData? _portalData;
  PortalSectionData? _sectionData;
  String? _error;
  bool _isInternalSidebarExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant PortalShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.role != widget.role ||
        oldWidget.sectionKey != widget.sectionKey) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sectionKey = widget.sectionKey ?? 'dashboard';
      late final PortalRoleData portal;
      late final PortalSectionData data;

      if (widget.role == SHIELDRole.customer) {
        portal = portalDataForRole(widget.role);
        data = portal.sectionFor(sectionKey);
      } else if (widget.role == SHIELDRole.provider) {
        final authSession = InternalAuthSession.instance;
        if (!authSession.isInitialized) {
          await authSession.initialize();
        }
        try {
          final workspace =
              await ApiService.getProviderPlatformWorkspace() ??
              <String, dynamic>{};
          final workspaceMeta =
              workspace['workspaceMeta'] as Map<String, dynamic>? ??
              const <String, dynamic>{};
          portal = portalDataForProviderWorkspaceMeta(workspaceMeta);
          data = portal.sectionFor(sectionKey);
        } catch (_) {
          portal = portalDataForRole(widget.role);
          data = portal.sectionFor(sectionKey);
        }
      } else {
        portal = portalDataForRole(widget.role);
        data = await ApiService.getRoleSectionData(widget.role, sectionKey);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _portalData = portal;
        _sectionData = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _portalData = null;
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _toggleInternalSidebar() {
    setState(() {
      _isInternalSidebarExpanded = !_isInternalSidebarExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final portal = _portalData ?? portalDataForRole(widget.role);
    final activeKey = widget.sectionKey ?? 'dashboard';
    final isCustomer = widget.role == SHIELDRole.customer;

    if (_isLoading) {
      if (isCustomer) {
        final section = portal.sectionFor(activeKey);
        return CustomerScaffold(
          portal: portal,
          section: section,
          activeSectionKey: activeKey,
          drawerContent: _CustomerPortalNav(
            portal: portal,
            activeSectionKey: activeKey,
            inDrawer: true,
          ),
          body: const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: LoadingCard(
              title: 'Preparing your space',
              subtitle: 'Loading the latest SHIELD customer data.',
            ),
          ),
        );
      }
      return const AppPageSkeleton(showSidebar: false);
    }

    if (_error != null || _sectionData == null) {
      if (isCustomer) {
        final section = portal.sectionFor(activeKey);
        return CustomerScaffold(
          portal: portal,
          section: section,
          activeSectionKey: activeKey,
          drawerContent: _CustomerPortalNav(
            portal: portal,
            activeSectionKey: activeKey,
            inDrawer: true,
          ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: ErrorCard(
              title: 'Customer data unavailable',
              message: _error ?? 'Unknown error occurred',
              onRetry: _loadData,
            ),
          ),
        );
      }
      return Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(portal.role.label)),
            ],
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text('Error loading dashboard data', style: AppTypography.h3),
                const SizedBox(height: 8),
                Text(
                  _error ?? 'Unknown error occurred',
                  textAlign: TextAlign.center,
                  style: AppTypography.body,
                ),
                const SizedBox(height: 16),
                AppButton(text: 'Retry', onPressed: _loadData),
              ],
            ),
          ),
        ),
      );
    }

    final section = _sectionData!;

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      body: SafeArea(
        child: isCustomer
            ? LayoutBuilder(
                builder: (context, constraints) {
                  final mediaQuery = MediaQuery.of(context);
                  final viewportWidth = AppResponsive.customerViewportWidth(
                    constraints.maxWidth,
                  );

                  return Center(
                    child: SizedBox(
                      width: viewportWidth,
                      child: MediaQuery(
                        data: mediaQuery.copyWith(
                          size: Size(viewportWidth, mediaQuery.size.height),
                        ),
                        child: CustomerScaffold(
                          portal: portal,
                          section: section,
                          activeSectionKey: activeKey,
                          drawerContent: _CustomerPortalNav(
                            portal: portal,
                            activeSectionKey: activeKey,
                            inDrawer: true,
                          ),
                          body: _RoleContent(
                            portal: portal,
                            section: section,
                            customerId: widget.customerId,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isCompactScreen = constraints.maxWidth < 1024;
                  if (isCompactScreen) {
                    return Scaffold(
                      backgroundColor: AppColors.lightGray,
                      drawer: Drawer(
                        child: SafeArea(
                          child: _InternalPortalSidebar(
                            portal: portal,
                            activeSectionKey: activeKey,
                            collapsed: false,
                            inDrawer: true,
                          ),
                        ),
                      ),
                      body: Builder(
                        builder: (scaffoldContext) => _RoleContent(
                          portal: portal,
                          section: section,
                          customerId: widget.customerId,
                          onSidebarToggle: () =>
                              Scaffold.of(scaffoldContext).openDrawer(),
                          isSidebarExpanded: false,
                        ),
                      ),
                    );
                  }

                  return Row(
                    children: [
                      _InternalPortalSidebar(
                        portal: portal,
                        activeSectionKey: activeKey,
                        collapsed: !_isInternalSidebarExpanded,
                        inDrawer: false,
                      ),
                      Expanded(
                        child: Scaffold(
                          backgroundColor: AppColors.lightGray,
                          body: _RoleContent(
                            portal: portal,
                            section: section,
                            customerId: widget.customerId,
                            onSidebarToggle: _toggleInternalSidebar,
                            isSidebarExpanded: _isInternalSidebarExpanded,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _EditablePrescriptionItem {
  final String name;
  final String dosage;
  final String frequency;
  final String duration;
  final double confidence;
  final String source;
  final bool selected;
  final List<String> alternatives;

  const _EditablePrescriptionItem({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.confidence,
    required this.source,
    required this.selected,
    this.alternatives = const [],
  });

  _EditablePrescriptionItem copyWith({
    String? name,
    String? dosage,
    String? frequency,
    String? duration,
    double? confidence,
    String? source,
    bool? selected,
    List<String>? alternatives,
  }) {
    return _EditablePrescriptionItem(
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      confidence: confidence ?? this.confidence,
      source: source ?? this.source,
      selected: selected ?? this.selected,
      alternatives: alternatives ?? this.alternatives,
    );
  }
}

IconData _portalSectionIcon(String key) {
  switch (key) {
    case 'dashboard':
      return Icons.space_dashboard_outlined;
    case 'calendar':
      return Icons.event_note_outlined;
    case 'folder':
      return Icons.description_outlined;
    case 'patient':
      return Icons.groups_outlined;
    case 'profile':
      return Icons.person_outline_rounded;
    case 'prescription':
      return Icons.receipt_long_outlined;
    case 'settings':
      return Icons.settings_outlined;
    case 'queue':
      return Icons.inbox_outlined;
    case 'wallet':
    case 'wallet-ops':
      return Icons.account_balance_wallet_outlined;
    case 'services':
      return Icons.medical_services_outlined;
    case 'orders':
      return Icons.shopping_bag_outlined;
    case 'referrals':
      return Icons.account_tree_outlined;
    case 'activity':
      return Icons.timeline_outlined;
    case 'appointments':
    case 'book-appointment':
      return Icons.event_note_outlined;
    case 'documents':
    case 'reports':
      return Icons.description_outlined;
    case 'users':
      return Icons.person_outline_rounded;
    case 'membership':
    case 'membership-plans':
      return Icons.workspace_premium_outlined;
    case 'prescriptions':
      return Icons.receipt_long_outlined;
    case 'notifications':
    case 'notification-center':
      return Icons.notifications_active_outlined;
    case 'system':
      return Icons.settings_outlined;
    case 'customers':
    case 'patients':
      return Icons.groups_2_outlined;
    case 'verification':
      return Icons.verified_user_outlined;
    case 'bills':
      return Icons.request_quote_outlined;
    case 'qr-scan':
      return Icons.qr_code_scanner_rounded;
    case 'history':
      return Icons.history_rounded;
    case 'consultations':
      return Icons.local_hospital_outlined;
    case 'home-visits':
      return Icons.home_work_outlined;
    case 'treatments':
      return Icons.healing_outlined;
    case 'tasks':
      return Icons.checklist_rtl_outlined;
    case 'follow-ups':
      return Icons.call_outlined;
    case 'complaints':
      return Icons.report_problem_outlined;
    case 'campaigns':
      return Icons.campaign_outlined;
    case 'approvals':
      return Icons.fact_check_outlined;
    case 'memberships':
      return Icons.card_membership_outlined;
    case 'reversals':
      return Icons.swap_horiz_outlined;
    case 'support':
      return Icons.support_agent_outlined;
    case 'analytics':
      return Icons.insights_outlined;
    case 'credit':
      return Icons.credit_score_outlined;
    case 'retention':
      return Icons.favorite_border_rounded;
    case 'roles':
      return Icons.admin_panel_settings_outlined;
    case 'agents':
      return Icons.badge_outlined;
    case 'crm':
      return Icons.support_agent_outlined;
    case 'visits':
      return Icons.event_available_outlined;
    case 'rewards':
      return Icons.stars_outlined;
    case 'followups':
      return Icons.call_outlined;
    case 'providers':
      return Icons.local_hospital_outlined;
    case 'availability':
      return Icons.schedule_outlined;
    case 'branches':
      return Icons.apartment_outlined;
    case 'employees':
      return Icons.manage_accounts_outlined;
    case 'insights':
      return Icons.insights_outlined;
    case 'platform':
      return Icons.hub_outlined;
    case 'businesses':
      return Icons.apartment_outlined;
    case 'audit':
      return Icons.policy_outlined;
    default:
      return Icons.radio_button_checked_outlined;
  }
}

class _RoleContent extends StatelessWidget {
  final PortalRoleData portal;
  final PortalSectionData section;
  final String? customerId;
  final VoidCallback? onSidebarToggle;
  final bool isSidebarExpanded;

  const _RoleContent({
    required this.portal,
    required this.section,
    this.customerId,
    this.onSidebarToggle,
    this.isSidebarExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    late final Widget content;
    final isAdminDashboard =
        portal.role == SHIELDRole.superAdmin && section.key == 'dashboard';
    final isCustomerProfile =
        portal.role == SHIELDRole.customer && section.key == 'profile';
    final isCustomerDashboard =
        portal.role == SHIELDRole.customer && section.key == 'dashboard';
    final isCustomerMembership =
        portal.role == SHIELDRole.customer &&
        const {
          'membership',
          'membership-details',
          'membership-subscription',
          'membership-benefits',
        }.contains(section.key);
    final isCustomerPrivilegeCard =
        portal.role == SHIELDRole.customer && section.key == 'privilege-card';
    final isCustomerServices =
        portal.role == SHIELDRole.customer && section.key == 'services';
    final isCustomerBooking =
        portal.role == SHIELDRole.customer && section.key == 'book-appointment';
    final isCustomerOrders =
        portal.role == SHIELDRole.customer && section.key == 'orders';
    final isCustomerReferrals =
        portal.role == SHIELDRole.customer && section.key == 'referrals';
    final isCustomerActivity =
        portal.role == SHIELDRole.customer && section.key == 'activity';
    final isCustomerAppointments =
        portal.role == SHIELDRole.customer && section.key == 'appointments';
    final isCustomerNotifications =
        portal.role == SHIELDRole.customer && section.key == 'notifications';
    final isCustomerDocuments =
        portal.role == SHIELDRole.customer && section.key == 'documents';
    final isCustomerPrescriptions =
        portal.role == SHIELDRole.customer && section.key == 'prescriptions';
    final isCustomerWallet =
        portal.role == SHIELDRole.customer && section.key == 'wallet';
    final isCustomerWalletHistory =
        portal.role == SHIELDRole.customer && section.key == 'wallet-history';
    final isCustomerRewards =
        portal.role == SHIELDRole.customer && section.key == 'rewards';
    final isCustomerSettings =
        portal.role == SHIELDRole.customer && section.key == 'settings';
    final isCustomerAccount =
        portal.role == SHIELDRole.customer && section.key == 'account';
    final isCustomerSupport =
        portal.role == SHIELDRole.customer && section.key == 'support';
    final isCustomerStoreChange =
        portal.role == SHIELDRole.customer && section.key == 'store-change';
    final isAgentRole = portal.role == SHIELDRole.agent;
    final isProviderRole = portal.role == SHIELDRole.provider;
    final isAdminRole = portal.role == SHIELDRole.superAdmin;
    final isCardUtilization =
        (portal.role == SHIELDRole.pharmacyStaff && section.key == 'qr-scan') ||
        (portal.role == SHIELDRole.clinicStaff && section.key == 'patients') ||
        (portal.role == SHIELDRole.dentalStaff && section.key == 'patients');
    final isAdminBusinesses =
        portal.role == SHIELDRole.superAdmin && section.key == 'businesses';
    final isAdminMasterData =
        portal.role == SHIELDRole.superAdmin &&
        section.key == 'membership-plans';
    final isAdminAudit =
        portal.role == SHIELDRole.superAdmin && section.key == 'audit';
    final isCrmSection = portal.role == SHIELDRole.crmExecutive;
    final isReportsSection =
        (portal.role == SHIELDRole.superAdmin ||
            portal.role == SHIELDRole.manager) &&
        section.key == 'reports';

    if (isAdminRole) {
      content = AdminPortalWorkspace(portal: portal, section: section);
    } else if (isAdminDashboard) {
      content = const _AdminOperationsCenterView();
    } else if (isCustomerProfile) {
      content = const _CustomerProfilePortalView();
    } else if (isCustomerDashboard) {
      content = const CustomerDashboardScreen();
    } else if (isCustomerMembership) {
      content = CustomerMembershipScreen(
        focus: section.key == 'membership-subscription'
            ? MembershipFocus.subscription
            : section.key == 'membership-benefits'
            ? MembershipFocus.benefits
            : MembershipFocus.overview,
      );
    } else if (isCustomerPrivilegeCard) {
      content = const CustomerPrivilegeCardScreen();
    } else if (isCustomerServices) {
      content = const CustomerServicesScreen();
    } else if (isCustomerBooking) {
      content = const CustomerBookingScreen();
    } else if (isCustomerOrders) {
      content = const CustomerOrdersScreen();
    } else if (isCustomerReferrals) {
      content = const CustomerReferralsScreen();
    } else if (isCustomerActivity) {
      content = const CustomerActivityScreen();
    } else if (isCustomerAppointments) {
      content = _CustomerProtectedSection(
        sectionKey: section.key,
        child: const CustomerVisitsScreen(),
      );
    } else if (isCustomerNotifications) {
      content = _CustomerNotificationsView(section: section);
    } else if (isCustomerDocuments) {
      content = _CustomerProtectedSection(
        sectionKey: section.key,
        child: const CustomerDocumentsScreen(),
      );
    } else if (isCustomerPrescriptions) {
      content = _CustomerProtectedSection(
        sectionKey: section.key,
        child: const CustomerPrescriptionsScreen(),
      );
    } else if (isCustomerWallet) {
      content = const CustomerWalletScreen();
    } else if (isCustomerWalletHistory) {
      content = const CustomerWalletScreen(showFullHistory: true);
    } else if (isCustomerRewards) {
      content = const CustomerRewardPointsScreen();
    } else if (isCustomerSettings) {
      content = const _CustomerSettingsView();
    } else if (isCustomerAccount) {
      content = const CustomerAccountScreen();
    } else if (isCustomerSupport) {
      content = const CustomerSupportScreen();
    } else if (isCustomerStoreChange) {
      content = const CustomerStoreChangeScreen();
    } else if (isAgentRole) {
      content = _buildAgentModuleContent(section);
    } else if (isProviderRole) {
      content = _buildProviderModuleContent(section);
    } else if (isCardUtilization) {
      content = _EnterpriseWorkspaceView(portal: portal, section: section);
    } else if (isAdminBusinesses) {
      content = const _AdminProviderNetworkView();
    } else if (isAdminMasterData) {
      content = const _AdminMasterDataView();
    } else if (isAdminAudit) {
      content = _EnterpriseWorkspaceView(portal: portal, section: section);
    } else if (portal.role == SHIELDRole.crmExecutive &&
        section.key == 'complaints') {
      content = const CrmComplaintsScreen();
    } else if (isCrmSection) {
      content = _CrmWorkspaceView(section: section);
    } else if (isReportsSection) {
      content = _EnterpriseWorkspaceView(portal: portal, section: section);
    } else {
      content = _EnterpriseWorkspaceView(portal: portal, section: section);
    }

    final customerContentOwnsScroll =
        isCustomerDashboard ||
        isCustomerMembership ||
        isCustomerPrivilegeCard ||
        isCustomerWallet ||
        isCustomerWalletHistory ||
        isCustomerRewards ||
        isCustomerServices ||
        isCustomerBooking ||
        isCustomerAppointments ||
        isCustomerOrders ||
        isCustomerReferrals ||
        isCustomerActivity;

    if (portal.role == SHIELDRole.customer && customerContentOwnsScroll) {
      return AppPageFrame(
        maxWidth: 760,
        padding: EdgeInsets.fromLTRB(
          AppResponsive.horizontalPadding(context),
          8,
          AppResponsive.horizontalPadding(context),
          24,
        ),
        child: content,
      );
    }

    if (portal.role == SHIELDRole.customer) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppResponsive.horizontalPadding(context),
          8,
          AppResponsive.horizontalPadding(context),
          24,
        ),
        child: AppPageFrame(
          maxWidth: 760,
          padding: EdgeInsets.zero,
          child: content,
        ),
      );
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: AppPageFrame(
            maxWidth: 1240,
            padding: EdgeInsets.fromLTRB(
              AppResponsive.horizontalPadding(context),
              20,
              AppResponsive.horizontalPadding(context),
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PortalHeader(
                  portal: portal,
                  section: section,
                  onSidebarToggle: onSidebarToggle,
                  isSidebarExpanded: isSidebarExpanded,
                ),
                const SizedBox(height: 20),
                content,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProviderModuleContent(PortalSectionData section) {
    switch (section.rendererKey ?? section.moduleId ?? section.key) {
      case 'dashboard':
        return const ProviderDashboardScreen();
      case 'queue':
        return const ProviderQueueScreen();
      case 'patient-workspace':
        return const ProviderCustomersScreen();
      case 'appointments':
        return const ProviderCustomersScreen(forcedTab: 'appointments');
      case 'documents':
        return const ProviderCustomersScreen(forcedTab: 'records');
      case 'prescriptions':
        return const ProviderCustomersScreen(forcedTab: 'records');
      case 'profile':
        return const ProviderProfileScreen();
      case 'settings':
        return const ProviderSettingsScreen();
      default:
        return _EnterpriseWorkspaceView(portal: portal, section: section);
    }
  }

  Widget _buildAgentModuleContent(PortalSectionData section) {
    switch (section.rendererKey ?? section.moduleId ?? section.key) {
      case 'dashboard':
        return const AgentDashboardScreen();
      case 'customers':
        return AgentCustomersScreen(initialCustomerId: customerId);
      case 'registration':
        return const AgentRegistrationScreen();
      case 'followups':
        return const AgentFollowUpsScreen();
      case 'store-changes':
        return const AgentStoreChangeScreen();
      case 'appointments':
        return const AgentAppointmentsScreen();
      case 'referrals':
        return const AgentReferralsScreen();
      case 'documents':
        return const AgentDocumentsScreen();
      case 'notifications':
        return const AgentNotificationsScreen();
      case 'performance':
        return const AgentPerformanceScreen();
      case 'reports':
        return const AgentReportsScreen();
      case 'profile':
        return const AgentSettingsScreen(profileOnly: true);
      case 'settings':
        return const AgentSettingsScreen();
      default:
        return _EnterpriseWorkspaceView(portal: portal, section: section);
    }
  }
}

class _InternalPortalSidebar extends StatelessWidget {
  final PortalRoleData portal;
  final String activeSectionKey;
  final bool collapsed;
  final bool inDrawer;

  const _InternalPortalSidebar({
    required this.portal,
    required this.activeSectionKey,
    required this.collapsed,
    this.inDrawer = false,
  });

  @override
  Widget build(BuildContext context) {
    if (portal.role == SHIELDRole.superAdmin) {
      return _AdminPortalNav(
        portal: portal,
        activeSectionKey: activeSectionKey,
        inDrawer: inDrawer,
        collapsed: inDrawer ? false : collapsed,
      );
    }

    return _RoleRailNav(
      portal: portal,
      activeSectionKey: activeSectionKey,
      collapsed: inDrawer ? false : collapsed,
      inDrawer: inDrawer,
    );
  }
}

class _RoleRailNav extends StatelessWidget {
  const _RoleRailNav({
    required this.portal,
    required this.activeSectionKey,
    required this.collapsed,
    this.inDrawer = false,
  });

  final PortalRoleData portal;
  final String activeSectionKey;
  final bool collapsed;
  final bool inDrawer;

  @override
  Widget build(BuildContext context) {
    final width = inDrawer ? null : (collapsed ? 92.0 : 276.0);

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: inDrawer
            ? null
            : const Border(right: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              collapsed ? 16 : 18,
              20,
              collapsed ? 16 : 18,
              16,
            ),
            child: Column(
              crossAxisAlignment: collapsed
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  width: collapsed ? 44 : double.infinity,
                  padding: EdgeInsets.all(collapsed ? 10 : 14),
                  decoration: BoxDecoration(
                    color: portal.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    portal.icon,
                    color: portal.accentColor,
                    size: collapsed ? 20 : 22,
                  ),
                ),
                if (!collapsed) ...[
                  const SizedBox(height: 14),
                  Text(
                    portal.role.label,
                    style: AppTypography.body.copyWith(
                      color: AppColors.shieldNavy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    portal.regionLabel,
                    style: AppTypography.tiny.copyWith(color: AppColors.gray),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                collapsed ? 10 : 12,
                12,
                collapsed ? 10 : 12,
                12,
              ),
              children: portal.sections.map((section) {
                final isActive = section.key == activeSectionKey;
                final icon = _portalSectionIcon(section.iconKey ?? section.key);
                final targetRoute =
                    section.route ??
                    '/portal/${portal.role.routeKey}/${section.key}';
                final tile = InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.go(targetRoute),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.symmetric(
                      horizontal: collapsed ? 0 : 12,
                      vertical: collapsed ? 10 : 12,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? portal.accentColor.withValues(alpha: 0.12)
                          : AppColors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: collapsed
                        ? Center(
                            child: Icon(
                              icon,
                              size: 20,
                              color: isActive
                                  ? portal.accentColor
                                  : AppColors.darkGray,
                            ),
                          )
                        : Row(
                            children: [
                              Icon(
                                icon,
                                size: 18,
                                color: isActive
                                    ? portal.accentColor
                                    : AppColors.gray,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  section.title,
                                  style: AppTypography.small.copyWith(
                                    color: isActive
                                        ? portal.accentColor
                                        : AppColors.darkGray,
                                    fontWeight: isActive
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (section.badgeCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: portal.accentColor.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    section.badgeCount.toString(),
                                    style: AppTypography.tiny.copyWith(
                                      color: portal.accentColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                );

                if (!collapsed) {
                  return tile;
                }

                return Tooltip(message: section.title, child: tile);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PortalHeader extends StatelessWidget {
  final PortalRoleData portal;
  final PortalSectionData section;
  final VoidCallback? onSidebarToggle;
  final bool isSidebarExpanded;

  const _PortalHeader({
    required this.portal,
    required this.section,
    this.onSidebarToggle,
    this.isSidebarExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onSidebarToggle != null)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: isSidebarExpanded
                  ? 'Collapse sidebar'
                  : 'Expand sidebar',
              onPressed: onSidebarToggle,
              icon: Icon(
                isSidebarExpanded
                    ? Icons.menu_open_rounded
                    : Icons.menu_rounded,
              ),
            ),
          )
        else
          Builder(
            builder: (context) {
              final scaffold = Scaffold.maybeOf(context);
              final showMenu = scaffold?.hasDrawer ?? false;
              if (!showMenu) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: const Icon(Icons.menu),
                ),
              );
            },
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                portal.role.label,
                style: AppTypography.tiny.copyWith(
                  color: portal.accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(section.title, style: AppTypography.h2),
              const SizedBox(height: 4),
              Text(
                portal.headline,
                style: AppTypography.small.copyWith(color: AppColors.gray),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CustomerPortalNav extends StatelessWidget {
  final PortalRoleData portal;
  final String activeSectionKey;
  final bool inDrawer;

  const _CustomerPortalNav({
    required this.portal,
    required this.activeSectionKey,
    required this.inDrawer,
  });

  static const List<MapEntry<String, List<String>>> _groups = [
    MapEntry('Main', ['dashboard', 'membership', 'wallet', 'rewards']),
    MapEntry('Healthcare', [
      'services',
      'appointments',
      'documents',
    ]),
    MapEntry('Commerce', ['orders']),
    MapEntry('Engagement', ['referrals', 'activity', 'notifications']),
    MapEntry('Account', ['profile', 'settings']),
  ];

  @override
  Widget build(BuildContext context) {
    final content = FutureBuilder<_CustomerAccessContext>(
      future: _loadCustomerAccessContext(),
      builder: (context, snapshot) {
        final accessContext = snapshot.data;
        final customer = accessContext?.customer;
        final accessState = accessContext == null
            ? null
            : CustomerAccessState(
                customer: accessContext.customer,
                customerStatus: accessContext.customer.status,
                membership: accessContext.membership,
              );

        return Container(
          width: inDrawer ? null : 280,
          decoration: BoxDecoration(
            color: AppColors.white,
            border: inDrawer
                ? null
                : const Border(right: BorderSide(color: AppColors.divider)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SHIELD',
                      style: AppTypography.h3.copyWith(
                        color: portal.accentColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      (customer?.fullName.trim().isNotEmpty ?? false)
                          ? customer!.fullName
                          : 'Customer',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _customerRegionLabel(customer),
                      style: AppTypography.tiny.copyWith(color: AppColors.gray),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      accessState == null
                          ? 'Loading customer'
                          : accessState.serviceAccessEnabled
                          ? 'Membership active'
                          : 'Membership pending',
                      style: AppTypography.small.copyWith(
                        color: AppColors.darkGray,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: _groups.length,
                  separatorBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Divider(height: 1),
                  ),
                  itemBuilder: (context, groupIndex) {
                    final group = _groups[groupIndex];
                    final groupKeys = group.value;
                    final items = groupKeys
                        .map(
                          (key) => portal.sections.firstWhere(
                            (section) => section.key == key,
                            orElse: () => portal.defaultSection,
                          ),
                        )
                        .where((section) => groupKeys.contains(section.key))
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(26, 0, 20, 6),
                          child: Text(
                            group.key.toUpperCase(),
                            style: AppTypography.tiny.copyWith(
                              color: AppColors.gray,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        ...items.map((section) {
                          final isActive = section.key == activeSectionKey;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 2,
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                if (inDrawer) {
                                  Navigator.pop(context);
                                }
                                context.go(
                                  '/portal/${portal.role.routeKey}/${section.key}',
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? portal.accentColor.withValues(
                                          alpha: 0.12,
                                        )
                                      : AppColors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  section.title,
                                  style: AppTypography.body.copyWith(
                                    color: isActive
                                        ? portal.accentColor
                                        : AppColors.darkGray,
                                    fontWeight: isActive
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (inDrawer) {
      return content;
    }

    return content;
  }
}

class _AdminPortalNav extends StatelessWidget {
  const _AdminPortalNav({
    required this.portal,
    required this.activeSectionKey,
    required this.inDrawer,
    this.collapsed = false,
  });

  final PortalRoleData portal;
  final String activeSectionKey;
  final bool inDrawer;
  final bool collapsed;

  static const List<MapEntry<String, List<String>>> _groups = [
    MapEntry('Overview', ['dashboard']),
    MapEntry('Operations', [
      'customers',
      'agents',
      'crm',
      'visits',
      'documents',
    ]),
    MapEntry('Business', ['memberships', 'wallet', 'rewards', 'referrals']),
    MapEntry('Providers', ['providers', 'services', 'availability']),
    MapEntry('Organization', ['branches', 'employees', 'roles']),
    MapEntry('Analytics', ['reports', 'insights', 'audit']),
    MapEntry('System', ['notifications', 'settings', 'platform']),
  ];

  @override
  Widget build(BuildContext context) {
    final isCollapsedRail = collapsed && !inDrawer;

    return Container(
      width: inDrawer
          ? null
          : isCollapsedRail
          ? 96
          : 304,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: inDrawer
            ? null
            : const Border(right: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              isCollapsedRail ? 16 : 20,
              22,
              isCollapsedRail ? 16 : 20,
              16,
            ),
            child: Column(
              crossAxisAlignment: isCollapsedRail
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  width: isCollapsedRail ? 46 : double.infinity,
                  padding: EdgeInsets.all(isCollapsedRail ? 10 : 14),
                  decoration: BoxDecoration(
                    color: portal.accentColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: portal.accentColor.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Icon(
                    Icons.admin_panel_settings_outlined,
                    color: portal.accentColor,
                    size: isCollapsedRail ? 22 : 24,
                  ),
                ),
                if (!isCollapsedRail) ...[
                  const SizedBox(height: 14),
                  Text(
                    'SHIELD Control',
                    style: AppTypography.h3.copyWith(color: portal.accentColor),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    portal.operatorName,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Unified Admin Console',
                    style: AppTypography.small.copyWith(
                      color: AppColors.darkGray,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                isCollapsedRail ? 10 : 12,
                12,
                isCollapsedRail ? 10 : 12,
                16,
              ),
              itemCount: _groups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final group = _groups[index];
                final items = group.value
                    .map(
                      (key) => portal.sections.firstWhere(
                        (section) => section.key == key,
                        orElse: () => portal.defaultSection,
                      ),
                    )
                    .where((section) => group.value.contains(section.key))
                    .toList();

                return Container(
                  padding: EdgeInsets.fromLTRB(
                    isCollapsedRail ? 8 : 10,
                    10,
                    isCollapsedRail ? 8 : 10,
                    8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isCollapsedRail)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 2, 8, 10),
                          child: Text(
                            group.key,
                            style: AppTypography.tiny.copyWith(
                              color: AppColors.gray,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ...items.map((section) {
                        final isActive = section.key == activeSectionKey;
                        final icon = _portalSectionIcon(section.key);
                        final tile = Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              if (inDrawer) {
                                Navigator.pop(context);
                              }
                              context.go(
                                '/portal/${portal.role.routeKey}/${section.key}',
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: isCollapsedRail ? 0 : 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? portal.accentColor.withValues(alpha: 0.12)
                                    : AppColors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: isCollapsedRail
                                  ? Center(
                                      child: Icon(
                                        icon,
                                        size: 20,
                                        color: isActive
                                            ? portal.accentColor
                                            : AppColors.darkGray,
                                      ),
                                    )
                                  : Row(
                                      children: [
                                        Icon(
                                          icon,
                                          size: 18,
                                          color: isActive
                                              ? portal.accentColor
                                              : AppColors.gray,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                section.title,
                                                style: AppTypography.small
                                                    .copyWith(
                                                      color: isActive
                                                          ? portal.accentColor
                                                          : AppColors.darkGray,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                section.summary,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTypography.tiny
                                                    .copyWith(
                                                      color: AppColors.gray,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        );
                        if (!isCollapsedRail) {
                          return tile;
                        }
                        return Tooltip(message: section.title, child: tile);
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleSwitcher extends StatelessWidget {
  final PortalRoleData portal;

  const _RoleSwitcher({required this.portal});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _HeroPanel extends StatelessWidget {
  final PortalRoleData portal;
  final PortalSectionData section;

  const _HeroPanel({required this.portal, required this.section});

  @override
  Widget build(BuildContext context) {
    final primaryMetric = section.metrics.isNotEmpty
        ? section.metrics.first
        : null;
    final queueCount = section.queueItems.length;
    final recentCount = section.recentItems.length;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final stack = constraints.maxWidth < 980;
              final left = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today\'s Operations',
                    style: AppTypography.tiny.copyWith(
                      color: portal.accentColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    section.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      color: AppColors.shieldNavy,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ],
              );

              final right = Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.end,
                children: [
                  _WorkspaceMiniStat(
                    label: primaryMetric?.label ?? 'Focus',
                    value: primaryMetric?.value ?? '${section.actions.length}',
                  ),
                  _WorkspaceMiniStat(label: 'Queue', value: '$queueCount'),
                  _WorkspaceMiniStat(label: 'Updates', value: '$recentCount'),
                ],
              );

              if (stack) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [left, const SizedBox(height: 12), right],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: left),
                  const SizedBox(width: 16),
                  right,
                ],
              );
            },
          ),
          if (section.actions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: section.actions
                  .map(
                    (action) => _WorkspaceActionChip(
                      label: action,
                      accentColor: portal.accentColor,
                      onTap: () => _handleHeroAction(
                        context,
                        portal: portal,
                        section: section,
                        action: action,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

void _handleHeroAction(
  BuildContext context, {
  required PortalRoleData portal,
  required PortalSectionData section,
  required String action,
}) {
  if (portal.role == SHIELDRole.customer) {
    switch (section.key) {
      case 'dashboard':
        switch (action) {
          case 'View card':
            context.go('/portal/customer/membership');
            return;
          case 'Book visit':
            context.go('/portal/customer/appointments');
            return;
          case 'Open wallet':
            context.go('/portal/customer/wallet');
            return;
        }
      case 'membership':
        switch (action) {
          case 'Open privilege card':
            _showMembershipCardDialog(context);
            return;
          case 'View benefits':
            showPortalDetailsSheet(
              context,
              title: 'Membership benefits',
              subtitle:
                  'Founding members keep wallet-linked savings, care priority, and cross-service benefits across the SHIELD network.',
              meta: 'Membership',
              status: 'Visible',
              highlights: const [
                'Priority access to partner pharmacy and clinic offers.',
                'Digital privilege card accepted across approved SHIELD locations.',
                'Benefits stay visible in the customer membership timeline.',
              ],
            );
            return;
          case 'Download membership PDF':
            showPortalSnackBar(
              context,
              'Membership PDF prepared for download in this frontend flow.',
            );
            return;
        }
      case 'prescriptions':
        switch (action) {
          case 'Upload prescription':
            _showPrescriptionUploadPicker(context);
            return;
          case 'Open pharmacy mapping':
            context.go('/portal/customer/services');
            return;
          case 'Share PDF':
            _showSharePdfSheet(context);
            return;
        }
      case 'recharge':
        switch (action) {
          case 'Request top-up':
            _showRechargeRequestSheet(context);
            return;
          case 'View recharge methods':
            showPortalDetailsSheet(
              context,
              title: 'Recharge methods',
              subtitle:
                  'Branch-assisted cash top-up, executive-assisted manual credit, and promotional campaign credits are currently shown in the recharge flow.',
              meta: 'Wallet recharge',
              status: 'Methods',
              highlights: const [
                'Branch-assisted top-up at partner pharmacy counters.',
                'Manual SHIELD executive-assisted wallet credit request.',
                'Promotional and referral-linked recharge bonuses when available.',
              ],
            );
            return;
          case 'Track request status':
            _showRechargeStatusSheet(context);
            return;
        }
      case 'notifications':
        switch (action) {
          case 'Mark all read':
            showPortalSnackBar(
              context,
              'All local notification previews marked as read.',
            );
            return;
          case 'Filter alerts':
            _showNotificationFilterSheet(context);
            return;
          case 'Notification settings':
            context.go('/portal/customer/settings');
            return;
        }
    }
  }

  showPortalSnackBar(context, '$action is not supported in this version.');
}

void _showMembershipCardDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (context) {
      final customerFuture = ApiService.getMyCustomerProfile();
      return FutureBuilder<Customer>(
        future: customerFuture,
        builder: (context, snapshot) {
          final customer = snapshot.data;
          final fullName = (customer?.fullName.trim().isNotEmpty ?? false)
              ? customer!.fullName
              : 'Customer';
          final cardNumber =
              customer?.shieldCardNumber?.trim().isNotEmpty == true
              ? customer!.shieldCardNumber!.trim()
              : customer?.customerCode.trim().isNotEmpty == true
              ? customer!.customerCode.trim()
              : 'Card pending';
          final tierLabel = customer?.status.toUpperCase() == 'ACTIVE'
              ? 'SHIELD ACTIVE MEMBER'
              : 'SHIELD MEMBERSHIP PENDING';

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Digital privilege card', style: AppTypography.h4),
                  const SizedBox(height: 14),
                  if (snapshot.connectionState == ConnectionState.waiting) ...[
                    const LoadingCard(
                      title: 'Loading card',
                      subtitle:
                          'Fetching the latest membership and card details.',
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.shieldBlue, AppColors.shieldNavy],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tierLabel,
                            style: AppTypography.tiny.copyWith(
                              color: AppColors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            cardNumber,
                            style: AppTypography.h4.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            fullName,
                            style: AppTypography.body.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.qr_code_2_rounded,
                              size: 52,
                              color: AppColors.shieldNavy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppButton(
                      text: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      height: 40,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

String _customerRegionLabel(Customer? customer) {
  if (customer == null) {
    return 'Loading your profile';
  }

  final parts = <String>[
    if ((customer.city ?? '').trim().isNotEmpty) customer.city!.trim(),
    if ((customer.district ?? '').trim().isNotEmpty) customer.district!.trim(),
    if ((customer.state ?? '').trim().isNotEmpty) customer.state!.trim(),
  ];

  if (parts.isNotEmpty) {
    return parts.join(', ');
  }

  if (customer.customerCode.trim().isNotEmpty) {
    return customer.customerCode.trim();
  }

  return 'Authenticated SHIELD account';
}

void _showPrescriptionUploadPicker(BuildContext context) {
  context.go('/portal/customer/prescriptions');
}

void _showSharePdfSheet(BuildContext context) {
  showPortalDetailsSheet(
    context,
    title: 'Share prescription PDF',
    subtitle:
        'Send the current prescription PDF to a pharmacy, caregiver, or your own device.',
    meta: 'PDF share',
    status: 'Ready',
    highlights: const [
      'Share to WhatsApp or mail from the device.',
      'Export to another SHIELD care desk if needed.',
      'Keep the original PDF preserved in the customer document timeline.',
    ],
  );
}

void _showRechargeRequestSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recharge request', style: AppTypography.h4),
              const SizedBox(height: 8),
              Text(
                'Create a manual top-up request for branch or executive approval.',
                style: AppTypography.small.copyWith(color: AppColors.gray),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Amount',
                  hintText: 'Enter top-up amount',
                  filled: true,
                  fillColor: AppColors.lightGray,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Branch or payment note',
                  filled: true,
                  fillColor: AppColors.lightGray,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 18),
              AppButton(
                text: 'Submit Request',
                onPressed: () {
                  Navigator.pop(context);
                  showPortalSnackBar(
                    context,
                    'Recharge request submitted in frontend flow.',
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _showRechargeStatusSheet(BuildContext context) {
  showPortalDetailsSheet(
    context,
    title: 'Recharge request status',
    subtitle:
        'The latest top-up request is moving through branch validation and SHIELD executive review.',
    meta: 'Recharge timeline',
    status: 'In progress',
    highlights: const [
      'Draft created at branch counter.',
      'Cash/payment confirmation pending validation.',
      'Wallet credit posts after SHIELD executive approval.',
    ],
  );
}

void _showNotificationFilterSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filter alerts', style: AppTypography.h4),
              const SizedBox(height: 8),
              Text(
                'Choose the alert groups you want to focus on.',
                style: AppTypography.small.copyWith(color: AppColors.gray),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _StaticFilterPill(label: 'Wallet alerts'),
                  _StaticFilterPill(label: 'Appointments'),
                  _StaticFilterPill(label: 'Reports'),
                  _StaticFilterPill(label: 'Membership'),
                ],
              ),
              const SizedBox(height: 18),
              AppButton(
                text: 'Apply Filters',
                onPressed: () {
                  Navigator.pop(context);
                  showPortalSnackBar(
                    context,
                    'Notification filters applied in frontend flow.',
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _EnterpriseWorkspaceView extends StatelessWidget {
  const _EnterpriseWorkspaceView({required this.portal, required this.section});

  final PortalRoleData portal;
  final PortalSectionData section;

  @override
  Widget build(BuildContext context) {
    final monitoringItems = section.insightItems.isNotEmpty
        ? section.insightItems
        : section.recentItems;
    final activityItems = section.recentItems.isNotEmpty
        ? section.recentItems
        : monitoringItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroPanel(portal: portal, section: section),
        const SizedBox(height: 14),
        _MetricGrid(metrics: section.metrics, accentColor: portal.accentColor),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final stack = constraints.maxWidth < 1040;
            final left = Column(
              children: [
                _EnterpriseWorkPanel(
                  title: 'Today\'s Work',
                  subtitle: 'Operational items that need attention now.',
                  items: section.queueItems,
                  accentColor: portal.accentColor,
                  viewAllLabel: 'Open queue',
                ),
                const SizedBox(height: 16),
                _EnterpriseWorkPanel(
                  title: 'Approvals & Exceptions',
                  subtitle: 'Items to review, verify, or escalate next.',
                  items: monitoringItems,
                  accentColor: AppColors.warning,
                  viewAllLabel: 'Review all',
                ),
              ],
            );
            final right = _EnterpriseUtilityPanel(
              portal: portal,
              section: section,
              activityItems: activityItems,
              notificationItems: monitoringItems,
            );

            if (stack) {
              return Column(
                children: [left, const SizedBox(height: 16), right],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: left),
                const SizedBox(width: 16),
                Expanded(flex: 3, child: right),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        _EnterpriseDataTable(section: section, accentColor: portal.accentColor),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  final List<PortalMetric> metrics;
  final Color accentColor;

  const _MetricGrid({required this.metrics, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth >= 1180
            ? metrics.length.clamp(1, 6)
            : constraints.maxWidth >= 1000
            ? 4
            : constraints.maxWidth >= 640
            ? 2
            : 1;
        final aspectRatio = constraints.maxWidth >= 1180
            ? 2.9
            : constraints.maxWidth >= 1000
            ? 2.65
            : constraints.maxWidth >= 640
            ? 2.15
            : 2.9;

        return GridView.builder(
          itemCount: metrics.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return AppCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          metric.value,
                          textAlign: TextAlign.left,
                          style: AppTypography.h4.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          metric.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.small.copyWith(
                            color: AppColors.gray,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          metric.note,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.tiny.copyWith(
                            color: AppColors.darkGray,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _EnterpriseWorkPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<PortalListItem> items;
  final Color accentColor;
  final String viewAllLabel;

  const _EnterpriseWorkPanel({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.accentColor,
    required this.viewAllLabel,
  });

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.take(5).toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.h4),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTypography.small.copyWith(
                        color: AppColors.gray,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${items.length} open',
                  style: AppTypography.tiny.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...visibleItems.asMap().entries.map((entry) {
            final item = entry.value;
            final isLast = entry.key == visibleItems.length - 1;

            return Column(
              children: [
                _EnterpriseRowItem(
                  item: item,
                  accentColor: accentColor,
                  showMetaChips: false,
                ),
                if (!isLast) const Divider(height: 18),
              ],
            );
          }),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${items.length} items in this panel',
                style: AppTypography.tiny.copyWith(color: AppColors.gray),
              ),
              const Spacer(),
              Text(
                viewAllLabel,
                style: AppTypography.tiny.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color color;

  const _TagChip({required this.label, required this.color});

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
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _WorkspaceMiniStat extends StatelessWidget {
  const _WorkspaceMiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTypography.body.copyWith(
              color: AppColors.shieldNavy,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.tiny.copyWith(color: AppColors.gray),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceActionChip extends StatelessWidget {
  const _WorkspaceActionChip({
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: accentColor.withValues(alpha: 0.16)),
        ),
        child: Text(
          label,
          style: AppTypography.tiny.copyWith(
            color: accentColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _EnterpriseUtilityPanel extends StatelessWidget {
  const _EnterpriseUtilityPanel({
    required this.portal,
    required this.section,
    required this.activityItems,
    required this.notificationItems,
  });

  final PortalRoleData portal;
  final PortalSectionData section;
  final List<PortalListItem> activityItems;
  final List<PortalListItem> notificationItems;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Utility Rail', style: AppTypography.h4),
          const SizedBox(height: 4),
          Text(
            'Role-specific shortcuts, alerts, and recency without pulling focus from the work area.',
            style: AppTypography.small.copyWith(color: AppColors.gray),
          ),
          const SizedBox(height: 14),
          _EnterpriseUtilitySection(
            title: 'Quick Actions',
            child: Column(
              children: section.actions
                  .take(4)
                  .map(
                    (action) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _handleHeroAction(
                          context,
                          portal: portal,
                          section: section,
                          action: action,
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lightGray,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Text(
                            action,
                            style: AppTypography.small.copyWith(
                              color: AppColors.shieldNavy,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 14),
          _EnterpriseUtilitySection(
            title: 'Notifications',
            child: Column(
              children: notificationItems.take(3).map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _EnterpriseRowItem(
                    item: item,
                    accentColor: AppColors.warning,
                    compact: true,
                    showMetaChips: false,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          _EnterpriseUtilitySection(
            title: 'Today',
            child: Row(
              children: [
                Expanded(
                  child: _WorkspaceMiniStat(
                    label: 'Shortcuts',
                    value: '${section.actions.length}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _WorkspaceMiniStat(
                    label: 'Live alerts',
                    value: '${notificationItems.length}',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _EnterpriseUtilitySection(
            title: 'Recent Activity',
            child: Column(
              children: activityItems.take(3).map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _EnterpriseRowItem(
                    item: item,
                    accentColor: AppColors.shieldBlue,
                    compact: true,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnterpriseDataTable extends StatelessWidget {
  const _EnterpriseDataTable({
    required this.section,
    required this.accentColor,
  });

  final PortalSectionData section;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final tableRows = [
      ...section.queueItems,
      ...section.insightItems,
      ...section.recentItems,
    ].take(6).toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Enterprise Data Table', style: AppTypography.h4),
          const SizedBox(height: 4),
          Text(
            'Shared dense workspace summary for sortable operational lists and fast scanning.',
            style: AppTypography.small.copyWith(color: AppColors.gray),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TagChip(
                      label: 'Search ready',
                      color: AppColors.shieldBlue,
                    ),
                    _TagChip(label: 'Bulk actions', color: accentColor),
                    _TagChip(label: 'Export', color: AppColors.success),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${tableRows.length} rows',
                style: AppTypography.tiny.copyWith(
                  color: AppColors.gray,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(18),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStatePropertyAll(AppColors.lightGray),
                  dataRowMinHeight: 58,
                  dataRowMaxHeight: 72,
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text('Work Item')),
                    DataColumn(label: Text('Context')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Signal')),
                  ],
                  rows: tableRows
                      .map(
                        (item) => DataRow(
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 260,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.small.copyWith(
                                        color: AppColors.shieldNavy,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.tiny.copyWith(
                                        color: AppColors.gray,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                item.meta,
                                style: AppTypography.tiny.copyWith(
                                  color: AppColors.darkGray,
                                ),
                              ),
                            ),
                            DataCell(
                              _TagChip(label: item.status, color: accentColor),
                            ),
                            DataCell(
                              Text(
                                item.subtitle.length > 42 ? 'High' : 'Normal',
                                style: AppTypography.tiny.copyWith(
                                  color: item.subtitle.length > 42
                                      ? AppColors.warning
                                      : AppColors.success,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnterpriseUtilitySection extends StatelessWidget {
  const _EnterpriseUtilitySection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.small.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _EnterpriseRowItem extends StatelessWidget {
  const _EnterpriseRowItem({
    required this.item,
    required this.accentColor,
    this.compact = false,
    this.showMetaChips = true,
  });

  final PortalListItem item;
  final Color accentColor;
  final bool compact;
  final bool showMetaChips;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: compact ? 8 : 10,
          height: compact ? 8 : 10,
          margin: const EdgeInsets.only(top: 5),
          decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: AppTypography.small.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item.status,
                    style: AppTypography.tiny.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                item.subtitle,
                maxLines: compact ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.small.copyWith(
                  color: AppColors.darkGray,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              if (showMetaChips)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TagChip(label: item.meta, color: AppColors.gray),
                    _TagChip(label: item.status, color: accentColor),
                  ],
                )
              else
                Text(
                  item.meta,
                  style: AppTypography.tiny.copyWith(color: AppColors.gray),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CrmWorkspaceView extends StatelessWidget {
  const _CrmWorkspaceView({required this.section});

  final PortalSectionData section;

  @override
  Widget build(BuildContext context) {
    const accentColor = AppColors.shieldNavy;
    final recentItems = section.recentItems.isNotEmpty
        ? section.recentItems
        : section.queueItems;
    final insightItems = section.insightItems.isNotEmpty
        ? section.insightItems
        : recentItems;
    final workRows = [
      ...section.queueItems,
      ...recentItems,
      ...insightItems,
    ].take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final stack = constraints.maxWidth < 980;
                  final intro = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _crmHeadlineFor(section),
                        style: AppTypography.h3.copyWith(
                          color: AppColors.shieldNavy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        section.summary,
                        style: AppTypography.small.copyWith(
                          color: AppColors.gray,
                          height: 1.35,
                        ),
                      ),
                    ],
                  );

                  final search = Container(
                    constraints: const BoxConstraints(maxWidth: 340),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        icon: const Icon(Icons.search, color: AppColors.gray),
                        hintText: _crmSearchHintFor(section),
                      ),
                    ),
                  );

                  final filters = Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      const _AdminFilterPill(
                        label: 'Today',
                        icon: Icons.today_outlined,
                        active: true,
                      ),
                      _AdminFilterPill(
                        label: _crmFocusLabelFor(section),
                        icon: Icons.task_alt_outlined,
                      ),
                      const _AdminFilterPill(
                        label: 'Retention',
                        icon: Icons.favorite_border_rounded,
                      ),
                      const _AdminFilterPill(
                        label: 'Escalations',
                        icon: Icons.flag_outlined,
                      ),
                    ],
                  );

                  if (stack) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        intro,
                        const SizedBox(height: 16),
                        search,
                        const SizedBox(height: 12),
                        filters,
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: intro),
                          const SizedBox(width: 16),
                          search,
                        ],
                      ),
                      const SizedBox(height: 14),
                      filters,
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _MetricGrid(metrics: section.metrics, accentColor: accentColor),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final stack = constraints.maxWidth < 1040;
            final left = Column(
              children: [
                _EnterpriseWorkPanel(
                  title: _crmPrimaryPanelTitleFor(section),
                  subtitle: _crmPrimaryPanelSubtitleFor(section),
                  items: section.queueItems,
                  accentColor: accentColor,
                  viewAllLabel: _crmPrimaryActionFor(section),
                ),
                const SizedBox(height: 16),
                _EnterpriseWorkPanel(
                  title: _crmSecondaryPanelTitleFor(section),
                  subtitle: _crmSecondaryPanelSubtitleFor(section),
                  items: insightItems,
                  accentColor: AppColors.warning,
                  viewAllLabel: 'Review insights',
                ),
              ],
            );

            final right = AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CRM Utility Rail', style: AppTypography.h4),
                  const SizedBox(height: 4),
                  Text(
                    'Keep next actions, quick context, and engagement signals visible without pulling attention away from active work.',
                    style: AppTypography.small.copyWith(color: AppColors.gray),
                  ),
                  const SizedBox(height: 14),
                  _EnterpriseUtilitySection(
                    title: 'Quick Actions',
                    child: Column(
                      children: section.actions
                          .take(4)
                          .map(
                            (action) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.lightGray,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.divider),
                                ),
                                child: Text(
                                  action,
                                  style: AppTypography.small.copyWith(
                                    color: AppColors.shieldNavy,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _EnterpriseUtilitySection(
                    title: 'Today',
                    child: Row(
                      children: [
                        Expanded(
                          child: _WorkspaceMiniStat(
                            label: 'Due now',
                            value: section.queueItems.length.toString(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _WorkspaceMiniStat(
                            label: 'Recent notes',
                            value: recentItems.length.toString(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _EnterpriseUtilitySection(
                    title: 'Recent Notes',
                    child: Column(
                      children: recentItems
                          .take(3)
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _EnterpriseRowItem(
                                item: item,
                                accentColor: AppColors.shieldBlue,
                                compact: true,
                                showMetaChips: false,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            );

            if (stack) {
              return Column(
                children: [left, const SizedBox(height: 16), right],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: left),
                const SizedBox(width: 16),
                Expanded(flex: 3, child: right),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_crmTableTitleFor(section), style: AppTypography.h4),
              const SizedBox(height: 4),
              Text(
                'Dense CRM worklist for faster scanning, triage, and ownership checks.',
                style: AppTypography.small.copyWith(color: AppColors.gray),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: const WidgetStatePropertyAll(
                        AppColors.lightGray,
                      ),
                      dataRowMinHeight: 58,
                      dataRowMaxHeight: 72,
                      columnSpacing: 24,
                      columns: const [
                        DataColumn(label: Text('Member / Work Item')),
                        DataColumn(label: Text('Context')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Priority')),
                      ],
                      rows: workRows
                          .map(
                            (item) => DataRow(
                              cells: [
                                DataCell(
                                  SizedBox(
                                    width: 280,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.small.copyWith(
                                            color: AppColors.shieldNavy,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.subtitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.tiny.copyWith(
                                            color: AppColors.gray,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    item.meta,
                                    style: AppTypography.tiny.copyWith(
                                      color: AppColors.darkGray,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  _TagChip(
                                    label: item.status,
                                    color: accentColor,
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    _crmPriorityFor(item.status),
                                    style: AppTypography.tiny.copyWith(
                                      color:
                                          _crmPriorityFor(item.status) == 'High'
                                          ? AppColors.warning
                                          : AppColors.success,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _crmHeadlineFor(PortalSectionData section) {
  switch (section.key) {
    case 'customers':
      return 'CRM Customer Desk';
    case 'tasks':
      return 'CRM Task Board';
    case 'follow-ups':
      return 'CRM Follow-Up Queue';
    case 'complaints':
      return 'CRM Complaint Resolution';
    case 'campaigns':
      return 'CRM Campaign Desk';
    default:
      return 'CRM Operations Center';
  }
}

String _crmSearchHintFor(PortalSectionData section) {
  switch (section.key) {
    case 'customers':
      return 'Search member, branch, or segment';
    case 'tasks':
      return 'Search task, owner, or locality';
    case 'follow-ups':
      return 'Search callback, member, or next date';
    case 'complaints':
      return 'Search complaint, branch, or issue';
    case 'campaigns':
      return 'Search campaign, audience, or branch';
    default:
      return 'Search member, issue, or engagement task';
  }
}

String _crmFocusLabelFor(PortalSectionData section) {
  switch (section.key) {
    case 'customers':
      return 'At-risk members';
    case 'tasks':
      return 'Due tasks';
    case 'follow-ups':
      return 'Call backs';
    case 'complaints':
      return 'Open cases';
    case 'campaigns':
      return 'Audience';
    default:
      return 'Follow-ups';
  }
}

String _crmPrimaryPanelTitleFor(PortalSectionData section) {
  switch (section.key) {
    case 'customers':
      return 'Priority Members';
    case 'tasks':
      return 'Today\'s Tasks';
    case 'follow-ups':
      return 'Today\'s Follow-Ups';
    case 'complaints':
      return 'Open Complaints';
    case 'campaigns':
      return 'Active Campaign Work';
    default:
      return 'Today\'s Work';
  }
}

String _crmPrimaryPanelSubtitleFor(PortalSectionData section) {
  switch (section.key) {
    case 'customers':
      return 'Members who need CRM attention, activation, or retention handling.';
    case 'tasks':
      return 'Assigned CRM work items that should be cleared during this shift.';
    case 'follow-ups':
      return 'Callbacks and unresolved journeys scheduled for immediate outreach.';
    case 'complaints':
      return 'Cases needing acknowledgment, assignment, or direct recovery action.';
    case 'campaigns':
      return 'Outreach drafts, audience prep, and launch-ready campaign tasks.';
    default:
      return 'The engagement desk queue that needs action before end of day.';
  }
}

String _crmPrimaryActionFor(PortalSectionData section) {
  switch (section.key) {
    case 'customers':
      return 'Open customer list';
    case 'tasks':
      return 'Open tasks';
    case 'follow-ups':
      return 'Open follow-ups';
    case 'complaints':
      return 'Open complaints';
    case 'campaigns':
      return 'Open campaigns';
    default:
      return 'Open CRM queue';
  }
}

String _crmSecondaryPanelTitleFor(PortalSectionData section) {
  switch (section.key) {
    case 'campaigns':
      return 'Message & Segment Signals';
    case 'complaints':
      return 'Resolution Insights';
    default:
      return 'Retention & Insight Signals';
  }
}

String _crmSecondaryPanelSubtitleFor(PortalSectionData section) {
  switch (section.key) {
    case 'campaigns':
      return 'What the audience and recent performance are telling the CRM desk.';
    case 'complaints':
      return 'Patterns that explain where service-recovery work is getting stuck.';
    default:
      return 'Behavior patterns and engagement clues that guide the next CRM action.';
  }
}

String _crmTableTitleFor(PortalSectionData section) {
  switch (section.key) {
    case 'customers':
      return 'CRM Member Worklist';
    case 'tasks':
      return 'CRM Task Worklist';
    case 'follow-ups':
      return 'CRM Callback Worklist';
    case 'complaints':
      return 'CRM Complaint Worklist';
    case 'campaigns':
      return 'CRM Campaign Worklist';
    default:
      return 'CRM Operations Worklist';
  }
}

String _crmPriorityFor(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('urgent') ||
      normalized.contains('open') ||
      normalized.contains('due') ||
      normalized.contains('assigned')) {
    return 'High';
  }
  if (normalized.contains('ready') ||
      normalized.contains('scheduled') ||
      normalized.contains('queued')) {
    return 'Medium';
  }
  return 'Normal';
}

class _CustomerProfilePortalView extends StatefulWidget {
  const _CustomerProfilePortalView();

  @override
  State<_CustomerProfilePortalView> createState() =>
      _CustomerProfilePortalViewState();
}

class _CustomerProfilePortalViewState
    extends State<_CustomerProfilePortalView> {
  static const List<String> _genderOptions = ['Male', 'Female', 'Other'];
  static const List<String> _bloodGroupOptions = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _error;
  String? _selectedGender;
  String? _selectedBloodGroup;
  DateTime _selectedDob = DateTime(DateTime.now().year - 25, 1, 1);
  Customer? _customer;
  Membership? _membership;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final customerId = ApiService.requireAuthenticatedCustomerId();
      final results = await Future.wait<Object?>([
        ApiService.getMyCustomerProfile(),
        _loadProfileMembership(customerId),
      ]);
      final customer = results[0]! as Customer;
      if (!mounted) return;
      _hydrateForm(customer);
      setState(() {
        _customer = customer;
        _membership = results[1] as Membership?;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Profile details could not be loaded. Please retry.';
        _isLoading = false;
      });
    }
  }

  Future<Membership?> _loadProfileMembership(String customerId) async {
    try {
      final bundle = await ApiService.getCustomerMembershipBundle(customerId);
      return MembershipModel.fromJson(bundle);
    } catch (_) {
      return null;
    }
  }

  void _hydrateForm(Customer customer) {
    _firstNameController.text = customer.firstName;
    _lastNameController.text = customer.lastName;
    _emailController.text = customer.email ?? '';
    _addressLine1Controller.text = customer.addressLine1 ?? '';
    _addressLine2Controller.text = customer.addressLine2 ?? '';
    _cityController.text = customer.city ?? '';
    _districtController.text = customer.district ?? '';
    _stateController.text = customer.state ?? '';
    _pincodeController.text = customer.pincode ?? '';
    _selectedGender = _normalizeDropdownValue(customer.gender, _genderOptions);
    _selectedBloodGroup = _normalizeDropdownValue(
      customer.bloodGroup,
      _bloodGroupOptions,
    );
    _selectedDob = customer.dob ?? DateTime(DateTime.now().year - 25, 1, 1);
  }

  String? _normalizeDropdownValue(String? value, List<String> options) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    for (final option in options) {
      if (option.toLowerCase() == normalized.toLowerCase()) {
        return option;
      }
    }

    return null;
  }

  Future<void> _saveProfile() async {
    if (_customer == null || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final savedCustomer = await ApiService.updateMyCustomerProfile(
        _customer!.copyWith(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _normalizeOptional(_emailController.text),
          dob: _selectedDob,
          gender: _selectedGender,
          addressLine1: _normalizeOptional(_addressLine1Controller.text),
          addressLine2: _normalizeOptional(_addressLine2Controller.text),
          city: _normalizeOptional(_cityController.text),
          district: _normalizeOptional(_districtController.text),
          state: _normalizeOptional(_stateController.text),
          pincode: _normalizeOptional(_pincodeController.text),
          bloodGroup: _selectedBloodGroup,
        ),
      );

      if (!mounted) return;
      _hydrateForm(savedCustomer);
      setState(() {
        _customer = savedCustomer;
        _isEditing = false;
        _isSaving = false;
      });
      showPortalSnackBar(context, 'Customer profile updated successfully.');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = 'Profile changes could not be saved. Please retry.';
      });
      showPortalSnackBar(
        context,
        'Profile update failed. Check backend connectivity and try again.',
      );
    }
  }

  String? _normalizeOptional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not added';
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _calculateAge(DateTime? dob) {
    if (dob == null) return 'N/A';
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return '$age yrs';
  }

  String? _requiredValidator(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  bool _hasUnsavedChanges() {
    final customer = _customer;
    if (customer == null) return false;
    return _firstNameController.text.trim() != customer.firstName ||
        _lastNameController.text.trim() != customer.lastName ||
        _normalizeOptional(_emailController.text) != customer.email ||
        _normalizeOptional(_addressLine1Controller.text) !=
            customer.addressLine1 ||
        _normalizeOptional(_addressLine2Controller.text) !=
            customer.addressLine2 ||
        _normalizeOptional(_cityController.text) != customer.city ||
        _normalizeOptional(_districtController.text) != customer.district ||
        _normalizeOptional(_stateController.text) != customer.state ||
        _normalizeOptional(_pincodeController.text) != customer.pincode ||
        _selectedGender !=
            _normalizeDropdownValue(customer.gender, _genderOptions) ||
        _selectedBloodGroup !=
            _normalizeDropdownValue(customer.bloodGroup, _bloodGroupOptions) ||
        _selectedDob != customer.dob;
  }

  Future<bool> _confirmDiscardChanges() async {
    if (!_hasUnsavedChanges()) return true;
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Discard profile changes?'),
            content: const Text(
              'Your unsaved personal and address updates will be lost.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Keep editing'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Discard'),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _initials(Customer customer) {
    final values = [customer.firstName, customer.lastName]
        .where((value) => value.trim().isNotEmpty)
        .map((value) => value.trim().characters.first.toUpperCase());
    return values.join().isEmpty ? 'S' : values.join();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AppPortalSectionSkeleton(
        showHero: true,
        statCards: 2,
        listItems: 3,
      );
    }

    if (_error != null && _customer == null) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profile unavailable', style: AppTypography.h4),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: AppTypography.small.copyWith(color: AppColors.gray),
            ),
            const SizedBox(height: 16),
            AppButton(text: 'Retry', onPressed: _loadProfile),
          ],
        ),
      );
    }

    final customer = _customer!;
    final membership = _membership;
    final address = [
      customer.addressLine1,
      customer.addressLine2,
      customer.city,
      customer.district,
      customer.state,
      customer.pincode,
    ].where((part) => part != null && part.trim().isNotEmpty).join(', ');

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.shieldBlue, AppColors.shieldNavy],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.white.withValues(alpha: 0.16),
                          child: Text(
                            _initials(customer),
                            style: AppTypography.body.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          customer.customerCode,
                          style: AppTypography.small.copyWith(
                            color: AppColors.white.withValues(alpha: 0.84),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        membership == null
                            ? 'MEMBERSHIP UNAVAILABLE'
                            : membership.isActive
                            ? 'MEMBERSHIP ACTIVE'
                            : 'MEMBERSHIP PENDING',
                        style: AppTypography.tiny.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  customer.fullName.toUpperCase(),
                  softWrap: true,
                  style: AppTypography.h4.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ProfileSummaryChip(
                      label: 'Verified • ${customer.mobile}',
                      icon: Icons.phone_iphone_outlined,
                    ),
                    _ProfileSummaryChip(
                      label: membership == null
                          ? 'Membership unavailable'
                          : membership.customerCode.isEmpty
                          ? 'Membership number pending'
                          : 'Member ID ${membership.customerCode}',
                      icon: Icons.badge_outlined,
                    ),
                    _ProfileSummaryChip(
                      label: customer.bloodGroup ?? 'Blood group pending',
                      icon: Icons.bloodtype_outlined,
                    ),
                    _ProfileSummaryChip(
                      label: _calculateAge(customer.dob),
                      icon: Icons.cake_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _HeroActionGrid(
                  actions: [
                    _HeroActionGridItem(
                      label: _isEditing ? 'Cancel changes' : 'Edit details',
                      onTap: () async {
                        if (_isEditing) {
                          if (!await _confirmDiscardChanges()) return;
                          _hydrateForm(customer);
                        }
                        setState(() {
                          _isEditing = !_isEditing;
                          _error = null;
                        });
                      },
                    ),
                    _HeroActionGridItem(
                      label: membership?.isActive == true
                          ? 'View member ID'
                          : 'Membership status',
                      onTap: () => context.go('/portal/customer/membership'),
                    ),
                    _HeroActionGridItem(
                      label: 'Open settings',
                      onTap: () => context.go('/portal/customer/settings'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Identity', style: AppTypography.h4)),
                    if (_isEditing)
                      Text(
                        'Only customer-safe fields are editable here.',
                        style: AppTypography.tiny.copyWith(
                          color: AppColors.gray,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isEditing) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _CustomerProfileTextField(
                          controller: _firstNameController,
                          label: 'First name',
                          validator: _requiredValidator,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CustomerProfileTextField(
                          controller: _lastNameController,
                          label: 'Last name',
                          validator: _requiredValidator,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ShieldDateInputField(
                    label: 'Date of birth',
                    initialDate: _selectedDob,
                    maxDate: DateTime.now(),
                    onChanged: (value) => _selectedDob = value,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _CustomerProfileDropdown(
                          label: 'Gender',
                          value: _selectedGender,
                          items: _genderOptions,
                          onChanged: (value) {
                            setState(() {
                              _selectedGender = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CustomerProfileDropdown(
                          label: 'Blood group',
                          value: _selectedBloodGroup,
                          items: _bloodGroupOptions,
                          onChanged: (value) {
                            setState(() {
                              _selectedBloodGroup = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  _ProfileFactRow(
                    label: 'Date of birth',
                    value:
                        '${_formatDate(customer.dob)}${customer.dob != null ? ' • ${_calculateAge(customer.dob)}' : ''}',
                  ),
                  const Divider(height: 24),
                  _ProfileFactRow(
                    label: 'Gender',
                    value: customer.gender ?? 'Not added',
                  ),
                  const Divider(height: 24),
                  _ProfileFactRow(
                    label: 'Blood group',
                    value: customer.bloodGroup ?? 'Not added',
                  ),
                  const Divider(height: 24),
                  _ProfileFactRow(
                    label: 'Aadhaar',
                    value: customer.aadhaarNumber.length >= 4
                        ? '****${customer.aadhaarNumber.substring(customer.aadhaarNumber.length - 4)}'
                        : customer.aadhaarNumber,
                  ),
                  const Divider(height: 24),
                  _ProfileFactRow(
                    label: 'Agent code',
                    value: customer.agentCode ?? 'Not available',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Contact and address', style: AppTypography.h4),
                const SizedBox(height: 16),
                if (_isEditing) ...[
                  _CustomerProfileTextField(
                    controller: _emailController,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  _CustomerProfileTextField(
                    controller: _addressLine1Controller,
                    label: 'Address line 1',
                  ),
                  const SizedBox(height: 12),
                  _CustomerProfileTextField(
                    controller: _addressLine2Controller,
                    label: 'Address line 2',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _CustomerProfileTextField(
                          controller: _cityController,
                          label: 'City',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CustomerProfileTextField(
                          controller: _districtController,
                          label: 'District',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _CustomerProfileTextField(
                          controller: _stateController,
                          label: 'State',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CustomerProfileTextField(
                          controller: _pincodeController,
                          label: 'Pincode',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            final trimmed = value?.trim() ?? '';
                            if (trimmed.isEmpty) return null;
                            if (trimmed.length < 6) {
                              return 'Enter a valid pincode';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  _ProfileFactRow(label: 'Mobile', value: customer.mobile),
                  const Divider(height: 24),
                  _ProfileFactRow(
                    label: 'Email',
                    value: customer.email ?? 'Not added',
                  ),
                  const Divider(height: 24),
                  _ProfileFactRow(
                    label: 'Address',
                    value: address.isEmpty ? 'Address not added' : address,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          _CustomerAlternativeContactsCard(
            customerId: customer.id,
            primaryMobile: customer.mobile,
          ),
          const SizedBox(height: 14),
          _CustomerAccountCapabilitiesCard(
            onEditProfile: () {
              if (!_isEditing) {
                setState(() => _isEditing = true);
              }
            },
            onOpenSettings: () => context.go('/portal/customer/settings'),
            onOpenAccount: () => context.go('/portal/customer/account'),
            onGetSupport: () => showCustomerSupportSheet(
              context,
              type: SupportSheetType.contact,
            ),
            onSignOut: () => _confirmCustomerSignOut(context),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(
              _error!,
              style: AppTypography.small.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: _isEditing
                      ? (_isSaving ? 'Saving...' : 'Save profile')
                      : 'Refresh details',
                  onPressed: _isSaving
                      ? null
                      : (_isEditing ? _saveProfile : _loadProfile),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerAlternativeContactsCard extends StatefulWidget {
  const _CustomerAlternativeContactsCard({
    required this.customerId,
    required this.primaryMobile,
  });

  final String customerId;
  final String primaryMobile;

  @override
  State<_CustomerAlternativeContactsCard> createState() =>
      _CustomerAlternativeContactsCardState();
}

class _CustomerAlternativeContactsCardState
    extends State<_CustomerAlternativeContactsCard> {
  late Future<List<Map<String, dynamic>>> _contactsFuture;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void didUpdateWidget(covariant _CustomerAlternativeContactsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customerId != widget.customerId) _loadContacts();
  }

  void _loadContacts() {
    _contactsFuture = ApiService.getAlternativeCustomerContacts(
      widget.customerId,
    );
  }

  Future<void> _addContact() async {
    final nameController = TextEditingController();
    final mobileController = TextEditingController();
    final relationshipController = TextEditingController();
    String? mobileError;
    final values = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add alternative contact'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Name (optional)'),
              ),
              TextField(
                controller: mobileController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Mobile number',
                  errorText: mobileError,
                ),
              ),
              TextField(
                controller: relationshipController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Relationship (optional)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final mobile = mobileController.text.trim();
                final normalizedMobile = mobile.replaceAll(RegExp(r'\D'), '');
                if (normalizedMobile.length != 10) {
                  setDialogState(
                    () => mobileError = 'Enter a valid 10-digit mobile number',
                  );
                  return;
                }
                final primaryDigits = widget.primaryMobile.replaceAll(
                  RegExp(r'\D'),
                  '',
                );
                final primaryLocalMobile = primaryDigits.length > 10
                    ? primaryDigits.substring(primaryDigits.length - 10)
                    : primaryDigits;
                if (normalizedMobile == primaryLocalMobile) {
                  setDialogState(
                    () => mobileError =
                        'Use a number different from the primary sign-in number',
                  );
                  return;
                }
                Navigator.pop(context, {
                  'mobile': normalizedMobile,
                  'name': nameController.text.trim(),
                  'relationship': relationshipController.text.trim(),
                });
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    mobileController.dispose();
    relationshipController.dispose();
    if (!mounted || values == null) return;

    try {
      await ApiService.saveAlternativeCustomerContact(
        widget.customerId,
        values,
      );
      if (!mounted) return;
      setState(_loadContacts);
      showPortalSnackBar(context, 'Alternative contact saved.');
    } catch (_) {
      if (!mounted) return;
      showPortalSnackBar(
        context,
        'Alternative contact could not be saved. Please check the number and retry.',
      );
    }
  }

  Future<void> _removeContact(Map<String, dynamic> contact) async {
    final contactId = contact['id']?.toString();
    if (contactId == null || contactId.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove alternative contact?'),
        content: Text(
          'Remove ${contact['name']?.toString().trim().isNotEmpty == true ? contact['name'] : 'this contact'} from your profile?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    try {
      await ApiService.removeAlternativeCustomerContact(
        widget.customerId,
        contactId,
      );
      if (!mounted) return;
      setState(_loadContacts);
      showPortalSnackBar(context, 'Alternative contact removed.');
    } catch (_) {
      if (!mounted) return;
      showPortalSnackBar(
        context,
        'Alternative contact could not be removed. Please retry.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _contactsFuture,
        builder: (context, snapshot) {
          final contacts = snapshot.data ?? const <Map<String, dynamic>>[];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Alternative contacts',
                      style: AppTypography.h4,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addContact,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Alternative contacts do not become SHIELD sign-in identities.',
                style: AppTypography.small.copyWith(color: AppColors.gray),
              ),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LinearProgressIndicator(),
                )
              else if (snapshot.hasError)
                TextButton(
                  onPressed: () => setState(_loadContacts),
                  child: const Text('Retry loading contacts'),
                )
              else if (contacts.isEmpty)
                Text(
                  'No alternative contacts added.',
                  style: AppTypography.small.copyWith(color: AppColors.gray),
                )
              else
                ...contacts.map(
                  (contact) => Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ProfileFactRow(
                            label:
                                contact['name']?.toString().trim().isNotEmpty ==
                                    true
                                ? contact['name'].toString()
                                : 'Alternative contact',
                            value:
                                [
                                      contact['mobile']?.toString(),
                                      contact['relation']?.toString(),
                                    ]
                                    .whereType<String>()
                                    .where((value) => value.trim().isNotEmpty)
                                    .join(' • '),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove contact',
                          onPressed: () => _removeContact(contact),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CustomerAccountCapabilitiesCard extends StatelessWidget {
  const _CustomerAccountCapabilitiesCard({
    required this.onEditProfile,
    required this.onOpenSettings,
    required this.onOpenAccount,
    required this.onGetSupport,
    required this.onSignOut,
  });

  final VoidCallback onEditProfile;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenAccount;
  final VoidCallback onGetSupport;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profile and family', style: AppTypography.h4),
          const SizedBox(height: 6),
          Text(
            'Manage the information SHIELD currently supports for this account.',
            style: AppTypography.small.copyWith(color: AppColors.gray),
          ),
          const SizedBox(height: 14),
          _CompactSettingAction(
            icon: Icons.home_outlined,
            title: 'Address details',
            subtitle: 'Update your current address in personal details',
            onTap: onOpenAccount,
          ),
          _CompactSettingAction(
            icon: Icons.location_on_outlined,
            title: 'Address book',
            subtitle: 'Manage saved addresses and your default address.',
            onTap: onOpenAccount,
          ),
          _CompactSettingAction(
            icon: Icons.group_outlined,
            title: 'Family members',
            subtitle: 'Manage family members linked to your account.',
            onTap: onOpenAccount,
          ),
          _CompactSettingAction(
            icon: Icons.emergency_outlined,
            title: 'Emergency contacts',
            subtitle: 'Manage emergency and alternative contacts.',
            onTap: onOpenAccount,
          ),
          _CompactSettingAction(
            icon: Icons.local_pharmacy_outlined,
            title: 'Preferred pharmacy',
            subtitle: 'Choose the pharmacy you prefer to use.',
            onTap: onOpenAccount,
          ),
          const SizedBox(height: 14),
          Text('Account and support', style: AppTypography.h4),
          const SizedBox(height: 6),
          _CompactSettingAction(
            icon: Icons.shield_outlined,
            title: 'Privacy and security',
            subtitle: 'Review available privacy and account controls',
            onTap: onOpenSettings,
          ),
          _CompactSettingAction(
            icon: Icons.tune_rounded,
            title: 'Settings',
            subtitle: 'Support, policy, and available device preferences',
            onTap: onOpenSettings,
          ),
          _CompactSettingAction(
            icon: Icons.help_outline,
            title: 'Help and support',
            subtitle: 'Send a membership, service, or app-support request',
            onTap: onGetSupport,
          ),
          _CompactSettingAction(
            icon: Icons.logout_rounded,
            title: 'Sign out',
            subtitle: 'Clear the current customer session on this device',
            destructive: true,
            onTap: onSignOut,
          ),
        ],
      ),
    );
  }
}

class _CustomerFaqItem extends StatelessWidget {
  const _CustomerFaqItem({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: AppTypography.body.copyWith(
            color: AppColors.shieldNavy,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(answer, style: AppTypography.small),
      ],
    );
  }
}

class _CustomerMembershipPortalView extends StatefulWidget {
  const _CustomerMembershipPortalView();

  @override
  State<_CustomerMembershipPortalView> createState() =>
      _CustomerMembershipPortalViewState();
}

class _CustomerMembershipPortalViewState
    extends State<_CustomerMembershipPortalView> {
  late Future<List<dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = Future.wait([
      ApiService.getMyCustomerProfile(),
      ApiService.getCustomerMembership(
        ApiService.requireAuthenticatedCustomerId(),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppPortalSectionSkeleton(
            showHero: true,
            statCards: 3,
            listItems: 4,
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return AppCard(
            child: Text(
              'Membership details unavailable',
              style: AppTypography.h4,
            ),
          );
        }

        final customer = snapshot.data![0] as Customer;
        final membership = snapshot.data![1] as Membership;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF14213D), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'SHIELD',
                          style: AppTypography.h4.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          membership.isActive ? 'ACTIVE' : 'INACTIVE',
                          style: AppTypography.tiny.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    customer.fullName.toUpperCase(),
                    style: AppTypography.h4.copyWith(color: AppColors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    membership.tierLabel.toUpperCase(),
                    style: AppTypography.small.copyWith(
                      color: AppColors.white.withValues(alpha: 0.84),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _ProfileSummaryChip(
                        label: 'ID ${membership.customerCode}',
                        icon: Icons.badge_outlined,
                        dark: true,
                      ),
                      _ProfileSummaryChip(
                        label:
                            'Valid till ${DateFormat('dd MMM yyyy').format(membership.endDate)}',
                        icon: Icons.event_outlined,
                        dark: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _HeroActionGrid(
                    actions: [
                      _HeroActionGridItem(
                        label: 'Open wallet',
                        onTap: () => context.go('/portal/customer/wallet'),
                      ),
                      _HeroActionGridItem(
                        label: 'Open profile',
                        onTap: () => context.go('/portal/customer/profile'),
                      ),
                      _HeroActionGridItem(
                        label: 'Book visit',
                        onTap: () =>
                            context.go('/portal/customer/appointments'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) => GridView.count(
                crossAxisCount: 1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: constraints.maxWidth >= 420 ? 3.1 : 2.7,
                children: [
                  _KpiTile(
                    title: 'Tier',
                    value: membership.tierLabel.replaceAll(' Member', ''),
                    icon: Icons.badge_outlined,
                    color: AppColors.shieldBlue,
                  ),
                  _KpiTile(
                    title: 'Earned',
                    value:
                        '₹${membership.totalEarnedCredits.toStringAsFixed(0)}',
                    icon: Icons.savings_outlined,
                    color: AppColors.shieldGreen,
                  ),
                  _KpiTile(
                    title: 'Redeemed',
                    value:
                        '₹${membership.totalRedeemedCredits.toStringAsFixed(0)}',
                    icon: Icons.redeem_outlined,
                    color: AppColors.warning,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Benefits', style: AppTypography.h4),
            const SizedBox(height: 12),
            ...[
              'Digital privilege card with QR verification',
              '${membership.tierLabel} service access across SHIELD care points',
              'Wallet-linked membership benefits calculated from the live ledger',
              'Priority support for onboarding and membership exceptions',
            ].map(
              (benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.shieldGreen,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          benefit,
                          style: AppTypography.body.copyWith(
                            color: AppColors.darkGray,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({
    required this.label,
    required this.onTap,
    this.width,
  });

  final String label;
  final VoidCallback onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: width,
          constraints: const BoxConstraints(minHeight: 38),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.small.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroActionGridItem {
  const _HeroActionGridItem({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;
}

class _HeroActionGrid extends StatelessWidget {
  const _HeroActionGrid({required this.actions});

  final List<_HeroActionGridItem> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final singleWidth = constraints.maxWidth;
        final twoColumnWidth = constraints.maxWidth >= 280
            ? (constraints.maxWidth - 12) / 2
            : singleWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            for (var index = 0; index < actions.length; index++)
              _HeroActionButton(
                label: actions[index].label,
                width: actions.length.isOdd && index == actions.length - 1
                    ? singleWidth
                    : twoColumnWidth,
                onTap: actions[index].onTap,
              ),
          ],
        );
      },
    );
  }
}

class _HeroStatBlock extends StatelessWidget {
  const _HeroStatBlock({
    required this.label,
    required this.value,
    required this.secondary,
  });

  final String label;
  final String value;
  final String secondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.tiny.copyWith(
              color: AppColors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            secondary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.small.copyWith(
              color: AppColors.white.withValues(alpha: 0.86),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerProfileTextField extends StatelessWidget {
  const _CustomerProfileTextField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: AppTypography.body.copyWith(color: AppColors.shieldNavy),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.shieldBlue),
        ),
      ),
    );
  }
}

class _CustomerProfileDropdown extends StatelessWidget {
  const _CustomerProfileDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final normalizedValue = items.contains(value) ? value : null;

    return DropdownButtonFormField<String>(
      initialValue: normalizedValue,
      items: items
          .map(
            (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.shieldBlue),
        ),
      ),
    );
  }
}

class _ProfileSummaryChip extends StatelessWidget {
  const _ProfileSummaryChip({
    required this.label,
    required this.icon,
    this.dark = false,
  });

  final String label;
  final IconData icon;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: dark
            ? AppColors.white.withValues(alpha: 0.1)
            : AppColors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.small.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileFactRow extends StatelessWidget {
  const _ProfileFactRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: AppTypography.small.copyWith(color: AppColors.gray),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTypography.body.copyWith(
              color: AppColors.shieldNavy,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.small.copyWith(color: AppColors.gray),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h5.copyWith(
                    color: AppColors.darkGray,
                    fontWeight: FontWeight.w700,
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

Future<void> _confirmCustomerSignOut(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Sign out of SHIELD?'),
      content: const Text(
        'You will need to verify your mobile number to access this account again.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Stay signed in'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Sign out'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  try {
    await CustomerAuthSession.instance.signOut();
    if (context.mounted) context.go('/customer/login');
  } catch (_) {
    if (context.mounted) {
      showPortalSnackBar(
        context,
        'Could not sign out safely. Please try again.',
      );
    }
  }
}

class _CustomerSettingsView extends StatelessWidget {
  const _CustomerSettingsView();

  Future<void> _showFaq(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Frequently asked questions'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CustomerFaqItem(
                question: 'How do I update my personal details?',
                answer:
                    'Open Profile and choose Edit details. Your verified primary mobile remains your sign-in identity.',
              ),
              SizedBox(height: 14),
              _CustomerFaqItem(
                question: 'Where can I see my membership?',
                answer:
                    'Open Membership from Profile or the customer menu to view the membership record available to your account.',
              ),
              SizedBox(height: 14),
              _CustomerFaqItem(
                question: 'How do I get help?',
                answer:
                    'Choose Get support to send a request to the SHIELD support team.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'SHIELD',
      applicationLegalese:
          'Sahakar Healthcare Initiative to Exempt Lifestyle Disease',
      children: const [
        SizedBox(height: 12),
        Text(
          'Version details are not currently supplied by the customer application build contract.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.shieldBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.shieldBlue,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Settings', style: AppTypography.h4),
                        const SizedBox(height: 4),
                        Text(
                          'Control alerts, privacy, support, and device preferences.',
                          style: AppTypography.small.copyWith(
                            color: AppColors.gray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const _CustomerPreferenceCard(),
        const SizedBox(height: 16),
        _SettingsGroupCard(
          title: 'Privacy and care',
          subtitle: 'Manage the currently supported account information.',
          children: [
            const _CompactSettingAction(
              icon: Icons.lock_outline,
              title: 'Security preferences unavailable',
              subtitle:
                  'PIN changes and care-sharing controls need a customer-safe backend contract.',
            ),
            _CompactSettingAction(
              icon: Icons.badge_outlined,
              title: 'Manage member identity',
              subtitle: 'Review profile, address, and membership details',
              onTap: () => context.go('/portal/customer/profile'),
            ),
            _CompactSettingAction(
              icon: Icons.devices_outlined,
              title: 'Active sessions',
              subtitle: 'Review this account’s signed-in devices',
              onTap: () => _showCustomerSecuritySheet(context),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SettingsGroupCard(
          title: 'Support',
          subtitle: 'Get help and understand app policies.',
          children: [
            _CompactSettingAction(
              icon: Icons.help_outline,
              title: 'Get support',
              subtitle: 'Send a membership, service, or app-support request',
              onTap: () => showCustomerSupportSheet(
                context,
                type: SupportSheetType.contact,
              ),
            ),
            _CompactSettingAction(
              icon: Icons.verified_user_outlined,
              title: 'Privacy policy',
              subtitle: 'Review how SHIELD handles member data',
              onTap: () async {
                final opened = await AppPolicyLinks.openPrivacyPolicy();
                if (!context.mounted || opened) {
                  return;
                }
                showPortalSnackBar(
                  context,
                  'Unable to open the privacy policy right now.',
                );
              },
            ),
            _CompactSettingAction(
              icon: Icons.feedback_outlined,
              title: 'Feedback',
              subtitle: 'Share customer app feedback with the SHIELD team',
              onTap: () => showCustomerSupportSheet(
                context,
                type: SupportSheetType.feedback,
              ),
            ),
            _CompactSettingAction(
              icon: Icons.quiz_outlined,
              title: 'FAQ',
              subtitle:
                  'Quick answers about your profile, membership, and support',
              onTap: () => _showFaq(context),
            ),
            _CompactSettingAction(
              icon: Icons.info_outline_rounded,
              title: 'About SHIELD',
              subtitle: 'Learn about the SHIELD customer application',
              onTap: () => _showAbout(context),
            ),
            _CompactSettingAction(
              icon: Icons.logout_rounded,
              title: 'Sign out',
              subtitle: 'Clear the current customer session on this device',
              destructive: true,
              onTap: () => _confirmCustomerSignOut(context),
            ),
          ],
        ),
      ],
    );
  }
}

Future<void> _showCustomerSecuritySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _CustomerSecuritySheet(),
  );
}

class _CustomerSecuritySheet extends StatefulWidget {
  const _CustomerSecuritySheet();

  @override
  State<_CustomerSecuritySheet> createState() => _CustomerSecuritySheetState();
}

class _CustomerSecuritySheetState extends State<_CustomerSecuritySheet> {
  bool _isLoading = true;
  bool _isMutating = false;
  String? _error;
  List<Map<String, dynamic>> _sessions = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final sessions = await ApiService.getAuthenticatedSessions();
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Signed-in devices could not be loaded. Please retry.';
        _isLoading = false;
      });
    }
  }

  Future<void> _revoke(String sessionId, {required bool otherDevices}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          otherDevices ? 'Sign out other devices?' : 'Revoke session?',
        ),
        content: Text(
          otherDevices
              ? 'Other signed-in devices will need to verify the customer mobile again.'
              : 'This device will need to verify the customer mobile again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isMutating = true);
    try {
      if (otherDevices) {
        await ApiService.revokeOtherSessions();
      } else {
        await ApiService.revokeSession(sessionId);
      }
      if (!mounted) return;
      showPortalSnackBar(context, 'Session access updated.');
      await _load();
    } catch (_) {
      if (!mounted) return;
      showPortalSnackBar(
        context,
        'Session access could not be updated. Please retry.',
      );
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final otherActiveSessions = _sessions.where(
      (session) => session['isCurrent'] != true && session['revokedAt'] == null,
    );
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .82,
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            SizedBox(
              width: 46,
              height: 5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Row(
              children: [
                Icon(Icons.shield_outlined, color: AppColors.shieldBlue),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Security and signed-in devices',
                    style: AppTypography.h4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Only sessions for this customer account are shown.',
              style: AppTypography.small.copyWith(color: AppColors.gray),
            ),
            const SizedBox(height: 14),
            if (otherActiveSessions.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _isMutating
                      ? null
                      : () => _revoke('', otherDevices: true),
                  icon: const Icon(Icons.phonelink_erase_outlined),
                  label: const Text('Sign out other devices'),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: AppButton(text: 'Retry', onPressed: _load),
      );
    }
    if (_sessions.isEmpty) {
      return Center(
        child: Text(
          'No signed-in devices found.',
          style: AppTypography.small.copyWith(color: AppColors.gray),
        ),
      );
    }
    return ListView.separated(
      itemCount: _sessions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final session = _sessions[index];
        final device = session['device'] as Map<String, dynamic>?;
        final current = session['isCurrent'] == true;
        final revoked = session['revokedAt'] != null;
        final sessionId = session['sessionId']?.toString() ?? '';
        return AppCard(
          child: Row(
            children: [
              Icon(
                current ? Icons.phone_android_outlined : Icons.devices_outlined,
                color: current ? AppColors.shieldGreen : AppColors.shieldBlue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device?['deviceName']?.toString() ?? 'Signed-in device',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                            device?['platform'],
                            device?['browser'],
                            session['loginMethod'],
                          ]
                          .whereType<String>()
                          .where((value) => value.trim().isNotEmpty)
                          .join(' • '),
                      style: AppTypography.small.copyWith(
                        color: AppColors.gray,
                      ),
                    ),
                  ],
                ),
              ),
              if (current)
                const _StatusPill(
                  label: 'Current',
                  color: AppColors.shieldGreen,
                )
              else if (revoked)
                const _StatusPill(label: 'Signed out', color: AppColors.gray)
              else
                TextButton(
                  onPressed: _isMutating || sessionId.isEmpty
                      ? null
                      : () => _revoke(sessionId, otherDevices: false),
                  child: const Text('Revoke'),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StaticActionChip extends StatelessWidget {
  const _StaticActionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.shieldBlue.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: AppTypography.small.copyWith(
              color: AppColors.shieldBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingCustomerAccessCard extends StatelessWidget {
  const _PendingCustomerAccessCard({
    required this.title,
    required this.message,
    this.primaryLabel,
    this.primaryRoute,
    this.secondaryLabel,
    this.secondaryRoute,
  });

  final String title;
  final String message;
  final String? primaryLabel;
  final String? primaryRoute;
  final String? secondaryLabel;
  final String? secondaryRoute;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: AppTypography.h4)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTypography.body.copyWith(color: AppColors.darkGray),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (primaryLabel != null && primaryRoute != null)
                _StaticActionChip(
                  label: primaryLabel!,
                  onTap: () => context.go(primaryRoute!),
                ),
              if (secondaryLabel != null && secondaryRoute != null)
                _StaticActionChip(
                  label: secondaryLabel!,
                  onTap: () => context.go(secondaryRoute!),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerProtectedSection extends StatefulWidget {
  const _CustomerProtectedSection({
    required this.sectionKey,
    required this.child,
  });

  final String sectionKey;
  final Widget child;

  @override
  State<_CustomerProtectedSection> createState() =>
      _CustomerProtectedSectionState();
}

class _CustomerProtectedSectionState extends State<_CustomerProtectedSection> {
  late Future<_CustomerAccessContext> _accessFuture;

  @override
  void initState() {
    super.initState();
    _loadCustomer();
  }

  void _loadCustomer() {
    _accessFuture = _loadCustomerAccessContext();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_CustomerAccessContext>(
      future: _accessFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppPortalSectionSkeleton(
            showHero: true,
            statCards: 2,
            listItems: 3,
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return ErrorCard(
            title: 'Access status unavailable',
            message:
                'Your customer access status could not be verified. Please try again.',
            onRetry: () => setState(_loadCustomer),
          );
        }

        final accessContext = snapshot.data!;
        final accessState = CustomerAccessState(
          customer: accessContext.customer,
          customerStatus: accessContext.customer.status,
          membership: accessContext.membership,
        );

        if (accessState.serviceAccessEnabled) {
          return widget.child;
        }

        switch (widget.sectionKey) {
          case 'appointments':
            return const _PendingCustomerAccessCard(
              title: 'Appointments unlock after card issue',
              message:
                  'Consultation, clinic, lab, dental, and homecare bookings stay disabled until SHIELD issues the membership card.',
              primaryLabel: 'Membership status',
              primaryRoute: '/portal/customer/membership',
              secondaryLabel: 'Browse products',
              secondaryRoute: '/portal/customer/services',
            );
          default:
            return widget.child;
        }
      },
    );
  }
}

class _CustomerAccessContext {
  const _CustomerAccessContext({
    required this.customer,
    required this.membership,
  });

  final Customer customer;
  final Membership membership;
}

class _CustomerAppointmentsView extends StatefulWidget {
  final PortalSectionData section;

  const _CustomerAppointmentsView({required this.section});

  @override
  State<_CustomerAppointmentsView> createState() =>
      _CustomerAppointmentsViewState();
}

class _CustomerAppointmentsViewState extends State<_CustomerAppointmentsView> {
  late Future<List<Appointment>> _appointmentsFuture;
  bool _showUpcomingOnly = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  void _loadAppointments() {
    _appointmentsFuture = ApiService.getAppointments(SHIELDRole.customer);
  }

  Future<void> _cancelAppointment(Appointment appointment) async {
    try {
      await ApiService.cancelCustomerAppointment(appointment.id);
      if (!mounted) return;
      setState(_loadAppointments);
      showPortalSnackBar(context, 'Appointment cancelled successfully.');
    } catch (_) {
      if (!mounted) return;
      showPortalSnackBar(
        context,
        'Cancellation is unavailable right now. Please try again shortly.',
      );
    }
  }

  Future<void> _rescheduleAppointment(Appointment appointment) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: appointment.appointmentDate.isAfter(DateTime.now())
          ? appointment.appointmentDate
          : DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selectedDate == null || !mounted) return;

    try {
      await ApiService.rescheduleCustomerAppointment(
        appointmentId: appointment.id,
        appointmentDate: DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          appointment.appointmentDate.hour,
          appointment.appointmentDate.minute,
        ),
      );
      if (!mounted) return;
      setState(_loadAppointments);
      showPortalSnackBar(context, 'Appointment rescheduled successfully.');
    } catch (_) {
      if (!mounted) return;
      showPortalSnackBar(
        context,
        'Rescheduling is unavailable right now. Please try again shortly.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Appointment>>(
      future: _appointmentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppPortalSectionSkeleton(
            showHero: true,
            statCards: 3,
            listItems: 5,
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return ErrorCard(
            title: 'Appointments unavailable',
            message: 'Your customer appointment feed could not be loaded.',
            onRetry: () => setState(_loadAppointments),
          );
        }

        final appointments = snapshot.data!;
        final upcoming =
            appointments
                .where(
                  (appointment) =>
                      appointment.status != AppointmentStatus.cancelled &&
                      appointment.status != AppointmentStatus.completed,
                )
                .toList()
              ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
        final history =
            appointments
                .where(
                  (appointment) =>
                      appointment.status == AppointmentStatus.cancelled ||
                      appointment.status == AppointmentStatus.completed,
                )
                .toList()
              ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
        final visibleList = _showUpcomingOnly ? upcoming : appointments;
        final nextVisit = upcoming.isNotEmpty ? upcoming.first : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.shieldBlue, AppColors.shieldNavy],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${upcoming.length} active visits',
                          style: AppTypography.h4.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${history.length} completed',
                          style: AppTypography.tiny.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Clinic, dental, and homecare visits stay inside the same customer app timeline.',
                    style: AppTypography.small.copyWith(
                      color: AppColors.white.withValues(alpha: 0.84),
                    ),
                  ),
                  if (nextVisit != null) ...[
                    const SizedBox(height: 12),
                    _HeroStatBlock(
                      label: 'Next visit',
                      value: nextVisit.doctorName ?? 'Appointment scheduled',
                      secondary:
                          '${DateFormat('dd MMM yyyy').format(nextVisit.appointmentDate)} • ${nextVisit.department ?? nextVisit.typeLabel}',
                    ),
                  ],
                  const SizedBox(height: 10),
                  _HeroActionGrid(
                    actions: [
                      _HeroActionGridItem(
                        label: 'Book consultation',
                        onTap: () => context.go('/portal/customer/services'),
                      ),
                      _HeroActionGridItem(
                        label: _showUpcomingOnly
                            ? 'Show full history'
                            : 'Show upcoming only',
                        onTap: () {
                          setState(() {
                            _showUpcomingOnly = !_showUpcomingOnly;
                          });
                        },
                      ),
                      _HeroActionGridItem(
                        label: 'Open notifications',
                        onTap: () =>
                            context.go('/portal/customer/notifications'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) => GridView.count(
                crossAxisCount: constraints.maxWidth >= 420 ? 2 : 1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: constraints.maxWidth >= 420 ? 2.5 : 3,
                children: [
                  _KpiTile(
                    title: 'Upcoming',
                    value: '${upcoming.length}',
                    icon: Icons.event_available_rounded,
                    color: AppColors.shieldBlue,
                  ),
                  _KpiTile(
                    title: 'Completed',
                    value:
                        '${history.where((a) => a.status == AppointmentStatus.completed).length}',
                    icon: Icons.task_alt_rounded,
                    color: AppColors.shieldGreen,
                  ),
                  _KpiTile(
                    title: 'Cancelled',
                    value:
                        '${history.where((a) => a.status == AppointmentStatus.cancelled).length}',
                    icon: Icons.cancel_outlined,
                    color: AppColors.error,
                  ),
                  _KpiTile(
                    title: 'Care types',
                    value:
                        '${appointments.map((a) => a.typeLabel).toSet().length}',
                    icon: Icons.local_hospital_outlined,
                    color: AppColors.warning,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _showUpcomingOnly
                  ? 'Upcoming and pending'
                  : 'Appointment timeline',
              style: AppTypography.h4,
            ),
            const SizedBox(height: 12),
            if (visibleList.isEmpty)
              AppCard(
                child: Text(
                  _showUpcomingOnly
                      ? 'No upcoming visits are scheduled yet.'
                      : 'No appointment history is available yet.',
                  style: AppTypography.body.copyWith(color: AppColors.gray),
                ),
              )
            else
              ...visibleList.map(
                (appointment) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    onTap: () => showPortalDetailsSheet(
                      context,
                      title: appointment.doctorName ?? appointment.typeLabel,
                      subtitle:
                          appointment.notes ?? 'Customer appointment entry',
                      meta: DateFormat(
                        'dd MMM yyyy • hh:mm a',
                      ).format(appointment.appointmentDate),
                      status: appointment.statusLabel,
                      highlights: [
                        'Provider: ${appointment.department ?? appointment.typeLabel}',
                        'This appointment remains inside the mobile-first customer portal flow.',
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _appointmentAccent(
                              appointment.status,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _appointmentIcon(appointment.status),
                            color: _appointmentAccent(appointment.status),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appointment.doctorName ?? appointment.typeLabel,
                                style: AppTypography.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${DateFormat('dd MMM yyyy • hh:mm a').format(appointment.appointmentDate)} • ${appointment.department ?? appointment.typeLabel}',
                                style: AppTypography.small.copyWith(
                                  color: AppColors.gray,
                                ),
                              ),
                              if ((appointment.notes ?? '').isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  appointment.notes!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.tiny.copyWith(
                                    color: AppColors.darkGray,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _StatusPill(
                              label: appointment.statusLabel,
                              color: _appointmentAccent(appointment.status),
                            ),
                            if (appointment.status ==
                                    AppointmentStatus.scheduled ||
                                appointment.status ==
                                    AppointmentStatus.rescheduled)
                              TextButton(
                                onPressed: () =>
                                    _rescheduleAppointment(appointment),
                                child: const Text('Reschedule'),
                              ),
                            if (appointment.status ==
                                    AppointmentStatus.scheduled ||
                                appointment.status ==
                                    AppointmentStatus.rescheduled)
                              TextButton(
                                onPressed: () =>
                                    _cancelAppointment(appointment),
                                child: const Text('Cancel'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CustomerNotificationsView extends StatefulWidget {
  final PortalSectionData section;

  const _CustomerNotificationsView({required this.section});

  @override
  State<_CustomerNotificationsView> createState() =>
      _CustomerNotificationsViewState();
}

class _CustomerNotificationsViewState
    extends State<_CustomerNotificationsView> {
  late Future<void> _notificationsFuture;
  List<NotificationModel> _notifications = const [];
  int? _nextNotificationOffset;
  NotificationType? _activeType;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications({bool append = false}) {
    final offset = append ? _nextNotificationOffset ?? 0 : 0;
    _notificationsFuture =
        ApiService.getCustomerNotificationCenter(offset: offset).then((
          payload,
        ) {
          final page = ((payload['items'] as List?) ?? const <dynamic>[])
              .whereType<Map>()
              .map(
                (item) =>
                    NotificationModel.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList();
          _notifications = append ? [..._notifications, ...page] : page;
          _nextNotificationOffset = payload['nextOffset'] as int?;
        });
  }

  Future<void> _markAllRead(List<NotificationModel> notifications) async {
    if (!notifications.any((notification) => !notification.isRead)) return;
    try {
      await ApiService.markAllNotificationsRead();
      if (!mounted) return;
      setState(_loadNotifications);
      showPortalSnackBar(context, 'All unread notifications marked as read.');
    } catch (_) {
      if (!mounted) return;
      showPortalSnackBar(
        context,
        'Notifications could not be marked as read. Please try again.',
      );
    }
  }

  Future<void> _openUnreadNotification(NotificationModel notification) async {
    try {
      await ApiService.markNotificationRead(notification.id);
      if (!mounted) return;
      setState(_loadNotifications);
      showPortalDetailsSheet(
        context,
        title: notification.title,
        subtitle: notification.body,
        meta: notification.typeLabel,
        status: 'Read',
        highlights: const [
          'This alert remains inside the compact customer app inbox.',
        ],
      );
    } catch (_) {
      if (!mounted) return;
      showPortalSnackBar(
        context,
        'Notification could not be opened. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _notificationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppPortalSectionSkeleton(
            showHero: true,
            statCards: 3,
            listItems: 5,
          );
        }

        if (snapshot.hasError) {
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notifications unavailable', style: AppTypography.h4),
                const SizedBox(height: 8),
                Text(
                  'The customer notification feed could not be loaded.',
                  style: AppTypography.small.copyWith(color: AppColors.gray),
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: 'Retry',
                  onPressed: () => setState(_loadNotifications),
                ),
              ],
            ),
          );
        }

        final notifications = _notifications;
        final visible = _activeType == null
            ? notifications
            : notifications
                  .where((notification) => notification.type == _activeType)
                  .toList();
        final unread = visible
            .where((notification) => !notification.isRead)
            .toList();
        final read = visible
            .where((notification) => notification.isRead)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.shieldBlue, AppColors.shieldNavy],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${unread.length} unread right now',
                          style: AppTypography.h4.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${notifications.length} total',
                          style: AppTypography.tiny.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Wallet alerts, appointment reminders, and document updates stay grouped in the same customer inbox.',
                    style: AppTypography.small.copyWith(
                      color: AppColors.white.withValues(alpha: 0.84),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _HeroActionGrid(
                    actions: [
                      _HeroActionGridItem(
                        label: 'Mark all read',
                        onTap: () => _markAllRead(notifications),
                      ),
                      _HeroActionGridItem(
                        label: 'Open settings',
                        onTap: () => context.go('/portal/customer/settings'),
                      ),
                      _HeroActionGridItem(
                        label: 'Refresh feed',
                        onTap: () => setState(_loadNotifications),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) => GridView.count(
                crossAxisCount: constraints.maxWidth >= 420 ? 2 : 1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: constraints.maxWidth >= 420 ? 2.5 : 3,
                children: [
                  _KpiTile(
                    title: 'Unread',
                    value: '${notifications.where((n) => !n.isRead).length}',
                    icon: Icons.mark_email_unread_outlined,
                    color: AppColors.shieldBlue,
                  ),
                  _KpiTile(
                    title: 'Wallet',
                    value:
                        '${notifications.where((n) => n.type == NotificationType.wallet).length}',
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppColors.shieldGreen,
                  ),
                  _KpiTile(
                    title: 'Appointments',
                    value:
                        '${notifications.where((n) => n.type == NotificationType.appointment).length}',
                    icon: Icons.calendar_month_outlined,
                    color: AppColors.warning,
                  ),
                  _KpiTile(
                    title: 'Documents',
                    value:
                        '${notifications.where((n) => n.type == NotificationType.document).length}',
                    icon: Icons.description_outlined,
                    color: AppColors.shieldNavy,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _activeType == null,
                    onTap: () => setState(() => _activeType = null),
                  ),
                  const SizedBox(width: 8),
                  for (final type in NotificationType.values) ...[
                    _FilterChip(
                      label: _notificationTypeLabel(type),
                      selected: _activeType == type,
                      onTap: () => setState(() => _activeType = type),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Unread first', style: AppTypography.h4),
            const SizedBox(height: 12),
            ...unread.map(
              (notification) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CustomerTimelineTile(
                  icon: _notificationIcon(notification.type),
                  accentColor: AppColors.shieldBlue,
                  title: notification.title,
                  subtitle: notification.body,
                  meta:
                      '${notification.typeLabel} • ${DateFormat('dd MMM • hh:mm a').format(notification.createdAt)}',
                  highlightUnread: true,
                  onTap: () => _openUnreadNotification(notification),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text('Earlier updates', style: AppTypography.h4),
            const SizedBox(height: 12),
            ...read.map(
              (notification) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CustomerTimelineTile(
                  icon: _notificationIcon(notification.type),
                  accentColor: AppColors.shieldGreen,
                  title: notification.title,
                  subtitle: notification.body,
                  meta:
                      '${notification.typeLabel} • ${DateFormat('dd MMM • hh:mm a').format(notification.createdAt)}',
                  onTap: () => showPortalDetailsSheet(
                    context,
                    title: notification.title,
                    subtitle: notification.body,
                    meta: notification.typeLabel,
                    status: 'Read',
                    highlights: const [
                      'Read items stay available as lightweight customer history.',
                    ],
                  ),
                ),
              ),
            ),
            if (_nextNotificationOffset != null) ...[
              const SizedBox(height: 8),
              Center(
                child: AppButton(
                  text: 'Load earlier updates',
                  onPressed: () =>
                      setState(() => _loadNotifications(append: true)),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

Color _appointmentAccent(AppointmentStatus status) {
  switch (status) {
    case AppointmentStatus.pending:
      return AppColors.warning;
    case AppointmentStatus.completed:
      return AppColors.shieldGreen;
    case AppointmentStatus.cancelled:
      return AppColors.error;
    case AppointmentStatus.rescheduled:
      return AppColors.warning;
    case AppointmentStatus.checkedIn:
      return AppColors.warning;
    case AppointmentStatus.inProgress:
      return AppColors.shieldNavy;
    case AppointmentStatus.scheduled:
      return AppColors.shieldBlue;
  }
}

IconData _appointmentIcon(AppointmentStatus status) {
  switch (status) {
    case AppointmentStatus.pending:
      return Icons.hourglass_top_rounded;
    case AppointmentStatus.completed:
      return Icons.task_alt_rounded;
    case AppointmentStatus.cancelled:
      return Icons.cancel_outlined;
    case AppointmentStatus.rescheduled:
      return Icons.update_rounded;
    case AppointmentStatus.checkedIn:
      return Icons.fact_check_outlined;
    case AppointmentStatus.inProgress:
      return Icons.local_hospital_outlined;
    case AppointmentStatus.scheduled:
      return Icons.event_note_rounded;
  }
}

String _notificationTypeLabel(NotificationType type) {
  switch (type) {
    case NotificationType.wallet:
      return 'Wallet';
    case NotificationType.appointment:
      return 'Visits';
    case NotificationType.document:
      return 'Docs';
    case NotificationType.membership:
      return 'Member';
    case NotificationType.system:
      return 'System';
  }
}

IconData _notificationIcon(NotificationType type) {
  switch (type) {
    case NotificationType.wallet:
      return Icons.account_balance_wallet_outlined;
    case NotificationType.appointment:
      return Icons.calendar_month_outlined;
    case NotificationType.document:
      return Icons.description_outlined;
    case NotificationType.membership:
      return Icons.workspace_premium_outlined;
    case NotificationType.system:
      return Icons.notifications_active_outlined;
  }
}

class _CustomerTimelineTile extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final String meta;
  final VoidCallback onTap;
  final bool highlightUnread;

  const _CustomerTimelineTile({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.onTap,
    this.highlightUnread = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor, size: 20),
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
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (highlightUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.shieldBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.small.copyWith(
                    color: AppColors.darkGray,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  meta,
                  style: AppTypography.tiny.copyWith(color: AppColors.gray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.shieldBlue : AppColors.lightGray,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: AppTypography.small.copyWith(
            color: selected ? AppColors.white : AppColors.darkGray,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.small.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CustomerPreferenceCard extends StatefulWidget {
  const _CustomerPreferenceCard();

  @override
  State<_CustomerPreferenceCard> createState() =>
      _CustomerPreferenceCardState();
}

class _CustomerPreferenceCardState extends State<_CustomerPreferenceCard> {
  final _repository = const CustomerAccountRepository();
  bool _loading = true;
  bool _saving = false;
  bool _push = true;
  bool _sms = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final value = await _repository.preferences();
      final notifications = value?['notificationPreferences'];
      if (!mounted) return;
      setState(() {
        _push = notifications is Map ? notifications['push'] != false : true;
        _sms = notifications is Map ? notifications['sms'] != false : true;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Preferences could not be loaded.';
      });
    }
  }

  Future<void> _save({bool? push, bool? sms}) async {
    final previousPush = _push;
    final previousSms = _sms;
    final nextPush = push ?? _push;
    final nextSms = sms ?? _sms;
    setState(() {
      _push = nextPush;
      _sms = nextSms;
      _saving = true;
    });
    try {
      await _repository.savePreferences({
        'notificationPreferences': {'push': nextPush, 'sms': nextSms},
      });
      if (!mounted) return;
      setState(() => _saving = false);
      showPortalSnackBar(context, 'Notification preferences saved.');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _push = previousPush;
        _sms = previousSms;
        _saving = false;
        _error = 'Preferences could not be saved. Please retry.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsGroupCard(
      title: 'Notification preferences',
      subtitle: _loading
          ? 'Loading saved preferences...'
          : 'Choose how SHIELD may contact you.',
      children: [
        if (_error != null)
          _CompactSettingAction(
            icon: Icons.refresh_rounded,
            title: _error!,
            subtitle: 'Tap to retry.',
            onTap: _load,
          )
        else ...[
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Push notifications'),
            subtitle: const Text('Appointment, record, and service updates'),
            value: _push,
            onChanged: _loading || _saving
                ? null
                : (value) => _save(push: value),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('SMS notifications'),
            subtitle: const Text('Important membership and care reminders'),
            value: _sms,
            onChanged: _loading || _saving
                ? null
                : (value) => _save(sms: value),
          ),
        ],
      ],
    );
  }
}

class _SettingsGroupCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _SettingsGroupCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.h5),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTypography.small.copyWith(color: AppColors.gray),
          ),
          const SizedBox(height: 14),
          ...children.asMap().entries.map((entry) {
            final index = entry.key;
            final child = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == children.length - 1 ? 0 : 10,
              ),
              child: child,
            );
          }),
        ],
      ),
    );
  }
}

class _CompactSettingAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool destructive;

  const _CompactSettingAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? AppColors.error : AppColors.shieldBlue;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: destructive ? AppColors.error : AppColors.darkGray,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTypography.tiny.copyWith(color: AppColors.gray),
                  ),
                ],
              ),
            ),
            if (onTap != null) Icon(Icons.chevron_right_rounded, color: accent),
          ],
        ),
      ),
    );
  }
}

class _ConsultationModeOption extends StatelessWidget {
  final String value;
  final String label;

  const _ConsultationModeOption({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<String>(
            value: value,
            activeColor: AppColors.shieldBlue,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 2),
          Text(label, style: AppTypography.small),
        ],
      ),
    );
  }
}

class _StaticFilterPill extends StatelessWidget {
  final String label;

  const _StaticFilterPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.shieldBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.small.copyWith(
          color: AppColors.shieldBlue,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CustomerServicesView extends StatefulWidget {
  const _CustomerServicesView();

  @override
  State<_CustomerServicesView> createState() => _CustomerServicesViewState();
}

class _CustomerServicesViewState extends State<_CustomerServicesView> {
  late Future<_CustomerAccessContext> _accessFuture;
  late Future<List<Map<String, dynamic>>> _providersFuture;
  late Future<Map<String, dynamic>> _wellnessProductsFuture;
  final TextEditingController _wellnessSearchController =
      TextEditingController();
  String? _wellnessCategoryId;
  int _wellnessPage = 1;
  String _activeTab =
      'PHARMACY'; // 'PHARMACY', 'LAB', 'HOMECARE', 'CONSULTATION'
  String _uploadStatus = 'No files selected';
  bool _isUploading = false;
  bool _isBooking = false;
  String? _lastBookingStatus;
  String? _selectedPrescriptionName;
  final TextEditingController _manualMedicineController =
      TextEditingController();
  final List<_EditablePrescriptionItem> _editablePrescriptionItems = [];

  // Consultation booking fields
  String _specialistType =
      'DOCTOR'; // 'DOCTOR', 'DENTAL', 'COSMETIC', 'DIETITIAN'
  String _consultationMode = 'IN_PERSON'; // 'IN_PERSON', 'TELE', 'VIDEO'
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedDietPlan;
  String? _selectedProviderId;

  @override
  void initState() {
    super.initState();
    _accessFuture = _loadCustomerAccessContext();
    _providersFuture = ApiService.getProviders();
    _wellnessProductsFuture = _loadWellnessProducts();
    _restoreProviderPreselection();
  }

  void _restoreProviderPreselection() {
    final query = GoRouterState.of(context).uri.queryParameters;
    final providerId = query['provider']?.trim();
    if (providerId == null || providerId.isEmpty) return;
    final requestedType = query['type']?.trim().toUpperCase();
    final specialist = _specialistForProviderType(requestedType);
    if (specialist == null) {
      _lastBookingStatus =
          'This provider type is not supported by the current booking workflow.';
      return;
    }
    _specialistType = specialist;
    _providersFuture = _providersFuture.then((providers) {
      final matching = _filterConsultationProviders(providers);
      final isAvailable = matching.any(
        (provider) => provider['id']?.toString() == providerId,
      );
      if (isAvailable) {
        _selectedProviderId = providerId;
      } else {
        _lastBookingStatus =
            'The selected provider is unavailable. Please choose another provider.';
      }
      return providers;
    });
  }

  String? _specialistForProviderType(String? providerType) {
    switch (providerType) {
      case 'CLINIC':
      case 'DOCTOR':
        return 'DOCTOR';
      case 'DENTAL':
        return 'DENTAL';
      default:
        return null;
    }
  }

  @override
  void dispose() {
    _manualMedicineController.dispose();
    _wellnessSearchController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadWellnessProducts() {
    return ApiService.getCustomerWellnessProducts(
      query: _wellnessSearchController.text,
      categoryId: _wellnessCategoryId,
      page: _wellnessPage,
    );
  }

  void _refreshWellnessProducts({int? page}) {
    setState(() {
      _wellnessPage = page ?? 1;
      _wellnessProductsFuture = _loadWellnessProducts();
    });
  }

  Future<void> _showWellnessProduct(Map<String, dynamic> product) async {
    final id = product['id']?.toString();
    if (id == null) return;
    try {
      final details = await ApiService.getCustomerWellnessProduct(id);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        builder: (context) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                details['productName']?.toString() ?? 'Wellness product',
                style: AppTypography.h4,
              ),
              if ((details['brand']?.toString() ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  details['brand'].toString(),
                  style: AppTypography.small.copyWith(color: AppColors.gray),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Demo products only — not live Sahakar inventory.',
                style: AppTypography.tiny.copyWith(color: AppColors.gray),
              ),
            ],
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        showPortalSnackBar(
          context,
          'Product details could not be loaded. Please retry.',
        );
      }
    }
  }

  String _inferMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    return 'application/pdf';
  }

  bool _isUploadSuccessStatus(String status) {
    final normalized = status.toLowerCase();
    return normalized.contains('uploaded successfully') ||
        normalized.contains('saved to your records');
  }

  bool _isUploadErrorStatus(String status) {
    return status.toLowerCase().contains('failed');
  }

  String _buildUploadErrorMessage(Object error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Prescription upload is taking longer than expected. Please check your connection and retry.';
      }
      return 'Prescription upload could not be completed. Please retry.';
    }

    return 'Prescription upload could not be completed. Please retry.';
  }

  Future<void> _handlePrescriptionUpload() async {
    final picked = await pickPrescriptionFile();

    if (!mounted || picked == null) {
      return;
    }

    final fileName = picked.name.isEmpty
        ? 'Prescription_${DateFormat('yyyy_MM_dd_HHmm').format(DateTime.now())}.pdf'
        : picked.name;
    final fileSize = picked.size <= 0 ? 1024 : picked.size;

    setState(() {
      _selectedPrescriptionName = fileName;
      _isUploading = true;
      _uploadStatus = 'Uploading $fileName to your customer records.';
    });

    try {
      await ApiService.uploadCustomerDocument(
        fileName: fileName,
        documentType: 'PRESCRIPTION',
        fileBytes: picked.bytes,
        mimeType: picked.mimeType ?? _inferMimeType(fileName),
        fileSize: fileSize,
      );
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _uploadStatus =
            'Prescription uploaded successfully and saved to your records.';
      });
      showPortalSnackBar(
        context,
        'Prescription uploaded and saved to your records.',
      );
    } catch (error) {
      final errorMessage = _buildUploadErrorMessage(error);
      setState(() {
        _isUploading = false;
        _uploadStatus =
            'Upload failed for ${_selectedPrescriptionName ?? 'selected file'}. $errorMessage';
      });
      showPortalSnackBar(context, errorMessage);
    }
  }

  void _addManualMedicine() {
    final value = _manualMedicineController.text.trim();
    if (value.isEmpty) {
      showPortalSnackBar(
        context,
        'Type a medicine or product name before adding it to the request list.',
      );
      return;
    }

    final entries = value
        .split(RegExp(r'[\n,;]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    setState(() {
      _editablePrescriptionItems.insertAll(
        0,
        entries.map(
          (entry) => _EditablePrescriptionItem(
            name: entry,
            dosage: 'As directed',
            frequency: 'As directed',
            duration: 'Not specified',
            confidence: 0,
            source: 'Requested by customer',
            selected: true,
          ),
        ),
      );
      _manualMedicineController.clear();
    });
    showPortalSnackBar(
      context,
      entries.length == 1
          ? 'Added ${entries.first} to your request list.'
          : 'Added ${entries.length} items to your request list.',
    );
  }

  void _submitEditablePrescriptionItems() {
    final selectedCount = _editablePrescriptionItems
        .where((item) => item.selected)
        .length;
    if (selectedCount == 0) {
      showPortalSnackBar(
        context,
        'Select at least one medicine or product before sending the list for review.',
      );
      return;
    }

    showPortalSnackBar(
      context,
      '$selectedCount items selected. Our pharmacy team will review them with your request.',
    );
  }

  Widget _buildSupportChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.shieldBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.tiny.copyWith(
          color: AppColors.shieldBlue,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildManualMedicineComposer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add medicines or products',
            style: AppTypography.small.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Type medicines, wellness products, or pharmacy items you want us to prepare.',
            style: AppTypography.tiny.copyWith(color: AppColors.gray),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _manualMedicineController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addManualMedicine(),
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Type medicine or product names',
                    filled: true,
                    fillColor: AppColors.lightGray,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.shieldBlue),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              AppButton(
                text: 'Add',
                width: 92,
                height: 50,
                onPressed: _addManualMedicine,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildEditablePrescriptionList() {
    if (_editablePrescriptionItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review medicines before approval',
                      style: AppTypography.h5,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Keep only the medicines or products you want us to review or prepare.',
                      style: AppTypography.small.copyWith(
                        color: AppColors.gray,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.shieldBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_editablePrescriptionItems.where((item) => item.selected).length} selected',
                  style: AppTypography.tiny.copyWith(
                    color: AppColors.shieldBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(_editablePrescriptionItems.length, (index) {
            final item = _editablePrescriptionItems[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildEditablePrescriptionItem(item, index),
            );
          }),
          const SizedBox(height: 8),
          AppButton(
            text: 'Use Selected Medicines',
            onPressed: _submitEditablePrescriptionItems,
          ),
        ],
      ),
    );
  }

  Widget _buildEditablePrescriptionItem(
    _EditablePrescriptionItem item,
    int index,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.selected
              ? AppColors.shieldBlue.withValues(alpha: 0.35)
              : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: item.selected,
                onChanged: (value) {
                  setState(() {
                    _editablePrescriptionItems[index] = item.copyWith(
                      selected: value ?? false,
                    );
                  });
                },
                activeColor: AppColors.shieldBlue,
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.source,
                      style: AppTypography.tiny.copyWith(
                        color: item.source == 'Requested by customer'
                            ? AppColors.warning
                            : AppColors.gray,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.confidence > 0
                          ? 'Confidence ${item.confidence.toStringAsFixed(0)}%'
                          : 'Manual entry',
                      style: AppTypography.tiny.copyWith(color: AppColors.gray),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  final removedName = item.name;
                  setState(() {
                    _editablePrescriptionItems.removeAt(index);
                  });
                  showPortalSnackBar(
                    context,
                    'Removed $removedName from the review list.',
                  );
                },
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.gray,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: item.name,
            decoration: const InputDecoration(labelText: 'Medicine or product'),
            onChanged: (value) {
              setState(() {
                _editablePrescriptionItems[index] = item.copyWith(name: value);
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: item.dosage,
                  decoration: const InputDecoration(labelText: 'Dosage'),
                  onChanged: (value) {
                    setState(() {
                      _editablePrescriptionItems[index] = item.copyWith(
                        dosage: value,
                      );
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  initialValue: item.frequency,
                  decoration: const InputDecoration(labelText: 'Frequency'),
                  onChanged: (value) {
                    setState(() {
                      _editablePrescriptionItems[index] = item.copyWith(
                        frequency: value,
                      );
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: item.duration,
            decoration: const InputDecoration(labelText: 'Duration'),
            onChanged: (value) {
              setState(() {
                _editablePrescriptionItems[index] = item.copyWith(
                  duration: value,
                );
              });
            },
          ),
          if (item.alternatives.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Suggested matches',
              style: AppTypography.tiny.copyWith(
                color: AppColors.gray,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: item.alternatives.map((alternative) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      _editablePrescriptionItems[index] = item.copyWith(
                        name: alternative,
                      );
                    });
                  },
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Text(
                      alternative,
                      style: AppTypography.tiny.copyWith(
                        color: AppColors.shieldBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleBookAppointment() async {
    setState(() {
      _isBooking = true;
      _lastBookingStatus = null;
    });

    const appointmentTypeMap = {
      'DOCTOR': 'CLINIC',
      'DENTAL': 'DENTAL',
      'COSMETIC': 'CLINIC',
      'DIETITIAN': 'CLINIC',
    };

    try {
      final selectedProviderId = _selectedProviderId;
      if (selectedProviderId == null || selectedProviderId.trim().isEmpty) {
        throw StateError('Select a provider before booking your consultation.');
      }
      final providers = await _providersFuture;
      final matchingProviders = _filterConsultationProviders(providers);
      final selectedProvider = matchingProviders
          .cast<Map<String, dynamic>?>()
          .firstWhere(
            (provider) => provider?['id']?.toString() == selectedProviderId,
            orElse: () => null,
          );

      if (selectedProvider == null) {
        throw StateError(
          'The selected provider is no longer available. Please choose another provider.',
        );
      }

      final providerId = selectedProvider['id']?.toString();
      if (providerId == null || providerId.trim().isEmpty) {
        throw StateError('Selected provider is missing a valid identifier.');
      }

      final appointment = await ApiService.createCustomerAppointment(
        providerId: providerId,
        appointmentType: appointmentTypeMap[_specialistType] ?? 'CLINIC',
        appointmentDate: _selectedDate,
        remarks:
            '${selectedProvider['providerName'] ?? selectedProvider['name'] ?? _specialistType} via $_consultationMode',
      );
      if (!mounted) return;
      setState(() {
        _isBooking = false;
        _lastBookingStatus =
            'Booked ${appointment.typeLabel.toLowerCase()} visit for ${DateFormat('dd MMM yyyy').format(appointment.appointmentDate)}.';
      });
      showPortalSnackBar(
        context,
        'Consultation booked successfully inside your customer appointments.',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isBooking = false;
        _lastBookingStatus = 'Booking failed. Please retry.';
      });
      showPortalSnackBar(
        context,
        error is StateError
            ? error.message
            : 'Appointment booking is unavailable right now. Please retry shortly.',
      );
    }
  }

  List<Map<String, dynamic>> _filterConsultationProviders(
    List<Map<String, dynamic>> providers,
  ) {
    final expectedType = _providerTypeForSpecialist(_specialistType);
    return providers.where((provider) {
      final providerType = provider['providerType']?.toString().trim();
      final status =
          provider['status']?.toString().trim().toUpperCase() ?? 'ACTIVE';
      return providerType == expectedType && status == 'ACTIVE';
    }).toList();
  }

  String _providerTypeForSpecialist(String specialistType) {
    switch (specialistType) {
      case 'DENTAL':
        return 'DENTAL';
      case 'DOCTOR':
      case 'COSMETIC':
      case 'DIETITIAN':
        return 'CLINIC';
      default:
        return 'CLINIC';
    }
  }

  String _providerLabelForSpecialist(String specialistType) {
    switch (specialistType) {
      case 'DENTAL':
        return 'Dental provider';
      case 'COSMETIC':
        return 'Cosmetic consultation provider';
      case 'DIETITIAN':
        return 'Dietitian consultation provider';
      case 'DOCTOR':
      default:
        return 'Consultation provider';
    }
  }

  Widget _buildTabButton(String key, String label, IconData icon) {
    final isActive = _activeTab == key;
    return InkWell(
      onTap: () => setState(() => _activeTab = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.shieldBlue.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppColors.shieldBlue : AppColors.divider,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.shieldBlue : AppColors.darkGray,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.small.copyWith(
                color: isActive ? AppColors.shieldBlue : AppColors.darkGray,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_CustomerAccessContext>(
      future: _accessFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppPortalSectionSkeleton(
            showHero: true,
            statCards: 2,
            listItems: 4,
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return ErrorCard(
            title: 'Services unavailable',
            message:
                'Your membership access status could not be verified. Please try again.',
            onRetry: () =>
                setState(() => _accessFuture = _loadCustomerAccessContext()),
          );
        }

        final accessContext = snapshot.data!;
        final accessState = CustomerAccessState(
          customer: accessContext.customer,
          customerStatus: accessContext.customer.status,
          membership: accessContext.membership,
        );

        if (!accessState.serviceAccessEnabled) {
          return _buildPendingProductPreview();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildTabButton(
                    'PHARMACY',
                    'Pharmacy',
                    Icons.local_pharmacy_outlined,
                  ),
                  const SizedBox(width: 8),
                  _buildTabButton('LAB', 'Laboratory', Icons.biotech_outlined),
                  const SizedBox(width: 8),
                  _buildTabButton('HOMECARE', 'Home Care', Icons.home_outlined),
                  const SizedBox(width: 8),
                  _buildTabButton(
                    'CONSULTATION',
                    'Consultations',
                    Icons.people_outline,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildActiveTabContent(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPendingProductPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PendingCustomerAccessCard(
          title: 'Browse-only product access',
          message:
              'Your SHIELD profile is created, but member services remain locked until admin or agent card issuance. You can still browse the loaded product experience below.',
          primaryLabel: 'Membership status',
          primaryRoute: '/portal/customer/membership',
          secondaryLabel: 'Complete profile',
          secondaryRoute: '/portal/customer/profile',
        ),
        const SizedBox(height: 18),
        Text('Wellness catalogue', style: AppTypography.h4),
        const SizedBox(height: 12),
        _buildWellnessCatalogue(),
      ],
    );
  }

  Widget _buildWellnessCatalogue() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _wellnessProductsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator(minHeight: 2);
        }
        if (snapshot.hasError) {
          return AppCard(
            child: Row(
              children: [
                const Icon(Icons.cloud_off_outlined, color: AppColors.gray),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'The wellness catalogue could not be loaded.',
                    style: AppTypography.small.copyWith(color: AppColors.gray),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(_refreshWellnessProducts),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final catalogue = snapshot.data ?? const <String, dynamic>{};
        final products = ((catalogue['items'] as List?) ?? const [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        final categories = ((catalogue['categories'] as List?) ?? const [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        final pagination = Map<String, dynamic>.from(
          (catalogue['pagination'] as Map?) ?? const {},
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              catalogue['disclosure']?.toString() ??
                  'Demo products only — not live Sahakar inventory.',
              style: AppTypography.tiny.copyWith(color: AppColors.gray),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _wellnessSearchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _refreshWellnessProducts(),
              decoration: InputDecoration(
                hintText: 'Search wellness products',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _refreshWellnessProducts,
                ),
              ),
            ),
            if (categories.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _wellnessCategoryId == null,
                    onSelected: (_) {
                      _wellnessCategoryId = null;
                      _refreshWellnessProducts();
                    },
                  ),
                  ...categories.map(
                    (category) => ChoiceChip(
                      label: Text(category['name']?.toString() ?? 'Category'),
                      selected:
                          _wellnessCategoryId == category['id']?.toString(),
                      onSelected: (_) {
                        _wellnessCategoryId = category['id']?.toString();
                        _refreshWellnessProducts();
                      },
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            if (products.isEmpty)
              AppCard(
                child: Text(
                  _wellnessSearchController.text.trim().isEmpty
                      ? 'No wellness products are available right now.'
                      : 'No wellness products match your search. Try another name or category.',
                  style: AppTypography.small.copyWith(color: AppColors.gray),
                ),
              ),
            ...products.map((product) {
              final name =
                  product['productName']?.toString() ?? 'Wellness product';
              final unit = product['unit']?.toString();
              final price = num.tryParse(
                product['sellingPrice']?.toString() ?? '',
              );
              final priceLabel = price == null
                  ? 'Price unavailable'
                  : NumberFormat.currency(
                      locale: 'en_IN',
                      symbol: '₹',
                    ).format(price);
              final purchasable = product['purchasable'] == true;
              final availabilityMessage = product['purchasabilityReason']
                  ?.toString()
                  .trim();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => _showWellnessProduct(product),
                  borderRadius: BorderRadius.circular(16),
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.shieldBlue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.health_and_safety_outlined,
                            color: AppColors.shieldBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: AppTypography.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (unit != null && unit.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  unit,
                                  style: AppTypography.tiny.copyWith(
                                    color: AppColors.gray,
                                  ),
                                ),
                              ],
                              if (!purchasable) ...[
                                const SizedBox(height: 4),
                                Text(
                                  availabilityMessage?.isNotEmpty == true
                                      ? availabilityMessage!
                                      : 'Catalogue only — ordering is not available.',
                                  style: AppTypography.tiny.copyWith(
                                    color: AppColors.gray,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          priceLabel,
                          style: AppTypography.small.copyWith(
                            color: AppColors.shieldNavy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            if ((pagination['totalPages'] as num? ?? 1) > 1) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _wellnessPage > 1
                        ? () =>
                              _refreshWellnessProducts(page: _wellnessPage - 1)
                        : null,
                    child: const Text('Previous'),
                  ),
                  Text(
                    'Page ${pagination['page'] ?? 1} of ${pagination['totalPages'] ?? 1}',
                    style: AppTypography.tiny.copyWith(color: AppColors.gray),
                  ),
                  TextButton(
                    onPressed:
                        _wellnessPage < (pagination['totalPages'] as num? ?? 1)
                        ? () =>
                              _refreshWellnessProducts(page: _wellnessPage + 1)
                        : null,
                    child: const Text('Next'),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTab) {
      case 'PHARMACY':
        return _buildPharmacyContent();
      case 'LAB':
        return _buildLabContent();
      case 'HOMECARE':
        return _buildHomeCareContent();
      case 'CONSULTATION':
        return _buildConsultationContent();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPharmacyContent() {
    const regularProducts = <Map<String, String>>[];
    const recommendedProducts = <Map<String, String>>[];

    return Column(
      key: const ValueKey('PHARMACY_VIEW'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upload prescription
        AppCard(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stackUploadHeader = constraints.maxWidth < 320;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Digital Prescription Upload', style: AppTypography.h4),
                  const SizedBox(height: 6),
                  Text(
                    'Upload a prescription or tell us what you need. Our pharmacy team will review and prepare it for you.',
                    style: AppTypography.small.copyWith(color: AppColors.gray),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildSupportChip('PDF'),
                      _buildSupportChip('JPG'),
                      _buildSupportChip('PNG'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.lightGray,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (stackUploadHeader)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.shieldBlue.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.description_outlined,
                                  color: AppColors.shieldBlue,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _selectedPrescriptionName ??
                                    'Choose a prescription file',
                                style: AppTypography.small.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.darkGray,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _uploadStatus,
                                style: AppTypography.tiny.copyWith(
                                  color: _isUploadErrorStatus(_uploadStatus)
                                      ? AppColors.error
                                      : _isUploadSuccessStatus(_uploadStatus)
                                      ? AppColors.shieldGreen
                                      : AppColors.gray,
                                  fontWeight:
                                      _isUploadErrorStatus(_uploadStatus) ||
                                          _isUploadSuccessStatus(_uploadStatus)
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.shieldBlue.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.description_outlined,
                                  color: AppColors.shieldBlue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _selectedPrescriptionName ??
                                          'Choose a prescription file',
                                      style: AppTypography.small.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.darkGray,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _uploadStatus,
                                      style: AppTypography.tiny.copyWith(
                                        color:
                                            _isUploadErrorStatus(_uploadStatus)
                                            ? AppColors.error
                                            : _isUploadSuccessStatus(
                                                _uploadStatus,
                                              )
                                            ? AppColors.shieldGreen
                                            : AppColors.gray,
                                        fontWeight:
                                            _isUploadErrorStatus(
                                                  _uploadStatus,
                                                ) ||
                                                _isUploadSuccessStatus(
                                                  _uploadStatus,
                                                )
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        height: 1.25,
                                      ),
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 14),
                        AppButton(
                          text: _isUploading ? 'Processing...' : 'Choose File',
                          onPressed: _isUploading
                              ? null
                              : _handlePrescriptionUpload,
                          isLoading: _isUploading,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Prescription uploads are saved to your customer records for review.',
                          style: AppTypography.tiny.copyWith(
                            color: AppColors.gray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // Regularly purchased products
        const SizedBox.shrink(),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth < 340 ? 1 : 2;
            final gridAspectRatio = crossAxisCount == 1
                ? 3.1
                : (constraints.maxWidth < 420 ? 1.75 : 2.05);

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: regularProducts.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: gridAspectRatio,
              ),
              itemBuilder: (context, index) {
                final prod = regularProducts[index];
                return AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.shieldBlue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.medication_outlined,
                          color: AppColors.shieldBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              prod['name']!,
                              style: AppTypography.small.copyWith(
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${prod['qty']} • ${prod['price']}',
                              style: AppTypography.tiny.copyWith(
                                color: AppColors.gray,
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 28,
                          height: 28,
                        ),
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.add_shopping_cart,
                          color: AppColors.shieldGreen,
                          size: 18,
                        ),
                        onPressed: () {
                          showPortalSnackBar(
                            context,
                            'Added ${prod['name']} to cart',
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 24),

        // Patient recommendations slider
        const SizedBox.shrink(),
        const SizedBox(height: 12),
        SizedBox(
          height: 0,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: recommendedProducts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final prod = recommendedProducts[index];
              return Container(
                width: 220,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prod['name']!,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      prod['desc']!,
                      style: AppTypography.tiny.copyWith(color: AppColors.gray),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          prod['price']!,
                          style: AppTypography.small.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.shieldBlue,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            showPortalSnackBar(
                              context,
                              'Added ${prod['name']} to cart',
                            );
                          },
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _buildWellnessCatalogue(),
      ],
    );
  }

  Widget _buildLabContent() {
    return Column(
      key: const ValueKey('LAB_VIEW'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Laboratory services unavailable', style: AppTypography.h4),
        const SizedBox(height: 12),
        Text(
          'A customer-safe laboratory catalogue is not configured yet.',
          style: AppTypography.small.copyWith(color: AppColors.gray),
        ),
      ],
    );
  }

  Widget _buildHomeCareContent() {
    return Column(
      key: const ValueKey('HOMECARE_VIEW'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Home care services unavailable', style: AppTypography.h4),
        const SizedBox(height: 12),
        Text(
          'A customer-safe home-care catalogue is not configured yet.',
          style: AppTypography.small.copyWith(color: AppColors.gray),
        ),
      ],
    );
  }

  Widget _buildConsultationContent() {
    final specialistTypes = [
      {
        'key': 'DOCTOR',
        'label': 'Doctor Consultation',
        'icon': Icons.medical_services_outlined,
      },
      {'key': 'DENTAL', 'label': 'Dental Care', 'icon': Icons.mood_outlined},
      {
        'key': 'COSMETIC',
        'label': 'Cosmetic Care',
        'icon': Icons.face_outlined,
      },
      {
        'key': 'DIETITIAN',
        'label': 'Dietitian',
        'icon': Icons.restaurant_menu_outlined,
      },
    ];

    const dietPlans = <Map<String, String>>[];

    return Column(
      key: const ValueKey('CONSULTATION_VIEW'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Book Specialist Consultation', style: AppTypography.h4),
        const SizedBox(height: 16),

        // Specialist selector
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 360;
            final aspectRatio = narrow ? 1.6 : 1.95;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: specialistTypes.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: aspectRatio,
              ),
              itemBuilder: (context, index) {
                final type = specialistTypes[index];
                final isSelected = _specialistType == type['key'];
                return InkWell(
                  onTap: () => setState(() {
                    _specialistType = type['key'] as String;
                    _selectedProviderId = null;
                  }),
                  child: Container(
                    padding: EdgeInsets.all(narrow ? 12 : 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.shieldBlue.withValues(alpha: 0.1)
                          : AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.shieldBlue
                            : AppColors.divider,
                        width: isSelected ? 1.8 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          type['icon'] as IconData,
                          color: isSelected
                              ? AppColors.shieldBlue
                              : AppColors.darkGray,
                          size: narrow ? 24 : 26,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          type['label'] as String,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.small.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? AppColors.shieldBlue
                                : AppColors.darkGray,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 24),

        // Interactive booking form
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_specialistType Appointment Booking Form',
                style: AppTypography.h5,
              ),
              const SizedBox(height: 16),

              ShieldDateInputField(
                label: 'Select Slot Date',
                initialDate: _selectedDate,
                minDate: DateTime.now(),
                maxDate: DateTime.now().add(const Duration(days: 30)),
                onChanged: (value) {
                  setState(() {
                    _selectedDate = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _providersFuture,
                builder: (context, snapshot) {
                  final providers =
                      snapshot.data ?? const <Map<String, dynamic>>[];
                  final matchingProviders = _filterConsultationProviders(
                    providers,
                  );
                  final dropdownValue =
                      matchingProviders.any(
                        (provider) =>
                            provider['id']?.toString() == _selectedProviderId,
                      )
                      ? _selectedProviderId
                      : null;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _providerLabelForSpecialist(_specialistType),
                        style: AppTypography.small.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const LinearProgressIndicator(minHeight: 2)
                      else if (snapshot.hasError)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.lightGray,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.cloud_off_outlined,
                                color: AppColors.gray,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Providers could not be loaded right now.',
                                  style: AppTypography.small.copyWith(
                                    color: AppColors.gray,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => setState(
                                  () => _providersFuture =
                                      ApiService.getProviders(),
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      else if (matchingProviders.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.24),
                            ),
                          ),
                          child: Text(
                            'No active backend provider is available yet for this consultation type.',
                            style: AppTypography.small.copyWith(
                              color: AppColors.darkGray,
                            ),
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          initialValue: dropdownValue,
                          decoration: InputDecoration(
                            hintText: 'Select provider',
                            filled: true,
                            fillColor: AppColors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppColors.divider,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppColors.divider,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppColors.shieldBlue,
                              ),
                            ),
                          ),
                          items: matchingProviders.map((provider) {
                            final providerId = provider['id']?.toString() ?? '';
                            final providerName =
                                provider['providerName']?.toString() ??
                                provider['name']?.toString() ??
                                'Provider';
                            final businessName =
                                (provider['business']
                                        as Map<String, dynamic>?)?['name']
                                    ?.toString();
                            return DropdownMenuItem<String>(
                              value: providerId,
                              child: Text(
                                businessName == null || businessName.isEmpty
                                    ? providerName
                                    : '$providerName • $businessName',
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedProviderId = value;
                            });
                          },
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // Consultation Mode radio toggle
              Text(
                'Consultation Mode',
                style: AppTypography.small.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              RadioGroup<String>(
                groupValue: _consultationMode,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _consultationMode = val);
                  }
                },
                child: const Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _ConsultationModeOption(
                      value: 'IN_PERSON',
                      label: 'In-Person',
                    ),
                    _ConsultationModeOption(
                      value: 'TELE',
                      label: 'Tele-Consult',
                    ),
                    _ConsultationModeOption(
                      value: 'VIDEO',
                      label: 'Online Video',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Book Slot Button
              AppButton(
                text: 'Book Consultation Slot',
                onPressed: _handleBookAppointment,
                isLoading: _isBooking,
              ),
              if (_lastBookingStatus != null) ...[
                const SizedBox(height: 12),
                Text(
                  _lastBookingStatus!,
                  style: AppTypography.small.copyWith(
                    color: _lastBookingStatus!.contains('failed')
                        ? AppColors.error
                        : AppColors.shieldGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Dietitian specific Preset Plans
        if (_specialistType == 'DIETITIAN') ...[
          Text('Preset Nutrition Plans', style: AppTypography.h4),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dietPlans.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final plan = dietPlans[index];
              final isSelected = _selectedDietPlan == plan['name'];
              return AppCard(
                padding: const EdgeInsets.all(16),
                onTap: () => setState(() => _selectedDietPlan = plan['name']),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.shieldNavy.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.restaurant_outlined,
                        color: AppColors.shieldNavy,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan['name']!,
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${plan['focus']} • Target: ${plan['cal']}',
                            style: AppTypography.tiny.copyWith(
                              color: AppColors.gray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected
                          ? AppColors.shieldGreen
                          : AppColors.divider,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _AdminOperationsCenterView extends StatelessWidget {
  const _AdminOperationsCenterView();

  @override
  Widget build(BuildContext context) {
    const topStats = [
      (
        'Revenue Run Rate',
        '₹8.4L',
        '+11% vs last month • 3 branches above target',
        Icons.currency_rupee_rounded,
        AppColors.shieldNavy,
      ),
      (
        'Active Customers',
        '412',
        '36 need reactivation • 14 renewals due',
        Icons.people_alt_outlined,
        AppColors.shieldBlue,
      ),
      (
        'Provider Network',
        '12',
        '2 license reviews • 1 timing gap',
        Icons.local_hospital_outlined,
        AppColors.shieldGreen,
      ),
      (
        'Critical Exceptions',
        '9',
        '3 wallet • 4 approval • 2 audit',
        Icons.warning_amber_rounded,
        AppColors.warning,
      ),
    ];

    const quickActions = [
      ('Approve', 'Customer batch', Icons.fact_check_outlined),
      ('Assign', 'Provider review', Icons.apartment_outlined),
      ('Control', 'Commercial rules', Icons.tune_outlined),
      ('Export', 'Leadership pack', Icons.download_outlined),
    ];

    const queueItems = [
      (
        'Provider pricing misalignment',
        'Perinthalmanna pharmacy pricing needs rule review before next billing cycle.',
        'Commercial',
        'Attention',
      ),
      (
        'Role assignment cleanup',
        'Two branch users still have broader-than-needed permissions after last onboarding.',
        'Access',
        'Review',
      ),
      (
        'Referral reward backlog',
        'Three qualified referrals are waiting for reward posting and audit confirmation.',
        'Referral',
        'Pending',
      ),
      (
        'Campaign readiness',
        'Wellness camp campaign has audience selection ready but notification copy is still draft.',
        'Growth',
        'Draft',
      ),
    ];

    const healthRows = [
      ('Customers', 'Healthy', 'Approvals are within the same-day target.'),
      (
        'Wallet & Benefits',
        'Watch',
        'Manual adjustments spiked at Tirur and need audit attention.',
      ),
      (
        'Providers',
        'Healthy',
        'All active branches are billable; two provider records need documentation refresh.',
      ),
      (
        'CRM',
        'Focus',
        'Renewal callbacks are lagging in Alanallur and Makkaraparamba.',
      ),
      (
        'Notifications',
        'Healthy',
        'Push and SMS delivery remain above 98% this week.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final stack = constraints.maxWidth < 980;
                  final intro = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Operations Center',
                        style: AppTypography.h3.copyWith(
                          color: AppColors.shieldNavy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Search first, act fast, and keep governance visible across providers, customers, and commercial controls.',
                        style: AppTypography.small.copyWith(
                          color: AppColors.gray,
                          height: 1.35,
                        ),
                      ),
                    ],
                  );

                  final search = Container(
                    constraints: const BoxConstraints(maxWidth: 340),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        icon: Icon(Icons.search, color: AppColors.gray),
                        hintText: 'Search customer, provider, or rule',
                      ),
                    ),
                  );

                  final actions = Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: const [
                      _AdminFilterPill(
                        label: 'All branches',
                        icon: Icons.account_tree_outlined,
                        active: true,
                      ),
                      _AdminFilterPill(
                        label: 'This week',
                        icon: Icons.date_range_outlined,
                      ),
                      _AdminFilterPill(
                        label: 'Exceptions',
                        icon: Icons.error_outline_rounded,
                      ),
                      _AdminFilterPill(
                        label: 'Export',
                        icon: Icons.file_download_outlined,
                      ),
                    ],
                  );

                  if (stack) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        intro,
                        const SizedBox(height: 16),
                        search,
                        const SizedBox(height: 12),
                        actions,
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: intro),
                          const SizedBox(width: 16),
                          search,
                        ],
                      ),
                      const SizedBox(height: 14),
                      actions,
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 960;
            final statCards = Wrap(
              spacing: 14,
              runSpacing: 14,
              children: topStats.map((stat) {
                return SizedBox(
                  width: compact
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 42) / 4,
                  child: _AdminStatCard(
                    label: stat.$1,
                    value: stat.$2,
                    note: stat.$3,
                    icon: stat.$4,
                    accent: stat.$5,
                  ),
                );
              }).toList(),
            );

            return statCards;
          },
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final stack = constraints.maxWidth < 980;
            final left = AppCard(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Priority Queue', style: AppTypography.h4),
                  const SizedBox(height: 6),
                  Text(
                    'What deserves admin attention before more feature expansion.',
                    style: AppTypography.small.copyWith(color: AppColors.gray),
                  ),
                  const SizedBox(height: 18),
                  ...queueItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _AdminQueueTile(
                        title: item.$1,
                        subtitle: item.$2,
                        meta: item.$3,
                        status: item.$4,
                      ),
                    ),
                  ),
                ],
              ),
            );

            final right = Column(
              children: [
                AppCard(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quick Actions', style: AppTypography.h4),
                      const SizedBox(height: 6),
                      Text(
                        'Command-level shortcuts for the highest-leverage admin workflows.',
                        style: AppTypography.small.copyWith(
                          color: AppColors.gray,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ...quickActions.map(
                        (action) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _AdminQuickActionTile(
                            title: action.$1,
                            subtitle: action.$2,
                            icon: action.$3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                AppCard(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Platform Health', style: AppTypography.h4),
                      const SizedBox(height: 6),
                      Text(
                        'A role-driven status summary across SHIELD operational domains.',
                        style: AppTypography.small.copyWith(
                          color: AppColors.gray,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...healthRows.map(
                        (row) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _AdminHealthRow(
                            title: row.$1,
                            status: row.$2,
                            note: row.$3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );

            if (stack) {
              return Column(
                children: [left, const SizedBox(height: 18), right],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: left),
                const SizedBox(width: 18),
                Expanded(child: right),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AdminProviderNetworkView extends StatefulWidget {
  const _AdminProviderNetworkView();

  @override
  State<_AdminProviderNetworkView> createState() =>
      _AdminProviderNetworkViewState();
}

class _AdminProviderNetworkViewState extends State<_AdminProviderNetworkView> {
  List<Map<String, dynamic>> _providers = [];
  List<Map<String, dynamic>> _businesses = [];
  bool _isLoading = true;
  Map<String, dynamic> _analytics = {};
  String _selectedType = 'ALL';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final providers = await ApiService.getProviders();
      final businesses = await ApiService.getBusinesses();
      final analytics = await ApiService.getProviderAnalytics();
      setState(() {
        _providers = providers;
        _businesses = businesses;
        _analytics = analytics ?? {};
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddProviderDialog(BuildContext context) {
    final nameController = TextEditingController();
    String selectedType = 'CLINIC';
    String selectedStatus = 'ACTIVE';
    String? selectedBusinessId;

    if (_businesses.isNotEmpty) {
      selectedBusinessId = _businesses.first['id'].toString();
    }

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Add New Provider',
                style: AppTypography.h4.copyWith(color: AppColors.shieldNavy),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Provider Name',
                      style: AppTypography.tiny.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'Enter provider name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Provider Type',
                      style: AppTypography.tiny.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'CLINIC',
                          child: Text('Clinic'),
                        ),
                        DropdownMenuItem(
                          value: 'PHARMACY',
                          child: Text('Pharmacy'),
                        ),
                        DropdownMenuItem(
                          value: 'LABORATORY',
                          child: Text('Laboratory'),
                        ),
                        DropdownMenuItem(
                          value: 'DENTAL',
                          child: Text('Dental'),
                        ),
                        DropdownMenuItem(
                          value: 'HOME_VISIT',
                          child: Text('Homecare'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Branch / Business Assignment',
                      style: AppTypography.tiny.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedBusinessId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                        ),
                      ),
                      items: _businesses.map((biz) {
                        return DropdownMenuItem<String>(
                          value: biz['id'].toString(),
                          child: Text(biz['name']?.toString() ?? ''),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedBusinessId = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Initial Status',
                      style: AppTypography.tiny.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'ACTIVE',
                          child: Text('Active'),
                        ),
                        DropdownMenuItem(value: 'SETUP', child: Text('Setup')),
                        DropdownMenuItem(
                          value: 'INACTIVE',
                          child: Text('Inactive'),
                        ),
                        DropdownMenuItem(
                          value: 'SUSPENDED',
                          child: Text('Suspended'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedStatus = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    Navigator.pop(context);
                    setState(() => _isLoading = true);
                    await ApiService.createProvider({
                      'providerName': nameController.text.trim(),
                      'providerType': selectedType,
                      'businessId': selectedBusinessId,
                      'status': selectedStatus,
                    });
                    _loadData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.shieldBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Create',
                    style: TextStyle(color: AppColors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditProviderDialog(
    BuildContext context,
    Map<String, dynamic> provider,
  ) {
    final providerId = provider['id'].toString();
    final nameController = TextEditingController(
      text: provider['providerName']?.toString(),
    );
    String selectedType = provider['providerType']?.toString() ?? 'CLINIC';
    String selectedStatus = provider['status']?.toString() ?? 'ACTIVE';
    String? selectedBusinessId =
        provider['businessId']?.toString() ??
        provider['business']?['id']?.toString();

    if (selectedBusinessId != null &&
        !_businesses.any((b) => b['id'].toString() == selectedBusinessId)) {
      selectedBusinessId = null;
    }
    if (selectedBusinessId == null && _businesses.isNotEmpty) {
      selectedBusinessId = _businesses.first['id'].toString();
    }

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Edit Provider Details',
                style: AppTypography.h4.copyWith(color: AppColors.shieldNavy),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Provider Name',
                      style: AppTypography.tiny.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Provider Type',
                      style: AppTypography.tiny.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'CLINIC',
                          child: Text('Clinic'),
                        ),
                        DropdownMenuItem(
                          value: 'PHARMACY',
                          child: Text('Pharmacy'),
                        ),
                        DropdownMenuItem(
                          value: 'LABORATORY',
                          child: Text('Laboratory'),
                        ),
                        DropdownMenuItem(
                          value: 'DENTAL',
                          child: Text('Dental'),
                        ),
                        DropdownMenuItem(
                          value: 'HOME_VISIT',
                          child: Text('Homecare'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Branch / Business Assignment',
                      style: AppTypography.tiny.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedBusinessId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                        ),
                      ),
                      items: _businesses.map((biz) {
                        return DropdownMenuItem<String>(
                          value: biz['id'].toString(),
                          child: Text(biz['name']?.toString() ?? ''),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedBusinessId = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Status',
                      style: AppTypography.tiny.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'ACTIVE',
                          child: Text('Active'),
                        ),
                        DropdownMenuItem(value: 'SETUP', child: Text('Setup')),
                        DropdownMenuItem(
                          value: 'INACTIVE',
                          child: Text('Inactive'),
                        ),
                        DropdownMenuItem(
                          value: 'SUSPENDED',
                          child: Text('Suspended'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedStatus = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    Navigator.pop(context);
                    setState(() => _isLoading = true);
                    await ApiService.updateProvider(providerId, {
                      'providerName': nameController.text.trim(),
                      'providerType': selectedType,
                      'businessId': selectedBusinessId,
                      'status': selectedStatus,
                    });
                    _loadData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.shieldBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(color: AppColors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteProvider(
    BuildContext context,
    String providerId,
    String name,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Provider',
            style: TextStyle(
              color: Colors.red[800],
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "$name"? This action will remove the provider record from the network.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                Navigator.pop(context);
                setState(() => _isLoading = true);
                await ApiService.deleteProvider(providerId);
                _loadData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showProviderDetailsSheet(
    BuildContext context,
    Map<String, dynamic> provider,
  ) {
    final providerId = provider['id'].toString();
    final name = provider['providerName']?.toString() ?? '';
    final type = provider['providerType']?.toString() ?? '';
    final status = provider['status']?.toString() ?? '';
    final branchName =
        provider['business']?['name']?.toString() ?? 'Central Group';
    final owner = (provider['uuid']?.toString() ?? '')
        .split('-')
        .first
        .toUpperCase();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: AppTypography.h4.copyWith(
                          color: AppColors.shieldNavy,
                        ),
                      ),
                    ),
                    _AdminStatusBadge(label: status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Operational Details & Live Performance metrics.',
                  style: AppTypography.small.copyWith(color: AppColors.gray),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _AdminMetaChip(icon: Icons.category_outlined, label: type),
                    _AdminMetaChip(
                      icon: Icons.place_outlined,
                      label: branchName,
                    ),
                    _AdminMetaChip(
                      icon: Icons.person_outline_rounded,
                      label: 'Owner: $owner',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Live Performance Metrics',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                FutureBuilder<Map<String, dynamic>?>(
                  future: ApiService.getProviderPerformance(providerId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(
                            color: AppColors.shieldBlue,
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasError || snapshot.data == null) {
                      return Text(
                        'Failed to load performance metrics.',
                        style: AppTypography.small.copyWith(
                          color: AppColors.gray,
                        ),
                      );
                    }
                    final perf = snapshot.data!;
                    return GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.2,
                      children: [
                        _buildStatCard(
                          'Total Appointments',
                          perf['totalAppointments']?.toString() ?? '0',
                          Icons.event,
                        ),
                        _buildStatCard(
                          'Unique Patients',
                          perf['uniquePatients']?.toString() ?? '0',
                          Icons.people_outline,
                        ),
                        _buildStatCard(
                          'Completion Rate',
                          '${(perf['completionRate'] as num?)?.toStringAsFixed(1) ?? '0'}%',
                          Icons.check_circle_outline,
                        ),
                        _buildStatCard(
                          'Revenue Generated',
                          '₹${perf['revenue']?.toString() ?? '0'}',
                          Icons.currency_rupee,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditProviderDialog(context, provider);
                        },
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit Details'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _confirmDeleteProvider(context, providerId, name),
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: AppColors.white,
                        ),
                        label: const Text(
                          'Delete Provider',
                          style: TextStyle(color: AppColors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.shieldBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTypography.tiny.copyWith(color: AppColors.gray),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.small.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.shieldNavy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60.0),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.shieldBlue),
        ),
      );
    }

    final filteredProviders = _providers.where((provider) {
      final matchesType =
          _selectedType == 'ALL' || provider['providerType'] == _selectedType;
      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          (provider['providerName']?.toString() ?? '').toLowerCase().contains(
            query,
          ) ||
          (provider['business']?['name']?.toString() ?? '')
              .toLowerCase()
              .contains(query);
      return matchesType && matchesSearch;
    }).toList();

    final activeCount = _providers.where((p) => p['status'] == 'ACTIVE').length;
    final totalRevenue = _analytics['totalRevenue'] ?? 0;
    final totalAppointments = _analytics['totalAppointments'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Provider Network Command',
                          style: AppTypography.h3.copyWith(
                            color: AppColors.shieldNavy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'One centralized provider system for directory, services, users, readiness, and operational performance.',
                          style: AppTypography.body.copyWith(
                            color: AppColors.gray,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.shieldBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Network snapshot',
                          style: AppTypography.tiny.copyWith(
                            color: AppColors.shieldBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$activeCount active providers',
                          style: AppTypography.body,
                        ),
                        Text(
                          '${_businesses.length} branches',
                          style: AppTypography.body,
                        ),
                        Text(
                          '₹$totalRevenue total revenue',
                          style: AppTypography.body,
                        ),
                        Text(
                          '$totalAppointments total appts',
                          style: AppTypography.body,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: TextField(
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          icon: Icon(Icons.search, color: AppColors.gray),
                          hintText: 'Search provider or branch',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showAddProviderDialog(context),
                    icon: const Icon(
                      Icons.add,
                      color: AppColors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Add Provider',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.shieldBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _AdminFilterPill(
                    label: 'All providers',
                    icon: Icons.grid_view_rounded,
                    active: _selectedType == 'ALL',
                    onTap: () => setState(() => _selectedType = 'ALL'),
                  ),
                  _AdminFilterPill(
                    label: 'Pharmacy',
                    icon: Icons.local_pharmacy_outlined,
                    active: _selectedType == 'PHARMACY',
                    onTap: () => setState(() => _selectedType = 'PHARMACY'),
                  ),
                  _AdminFilterPill(
                    label: 'Clinic',
                    icon: Icons.medical_services_outlined,
                    active: _selectedType == 'CLINIC',
                    onTap: () => setState(() => _selectedType = 'CLINIC'),
                  ),
                  _AdminFilterPill(
                    label: 'Lab',
                    icon: Icons.science_outlined,
                    active: _selectedType == 'LABORATORY',
                    onTap: () => setState(() => _selectedType = 'LABORATORY'),
                  ),
                  _AdminFilterPill(
                    label: 'Dental',
                    icon: Icons.masks_outlined,
                    active: _selectedType == 'DENTAL',
                    onTap: () => setState(() => _selectedType = 'DENTAL'),
                  ),
                  _AdminFilterPill(
                    label: 'Homecare',
                    icon: Icons.home_work_outlined,
                    active: _selectedType == 'HOME_VISIT',
                    onTap: () => setState(() => _selectedType = 'HOME_VISIT'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final stack = constraints.maxWidth < 1040;
            final directory = AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Provider Directory', style: AppTypography.h4),
                  const SizedBox(height: 6),
                  Text(
                    'Centralized provider records instead of separate doctor, lab, and pharmacy CRUD silos.',
                    style: AppTypography.small.copyWith(color: AppColors.gray),
                  ),
                  const SizedBox(height: 18),
                  if (filteredProviders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text('No providers found matching filters.'),
                      ),
                    )
                  else
                    ...filteredProviders.map(
                      (provider) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AdminProviderRow(
                          provider: provider,
                          onTap: () =>
                              _showProviderDetailsSheet(context, provider),
                        ),
                      ),
                    ),
                ],
              ),
            );

            final side = Column(
              children: [
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Management Modules', style: AppTypography.h4),
                      SizedBox(height: 14),
                      _AdminMiniModuleTile(
                        title: 'Provider Directory',
                        subtitle: 'Identity, branch, category, and ownership',
                        icon: Icons.apartment_outlined,
                      ),
                      SizedBox(height: 10),
                      _AdminMiniModuleTile(
                        title: 'Provider Services',
                        subtitle:
                            'Capabilities, pricing, and enabled workflows',
                        icon: Icons.medical_services_outlined,
                      ),
                      SizedBox(height: 10),
                      _AdminMiniModuleTile(
                        title: 'Users & Licenses',
                        subtitle: 'Staff accounts, credentials, and renewals',
                        icon: Icons.badge_outlined,
                      ),
                      SizedBox(height: 10),
                      _AdminMiniModuleTile(
                        title: 'Timings & Holidays',
                        subtitle:
                            'Availability windows and operational closures',
                        icon: Icons.schedule_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Readiness Watchlist', style: AppTypography.h4),
                      const SizedBox(height: 14),
                      ..._providers.where((p) => p['status'] != 'ACTIVE').map((
                        p,
                      ) {
                        String readinessNote =
                            'Awaiting active setup verification.';
                        if (p['status'] == 'SETUP') {
                          readinessNote =
                              'Timings and operational schedules must be set up.';
                        } else if (p['status'] == 'SUSPENDED') {
                          readinessNote =
                              'Provider has been suspended by system administrator.';
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _AdminHealthRow(
                            title: p['providerName']?.toString() ?? '',
                            status: p['status']?.toString() ?? '',
                            note: readinessNote,
                          ),
                        );
                      }),
                      if (_providers.every((p) => p['status'] == 'ACTIVE'))
                        const Center(
                          child: Text('All providers are active and ready.'),
                        ),
                    ],
                  ),
                ),
              ],
            );

            if (stack) {
              return Column(
                children: [directory, const SizedBox(height: 18), side],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: directory),
                const SizedBox(width: 18),
                Expanded(flex: 2, child: side),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AdminMasterDataView extends StatefulWidget {
  const _AdminMasterDataView();

  @override
  State<_AdminMasterDataView> createState() => _AdminMasterDataViewState();
}

class _AdminMasterDataViewState extends State<_AdminMasterDataView> {
  String _selectedGroup = 'ALL';
  String _searchQuery = '';

  static const List<Map<String, String>> _domains = [
    {
      'name': 'Branches',
      'group': 'Organization',
      'owner': 'Admin',
      'records': '5 records',
      'status': 'Active',
      'note': 'Branch identity, territory linkage, and operational ownership.',
      'next': 'Review territory assignment',
    },
    {
      'name': 'Departments',
      'group': 'Organization',
      'owner': 'Admin',
      'records': '14 records',
      'status': 'Active',
      'note':
          'Department structure shared across admin, CRM, and provider teams.',
      'next': 'Confirm CRM/service handoff map',
    },
    {
      'name': 'Services',
      'group': 'Catalog',
      'owner': 'Admin',
      'records': '32 records',
      'status': 'Review',
      'note':
          'Central service catalog for customer, provider, and reporting flows.',
      'next': 'Normalize service naming',
    },
    {
      'name': 'Provider Types',
      'group': 'Catalog',
      'owner': 'Admin',
      'records': '7 records',
      'status': 'Open',
      'note':
          'Single taxonomy for pharmacy, lab, doctor, dental, homecare, and more.',
      'next': 'Align capabilities to each type',
    },
    {
      'name': 'Membership Plans',
      'group': 'Commercial',
      'owner': 'Admin',
      'records': '2 records',
      'status': 'Active',
      'note':
          'Founding and standard plan masters with fee and renewal governance.',
      'next': 'Preview renewal copy',
    },
    {
      'name': 'Benefit Rules',
      'group': 'Commercial',
      'owner': 'Admin',
      'records': '11 rules',
      'status': 'Review',
      'note':
          'Central benefit application rules, not portal-local discount logic.',
      'next': 'Check provider eligibility mapping',
    },
    {
      'name': 'Referral Rules',
      'group': 'Commercial',
      'owner': 'Admin',
      'records': '4 rules',
      'status': 'Active',
      'note':
          'Delayed, status-driven referral qualification and reward policy.',
      'next': 'Review pending campaign changes',
    },
    {
      'name': 'Wallet Rules',
      'group': 'Commercial',
      'owner': 'Admin',
      'records': '6 rules',
      'status': 'Review',
      'note':
          'Cash, reward points, and benefit-ledger control data for SHIELD.',
      'next': 'Validate recharge controls',
    },
    {
      'name': 'Holiday Calendar',
      'group': 'Operations',
      'owner': 'Admin',
      'records': '9 holidays',
      'status': 'Pending',
      'note':
          'Central closures for branches, providers, and downstream scheduling.',
      'next': 'Publish festival calendar',
    },
    {
      'name': 'Working Hours',
      'group': 'Operations',
      'owner': 'Admin',
      'records': '18 shifts',
      'status': 'Pending',
      'note':
          'Reusable slot and shift masters for appointments and provider timings.',
      'next': 'Confirm weekend rules',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredDomains = _domains.where((domain) {
      final matchesGroup =
          _selectedGroup == 'ALL' || domain['group'] == _selectedGroup;
      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          domain['name']!.toLowerCase().contains(query) ||
          domain['group']!.toLowerCase().contains(query) ||
          domain['note']!.toLowerCase().contains(query);
      return matchesGroup && matchesSearch;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Admin Master Data Console', style: AppTypography.h2),
              const SizedBox(height: 8),
              Text(
                'One workspace for organization, catalog, commercial, and operational masters that every other portal should consume.',
                style: AppTypography.body.copyWith(
                  color: AppColors.gray,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: const [
                  _AdminStatusOverviewChip(
                    label: '10 master groups',
                    icon: Icons.dataset_outlined,
                  ),
                  _AdminStatusOverviewChip(
                    label: '7 rule sets',
                    icon: Icons.rule_folder_outlined,
                  ),
                  _AdminStatusOverviewChip(
                    label: '3 pending reviews',
                    icon: Icons.pending_actions_outlined,
                  ),
                  _AdminStatusOverviewChip(
                    label: 'No hardcoded drift',
                    icon: Icons.shield_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: TextField(
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          icon: Icon(Icons.search, color: AppColors.gray),
                          hintText:
                              'Search master domain, owner, or governance note',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _AdminFilterPill(
                    label: 'All masters',
                    icon: Icons.grid_view_rounded,
                    active: _selectedGroup == 'ALL',
                    onTap: () => setState(() => _selectedGroup = 'ALL'),
                  ),
                  _AdminFilterPill(
                    label: 'Organization',
                    icon: Icons.account_tree_outlined,
                    active: _selectedGroup == 'Organization',
                    onTap: () =>
                        setState(() => _selectedGroup = 'Organization'),
                  ),
                  _AdminFilterPill(
                    label: 'Catalog',
                    icon: Icons.widgets_outlined,
                    active: _selectedGroup == 'Catalog',
                    onTap: () => setState(() => _selectedGroup = 'Catalog'),
                  ),
                  _AdminFilterPill(
                    label: 'Commercial',
                    icon: Icons.request_quote_outlined,
                    active: _selectedGroup == 'Commercial',
                    onTap: () => setState(() => _selectedGroup = 'Commercial'),
                  ),
                  _AdminFilterPill(
                    label: 'Operations',
                    icon: Icons.schedule_outlined,
                    active: _selectedGroup == 'Operations',
                    onTap: () => setState(() => _selectedGroup = 'Operations'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final stack = constraints.maxWidth < 1040;
            final directory = AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Domain Directory', style: AppTypography.h4),
                  const SizedBox(height: 6),
                  Text(
                    'These masters should own labels, types, rules, and operational defaults instead of scattering config through feature screens.',
                    style: AppTypography.small.copyWith(color: AppColors.gray),
                  ),
                  const SizedBox(height: 18),
                  ...filteredDomains.map(
                    (domain) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AdminMasterDomainRow(
                        domain: domain,
                        onTap: () {
                          showPortalDetailsSheet(
                            context,
                            title: domain['name']!,
                            subtitle: domain['note']!,
                            meta: '${domain['group']} • ${domain['records']}',
                            status: domain['status']!,
                            highlights: [
                              'Owner: ${domain['owner']}',
                              'Record volume: ${domain['records']}',
                              'Next action: ${domain['next']}',
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );

            const side = Column(
              children: [
                AppCard(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Control Modules', style: AppTypography.h4),
                      SizedBox(height: 14),
                      _AdminMiniModuleTile(
                        title: 'Organization',
                        subtitle:
                            'Branches, departments, territories, and ownership',
                        icon: Icons.apartment_outlined,
                      ),
                      SizedBox(height: 10),
                      _AdminMiniModuleTile(
                        title: 'Catalog',
                        subtitle:
                            'Service categories, services, and provider types',
                        icon: Icons.widgets_outlined,
                      ),
                      SizedBox(height: 10),
                      _AdminMiniModuleTile(
                        title: 'Commercial Rules',
                        subtitle:
                            'Membership, benefits, referral, and wallet controls',
                        icon: Icons.request_quote_outlined,
                      ),
                      SizedBox(height: 10),
                      _AdminMiniModuleTile(
                        title: 'Operational Calendar',
                        subtitle: 'Holidays, shifts, and working-hour defaults',
                        icon: Icons.event_available_outlined,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18),
                AppCard(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Readiness Watchlist', style: AppTypography.h4),
                      SizedBox(height: 14),
                      _AdminHealthRow(
                        title: 'Provider type taxonomy',
                        status: 'Open',
                        note:
                            'A single capability map is still needed before provider portal expansion.',
                      ),
                      SizedBox(height: 12),
                      _AdminHealthRow(
                        title: 'Working-hour standards',
                        status: 'Pending',
                        note:
                            'Appointment and provider timing defaults should be unified in one source.',
                      ),
                      SizedBox(height: 12),
                      _AdminHealthRow(
                        title: 'Commercial rule ownership',
                        status: 'Review',
                        note:
                            'Wallet, benefit, reward, and referral controls must stay inside the admin master layer.',
                      ),
                    ],
                  ),
                ),
              ],
            );

            if (stack) {
              return Column(
                children: [directory, const SizedBox(height: 18), side],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: directory),
                const SizedBox(width: 18),
                Expanded(flex: 2, child: side),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  const _AdminStatCard({
    required this.label,
    required this.value,
    required this.note,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final String note;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.small.copyWith(color: AppColors.gray),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTypography.h3.copyWith(
              color: AppColors.shieldNavy,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            note,
            style: AppTypography.tiny.copyWith(
              color: AppColors.darkGray,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminStatusOverviewChip extends StatelessWidget {
  const _AdminStatusOverviewChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.shieldBlue),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.small.copyWith(
              color: AppColors.shieldNavy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminQueueTile extends StatelessWidget {
  const _AdminQueueTile({
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.status,
  });

  final String title;
  final String subtitle;
  final String meta;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
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
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _AdminStatusBadge(label: status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTypography.small.copyWith(
              color: AppColors.darkGray,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            meta,
            style: AppTypography.tiny.copyWith(
              color: AppColors.gray,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminMasterDomainRow extends StatelessWidget {
  const _AdminMasterDomainRow({required this.domain, required this.onTap});

  final Map<String, String> domain;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    domain['name']!,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.shieldNavy,
                    ),
                  ),
                ),
                _AdminStatusBadge(label: domain['status']!),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _AdminMetaChip(
                  icon: Icons.folder_open_outlined,
                  label: domain['group']!,
                ),
                _AdminMetaChip(
                  icon: Icons.inventory_2_outlined,
                  label: domain['records']!,
                ),
                _AdminMetaChip(
                  icon: Icons.person_outline_rounded,
                  label: domain['owner']!,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              domain['note']!,
              style: AppTypography.small.copyWith(
                color: AppColors.darkGray,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'Next',
                  style: AppTypography.tiny.copyWith(
                    color: AppColors.gray,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    domain['next']!,
                    style: AppTypography.tiny.copyWith(
                      color: AppColors.shieldBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminQuickActionTile extends StatelessWidget {
  const _AdminQuickActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.shieldBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: AppColors.shieldBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.small.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.tiny.copyWith(color: AppColors.gray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminHealthRow extends StatelessWidget {
  const _AdminHealthRow({
    required this.title,
    required this.status,
    required this.note,
  });

  final String title;
  final String status;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.small.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                note,
                style: AppTypography.tiny.copyWith(
                  color: AppColors.gray,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _AdminStatusBadge(label: status),
      ],
    );
  }
}

class _AdminProviderRow extends StatelessWidget {
  const _AdminProviderRow({required this.provider, required this.onTap});

  final Map<String, dynamic> provider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = provider['providerName']?.toString() ?? '';
    final type = provider['providerType']?.toString() ?? '';
    final status = provider['status']?.toString() ?? '';
    final branchName =
        provider['business']?['name']?.toString() ?? 'Central Group';
    final owner = (provider['uuid']?.toString() ?? '')
        .split('-')
        .first
        .toUpperCase();

    String services = 'General Healthcare Services';
    if (type == 'PHARMACY') {
      services = 'Billing, prescriptions, wallet settlement';
    } else if (type == 'CLINIC') {
      services = 'Consultations, reports, appointments';
    } else if (type == 'LABORATORY') {
      services = 'Tests, reports, collections';
    } else if (type == 'DENTAL') {
      services = 'Procedures, recalls, image uploads';
    } else if (type == 'HOME_VISIT') {
      services = 'Route visits, nurse assignments, follow-ups';
    }

    String readiness = 'Pending Setup';
    if (status == 'ACTIVE') {
      readiness = 'Ready';
    } else if (status == 'SETUP') {
      readiness = 'Needs Timings';
    } else if (status == 'SUSPENDED') {
      readiness = 'Suspended';
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.shieldNavy,
                    ),
                  ),
                ),
                _AdminStatusBadge(label: status),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _AdminMetaChip(icon: Icons.category_outlined, label: type),
                _AdminMetaChip(icon: Icons.place_outlined, label: branchName),
                _AdminMetaChip(
                  icon: Icons.person_outline_rounded,
                  label: owner,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              services,
              style: AppTypography.small.copyWith(
                color: AppColors.darkGray,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'Readiness',
                  style: AppTypography.tiny.copyWith(
                    color: AppColors.gray,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                _AdminStatusBadge(label: readiness),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminMiniModuleTile extends StatelessWidget {
  const _AdminMiniModuleTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.shieldNavy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: AppColors.shieldNavy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.small.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.tiny.copyWith(color: AppColors.gray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminMetaChip extends StatelessWidget {
  const _AdminMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.gray),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.tiny),
        ],
      ),
    );
  }
}

class _AdminStatusBadge extends StatelessWidget {
  const _AdminStatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final normalized = label.toLowerCase();
    final color = normalized.contains('ready') || normalized.contains('healthy')
        ? AppColors.shieldGreen
        : normalized.contains('pending') ||
              normalized.contains('watch') ||
              normalized.contains('review') ||
              normalized.contains('due')
        ? AppColors.warning
        : normalized.contains('draft') ||
              normalized.contains('setup') ||
              normalized.contains('needs')
        ? AppColors.shieldBlue
        : AppColors.error;

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
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AdminFilterPill extends StatelessWidget {
  const _AdminFilterPill({
    required this.label,
    required this.icon,
    this.active = false,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? AppColors.shieldNavy.withValues(alpha: 0.08)
              : AppColors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? AppColors.shieldNavy : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: active ? AppColors.shieldNavy : AppColors.gray,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.small.copyWith(
                color: active ? AppColors.shieldNavy : AppColors.darkGray,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
