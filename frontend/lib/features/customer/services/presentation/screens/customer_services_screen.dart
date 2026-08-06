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
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? CustomerServicesController();
    _controller.load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
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
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Text('Services', style: AppTypography.h3),
            const SizedBox(height: 6),
            Text(
              'Find active SHIELD providers and continue to existing care flows.',
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
                          _controller.load(
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
                  _controller.load(query: _search.text, type: type),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Text('Providers', style: AppTypography.h4)),
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
                  child: _ProviderCard(provider: provider),
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
      _controller.load(query: value, type: _controller.selectedType);
    });
  }
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
  const _ProviderCard({required this.provider});
  final CustomerProvider provider;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: () => showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(provider.name, style: AppTypography.h4),
            const SizedBox(height: 8),
            Text(
              provider.typeLabel,
              style: AppTypography.small.copyWith(color: AppColors.gray),
            ),
            if (provider.businessName != null) ...[
              const SizedBox(height: 8),
              Text(provider.businessName!),
            ],
            const SizedBox(height: 16),
            Text(
              'Additional provider details, coverage, hours, ratings, and location are not available in the current customer contract.',
              style: AppTypography.small.copyWith(color: AppColors.gray),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/portal/customer/book-appointment'),
              child: const Text('Continue to booking'),
            ),
          ],
        ),
      ),
    ),
    child: Row(
      children: [
        const CircleAvatar(child: Icon(Icons.medical_services_outlined)),
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
