import 'package:built_collection/built_collection.dart';
import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_activity_timeline_minimal.data.gql.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_activity_timeline_minimal.req.gql.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_activity_timeline_full.data.gql.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_activity_timeline_full.req.gql.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_contributions.data.gql.dart';
import 'package:diohub/services/users/user_info_service.dart';
import 'package:diohub/view/profile/about/widgets/activity_timeline_event.dart';

/// Phase 1 result: cursor before range and total count
class Phase1Result {
  final String? cursorBeforeRange;
  final int totalInRange;
  final String? cursorAfterRange;

  Phase1Result({
    this.cursorBeforeRange,
    required this.totalInRange,
    this.cursorAfterRange,
  });
}

/// Phase 1 state: tracks pagination for all types
class Phase1State {
  int? firstRepos = 100;
  int? firstPRs = 100;
  int? firstIssues = 100;
  String? afterRepos;
  String? afterPRs;
  String? afterIssues;

  Phase1Result? reposResult;
  Phase1Result? prsResult;
  Phase1Result? issuesResult;

  bool get allRangesFound =>
      reposResult != null && prsResult != null && issuesResult != null;
}

class UserActivityService {
  static final GraphqlHandler _gqlHandler = GraphqlHandler();

  /// Phase 1: Combined minimal fetch with dynamic first params
  /// As we find ranges for each type, set their first to 0
  static Future<Map<String, Phase1Result>> _fetchMinimalData(
    String login,
    DateTime from,
    DateTime to, {
    bool refreshCache = false,
  }) async {
    final state = Phase1State();
    final results = <String, Phase1Result>{};

    // Continue until all types have found their ranges
    while (!state.allRangesFound) {
      final batch = await _gqlHandler.query(
        GuserActivityTimelineMinimalReq(
          (final GuserActivityTimelineMinimalReqBuilder b) {
            b..vars.user = login;
            if (state.firstRepos != null && state.firstRepos! > 0) {
              b..vars.firstRepos = state.firstRepos;
              if (state.afterRepos != null) {
                b..vars.afterRepos = state.afterRepos;
              }
            } else {
              b..vars.firstRepos = 0; // Stop fetching repos
            }

            if (state.firstPRs != null && state.firstPRs! > 0) {
              b..vars.firstPRs = state.firstPRs;
              if (state.afterPRs != null) {
                b..vars.afterPRs = state.afterPRs;
              }
            } else {
              b..vars.firstPRs = 0; // Stop fetching PRs
            }

            if (state.firstIssues != null && state.firstIssues! > 0) {
              b..vars.firstIssues = state.firstIssues;
              if (state.afterIssues != null) {
                b..vars.afterIssues = state.afterIssues;
              }
            } else {
              b..vars.firstIssues = 0; // Stop fetching issues
          }
        },
      ),
      refreshCache: refreshCache,
    );

      final data = GuserActivityTimelineMinimalData.fromJson(batch.data!)!.user!;

      // Process repositories
      if (state.reposResult == null && data.repositories.edges != null) {
        final reposResult = _processRepositories(
          data.repositories.edges!,
          data.repositories.pageInfo,
          from,
          to,
        );
        if (reposResult != null) {
          state.reposResult = reposResult;
          results['repos'] = reposResult;
          state.firstRepos = 0; // Stop fetching repos
        } else {
          // Continue pagination
          state.afterRepos = data.repositories.pageInfo.endCursor;
        }
      }

      // Process pull requests
      if (state.prsResult == null && data.pullRequests.edges != null) {
        final prsResult = _processPullRequests(
          data.pullRequests.edges!,
          data.pullRequests.pageInfo,
          from,
          to,
        );
        if (prsResult != null) {
          state.prsResult = prsResult;
          results['prs'] = prsResult;
          state.firstPRs = 0; // Stop fetching PRs
        } else {
          // Continue pagination
          state.afterPRs = data.pullRequests.pageInfo.endCursor;
        }
      }

      // Process issues
      if (state.issuesResult == null && data.issues.edges != null) {
        final issuesResult = _processIssues(
          data.issues.edges!,
          data.issues.pageInfo,
          from,
          to,
        );
        if (issuesResult != null) {
          state.issuesResult = issuesResult;
          results['issues'] = issuesResult;
          state.firstIssues = 0; // Stop fetching issues
        } else {
          // Continue pagination
          state.afterIssues = data.issues.pageInfo.endCursor;
        }
      }

      // Check if we should continue
      final shouldContinue = (!state.allRangesFound) &&
          (data.repositories.pageInfo.hasNextPage ||
              data.pullRequests.pageInfo.hasNextPage ||
              data.issues.pageInfo.hasNextPage);

      if (!shouldContinue) break;
    }

    return results;
  }

  /// Process repositories to find range
  static Phase1Result? _processRepositories(
    BuiltList<GuserActivityTimelineMinimalData_user_repositories_edges?> edges,
    GuserActivityTimelineMinimalData_user_repositories_pageInfo pageInfo,
    DateTime from,
    DateTime to,
  ) {
    String? cursorBeforeRange;
    int totalInRange = 0;
    String? lastInRangeCursor;
    bool foundFirstInRange = false;

    for (final edge in edges) {
      if (edge == null) continue;
      final node = edge.node;
      if (node == null) continue;

      final createdAt = node.createdAt;
      final currentCursor = edge.cursor;

      // Stop if date is before range (ordered DESC)
      if (createdAt.isBefore(from)) {
        break;
      }

      if (_isInDateRange(createdAt, from, to)) {
        if (!foundFirstInRange) {
          foundFirstInRange = true;
          // cursorBeforeRange is already set from previous iteration
        }
        totalInRange++;
        lastInRangeCursor = currentCursor;
      } else {
        if (!foundFirstInRange) {
          cursorBeforeRange = currentCursor; // Save cursor before range
        } else {
          // Passed range
          break;
        }
      }
    }

    if (foundFirstInRange) {
      return Phase1Result(
        cursorBeforeRange: cursorBeforeRange,
        totalInRange: totalInRange,
        cursorAfterRange: lastInRangeCursor,
      );
    }

    // Range not found yet, continue pagination
    return null;
  }

  /// Process pull requests to find range
  static Phase1Result? _processPullRequests(
    BuiltList<GuserActivityTimelineMinimalData_user_pullRequests_edges?> edges,
    GuserActivityTimelineMinimalData_user_pullRequests_pageInfo pageInfo,
    DateTime from,
    DateTime to,
  ) {
    String? cursorBeforeRange;
    int totalInRange = 0;
    String? lastInRangeCursor;
    bool foundFirstInRange = false;

    for (final edge in edges) {
      if (edge == null) continue;
      final node = edge.node;
      if (node == null) continue;

      final createdAt = node.createdAt;
      final currentCursor = edge.cursor;

      if (createdAt.isBefore(from)) {
        break;
      }

      if (_isInDateRange(createdAt, from, to)) {
        if (!foundFirstInRange) {
          foundFirstInRange = true;
        }
        totalInRange++;
        lastInRangeCursor = currentCursor;
      } else {
        if (!foundFirstInRange) {
          cursorBeforeRange = currentCursor;
        } else {
          break;
        }
      }
    }

    if (foundFirstInRange) {
      return Phase1Result(
        cursorBeforeRange: cursorBeforeRange,
        totalInRange: totalInRange,
        cursorAfterRange: lastInRangeCursor,
      );
    }

    return null;
  }

  /// Process issues to find range
  static Phase1Result? _processIssues(
    BuiltList<GuserActivityTimelineMinimalData_user_issues_edges?> edges,
    GuserActivityTimelineMinimalData_user_issues_pageInfo pageInfo,
    DateTime from,
    DateTime to,
  ) {
    String? cursorBeforeRange;
    int totalInRange = 0;
    String? lastInRangeCursor;
    bool foundFirstInRange = false;

    for (final edge in edges) {
      if (edge == null) continue;
      final node = edge.node;
      if (node == null) continue;

      final createdAt = node.createdAt;
      final currentCursor = edge.cursor;

      if (createdAt.isBefore(from)) {
        break;
      }

      if (_isInDateRange(createdAt, from, to)) {
        if (!foundFirstInRange) {
          foundFirstInRange = true;
        }
        totalInRange++;
        lastInRangeCursor = currentCursor;
      } else {
        if (!foundFirstInRange) {
          cursorBeforeRange = currentCursor;
        } else {
          break;
        }
      }
    }

    if (foundFirstInRange) {
      return Phase1Result(
        cursorBeforeRange: cursorBeforeRange,
        totalInRange: totalInRange,
        cursorAfterRange: lastInRangeCursor,
      );
    }

    return null;
  }

  /// Check if date is in range (inclusive boundaries)
  static bool _isInDateRange(DateTime date, DateTime from, DateTime to) {
    return date.isAfter(from.subtract(const Duration(days: 1))) &&
        date.isBefore(to.add(const Duration(days: 1)));
  }

  /// Phase 2: Single combined query with full fields
  static Future<GuserActivityTimelineFullData_user> _fetchDetailedData(
    Map<String, Phase1Result> phase1Results,
    String login, {
    bool refreshCache = false,
  }) async {
    final reposResult = phase1Results['repos'];
    final prsResult = phase1Results['prs'];
    final issuesResult = phase1Results['issues'];

    final response = await _gqlHandler.query(
      GuserActivityTimelineFullReq(
        (final GuserActivityTimelineFullReqBuilder b) {
          b..vars.user = login;

          // Repositories
          if (reposResult != null && reposResult.totalInRange > 0) {
            b
              ..vars.firstRepos = reposResult.totalInRange
              ..vars.afterRepos = reposResult.cursorBeforeRange;
          } else {
            b..vars.firstRepos = 0;
          }

          // Pull Requests
          if (prsResult != null && prsResult.totalInRange > 0) {
            b
              ..vars.firstPRs = prsResult.totalInRange
              ..vars.afterPRs = prsResult.cursorBeforeRange;
          } else {
            b..vars.firstPRs = 0;
          }

          // Issues
          if (issuesResult != null && issuesResult.totalInRange > 0) {
            b
              ..vars.firstIssues = issuesResult.totalInRange
              ..vars.afterIssues = issuesResult.cursorBeforeRange;
          } else {
            b..vars.firstIssues = 0;
          }
        },
      ),
      refreshCache: refreshCache,
    );

    return GuserActivityTimelineFullData.fromJson(response.data!)!.user!;
  }

  /// Fetch commits (already date-filtered, no two-phase needed)
  /// Note: Using existing userContributions query structure for commits
  /// TODO: Create separate commits query if needed for pagination
  static Future<GuserContributionsData_user> _fetchCommits(
    String login,
    DateTime from,
    DateTime to, {
    bool refreshCache = false,
  }) async {
    // Use existing getUserContributions for commits
    // It already has commitContributionsByRepository
    return UserInfoService.getUserContributions(
      login,
      from: from,
      to: to,
      refreshCache: refreshCache,
    );
  }

  /// Main entry point: Two-phase fetch with combined queries
  static Future<UserActivityTimelineData> getUserActivityTimeline({
    required String login,
    required DateTime from,
    required DateTime to,
    bool refreshCache = false,
  }) async {
    // Phase 1: Combined minimal fetch (single query per page)
    final phase1Results = await _fetchMinimalData(
      login,
      from,
      to,
      refreshCache: refreshCache,
    );

    // Phase 2: Combined full fetch (single query for all types)
    final results = await Future.wait([
      _fetchDetailedData(phase1Results, login, refreshCache: refreshCache),
      _fetchCommits(login, from, to, refreshCache: refreshCache),
    ]);

    // Convert to timeline events
    return _buildTimelineData(
      results[0] as GuserActivityTimelineFullData_user,
      results[1] as GuserContributionsData_user,
      from,
      to,
    );
  }

  /// Build timeline data from GraphQL responses
  static UserActivityTimelineData _buildTimelineData(
    GuserActivityTimelineFullData_user fullData,
    GuserContributionsData_user commitsData,
    DateTime from,
    DateTime to,
  ) {
    // TODO: Implement conversion to ActivityTimelineEvent
    // This will be implemented in the converter
    throw UnimplementedError('Timeline data conversion not yet implemented');
  }
}

