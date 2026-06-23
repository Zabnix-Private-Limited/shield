import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

class ShieldDateInputField extends StatefulWidget {
  final String label;
  final String hintText;
  final DateTime initialDate;
  final DateTime? minDate;
  final DateTime? maxDate;
  final ValueChanged<DateTime> onChanged;

  const ShieldDateInputField({
    super.key,
    required this.label,
    required this.initialDate,
    required this.onChanged,
    this.hintText = 'DD/MM/YYYY',
    this.minDate,
    this.maxDate,
  });

  @override
  State<ShieldDateInputField> createState() => _ShieldDateInputFieldState();
}

class _ShieldDateInputFieldState extends State<ShieldDateInputField> {
  static final DateFormat _displayFormat = DateFormat('dd/MM/yyyy');
  static final List<DateFormat> _acceptedFormats = [
    DateFormat('dd/MM/yyyy'),
    DateFormat('d/M/yyyy'),
    DateFormat('dd-MM-yyyy'),
    DateFormat('d-M-yyyy'),
    DateFormat('yyyy-MM-dd'),
  ];

  late final TextEditingController _controller;
  late DateTime _selectedDate;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _selectedDate = _normalizeDate(widget.initialDate);
    _controller = TextEditingController(
      text: _displayFormat.format(_selectedDate),
    );
  }

  @override
  void didUpdateWidget(covariant ShieldDateInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final normalizedInitial = _normalizeDate(widget.initialDate);
    if (!_isSameDate(normalizedInitial, _selectedDate)) {
      _selectedDate = normalizedInitial;
      _controller.text = _displayFormat.format(_selectedDate);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DateTime _normalizeDate(DateTime date) => DateTime(date.year, date.month, date.day);

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime? _tryParse(String value) {
    final input = value.trim();
    if (input.isEmpty) {
      return null;
    }

    for (final format in _acceptedFormats) {
      try {
        return _normalizeDate(format.parseStrict(input));
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  bool _isWithinRange(DateTime date) {
    final minDate = widget.minDate != null ? _normalizeDate(widget.minDate!) : null;
    final maxDate = widget.maxDate != null ? _normalizeDate(widget.maxDate!) : null;

    if (minDate != null && date.isBefore(minDate)) {
      return false;
    }
    if (maxDate != null && date.isAfter(maxDate)) {
      return false;
    }
    return true;
  }

  void _commitDate(DateTime date) {
    final normalized = _normalizeDate(date);
    setState(() {
      _selectedDate = normalized;
      _controller.text = _displayFormat.format(normalized);
      _errorText = null;
    });
    widget.onChanged(normalized);
  }

  void _validateManualEntry() {
    final parsed = _tryParse(_controller.text);
    if (parsed == null) {
      setState(() {
        _errorText = 'Enter date as DD/MM/YYYY';
      });
      return;
    }

    if (!_isWithinRange(parsed)) {
      setState(() {
        _errorText = widget.minDate != null
            ? 'Previous dates are not allowed'
            : 'Enter a valid available date';
      });
      return;
    }

    _commitDate(parsed);
  }

  Future<void> _openPicker() async {
    final minDate = widget.minDate != null ? _normalizeDate(widget.minDate!) : null;
    final maxDate = widget.maxDate != null ? _normalizeDate(widget.maxDate!) : null;
    var tempSelected = _selectedDate;

    if (minDate != null && tempSelected.isBefore(minDate)) {
      tempSelected = minDate;
    }
    if (maxDate != null && tempSelected.isAfter(maxDate)) {
      tempSelected = maxDate;
    }

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        final pickerTheme = Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            surface: AppColors.white,
            surfaceContainerHighest: AppColors.white,
            primary: AppColors.shieldBlue,
          ),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        );

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shieldNavy.withValues(alpha: 0.12),
                  blurRadius: 32,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Theme(
              data: pickerTheme,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                child: StatefulBuilder(
                  builder: (context, setDialogState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          style: AppTypography.small.copyWith(color: AppColors.gray),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat('dd MMM yyyy').format(tempSelected),
                          style: AppTypography.h4.copyWith(
                            color: AppColors.shieldNavy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: SfDateRangePicker(
                            backgroundColor: AppColors.white,
                            view: DateRangePickerView.month,
                            selectionMode: DateRangePickerSelectionMode.single,
                            allowViewNavigation: true,
                            showNavigationArrow: true,
                            initialDisplayDate: tempSelected,
                            initialSelectedDate: tempSelected,
                            minDate: minDate,
                            maxDate: maxDate,
                            headerHeight: 60,
                            selectionShape: DateRangePickerSelectionShape.circle,
                            selectionColor: AppColors.shieldBlue,
                            todayHighlightColor: AppColors.shieldBlue,
                            headerStyle: DateRangePickerHeaderStyle(
                              textAlign: TextAlign.left,
                              textStyle: AppTypography.h4.copyWith(
                                color: AppColors.darkGray,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            monthViewSettings: DateRangePickerMonthViewSettings(
                              firstDayOfWeek: 7,
                              viewHeaderStyle: DateRangePickerViewHeaderStyle(
                                backgroundColor: const Color(0xFFEFF4FF),
                                textStyle: AppTypography.body.copyWith(
                                  color: AppColors.darkGray,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            monthCellStyle: DateRangePickerMonthCellStyle(
                              textStyle: AppTypography.body.copyWith(
                                color: AppColors.darkGray,
                              ),
                              trailingDatesTextStyle: AppTypography.body.copyWith(
                                color: AppColors.gray.withValues(alpha: 0.45),
                              ),
                              leadingDatesTextStyle: AppTypography.body.copyWith(
                                color: AppColors.gray.withValues(alpha: 0.45),
                              ),
                              todayTextStyle: AppTypography.body.copyWith(
                                color: AppColors.shieldBlue,
                                fontWeight: FontWeight.w700,
                              ),
                              disabledDatesTextStyle: AppTypography.body.copyWith(
                                color: AppColors.gray.withValues(alpha: 0.35),
                              ),
                            ),
                            selectionTextStyle: AppTypography.body.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w700,
                            ),
                            yearCellStyle: DateRangePickerYearCellStyle(
                              textStyle: AppTypography.body.copyWith(
                                color: AppColors.darkGray,
                              ),
                              leadingDatesTextStyle: AppTypography.body.copyWith(
                                color: AppColors.gray.withValues(alpha: 0.45),
                              ),
                              disabledDatesTextStyle: AppTypography.body.copyWith(
                                color: AppColors.gray.withValues(alpha: 0.35),
                              ),
                            ),
                            monthFormat: 'MMMM',
                            onSelectionChanged: (args) {
                              final value = args.value;
                              if (value is DateTime) {
                                setDialogState(() {
                                  tempSelected = _normalizeDate(value);
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'Cancel',
                                style: AppTypography.body.copyWith(color: AppColors.shieldBlue),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(tempSelected),
                              child: Text(
                                'OK',
                                style: AppTypography.body.copyWith(
                                  color: AppColors.shieldBlue,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );

    if (picked != null) {
      _commitDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTypography.small.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          keyboardType: TextInputType.datetime,
          onSubmitted: (_) => _validateManualEntry(),
          onEditingComplete: _validateManualEntry,
          decoration: InputDecoration(
            hintText: widget.hintText,
            errorText: _errorText,
            filled: true,
            fillColor: AppColors.lightGray,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              onPressed: _openPicker,
              icon: const Icon(Icons.calendar_month_outlined),
              color: AppColors.shieldBlue,
              tooltip: 'Open calendar',
            ),
          ),
        ),
      ],
    );
  }
}
