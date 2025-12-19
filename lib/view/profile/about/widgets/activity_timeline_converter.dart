import 'package:diohub/graphql/queries/users/__generated__/user_activity_timeline_full.data.gql.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_info.data.gql.dart';
import 'package:diohub/models/commits/commit_card_data_model.dart';
import 'package:diohub/models/issues/issue_card_data_model.dart';
import 'package:diohub/models/pull_requests/pull_request_card_data_model.dart';
import 'package:diohub/models/repositories/repo_card_data_model.dart';
import 'package:diohub/view/profile/about/widgets/activity_timeline_event.dart';

/// Helper class to store repo data with count
/// Stores all available fields from GraphQL for future UI use
class _RepoData {
  final String owner;
  final String name;
  final String url;
  final String? id; // Repository ID from GraphQL
  final RepoCardDataModel?
      repoData; // Full repository metadata preserved from GraphQL
  int count;

  _RepoData({
    required this.owner,
    required this.name,
    required this.url,
    this.id,
    this.repoData,
    this.count = 0,
  });
}

/// Converts GraphQL data to timeline events
///
/// This converter transforms raw GraphQL API responses into a unified
/// `ActivityTimelineEvent` format that the UI can consume.
///
/// **Conversion Flow:**
/// 1. Convert each event type (repos, PRs, issues, commits) independently
/// 2. Combine all events into a single list
/// 3. Sort by date (newest first) for consistent timeline display
class ActivityTimelineConverter {
  /// Convert all GraphQL data to timeline events
  ///
  /// **Process:**
  /// 1. Convert repositories → repository creation events
  /// 2. Convert pull requests → PR events
  /// 3. Convert issues → issue events
  /// 4. Convert commits → commit events (grouped by date)
  /// 5. Sort all events by date (newest first)
  static List<ActivityTimelineEvent> convertToEvents(
    GuserActivityTimelineFullData_user fullData,
  ) {
    final events = <ActivityTimelineEvent>[];

    // Convert each event type independently
    events.addAll(_convertRepositories(fullData));
    events.addAll(_convertPullRequests(fullData));
    events.addAll(_convertIssues(fullData));
    events.addAll(_convertCommits(fullData));

    // Sort events by date (newest first)
    // Required: While each type is sorted by API, we need to merge across types
    // since repos, PRs, issues, and commits may have overlapping dates
    events.sort((a, b) => b.date.compareTo(a.date));

    return events;
  }

  /// Convert repositories to repository creation events
  static List<ActivityTimelineEvent> _convertRepositories(
    GuserActivityTimelineFullData_user fullData,
  ) {
    final events = <ActivityTimelineEvent>[];
    final edges = fullData.repositories.edges;

    if (edges == null) return events;

    for (final edge in edges) {
      if (edge?.node == null) continue;

      final repo = edge!.node!;
      final owner = repo.owner.login;
      final name = repo.name;
      final url = repo.url.toString();

      // Create unified repository data model using fromGraphQL to preserve all metadata
      // Cast to GrepositoryFields since the query includes ...repositoryFields fragment
      final repoData = RepoCardDataModel.fromGraphQL(repo as GrepositoryFields);

      events.add(
        ActivityTimelineEvent(
          type: ActivityEventType.repositoryCreated,
          date: repo.createdAt,
          repositoryOwner: owner,
          repositoryName: name,
          repositoryUrl: url,
          repositoryData: repoData,
          repositoryNode: repo, // Store full GraphQL node
        ),
      );
    }

    return events;
  }

  /// Convert pull requests to PR events
  static List<ActivityTimelineEvent> _convertPullRequests(
    GuserActivityTimelineFullData_user fullData,
  ) {
    final events = <ActivityTimelineEvent>[];
    final edges = fullData.pullRequests.edges;

    if (edges == null) return events;

    for (final edge in edges) {
      if (edge?.node == null) continue;

      final pr = edge!.node!;
      final owner = pr.repository.owner.login;
      final name = pr.repository.name;
      final url = pr.repository.url.toString();

      // Create unified PR data model
      final prData = PullRequestCardDataModel.fromGraphQL(pr);

      events.add(
        ActivityTimelineEvent(
          type: ActivityEventType.pullRequest,
          date: pr.createdAt,
          title: pr.title,
          repositoryOwner: owner,
          repositoryName: name,
          repositoryUrl: url,
          pullRequestData: prData,
          pullRequestNode: pr, // Store full GraphQL node
        ),
      );
    }

    return events;
  }

  /// Convert issues to issue events
  static List<ActivityTimelineEvent> _convertIssues(
    GuserActivityTimelineFullData_user fullData,
  ) {
    final events = <ActivityTimelineEvent>[];
    final edges = fullData.issues.edges;

    if (edges == null) return events;

    for (final edge in edges) {
      if (edge?.node == null) continue;

      final issue = edge!.node!;
      final owner = issue.repository.owner.login;
      final name = issue.repository.name;
      final url = issue.repository.url.toString();

      // Create unified issue data model
      final issueData = IssueCardDataModel.fromGraphQL(issue);

      events.add(
        ActivityTimelineEvent(
          type: ActivityEventType.issue,
          date: issue.createdAt,
          title: issue.title,
          repositoryOwner: owner,
          repositoryName: name,
          repositoryUrl: url,
          issueData: issueData,
          issueNode: issue, // Store full GraphQL node
        ),
      );
    }

    return events;
  }

  /// Convert commits to commit events (grouped by date and repository)
  ///
  /// **GitHub API Structure:**
  /// - API returns commits grouped by repository
  /// - Each repository has contributions (date + commit count)
  ///
  /// **Our Transformation:**
  /// - Regroup by date (one event per day)
  /// - Aggregate commits across all repositories for that day
  /// - Store all repository info for UI display
  ///
  /// **Flow:**
  /// 1. **First Pass:** Iterate through repos and contributions
  ///    - Extract repo data (owner, name, url, id) - CAPTURE ALL FIELDS HERE
  ///    - Group contributions by date (YYYY-MM-DD key)
  ///    - Accumulate commit counts per repo per date
  ///    - Store complete repo data to avoid later lookups
  ///
  /// 2. **Second Pass:** Create events for each date
  ///    - Count total commits across all repos for that date
  ///    - Build repository info list (already has all data, no lookups needed)
  ///    - Create one ActivityTimelineEvent per date
  ///
  /// **Example:**
  /// Input: Repo A (Jan 1: 3 commits), Repo B (Jan 1: 2 commits)
  /// Output: One event for Jan 1 with 5 total commits, 2 repositories
  static List<ActivityTimelineEvent> _convertCommits(
    GuserActivityTimelineFullData_user fullData,
  ) {
    final events = <ActivityTimelineEvent>[];
    final repos =
        fullData.contributionsCollection.commitContributionsByRepository;

    // PHASE 1: Group contributions by date
    // Structure: dateKey -> {repoKey -> _RepoData with count}
    // We store complete repo data here to avoid expensive lookups later
    final contributionsByDate = <String, Map<String, _RepoData>>{};

    // Iterate through repositories (API groups by repo)
    for (final repoContributions in repos) {
      final repo = repoContributions.repository;

      // Create RepoCardDataModel using fromGraphQL to preserve all metadata
      // Cast to GrepositoryFields since the query includes ...repositoryFields fragment
      final repoData = RepoCardDataModel.fromGraphQL(repo as GrepositoryFields);

      // Extract all repo fields ONCE - store for later use
      final owner = repo.owner.login;
      final name = repo.name;
      final repoKey = '$owner/$name'; // Key for grouping
      final repoUrl = repo.url.toString();
      final repoId = repo.id; // Store repository ID for future UI use

      final contributions = repoContributions.contributions;
      if (contributions.nodes == null) continue;

      // Iterate through contributions for this repository
      for (final contribution in contributions.nodes!) {
        if (contribution == null) continue;

        final occurredAt = contribution.occurredAt;
        final commitCount = contribution.commitCount;

        // Create date key for grouping (YYYY-MM-DD format)
        final dateKey = _getDateKey(occurredAt);

        // Ensure date entry exists
        contributionsByDate.putIfAbsent(dateKey, () => {});

        // Ensure repo entry exists for this date, initialize with repo data
        // This is where we capture ALL repo fields to avoid lookups later
        // Store RepoCardDataModel for full metadata preservation
        contributionsByDate[dateKey]!.putIfAbsent(
          repoKey,
          () => _RepoData(
            owner: owner,
            name: name,
            url: repoUrl,
            id: repoId,
            repoData: repoData, // Store full repository metadata
            count: 0,
          ),
        );

        // Accumulate commit count for this repo on this date
        contributionsByDate[dateKey]![repoKey]!.count += commitCount;
      }
    }

    // PHASE 2: Create events for each date
    // Now we have contributions grouped by date, create one event per date
    for (final dateEntry in contributionsByDate.entries) {
      final date = _parseDateKey(dateEntry.key);
      final reposForDate = dateEntry.value;

      // Count total commits across all repositories for this date
      int totalCommits = 0;
      for (final repoData in reposForDate.values) {
        totalCommits += repoData.count;
      }

      // Get first repository for display header (already has all data, no lookup needed)
      final firstRepo = reposForDate.values.first;

      // Build repository info list for commit card display
      // All repo data (owner, name, url, id, full metadata) already stored - no lookups needed
      final repoInfos = <CommitRepositoryInfo>[];
      for (final repoData in reposForDate.values) {
        repoInfos.add(
          CommitRepositoryInfo(
            owner: repoData.owner,
            name: repoData.name,
            url: repoData.url,
            id: repoData.id, // Store ID for future UI use (navigation, etc.)
            count: repoData.count,
            repoData: repoData
                .repoData, // Preserve full repository metadata from GraphQL
          ),
        );
      }

      // Create unified commit data model for the card widget
      final commitData = CommitCardDataModel(
        count: totalCommits,
        date: date,
        repositories: repoInfos,
      );

      // Create timeline event for this date
      events.add(
        ActivityTimelineEvent(
          type: ActivityEventType.commit,
          date: date,
          repositoryOwner: firstRepo.owner,
          repositoryName: firstRepo.name,
          repositoryUrl:
              firstRepo.url, // Already stored in first loop, no lookup needed
          commitData: commitData,
          // Commits are aggregated, so no single GraphQL node to store
        ),
      );
    }

    return events;
  }

  /// Get date key in YYYY-MM-DD format
  static String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Parse date key back to DateTime (start of day)
  static DateTime _parseDateKey(String dateKey) {
    final parts = dateKey.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}
