import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../utils/shield_date_utils.dart';

typedef ShieldSelectableDatePredicate = bool Function(DateTime date);

Future<DateTime?> showShieldDatePicker(
  BuildContext context, {
  required DateTime firstDate,
  required DateTime lastDate,
  DateTime? initialDate,
  String title = 'Select Date',
  String? helperText,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool autoCloseOnSelect = false,
  ShieldSelectableDatePredicate? selectableDayPredicate,
}) {
  final normalizedFirstDate = ShieldDateUtils.dateOnly(firstDate);
  final normalizedLastDate = ShieldDateUtils.dateOnly(lastDate);
  final normalizedInitialDate = ShieldDateUtils.dateOnly(
    initialDate ?? normalizedFirstDate,
  );
  final isDesktopLayout = MediaQuery.sizeOf(context).width >= 720;

  final picker = _ShieldDatePickerSurface(
    firstDate: normalizedFirstDate,
    lastDate: normalizedLastDate,
    initialDate: normalizedInitialDate,
    title: title,
    helperText: helperText,
    confirmLabel: confirmLabel,
    cancelLabel: cancelLabel,
    autoCloseOnSelect: autoCloseOnSelect,
    selectableDayPredicate: selectableDayPredicate,
  );

  if (isDesktopLayout) {
    return showDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: picker,
      ),
    );
  }

  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.shieldNavy.withValues(alpha: 0.34),
    builder: (context) => picker,
  );
}

Future<DateTimeRange?> showShieldDateRangePicker(
  BuildContext context, {
  required DateTime firstDate,
  required DateTime lastDate,
  DateTimeRange? initialDateRange,
  String title = 'Select Date Range',
  String? helperText,
  String startTitle = 'Select Start Date',
  String endTitle = 'Select End Date',
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  ShieldSelectableDatePredicate? selectableDayPredicate,
}) async {
  final normalizedFirstDate = ShieldDateUtils.dateOnly(firstDate);
  final normalizedLastDate = ShieldDateUtils.dateOnly(lastDate);
  final fallbackRange = DateTimeRange(
    start: normalizedFirstDate,
    end: normalizedFirstDate,
  );
  final normalizedInitialRange = ShieldDateUtils.normalizeDateRange(
    initialDateRange ?? fallbackRange,
  );

  final startDate = await showShieldDatePicker(
    context,
    firstDate: normalizedFirstDate,
    lastDate: normalizedLastDate,
    initialDate: normalizedInitialRange.start,
    title: startTitle,
    helperText:
        helperText ?? '$title\nChoose the first date in the reporting range.',
    confirmLabel: 'Next',
    cancelLabel: cancelLabel,
    selectableDayPredicate: selectableDayPredicate,
  );
  if (startDate == null) {
    return null;
  }
  if (!context.mounted) {
    return null;
  }

  final normalizedStart = ShieldDateUtils.dateOnly(startDate);
  final fallbackEnd = normalizedInitialRange.end.isBefore(normalizedStart)
      ? normalizedStart
      : normalizedInitialRange.end;
  final endDate = await showShieldDatePicker(
    context,
    firstDate: normalizedStart,
    lastDate: normalizedLastDate,
    initialDate: fallbackEnd,
    title: endTitle,
    helperText:
        helperText ?? '$title\nChoose the last date in the reporting range.',
    confirmLabel: confirmLabel,
    cancelLabel: cancelLabel,
    selectableDayPredicate: selectableDayPredicate,
  );
  if (endDate == null) {
    return null;
  }

  return ShieldDateUtils.normalizeDateRange(
    DateTimeRange(start: normalizedStart, end: endDate),
  );
}

class _ShieldDatePickerSurface extends StatefulWidget {
  const _ShieldDatePickerSurface({
    required this.firstDate,
    required this.lastDate,
    required this.initialDate,
    required this.title,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.autoCloseOnSelect,
    this.helperText,
    this.selectableDayPredicate,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime initialDate;
  final String title;
  final String? helperText;
  final String confirmLabel;
  final String cancelLabel;
  final bool autoCloseOnSelect;
  final ShieldSelectableDatePredicate? selectableDayPredicate;

  @override
  State<_ShieldDatePickerSurface> createState() =>
      _ShieldDatePickerSurfaceState();
}

class _ShieldDatePickerSurfaceState extends State<_ShieldDatePickerSurface> {
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
    final isDesktopLayout = MediaQuery.sizeOf(context).width >= 720;
    final surfaceColor = isDark
        ? const Color(0xFF101828).withValues(alpha: 0.92)
        : AppColors.white.withValues(alpha: 0.96);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.white.withValues(alpha: 0.7);
    final textPrimary = isDark ? AppColors.white : AppColors.shieldNavy;
    final textSecondary = isDark
        ? Colors.white.withValues(alpha: 0.72)
        : AppColors.gray;

    final shell = ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
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
                if (!isDesktopLayout)
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
                SizedBox(height: isDesktopLayout ? 4 : 18),
                Center(
                  child: Text(
                    widget.title,
                    style: AppTypography.h5.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if ((widget.helperText ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.helperText!,
                    textAlign: TextAlign.center,
                    style: AppTypography.small.copyWith(
                      color: textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
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
                      child: SlideTransition(position: slide, child: child),
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
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: Text(widget.cancelLabel),
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
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          textStyle: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        child: Text(widget.confirmLabel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (isDesktopLayout) {
      return shell;
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Align(alignment: Alignment.bottomCenter, child: shell),
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
                        : 'Tap month or year for faster navigation',
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
    final daysInMonth = DateTime(_displayMonth.year, _displayMonth.month + 1, 0)
        .day;
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

    return Listener(
      key: key,
      onPointerSignal: (signal) {
        if (signal is PointerScrollEvent) {
          if (signal.scrollDelta.dy > 0 && _canMoveMonth(1)) {
            _shiftMonth(1);
          } else if (signal.scrollDelta.dy < 0 && _canMoveMonth(-1)) {
            _shiftMonth(-1);
          }
        }
      },
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
    final normalized = ShieldDateUtils.dateOnly(date);
    final isSelected = ShieldDateUtils.isSameDate(normalized, _selectedDate);
    final isToday = ShieldDateUtils.isSameDate(normalized, DateTime.now());
    final isDisabled =
        !_isDateSelectable(normalized) ||
        normalized.isBefore(widget.firstDate) ||
        normalized.isAfter(widget.lastDate);

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
                final nextDate = ShieldDateUtils.dateOnly(normalized);
                if (widget.autoCloseOnSelect) {
                  Navigator.of(context).pop(nextDate);
                  return;
                }
                setState(() {
                  _selectedDate = nextDate;
                  _displayMonth = DateTime(nextDate.year, nextDate.month);
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
              final hasSelectableDate =
                  !_monthHasNoSelectableDates(monthDate, monthEnd);
              final isDisabled = monthEnd.isBefore(widget.firstDate) ||
                  monthDate.isAfter(widget.lastDate) ||
                  !hasSelectableDate;
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
    final lastMomentInTargetMonth = DateTime(target.year, target.month + 1, 0);
    return !(lastMomentInTargetMonth.isBefore(widget.firstDate) ||
        target.isAfter(widget.lastDate) ||
        _monthHasNoSelectableDates(target, lastMomentInTargetMonth));
  }

  bool _monthHasNoSelectableDates(DateTime start, DateTime end) {
    if (widget.selectableDayPredicate == null) {
      return false;
    }

    final effectiveStart = start.isBefore(widget.firstDate)
        ? widget.firstDate
        : start;
    final effectiveEnd = end.isAfter(widget.lastDate) ? widget.lastDate : end;
    for (var day = effectiveStart.day; day <= effectiveEnd.day; day++) {
      final current = DateTime(effectiveStart.year, effectiveStart.month, day);
      if (_isDateSelectable(current)) {
        return false;
      }
    }
    return true;
  }

  bool _isDateSelectable(DateTime date) {
    final predicate = widget.selectableDayPredicate;
    return predicate == null || predicate(date);
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
    final daysInMonth = DateTime(_displayMonth.year, _displayMonth.month + 1, 0)
        .day;
    final day = _selectedDate.year == _displayMonth.year &&
            _selectedDate.month == _displayMonth.month
        ? _selectedDate.day
        : 1;

    var candidate = _clampToBounds(
      DateTime(
        _displayMonth.year,
        _displayMonth.month,
        day.clamp(1, daysInMonth),
      ),
    );

    if (_isDateSelectable(candidate)) {
      return candidate;
    }

    for (var nextDay = candidate.day + 1; nextDay <= daysInMonth; nextDay++) {
      final nextCandidate = DateTime(
        _displayMonth.year,
        _displayMonth.month,
        nextDay,
      );
      if (_isDateSelectable(nextCandidate)) {
        return nextCandidate;
      }
    }

    for (var previousDay = candidate.day - 1; previousDay >= 1; previousDay--) {
      final previousCandidate = DateTime(
        _displayMonth.year,
        _displayMonth.month,
        previousDay,
      );
      if (_isDateSelectable(previousCandidate)) {
        return previousCandidate;
      }
    }

    return candidate;
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
