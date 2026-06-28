import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/models/appointment.dart';
import '../../../../shared/models/customer.dart';
import '../../../../shared/models/document.dart';
import '../../../../shared/models/membership.dart';
import '../../../../shared/models/notification.dart';
import '../../../../shared/models/shield_role.dart';
import '../../../../shared/models/wallet.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_page_frame.dart';
import '../../../../shared/widgets/app_responsive.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/widgets/shield_date_input_field.dart';
import '../../../../shared/services/api_service.dart';
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

  @override
  Widget build(BuildContext context) {
    final portal = portalDataForRole(widget.role);
    final activeKey = widget.sectionKey ?? 'dashboard';
    final isCustomer = widget.role == SHIELDRole.customer;

    if (_isLoading) {
      return AppPageSkeleton(
        showSidebar: !isCustomer && AppResponsive.isDesktop(context),
      );
    }

    if (_error != null || _sectionData == null) {
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
                        child: Scaffold(
                          backgroundColor: AppColors.lightGray,
                          drawer: _RoleDrawer(
                            portal: portal,
                            activeSectionKey: activeKey,
                          ),
                          body: _RoleContent(portal: portal, section: section),
                        ),
                      ),
                    ),
                  );
                },
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 1300,
                  child: Row(
                    children: [
                      _RoleSidebar(portal: portal, activeSectionKey: activeKey),
                      Expanded(
                        child: _RoleContent(portal: portal, section: section),
                      ),
                    ],
                  ),
                ),
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

class _RoleContent extends StatelessWidget {
  final PortalRoleData portal;
  final PortalSectionData section;

  const _RoleContent({required this.portal, required this.section});

  @override
  Widget build(BuildContext context) {
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
    final isAdminAudit =
        portal.role == SHIELDRole.superAdmin && section.key == 'audit';
    final isReportsSection =
        (portal.role == SHIELDRole.superAdmin ||
            portal.role == SHIELDRole.manager) &&
        section.key == 'reports';

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
                _PortalHeader(portal: portal, section: section),
                const SizedBox(height: 20),
                if (isCustomerProfile)
                  const _CustomerProfilePortalView()
                else if (isCustomerDashboard)
                  const _CustomerDashboardPortalView()
                else if (isCustomerMembership)
                  const _CustomerMembershipPortalView()
                else if (isCustomerServices)
                  const _CustomerServicesView()
                else if (isCustomerAppointments)
                  _CustomerAppointmentsView(section: section)
                else if (isCustomerNotifications)
                  _CustomerNotificationsView(section: section)
                else if (isCustomerWallet)
                  const _CustomerWalletView()
                else if (isCustomerSettings)
                  const _CustomerSettingsView()
                else if (isCardUtilization)
                  const _CardUtilizationView()
                else if (isAdminBusinesses)
                  const _BranchIdsDirectoryView()
                else if (isAdminAudit)
                  const _ServiceUtilizationView()
                else if (isReportsSection)
                  const _AdminReportsView()
                else ...[
                  _HeroPanel(portal: portal, section: section),
                  const SizedBox(height: 20),
                  _MetricGrid(
                    metrics: section.metrics,
                    accentColor: portal.accentColor,
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stack = constraints.maxWidth < 900;
                      final priorityPanel = _ListPanel(
                        title: 'Priority Queue',
                        subtitle:
                            'What needs attention first in this role view.',
                        items: section.queueItems,
                        accentColor: portal.accentColor,
                      );
                      final recentPanel = _ListPanel(
                        title: 'Recent Activity',
                        subtitle:
                            'Latest actions and timeline events in the portal flow.',
                        items: section.recentItems,
                        accentColor: AppColors.shieldBlue,
                      );

                      if (stack) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            priorityPanel,
                            const SizedBox(height: 20),
                            recentPanel,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: priorityPanel),
                          const SizedBox(width: 20),
                          Expanded(child: recentPanel),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleSidebar extends StatelessWidget {
  final PortalRoleData portal;
  final String activeSectionKey;

  const _RoleSidebar({required this.portal, required this.activeSectionKey});

  @override
  Widget build(BuildContext context) {
    if (portal.role == SHIELDRole.customer) {
      return _CustomerPortalNav(
        portal: portal,
        activeSectionKey: activeSectionKey,
        inDrawer: false,
      );
    }

    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(right: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SHIELD',
                  style: AppTypography.h3.copyWith(color: portal.accentColor),
                ),
                const SizedBox(height: 6),
                Text(
                  portal.role.label,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  portal.regionLabel,
                  style: AppTypography.tiny.copyWith(color: AppColors.gray),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: portal.sections.map((section) {
                final isActive = section.key == activeSectionKey;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => context.go(
                      '/portal/${portal.role.routeKey}/${section.key}',
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? portal.accentColor.withValues(alpha: 0.12)
                            : AppColors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.title,
                            style: AppTypography.body.copyWith(
                              color: isActive
                                  ? portal.accentColor
                                  : AppColors.darkGray,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            section.summary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.tiny.copyWith(
                              color: AppColors.gray,
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _RoleDrawer extends StatelessWidget {
  final PortalRoleData portal;
  final String activeSectionKey;

  const _RoleDrawer({required this.portal, required this.activeSectionKey});

  @override
  Widget build(BuildContext context) {
    if (portal.role == SHIELDRole.customer) {
      return Drawer(
        child: SafeArea(
          child: _CustomerPortalNav(
            portal: portal,
            activeSectionKey: activeSectionKey,
            inDrawer: true,
          ),
        ),
      );
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SHIELD',
                    style: AppTypography.h3.copyWith(color: portal.accentColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    portal.role.label,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    portal.regionLabel,
                    style: AppTypography.tiny.copyWith(color: AppColors.gray),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                children: portal.sections.map((section) {
                  final isActive = section.key == activeSectionKey;
                  return ListTile(
                    selected: isActive,
                    selectedTileColor: portal.accentColor.withValues(
                      alpha: 0.12,
                    ),
                    title: Text(section.title),
                    subtitle: Text(
                      section.summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      context.go(
                        '/portal/${portal.role.routeKey}/${section.key}',
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortalHeader extends StatelessWidget {
  final PortalRoleData portal;
  final PortalSectionData section;

  const _PortalHeader({required this.portal, required this.section});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
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
    final content = FutureBuilder<Map<String, dynamic>>(
      future: ApiService.getWalletProfile('1'),
      builder: (context, snapshot) {
        final balance = snapshot.hasData
            ? (double.tryParse(snapshot.data!['balance']?.toString() ?? '0') ??
                  0.0)
            : 0.0;

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
                      portal.operatorName,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Founding Member',
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
                              'Wallet balance',
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            portal.accentColor.withValues(alpha: 0.95),
            AppColors.shieldNavy,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(portal.icon, color: AppColors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      portal.operatorName,
                      style: AppTypography.body.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      portal.regionLabel,
                      style: AppTypography.tiny.copyWith(
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            section.summary,
            style: AppTypography.h4.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: 14),
          _HeroActionGrid(
            actions: section.actions
                .map(
                  (action) => _HeroActionGridItem(
                    label: action,
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

class _MetricGrid extends StatelessWidget {
  final List<PortalMetric> metrics;
  final Color accentColor;

  const _MetricGrid({required this.metrics, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth >= 1000
            ? 3
            : constraints.maxWidth >= 640
            ? 2
            : 1;
        final aspectRatio = constraints.maxWidth >= 1000
            ? 2.75
            : constraints.maxWidth >= 640
            ? 2.35
            : 3.1;

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
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          metric.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.small.copyWith(
                            color: AppColors.gray,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          metric.note,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.tiny.copyWith(
                            color: AppColors.darkGray,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Align(
                    alignment: Alignment.topRight,
                    child: Text(
                      metric.value,
                      textAlign: TextAlign.right,
                      style: AppTypography.h4.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w700,
                      ),
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

class _ListPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<PortalListItem> items;
  final Color accentColor;

  const _ListPanel({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.h4),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTypography.small.copyWith(color: AppColors.gray),
          ),
          const SizedBox(height: 16),
          ...items.asMap().entries.map((entry) {
            final item = entry.value;
            final isLast = entry.key == items.length - 1;

            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.subtitle,
                            style: AppTypography.small.copyWith(
                              color: AppColors.darkGray,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _TagChip(label: item.meta, color: AppColors.gray),
                              _TagChip(label: item.status, color: accentColor),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
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
      final customer = await ApiService.getCustomerProfile('1');
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
    _selectedGender = customer.gender;
    _selectedBloodGroup = customer.bloodGroup;
    _selectedDob = customer.dob ?? DateTime(DateTime.now().year - 25, 1, 1);
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
                      label: 'View member ID',
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

class _CustomerDashboardPortalView extends StatefulWidget {
  const _CustomerDashboardPortalView();

  @override
  State<_CustomerDashboardPortalView> createState() =>
      _CustomerDashboardPortalViewState();
}

class _CustomerDashboardPortalViewState
    extends State<_CustomerDashboardPortalView> {
  late Future<Customer> _customerFuture;
  late Future<Map<String, dynamic>> _walletFuture;
  late Future<List<WalletTransaction>> _transactionsFuture;
  late Future<Membership> _membershipFuture;
  late Future<List<Appointment>> _appointmentsFuture;
  late Future<List<Document>> _documentsFuture;

  @override
  void initState() {
    super.initState();
    _customerFuture = ApiService.getCustomerProfile('1');
    _walletFuture = ApiService.getWalletProfile('1');
    _transactionsFuture = _walletFuture.then(
      (wallet) =>
          ApiService.getWalletTransactions(wallet['walletId'].toString()),
    );
    _membershipFuture = ApiService.getCustomerMembership('1');
    _appointmentsFuture = ApiService.getAppointments(SHIELDRole.customer);
    _documentsFuture = ApiService.getDocuments(SHIELDRole.customer);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        _customerFuture,
        _walletFuture,
        _transactionsFuture,
        _membershipFuture,
        _appointmentsFuture,
        _documentsFuture,
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppPortalSectionSkeleton(
            showHero: true,
            statCards: 4,
            listItems: 4,
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dashboard unavailable', style: AppTypography.h4),
                const SizedBox(height: 8),
                Text(
                  'The customer dashboard preview could not be loaded.',
                  style: AppTypography.small.copyWith(color: AppColors.gray),
                ),
              ],
            ),
          );
        }

        final customer = snapshot.data![0] as Customer;
        final wallet = snapshot.data![1] as Map<String, dynamic>;
        final transactions = snapshot.data![2] as List<WalletTransaction>;
        final membership = snapshot.data![3] as Membership;
        final appointments = snapshot.data![4] as List<Appointment>;
        final documents = snapshot.data![5] as List<Document>;
        final walletBalance =
            double.tryParse(wallet['balance']?.toString() ?? '0') ?? 0.0;
        final pointsBalance =
            double.tryParse(wallet['pointsBalance']?.toString() ?? '0') ?? 0.0;
        final upcomingVisits = appointments.length;
        final documentCount = documents.length;

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
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              membership.tierLabel,
                              style: AppTypography.small.copyWith(
                                color: AppColors.white.withValues(alpha: 0.8),
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
                          color: AppColors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          customer.status.toUpperCase(),
                          style: AppTypography.tiny.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth = (constraints.maxWidth - 10) / 2;
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _HeroStatBlock(
                            width: itemWidth,
                            label: 'Wallet',
                            value: '₹${walletBalance.toStringAsFixed(0)}',
                            secondary:
                                '${pointsBalance.toStringAsFixed(0)} reward pts',
                          ),
                          _HeroStatBlock(
                            width: itemWidth,
                            label: 'Activity',
                            value: '$upcomingVisits visits',
                            secondary: '$documentCount documents',
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _HeroActionGrid(
                    actions: [
                      _HeroActionGridItem(
                        label: 'View card',
                        onTap: () => context.go('/portal/customer/membership'),
                      ),
                      _HeroActionGridItem(
                        label: 'Book visit',
                        onTap: () =>
                            context.go('/portal/customer/appointments'),
                      ),
                      _HeroActionGridItem(
                        label: 'Open wallet',
                        onTap: () => context.go('/portal/customer/wallet'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) => GridView.count(
                crossAxisCount: constraints.maxWidth >= 420 ? 2 : 1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: constraints.maxWidth >= 420 ? 2.2 : 2.8,
                children: [
                  _KpiTile(
                    title: 'Wallet',
                    value: '₹${walletBalance.toStringAsFixed(0)}',
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppColors.shieldBlue,
                  ),
                  _KpiTile(
                    title: 'Visits',
                    value: '$upcomingVisits',
                    icon: Icons.calendar_month_outlined,
                    color: AppColors.shieldGreen,
                  ),
                  _KpiTile(
                    title: 'Docs',
                    value: '$documentCount',
                    icon: Icons.description_outlined,
                    color: AppColors.shieldNavy,
                  ),
                  _KpiTile(
                    title: 'Points',
                    value: '${pointsBalance.toStringAsFixed(0)} pts',
                    icon: Icons.workspace_premium_outlined,
                    color: AppColors.warning,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Upcoming Appointments', style: AppTypography.h4),
            const SizedBox(height: 12),
            ...appointments
                .take(3)
                .map(
                  (appointment) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.shieldBlue,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appointment.doctorName ?? 'Appointment',
                                  style: AppTypography.body.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${DateFormat('dd MMM yyyy').format(appointment.appointmentDate)} • ${appointment.department ?? 'SHIELD care'}',
                                  style: AppTypography.small.copyWith(
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
                ),
            const SizedBox(height: 14),
            Text('Recent Activity', style: AppTypography.h4),
            const SizedBox(height: 12),
            ...transactions
                .take(4)
                .map(
                  (txn) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color:
                                  (txn.transactionType == 'CREDIT'
                                          ? AppColors.shieldGreen
                                          : AppColors.error)
                                      .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              txn.transactionType == 'CREDIT'
                                  ? Icons.south_west_rounded
                                  : Icons.north_east_rounded,
                              color: txn.transactionType == 'CREDIT'
                                  ? AppColors.shieldGreen
                                  : AppColors.error,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  txn.remarks ?? 'Activity',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.body.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat(
                                    'dd MMM yyyy • hh:mm a',
                                  ).format(txn.createdAt),
                                  style: AppTypography.tiny.copyWith(
                                    color: AppColors.gray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${txn.transactionType == 'CREDIT' ? '+' : '-'}₹${txn.amount.toStringAsFixed(0)}',
                            style: AppTypography.body.copyWith(
                              color: txn.transactionType == 'CREDIT'
                                  ? AppColors.shieldGreen
                                  : AppColors.error,
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
      },
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
      ApiService.getCustomerProfile('1'),
      ApiService.getCustomerMembership('1'),
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
    this.width,
  });

  final String label;
  final String value;
  final String secondary;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
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
    return DropdownButtonFormField<String>(
      initialValue: value,
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

class _CustomerWalletView extends StatefulWidget {
  const _CustomerWalletView();

  @override
  State<_CustomerWalletView> createState() => _CustomerWalletViewState();
}

class _CustomerWalletViewState extends State<_CustomerWalletView> {
  late Future<Map<String, dynamic>> _walletProfileFuture;
  late Future<List<WalletTransaction>> _transactionsFuture;
  String _selectedLedger = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  void _loadWalletData() {
    _walletProfileFuture = ApiService.getWalletProfile('1');
    _transactionsFuture = _walletProfileFuture.then((profile) {
      return ApiService.getWalletTransactions(profile['walletId'].toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([_walletProfileFuture, _transactionsFuture]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppPortalSectionSkeleton(
            showHero: true,
            statCards: 4,
            listItems: 5,
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Wallet unavailable', style: AppTypography.h4),
                const SizedBox(height: 8),
                Text(
                  'The local wallet preview could not be loaded.',
                  style: AppTypography.small.copyWith(color: AppColors.gray),
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: 'Retry',
                  onPressed: () {
                    setState(_loadWalletData);
                  },
                ),
              ],
            ),
          );
        }

        final walletProfile = snapshot.data![0] as Map<String, dynamic>;
        final transactions = snapshot.data![1] as List<WalletTransaction>;
        double cashBalance = 0;
        double pointsBalance = 0;
        double monthlySpend = 0;
        double rewardCredits = 0;
        final creditAvailable =
            double.tryParse(
              (walletProfile['creditAvailable'] ?? 0).toString(),
            ) ??
            0;

        for (final txn in transactions) {
          final delta = txn.transactionType == 'CREDIT'
              ? txn.amount
              : -txn.amount;
          if (txn.subLedgerType == 'POINTS') {
            pointsBalance += delta;
            if (txn.transactionType == 'CREDIT') {
              rewardCredits += txn.amount;
            }
          } else {
            cashBalance += delta;
            if (txn.transactionType == 'DEBIT') {
              monthlySpend += txn.amount;
            }
          }
        }

        final visibleTransactions = transactions.where((txn) {
          return _selectedLedger == 'ALL' ||
              txn.subLedgerType == _selectedLedger;
        }).toList();
        double ledgerBalanceAfter(WalletTransaction target) {
          final sameLedger =
              transactions
                  .where((txn) => txn.subLedgerType == target.subLedgerType)
                  .toList()
                ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
          var balance = 0.0;
          for (final txn in sameLedger) {
            balance += txn.transactionType == 'CREDIT'
                ? txn.amount
                : -txn.amount;
            if (txn.id == target.id) {
              return balance;
            }
          }
          return balance;
        }

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
                          'Wallet overview',
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
                          (walletProfile['status'] ?? 'ACTIVE').toString(),
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
                    'Cash, points, credit, and ledger movement in one compact customer view.',
                    style: AppTypography.small.copyWith(
                      color: AppColors.white.withValues(alpha: 0.84),
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth = (constraints.maxWidth - 10) / 2;
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _HeroStatBlock(
                            width: itemWidth,
                            label: 'Cash',
                            value: '₹${cashBalance.toStringAsFixed(0)}',
                            secondary:
                                '${pointsBalance.toStringAsFixed(0)} reward pts',
                          ),
                          _HeroStatBlock(
                            width: itemWidth,
                            label: 'Credit',
                            value: '₹${creditAvailable.toStringAsFixed(0)}',
                            secondary:
                                '₹${monthlySpend.toStringAsFixed(0)} spent this cycle',
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _CompactValueCard(
                          title: 'Cash balance',
                          value: '₹${cashBalance.toStringAsFixed(0)}',
                          caption: 'Redeemable portal cash',
                          accentColor: AppColors.white,
                          icon: Icons.currency_rupee,
                          dark: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CompactValueCard(
                          title: 'Points balance',
                          value: '${pointsBalance.toStringAsFixed(0)} pts',
                          caption: 'Referral + loyalty rewards',
                          accentColor: AppColors.white,
                          icon: Icons.stars_rounded,
                          dark: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _CompactValueCard(
                          title: 'Monthly spend',
                          value: '₹${monthlySpend.toStringAsFixed(0)}',
                          caption: 'Pharmacy + services',
                          accentColor: AppColors.white,
                          icon: Icons.arrow_upward_rounded,
                          dark: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CompactValueCard(
                          title: 'Rewards earned',
                          value: '${rewardCredits.toStringAsFixed(0)} pts',
                          caption: 'Approved referrals + promos',
                          accentColor: AppColors.white,
                          icon: Icons.card_giftcard_outlined,
                          dark: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _HeroActionGrid(
                    actions: [
                      _HeroActionGridItem(
                        label: 'Open profile',
                        onTap: () => context.go('/portal/customer/profile'),
                      ),
                      _HeroActionGridItem(
                        label: 'Open statement',
                        onTap: () => showPortalDetailsSheet(
                          context,
                          title: 'Wallet statement preview',
                          subtitle:
                              'Detailed statements stay grouped inside the customer wallet flow until export APIs are wired.',
                          meta: 'Customer wallet',
                          status: 'Live ledger',
                          highlights: const [
                            'Cash and points entries remain separated by sub-ledger type.',
                            'Statement export can later connect here without changing the customer route structure.',
                          ],
                        ),
                      ),
                      _HeroActionGridItem(
                        label: 'Points rules',
                        onTap: () => showPortalDetailsSheet(
                          context,
                          title: 'Points wallet rules',
                          subtitle:
                              'Referral, loyalty, and promotional points stay separate from cash.',
                          meta: 'Customer wallet',
                          status: 'Policy',
                          highlights: const [
                            'Referral points credit only after the referred member is approved.',
                            'Wallet cash remains branch-restricted only for Hyper Pharmacy usage where applicable.',
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Recent activity', style: AppTypography.h4),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _selectedLedger == 'ALL',
                    onTap: () => setState(() => _selectedLedger = 'ALL'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Cash',
                    selected: _selectedLedger == 'CASH',
                    onTap: () => setState(() => _selectedLedger = 'CASH'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Points',
                    selected: _selectedLedger == 'POINTS',
                    onTap: () => setState(() => _selectedLedger = 'POINTS'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...visibleTransactions.take(6).map((txn) {
              final isCredit = txn.transactionType == 'CREDIT';
              final accent = isCredit ? AppColors.shieldGreen : AppColors.error;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  padding: const EdgeInsets.all(14),
                  onTap: () => showPortalDetailsSheet(
                    context,
                    title: txn.remarks ?? 'Wallet transaction',
                    subtitle:
                        '${txn.subLedgerType} ${txn.transactionType.toLowerCase()} entry for ${txn.amount.toStringAsFixed(0)}.',
                    meta: DateFormat(
                      'dd MMM yyyy, hh:mm a',
                    ).format(txn.createdAt),
                    status: txn.transactionType,
                    highlights: [
                      'Post-transaction balance in ${txn.subLedgerType} ledger is ${ledgerBalanceAfter(txn).toStringAsFixed(0)}.',
                      'This transaction is loaded from the live customer wallet ledger.',
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isCredit
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          color: accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              txn.remarks ?? 'Wallet transaction',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.body.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              DateFormat(
                                'dd MMM • hh:mm a',
                              ).format(txn.createdAt),
                              style: AppTypography.tiny.copyWith(
                                color: AppColors.gray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isCredit ? '+' : '-'}₹${txn.amount.toStringAsFixed(0)}',
                            style: AppTypography.body.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          _LedgerBadge(ledgerType: txn.subLedgerType),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
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
              title: 'Back to dashboard',
              subtitle: 'Return to the customer home view',
              destructive: true,
              onTap: () => context.go('/portal/customer/dashboard'),
            ),
          ],
        ),
      ],
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

class _CompactValueCard extends StatelessWidget {
  final String title;
  final String value;
  final String caption;
  final Color accentColor;
  final IconData icon;
  final bool dark;

  const _CompactValueCard({
    required this.title,
    required this.value,
    required this.caption,
    required this.accentColor,
    required this.icon,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Container(
        decoration: dark
            ? BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        padding: dark ? const EdgeInsets.all(2) : EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.small.copyWith(
                      color: dark
                          ? AppColors.white.withValues(alpha: 0.82)
                          : AppColors.gray,
                    ),
                  ),
                ),
                Icon(icon, color: accentColor, size: 18),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: AppTypography.h4.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              caption,
              style: AppTypography.tiny.copyWith(
                color: dark
                    ? AppColors.white.withValues(alpha: 0.78)
                    : AppColors.gray,
              ),
            ),
          ],
        ),
      ),
    );
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

class _LedgerBadge extends StatelessWidget {
  final String ledgerType;

  const _LedgerBadge({required this.ledgerType});

  @override
  Widget build(BuildContext context) {
    final isCash = ledgerType == 'CASH';
    final color = isCash ? AppColors.shieldNavy : AppColors.shieldBlue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        ledgerType,
        style: AppTypography.tiny.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab Selector Row
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

        // Tab Contents
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _buildActiveTabContent(),
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
