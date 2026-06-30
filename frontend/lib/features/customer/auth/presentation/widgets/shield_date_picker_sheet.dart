import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';

Future<DateTime?> showShieldDatePickerSheet(
  BuildContext context, {
  required DateTime firstDate,
  required DateTime lastDate,
  DateTime? initialDate,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.shieldNavy.withValues(alpha: 0.34),
    builder: (context) => _ShieldDatePickerSheet(
      firstDate: _dateOnly(firstDate),
      lastDate: _dateOnly(lastDate),
      initialDate: _dateOnly(
        initialDate ??
            DateTime(
              DateTime.now().year - 25,
              DateTime.now().month,
              DateTime.now().day,
            ),
      ),
    ),
  );
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

class _ShieldDatePickerSheet extends StatefulWidget {
  const _ShieldDatePickerSheet({
    required this.firstDate,
    required this.lastDate,
    required this.initialDate,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime initialDate;

  @override
  State<_ShieldDatePickerSheet> createState() => _ShieldDatePickerSheetState();
}

class _ShieldDatePickerSheetState extends State<_ShieldDatePickerSheet> {
  static const _monthNames = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const _weekdayNames = <String>[
    'Su',
    'Mo',
    'Tu',
    'We',
    'Th',
    'Fr',
    'Sa',
  ];

  late DateTime _selectedDate;
  late DateTime _displayMonth;
  bool _showMonthYearPicker = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = _clampToBounds(widget.initialDate);
    _displayMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark
        ? const Color(0xFF101828).withValues(alpha: 0.9)
        : AppColors.white.withValues(alpha: 0.86);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.white.withValues(alpha: 0.7);
    final textPrimary = isDark ? AppColors.white : AppColors.shieldNavy;
    final textSecondary = isDark
        ? Colors.white.withValues(alpha: 0.72)
        : AppColors.gray;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shieldNavy.withValues(alpha: 0.18),
                        blurRadius: 36,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 54,
                            height: 5,
                            decoration: BoxDecoration(
                              color: textSecondary.withValues(alpha: 0.24),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: Text(
                            'Select Date of Birth',
                            style: AppTypography.h5.copyWith(
                              color: textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _buildHeader(textPrimary, textSecondary),
                        const SizedBox(height: 18),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            final slide = Tween<Offset>(
                              begin: const Offset(0, 0.08),
                              end: Offset.zero,
                            ).animate(animation);
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: slide,
                                child: child,
                              ),
                            );
                          },
                          child: _showMonthYearPicker
                              ? _buildMonthYearPicker(
                                  key: const ValueKey('month-year-picker'),
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  isDark: isDark,
                                )
                              : _buildCalendar(
                                  key: ValueKey(
                                    'calendar-${_displayMonth.year}-${_displayMonth.month}',
                                  ),
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  isDark: isDark,
                                ),
                        ),
                        const SizedBox(height: 18),
                        const Divider(height: 1, color: AppColors.divider),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(
                                  foregroundColor: textSecondary,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  textStyle: AppTypography.body.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(_selectedDate),
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: AppColors.shieldBlue,
                                  foregroundColor: AppColors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  textStyle: AppTypography.body.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                child: const Text('Confirm'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color textPrimary, Color textSecondary) {
    final canGoPrev = _canMoveMonth(-1);
    final canGoNext = _canMoveMonth(1);

    return Row(
      children: [
        _HeaderButton(
          icon: Icons.chevron_left_rounded,
          enabled: canGoPrev,
          onTap: canGoPrev ? () => _shiftMonth(-1) : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () {
              setState(() {
                _showMonthYearPicker = !_showMonthYearPicker;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  Text(
                    '${_monthNames[_displayMonth.month - 1]} ${_displayMonth.year}',
                    style: AppTypography.h5.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _showMonthYearPicker
                        ? 'Tap a month to jump faster'
                        : 'Tap month/year for faster navigation',
                    style: AppTypography.tiny.copyWith(color: textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _HeaderButton(
          icon: Icons.chevron_right_rounded,
          enabled: canGoNext,
          onTap: canGoNext ? () => _shiftMonth(1) : null,
        ),
      ],
    );
  }

  Widget _buildCalendar({
    required Key key,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    final firstDay = DateTime(_displayMonth.year, _displayMonth.month, 1);
    final daysInMonth =
        DateTime(_displayMonth.year, _displayMonth.month + 1, 0).day;
    final leadingEmptyDays = firstDay.weekday % 7;

    final cells = <Widget>[
      for (final weekday in _weekdayNames)
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              weekday,
              style: AppTypography.tiny.copyWith(
                color: textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      for (var index = 0; index < leadingEmptyDays; index++)
        const SizedBox.shrink(),
      for (var day = 1; day <= daysInMonth; day++)
        _buildDayCell(
          DateTime(_displayMonth.year, _displayMonth.month, day),
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          isDark: isDark,
        ),
    ];

    return Container(
      key: key,
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 7,
        childAspectRatio: 0.92,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        children: cells,
      ),
    );
  }

  Widget _buildDayCell(
    DateTime date, {
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    final normalized = _dateOnly(date);
    final isSelected = normalized == _selectedDate;
    final isToday = normalized == _dateOnly(DateTime.now());
    final isDisabled =
        normalized.isBefore(widget.firstDate) || normalized.isAfter(widget.lastDate);

    Color backgroundColor = Colors.transparent;
    Color foregroundColor = textPrimary;
    BoxBorder? border;

    if (isSelected) {
      backgroundColor = AppColors.shieldBlue;
      foregroundColor = AppColors.white;
    } else if (isToday) {
      backgroundColor = AppColors.shieldBlue.withValues(alpha: 0.1);
      foregroundColor = AppColors.shieldBlue;
      border = Border.all(
        color: AppColors.shieldBlue.withValues(alpha: 0.22),
      );
    } else if (isDark) {
      backgroundColor = Colors.white.withValues(alpha: 0.02);
    }

    if (isDisabled) {
      foregroundColor = textSecondary.withValues(alpha: 0.38);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled
            ? null
            : () {
                setState(() {
                  _selectedDate = normalized;
                  _displayMonth = DateTime(normalized.year, normalized.month);
                });
              },
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: border,
          ),
          child: Text(
            '${date.day}',
            style: AppTypography.small.copyWith(
              color: foregroundColor,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthYearPicker({
    required Key key,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    final minYear = widget.firstDate.year;
    final maxYear = widget.lastDate.year;
    final canDecreaseYear = _displayMonth.year > minYear;
    final canIncreaseYear = _displayMonth.year < maxYear;

    return Container(
      key: key,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _HeaderButton(
                icon: Icons.chevron_left_rounded,
                enabled: canDecreaseYear,
                onTap: canDecreaseYear ? () => _shiftYear(-1) : null,
              ),
              Expanded(
                child: Text(
                  '${_displayMonth.year}',
                  textAlign: TextAlign.center,
                  style: AppTypography.h4.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _HeaderButton(
                icon: Icons.chevron_right_rounded,
                enabled: canIncreaseYear,
                onTap: canIncreaseYear ? () => _shiftYear(1) : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 12,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final month = index + 1;
              final monthDate = DateTime(_displayMonth.year, month, 1);
              final monthEnd = DateTime(_displayMonth.year, month + 1, 0);
              final isDisabled = monthEnd.isBefore(widget.firstDate) ||
                  monthDate.isAfter(widget.lastDate);
              final isActive = _displayMonth.month == month;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isDisabled
                      ? null
                      : () {
                          setState(() {
                            _displayMonth = DateTime(_displayMonth.year, month);
                            _selectedDate = _clampSelectedToDisplayMonth();
                            _showMonthYearPicker = false;
                          });
                        },
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.shieldBlue
                          : isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : AppColors.lightGray,
                      borderRadius: BorderRadius.circular(18),
                      border: isActive
                          ? null
                          : Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : AppColors.divider,
                            ),
                    ),
                    child: Text(
                      _monthNames[index].substring(0, 3),
                      style: AppTypography.small.copyWith(
                        color: isDisabled
                            ? textSecondary.withValues(alpha: 0.38)
                            : isActive
                                ? AppColors.white
                                : textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  bool _canMoveMonth(int delta) {
    final target = DateTime(_displayMonth.year, _displayMonth.month + delta);
    final lastMomentInTargetMonth =
        DateTime(target.year, target.month + 1, 0);
    return !(lastMomentInTargetMonth.isBefore(widget.firstDate) ||
        target.isAfter(widget.lastDate));
  }

  void _shiftMonth(int delta) {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + delta);
      _selectedDate = _clampSelectedToDisplayMonth();
    });
  }

  void _shiftYear(int delta) {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year + delta, _displayMonth.month);
      _selectedDate = _clampSelectedToDisplayMonth();
    });
  }

  DateTime _clampSelectedToDisplayMonth() {
    final daysInMonth = DateTime(_displayMonth.year, _displayMonth.month + 1, 0).day;
    final day = _selectedDate.year == _displayMonth.year &&
            _selectedDate.month == _displayMonth.month
        ? _selectedDate.day
        : 1;
    return _clampToBounds(
      DateTime(_displayMonth.year, _displayMonth.month, day.clamp(1, daysInMonth)),
    );
  }

  DateTime _clampToBounds(DateTime date) {
    if (date.isBefore(widget.firstDate)) {
      return widget.firstDate;
    }
    if (date.isAfter(widget.lastDate)) {
      return widget.lastDate;
    }
    return date;
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: enabled
                ? AppColors.shieldBlue.withValues(alpha: 0.08)
                : AppColors.divider.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            icon,
            color: enabled
                ? AppColors.shieldBlue
                : AppColors.gray.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
