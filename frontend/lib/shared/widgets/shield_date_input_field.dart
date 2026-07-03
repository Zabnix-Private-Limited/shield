import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../utils/shield_date_utils.dart';
import 'shield_date_picker.dart';

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
  late final TextEditingController _controller;
  late DateTime _selectedDate;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _selectedDate = ShieldDateUtils.dateOnly(widget.initialDate);
    _controller = TextEditingController(text: _formattedDate);
  }

  @override
  void didUpdateWidget(covariant ShieldDateInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final normalizedInitial = ShieldDateUtils.dateOnly(widget.initialDate);
    if (!ShieldDateUtils.isSameDate(normalizedInitial, _selectedDate)) {
      _selectedDate = normalizedInitial;
      _controller.text = _formattedDate;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _formattedDate => ShieldDateUtils.formatDisplayDate(_selectedDate);

  bool _isWithinRange(DateTime date) {
    final minDate = widget.minDate != null
        ? ShieldDateUtils.dateOnly(widget.minDate!)
        : null;
    final maxDate = widget.maxDate != null
        ? ShieldDateUtils.dateOnly(widget.maxDate!)
        : null;

    if (minDate != null && date.isBefore(minDate)) {
      return false;
    }
    if (maxDate != null && date.isAfter(maxDate)) {
      return false;
    }
    return true;
  }

  void _commitDate(DateTime date) {
    final normalized = ShieldDateUtils.dateOnly(date);
    setState(() {
      _selectedDate = normalized;
      _controller.text = ShieldDateUtils.formatDisplayDate(normalized);
      _errorText = null;
    });
    widget.onChanged(normalized);
  }

  void _validateManualEntry() {
    final parsed = ShieldDateUtils.tryParseFlexibleDate(_controller.text);
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
    final minDate = widget.minDate != null
        ? ShieldDateUtils.dateOnly(widget.minDate!)
        : null;
    final maxDate = widget.maxDate != null
        ? ShieldDateUtils.dateOnly(widget.maxDate!)
        : null;
    var tempSelected = _selectedDate;

    if (minDate != null && tempSelected.isBefore(minDate)) {
      tempSelected = minDate;
    }
    if (maxDate != null && tempSelected.isAfter(maxDate)) {
      tempSelected = maxDate;
    }

    final picked = await showShieldDatePicker(
      context,
      firstDate: minDate ?? DateTime(1930),
      lastDate: maxDate ?? DateTime(DateTime.now().year + 50, 12, 31),
      initialDate: tempSelected,
      title: widget.label,
      helperText: 'Enter the date manually or use the SHIELD calendar.',
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
