import 'package:intl/intl.dart';

class AppDisplayFormatters {
  AppDisplayFormatters._();

  static final DateFormat _shortDate = DateFormat('dd MMM yyyy');
  static final DateFormat _shortDateTime = DateFormat('dd MMM yyyy, hh:mm a');
  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );
  static final NumberFormat _integerNumber = NumberFormat.decimalPattern(
    'en_IN',
  );

  static String formatCell(String key, String value) {
    final normalizedValue = value.trim();
    if (normalizedValue.isEmpty) {
      return '-';
    }

    final normalizedKey = key.trim().toLowerCase();
    if (_looksLikeDateField(normalizedKey)) {
      return formatDateOrDateTime(normalizedValue);
    }
    if (_looksLikeCurrencyField(normalizedKey)) {
      return formatCurrencyString(normalizedValue);
    }
    if (_looksLikePhoneField(normalizedKey)) {
      return formatPhone(normalizedValue);
    }
    if (_looksLikeStatusField(normalizedKey)) {
      return formatStatusLabel(normalizedValue);
    }
    if (_looksLikeIdentifierField(normalizedKey)) {
      return formatIdentifier(normalizedValue);
    }
    return normalizedValue;
  }

  static String formatDateOrDateTime(String value) {
    final parsed = DateTime.tryParse(value.trim());
    if (parsed == null) {
      return value.trim();
    }

    final local = parsed.toLocal();
    final hasTime =
        local.hour != 0 ||
        local.minute != 0 ||
        local.second != 0 ||
        local.millisecond != 0;
    return hasTime ? _shortDateTime.format(local) : _shortDate.format(local);
  }

  static String formatCurrencyString(String value) {
    final sanitized = value.replaceAll(RegExp(r'[^0-9.-]'), '');
    final parsed = num.tryParse(sanitized);
    if (parsed == null) {
      return value.trim();
    }
    return _currency.format(parsed);
  }

  static String formatNumberString(String value) {
    final sanitized = value.replaceAll(RegExp(r'[^0-9.-]'), '');
    final parsed = num.tryParse(sanitized);
    if (parsed == null) {
      return value.trim();
    }
    return _integerNumber.format(parsed);
  }

  static String formatPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '${digits.substring(0, 5)} ${digits.substring(5)}';
    }
    if (digits.length == 12 && digits.startsWith('91')) {
      return '+91 ${digits.substring(2, 7)} ${digits.substring(7)}';
    }
    return value.trim();
  }

  static String formatStatusLabel(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return 'Unknown';
    }
    return normalized
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part.substring(0, 1).toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  static String formatIdentifier(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return '-';
    }
    if (normalized.length <= 18) {
      return normalized.toUpperCase();
    }
    return '${normalized.substring(0, 8).toUpperCase()}...${normalized.substring(normalized.length - 6).toUpperCase()}';
  }

  static bool _looksLikeDateField(String key) {
    return key.contains('date') ||
        key.contains('time') ||
        key.contains('joined') ||
        key.contains('updated') ||
        key.contains('created') ||
        key.contains('expiry');
  }

  static bool _looksLikeCurrencyField(String key) {
    return key.contains('amount') ||
        key.contains('price') ||
        key.contains('revenue') ||
        key.contains('wallet') ||
        key.contains('cash') ||
        key.contains('balance') ||
        key.contains('refund') ||
        key.contains('credit') ||
        key.contains('debit');
  }

  static bool _looksLikePhoneField(String key) {
    return key.contains('phone') ||
        key.contains('mobile') ||
        key.contains('contact');
  }

  static bool _looksLikeStatusField(String key) {
    return key == 'status' ||
        key.endsWith('_status') ||
        key.contains('state') ||
        key.contains('priority');
  }

  static bool _looksLikeIdentifierField(String key) {
    return key.endsWith('id') ||
        key.endsWith('_id') ||
        key.contains('code') ||
        key.contains('reference');
  }
}
