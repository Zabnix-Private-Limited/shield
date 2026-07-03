import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/shared/utils/shield_date_utils.dart';

void main() {
  group('ShieldDateUtils', () {
    test('normalizes a date range into ascending date-only bounds', () {
      final normalized = ShieldDateUtils.buildNormalizedDateRange(
        DateTime(2026, 7, 9, 18, 30),
        DateTime(2026, 7, 3, 8, 15),
      );

      expect(normalized.start, DateTime(2026, 7, 3));
      expect(normalized.end, DateTime(2026, 7, 9));
    });

    test('formats a single-day range without duplicating the date', () {
      final formatted = ShieldDateUtils.formatDisplayDateRange(
        DateTimeRange(
          start: DateTime(2026, 7, 3),
          end: DateTime(2026, 7, 3, 23, 59),
        ),
      );

      expect(formatted, '03/07/2026');
    });

    test('formats a multi-day range as a concise span', () {
      final formatted = ShieldDateUtils.formatDisplayDateRange(
        DateTimeRange(
          start: DateTime(2026, 7, 3),
          end: DateTime(2026, 7, 9),
        ),
      );

      expect(formatted, '03/07/2026 - 09/07/2026');
    });
  });
}
