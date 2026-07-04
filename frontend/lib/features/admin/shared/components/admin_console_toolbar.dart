import 'package:flutter/material.dart';

import 'admin_filter_bar.dart';
import 'admin_search_bar.dart';
import '../widgets/admin_section_tabs.dart';

class AdminConsoleToolbar extends StatelessWidget {
  const AdminConsoleToolbar({
    super.key,
    required this.searchHint,
    this.filters = const <String>[],
    this.tabs = const <String>[],
    this.trailing,
  });

  final String searchHint;
  final List<String> filters;
  final List<String> tabs;
  final Widget? trailing;

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
                  AdminSearchBar(hintText: searchHint),
                  if (trailing != null) ...[
                    const SizedBox(height: 12),
                    trailing!,
                  ],
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: AdminSearchBar(hintText: searchHint)),
                  if (trailing != null) ...[
                    const SizedBox(width: 16),
                    trailing!,
                  ],
                ],
              ),
        if (tabs.isNotEmpty) ...[
          const SizedBox(height: 12),
          AdminSectionTabs(tabs: tabs),
        ],
        if (filters.isNotEmpty) ...[
          const SizedBox(height: 12),
          AdminFilterBar(filters: filters),
        ],
      ],
    );
  }
}
