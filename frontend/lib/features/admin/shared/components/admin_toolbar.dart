import 'package:flutter/material.dart';

import 'admin_filter_bar.dart';
import 'admin_search_bar.dart';

class AdminToolbar extends StatelessWidget {
  const AdminToolbar({
    super.key,
    this.searchHint = 'Search',
    this.filters = const <String>[],
  });

  final String searchHint;
  final List<String> filters;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminSearchBar(hintText: searchHint),
        if (filters.isNotEmpty) ...[
          const SizedBox(height: 12),
          AdminFilterBar(filters: filters),
        ],
      ],
    );
  }
}
