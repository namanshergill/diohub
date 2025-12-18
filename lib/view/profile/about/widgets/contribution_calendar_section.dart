import 'package:diohub/common/animations/fade_animation_widget.dart';
import 'package:diohub/common/charts/contribution_calendar_widget.dart';
import 'package:diohub/common/misc/nested_card_with_header.dart';
import 'package:diohub/common/misc/shimmer_widget.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use GitHub's default green colors
    final defaultColors = colors ??
        [
          Color(0xFFEBEDF0), // No contributions
          Color(0xFF9BE9A8), // Low
          Color(0xFF40C463), // Medium
          Color(0xFF30A14E), // High
          Color(0xFF216E39), // Very high
        ];

    // Build header text based on selected year or custom range
    String headerText;
    if (useCustomRange && customFromDate != null && customToDate != null) {
      final fromStr = '${customFromDate!.year}-${customFromDate!.month.toString().padLeft(2, '0')}-${customFromDate!.day.toString().padLeft(2, '0')}';
      final toStr = '${customToDate!.year}-${customToDate!.month.toString().padLeft(2, '0')}-${customToDate!.day.toString().padLeft(2, '0')}';
      final daysDiff = customToDate!.difference(customFromDate!).inDays;
      final yearsDiff = daysDiff / 365.25;
      
      // Note: GitHub API only returns ~53 weeks of calendar data (last year)
      // Statistics reflect the full range, but calendar visualization is limited
      if (yearsDiff > 1.1) {
        headerText = '$totalContributions contributions from $fromStr to $toStr\n(Calendar shows last year only)';
      } else {
        headerText = '$totalContributions contributions from $fromStr to $toStr';
      }
    } else if (selectedYear == null) {
      headerText = '$totalContributions contributions in the last year';
    } else {
      headerText = '$totalContributions contributions in $selectedYear';
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
        } else if (value == 'lastYear') {
          // Reset to last year - need to handle null case
          if (onYearChanged != null) {
            // Call with a sentinel value that we'll handle in the parent
            // Actually, we can't pass null to a non-nullable int parameter
            // So we'll use onCustomRangeChanged to clear it
            onCustomRangeChanged?.call(null, null);
          }
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
                  ? 'Custom'
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
    final initialFrom = customFromDate ?? now.subtract(const Duration(days: 365));
    final initialTo = customToDate ?? now;

    final pickedFrom = await showDatePicker(
      context: context,
      initialDate: initialFrom,
      firstDate: DateTime(2000),
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
