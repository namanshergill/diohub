import 'package:diohub/common/charts/contribution_calendar_widget.dart';
import 'package:flutter/material.dart';

/// Helper functions to convert GraphQL contribution data to widget formats

/// Converts GraphQL contribution calendar weeks to ContributionDay format
///
/// This is a generic helper - you'll need to adapt it to your actual GraphQL types
/// once the contributionsCollection query is added.
List<List<ContributionDay>> convertContributionWeeks(
  List<dynamic> weeks,
) {
  // TODO: Implement once GraphQL types are available
  // This is a placeholder - adapt to your actual GraphQL structure
  return [];

  // Example implementation using functional approach (uncomment and adapt when types are available):
  // return weeks
  //     .whereType<WeekType>() // Filter out nulls and ensure correct type
  //     .map((week) => week.contributionDays
  //         .whereType<DayType>() // Filter out null days
  //         .map((day) => ContributionDay(
  //               date: DateTime.parse(day.date.toString()),
  //               count: day.contributionCount,
  //               color: day.color != null ? _parseColor(day.color!) : null,
  //               level: _convertContributionLevel(day.contributionLevel),
  //             ))
  //         .toList())
  //     .toList();
}

/// Parses hex color string to Color
///
/// Example: "#9be9a8" -> Color(0xFF9BE9A8)
Color _parseColor(String hexColor) {
  // Remove # if present and ensure uppercase
  final hex = hexColor.replaceFirst('#', '').toUpperCase();
  // Parse as int with alpha channel (FF = fully opaque)
  final colorValue = int.parse('FF$hex', radix: 16);
  return Color(colorValue);
}

/// Converts contribution level enum from GraphQL to ContributionLevel
ContributionLevel _convertContributionLevel(String level) {
  switch (level) {
    case 'NONE':
      return ContributionLevel.none;
    case 'FIRST_QUARTILE':
      return ContributionLevel.firstQuartile;
    case 'SECOND_QUARTILE':
      return ContributionLevel.secondQuartile;
    case 'THIRD_QUARTILE':
      return ContributionLevel.thirdQuartile;
    case 'FOURTH_QUARTILE':
      return ContributionLevel.fourthQuartile;
    default:
      return ContributionLevel.none;
  }
}

/// Extracts month labels from contribution weeks
///
/// Uses functional programming to avoid nested loops.
/// This is a generic helper - you'll need to adapt it to your actual GraphQL types
List<DateTime> extractMonthsFromWeeks(
  List<dynamic> weeks,
) {
  // TODO: Implement once GraphQL types are available
  // This is a placeholder - adapt to your actual GraphQL structure
  return [];

  // Example implementation using functional approach (uncomment and adapt when types are available):
  // return weeks
  //     .whereType<WeekType>() // Filter out nulls
  //     .expand((week) => week.contributionDays) // Flatten weeks into days
  //     .whereType<DayType>() // Filter out null days
  //     .map((day) => DateTime.parse(day.date.toString()))
  //     .map((date) => DateTime(date.year, date.month, 1)) // Extract month
  //     .toSet() // Remove duplicates
  //     .toList()
  //   ..sort(); // Sort chronologically
}
