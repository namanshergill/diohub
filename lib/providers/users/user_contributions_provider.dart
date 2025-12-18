import 'package:diohub/app/global.dart';
import 'package:diohub/common/charts/contribution_calendar_widget.dart';
import 'package:diohub/graphql/__generated__/schema.schema.gql.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_contributions.data.gql.dart';
import 'package:diohub/services/users/user_info_service.dart';
import 'package:diohub/view/profile/about/widgets/activity_overview_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Combined contribution data from multiple years.
/// Reuses existing types (ContributionDay, ContributedRepository) to avoid duplication.
class CombinedContributionsData {
  const CombinedContributionsData({
    required this.weeks,
    required this.colors,
    required this.totalContributions,
    required this.totalCommitContributions,
    required this.totalPullRequestContributions,
    required this.totalIssueContributions,
    required this.totalPullRequestReviewContributions,
    required this.commitContributionsByRepository,
    required this.contributionYears,
  });

  /// Combined weeks from all years (List<List<ContributionDay>>)
  final List<List<ContributionDay>> weeks;

  /// Color scheme for contribution levels
  final List<Color> colors;

  /// Total contributions across all years
  final int totalContributions;

  /// Total commit contributions
  final int totalCommitContributions;

  /// Total pull request contributions
  final int totalPullRequestContributions;

  /// Total issue contributions
  final int totalIssueContributions;

  /// Total pull request review contributions
  final int totalPullRequestReviewContributions;

  /// Combined repositories with summed contribution counts
  final List<ContributedRepository> commitContributionsByRepository;

  /// All available contribution years
  final List<int> contributionYears;
}

/// Provider for fetching user contributions with customizable date ranges.
/// Key format options:
/// - "userName:lastYear" - last year from today
/// - "userName:year:year" - specific year (e.g., "userName:2023:2023")
/// - "userName:custom:fromDate:toDate" - custom date range (ISO format)
///
/// For single-year ranges, returns GuserContributionsData_user directly.
/// For multi-year ranges, fetches each year in parallel and returns CombinedContributionsData.
/// This ensures stable keys that only change when the date range changes.
final userContributionsProvider =
    FutureProvider.autoDispose.family<Object, String>((ref, key) async {
  try {
    // Parse key
    final parts = key.split(':');
    final userName = parts[0];

    DateTime? from;
    DateTime? to;

    if (parts.length == 2 && parts[1] == 'lastYear') {
      // Default: last year from today
      final now = DateTime.now();
      to = DateTime(now.year, now.month, now.day);
      from = DateTime(to.year - 1, to.month, to.day);
    } else if (parts.length == 3) {
      // Specific year range
      final fromYear = int.parse(parts[1]);
      final toYear = int.parse(parts[2]);
      from = DateTime(fromYear, 1, 1);
      to = DateTime(toYear, 12, 31);
    } else if (parts.length == 4 && parts[1] == 'custom') {
      // Custom date range: "userName:custom:fromDate:toDate" (format: YYYY-MM-DD)
      from = DateTime.parse(parts[2]);
      to = DateTime.parse(parts[3]);
    } else {
      throw Exception('Invalid provider key format: $key');
    }

  // All code paths above set from and to, so they're guaranteed to be non-null
  final fromDate = from;
  final toDate = to;

  // Check if this is a multi-year range
  final yearsDiff = (toDate.year - fromDate.year) + 1;

  if (yearsDiff <= 1) {
    // Single year - return GraphQL type directly
    return UserInfoService.getUserContributions(
      userName,
      from: fromDate,
      to: toDate,
    );
  }

  // Multi-year range: fetch each year in parallel
  final yearQueries = <Future<GuserContributionsData_user>>[];

  for (int year = fromDate.year; year <= toDate.year; year++) {
    final yearStart = year == fromDate.year
        ? DateTime(year, fromDate.month, fromDate.day)
        : DateTime(year, 1, 1);
    final yearEnd = year == toDate.year
        ? DateTime(year, toDate.month, toDate.day)
        : DateTime(year, 12, 31);

    yearQueries.add(
      UserInfoService.getUserContributions(
        userName,
        from: yearStart,
        to: yearEnd,
      ),
    );
  }

  // Fetch all years in parallel
  final results = await Future.wait(yearQueries);

  // Combine results into wrapper
  return _combineResults(results);
  } catch (e, stackTrace) {
    log.e('Error fetching user contributions', error: e, stackTrace: stackTrace);
    rethrow;
  }
});

/// Combines multiple year results into a single CombinedContributionsData.
CombinedContributionsData _combineResults(
  List<GuserContributionsData_user> results,
) {
  if (results.isEmpty) {
    throw Exception('No results to combine');
  }

  log.d('[_combineResults] Starting to combine ${results.length} year results');

  // Combine all weeks from all years, preserving the original week structure from API
  // Use a map to track days by date (YYYY-MM-DD) to handle duplicates at year boundaries
  final allDaysMap = <String, ContributionDay>{};
  // Track week first days (as date strings) to preserve week structure and avoid duplicates
  final weekFirstDaysSet = <String>{};
  final weekFirstDaysList = <String>[];

  // Collect all weeks and days from all year results
  for (int resultIndex = 0; resultIndex < results.length; resultIndex++) {
    final result = results[resultIndex];
    final calendar = result.contributionsCollection.contributionCalendar;
    final weeks = calendar.weeks.whereType<
        GuserContributionsData_user_contributionsCollection_contributionCalendar_weeks>();

    log.d('[_combineResults] Result $resultIndex: Found ${weeks.length} weeks');

    for (int weekIndex = 0; weekIndex < weeks.length; weekIndex++) {
      final week = weeks.elementAt(weekIndex);
      
      // Get the first day of the week from the API (more reliable than using contributionDays.first)
      final firstDayDate = DateTime.parse(week.firstDay.toString());
      final firstDayKey = '${firstDayDate.year}-${firstDayDate.month.toString().padLeft(2, '0')}-${firstDayDate.day.toString().padLeft(2, '0')}';
      
      log.d('[_combineResults] Result $resultIndex, Week $weekIndex: firstDay=$firstDayKey, days=${week.contributionDays.length}');
      
      // Track unique week first days (use set for O(1) lookup, list for ordered output)
      if (!weekFirstDaysSet.contains(firstDayKey)) {
        weekFirstDaysSet.add(firstDayKey);
        weekFirstDaysList.add(firstDayKey);
        log.d('[_combineResults] Added new week: $firstDayKey (total unique weeks: ${weekFirstDaysList.length})');
      } else {
        log.d('[_combineResults] Skipped duplicate week: $firstDayKey');
      }

      // Collect all days from this week
      for (final day in week.contributionDays) {
        final dayDate = DateTime.parse(day.date.toString());
        final dateKey = '${dayDate.year}-${dayDate.month.toString().padLeft(2, '0')}-${dayDate.day.toString().padLeft(2, '0')}';

        // Use the latest data if there's a duplicate (at year boundaries)
        if (!allDaysMap.containsKey(dateKey)) {
          final contributionDay = ContributionDay(
            date: dayDate,
            count: day.contributionCount,
            color: _parseColor(day.color),
            level: _convertContributionLevel(day.contributionLevel),
          );
          allDaysMap[dateKey] = contributionDay;
        }
      }
    }
  }

  log.d('[_combineResults] Collected ${allDaysMap.length} unique days');
  log.d('[_combineResults] Collected ${weekFirstDaysList.length} unique week first days');

  // Sort week first days chronologically
  weekFirstDaysList.sort((a, b) => a.compareTo(b));
  log.d('[_combineResults] Sorted weeks. First week: ${weekFirstDaysList.firstOrNull}, Last week: ${weekFirstDaysList.lastOrNull}');

  // Reconstruct weeks preserving the original structure
  // Each week from API starts on the first day and has 7 days
  final allWeeks = <List<ContributionDay>>[];
  for (int weekIndex = 0; weekIndex < weekFirstDaysList.length; weekIndex++) {
    final firstDayKey = weekFirstDaysList[weekIndex];
    final firstDayDate = DateTime.parse(firstDayKey);
    final week = <ContributionDay>[];
    
    // Add 7 days for this week (preserving API structure)
    for (int i = 0; i < 7; i++) {
      final weekDay = firstDayDate.add(Duration(days: i));
      final dateKey = '${weekDay.year}-${weekDay.month.toString().padLeft(2, '0')}-${weekDay.day.toString().padLeft(2, '0')}';
      
      // Get day from map or create empty day
      final day = allDaysMap[dateKey] ?? ContributionDay(
        date: weekDay,
        count: 0,
        color: null,
        level: ContributionLevel.none,
      );
      
      week.add(day);
    }
    
    allWeeks.add(week);
    
    if (weekIndex < 3 || weekIndex >= weekFirstDaysList.length - 3) {
      log.d('[_combineResults] Reconstructed week $weekIndex: firstDay=$firstDayKey, days=${week.length}');
    }
  }

  log.d('[_combineResults] Final result: ${allWeeks.length} weeks, ${allDaysMap.length} unique days');

  // Combine repositories (merge by repository URL, sum contributions)
  final repoMap = <String, ContributedRepository>{};

  for (final result in results) {
    final repos = result.contributionsCollection.commitContributionsByRepository
        .whereType<
            GuserContributionsData_user_contributionsCollection_commitContributionsByRepository>();

    for (final repo in repos) {
      final repoData = repo.repository;
      final url = repoData.url.toString();
      final owner = repoData.owner.login;
      final primaryLang = repoData.primaryLanguage;

      if (repoMap.containsKey(url)) {
        // Sum contributions for existing repo
        final existing = repoMap[url]!;
        repoMap[url] = ContributedRepository(
          name: existing.name,
          owner: existing.owner,
          url: existing.url,
          contributionCount:
              existing.contributionCount + repo.contributions.totalCount,
          description: existing.description,
          language: existing.language,
          languageColor: existing.languageColor,
          stargazersCount: existing.stargazersCount,
          isPrivate: existing.isPrivate,
          isFork: existing.isFork,
        );
      } else {
        // Add new repo
        repoMap[url] = ContributedRepository(
          name: repoData.name,
          owner: owner,
          url: url,
          contributionCount: repo.contributions.totalCount,
          description: repoData.description,
          language: primaryLang?.name,
          languageColor: primaryLang?.color,
          stargazersCount: repoData.stargazerCount,
          isPrivate: repoData.isPrivate,
          isFork: repoData.isFork,
        );
      }
    }
  }

  // Sort repositories by contribution count (descending)
  final repositories = repoMap.values.toList()
    ..sort((a, b) => b.contributionCount.compareTo(a.contributionCount));

  // Sum all statistics
  int totalContributions = 0;
  int totalCommits = 0;
  int totalPRs = 0;
  int totalIssues = 0;
  int totalReviews = 0;
  final allYears = <int>{};

  for (final result in results) {
    final collection = result.contributionsCollection;
    totalContributions += collection.contributionCalendar.totalContributions;
    totalCommits += collection.totalCommitContributions;
    totalPRs += collection.totalPullRequestContributions;
    totalIssues += collection.totalIssueContributions;
    totalReviews += collection.totalPullRequestReviewContributions;
    allYears.addAll(collection.contributionYears);
  }

  // Get colors from the first result (they should be the same)
  final colors = _parseColors(
    results.first.contributionsCollection.contributionCalendar.colors.toList(),
  );

  return CombinedContributionsData(
    weeks: allWeeks,
    colors: colors,
    totalContributions: totalContributions,
    totalCommitContributions: totalCommits,
    totalPullRequestContributions: totalPRs,
    totalIssueContributions: totalIssues,
    totalPullRequestReviewContributions: totalReviews,
    commitContributionsByRepository: repositories,
    contributionYears: allYears.toList()..sort(),
  );
}

/// Converts GraphQL contribution level to enum
ContributionLevel _convertContributionLevel(GContributionLevel level) {
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

/// Parses hex color string to Color
Color _parseColor(String hexColor) {
  // Remove # if present and ensure uppercase
  final hex = hexColor.replaceFirst('#', '').toUpperCase();
  // Parse as int with alpha channel (FF = fully opaque)
  final colorValue = int.parse('FF$hex', radix: 16);
  return Color(colorValue);
}

/// Parses list of hex color strings to Color list
List<Color> _parseColors(List<String> colors) {
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
  return colors.map(_parseColor).toList();
}
