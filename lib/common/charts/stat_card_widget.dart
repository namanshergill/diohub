import 'package:flutter/material.dart';

/// A reusable stat card widget for displaying metrics.
///
/// This widget can be used to display any metric with an icon, value, and label.
/// It's tappable and can navigate to detailed views.
///
/// Example usage:
/// ```dart
/// StatCardWidget(
///   icon: Octicons.git_commit,
///   value: '1,234',
///   label: 'Commits',
///   color: Colors.green,
///   onTap: () => navigateToCommits(),
/// )
/// ```
class StatCardWidget extends StatelessWidget {
  const StatCardWidget({
    required this.icon,
    required this.value,
    required this.label,
    this.color,
    this.onTap,
    this.iconSize = 14.0,
    this.valueStyle,
    this.labelStyle,
    this.padding,
    this.borderRadius = 8.0,
    super.key,
  });

  /// Icon to display
  final IconData icon;

  /// The value to display (e.g., "1,234" or "45%")
  final String value;

  /// Label text below the value
  final String label;

  /// Color for the icon and value
  final Color? color;

  /// Callback when the card is tapped
  final VoidCallback? onTap;

  /// Size of the icon
  final double iconSize;

  /// Style for the value text
  final TextStyle? valueStyle;

  /// Style for the label text
  final TextStyle? labelStyle;

  /// Padding around the content
  final EdgeInsets? padding;

  /// Border radius for the card
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final defaultColor = color ?? colorScheme.primary;
    final defaultValueStyle = valueStyle ??
        theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: defaultColor,
        );
    final defaultLabelStyle = labelStyle ??
        theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontSize: 11,
        );
    final defaultPadding =
        padding ?? const EdgeInsets.symmetric(vertical: 8, horizontal: 6);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: iconSize,
                color: defaultColor,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  value,
                  style: defaultValueStyle,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Flexible(
          child: Text(
            label,
            style: defaultLabelStyle,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );

    if (onTap == null) {
      // Non-tappable stat card
      return Padding(
        padding: defaultPadding,
        child: content,
      );
    }

    // Tappable stat card with visual feedback
    return Material(
      color: colorScheme.surfaceContainerHighest.withOpacity(0.2),
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: defaultPadding,
          child: content,
        ),
      ),
    );
  }
}

/// A grid of stat cards for displaying multiple metrics.
///
/// Example usage:
/// ```dart
/// StatCardGrid(
///   stats: [
///     StatCardData(
///       icon: Octicons.git_commit,
///       value: '1,234',
///       label: 'Commits',
///       color: Colors.green,
///     ),
///     StatCardData(
///       icon: Octicons.git_pull_request,
///       value: '456',
///       label: 'Pull Requests',
///       color: Colors.blue,
///     ),
///   ],
/// )
/// ```
class StatCardGrid extends StatelessWidget {
  const StatCardGrid({
    required this.stats,
    this.crossAxisCount = 4,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    this.padding,
    super.key,
  });

  /// List of stat data to display
  final List<StatCardData> stats;

  /// Number of columns in the grid
  final int crossAxisCount;

  /// Spacing between cards horizontally
  final double spacing;

  /// Spacing between cards vertically
  final double runSpacing;

  /// Padding around the grid
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: runSpacing,
          childAspectRatio: 1.0, // More vertical space for content
        ),
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final stat = stats[index];
          return StatCardWidget(
            icon: stat.icon,
            value: stat.value,
            label: stat.label,
            color: stat.color,
            onTap: stat.onTap,
          );
        },
      ),
    );
  }
}

/// Data class for stat card information
class StatCardData {
  const StatCardData({
    required this.icon,
    required this.value,
    required this.label,
    this.color,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? color;
  final VoidCallback? onTap;
}
