import 'package:diohub/graphql/queries/users/__generated__/user_activity_timeline_full.data.gql.dart';
import 'package:diohub/models/issues/issue_model.dart';
import 'package:diohub/models/pull_requests/pull_request_model.dart';
import 'package:diohub/models/repositories/repo_card_data_model.dart';
import 'package:diohub/models/users/user_info_model.dart';

// Helper to safely access fragment fields that may not be in generated type yet
T? _getFieldSafely<T>(dynamic obj, String fieldName) {
  try {
    return (obj as dynamic)[fieldName] as T?;
  } catch (_) {
    return null;
  }
}

/// Unified data model for PullRequestCard that works with both REST and GraphQL
class PullRequestCardDataModel {
  const PullRequestCardDataModel({
    required this.title,
    required this.number,
    required this.state,
    required this.url,
    required this.repositoryOwner,
    required this.repositoryName,
    required this.repositoryUrl,
    this.body,
    this.bodyHtml,
    this.merged,
    this.mergedAt,
    this.createdAt,
    this.updatedAt,
    this.closedAt,
    this.author,
    this.labels,
    this.assignees,
    this.additions,
    this.deletions,
    this.changedFiles,
    this.repositoryData,
  });

  final String title;
  final int number;
  final String state; // OPEN, CLOSED, MERGED
  final String url;
  final String repositoryOwner;
  final String repositoryName;
  final String repositoryUrl;
  final String? body;
  final String? bodyHtml; // HTML body from GraphQL
  final bool? merged;
  final DateTime? mergedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? closedAt;
  final UserInfoModel? author; // Author from GraphQL
  final List<Label>? labels; // Labels from GraphQL
  final List<UserInfoModel>? assignees; // Assignees from GraphQL
  final int? additions; // Lines added from GraphQL
  final int? deletions; // Lines deleted from GraphQL
  final int? changedFiles; // Files changed from GraphQL
  final RepoCardDataModel?
      repositoryData; // Full repository metadata from GraphQL

  /// Get action string for display
  String get action {
    if (merged == true) return 'merged';
    if (state == 'CLOSED') return 'closed';
    return 'opened';
  }

  /// Construct from REST PullRequestModel
  factory PullRequestCardDataModel.fromPullRequestModel(
    PullRequestModel pr,
  ) {
    // Extract repo from URL
    String repoOwner = '';
    String repoName = '';
    String repoUrl = '';

    if (pr.url != null) {
      final parts =
          pr.url!.replaceAll('https://api.github.com/repos/', '').split('/');
      if (parts.length >= 2) {
        repoOwner = parts[0];
        repoName = parts[1];
        repoUrl = 'https://github.com/$repoOwner/$repoName';
      }
    }

    // Extract repository data if available
    RepoCardDataModel? repositoryData;
    // Create basic repo data from extracted info
    try {
      repositoryData = RepoCardDataModel(
        name: repoName,
        url: repoUrl,
        description: null, // Not available in PullRequestModel
        language: null, // Not available in PullRequestModel
      );
    } catch (_) {
      // If conversion fails, repositoryData stays null
    }

    return PullRequestCardDataModel(
      title: pr.title ?? '',
      number: pr.number ?? 0,
      state: pr.state == IssueState.OPEN
          ? 'OPEN'
          : (pr.merged == true ? 'MERGED' : 'CLOSED'),
      url: pr.htmlUrl ?? pr.url ?? '',
      repositoryOwner: repoOwner,
      repositoryName: repoName,
      repositoryUrl: repoUrl,
      body: pr.body,
      bodyHtml: pr.bodyHtml, // Preserve HTML body
      merged: pr.merged,
      mergedAt: pr.mergedAt,
      createdAt: pr.createdAt,
      updatedAt: pr.updatedAt,
      closedAt: pr.closedAt, // Preserve closedAt
      author: pr.user, // Preserve author
      labels: pr.labels, // Preserve labels
      assignees: pr.assignees, // Preserve assignees
      additions: pr.additions, // Preserve additions
      deletions: pr.deletions, // Preserve deletions
      changedFiles: pr.changedFiles, // Preserve changedFiles
      repositoryData: repositoryData, // Preserve repository data
    );
  }

  /// Construct from GraphQL timeline PR type
  /// Extracts all available fields from GraphQL to preserve all metadata
  factory PullRequestCardDataModel.fromGraphQL(
    GuserActivityTimelineFullData_user_pullRequests_edges_node pr,
  ) {
    // Extract author - use dynamic access since fragment fields may not be in generated type yet
    UserInfoModel? author;
    try {
      final authorField = (pr as dynamic).author;
      if (authorField != null) {
        author = UserInfoModel(
          login: (authorField as dynamic).login as String?,
          avatarUrl: (authorField as dynamic).avatarUrl?.toString(),
        );
      }
    } catch (_) {
      // Field not available yet, will be after code regeneration
    }

    // Extract labels - use dynamic access
    List<Label>? labels;
    try {
      final labelsField = (pr as dynamic).labels;
      if (labelsField?.nodes != null) {
        final nodes = (labelsField.nodes as List?)?.whereType();
        labels = nodes
            ?.map((label) => Label(
                  name: (label as dynamic).name as String? ?? '',
                  color: (label as dynamic).color as String?,
                ))
            .toList();
      }
    } catch (_) {
      // Field not available yet, will be after code regeneration
    }

    // Extract assignees - use dynamic access
    List<UserInfoModel>? assignees;
    try {
      final assigneesField = (pr as dynamic).assignees;
      if (assigneesField?.edges != null) {
        final edges = (assigneesField.edges as List?)?.whereType();
        assignees = edges
            ?.map((edge) => (edge as dynamic).node)
            .whereType()
            .map((user) => UserInfoModel(
                  login: (user as dynamic).login as String?,
                  avatarUrl: (user as dynamic).avatarUrl?.toString(),
                ))
            .toList();
      }
    } catch (_) {
      // Field not available yet, will be after code regeneration
    }

    // Extract repository data using fromGraphQL to preserve all metadata
    RepoCardDataModel? repositoryData;
    try {
      // The repository in pullInfo fragment uses repoInfo which doesn't have all fields
      // But we can still create a basic RepoCardDataModel
      repositoryData = RepoCardDataModel(
        name: pr.repository.name,
        url: pr.repository.url.toString(),
        description: null, // Not in repoInfo fragment
        language: null, // Not in repoInfo fragment
      );
    } catch (_) {
      // If conversion fails, repositoryData stays null
    }

    return PullRequestCardDataModel(
      title: pr.title,
      number: pr.number,
      state: pr.state.name, // Convert enum to String
      url: pr.url.toString(),
      repositoryOwner: pr.repository.owner.login,
      repositoryName: pr.repository.name,
      repositoryUrl: pr.repository.url.toString(),
      body: pr.body,
      bodyHtml: _getFieldSafely<String?>(pr, 'bodyHTML'), // Extract HTML body
      merged: pr.merged,
      mergedAt: pr.mergedAt,
      createdAt: pr.createdAt,
      updatedAt: pr.updatedAt,
      closedAt: _getFieldSafely<DateTime?>(pr, 'closedAt'), // Extract closedAt
      author: author,
      labels: labels,
      assignees: assignees,
      additions: _getFieldSafely<int?>(pr, 'additions'), // Extract additions
      deletions: _getFieldSafely<int?>(pr, 'deletions'), // Extract deletions
      changedFiles:
          _getFieldSafely<int?>(pr, 'changedFiles'), // Extract changedFiles
      repositoryData: repositoryData,
    );
  }
}
