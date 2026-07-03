import 'package:intl/intl.dart';

class ShieldDateUtils {
  ShieldDateUtils._();

  static final DateFormat displayDateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat shortMonthDateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat shortMonthDateTimeFormat = DateFormat(
    'dd MMM, h:mm a',
  );

  static final List<DateFormat> acceptedInputFormats = <DateFormat>[
    DateFormat('dd/MM/yyyy'),
    DateFormat('d/M/yyyy'),
    DateFormat('dd-MM-yyyy'),
    DateFormat('d-M-yyyy'),
    DateFormat('yyyy-MM-dd'),
  ];

  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool isSameDate(DateTime a, DateTime b) {
    final left = dateOnly(a);
    final right = dateOnly(b);
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  static DateTime? tryParseFlexibleDate(String input) {
    final normalized = input.trim();
    if (normalized.isEmpty) {
      return null;
    }

    for (final format in acceptedInputFormats) {
      try {
        return dateOnly(format.parseStrict(normalized));
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  static String formatDisplayDate(DateTime date) {
    return displayDateFormat.format(dateOnly(date));
  }

  static String formatShortMonthDate(DateTime date) {
    return shortMonthDateFormat.format(dateOnly(date));
  }

  static String formatShortMonthDateTime(DateTime date) {
    return shortMonthDateTimeFormat.format(date.toLocal());
  }
}
