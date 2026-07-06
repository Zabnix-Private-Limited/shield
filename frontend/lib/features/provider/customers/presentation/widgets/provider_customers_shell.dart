import 'package:flutter/material.dart';

import '../../../../admin/shared/components/admin_data_table.dart';
import '../../../../../../app/theme/app_colors.dart';
import '../../../../../../app/theme/app_typography.dart';
import '../../../../../../shared/utils/app_display_formatters.dart';

class ProviderCustomersShell extends StatelessWidget {
  const ProviderCustomersShell({
    super.key,
    required this.searchController,
    required this.searchHint,
    required this.searchHelper,
    required this.suggestions,
    required this.customers,
    required this.selectedCustomerId,
    required this.loading,
    required this.onSearchChanged,
    required this.onSuggestionSelected,
    required this.onCustomerSelected,
  });

  final TextEditingController searchController;
  final String searchHint;
  final String searchHelper;
  final List<String> suggestions;
  final List<Map<String, dynamic>> customers;
  final String? selectedCustomerId;
  final bool loading;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSuggestionSelected;
  final ValueChanged<String> onCustomerSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Patient workspace', style: AppTypography.h4),
          const SizedBox(height: 8),
          Text(
            searchHelper,
            style: AppTypography.small.copyWith(color: AppColors.gray),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: searchHint,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searchController.text.trim().isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
            ),
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestions
                  .map(
                    (suggestion) => ActionChip(
                      label: Text(suggestion),
                      onPressed: () => onSuggestionSelected(suggestion),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                customers.isEmpty
                    ? 'No patients match the current search'
                    : 'Showing ${customers.length} patient${customers.length == 1 ? '' : 's'}',
                style: AppTypography.small.copyWith(
                  color: AppColors.gray,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (customers.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                'Try a different name, phone number, membership plan, or customer code.',
                style: AppTypography.small.copyWith(color: AppColors.gray),
              ),
            )
          else
            AdminDataTable<Map<String, dynamic>>(
              columns: [
                AdminDataTableColumn<Map<String, dynamic>>(
                  key: 'customer',
                  label: 'Patient',
                  valueBuilder: (row) {
                    final name = row['fullName']?.toString().trim();
                    final code = row['customerCode']?.toString().trim();
                    if ((code ?? '').isEmpty) {
                      return name?.isNotEmpty == true ? name! : 'SHIELD member';
                    }
                    return '${name?.isNotEmpty == true ? name : 'SHIELD member'}\n${AppDisplayFormatters.formatIdentifier(code!)}';
                  },
                ),
                AdminDataTableColumn<Map<String, dynamic>>(
                  key: 'membershipPlan',
                  label: 'Membership',
                  valueBuilder: (row) =>
                      row['membershipPlan']?.toString().trim().isNotEmpty ==
                          true
                      ? row['membershipPlan'].toString()
                      : AppDisplayFormatters.formatStatusLabel(
                          row['membershipStatus']?.toString() ?? 'Pending',
                        ),
                ),
                AdminDataTableColumn<Map<String, dynamic>>(
                  key: 'mobile',
                  label: 'Mobile',
                  valueBuilder: (row) => AppDisplayFormatters.formatPhone(
                    row['mobile']?.toString() ?? '',
                  ),
                ),
                AdminDataTableColumn<Map<String, dynamic>>(
                  key: 'city',
                  label: 'Location',
                  valueBuilder: (row) {
                    final city = row['city']?.toString().trim() ?? '';
                    final district = row['district']?.toString().trim() ?? '';
                    final label = [
                      city,
                      district,
                    ].where((value) => value.isNotEmpty).join(', ');
                    return label.isEmpty ? '-' : label;
                  },
                ),
                AdminDataTableColumn<Map<String, dynamic>>(
                  key: 'status',
                  label: 'Status',
                  valueBuilder: (row) => AppDisplayFormatters.formatStatusLabel(
                    row['status']?.toString() ?? 'Active',
                  ),
                ),
                AdminDataTableColumn<Map<String, dynamic>>(
                  key: 'updatedAt',
                  label: 'Updated',
                  valueBuilder: (row) =>
                      AppDisplayFormatters.formatDateOrDateTime(
                        row['updatedAt']?.toString() ??
                            row['createdAt']?.toString() ??
                            '',
                      ),
                ),
              ],
              rows: customers,
              selectionEnabled: true,
              selectionKey: (row) => row['id']?.toString() ?? '',
              selectedRowId: selectedCustomerId,
              onRowTap: (row) =>
                  onCustomerSelected(row['id']?.toString() ?? ''),
              onSelectionChanged: (ids) {
                if (ids.isNotEmpty) {
                  onCustomerSelected(ids.last);
                }
              },
            ),
        ],
      ),
    );
  }
}
