import 'package:contribution_heatmap/contribution_heatmap.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

/// A single day in the contribution calendar
class ContributionDay {
  const ContributionDay({
    required this.date,
    required this.count,
    this.color,
    this.level,
  });

  final DateTime date;
  final int count;
  final Color? color;
  final ContributionLevel? level;
}

/// Contribution level enum
enum ContributionLevel {
  none,
  firstQuartile,
  secondQuartile,
  thirdQuartile,
  fourthQuartile,
}

/// A reusable contribution calendar widget (GitHub-style heatmap).
///
/// This widget wraps the contribution_heatmap library for high-performance rendering.
/// It maintains the same API as before but uses an optimized library implementation.
///
/// Example usage:
/// ```dart
/// ContributionCalendarWidget(
///   weeks: contributionWeeks,
///   onDayTap: (day) => showDayDetails(day),
/// )
/// ```
class ContributionCalendarWidget extends StatefulWidget {
  const ContributionCalendarWidget({
    required this.weeks,
    this.colors,
    this.onDayTap,
    this.onDayLongPress,
    this.showMonthLabels = true,
    this.showDayLabels = true,
    this.cellSize = 11.0,
    this.cellSpacing = 2.0,
    this.monthLabelHeight = 20.0,
    this.dayLabelWidth = 20.0,
    this.legendColors,
    this.showLegend = true,
    this.legendLabels = const ['Less', 'More'],
    this.shouldScroll = false,
    super.key,
  });

  /// List of weeks, each containing days
  /// Each week should have 7 days (Mon-Sun)
  final List<List<ContributionDay>> weeks;

  /// Color scheme for contribution levels (ignored - using library's green scheme)
  /// Kept for API compatibility
  final List<Color>? colors;

  /// Callback when a day is tapped
  final void Function(ContributionDay day)? onDayTap;

  /// Callback when a day is long-pressed (not supported by library, ignored)
  final void Function(ContributionDay day)? onDayLongPress;

  /// Whether to show month labels above the calendar
  final bool showMonthLabels;

  /// Whether to show day labels (Mon, Tue, etc.) on the left
  final bool showDayLabels;

  /// Size of each calendar cell in pixels
  final double cellSize;

  /// Spacing between cells in pixels
  final double cellSpacing;

  /// Height reserved for month labels (ignored - library handles this)
  final double monthLabelHeight;

  /// Width reserved for day labels (ignored - library handles this)
  final double dayLabelWidth;

  /// Colors for the legend (ignored - using library's colors)
  final List<Color>? legendColors;

  /// Whether to show the legend (not supported by library, ignored)
  final bool showLegend;

  /// Labels for the legend (not supported by library, ignored)
  final List<String> legendLabels;

  /// Whether the calendar should be horizontally scrollable
  /// Set to true for multi-year ranges (>1 year)
  final bool shouldScroll;

  @override
  State<ContributionCalendarWidget> createState() =>
      _ContributionCalendarWidgetState();
}

class _ContributionCalendarWidgetState
    extends State<ContributionCalendarWidget> {
  // Cached conversion results - only recalculate when weeks change
  List<ContributionEntry>? _cachedEntries;
  DateTime? _cachedMinDate;
  DateTime? _cachedMaxDate;
  Map<String, ContributionDay>? _cachedDayMap; // For O(1) lookup in onCellTap
  List<List<ContributionDay>>? _cachedWeeks;
  double? _cachedCalendarWidth;

  void _updateCacheIfNeeded() {
    // Only recalculate if weeks have changed
    if (_cachedWeeks == widget.weeks && _cachedEntries != null) {
      return;
    }

    // Convert weeks format to entries format for the library
    final entries = <ContributionEntry>[];
    final dayMap = <String, ContributionDay>{};
    DateTime? minDate;
    DateTime? maxDate;

    for (final week in widget.weeks) {
      for (final day in week) {
        entries.add(ContributionEntry(day.date, day.count));

        // Create a key for O(1) lookup: "YYYY-MM-DD"
        final dateKey = '${day.date.year}-${day.date.month}-${day.date.day}';
        dayMap[dateKey] = day;

        if (minDate == null || day.date.isBefore(minDate)) {
          minDate = day.date;
        }
        if (maxDate == null || day.date.isAfter(maxDate)) {
          maxDate = day.date;
        }
      }
    }

    _cachedEntries = entries;
    _cachedMinDate = minDate;
    _cachedMaxDate = maxDate;
    _cachedDayMap = dayMap;
    _cachedWeeks = widget.weeks;
    _cachedCalendarWidth =
        widget.weeks.length * (widget.cellSize + widget.cellSpacing);
  }

  @override
  Widget build(BuildContext context) {
    // Update cache if needed (only recalculates when weeks change)
    _updateCacheIfNeeded();

    // Build the heatmap widget
    final heatmap = ContributionHeatmap(
      entries: _cachedEntries!,
      minDate: _cachedMinDate,
      maxDate: _cachedMaxDate,
      cellSize: widget.cellSize,
      cellSpacing: widget.cellSpacing,
      // splittedMonthView: true,
      showCellDate: true,
      cellRadius: 2,
      showMonthLabels: widget.showMonthLabels,
      weekdayLabel: WeekdayLabel.none,
      heatmapColor: HeatmapColor.green, // GitHub-style green
      onCellTap: widget.onDayTap != null
          ? (date, value) {
              // O(1) lookup using cached map
              final dateKey = '${date.year}-${date.month}-${date.day}';
              final day = _cachedDayMap![dateKey];
              if (day != null) {
                widget.onDayTap!(day);
              }
            }
          : null,
    );

    // Use cached calendar width
    final calendarWidth = _cachedCalendarWidth!;

    // Wrap heatmap in scrollable container if needed
    // Use LayoutBuilder to handle overflow on small screens
    final heatmapWidget = LayoutBuilder(
      builder: (context, constraints) {
        // If shouldScroll is true, always make it scrollable
        if (widget.shouldScroll) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: heatmap,
          );
        }

        // If calendar is wider than available space, make it scrollable
        if (calendarWidth > constraints.maxWidth) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: heatmap,
          );
        }

        // Fits on screen - use ConstrainedBox to ensure it respects max width
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: constraints.maxWidth,
          ),
          child: heatmap,
        );
      },
    );

    // Build legend if enabled
    if (widget.showLegend) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heatmapWidget,
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: _buildLegend(context),
          ),
        ],
      );
    }

    return heatmapWidget;
  }

  // Cached legend widget - only rebuilds when cellSize or legendLabels change
  Widget? _cachedLegend;
  double? _cachedLegendCellSize;
  List<String>? _cachedLegendLabels;

  /// Build the legend showing color gradient with "Less" and "More" labels
  Widget _buildLegend(BuildContext context) {
    // Cache legend widget - only rebuild when cellSize or legendLabels change
    if (_cachedLegend == null ||
        _cachedLegendCellSize != widget.cellSize ||
        _cachedLegendLabels != widget.legendLabels) {
      final theme = Theme.of(context);
      final textStyle = theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontSize: 10,
      );

      // Get the green color palette (matching HeatmapColor.green)
      // Using a subset of colors for the legend (0%, 25%, 50%, 75%, 100%)
      final legendColors = [
        const Color(0xFFE8F5E8), // 0% - no contributions
        const Color(0xFFB0D1B1), // ~30% - low
        const Color(0xFF78AD7B), // ~60% - medium
        const Color(0xFF539556), // ~80% - high
        const Color(0xFF2E7D32), // 100% - very high
      ];

      // Pre-build color containers list
      final colorContainers = legendColors.map((color) {
        return Container(
          width: widget.cellSize,
          height: widget.cellSize,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }).toList();

      _cachedLegend = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.legendLabels.isNotEmpty)
            Text(
              widget.legendLabels.first,
              style: textStyle,
            ),
          const SizedBox(width: 4),
          ...colorContainers,
          if (widget.legendLabels.length > 1) ...[
            const SizedBox(width: 4),
            Text(
              widget.legendLabels.last,
              style: textStyle,
            ),
          ],
        ],
      );
      _cachedLegendCellSize = widget.cellSize;
      _cachedLegendLabels = widget.legendLabels;
    }

    return _cachedLegend!;
  }
}
