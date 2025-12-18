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

    // Build header text based on selected year
    final currentYear = DateTime.now().year;
    final headerText = selectedYear == null
        ? '$totalContributions contributions in the last year'
        : selectedYear == currentYear
            ? '$totalContributions contributions in $selectedYear'
            : '$totalContributions contributions in $selectedYear';

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
          if (availableYears != null && availableYears!.isNotEmpty)
            _buildYearSelector(context),
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

  Widget _buildYearSelector(BuildContext context) {
    if (availableYears == null || availableYears!.isEmpty) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<int>(
      initialValue: selectedYear,
      onSelected: onYearChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedYear?.toString() ?? 'Year',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => availableYears!
          .map((year) => PopupMenuItem(
                value: year,
                child: Text(year.toString()),
              ))
          .toList(),
    );
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
