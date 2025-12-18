import 'package:diohub/common/charts/contribution_calendar_widget.dart';
import 'package:diohub/common/utils/contribution_utils.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_info.data.gql.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_contributions.data.gql.dart';
import 'package:diohub/view/profile/about/widgets/activity_overview_section.dart';
import 'package:flutter/material.dart';

/// Converts GraphQL contribution data to widget-friendly formats.
///
/// This class provides type-safe conversion methods for contribution data
/// from GraphQL types to widget data structures.
class ContributionDataConverter {
  /// Converts GraphQL contribution calendar weeks to ContributionDay format
  static List<List<ContributionDay>> convertWeeks(
    List<GuserContributionsData_user_contributionsCollection_contributionCalendar_weeks?>?
        weeks,
  ) {
    if (weeks == null || weeks.isEmpty) {
      return [];
    }

    return weeks
        .whereType<
            GuserContributionsData_user_contributionsCollection_contributionCalendar_weeks>()
        .map((week) => week.contributionDays
            .whereType<
                GuserContributionsData_user_contributionsCollection_contributionCalendar_weeks_contributionDays>()
            .map((day) => ContributionDay(
                  date: DateTime.parse(day.date.toString()),
                  count: day.contributionCount,
                  // Use GitHub colors from API
                  color: parseContributionColor(day.color),
                  level: convertContributionLevel(day.contributionLevel),
                ))
            .toList())
        .toList();
  }

  /// Converts GraphQL contribution calendar colors to Color list
  static List<Color> convertColors(
    List<String>? colors,
  ) {
    if (colors == null || colors.isEmpty) {
      // Default GitHub colors
      return [
        Color(0xFFEBEDF0),
        Color(0xFF9BE9A8),
        Color(0xFF40C463),
        Color(0xFF30A14E),
        Color(0xFF216E39),
      ];
    }

    return parseContributionColors(colors);
  }

  /// Extracts months from contribution weeks for labels
  static List<DateTime> extractMonths(
    List<GuserContributionsData_user_contributionsCollection_contributionCalendar_weeks?>?
        weeks,
  ) {
    if (weeks == null || weeks.isEmpty) {
      return [];
    }

    return weeks
        .whereType<
            GuserContributionsData_user_contributionsCollection_contributionCalendar_weeks>()
        .expand((week) => week.contributionDays)
        .whereType<
            GuserContributionsData_user_contributionsCollection_contributionCalendar_weeks_contributionDays>()
        .map((day) => DateTime.parse(day.date.toString()))
        .map((date) => DateTime(date.year, date.month, 1))
        .toSet()
        .toList()
      ..sort();
  }

  /// Converts contributed repositories from GraphQL
  /// Uses repositoryFields fragment, so repository implements GrepositoryFields
  static List<ContributedRepository> convertRepositories(
    List<GuserContributionsData_user_contributionsCollection_commitContributionsByRepository?>?
        repositories,
  ) {
    if (repositories == null || repositories.isEmpty) {
      return [];
    }

    return repositories
        .whereType<
            GuserContributionsData_user_contributionsCollection_commitContributionsByRepository>()
        .map((repo) {
          final repository = repo.repository;
          // Cast to GrepositoryFields to access fragment fields
          final repoFields = repository as GrepositoryFields;

          // Owner has a direct login property (not a union type)
          final owner = repository.owner.login;

          // Get primary language - try primaryLanguage first (added separately in query)
          String? language;
          String? languageColor;

          // Access primaryLanguage directly from repository (added separately, not in fragment)
          final primaryLang = repository.primaryLanguage;
          if (primaryLang != null) {
            language = primaryLang.name;
            languageColor = primaryLang.color;
          }

          // Fallback to languages from fragment if primaryLanguage not available
          if (language == null) {
            final edges = repoFields.languages?.edges;
            if (edges != null) {
              for (final edge in edges) {
                if (edge != null) {
                  language = edge.node.name;
                  break;
                }
              }
            }
          }

          return ContributedRepository(
            name: repoFields.name,
            owner: owner,
            url: repoFields.url.toString(),
            contributionCount: repo.contributions.totalCount,
            description: repoFields.description,
            language: language,
            languageColor: languageColor,
            stargazersCount: repoFields.stargazerCount,
            isPrivate: repoFields.isPrivate,
            isFork: repoFields.isFork,
          );
        })
        .whereType<ContributedRepository>()
        .toList();
  }

}
