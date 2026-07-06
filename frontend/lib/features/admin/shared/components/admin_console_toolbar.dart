import 'package:flutter/material.dart';

import 'admin_filter_bar.dart';
import 'admin_search_bar.dart';
import '../widgets/admin_section_tabs.dart';

class AdminConsoleToolbar extends StatelessWidget {
  const AdminConsoleToolbar({
    super.key,
    required this.searchHint,
    this.searchValue = '',
    this.filters = const <String>[],
    this.tabs = const <String>[],
    this.selectedTab,
    this.selectedFilter,
    this.onSearchChanged,
    this.onSearchCleared,
    this.onTabSelected,
    this.onFilterSelected,
    this.onRefresh,
    this.trailing,
    this.showTabs = true,
  });

  final String searchHint;
  final String searchValue;
  final List<String> filters;
  final List<String> tabs;
  final String? selectedTab;
  final String? selectedFilter;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchCleared;
  final ValueChanged<String>? onTabSelected;
  final ValueChanged<String>? onFilterSelected;
  final VoidCallback? onRefresh;
  final Widget? trailing;
  final bool showTabs;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 1180;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        narrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminSearchBar(
                    hintText: searchHint,
                    value: searchValue,
                    onChanged: onSearchChanged,
                    onClear: onSearchCleared,
                  ),
                  if (trailing != null || onRefresh != null) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (trailing != null) trailing!,
                        if (onRefresh != null)
                          _RefreshButton(onPressed: onRefresh!),
                      ],
                    ),
                  ],
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AdminSearchBar(
                      hintText: searchHint,
                      value: searchValue,
                      onChanged: onSearchChanged,
                      onClear: onSearchCleared,
                    ),
                  ),
                  if (trailing != null || onRefresh != null) ...[
                    const SizedBox(width: 12),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (trailing != null) trailing!,
                        if (onRefresh != null)
                          _RefreshButton(onPressed: onRefresh!),
                      ],
                    ),
                  ],
                ],
              ),
        if (showTabs && tabs.isNotEmpty) ...[
          const SizedBox(height: 8),
          AdminSectionTabs(
            tabs: tabs,
            selectedTab: selectedTab,
            onSelected: onTabSelected,
          ),
        ],
        if (filters.isNotEmpty) ...[
          const SizedBox(height: 8),
          AdminFilterBar(
            filters: filters,
            selectedFilter: selectedFilter,
            onSelected: onFilterSelected,
          ),
        ],
      ],
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Refresh workspace',
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text('Refresh'),
      ),
    );
  }
}
