import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../customer/dashboard/presentation/screens/dashboard_screen.dart';
import '../../../customer/membership/presentation/screens/membership_screen.dart';
import '../../../customer/shared/domain/customer_access_state.dart';
import '../../../customer/wallet/presentation/screens/wallet_screen.dart';
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
import '../../../../shared/services/api_service.dart';
import '../../../../shared/services/customer_auth_session.dart';
import '../../../../shared/utils/prescription_file_picker.dart';
import '../../../../shared/widgets/customer_support_sheet.dart';
import '../../../../shared/widgets/portal_support.dart';
import '../portal_role_data.dart';

class PortalShell extends StatefulWidget {
  final SHIELDRole role;
  final String? sectionKey;

  const PortalShell({super.key, required this.role, required this.sectionKey});

  @override
  State<PortalShell> createState() => _PortalShellState();
}

class _PortalShellState extends State<PortalShell> {
  bool _isLoading = true;
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
      final data = await ApiService.getRoleSectionData(widget.role, sectionKey);
      if (!mounted) return;
      setState(() {
        _sectionData = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
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
    final portal = portalDataForRole(widget.role);
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
        appBar: AppBar(title: Text(portal.role.label)),
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
                          body: _RoleContent(portal: portal, section: section),
                        ),
                      ),
                    ),
                  );
                },
              )
            : Row(
                children: [
                  _InternalPortalSidebar(
                    portal: portal,
                    activeSectionKey: activeKey,
                    collapsed: !_isInternalSidebarExpanded,
                  ),
                  Expanded(
                    child: Scaffold(
                      backgroundColor: AppColors.lightGray,
                      body: _RoleContent(
                        portal: portal,
                        section: section,
                        onSidebarToggle: _toggleInternalSidebar,
                        isSidebarExpanded: _isInternalSidebarExpanded,
                      ),
                    ),
                  ),
                ],
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
    case 'wallet':
    case 'wallet-ops':
      return Icons.account_balance_wallet_outlined;
    case 'services':
      return Icons.medical_services_outlined;
    case 'appointments':
    case 'book-appointment':
      return Icons.event_note_outlined;
    case 'documents':
    case 'reports':
      return Icons.description_outlined;
    case 'profile':
    case 'users':
      return Icons.person_outline_rounded;
    case 'membership':
    case 'membership-plans':
      return Icons.workspace_premium_outlined;
    case 'prescriptions':
      return Icons.receipt_long_outlined;
    case 'notifications':
    case 'notification-center':
      return Icons.notifications_none_rounded;
    case 'settings':
    case 'system':
      return Icons.settings_outlined;
    case 'customers':
    case 'patients':
      return Icons.groups_outlined;
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
      return Icons.badge_outlined;
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
  final VoidCallback? onSidebarToggle;
  final bool isSidebarExpanded;

  const _RoleContent({
    required this.portal,
    required this.section,
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
        portal.role == SHIELDRole.customer && section.key == 'membership';
    final isCustomerServices =
        portal.role == SHIELDRole.customer && section.key == 'services';
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
    final isCustomerSettings =
        portal.role == SHIELDRole.customer && section.key == 'settings';
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

    if (isAdminDashboard) {
      content = const _AdminOperationsCenterView();
    } else if (isCustomerProfile) {
      content = const _CustomerProfilePortalView();
    } else if (isCustomerDashboard) {
      content = const CustomerDashboardScreen();
    } else if (isCustomerMembership) {
      content = const CustomerMembershipScreen();
    } else if (isCustomerServices) {
      content = const _CustomerServicesView();
    } else if (isCustomerAppointments) {
      content = _CustomerProtectedSection(
        sectionKey: section.key,
        child: _CustomerAppointmentsView(section: section),
      );
    } else if (isCustomerNotifications) {
      content = _CustomerNotificationsView(section: section);
    } else if (isCustomerDocuments) {
      content = const _CustomerDocumentsView();
    } else if (isCustomerPrescriptions) {
      content = const _CustomerPrescriptionsView();
    } else if (isCustomerWallet) {
      content = const CustomerWalletScreen();
    } else if (isCustomerSettings) {
      content = const _CustomerSettingsView();
    } else if (isCardUtilization) {
      content = const _CardUtilizationView();
    } else if (isAdminBusinesses) {
      content = const _AdminProviderNetworkView();
    } else if (isAdminMasterData) {
      content = const _AdminMasterDataView();
    } else if (isAdminAudit) {
      content = const _ServiceUtilizationView();
    } else if (isCrmSection) {
      content = _CrmWorkspaceView(section: section);
    } else if (isReportsSection) {
      content = const _AdminReportsView();
    } else {
      content = _EnterpriseWorkspaceView(portal: portal, section: section);
    }

    final customerContentOwnsScroll =
        isCustomerDashboard || isCustomerMembership || isCustomerWallet;

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
}

class _InternalPortalSidebar extends StatelessWidget {
  final PortalRoleData portal;
  final String activeSectionKey;
  final bool collapsed;

  const _InternalPortalSidebar({
    required this.portal,
    required this.activeSectionKey,
    required this.collapsed,
  });

  @override
  Widget build(BuildContext context) {
    if (portal.role == SHIELDRole.superAdmin) {
      return _AdminPortalNav(
        portal: portal,
        activeSectionKey: activeSectionKey,
        inDrawer: false,
        collapsed: collapsed,
      );
    }

    return _RoleRailNav(
      portal: portal,
      activeSectionKey: activeSectionKey,
      collapsed: collapsed,
    );
  }
}

class _RoleRailNav extends StatelessWidget {
  const _RoleRailNav({
    required this.portal,
    required this.activeSectionKey,
    required this.collapsed,
  });

  final PortalRoleData portal;
  final String activeSectionKey;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final width = collapsed ? 92.0 : 276.0;

    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(right: BorderSide(color: AppColors.divider)),
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
                final icon = _portalSectionIcon(section.key);
                final tile = InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.go(
                    '/portal/${portal.role.routeKey}/${section.key}',
                  ),
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
        const SizedBox(width: 12),
        _RoleSwitcher(portal: portal),
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

  static const List<List<String>> _groups = [
    ['dashboard', 'wallet', 'services', 'appointments', 'documents'],
    ['membership', 'profile', 'prescriptions'],
    ['notifications', 'settings'],
  ];

  @override
  Widget build(BuildContext context) {
    final content = FutureBuilder<List<dynamic>>(
      future: Future.wait<dynamic>([
        ApiService.getCustomerProfile(ApiService.requireAuthenticatedCustomerId()),
        ApiService.getWalletProfile(ApiService.requireAuthenticatedCustomerId()),
      ]),
      builder: (context, snapshot) {
        final customer = snapshot.hasData ? snapshot.data![0] as Customer : null;
        final wallet = snapshot.hasData
            ? snapshot.data![1] as Map<String, dynamic>
            : const <String, dynamic>{};
        final balance =
            double.tryParse(wallet['balance']?.toString() ?? '0') ?? 0.0;
        final accessState = customer == null
            ? null
            : CustomerAccessState(
                customer: customer,
                customerStatus: customer.status,
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
                      customer?.fullName ?? portal.operatorName,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
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
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightGray,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: AppColors.shieldBlue,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              accessState?.serviceAccessEnabled == true
                                  ? 'Wallet balance'
                                  : 'Wallet unlocks after card issue',
                              style: AppTypography.tiny.copyWith(
                                color: AppColors.gray,
                              ),
                            ),
                          ),
                          Text(
                            '₹${balance.toStringAsFixed(0)}',
                            style: AppTypography.small.copyWith(
                              color: AppColors.shieldBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
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
                    final groupKeys = _groups[groupIndex];
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
                      children: items.map((section) {
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
                                    ? portal.accentColor.withValues(alpha: 0.12)
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
                      }).toList(),
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
    MapEntry('Operations', ['dashboard', 'audit']),
    MapEntry('People', ['users']),
    MapEntry('Provider Network', ['businesses']),
    MapEntry('Commercial', ['membership-plans']),
    MapEntry('Reports', ['reports']),
    MapEntry('System', ['roles', 'notification-center', 'system']),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<SHIELDRole>(
          value: portal.role,
          items: SHIELDRole.values.map((role) {
            return DropdownMenuItem(
              value: role,
              child: Text(role.label, style: AppTypography.small),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              context.go('/portal/${value.routeKey}/dashboard');
            }
          },
        ),
      ),
    );
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

  showPortalSnackBar(
    context,
    '$action is available as a portal interaction preview.',
  );
}

void _showMembershipCardDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Digital privilege card', style: AppTypography.h4),
              const SizedBox(height: 14),
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
                      'SHIELD FOUNDING MEMBER',
                      style: AppTypography.tiny.copyWith(
                        color: AppColors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'SHLD-2026-123456',
                      style: AppTypography.h4.copyWith(color: AppColors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Nihal Rahman',
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
}

void _showPrescriptionUploadPicker(BuildContext context) {
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
              Text('Upload prescription', style: AppTypography.h4),
              const SizedBox(height: 8),
              Text(
                'Choose how you want to add the prescription file.',
                style: AppTypography.small.copyWith(color: AppColors.gray),
              ),
              const SizedBox(height: 18),
              _BottomActionTile(
                icon: Icons.picture_as_pdf_outlined,
                title: 'Choose PDF',
                subtitle: 'Upload a stored doctor prescription PDF',
                onTap: () {
                  Navigator.pop(context);
                  showPortalSnackBar(
                    context,
                    'PDF picker opened in frontend flow.',
                  );
                },
              ),
              _BottomActionTile(
                icon: Icons.photo_library_outlined,
                title: 'Choose image',
                subtitle: 'Pick a prescription image from the device',
                onTap: () {
                  Navigator.pop(context);
                  showPortalSnackBar(
                    context,
                    'Image picker opened in frontend flow.',
                  );
                },
              ),
              _BottomActionTile(
                icon: Icons.camera_alt_outlined,
                title: 'Scan now',
                subtitle: 'Capture a prescription photo using the camera',
                onTap: () {
                  Navigator.pop(context);
                  showPortalSnackBar(
                    context,
                    'Camera capture opened in frontend flow.',
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
      final customer = await ApiService.getCustomerProfile(
        ApiService.requireAuthenticatedCustomerId(),
      );
      if (!mounted) return;
      _hydrateForm(customer);
      setState(() {
        _customer = customer;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
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
      final savedCustomer = await ApiService.updateCustomerProfile(
        _customer!.id,
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
        _error = error.toString();
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.fullName.toUpperCase(),
                            style: AppTypography.body.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.7,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            customer.customerCode,
                            style: AppTypography.small.copyWith(
                              color: AppColors.white.withValues(alpha: 0.84),
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
                        color: AppColors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        customer.status.toUpperCase(),
                        style: AppTypography.tiny.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ProfileSummaryChip(
                      label: customer.mobile,
                      icon: Icons.phone_iphone_outlined,
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
                      onTap: () {
                        if (_isEditing) {
                          _hydrateForm(customer);
                        }
                        setState(() {
                          _isEditing = !_isEditing;
                          _error = null;
                        });
                      },
                    ),
                    _HeroActionGridItem(
                      label: customer.status.toUpperCase() == 'ACTIVE'
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
      ApiService.getCustomerProfile(ApiService.requireAuthenticatedCustomerId()),
      ApiService.getCustomerMembership(ApiService.requireAuthenticatedCustomerId()),
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
              'Membership preview unavailable',
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

class _CustomerSettingsView extends StatefulWidget {
  const _CustomerSettingsView();

  @override
  State<_CustomerSettingsView> createState() => _CustomerSettingsViewState();
}

class _CustomerSettingsViewState extends State<_CustomerSettingsView> {
  bool _pushAlerts = true;
  bool _smsAlerts = true;
  bool _walletUpdates = true;
  bool _sharedCare = true;

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
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _StatusPill(
                    label: _pushAlerts ? 'Push alerts on' : 'Push alerts off',
                    color: _pushAlerts ? AppColors.shieldBlue : AppColors.gray,
                  ),
                  _StatusPill(
                    label: _sharedCare
                        ? 'Shared care enabled'
                        : 'Private profile',
                    color: _sharedCare
                        ? AppColors.shieldGreen
                        : AppColors.error,
                  ),
                  const _StatusPill(
                    label: 'Device secured',
                    color: AppColors.shieldNavy,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SettingsGroupCard(
          title: 'Notifications',
          subtitle: 'Choose how SHIELD reaches you.',
          children: [
            _CompactSettingToggle(
              icon: Icons.notifications_active_outlined,
              title: 'Push alerts',
              subtitle: 'Appointments, wallet credits, and reminders',
              value: _pushAlerts,
              onChanged: (value) => setState(() => _pushAlerts = value),
            ),
            _CompactSettingToggle(
              icon: Icons.sms_outlined,
              title: 'SMS alerts',
              subtitle: 'OTP and time-sensitive updates',
              value: _smsAlerts,
              onChanged: (value) => setState(() => _smsAlerts = value),
            ),
            _CompactSettingToggle(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Wallet updates',
              subtitle: 'Recharge, spend, and points changes',
              value: _walletUpdates,
              onChanged: (value) => setState(() => _walletUpdates = value),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SettingsGroupCard(
          title: 'Privacy and care',
          subtitle: 'Manage profile sharing and healthcare access.',
          children: [
            _CompactSettingToggle(
              icon: Icons.health_and_safety_outlined,
              title: 'Shared care profile',
              subtitle: 'Allow approved providers to view linked records',
              value: _sharedCare,
              onChanged: (value) => setState(() => _sharedCare = value),
            ),
            _CompactSettingAction(
              icon: Icons.lock_outline,
              title: 'Change app PIN',
              subtitle: 'Update your local access code',
              onTap: () => showPortalSnackBar(
                context,
                'PIN update flow is available as a frontend-only placeholder.',
              ),
            ),
            _CompactSettingAction(
              icon: Icons.badge_outlined,
              title: 'Manage member identity',
              subtitle: 'Review profile, address, and membership details',
              onTap: () => context.go('/portal/customer/profile'),
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
              title: 'Help center',
              subtitle: 'Troubleshooting and FAQs',
              onTap: () => showPortalSnackBar(
                context,
                'Help center content is represented as a frontend-only support flow.',
              ),
            ),
            _CompactSettingAction(
              icon: Icons.verified_user_outlined,
              title: 'Privacy policy',
              subtitle: 'Review how SHIELD handles member data',
              onTap: () => showPortalDetailsSheet(
                context,
                title: 'Privacy policy preview',
                subtitle:
                    'This preview summarizes customer-facing data usage until policy content is wired from backend content services.',
                meta: 'Settings',
                status: 'Frontend flow',
                highlights: const [
                  'Medical records stay restricted to approved provider workflows.',
                  'Notification preferences remain configurable from the customer app.',
                ],
              ),
            ),
            _CompactSettingAction(
              icon: Icons.contact_support_outlined,
              title: 'Contact us',
              subtitle: 'Reach SHIELD support for membership or service issues',
              onTap: () => showCustomerSupportSheet(
                context,
                type: SupportSheetType.contact,
              ),
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
              icon: Icons.logout_rounded,
              title: 'Sign out',
              subtitle: 'Clear the current customer session on this device',
              destructive: true,
              onTap: () async {
                await CustomerAuthSession.instance.signOut();
                if (context.mounted) {
                  context.go('/customer/login');
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _StaticActionChip extends StatelessWidget {
  const _StaticActionChip({
    required this.label,
    required this.onTap,
  });

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
              Expanded(
                child: Text(title, style: AppTypography.h4),
              ),
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

class _CustomerProtectedSection extends StatelessWidget {
  const _CustomerProtectedSection({
    required this.sectionKey,
    required this.child,
  });

  final String sectionKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Customer>(
      future: ApiService.getCustomerProfile(
        ApiService.requireAuthenticatedCustomerId(),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const AppPortalSectionSkeleton(
            showHero: true,
            statCards: 2,
            listItems: 3,
          );
        }

        final customer = snapshot.data!;
        final accessState = CustomerAccessState(
          customer: customer,
          customerStatus: customer.status,
        );

        if (accessState.serviceAccessEnabled) {
          return child;
        }

        switch (sectionKey) {
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
            return child;
        }
      },
    );
  }
}

class _CustomerDocumentsView extends StatelessWidget {
  const _CustomerDocumentsView();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Customer>(
      future: ApiService.getCustomerProfile(
        ApiService.requireAuthenticatedCustomerId(),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const AppPortalSectionSkeleton(
            showHero: true,
            statCards: 2,
            listItems: 3,
          );
        }

        final customer = snapshot.data!;
        final accessState = CustomerAccessState(
          customer: customer,
          customerStatus: customer.status,
        );

        if (!accessState.serviceAccessEnabled) {
          return const _PendingCustomerAccessCard(
            title: 'Documents unlock after card issue',
            message:
                'Document uploads, linked care files, and member-record access stay locked until SHIELD issues the customer membership card.',
            primaryLabel: 'Membership status',
            primaryRoute: '/portal/customer/membership',
            secondaryLabel: 'Complete profile',
            secondaryRoute: '/portal/customer/profile',
          );
        }

        return const _PendingCustomerAccessCard(
          title: 'Documents migration in progress',
          message:
              'This customer route has been reserved for the backend-driven document experience and is being extracted away from older static portal content.',
          primaryLabel: 'Open notifications',
          primaryRoute: '/portal/customer/notifications',
          secondaryLabel: 'Open profile',
          secondaryRoute: '/portal/customer/profile',
        );
      },
    );
  }
}

class _CustomerPrescriptionsView extends StatelessWidget {
  const _CustomerPrescriptionsView();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Customer>(
      future: ApiService.getCustomerProfile(
        ApiService.requireAuthenticatedCustomerId(),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const AppPortalSectionSkeleton(
            showHero: true,
            statCards: 2,
            listItems: 3,
          );
        }

        final customer = snapshot.data!;
        final accessState = CustomerAccessState(
          customer: customer,
          customerStatus: customer.status,
        );

        if (!accessState.serviceAccessEnabled) {
          return const _PendingCustomerAccessCard(
            title: 'Prescriptions stay pending',
            message:
                'Prescription uploads and pharmacy-linked care actions are blocked until the SHIELD membership card is issued. You can still browse loaded products.',
            primaryLabel: 'Browse products',
            primaryRoute: '/portal/customer/services',
            secondaryLabel: 'Membership status',
            secondaryRoute: '/portal/customer/membership',
          );
        }

        return const _PendingCustomerAccessCard(
          title: 'Prescriptions route reserved',
          message:
              'The dedicated prescription workflow is being moved out of older static portal content and into the customer production slice.',
          primaryLabel: 'Open services',
          primaryRoute: '/portal/customer/services',
          secondaryLabel: 'Open notifications',
          secondaryRoute: '/portal/customer/notifications',
        );
      },
    );
  }
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
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Appointments unavailable', style: AppTypography.h4),
                const SizedBox(height: 8),
                Text(
                  'The customer appointment feed could not be loaded.',
                  style: AppTypography.small.copyWith(color: AppColors.gray),
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: 'Retry',
                  onPressed: () => setState(_loadAppointments),
                ),
              ],
            ),
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
            ...visibleList.map(
              (appointment) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  padding: const EdgeInsets.all(14),
                  onTap: () => showPortalDetailsSheet(
                    context,
                    title: appointment.doctorName ?? appointment.typeLabel,
                    subtitle: appointment.notes ?? 'Customer appointment entry',
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
                          if (appointment.status == AppointmentStatus.scheduled)
                            TextButton(
                              onPressed: () => _cancelAppointment(appointment),
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
  late Future<List<NotificationModel>> _notificationsFuture;
  NotificationType? _activeType;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    _notificationsFuture = ApiService.getNotifications(SHIELDRole.customer);
  }

  Future<void> _markAllRead(List<NotificationModel> notifications) async {
    final unread = notifications.where((notification) => !notification.isRead);
    for (final notification in unread) {
      await ApiService.markNotificationRead(notification.id);
    }
    if (!mounted) return;
    setState(_loadNotifications);
    showPortalSnackBar(context, 'All unread notifications marked as read.');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NotificationModel>>(
      future: _notificationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppPortalSectionSkeleton(
            showHero: true,
            statCards: 3,
            listItems: 5,
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
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

        final notifications = snapshot.data!;
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
                  onTap: () async {
                    await ApiService.markNotificationRead(notification.id);
                    if (!context.mounted) return;
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
                  },
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
          ],
        );
      },
    );
  }
}

Color _appointmentAccent(AppointmentStatus status) {
  switch (status) {
    case AppointmentStatus.completed:
      return AppColors.shieldGreen;
    case AppointmentStatus.cancelled:
      return AppColors.error;
    case AppointmentStatus.rescheduled:
      return AppColors.warning;
    case AppointmentStatus.scheduled:
      return AppColors.shieldBlue;
  }
}

IconData _appointmentIcon(AppointmentStatus status) {
  switch (status) {
    case AppointmentStatus.completed:
      return Icons.task_alt_rounded;
    case AppointmentStatus.cancelled:
      return Icons.cancel_outlined;
    case AppointmentStatus.rescheduled:
      return Icons.update_rounded;
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

class _CompactSettingToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CompactSettingToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: Icon(icon, color: AppColors.shieldBlue, size: 20),
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.shieldBlue,
          ),
        ],
      ),
    );
  }
}

class _CompactSettingAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  const _CompactSettingAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
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
            Icon(Icons.chevron_right_rounded, color: accent),
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

class _BottomActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _BottomActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
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
                child: Icon(icon, color: AppColors.shieldBlue, size: 20),
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
              const Icon(Icons.chevron_right_rounded, color: AppColors.gray),
            ],
          ),
        ),
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
  late Future<Customer> _customerFuture;
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

  @override
  void initState() {
    super.initState();
    _customerFuture = ApiService.getCustomerProfile(
      ApiService.requireAuthenticatedCustomerId(),
    );
  }

  @override
  void dispose() {
    _manualMedicineController.dispose();
    super.dispose();
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
      final responseMessage = error.response?.data is Map<String, dynamic>
          ? (error.response!.data['message']?.toString() ??
                error.response!.data['error']?.toString())
          : null;
      if (responseMessage != null && responseMessage.trim().isNotEmpty) {
        return responseMessage.trim();
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Prescription upload is taking longer than expected. Please check your connection and retry.';
      }
      return error.message ?? 'Upload failed unexpectedly.';
    }

    return error.toString().replaceFirst('Exception: ', '').trim().isEmpty
        ? 'Upload failed unexpectedly.'
        : error.toString().replaceFirst('Exception: ', '').trim();
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

    const providerMap = {
      'DOCTOR': '1',
      'DENTAL': '2',
      'COSMETIC': '3',
      'DIETITIAN': '4',
    };

    const appointmentTypeMap = {
      'DOCTOR': 'CLINIC',
      'DENTAL': 'DENTAL',
      'COSMETIC': 'CLINIC',
      'DIETITIAN': 'CLINIC',
    };

    try {
      final appointment = await ApiService.createCustomerAppointment(
        providerId: providerMap[_specialistType] ?? '1',
        appointmentType: appointmentTypeMap[_specialistType] ?? 'CLINIC',
        appointmentDate: _selectedDate,
        remarks: '$_specialistType consultation via $_consultationMode',
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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isBooking = false;
        _lastBookingStatus = 'Booking failed. Please retry.';
      });
      showPortalSnackBar(
        context,
        'Appointment booking is unavailable right now. Please retry shortly.',
      );
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
    return FutureBuilder<Customer>(
      future: _customerFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const AppPortalSectionSkeleton(
            showHero: true,
            statCards: 2,
            listItems: 4,
          );
        }

        final customer = snapshot.data!;
        final accessState = CustomerAccessState(
          customer: customer,
          customerStatus: customer.status,
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
    const products = [
      {
        'name': 'Omega-3 Fish Oil',
        'price': '₹650.00',
        'desc': 'Heart and joint health',
      },
      {
        'name': 'Vitamin D3 60K',
        'price': '₹150.00',
        'desc': 'Bone strength support',
      },
      {
        'name': 'Multi-Vitamin Daily',
        'price': '₹240.00',
        'desc': 'Loaded wellness support',
      },
    ];

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
        Text('Loaded products', style: AppTypography.h4),
        const SizedBox(height: 12),
        ...products.map(
          (product) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.shieldBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.local_pharmacy_outlined,
                      color: AppColors.shieldBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name']!,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product['desc']!,
                          style: AppTypography.small.copyWith(
                            color: AppColors.gray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    product['price']!,
                    style: AppTypography.small.copyWith(
                      color: AppColors.shieldNavy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
    final regularProducts = [
      {'name': 'Paracetamol 650mg', 'qty': '15 tablets', 'price': '₹45.00'},
      {'name': 'Metformin 500mg', 'qty': '30 tablets', 'price': '₹90.00'},
      {'name': 'Atorvastatin 10mg', 'qty': '10 tablets', 'price': '₹120.00'},
      {'name': 'Multi-Vitamin Daily', 'qty': '30 capsules', 'price': '₹240.00'},
    ];

    final recommendedProducts = [
      {
        'name': 'Omega-3 Fish Oil',
        'price': '₹650.00',
        'desc': 'Heart and joint health',
      },
      {
        'name': 'Vitamin D3 60K',
        'price': '₹150.00',
        'desc': 'Bone strength support',
      },
      {
        'name': 'Probiotics Active',
        'price': '₹380.00',
        'desc': 'Digestive health boost',
      },
    ];

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
                          'Upload a prescription above, or add the medicines and products you want below.',
                          style: AppTypography.tiny.copyWith(
                            color: AppColors.gray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildManualMedicineComposer(),
                  if (_editablePrescriptionItems.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildEditablePrescriptionList(),
                  ],
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // Regularly purchased products
        Text('Regularly Purchased Products', style: AppTypography.h4),
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
        Text('Suggestions Other Patients Buy', style: AppTypography.h4),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
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
      ],
    );
  }

  Widget _buildLabContent() {
    final labTests = [
      {
        'name': 'Complete Blood Count (CBC)',
        'price': '₹350.00',
        'time': 'Reports in 12 hours',
      },
      {
        'name': 'Lipid Profile (Cholesterol)',
        'price': '₹600.00',
        'time': 'Reports in 12 hours',
      },
      {
        'name': 'HbA1c (Diabetic Sugar)',
        'price': '₹450.00',
        'time': 'Reports in 8 hours',
      },
      {
        'name': 'Thyroid Profile (T3, T4, TSH)',
        'price': '₹550.00',
        'time': 'Reports in 24 hours',
      },
      {
        'name': 'Renal/Kidney Function Test',
        'price': '₹500.00',
        'time': 'Reports in 12 hours',
      },
    ];

    return Column(
      key: const ValueKey('LAB_VIEW'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Laboratory Services Directory', style: AppTypography.h4),
        const SizedBox(height: 12),
        ...labTests.map((test) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.shieldBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.science_outlined,
                      color: AppColors.shieldBlue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          test['name']!,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          test['time']!,
                          style: AppTypography.tiny.copyWith(
                            color: AppColors.gray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        test['price']!,
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.shieldNavy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.shieldBlue,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          showPortalSnackBar(
                            context,
                            'Requested ${test['name']}. Our lab coordinator will contact you.',
                          );
                        },
                        child: const Text('Book Test'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildHomeCareContent() {
    final homeServices = [
      {
        'name': 'Nursing Home Visit',
        'desc': 'General nursing care, vital checks, injections',
        'price': '₹500 / visit',
      },
      {
        'name': 'Diabetic Wound Dressing',
        'desc': 'Surgical dressing + blood glucose monitoring',
        'price': '₹600 / visit',
      },
      {
        'name': 'Physiotherapy Session',
        'desc': 'Post-stroke, orthopaedic rehabilitation',
        'price': '₹800 / session',
      },
      {
        'name': 'Elderly Care Companion',
        'desc': 'Assisted checkups and medicine management',
        'price': '₹400 / visit',
      },
    ];

    return Column(
      key: const ValueKey('HOMECARE_VIEW'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Home Care Services Directory', style: AppTypography.h4),
        const SizedBox(height: 12),
        ...homeServices.map((srv) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.shieldGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.home_outlined,
                      color: AppColors.shieldGreen,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          srv['name']!,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          srv['desc']!,
                          style: AppTypography.small.copyWith(
                            color: AppColors.gray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        srv['price']!,
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.shieldNavy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.shieldGreen,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          showPortalSnackBar(
                            context,
                            'Requested ${srv['name']}. Home care team will schedule a visit.',
                          );
                        },
                        child: const Text('Request'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
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

    final dietPlans = [
      {
        'name': 'Diabetic-Friendly Diet',
        'cal': '1600 kcal',
        'focus': 'Low Glycemic Index, fiber rich',
      },
      {
        'name': 'Hypertension Management Plan',
        'cal': '1800 kcal',
        'focus': 'Low sodium, DASH-compliant',
      },
      {
        'name': 'Weight Loss Plan',
        'cal': '1400 kcal',
        'focus': 'Caloric deficit, high protein',
      },
      {
        'name': 'High-Protein Active Diet',
        'cal': '2200 kcal',
        'focus': 'Muscle recovery, complex carbs',
      },
    ];

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

class _CardUtilizationView extends StatefulWidget {
  const _CardUtilizationView();

  @override
  State<_CardUtilizationView> createState() => _CardUtilizationViewState();
}

class _CardUtilizationViewState extends State<_CardUtilizationView> {
  final List<Map<String, String>> _providers = [
    {
      'id': 'pharmacy-1',
      'name': 'SHIELD Hyper Pharmacy Perinthalmanna',
      'type': 'PHARMACY',
      'issuedBusinessId': 'HYP-PERINTHALMANNA',
    },
    {
      'id': 'pharmacy-2',
      'name': 'SHIELD Hyper Pharmacy Manjeri',
      'type': 'PHARMACY',
      'issuedBusinessId': 'HYP-MANJERI',
    },
    {
      'id': 'clinic-1',
      'name': 'Smart Clinic Manjeri',
      'type': 'CLINIC',
      'issuedBusinessId': 'SHG',
    },
    {
      'id': 'dental-1',
      'name': 'Dentistry Melattur',
      'type': 'DENTAL',
      'issuedBusinessId': 'SHG',
    },
    {
      'id': 'home-1',
      'name': 'Home Care Alanallur',
      'type': 'HOME_VISIT',
      'issuedBusinessId': 'SHG',
    },
  ];

  final List<Map<String, dynamic>> _cards = [
    {
      'cardNumber': 'SHLD-CARD-123456',
      'fullName': 'Nihal Rahman',
      'dob': '15/05/1990',
      'bloodGroup': 'O+',
      'agentCode': 'AGT-SAHAKAR-101',
      'membership': 'FOUNDING',
      'cashBalance': 5950.00,
      'pointsBalance': 150.00,
      'issuedBusinessId': 'HYP-PERINTHALMANNA',
      'issuedBusinessName': 'SHIELD Hyper Pharmacy Perinthalmanna',
    },
    {
      'cardNumber': 'SHLD-CARD-789012',
      'fullName': 'Fathima Sherin',
      'dob': '12/10/1998',
      'bloodGroup': 'A+',
      'agentCode': 'AGT-SAHAKAR-102',
      'membership': 'STANDARD',
      'cashBalance': 1200.00,
      'pointsBalance': 0.00,
      'issuedBusinessId': 'HYP-MANJERI',
      'issuedBusinessName': 'SHIELD Hyper Pharmacy Manjeri',
    },
    {
      'cardNumber': 'SHLD-CARD-456789',
      'fullName': 'Shanib K',
      'dob': '25/08/1994',
      'bloodGroup': 'B+',
      'agentCode': 'AGT-SAHAKAR-103',
      'membership': 'STANDARD',
      'cashBalance': 300.00,
      'pointsBalance': 0.00,
      'issuedBusinessId': 'HYP-MANJERI',
      'issuedBusinessName': 'SHIELD Hyper Pharmacy Manjeri',
    },
  ];

  late Map<String, String> _selectedProvider;
  late Map<String, dynamic> _selectedCard;
  bool _isValidated = false;
  bool _validationSuccess = false;
  String _validationMessage = '';
  final List<String> _utilizationLogs = [];
  final TextEditingController _amountController = TextEditingController(
    text: '450.00',
  );

  @override
  void initState() {
    super.initState();
    _selectedProvider = _providers[0];
    _selectedCard = _cards[0];
  }

  void _verifyCard() {
    final cardIssuedBiz = _selectedCard['issuedBusinessId'] as String;
    final providerType = _selectedProvider['type'] as String;
    final providerBiz = _selectedProvider['issuedBusinessId'] as String;

    setState(() {
      _isValidated = true;
      if (providerType == 'PHARMACY') {
        if (cardIssuedBiz == providerBiz) {
          _validationSuccess = true;
          _validationMessage =
              'Compatible: Card matches store location. Verification successful!';
        } else {
          _validationSuccess = false;
          _validationMessage =
              '[Error: Local store mismatch. Cards issued at other stores cannot be utilized here.]';
        }
      } else {
        _validationSuccess = true;
        _validationMessage =
            'Compatible: General service provider access granted across locations.';
      }
    });
  }

  void _logUtilization() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    setState(() {
      _utilizationLogs.insert(
        0,
        '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')} - '
        'Card ${_selectedCard['cardNumber']} (${_selectedCard['fullName']}) utilized at ${_selectedProvider['name']} for ₹${amount.toStringAsFixed(2)}',
      );
    });
    showPortalSnackBar(
      context,
      'Logged card utilization of ₹${amount.toStringAsFixed(2)} successfully!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left block - validation scanner controls
            Expanded(
              flex: 4,
              child: AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Simulate QR Scanner & Card Reader',
                      style: AppTypography.h4,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select Store / Provider Location:',
                      style: AppTypography.small.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.lightGray,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Map<String, String>>(
                          isExpanded: true,
                          value: _selectedProvider,
                          items: _providers.map((p) {
                            return DropdownMenuItem(
                              value: p,
                              child: Text(
                                p['name']!,
                                style: AppTypography.small,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedProvider = val;
                                _isValidated = false;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Simulate Card Scan / Code Entry:',
                      style: AppTypography.small.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.lightGray,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Map<String, dynamic>>(
                          isExpanded: true,
                          value: _selectedCard,
                          items: _cards.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Text(
                                '${c['cardNumber']} - ${c['fullName']} (Issued: ${c['issuedBusinessId']})',
                                style: AppTypography.small,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedCard = val;
                                _isValidated = false;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      text: 'Simulate privilege QR Scan',
                      onPressed: _verifyCard,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),
            // Right block - scan verification details
            Expanded(
              flex: 5,
              child: AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verification Status & Details',
                      style: AppTypography.h4,
                    ),
                    const SizedBox(height: 16),
                    if (!_isValidated)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.lightGray,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.qr_code,
                                size: 48,
                                color: AppColors.gray,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Awaiting scan simulation. Select store and card details to begin verification.',
                                style: AppTypography.small.copyWith(
                                  color: AppColors.gray,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      // Warning or Success Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _validationSuccess
                              ? AppColors.shieldGreen.withValues(alpha: 0.12)
                              : AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _validationSuccess
                                ? AppColors.shieldGreen
                                : AppColors.error,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _validationSuccess
                                  ? Icons.check_circle
                                  : Icons.error,
                              color: _validationSuccess
                                  ? AppColors.shieldGreen
                                  : AppColors.error,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _validationSuccess
                                        ? 'CARD COMPATIBLE'
                                        : 'STORE MISMATCH ERROR',
                                    style: AppTypography.body.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: _validationSuccess
                                          ? AppColors.shieldGreen
                                          : AppColors.error,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _validationMessage,
                                    style: AppTypography.small.copyWith(
                                      color: _validationSuccess
                                          ? AppColors.shieldNavy
                                          : AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_validationSuccess) ...[
                        Text(
                          'SHIELD PRIVILEGE MEMBER DETAILS',
                          style: AppTypography.tiny.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.gray,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Member Name:',
                              style: AppTypography.small.copyWith(
                                color: AppColors.gray,
                              ),
                            ),
                            Text(
                              _selectedCard['fullName']!,
                              style: AppTypography.small.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Membership tier:',
                              style: AppTypography.small.copyWith(
                                color: AppColors.gray,
                              ),
                            ),
                            Text(
                              _selectedCard['membership']!,
                              style: AppTypography.small.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.shieldBlue,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Card Number:',
                              style: AppTypography.small.copyWith(
                                color: AppColors.gray,
                              ),
                            ),
                            Text(
                              _selectedCard['cardNumber']!,
                              style: AppTypography.small,
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Issued At Store:',
                              style: AppTypography.small.copyWith(
                                color: AppColors.gray,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _selectedCard['issuedBusinessName']!,
                                style: AppTypography.small,
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.shieldNavy.withValues(
                                    alpha: 0.05,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'CASH LEDGER',
                                      style: AppTypography.tiny.copyWith(
                                        color: AppColors.gray,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${(_selectedCard['cashBalance'] as double).toStringAsFixed(2)}',
                                      style: AppTypography.body.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.shieldBlue.withValues(
                                    alpha: 0.05,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'POINTS LEDGER',
                                      style: AppTypography.tiny.copyWith(
                                        color: AppColors.gray,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${(_selectedCard['pointsBalance'] as double).toStringAsFixed(0)} PTS',
                                      style: AppTypography.body.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.shieldBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.divider),
                                ),
                                child: TextField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    prefixText: '₹',
                                    labelText: 'Transaction Amount',
                                  ),
                                  style: AppTypography.small,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.shieldGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _logUtilization,
                              child: Text(
                                'Log Card Use',
                                style: AppTypography.body.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent Local Card Utilization logs',
                style: AppTypography.h4,
              ),
              const SizedBox(height: 12),
              if (_utilizationLogs.isEmpty)
                Text(
                  'No logs recorded in this session.',
                  style: AppTypography.small.copyWith(color: AppColors.gray),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _utilizationLogs.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.history_toggle_off,
                            color: AppColors.shieldGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _utilizationLogs[index],
                              style: AppTypography.small.copyWith(
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
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
      debugPrint('Error loading provider data: $e');
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
                    children: [
                      Text('Management Modules', style: AppTypography.h4),
                      const SizedBox(height: 14),
                      const _AdminMiniModuleTile(
                        title: 'Provider Directory',
                        subtitle: 'Identity, branch, category, and ownership',
                        icon: Icons.apartment_outlined,
                      ),
                      const SizedBox(height: 10),
                      const _AdminMiniModuleTile(
                        title: 'Provider Services',
                        subtitle:
                            'Capabilities, pricing, and enabled workflows',
                        icon: Icons.medical_services_outlined,
                      ),
                      const SizedBox(height: 10),
                      const _AdminMiniModuleTile(
                        title: 'Users & Licenses',
                        subtitle: 'Staff accounts, credentials, and renewals',
                        icon: Icons.badge_outlined,
                      ),
                      const SizedBox(height: 10),
                      const _AdminMiniModuleTile(
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

            final side = Column(
              children: [
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Control Modules', style: AppTypography.h4),
                      const SizedBox(height: 14),
                      const _AdminMiniModuleTile(
                        title: 'Organization',
                        subtitle:
                            'Branches, departments, territories, and ownership',
                        icon: Icons.apartment_outlined,
                      ),
                      const SizedBox(height: 10),
                      const _AdminMiniModuleTile(
                        title: 'Catalog',
                        subtitle:
                            'Service categories, services, and provider types',
                        icon: Icons.widgets_outlined,
                      ),
                      const SizedBox(height: 10),
                      const _AdminMiniModuleTile(
                        title: 'Commercial Rules',
                        subtitle:
                            'Membership, benefits, referral, and wallet controls',
                        icon: Icons.request_quote_outlined,
                      ),
                      const SizedBox(height: 10),
                      const _AdminMiniModuleTile(
                        title: 'Operational Calendar',
                        subtitle: 'Holidays, shifts, and working-hour defaults',
                        icon: Icons.event_available_outlined,
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
                      const _AdminHealthRow(
                        title: 'Provider type taxonomy',
                        status: 'Open',
                        note:
                            'A single capability map is still needed before provider portal expansion.',
                      ),
                      const SizedBox(height: 12),
                      const _AdminHealthRow(
                        title: 'Working-hour standards',
                        status: 'Pending',
                        note:
                            'Appointment and provider timing defaults should be unified in one source.',
                      ),
                      const SizedBox(height: 12),
                      const _AdminHealthRow(
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

class _BranchIdsDirectoryView extends StatefulWidget {
  const _BranchIdsDirectoryView();

  @override
  State<_BranchIdsDirectoryView> createState() =>
      _BranchIdsDirectoryViewState();
}

class _BranchIdsDirectoryViewState extends State<_BranchIdsDirectoryView> {
  String _selectedStore = 'ALL';
  String _searchQuery = '';

  final List<Map<String, dynamic>> _members = [
    {
      'customerCode': 'CUST-123456',
      'fullName': 'Nihal Rahman',
      'mobile': '9876543210',
      'dob': '15/05/1990',
      'age': '36 years',
      'bloodGroup': 'O+',
      'agentCode': 'AGT-SAHAKAR-101',
      'store': 'Perinthalmanna Store',
      'status': 'ACTIVE',
      'membership': 'FOUNDING',
      'card': 'SHLD-CARD-123456',
    },
    {
      'customerCode': 'CUST-789012',
      'fullName': 'Fathima Sherin',
      'mobile': '9876543211',
      'dob': '12/10/1998',
      'age': '28 years',
      'bloodGroup': 'A+',
      'agentCode': 'AGT-SAHAKAR-102',
      'store': 'Manjeri Store',
      'status': 'ACTIVE',
      'membership': 'STANDARD',
      'card': 'SHLD-CARD-789012',
    },
    {
      'customerCode': 'CUST-456789',
      'fullName': 'Shanib K',
      'mobile': '9876543212',
      'dob': '25/08/1994',
      'age': '32 years',
      'bloodGroup': 'B+',
      'agentCode': 'AGT-SAHAKAR-103',
      'store': 'Tirur Store',
      'status': 'PENDING',
      'membership': 'STANDARD',
      'card': 'SHLD-CARD-456789',
    },
    {
      'customerCode': 'CUST-987654',
      'fullName': 'Suneer K',
      'mobile': '9876543213',
      'dob': '05/04/1986',
      'age': '40 years',
      'bloodGroup': 'AB+',
      'agentCode': 'AGT-SAHAKAR-101',
      'store': 'Perinthalmanna Store',
      'status': 'ACTIVE',
      'membership': 'FOUNDING',
      'card': 'SHLD-CARD-987654',
    },
  ];

  Widget _buildStoreChip(String storeVal, String label) {
    final isSelected = _selectedStore == storeVal;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedStore = storeVal;
        });
      },
      selectedColor: AppColors.shieldBlue.withValues(alpha: 0.12),
      labelStyle: AppTypography.small.copyWith(
        color: isSelected ? AppColors.shieldBlue : AppColors.darkGray,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _members.where((m) {
      final matchesStore =
          _selectedStore == 'ALL' || m['store'] == _selectedStore;
      final q = _searchQuery.toLowerCase();
      final matchesSearch =
          q.isEmpty ||
          m['fullName'].toLowerCase().contains(q) ||
          m['customerCode'].toLowerCase().contains(q) ||
          m['agentCode'].toLowerCase().contains(q) ||
          m['mobile'].contains(q);
      return matchesStore && matchesSearch;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SHIELD Branch-wise IDs Directory', style: AppTypography.h4),
              const SizedBox(height: 16),
              // Search & Filter
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.lightGray,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: TextField(
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          icon: Icon(Icons.search, color: AppColors.gray),
                          hintText: 'Search by Name, ID, Mobile, or Agent...',
                        ),
                        style: AppTypography.small,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStoreChip('ALL', 'All Branches'),
                    const SizedBox(width: 8),
                    _buildStoreChip('Perinthalmanna Store', 'Perinthalmanna'),
                    const SizedBox(width: 8),
                    _buildStoreChip('Manjeri Store', 'Manjeri'),
                    const SizedBox(width: 8),
                    _buildStoreChip('Tirur Store', 'Tirur'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AppCard(
          padding: EdgeInsets.zero,
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(2.5),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(1.5),
              4: FlexColumnWidth(1.5),
              5: FlexColumnWidth(1.5),
            },
            children: [
              // Header
              TableRow(
                decoration: const BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'ID Code',
                      style: AppTypography.small.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.shieldNavy,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Full Name / Mobile',
                      style: AppTypography.small.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.shieldNavy,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Registration Store',
                      style: AppTypography.small.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.shieldNavy,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Agent Code',
                      style: AppTypography.small.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.shieldNavy,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Age',
                      style: AppTypography.small.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.shieldNavy,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Status',
                      style: AppTypography.small.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.shieldNavy,
                      ),
                    ),
                  ),
                ],
              ),
              ...filtered.map((m) {
                final isPending = m['status'] == 'PENDING';
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: InkWell(
                        onTap: () {
                          showPortalDetailsSheet(
                            context,
                            title: 'Member Profile: ${m['fullName']}',
                            subtitle:
                                'ID: ${m['customerCode']} • Card Number: ${m['card']}',
                            meta: m['store'],
                            status: m['status'],
                            highlights: [
                              'DOB: ${m['dob']} (${m['age']})',
                              'Blood Group: ${m['bloodGroup']}',
                              'Registered under Sahakar Group Agent Code: ${m['agentCode']}',
                              'Authorized privilege card status: ${m['status']}.',
                            ],
                          );
                        },
                        child: Text(
                          m['customerCode']!,
                          style: AppTypography.small.copyWith(
                            color: AppColors.shieldBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m['fullName']!,
                            style: AppTypography.small.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            m['mobile']!,
                            style: AppTypography.tiny.copyWith(
                              color: AppColors.gray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(m['store']!, style: AppTypography.small),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        m['agentCode']!,
                        style: AppTypography.small.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(m['age']!, style: AppTypography.small),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isPending
                              ? AppColors.warning.withValues(alpha: 0.1)
                              : AppColors.shieldGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          m['status']!,
                          style: AppTypography.tiny.copyWith(
                            color: isPending
                                ? AppColors.warning
                                : AppColors.shieldGreen,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _ServiceUtilizationView extends StatefulWidget {
  const _ServiceUtilizationView();

  @override
  State<_ServiceUtilizationView> createState() =>
      _ServiceUtilizationViewState();
}

class _ServiceUtilizationViewState extends State<_ServiceUtilizationView> {
  String _selectedCategory = 'ALL';

  final List<Map<String, dynamic>> _txns = [
    {
      'customer': 'Nihal Rahman',
      'card': 'SHLD-CARD-123456',
      'provider': 'SHIELD Hyper Pharmacy Perinthalmanna',
      'category': 'Pharmacy',
      'amount': 1200.00,
      'date': '03/06/2026',
      'status': 'Settled',
    },
    {
      'customer': 'Nihal Rahman',
      'card': 'SHLD-CARD-123456',
      'provider': 'Smart Clinic Manjeri',
      'category': 'Clinic',
      'amount': 500.00,
      'date': '05/06/2026',
      'status': 'Settled',
    },
    {
      'customer': 'Nihal Rahman',
      'card': 'SHLD-CARD-123456',
      'provider': 'Laboratory Tirur',
      'category': 'Lab',
      'amount': 350.00,
      'date': '12/06/2026',
      'status': 'Settled',
    },
    {
      'customer': 'Fathima Sherin',
      'card': 'SHLD-CARD-789012',
      'provider': 'SHIELD Hyper Pharmacy Manjeri',
      'category': 'Pharmacy',
      'amount': 850.00,
      'date': '15/06/2026',
      'status': 'Settled',
    },
    {
      'customer': 'Fathima Sherin',
      'card': 'SHLD-CARD-789012',
      'provider': 'Dentistry Melattur',
      'category': 'Dental',
      'amount': 1500.00,
      'date': '18/06/2026',
      'status': 'Settled',
    },
    {
      'customer': 'Shanib K',
      'card': 'SHLD-CARD-456789',
      'provider': 'Home Care Alanallur',
      'category': 'Homecare',
      'amount': 600.00,
      'date': '20/06/2026',
      'status': 'Settled',
    },
  ];

  Widget _buildCategoryChip(String cat, String label) {
    final isSelected = _selectedCategory == cat;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedCategory = cat;
        });
      },
      selectedColor: AppColors.shieldNavy.withValues(alpha: 0.12),
      labelStyle: AppTypography.small.copyWith(
        color: isSelected ? AppColors.shieldNavy : AppColors.darkGray,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _txns.where((t) {
      return _selectedCategory == 'ALL' || t['category'] == _selectedCategory;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('IDs Service Utilization logs', style: AppTypography.h4),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip('ALL', 'All Services'),
                    const SizedBox(width: 8),
                    _buildCategoryChip('Pharmacy', 'Pharmacy'),
                    const SizedBox(width: 8),
                    _buildCategoryChip('Clinic', 'Clinic'),
                    const SizedBox(width: 8),
                    _buildCategoryChip('Lab', 'Laboratory'),
                    const SizedBox(width: 8),
                    _buildCategoryChip('Dental', 'Dental'),
                    const SizedBox(width: 8),
                    _buildCategoryChip('Homecare', 'Home Care'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AppCard(
          padding: EdgeInsets.zero,
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(1.2),
              1: FlexColumnWidth(2.5),
              2: FlexColumnWidth(3.5),
              3: FlexColumnWidth(1.5),
              4: FlexColumnWidth(1.5),
              5: FlexColumnWidth(1.3),
            },
            children: [
              // Header
              TableRow(
                decoration: const BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Date',
                      style: AppTypography.small.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.shieldNavy,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Member / Card',
                      style: AppTypography.small.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.shieldNavy,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Utilized At Provider',
                      style: AppTypography.small.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.shieldNavy,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Category',
                      style: AppTypography.small.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.shieldNavy,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Debited',
                      style: AppTypography.small.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.shieldNavy,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Status',
                      style: AppTypography.small.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.shieldNavy,
                      ),
                    ),
                  ),
                ],
              ),
              ...filtered.map((t) {
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(t['date']!, style: AppTypography.small),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t['customer']!,
                            style: AppTypography.small.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            t['card']!,
                            style: AppTypography.tiny.copyWith(
                              color: AppColors.gray,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(t['provider']!, style: AppTypography.small),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(t['category']!, style: AppTypography.small),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        '₹${(t['amount'] as double).toStringAsFixed(2)}',
                        style: AppTypography.small.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.shieldGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          t['status']!,
                          style: AppTypography.tiny.copyWith(
                            color: AppColors.shieldGreen,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminReportsView extends StatelessWidget {
  const _AdminReportsView();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grid cards
        Row(
          children: [
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Wallet Cash Balance',
                      style: AppTypography.small.copyWith(
                        color: AppColors.gray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹8,450.00',
                      style: AppTypography.h3.copyWith(
                        color: AppColors.shieldNavy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Referral Points Awarded',
                      style: AppTypography.small.copyWith(
                        color: AppColors.gray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '300 PTS',
                      style: AppTypography.h3.copyWith(
                        color: AppColors.shieldBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Membership Fees collected',
                      style: AppTypography.small.copyWith(
                        color: AppColors.gray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹1,500.00',
                      style: AppTypography.h3.copyWith(
                        color: AppColors.shieldGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Membership Plan Distribution',
                      style: AppTypography.h4,
                    ),
                    const SizedBox(height: 20),
                    // Founding
                    Row(
                      children: [
                        Expanded(
                          flex: 65,
                          child: Container(
                            height: 24,
                            decoration: const BoxDecoration(
                              color: AppColors.shieldNavy,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(6),
                                bottomLeft: Radius.circular(6),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 35,
                          child: Container(
                            height: 24,
                            decoration: const BoxDecoration(
                              color: AppColors.shieldBlue,
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(6),
                                bottomRight: Radius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              color: AppColors.shieldNavy,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Founding Members (65%)',
                              style: AppTypography.small,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              color: AppColors.shieldBlue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Standard Members (35%)',
                              style: AppTypography.small,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Service Category Utilization share',
                      style: AppTypography.h4,
                    ),
                    const SizedBox(height: 16),
                    _buildUtilBar('Pharmacy', 55, AppColors.shieldGreen),
                    const SizedBox(height: 12),
                    _buildUtilBar(
                      'Clinics & Consults',
                      25,
                      AppColors.shieldBlue,
                    ),
                    const SizedBox(height: 12),
                    _buildUtilBar('Laboratory', 10, AppColors.shieldNavy),
                    const SizedBox(height: 12),
                    _buildUtilBar('Home Care & Others', 10, AppColors.gray),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUtilBar(String label, int percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.small),
            Text(
              '$percentage%',
              style: AppTypography.small.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              flex: percentage,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            Expanded(
              flex: 100 - percentage,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
