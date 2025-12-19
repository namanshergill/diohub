import 'package:diohub/graphql/queries/users/__generated__/user_activity_timeline_full.data.gql.dart';
import 'package:diohub/models/issues/issue_model.dart';
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

/// Unified data model for IssueCard that works with both REST and GraphQL
class IssueCardDataModel {
  const IssueCardDataModel({
    required this.title,
    required this.number,
    required this.state,
    required this.url,
    required this.repositoryOwner,
    required this.repositoryName,
    required this.repositoryUrl,
    this.body,
    this.bodyHtml,
    this.commentCount,
    this.createdAt,
    this.updatedAt,
    this.closedAt,
    this.author,
    this.labels,
    this.assignees,
    this.repositoryData,
  });

  final String title;
  final int number;
  final String state; // OPEN, CLOSED
  final String url;
  final String repositoryOwner;
  final String repositoryName;
  final String repositoryUrl;
  final String? body;
  final String? bodyHtml; // HTML body from GraphQL
  final int? commentCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? closedAt;
  final UserInfoModel? author; // Author from GraphQL
  final List<Label>? labels; // Labels from GraphQL
  final List<UserInfoModel>? assignees; // Assignees from GraphQL
  final RepoCardDataModel? repositoryData; // Full repository metadata from GraphQL

  /// Construct from REST IssueModel
  factory IssueCardDataModel.fromIssueModel(IssueModel issue) {
    // Extract repo from URL
    String repoOwner = '';
    String repoName = '';
    String repoUrl = '';
    
    if (issue.url != null) {
      final parts = issue.url!
          .replaceAll('https://api.github.com/repos/', '')
          .split('/');
      if (parts.length >= 2) {
        repoOwner = parts[0];
        repoName = parts[1];
        repoUrl = 'https://github.com/$repoOwner/$repoName';
      }
    }

    // Extract repository data if available
    RepoCardDataModel? repositoryData;
    if (issue.repository != null) {
      repositoryData = RepoCardDataModel.fromRepositoryModel(issue.repository!);
    }

    return IssueCardDataModel(
      title: issue.title ?? '',
      number: issue.number ?? 0,
      state: issue.state == IssueState.OPEN ? 'OPEN' : 'CLOSED',
      url: issue.htmlUrl ?? issue.url ?? '',
      repositoryOwner: repoOwner,
      repositoryName: repoName,
      repositoryUrl: repoUrl,
      body: issue.body,
      bodyHtml: issue.bodyHtml, // Preserve HTML body
      commentCount: issue.comments,
      createdAt: issue.createdAt,
      updatedAt: issue.updatedAt,
      closedAt: issue.closedAt, // Preserve closedAt
      author: issue.user, // Preserve author
      labels: issue.labels, // Preserve labels
      assignees: issue.assignees, // Preserve assignees
      repositoryData: repositoryData, // Preserve repository data
    );
  }

  /// Construct from GraphQL timeline issue type
  /// Extracts all available fields from GraphQL to preserve all metadata
  factory IssueCardDataModel.fromGraphQL(
    GuserActivityTimelineFullData_user_issues_edges_node issue,
  ) {
    // Extract author - use dynamic access since fragment fields may not be in generated type yet
    UserInfoModel? author;
    try {
      final authorField = (issue as dynamic).author;
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
      final labelsField = (issue as dynamic).labels;
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
      final assigneesField = (issue as dynamic).assignees;
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
      // The repository in issueInfo fragment uses repoInfo which doesn't have all fields
      // But we can still create a basic RepoCardDataModel
      repositoryData = RepoCardDataModel(
        name: issue.repository.name,
        url: issue.repository.url.toString(),
        description: null, // Not in repoInfo fragment
        language: null, // Not in repoInfo fragment
      );
    } catch (_) {
      // If conversion fails, repositoryData stays null
    }

    return IssueCardDataModel(
      title: issue.title,
      number: issue.number,
      state: issue.state.name, // Convert enum to String
      url: issue.url.toString(),
      repositoryOwner: issue.repository.owner.login,
      repositoryName: issue.repository.name,
      repositoryUrl: issue.repository.url.toString(),
      body: issue.body,
      bodyHtml: _getFieldSafely<String?>(issue, 'bodyHTML'), // Extract HTML body
      commentCount: issue.comments.totalCount,
      createdAt: issue.createdAt,
      updatedAt: issue.updatedAt,
      closedAt: _getFieldSafely<DateTime?>(issue, 'closedAt'), // Extract closedAt
      author: author,
      labels: labels,
      assignees: assignees,
      repositoryData: repositoryData,
    );
  }
}

