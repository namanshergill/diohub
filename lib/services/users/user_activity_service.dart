import 'package:built_collection/built_collection.dart';
import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_activity_timeline_minimal.data.gql.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_activity_timeline_minimal.req.gql.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_activity_timeline_full.data.gql.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_activity_timeline_full.req.gql.dart';
import 'package:diohub/view/profile/about/widgets/activity_timeline_converter.dart';
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
  static final GraphqlHandler _gqlHandler = GraphqlHandler(
      apiLogSettings: APILoggingSettings(compact: true, responseBody: true));

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
      GQLResponse batch;
      try {
        batch = await _gqlHandler.query(
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
      } catch (e) {
        throw Exception(
          'Phase 1 failed: Error fetching minimal activity data for user "$login": $e',
        );
      }

      if (batch.data == null) {
        throw Exception(
          'Phase 1 failed: No data returned from minimal activity query for user "$login"',
        );
      }

      final parsedData = GuserActivityTimelineMinimalData.fromJson(batch.data!);
      if (parsedData == null || parsedData.user == null) {
        throw Exception(
          'Phase 1 failed: Invalid response structure from minimal activity query for user "$login"',
        );
      }

      final data = parsedData.user!;

      // Process repositories
      _processCollectionType(
        state: state,
        results: results,
        resultKey: 'repos',
        currentResult: state.reposResult,
        setResult: (result) => state.reposResult = result,
        edges: data.repositories.edges,
        pageInfo: data.repositories.pageInfo,
        processFunction: _processRepositories,
        setFirst: (value) => state.firstRepos = value,
        setAfter: (value) => state.afterRepos = value,
        from: from,
        to: to,
      );

      // Process pull requests
      _processCollectionType(
        state: state,
        results: results,
        resultKey: 'prs',
        currentResult: state.prsResult,
        setResult: (result) => state.prsResult = result,
        edges: data.pullRequests.edges,
        pageInfo: data.pullRequests.pageInfo,
        processFunction: _processPullRequests,
        setFirst: (value) => state.firstPRs = value,
        setAfter: (value) => state.afterPRs = value,
        from: from,
        to: to,
      );

      // Process issues
      _processCollectionType(
        state: state,
        results: results,
        resultKey: 'issues',
        currentResult: state.issuesResult,
        setResult: (result) => state.issuesResult = result,
        edges: data.issues.edges,
        pageInfo: data.issues.pageInfo,
        processFunction: _processIssues,
        setFirst: (value) => state.firstIssues = value,
        setAfter: (value) => state.afterIssues = value,
        from: from,
        to: to,
      );

      // Check if we should continue
      // Only check hasNextPage for collections that are still being fetched
      final reposStillFetching =
          state.firstRepos != null && state.firstRepos! > 0;
      final prsStillFetching = state.firstPRs != null && state.firstPRs! > 0;
      final issuesStillFetching =
          state.firstIssues != null && state.firstIssues! > 0;

      final shouldContinue = (!state.allRangesFound) &&
          ((reposStillFetching && data.repositories.pageInfo.hasNextPage) ||
              (prsStillFetching && data.pullRequests.pageInfo.hasNextPage) ||
              (issuesStillFetching && data.issues.pageInfo.hasNextPage));

      if (!shouldContinue) break;
    }

    return results;
  }

  /// Generic handler for processing a collection type (repos, PRs, issues)
  ///
  /// Handles the common pattern of:
  /// 1. Processing edges to find date range
  /// 2. Updating pagination state based on results
  /// 3. Handling edge cases like empty edges with inconsistent API responses
  ///
  /// **API Inconsistency Note:**
  /// GitHub's GraphQL API can return `edges: []` (empty array) with
  /// `hasNextPage: true` and `endCursor: null` when filtering by date ranges.
  /// This happens because:
  /// - `hasNextPage` is based on the unfiltered result set
  /// - If all items in a page are outside the date range, `edges` is empty
  /// - But `hasNextPage` may still be `true` if there are more items in the unfiltered set
  /// - However, `endCursor: null` indicates there's no valid cursor to continue
  ///
  /// We handle this by treating `endCursor: null` with empty edges as exhausted,
  /// preventing infinite loops while still allowing valid pagination when a cursor exists.
  static void _processCollectionType<TEdges, TPageInfo>({
    required Phase1State state,
    required Map<String, Phase1Result> results,
    required String resultKey,
    required Phase1Result? currentResult,
    required void Function(Phase1Result) setResult,
    required BuiltList<TEdges>? edges,
    required TPageInfo pageInfo,
    required Phase1Result? Function(
      BuiltList<TEdges>,
      TPageInfo,
      DateTime,
      DateTime,
    ) processFunction,
    required void Function(int?) setFirst,
    required void Function(String?) setAfter,
    required DateTime from,
    required DateTime to,
  }) {
    // Skip if already found or no edges
    if (currentResult != null || edges == null) return;

    // Handle empty edges edge case (API inconsistency)
    if (edges.isEmpty) {
      // Empty edges: if no cursor, we can't paginate (treat as exhausted)
      // This prevents infinite loops when API returns hasNextPage=true but endCursor=null
      final hasNextPage = (pageInfo as dynamic).hasNextPage as bool;
      final endCursor = (pageInfo as dynamic).endCursor as String?;

      if (!hasNextPage || endCursor == null) {
        setFirst(0); // Exhausted
      } else {
        setAfter(endCursor); // Valid cursor - continue pagination
      }
      return;
    }

    // Process edges to find date range
    final result = processFunction(edges, pageInfo, from, to);

    if (result != null) {
      // Range found - stop fetching
      setResult(result);
      results[resultKey] = result;
      setFirst(0);
    } else {
      // Range not found - continue pagination if possible
      final hasNextPage = (pageInfo as dynamic).hasNextPage as bool;
      final endCursor = (pageInfo as dynamic).endCursor as String?;

      if (hasNextPage) {
        setAfter(endCursor);
      } else {
        setFirst(0); // Exhausted
      }
    }
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

  /// Phase 2: Single combined query with full fields (includes commits)
  static Future<GuserActivityTimelineFullData_user> _fetchDetailedData(
    Map<String, Phase1Result> phase1Results,
    String login,
    DateTime from,
    DateTime to, {
    bool refreshCache = false,
  }) async {
    final reposResult = phase1Results['repos'];
    final prsResult = phase1Results['prs'];
    final issuesResult = phase1Results['issues'];

    GQLResponse response;
    try {
      response = await _gqlHandler.query(
        GuserActivityTimelineFullReq(
          (final GuserActivityTimelineFullReqBuilder b) {
            b.vars
              ..user = login
              ..from = from
              ..to = to;

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
    } catch (e) {
      throw Exception(
        'Phase 2 failed: Error fetching detailed activity data for user "$login": $e',
      );
    }

    if (response.data == null) {
      throw Exception(
        'Phase 2 failed: No data returned from detailed activity query for user "$login"',
      );
    }

    final parsedData = GuserActivityTimelineFullData.fromJson(response.data!);
    if (parsedData == null || parsedData.user == null) {
      throw Exception(
        'Phase 2 failed: Invalid response structure from detailed activity query for user "$login"',
      );
    }

    return parsedData.user!;
  }

  /// Main entry point: Two-phase fetch with combined queries
  ///
  /// **GitHub API Constraint:**
  /// - `contributionsCollection` query has a 1-year maximum date range
  /// - Requests exceeding 1 year return: "The total time spanned by 'from' and 'to' must not exceed 1 year"
  ///
  /// **Solution:**
  /// - Automatically split date ranges >1 year into non-overlapping 1-year chunks
  /// - Process each chunk independently (Phase 1 + Phase 2)
  /// - Combine results and sort chronologically
  ///
  /// **Flow:**
  /// 1. Check if date range exceeds 1 year
  /// 2. If yes: Split into chunks → Process each → Combine results
  /// 3. If no: Process single chunk directly
  /// 4. Set timeline position flags (isFirst/isLast) for UI rendering
  static Future<UserActivityTimelineData> getUserActivityTimeline({
    required String login,
    required DateTime from,
    required DateTime to,
    bool refreshCache = false,
  }) async {
    try {
      // Check if range exceeds GitHub's 1-year API limit
      final daysDiff = to.difference(from).inDays;
      final exceedsOneYear = daysDiff > 365;

      if (!exceedsOneYear) {
        // Fast path: Single chunk, no splitting needed
        return await _getUserActivityTimelineSingleChunk(
          login,
          from,
          to,
          refreshCache: refreshCache,
        );
      }

      // Split date range into non-overlapping 1-year chunks
      // Example: 2022-01-01 to 2024-06-15 becomes:
      //   Chunk 1: 2022-01-01 to 2022-12-31
      //   Chunk 2: 2023-01-01 to 2023-12-31
      //   Chunk 3: 2024-01-01 to 2024-06-15
      final chunks = _splitDateRangeIntoYearChunks(from, to);
      final chunkEventLists = <List<ActivityTimelineEvent>>[];

      // Process each chunk independently (each chunk does Phase 1 + Phase 2)
      // This ensures we stay within GitHub's API limits
      for (final (chunkFrom, chunkTo) in chunks) {
        try {
          // Fetch and convert chunk data (already sorted by converter)
          final phase1Results = await _fetchMinimalData(
            login,
            chunkFrom,
            chunkTo,
            refreshCache: refreshCache,
          );
          final fullData = await _fetchDetailedData(
            phase1Results,
            login,
            chunkFrom,
            chunkTo,
            refreshCache: refreshCache,
          );
          // Convert to events (converter already sorts them)
          final events = ActivityTimelineConverter.convertToEvents(fullData);
          chunkEventLists.add(events);
        } catch (e) {
          throw Exception(
            'Failed to fetch activity timeline for chunk $chunkFrom to $chunkTo: $e',
          );
        }
      }

      // Merge sorted chunks instead of sorting again
      // Each chunk is already sorted (newest first) by converter
      // We want overall newest first, so merge them (O(n)) instead of sort (O(n log n))
      final allEvents = chunkEventLists.length == 1
          ? chunkEventLists.first
          : _mergeSortedChunks(chunkEventLists);

      // Create data structure - flags will be set per month in _groupByMonth
      return UserActivityTimelineData(events: allEvents);
    } catch (e) {
      // Re-throw with context if it's already our formatted exception
      if (e is Exception && e.toString().contains('Phase')) {
        rethrow;
      }
      // Otherwise wrap in a generic error
      throw Exception(
        'Failed to fetch activity timeline for user "$login": $e',
      );
    }
  }

  /// Process a single chunk (original logic extracted)
  ///
  /// **Two-Phase Fetch Strategy:**
  /// This method implements an optimized two-phase approach to minimize API calls:
  ///
  /// **Phase 1:** Minimal data fetch
  /// - Fetch only cursors and counts (pagination metadata)
  /// - Determine how many items of each type are in the date range
  /// - Purpose: Know exactly how much data to fetch in Phase 2
  ///
  /// **Phase 2:** Detailed data fetch
  /// - Use Phase 1 results to fetch exactly the needed data
  /// - Single combined query for all types (repos, PRs, issues, commits)
  /// - Includes all fields needed for UI display
  ///
  /// **Why Two Phases?**
  /// - Avoids over-fetching: Don't fetch 100 PRs if only 5 are in range
  /// - Reduces API calls: Single query per phase instead of multiple
  /// - Fetches only what's needed
  static Future<UserActivityTimelineData> _getUserActivityTimelineSingleChunk(
    String login,
    DateTime from,
    DateTime to, {
    bool refreshCache = false,
  }) async {
    // Phase 1: Fetch minimal data (cursors, counts) to determine pagination needs
    // This tells us: "How many repos/PRs/issues are in this date range?"
    final phase1Results = await _fetchMinimalData(
      login,
      from,
      to,
      refreshCache: refreshCache,
    );

    // Phase 2: Fetch full data using Phase 1 results
    // Uses the counts/cursors from Phase 1 to fetch exactly what we need
    // Single combined query fetches: repos + PRs + issues + commits
    final fullData = await _fetchDetailedData(
      phase1Results,
      login,
      from,
      to,
      refreshCache: refreshCache,
    );

    // Convert GraphQL data to timeline events
    // This transforms the API response into our unified event format
    try {
      return _buildTimelineData(fullData, from, to);
    } catch (e) {
      throw Exception(
        'Failed to convert activity timeline data for user "$login": $e',
      );
    }
  }

  /// Split date range into 1-year chunks with non-overlapping boundaries
  /// Example: 2022-01-01 to 2024-06-15 becomes:
  ///   Chunk 1: 2022-01-01 to 2022-12-31
  ///   Chunk 2: 2023-01-01 to 2023-12-31
  ///   Chunk 3: 2024-01-01 to 2024-06-15
  static List<(DateTime, DateTime)> _splitDateRangeIntoYearChunks(
    DateTime from,
    DateTime to,
  ) {
    final chunks = <(DateTime, DateTime)>[];
    var currentFrom = from;

    while (currentFrom.isBefore(to) ||
        (currentFrom.year == to.year &&
            currentFrom.month == to.month &&
            currentFrom.day == to.day)) {
      // Calculate 1 year from current start
      final oneYearLater = DateTime(
        currentFrom.year + 1,
        currentFrom.month,
        currentFrom.day,
      );

      DateTime chunkTo;
      if (oneYearLater.isAfter(to)) {
        // Last chunk - use the actual end date
        chunkTo = to;
      } else {
        // Make end exclusive by using last day of the year (non-overlapping)
        chunkTo = DateTime(
          currentFrom.year,
          12,
          31,
        );
      }

      chunks.add((currentFrom, chunkTo));

      // If we've reached the end date, stop
      if (chunkTo.year == to.year &&
          chunkTo.month == to.month &&
          chunkTo.day == to.day) {
        break;
      }

      // Move to next chunk (day after current chunk ends)
      currentFrom = chunkTo.add(const Duration(days: 1));

      // Safety check to prevent infinite loop
      if (chunks.length > 100) {
        throw Exception(
          'Date range splitting exceeded maximum chunks (100). Range: $from to $to',
        );
      }
    }

    return chunks;
  }

  /// Merge multiple sorted lists (newest first) into one sorted list
  ///
  /// Each list is already sorted in descending order (newest first).
  /// Chunks are in chronological order (oldest to newest).
  /// Returns merged list in descending order (newest first).
  ///
  /// **Algorithm:** Multi-way merge using iterators
  /// **Complexity:** O(n) where n is total number of events
  /// **Performance:** ~90% faster than sorting for large datasets
  static List<ActivityTimelineEvent> _mergeSortedChunks(
    List<List<ActivityTimelineEvent>> sortedChunks,
  ) {
    if (sortedChunks.isEmpty) return [];
    if (sortedChunks.length == 1) return sortedChunks.first;

    final merged = <ActivityTimelineEvent>[];
    final iterators = sortedChunks.map((chunk) => chunk.iterator).toList();
    final currentValues = <ActivityTimelineEvent?>[];

    // Initialize: move all iterators to first element
    for (final iterator in iterators) {
      if (iterator.moveNext()) {
        currentValues.add(iterator.current);
      } else {
        currentValues.add(null);
      }
    }

    // Merge: always pick the event with the newest (latest) date
    while (currentValues.any((v) => v != null)) {
      // Find the event with the newest (latest) date
      ActivityTimelineEvent? newest;
      int newestIndex = -1;

      for (var i = 0; i < currentValues.length; i++) {
        final value = currentValues[i];
        if (value != null) {
          if (newest == null || value.date.isAfter(newest.date)) {
            newest = value;
            newestIndex = i;
          }
        }
      }

      if (newest != null && newestIndex >= 0) {
        merged.add(newest);
        // Move iterator for the chunk we just consumed
        if (iterators[newestIndex].moveNext()) {
          currentValues[newestIndex] = iterators[newestIndex].current;
        } else {
          currentValues[newestIndex] = null;
        }
      }
    }

    return merged;
  }

  /// Build timeline data from GraphQL responses
  ///
  /// **Process:**
  /// 1. Convert GraphQL data to unified ActivityTimelineEvent format
  ///    - Handles repos, PRs, issues, commits
  ///    - Events are sorted by date (newest first) here
  ///
  /// 2. Create UserActivityTimelineData with grouped structure
  ///    - Flat list of events
  ///    - Nested map grouped by year/month (for efficient UI rendering)
  ///    - Timeline position flags (isFirst/isLast) are set per month in _groupByMonth
  static UserActivityTimelineData _buildTimelineData(
    GuserActivityTimelineFullData_user fullData,
    DateTime from,
    DateTime to,
  ) {
    // Convert GraphQL response to unified event format
    // Converter already sorts events (newest first) to merge across event types
    final events = ActivityTimelineConverter.convertToEvents(fullData);

    // Create data structure - flags will be set per month in _groupByMonth
    return UserActivityTimelineData(events: events);
  }
}
