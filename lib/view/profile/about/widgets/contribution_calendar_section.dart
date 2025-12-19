import 'package:diohub/common/animations/fade_animation_widget.dart';
import 'package:diohub/common/charts/contribution_calendar_widget.dart';
import 'package:diohub/common/misc/nested_card_with_header.dart';
import 'package:diohub/common/misc/shimmer_widget.dart';
import 'package:diohub/common/utils/contribution_utils.dart';
import 'package:flutter/material.dart';

/// A section widget that displays the contribution calendar with statistics.
///
/// This widget combines the contribution calendar grid with summary statistics
/// and provides interactive features like day details on tap.
class ContributionCalendarSection extends StatelessWidget {
  const ContributionCalendarSection({
    required this.weeks,
    required this.totalContributions,
    this.colors,
    this.onDayTap,
    this.selectedYear,
    this.availableYears,
    this.onYearChanged,
    this.customFromDate,
    this.customToDate,
    this.useCustomRange = false,
    this.onCustomRangeChanged,
    this.createdAt,
    super.key,
  });

  /// List of weeks, each containing 7 days (Mon-Sun)
  final List<List<ContributionDay>> weeks;

  /// Total contributions in the displayed period
  final int totalContributions;

  /// Color scheme for contribution levels
  final List<Color>? colors;

  /// Callback when a day is tapped
  final void Function(ContributionDay day)? onDayTap;

  /// Currently selected year
  final int? selectedYear;

  /// Available years to select from
  final List<int>? availableYears;

  /// Callback when year selection changes
  final void Function(int year)? onYearChanged;

  /// Custom date range start
  final DateTime? customFromDate;

  /// Custom date range end
  final DateTime? customToDate;

  /// Whether custom date range is active
  final bool useCustomRange;

  /// Callback when custom date range changes
  final void Function(DateTime? from, DateTime? to)? onCustomRangeChanged;

  /// User's GitHub account creation date (for "Since joining GitHub" option)
  final DateTime? createdAt;

  /// Checks if the current custom range matches "Since joining GitHub"
  bool get _isSinceJoining {
    if (!useCustomRange || customFromDate == null || createdAt == null) {
      return false;
    }
    return customFromDate!.year == createdAt!.year &&
        customFromDate!.month == createdAt!.month &&
        customFromDate!.day == createdAt!.day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use colors from GitHub API (provided via colors parameter)
    // Colors come from contributionCalendar.colors in GraphQL response
    final defaultColors = colors;
    if (defaultColors == null || defaultColors.isEmpty) {
      // Should not happen - colors always come from GitHub API
      // Return error state if somehow missing
      return NestedCardWithHeader(
        header: Text(
          'Contribution Graph',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Unable to load contribution colors',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
      );
    }

    // Build header text based on selected year or custom range
    // Also determine if calendar should scroll (multi-year ranges)
    String headerText;
    bool shouldScroll = false;

    if (useCustomRange && customFromDate != null && customToDate != null) {
      final daysDiff = customToDate!.difference(customFromDate!).inDays;
      final yearsDiff = daysDiff / 365.25;

      // Enable scrolling for ranges > 1 year
      shouldScroll = yearsDiff > 1.0;

      if (_isSinceJoining) {
        headerText = '$totalContributions contributions since joining GitHub';
      } else {
        final fromStr = formatDateOnly(customFromDate!);
        final toStr = formatDateOnly(customToDate!);
        headerText =
            '$totalContributions contributions from $fromStr to $toStr';
      }
    } else if (selectedYear == null) {
      headerText = '$totalContributions contributions in the last year';
      // Last year is always single year, no scrolling needed
      shouldScroll = false;
    } else {
      headerText = '$totalContributions contributions in $selectedYear';
      // Single year selection, no scrolling needed
      shouldScroll = false;
    }

    return NestedCardWithHeader(
      header: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              headerText,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildDateRangeSelector(context),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contribution calendar with fade animation
            FadeAnimationSection(
              duration: const Duration(milliseconds: 300),
              child: ContributionCalendarWidget(
                weeks: weeks,
                colors: defaultColors,
                onDayTap: onDayTap,
                showMonthLabels: true,
                showDayLabels: false,
                cellSize: 11.0,
                cellSpacing: 2.0,
                shouldScroll: shouldScroll,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector(BuildContext context) {
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
              useCustomRange
                  ? (_isSinceJoining ? 'Since joining' : 'Custom')
                  : selectedYear?.toString() ?? 'Last Year',
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

/// Loading state for contribution calendar section
class ContributionCalendarSectionLoading extends StatelessWidget {
  const ContributionCalendarSectionLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return NestedCardWithHeader(
      header: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ShimmerWidget.container(
            height: 20,
            width: 250,
            borderRadius: BorderRadius.circular(4),
          ),
          ShimmerWidget.container(
            height: 28,
            width: 60,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar grid shimmer - match actual calendar structure
            ShimmerWidget.container(
              height: 120,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}
