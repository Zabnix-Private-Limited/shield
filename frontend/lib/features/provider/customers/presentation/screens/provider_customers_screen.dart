import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/presentation/widgets/provider_workspace_scaffold.dart';
import '../widgets/patient_header_strip.dart';
import '../widgets/provider_customers_shell.dart';
import '../widgets/provider_patient_tabbed_detail_pane.dart';

class ProviderCustomersScreen extends StatefulWidget {
  const ProviderCustomersScreen({super.key, this.forcedTab});

  final String? forcedTab;

  @override
  State<ProviderCustomersScreen> createState() =>
      _ProviderCustomersScreenState();
}

class _ProviderCustomersScreenState extends State<ProviderCustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';
  String? _lastRouteSelectedCustomerId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final routeSearch =
        GoRouterState.of(context).uri.queryParameters['search'] ?? '';
    if (_searchController.text != routeSearch) {
      _searchController.value = TextEditingValue(
        text: routeSearch,
        selection: TextSelection.collapsed(offset: routeSearch.length),
      );
      _searchQuery = routeSearch;
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProviderWorkspaceScaffold(
      builder: (context, ref, controller) {
        final routeState = GoRouterState.of(context);
        final roleKey = routeState.pathParameters['role'] ?? 'provider';
        final activeTab = _resolveTab(
          widget.forcedTab ?? routeState.uri.queryParameters['tab'],
        );
        final routeSelectedCustomerId = routeState
            .uri
            .queryParameters['selected_customer']
            ?.trim();

        _syncRouteSelection(
          routeSelectedCustomerId: routeSelectedCustomerId,
          controllerSelect: controller.selectCustomer,
          selectedCustomerId: controller.selectedCustomerId,
        );

        final filteredCustomers = controller.customers
            .where((customer) {
              final query = _searchQuery.trim().toLowerCase();
              if (query.isEmpty) {
                return true;
              }
              final haystack = [
                customer['fullName'],
                customer['customerCode'],
                customer['mobile'],
                customer['membershipNumber'],
                customer['membershipPlan'],
                customer['shieldCardNumber'],
                customer['city'],
                customer['district'],
                customer['status'],
              ].map((value) => value?.toString().toLowerCase() ?? '').join(' ');
              return haystack.contains(query);
            })
            .toList(growable: false);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProviderCustomersShell(
              searchController: _searchController,
              searchHint: controller.patientSearchPlaceholder,
              searchHelper: controller.patientSearchSubtitle,
              suggestions: controller.patientSearchSupportedQueries,
              customers: filteredCustomers,
              selectedCustomerId: controller.selectedCustomerId,
              loading:
                  controller.isCustomerLoading &&
                  controller.selectedCustomer == null,
              onSearchChanged: _handleSearchChanged,
              onSuggestionSelected: (query) {
                _searchController.value = TextEditingValue(
                  text: query,
                  selection: TextSelection.collapsed(offset: query.length),
                );
                _handleSearchChanged(query);
              },
              onCustomerSelected: (customerId) async {
                await controller.selectCustomer(customerId);
                if (!mounted) {
                  return;
                }
                _updateRoute(
                  selectedCustomerId: customerId,
                  activeTab: activeTab,
                  search: _searchQuery,
                );
              },
            ),
            const SizedBox(height: 16),
            if (controller.isCustomerLoading &&
                controller.selectedCustomer != null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (controller.selectedCustomer == null)
              _ProviderEmptyWorkspace(
                message: controller.patientWorkspaceEmptyStateMessage,
              )
            else ...[
              PatientHeaderStrip(
                customer: controller.selectedCustomer!,
                selectedMembershipLabel: controller.patientHeaderFieldValue(
                  'membership',
                ),
                cardStatusLabel: controller.patientHeaderFieldValue(
                  'shield-card',
                ),
                walletSummaryLabel: controller.patientHeaderFieldValue(
                  'wallet',
                ),
                locationLabel: controller.patientHeaderFieldValue('location'),
                bloodGroupLabel: controller.patientHeaderFieldValue(
                  'blood-group',
                ),
                upcomingVisitLabel: controller.patientHeaderFieldValue(
                  'upcoming-appointment',
                ),
                onOpenTab: (tabId) => _updateRoute(
                  selectedCustomerId: controller.selectedCustomerId,
                  activeTab: _resolveTab(tabId),
                  search: _searchQuery,
                ),
              ),
              const SizedBox(height: 16),
              ProviderPatientTabbedDetailPane(
                roleKey: roleKey,
                controller: controller,
                activeTab: activeTab,
                onTabChanged: (tabId) => _updateRoute(
                  selectedCustomerId: controller.selectedCustomerId,
                  activeTab: _resolveTab(tabId),
                  search: _searchQuery,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _handleSearchChanged(String value) {
    _searchDebounce?.cancel();
    setState(() {
      _searchQuery = value;
    });
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) {
        return;
      }
      _updateRoute(search: value, activeTab: _resolveTab(widget.forcedTab));
    });
  }

  void _syncRouteSelection({
    required String? routeSelectedCustomerId,
    required Future<void> Function(String customerId) controllerSelect,
    required String? selectedCustomerId,
  }) {
    final normalized = routeSelectedCustomerId?.trim();
    if (normalized == null || normalized.isEmpty) {
      return;
    }
    if (normalized == selectedCustomerId ||
        normalized == _lastRouteSelectedCustomerId) {
      return;
    }
    _lastRouteSelectedCustomerId = normalized;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      controllerSelect(normalized);
    });
  }

  void _updateRoute({
    String? selectedCustomerId,
    String? activeTab,
    String? search,
  }) {
    final current = GoRouterState.of(context).uri;
    final nextQuery = <String, String>{...current.queryParameters};

    final normalizedSearch = (search ?? _searchQuery).trim();
    if (normalizedSearch.isEmpty) {
      nextQuery.remove('search');
    } else {
      nextQuery['search'] = normalizedSearch;
    }

    final normalizedTab = _resolveTab(
      activeTab ?? widget.forcedTab ?? current.queryParameters['tab'],
    );
    nextQuery['tab'] = normalizedTab;

    final normalizedCustomer = selectedCustomerId?.trim();
    if (normalizedCustomer == null || normalizedCustomer.isEmpty) {
      nextQuery.remove('selected_customer');
    } else {
      nextQuery['selected_customer'] = normalizedCustomer;
      _lastRouteSelectedCustomerId = normalizedCustomer;
    }

    final nextUri = current.replace(queryParameters: nextQuery);
    context.go(nextUri.toString());
  }

  String _resolveTab(String? candidate) {
    const supportedTabs = {
      'documents',
      'clinical-notes',
      'billing-wallet',
      'timeline',
      'prescriptions',
    };
    final normalized = candidate?.trim();
    if (normalized == null || !supportedTabs.contains(normalized)) {
      return 'documents';
    }
    return normalized;
  }
}

class _ProviderEmptyWorkspace extends StatelessWidget {
  const _ProviderEmptyWorkspace({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF667085)),
      ),
    );
  }
}
