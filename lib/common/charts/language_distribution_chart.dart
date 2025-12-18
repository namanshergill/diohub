import 'package:flutter/material.dart';

/// Data for a language in the distribution chart
class LanguageData {
  const LanguageData({
    required this.name,
    required this.percentage,
    this.color,
    this.size,
  });

  final String name;
  final double percentage; // 0.0 to 100.0
  final Color? color;
  final int? size; // Optional: bytes or lines of code
}

/// A reusable horizontal bar chart for language distribution.
///
/// This widget displays languages with their usage percentages
/// in a horizontal bar chart format.
///
/// Example usage:
/// ```dart
/// LanguageDistributionChart(
///   languages: [
///     LanguageData(name: 'JavaScript', percentage: 45.0, color: Colors.yellow),
///     LanguageData(name: 'TypeScript', percentage: 30.0, color: Colors.blue),
///     LanguageData(name: 'Python', percentage: 15.0, color: Colors.green),
///   ],
///   maxLanguages: 5,
/// )
/// ```
class LanguageDistributionChart extends StatelessWidget {
  const LanguageDistributionChart({
    required this.languages,
    this.maxLanguages = 5,
    this.barHeight = 24.0,
    this.barSpacing = 8.0,
    this.showPercentage = true,
    this.showSize = false,
    this.labelStyle,
    this.percentageStyle,
    this.onLanguageTap,
    super.key,
  });

  /// List of languages with their percentages
  final List<LanguageData> languages;

  /// Maximum number of languages to display
  final int maxLanguages;

  /// Height of each bar
  final double barHeight;

  /// Spacing between bars
  final double barSpacing;

  /// Whether to show percentage text
  final bool showPercentage;

  /// Whether to show size (bytes/lines) if available
  final bool showSize;

  /// Style for language labels
  final TextStyle? labelStyle;

  /// Style for percentage text
  final TextStyle? percentageStyle;

  /// Callback when a language bar is tapped
  final void Function(LanguageData language)? onLanguageTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (languages.isEmpty) {
      return Center(
        child: Text(
          'No language data available',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // Sort by percentage (descending) and take top N
    final sortedLanguages = List<LanguageData>.from(languages)
      ..sort((a, b) => b.percentage.compareTo(a.percentage));
    final displayLanguages = sortedLanguages.take(maxLanguages).toList();

    final defaultLabelStyle = labelStyle ??
        theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurface,
        ) ??
        TextStyle(color: colorScheme.onSurface);
    final defaultPercentageStyle = percentageStyle ??
        theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ) ??
        TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: displayLanguages.map((language) {
        return Padding(
          padding: EdgeInsets.only(bottom: barSpacing),
          child: _buildLanguageBar(
            context,
            language,
            defaultLabelStyle,
            defaultPercentageStyle,
            colorScheme,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLanguageBar(
    BuildContext context,
    LanguageData language,
    TextStyle labelStyle,
    TextStyle percentageStyle,
    ColorScheme colorScheme,
  ) {
    // Default color if not provided (use a hash-based color)
    final color =
        language.color ?? _getColorForLanguage(language.name, colorScheme);

    final bar = GestureDetector(
      onTap: onLanguageTap != null ? () => onLanguageTap!(language) : null,
      child: Container(
        height: barHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          children: [
            // Background bar
            FractionallySizedBox(
              widthFactor: language.percentage / 100.0,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // Label and percentage overlay
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Language name
                  Flexible(
                    child: Text(
                      language.name,
                      style: labelStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Percentage and size
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showSize && language.size != null) ...[
                        Text(
                          _formatSize(language.size!),
                          style: percentageStyle,
                        ),
                        const SizedBox(width: 4),
                        Text('•', style: percentageStyle),
                        const SizedBox(width: 4),
                      ],
                      if (showPercentage)
                        Text(
                          '${language.percentage.toStringAsFixed(1)}%',
                          style: percentageStyle,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return bar;
  }

  Color _getColorForLanguage(String languageName, ColorScheme colorScheme) {
    // Generate a consistent color based on language name
    final hash = languageName.hashCode;
    final hue = (hash.abs() % 360).toDouble();
    return HSVColor.fromAHSV(1.0, hue, 0.7, 0.8).toColor();
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
