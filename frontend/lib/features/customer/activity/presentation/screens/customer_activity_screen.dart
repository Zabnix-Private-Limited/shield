import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/services/api_service.dart';
import '../../../../customer/shared/widgets/error_card.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_skeleton.dart';

class CustomerActivityScreen extends StatefulWidget {
  const CustomerActivityScreen({super.key});

  @override
  State<CustomerActivityScreen> createState() => _CustomerActivityScreenState();
}

class _CustomerActivityScreenState extends State<CustomerActivityScreen> {
  final _events = <Map<String, dynamic>>[];
  String? _selectedCategory;
  var _isLoading = true;
  var _isLoadingMore = false;
  var _hasMore = false;
  var _page = 1;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadTimeline(reset: true);
  }

  Future<void> _loadTimeline({required bool reset}) async {
    if (_isLoadingMore || (!reset && !_hasMore)) return;
    final requestedPage = reset ? 1 : _page + 1;
    setState(() {
      if (reset && _events.isEmpty) _isLoading = true;
      if (!reset) _isLoadingMore = true;
      _error = null;
    });
    try {
      final response = await ApiService.getCustomerTimeline(
        page: requestedPage,
      );
      final items = (response['items'] as List? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      final pagination = Map<String, dynamic>.from(
        response['pagination'] as Map? ?? const <String, dynamic>{},
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _events
            ..clear()
            ..addAll(items);
        } else {
          final unique = <String, Map<String, dynamic>>{
            for (final event in _events) event['id'].toString(): event,
            for (final event in items) event['id'].toString(): event,
          };
          _events
            ..clear()
            ..addAll(unique.values);
        }
        _page = (pagination['page'] as num?)?.toInt() ?? requestedPage;
        _hasMore = pagination['hasMore'] == true;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _events.isEmpty) {
      return const AppPortalSectionSkeleton(showHero: true, listItems: 5);
    }
    if (_error != null && _events.isEmpty) {
      return ErrorCard(
        title: 'Could not load activity',
        message: 'Please check your connection and try again.',
        onRetry: () => _loadTimeline(reset: true),
      );
    }

    final events = _events;
    final categories =
        events
            .map((event) => event['category']?.toString().trim() ?? '')
            .where((category) => category.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final visibleEvents = _selectedCategory == null
        ? events
        : events
              .where(
                (event) =>
                    event['category']?.toString().toUpperCase() ==
                    _selectedCategory,
              )
              .toList();
    return RefreshIndicator(
      onRefresh: () => _loadTimeline(reset: true),
      color: AppColors.shieldBlue,
      child: events.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [_ActivityEmptyState()],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount:
                  2 +
                  (visibleEvents.isEmpty ? 1 : visibleEvents.length) +
                  ((_hasMore || _isLoadingMore) && visibleEvents.isNotEmpty
                      ? 1
                      : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0) return const _ActivityIntro();
                if (index == 1) {
                  return _ActivityFilters(
                    categories: categories,
                    selectedCategory: _selectedCategory,
                    onSelected: (category) =>
                        setState(() => _selectedCategory = category),
                  );
                }
                if (visibleEvents.isEmpty && index == 2) {
                  return const _ActivityFilteredEmptyState();
                }
                if (index == visibleEvents.length + 2) {
                  return Center(
                    child: TextButton(
                      onPressed: _isLoadingMore
                          ? null
                          : () => _loadTimeline(reset: false),
                      child: Text(
                        _isLoadingMore ? 'Loading more…' : 'Load more activity',
                      ),
                    ),
                  );
                }
                return _ActivityEventCard(event: visibleEvents[index - 2]);
              },
            ),
    );
  }
}

class _ActivityFilters extends StatelessWidget {
  const _ActivityFilters({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('All'),
          selected: selectedCategory == null,
          onSelected: (_) => onSelected(null),
        ),
        ...categories.map(
          (category) => ChoiceChip(
            label: Text(_displayCategory(category)),
            selected: selectedCategory == category.toUpperCase(),
            onSelected: (_) => onSelected(category.toUpperCase()),
          ),
        ),
      ],
    );
  }

  String _displayCategory(String value) => value
      .toLowerCase()
      .split('_')
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}

class _ActivityIntro extends StatelessWidget {
  const _ActivityIntro();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.shieldBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.timeline_outlined,
                color: AppColors.shieldBlue,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Activity timeline', style: AppTypography.h4),
                  SizedBox(height: 4),
                  Text(
                    'Your membership, visits, documents, wallet and notification activity.',
                    style: AppTypography.small,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityEmptyState extends StatelessWidget {
  const _ActivityEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 36),
      child: AppCard(
        child: Column(
          children: [
            Icon(Icons.timeline_outlined, size: 42, color: AppColors.gray),
            SizedBox(height: 12),
            Text('No activity yet', style: AppTypography.h4),
            SizedBox(height: 6),
            Text(
              'Membership, visits, documents and wallet activity will appear here when recorded.',
              textAlign: TextAlign.center,
              style: AppTypography.body,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityFilteredEmptyState extends StatelessWidget {
  const _ActivityFilteredEmptyState();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Text(
        'No activity matches this filter.',
        style: AppTypography.body,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ActivityEventCard extends StatelessWidget {
  const _ActivityEventCard({required this.event});

  final Map<String, dynamic> event;

  @override
  Widget build(BuildContext context) {
    final category = event['category']?.toString() ?? 'ACTIVITY';
    final timestamp = DateTime.tryParse(event['timestamp']?.toString() ?? '');
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _colorFor(category).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_iconFor(category), color: _colorFor(category)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['displayTitle']?.toString() ?? 'Activity recorded',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event['description']?.toString() ?? 'SHIELD activity update',
                  style: AppTypography.small.copyWith(
                    color: AppColors.darkGray,
                  ),
                ),
                if (timestamp != null) ...[
                  const SizedBox(height: 7),
                  Text(
                    DateFormat('dd MMM yyyy • hh:mm a').format(timestamp),
                    style: AppTypography.tiny.copyWith(color: AppColors.gray),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(String category) => switch (category.toUpperCase()) {
    'MEMBERSHIP' => AppColors.shieldBlue,
    'WALLET' => AppColors.shieldGreen,
    'DOCUMENT' || 'PRESCRIPTION' => AppColors.shieldLightBlue,
    'LAB' => AppColors.shieldLightBlue,
    'BILLING' => AppColors.warning,
    'NOTIFICATION' => AppColors.shieldBlue,
    'APPOINTMENT' || 'VISIT' => AppColors.warning,
    _ => AppColors.shieldNavy,
  };

  IconData _iconFor(String category) => switch (category.toUpperCase()) {
    'MEMBERSHIP' => Icons.workspace_premium_outlined,
    'WALLET' => Icons.account_balance_wallet_outlined,
    'DOCUMENT' || 'PRESCRIPTION' => Icons.description_outlined,
    'LAB' => Icons.science_outlined,
    'BILLING' => Icons.receipt_long_outlined,
    'NOTIFICATION' => Icons.notifications_active_outlined,
    'APPOINTMENT' || 'VISIT' => Icons.calendar_month_outlined,
    _ => Icons.timeline_outlined,
  };
}
