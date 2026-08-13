import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../customer/shared/widgets/error_card.dart';
import '../../data/models/customer_provider.dart';
import '../controllers/customer_services_controller.dart';

class CustomerServicesScreen extends StatefulWidget {
  const CustomerServicesScreen({super.key, this.controller});

  final CustomerServicesController? controller;

  @override
  State<CustomerServicesScreen> createState() => _CustomerServicesScreenState();
}

class _CustomerServicesScreenState extends State<CustomerServicesScreen> {
  late final CustomerServicesController _controller;
  late final bool _ownsController;
  final _search = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;
  String? _lastRoute;
  bool _openingProvider = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? CustomerServicesController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uri = _routeUri(context);
    final route = uri.toString();
    if (_lastRoute == route) return;
    _lastRoute = route;
    final query = uri.queryParameters['q'] ?? '';
    final type = uri.queryParameters['type'];
    final loadedPage = int.tryParse(uri.queryParameters['page'] ?? '') ?? 1;
    _search.value = _search.value.copyWith(text: query);
    if (_ownsController) {
      _controller.restore(query: query, type: type, loadedPage: loadedPage);
    } else {
      _controller.load(query: query, type: type);
    }
    final providerId = uri.queryParameters['provider'];
    if (providerId != null && providerId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_openingProvider) _showProvider(providerId);
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) {
      if (_controller.isLoading && _controller.categories.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_controller.error != null && _controller.categories.isEmpty) {
        return ErrorCard(
          title: 'Services unavailable',
          message: 'Provider discovery could not be loaded right now.',
          onRetry: _controller.load,
        );
      }
      return RefreshIndicator(
        onRefresh: _controller.load,
        child: ListView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Text('Services', style: AppTypography.h3),
            const SizedBox(height: 6),
            Text(
              _categoryPresentation(_controller.selectedType).intro,
              style: AppTypography.small.copyWith(color: AppColors.gray),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _search,
              onChanged: _searchProviders,
              decoration: InputDecoration(
                hintText: 'Search providers or services',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _search.clear();
                          _applyRoute(
                            query: '',
                            type: _controller.selectedType,
                          );
                          setState(() {});
                        },
                      ),
              ),
            ),
            const SizedBox(height: 16),
            _CategoryFilters(
              categories: _controller.categories,
              selected: _controller.selectedType,
              onSelected: (type) =>
                  _applyRoute(query: _search.text, type: type),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _categoryPresentation(_controller.selectedType).heading,
                    style: AppTypography.h4,
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      context.go('/portal/customer/book-appointment'),
                  child: const Text('Book a visit'),
                ),
              ],
            ),
            if (_controller.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ErrorCard(
                  title: 'Could not refresh providers',
                  message: 'Showing the last available result set.',
                  onRetry: _controller.load,
                ),
              ),
            if (_controller.page.items.isEmpty)
              AppCard(
                child: Text(
                  _search.text.trim().isEmpty
                      ? 'No active providers are available right now.'
                      : 'No providers match your search.',
                  style: AppTypography.small.copyWith(color: AppColors.gray),
                ),
              )
            else
              ..._controller.page.items.map(
                (provider) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ProviderCard(
                    provider: provider,
                    onTap: () => _openProvider(provider),
                  ),
                ),
              ),
            if (_controller.page.page < _controller.page.totalPages)
              Center(
                child: TextButton(
                  onPressed: _controller.isLoading ? null : _loadNextPage,
                  child: Text(
                    _controller.isLoading
                        ? 'Loading more…'
                        : 'Load more providers',
                  ),
                ),
              ),
            const SizedBox(height: 8),
            AppCard(
              child: Row(
                children: [
                  const Icon(
                    Icons.support_agent_outlined,
                    color: AppColors.shieldBlue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Need membership or benefit help?',
                      style: AppTypography.small.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/portal/customer/settings'),
                    child: const Text('Support'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );

  void _searchProviders(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _applyRoute(query: value, type: _controller.selectedType);
    });
  }

  void _applyRoute({required String query, required String? type}) {
    final trimmed = query.trim();
    final route = _servicesRoute(query: trimmed, type: type);
    if (_routeUri(context).toString() == route) {
      _controller.applyFilters(query: trimmed, type: type);
      return;
    }
    context.go(route);
  }

  Future<void> _loadNextPage() async {
    await _controller.loadNextPage();
    if (!mounted || _controller.error != null) return;
    context.replace(
      _servicesRoute(
        query: _controller.query,
        type: _controller.selectedType,
        page: _controller.page.page,
      ),
    );
  }

  void _openProvider(CustomerProvider provider) {
    if (provider.id.trim().isEmpty) return;
    _showProvider(provider.id);
  }

  Future<void> _showProvider(String id) async {
    _openingProvider = true;
    try {
      final provider = _controller.page.items
          .where((item) => item.id == id)
          .firstOrNull;
      final selectedProvider = await showModalBottomSheet<CustomerProvider>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        builder: (sheetContext) => _ProviderDetailsSheet(
          providerId: id,
          provider: provider,
          loadDetails: _controller.provider,
          actionLabelForType: _providerActionLabel,
          onAction: (resolvedProvider) =>
              Navigator.of(sheetContext).pop(resolvedProvider),
        ),
      );
      if (mounted && selectedProvider != null) {
        _openProviderAction(
          type: selectedProvider.type,
          providerId: selectedProvider.id,
        );
      }
    } finally {
      _openingProvider = false;
    }
  }

  String _providerActionLabel(String type) =>
      type.trim().toUpperCase() == 'PHARMACY'
      ? 'Open prescription upload'
      : _supportsBooking(type)
      ? 'Continue to booking'
      : 'View booking options';

  bool _supportsBooking(String type) =>
      const {'CLINIC', 'DENTAL'}.contains(type.trim().toUpperCase());

  void _openProviderAction({required String type, String? providerId}) {
    if (type.trim().toUpperCase() == 'PHARMACY') {
      context.push(
        Uri(
          path: '/portal/customer/prescriptions',
          queryParameters: {
            if (providerId != null && providerId.isNotEmpty)
              'provider': providerId,
            'type': 'PHARMACY',
          },
        ).toString(),
      );
      return;
    }
    final query = <String, String>{
      if (providerId != null && providerId.isNotEmpty) 'provider': providerId,
      if (type.trim().isNotEmpty) 'type': type.trim().toUpperCase(),
    };
    context.push(
      Uri(
        path: '/portal/customer/book-appointment',
        queryParameters: query,
      ).toString(),
    );
  }
}

Uri _routeUri(BuildContext context) {
  try {
    return GoRouterState.of(context).uri;
  } catch (_) {
    return Uri.parse('/portal/customer/services');
  }
}

String _servicesRoute({
  required String query,
  required String? type,
  int page = 1,
  String? provider,
}) {
  final parameters = <String, String>{
    if (query.isNotEmpty) 'q': query,
    if (type != null && type.isNotEmpty) 'type': type,
    if (page > 1) 'page': '$page',
    if (provider != null && provider.isNotEmpty) 'provider': provider,
  };
  return Uri(
    path: '/portal/customer/services',
    queryParameters: parameters,
  ).toString();
}

class _CategoryFilters extends StatelessWidget {
  const _CategoryFilters({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });
  final List<CustomerProviderCategory> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        ChoiceChip(
          label: const Text('All'),
          selected: selected == null,
          onSelected: (_) => onSelected(null),
        ),
        ...categories.map(
          (category) => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(
              avatar: Icon(_categoryPresentation(category.code).icon, size: 18),
              label: Text(category.label),
              selected: selected == category.code,
              onSelected: (_) => onSelected(category.code),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.provider, required this.onTap});
  final CustomerProvider provider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    child: Row(
      children: [
        CircleAvatar(child: Icon(_categoryPresentation(provider.type).icon)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.name,
                style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                [
                  provider.typeLabel,
                  provider.businessName,
                ].whereType<String>().join(' · '),
                style: AppTypography.tiny.copyWith(color: AppColors.gray),
              ),
            ],
          ),
        ),
        Text(
          provider.availabilityLabel,
          style: AppTypography.tiny.copyWith(
            color: AppColors.shieldGreen,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _ProviderDetailsSheet extends StatelessWidget {
  const _ProviderDetailsSheet({
    required this.providerId,
    required this.provider,
    required this.loadDetails,
    required this.actionLabelForType,
    required this.onAction,
  });

  final String providerId;
  final CustomerProvider? provider;
  final Future<CustomerProvider> Function(String id) loadDetails;
  final String Function(String type) actionLabelForType;
  final ValueChanged<CustomerProvider> onAction;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CustomerProvider>(
      future: loadDetails(providerId),
      builder: (context, snapshot) {
        final details = snapshot.data ?? provider;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                details?.name ?? 'Provider details',
                style: AppTypography.h4,
              ),
              if (details != null) ...[
                const SizedBox(height: 8),
                Text(
                  details.typeLabel,
                  style: AppTypography.small.copyWith(color: AppColors.gray),
                ),
                if (details.businessName != null) ...[
                  const SizedBox(height: 8),
                  Text(details.businessName!),
                ],
              ],
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: LinearProgressIndicator(),
                ),
              const SizedBox(height: 16),
              Text(
                snapshot.hasError
                    ? 'Provider details could not be loaded. You can still continue to the existing booking flow.'
                    : 'Only customer-visible provider details are shown. Coverage, hours, ratings, and location are not available in the current customer contract.',
                style: AppTypography.small.copyWith(color: AppColors.gray),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: details == null ? null : () => onAction(details),
                child: Text(actionLabelForType(details?.type ?? '')),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryPresentation {
  const _CategoryPresentation(this.heading, this.intro, this.icon);

  final String heading;
  final String intro;
  final IconData icon;
}

_CategoryPresentation _categoryPresentation(String? type) {
  switch (type?.trim().toUpperCase()) {
    case 'PHARMACY':
      return const _CategoryPresentation(
        'Pharmacies',
        'Find active pharmacy providers and use the existing prescription upload flow when needed.',
        Icons.local_pharmacy_outlined,
      );
    case 'LAB':
    case 'LABORATORY':
      return const _CategoryPresentation(
        'Laboratories',
        'Find active laboratory providers. Booking is shown only when the existing flow supports it.',
        Icons.science_outlined,
      );
    case 'DENTAL':
      return const _CategoryPresentation(
        'Dental care',
        'Find active dental providers and continue to the supported booking flow.',
        Icons.mood_outlined,
      );
    case 'HOMECARE':
    case 'HOME_CARE':
      return const _CategoryPresentation(
        'Home care',
        'Find active home-care providers and view the available next steps.',
        Icons.home_outlined,
      );
    case 'DIETITIAN':
      return const _CategoryPresentation(
        'Dietitian services',
        'Find active dietitian providers and view the available next steps.',
        Icons.restaurant_menu_outlined,
      );
    case 'WELLNESS':
      return const _CategoryPresentation(
        'Wellness providers',
        'Discover active wellness providers. This is separate from the Wellness Shop catalogue.',
        Icons.spa_outlined,
      );
    case 'CLINIC':
    case 'DOCTOR':
      return const _CategoryPresentation(
        'Consultations',
        'Find active consultation providers and continue to the supported booking flow.',
        Icons.medical_services_outlined,
      );
    default:
      return const _CategoryPresentation(
        'Providers',
        'Find active SHIELD providers and continue to existing care flows.',
        Icons.medical_services_outlined,
      );
  }
}
