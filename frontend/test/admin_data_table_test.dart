import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/admin/shared/components/admin_data_table.dart';

void main() {
  testWidgets(
    'AdminDataTable supports server-sort controls, row selection, row tap, export, and pagination callbacks',
    (tester) async {
      String? tappedRowId;
      String? sortedColumnKey;
      bool? sortAscending;
      int? changedPage;
      int? changedPageSize;
      var exportTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminDataTable<Map<String, String>>(
              columns: [
                AdminDataTableColumn<Map<String, String>>(
                  key: 'customer',
                  label: 'Customer',
                  sortKey: 'name',
                  valueBuilder: _readValue('customer'),
                ),
                AdminDataTableColumn<Map<String, String>>(
                  key: 'status',
                  label: 'Status',
                  sortKey: 'status',
                  valueBuilder: _readValue('status'),
                ),
              ],
              rows: const [
                {'id': '1', 'customer': 'Arun Thomas', 'status': 'ACTIVE'},
                {'id': '2', 'customer': 'Bina Joseph', 'status': 'SUSPENDED'},
              ],
              selectionKey: (row) => row['id'] ?? '',
              selectedRowId: '2',
              selectionEnabled: true,
              sortedColumnKey: 'name',
              sortAscending: true,
              onSortChanged: (columnKey, ascending) {
                sortedColumnKey = columnKey;
                sortAscending = ascending;
              },
              onRowTap: (row) {
                tappedRowId = row['id'];
              },
              page: 2,
              pageSize: 25,
              totalRows: 60,
              onPageChanged: (page) {
                changedPage = page;
              },
              onPageSizeChanged: (pageSize) {
                changedPageSize = pageSize;
              },
              onExport: () {
                exportTriggered = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('1 selected'), findsOneWidget);
      expect(find.text('Page 2 of 3'), findsOneWidget);
      expect(find.text('Rows per page'), findsOneWidget);
      expect(find.text('Export'), findsOneWidget);

      await tester.tap(find.text('Export'));
      await tester.pump();
      expect(exportTriggered, isTrue);

      await tester.tap(find.text('Customer'));
      await tester.pump();
      expect(sortedColumnKey, 'name');
      expect(sortAscending, isFalse);

      await tester.tap(find.text('Bina Joseph'));
      await tester.pump();
      expect(tappedRowId, '2');

      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(changedPage, 3);

      await tester.tap(find.text('25 / page'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('50 / page').last);
      await tester.pumpAndSettle();
      expect(changedPageSize, 50);
    },
  );
}

String Function(Map<String, String>) _readValue(String key) {
  return (row) => row[key] ?? '';
}
