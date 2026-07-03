import 'package:flutter/material.dart';

import '../../../../../shared/widgets/shield_date_picker.dart';

Future<DateTime?> showShieldDatePickerSheet(
  BuildContext context, {
  required DateTime firstDate,
  required DateTime lastDate,
  DateTime? initialDate,
}) {
  return showShieldDatePicker(
    context,
    firstDate: firstDate,
    lastDate: lastDate,
    initialDate:
        initialDate ??
        DateTime(
          DateTime.now().year - 25,
          DateTime.now().month,
          DateTime.now().day,
        ),
    title: 'Select Date of Birth',
    helperText: 'Choose the correct date to complete your SHIELD profile.',
  );
}
