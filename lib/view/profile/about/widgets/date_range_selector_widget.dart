import 'package:diohub/common/utils/contribution_utils.dart';
import 'package:flutter/material.dart';

/// A reusable widget for selecting contribution date ranges
/// 
/// Supports:
/// - Last year (default)
/// - Specific years
/// - Since joining GitHub
/// - Custom date range
class DateRangeSelectorWidget extends StatelessWidget {
  const DateRangeSelectorWidget({
    required this.selectedYear,
    required this.availableYears,
    required this.customFromDate,
    required this.customToDate,
    required this.useCustomRange,
    required this.createdAt,
    required this.onYearChanged,
    required this.onCustomRangeChanged,
    super.key,
  });

  /// Currently selected year (null = last year)
  final int? selectedYear;

  /// Available years to select from
  final List<int>? availableYears;

  /// Custom date range start
  final DateTime? customFromDate;

  /// Custom date range end
  final DateTime? customToDate;

  /// Whether custom date range is active
  final bool useCustomRange;

  /// User's GitHub account creation date (for "Since joining GitHub" option)
  final DateTime? createdAt;

  /// Callback when year selection changes
  final void Function(int year)? onYearChanged;

  /// Callback when custom date range changes
  final void Function(DateTime? from, DateTime? to)? onCustomRangeChanged;

  /// Checks if the current custom range matches "Since joining GitHub"
  bool get _isSinceJoining {
    if (!useCustomRange || customFromDate == null || createdAt == null) {
      return false;
    }
    return customFromDate!.year == createdAt!.year &&
        customFromDate!.month == createdAt!.month &&
        customFromDate!.day == createdAt!.day;
  }

  /// Gets the display text for the current selection
  String get displayText {
    if (useCustomRange) {
      return _isSinceJoining ? 'Since joining' : 'Custom';
    }
    return selectedYear?.toString() ?? 'Last Year';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'custom') {
          _showCustomDateRangePicker(context);
        } else if (value == 'sinceJoining') {
          // Set range from account creation to now
          if (createdAt != null) {
            final now = DateTime.now();
            onCustomRangeChanged?.call(createdAt, now);
          }
        } else if (value == 'lastYear') {
          // Reset to last year
          onCustomRangeChanged?.call(null, null);
        } else if (value.startsWith('year:')) {
          final year = int.parse(value.split(':')[1]);
          onYearChanged?.call(year);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              useCustomRange ? Icons.date_range : Icons.calendar_today,
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              displayText,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[
          const PopupMenuItem(
            value: 'lastYear',
            child: Text('Last Year'),
          ),
          if (availableYears != null && availableYears!.isNotEmpty) ...[
            const PopupMenuDivider(),
            ...availableYears!.map((year) => PopupMenuItem(
                  value: 'year:$year',
                  child: Text(year.toString()),
                )),
          ],
          const PopupMenuDivider(),
          if (createdAt != null)
            const PopupMenuItem(
              value: 'sinceJoining',
              child: Row(
                children: [
                  Icon(Icons.cake, size: 16),
                  SizedBox(width: 8),
                  Text('Since joining GitHub'),
                ],
              ),
            ),
          const PopupMenuItem(
            value: 'custom',
            child: Row(
              children: [
                Icon(Icons.date_range, size: 16),
                SizedBox(width: 8),
                Text('Custom Range'),
              ],
            ),
          ),
        ];
        return items;
      },
    );
  }

  Future<void> _showCustomDateRangePicker(BuildContext context) async {
    final now = DateTime.now();
    final initialFrom =
        customFromDate ?? now.subtract(const Duration(days: 365));
    final initialTo = customToDate ?? now;

    // Use createdAt as earliest date, or default to year 2000 if not available
    final earliestDate = createdAt ?? DateTime(2000);

    final pickedFrom = await showDatePicker(
      context: context,
      initialDate: initialFrom,
      firstDate: earliestDate,
      lastDate: now,
      helpText: 'Select start date',
    );

    if (pickedFrom == null) return;

    final pickedTo = await showDatePicker(
      context: context,
      initialDate: pickedFrom.isAfter(initialTo) ? pickedFrom : initialTo,
      firstDate: pickedFrom,
      lastDate: now,
      helpText: 'Select end date',
    );

    if (pickedTo != null) {
      onCustomRangeChanged?.call(pickedFrom, pickedTo);
    }
  }
}

