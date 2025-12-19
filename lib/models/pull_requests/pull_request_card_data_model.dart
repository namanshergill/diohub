import 'package:diohub/graphql/queries/users/__generated__/user_activity_timeline_full.data.gql.dart';
import 'package:diohub/models/issues/issue_model.dart';
import 'package:diohub/models/pull_requests/pull_request_model.dart';

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
    this.merged,
    this.mergedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String title;
  final int number;
  final String state; // OPEN, CLOSED, MERGED
  final String url;
  final String repositoryOwner;
  final String repositoryName;
  final String repositoryUrl;
  final String? body;
  final bool? merged;
  final DateTime? mergedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
      final parts = pr.url!
          .replaceAll('https://api.github.com/repos/', '')
          .split('/');
      if (parts.length >= 2) {
        repoOwner = parts[0];
        repoName = parts[1];
        repoUrl = 'https://github.com/$repoOwner/$repoName';
      }
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
      merged: pr.merged,
      mergedAt: pr.mergedAt,
      createdAt: pr.createdAt,
      updatedAt: pr.updatedAt,
    );
  }

  /// Construct from GraphQL timeline PR type
  factory PullRequestCardDataModel.fromGraphQL(
    GuserActivityTimelineFullData_user_pullRequests_edges_node pr,
  ) {
    return PullRequestCardDataModel(
      title: pr.title,
      number: pr.number,
      state: pr.state.name, // Convert enum to String
      url: pr.url.toString(),
      repositoryOwner: pr.repository.owner.login,
      repositoryName: pr.repository.name,
      repositoryUrl: pr.repository.url.toString(),
      body: pr.body,
      merged: pr.merged,
      mergedAt: pr.mergedAt,
      createdAt: pr.createdAt,
      updatedAt: pr.updatedAt,
    );
  }
}

