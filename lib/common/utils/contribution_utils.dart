import 'package:diohub/common/charts/contribution_calendar_widget.dart';
import 'package:diohub/graphql/__generated__/schema.schema.gql.dart';
import 'package:flutter/material.dart';

/// Shared utility functions for contribution data processing

/// Formats a DateTime to YYYY-MM-DD string format
String formatDateOnly(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// Parses hex color string to Color
///
/// Example: "#9be9a8" -> Color(0xFF9BE9A8)
/// Returns Colors.grey if parsing fails
Color parseContributionColor(String hexColor) {
  try {
    // Remove # if present and ensure uppercase
    final hex = hexColor.replaceFirst('#', '').toUpperCase();
    // Parse as int with alpha channel (FF = fully opaque)
    final colorValue = int.parse('FF$hex', radix: 16);
    return Color(colorValue);
  } catch (e) {
    return Colors.grey;
  }
}

/// Parses list of hex color strings to Color list
List<Color> parseContributionColors(List<String> colors) {
  if (colors.isEmpty) {
    // Default GitHub colors
    return [
      Color(0xFFEBEDF0),
      Color(0xFF9BE9A8),
      Color(0xFF40C463),
      Color(0xFF30A14E),
      Color(0xFF216E39),
    ];
  }
  return colors.map(parseContributionColor).toList();
}

/// Converts GraphQL contribution level to ContributionLevel enum
ContributionLevel convertContributionLevel(GContributionLevel level) {
  switch (level) {
    case GContributionLevel.NONE:
      return ContributionLevel.none;
    case GContributionLevel.FIRST_QUARTILE:
      return ContributionLevel.firstQuartile;
    case GContributionLevel.SECOND_QUARTILE:
      return ContributionLevel.secondQuartile;
    case GContributionLevel.THIRD_QUARTILE:
      return ContributionLevel.thirdQuartile;
    case GContributionLevel.FOURTH_QUARTILE:
      return ContributionLevel.fourthQuartile;
    default:
      return ContributionLevel.none;
  }
}

