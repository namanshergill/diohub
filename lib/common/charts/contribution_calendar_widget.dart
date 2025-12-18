import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
/// This widget displays a grid of days showing contribution activity.
/// It's generic and can be used for any time-based activity visualization.
///
/// Example usage:
/// ```dart
/// ContributionCalendarWidget(
///   days: contributionDays,
///   colors: ['#ebedf0', '#9be9a8', '#40c463', '#30a14e', '#216e39'],
///   onDayTap: (day) => showDayDetails(day),
/// )
/// ```
class ContributionCalendarWidget extends StatelessWidget {
  const ContributionCalendarWidget({
    required this.weeks,
    this.colors,
    this.onDayTap,
    this.onDayLongPress,
    this.showMonthLabels = true,
    this.showDayLabels = false,
    this.cellSize = 11.0,
    this.cellSpacing = 2.0,
    this.monthLabelHeight = 20.0,
    this.dayLabelWidth = 20.0,
    this.legendColors,
    this.showLegend = true,
    this.legendLabels = const ['Less', 'More'],
    super.key,
  });

  /// List of weeks, each containing days
  /// Each week should have 7 days (Mon-Sun)
  final List<List<ContributionDay>> weeks;

  /// Color scheme for contribution levels
  /// Should be ordered from lowest to highest activity
  final List<Color>? colors;

  /// Callback when a day is tapped
  final void Function(ContributionDay day)? onDayTap;

  /// Callback when a day is long-pressed
  final void Function(ContributionDay day)? onDayLongPress;

  /// Whether to show month labels above the calendar
  final bool showMonthLabels;

  /// Whether to show day labels (Mon, Tue, etc.) on the left
  final bool showDayLabels;

  /// Size of each calendar cell in pixels
  final double cellSize;

  /// Spacing between cells in pixels
  final double cellSpacing;

  /// Height reserved for month labels
  final double monthLabelHeight;

  /// Width reserved for day labels
  final double dayLabelWidth;

  /// Colors for the legend (defaults to colors if not provided)
  final List<Color>? legendColors;

  /// Whether to show the legend
  final bool showLegend;

  /// Labels for the legend (e.g., ['Less', 'More'])
  final List<String> legendLabels;

  @override
  Widget build(BuildContext context) {
    debugPrint('[ContributionCalendarWidget] Building with ${weeks.length} weeks');
    if (weeks.isNotEmpty) {
      final totalDays = weeks.fold<int>(0, (sum, week) => sum + week.length);
      debugPrint('[ContributionCalendarWidget] Total days: $totalDays (${weeks.length} weeks × ~7 days)');
      debugPrint('[ContributionCalendarWidget] First week: ${weeks.first.length} days, first day: ${weeks.first.first.date}');
      debugPrint('[ContributionCalendarWidget] Last week: ${weeks.last.length} days, first day: ${weeks.last.first.date}');
    }
    
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Default colors (GitHub-style green)
    final defaultColors = colors ??
        [
          Color(0xFFEBEDF0), // No contributions
          Color(0xFF9BE9A8), // Low
          Color(0xFF40C463), // Medium
          Color(0xFF30A14E), // High
          Color(0xFF216E39), // Very high
        ];

    // Extract months from weeks for labels
    final months = _extractMonths(weeks);

    // Calculate calendar grid width for proper month label positioning
    final calendarWidth = weeks.length * (cellSize + cellSpacing);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Calendar grid with month labels and scrollable content
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day labels (Mon, Tue, etc.) - fixed, doesn't scroll
            if (showDayLabels)
              SizedBox(
                width: dayLabelWidth,
                child: _buildDayLabels(context),
              ),

            // Scrollable calendar with month labels
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month labels - scrolls with calendar
                    if (showMonthLabels && months.isNotEmpty)
                      SizedBox(
                        height: monthLabelHeight,
                        width: calendarWidth,
                        child: _buildMonthLabels(context, months, weeks),
                      ),

                    // Calendar grid
                    SizedBox(
                      width: calendarWidth,
                      child: _buildCalendarGrid(
                        context,
                        defaultColors,
                        colorScheme,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Legend
        if (showLegend)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: _buildLegend(context, defaultColors, colorScheme),
          ),
      ],
    );
  }

  Widget _buildMonthLabels(
    BuildContext context,
    List<DateTime> months,
    List<List<ContributionDay>> weeks,
  ) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontSize: 10,
    );

    // Calculate month positions based on actual week positions
    // Each week takes (cellSize + cellSpacing) width
    final weekWidth = cellSize + cellSpacing;
    final monthPositions = <DateTime, double>{};
    
    // Track which month each week belongs to
    for (int weekIndex = 0; weekIndex < weeks.length; weekIndex++) {
      final week = weeks[weekIndex];
      if (week.isEmpty) continue;
      
      // Get the first day of the week to determine the month
      final firstDay = week.first.date;
      final month = DateTime(firstDay.year, firstDay.month, 1);
      
      // Calculate the x position of this week
      final weekX = weekIndex * weekWidth;
      
      // Only set position if this is the first week of the month or if we haven't set it yet
      if (!monthPositions.containsKey(month) || 
          weekX < monthPositions[month]!) {
        monthPositions[month] = weekX;
      }
    }

    // Build positioned month labels
    return Stack(
      children: monthPositions.entries.map((entry) {
        final month = entry.key;
        final x = entry.value;
        
        return Positioned(
          left: x,
          child: Text(
            DateFormat('MMM').format(month),
            style: textStyle,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDayLabels(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontSize: 10,
    );

    final dayNames = ['Mon', 'Wed', 'Fri'];

    return Column(
      children: List.generate(7, (index) {
        if (index % 2 == 0 && index < dayNames.length) {
          return SizedBox(
            height: cellSize + cellSpacing,
            child: Center(
              child: Text(
                dayNames[index ~/ 2],
                style: textStyle,
              ),
            ),
          );
        }
        return SizedBox(height: cellSize + cellSpacing);
      }),
    );
  }

  Widget _buildCalendarGrid(
    BuildContext context,
    List<Color> colors,
    ColorScheme colorScheme,
  ) {
    return Wrap(
      spacing: cellSpacing,
      runSpacing: cellSpacing,
      children: weeks.expand((week) {
        return week.map((day) {
          return _buildDayCell(context, day, colors, colorScheme);
        });
      }).toList(),
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    ContributionDay day,
    List<Color> colors,
    ColorScheme colorScheme,
  ) {
    // Determine color based on count
    final color = day.color ?? _getColorForCount(day.count, colors);

    return Tooltip(
      message: _getTooltipMessage(day),
      waitDuration: const Duration(milliseconds: 500),
      child: _AnimatedDayCell(
        day: day,
        color: color,
        cellSize: cellSize,
        onTap: onDayTap != null ? () => onDayTap!(day) : null,
        onLongPress: onDayLongPress != null ? () => onDayLongPress!(day) : null,
      ),
    );
  }

  Widget _buildLegend(
    BuildContext context,
    List<Color> colors,
    ColorScheme colorScheme,
  ) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontSize: 10,
    );

    final legendColorsToShow = legendColors ?? colors;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (legendLabels.isNotEmpty)
          Text(
            legendLabels.first,
            style: textStyle,
          ),
        const SizedBox(width: 4),
        ...legendColorsToShow.map((color) {
          return Container(
            width: cellSize,
            height: cellSize,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
        if (legendLabels.length > 1) ...[
          const SizedBox(width: 4),
          Text(
            legendLabels.last,
            style: textStyle,
          ),
        ],
      ],
    );
  }

  Color _getColorForCount(int count, List<Color> colors) {
    if (count == 0) return colors[0];
    if (count == 1) return colors[1];
    if (count <= 3) return colors[2];
    if (count <= 6) return colors[3];
    return colors[4];
  }

  String _getTooltipMessage(ContributionDay day) {
    final dateStr = DateFormat('MMM d, yyyy').format(day.date);
    if (day.count == 0) {
      return 'No contributions on $dateStr';
    } else if (day.count == 1) {
      return '1 contribution on $dateStr';
    } else {
      return '${day.count} contributions on $dateStr';
    }
  }

  List<DateTime> _extractMonths(List<List<ContributionDay>> weeks) {
    final months = <DateTime>{};
    for (final week in weeks) {
      for (final day in week) {
        final month = DateTime(day.date.year, day.date.month, 1);
        months.add(month);
      }
    }
    return months.toList()..sort();
  }
}

/// Animated day cell with scale and color transitions
class _AnimatedDayCell extends StatefulWidget {
  const _AnimatedDayCell({
    required this.day,
    required this.color,
    required this.cellSize,
    this.onTap,
    this.onLongPress,
  });

  final ContributionDay day;
  final Color color;
  final double cellSize;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  State<_AnimatedDayCell> createState() => _AnimatedDayCellState();
}

class _AnimatedDayCellState extends State<_AnimatedDayCell>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onLongPress: widget.onLongPress,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: widget.cellSize,
          height: widget.cellSize,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.color.withOpacity(0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(2),
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              onHover: (hovering) {
                setState(() {
                  _isHovered = hovering;
                });
              },
              child: Container(),
            ),
          ),
        ),
      ),
    );
  }
}
