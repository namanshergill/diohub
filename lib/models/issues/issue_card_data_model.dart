import 'package:diohub/graphql/queries/users/__generated__/user_activity_timeline_full.data.gql.dart';
import 'package:diohub/models/issues/issue_model.dart';

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
    this.commentCount,
    this.createdAt,
    this.updatedAt,
  });

  final String title;
  final int number;
  final String state; // OPEN, CLOSED
  final String url;
  final String repositoryOwner;
  final String repositoryName;
  final String repositoryUrl;
  final String? body;
  final int? commentCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

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

    return IssueCardDataModel(
      title: issue.title ?? '',
      number: issue.number ?? 0,
      state: issue.state == IssueState.OPEN ? 'OPEN' : 'CLOSED',
      url: issue.htmlUrl ?? issue.url ?? '',
      repositoryOwner: repoOwner,
      repositoryName: repoName,
      repositoryUrl: repoUrl,
      body: issue.body,
      commentCount: issue.comments,
      createdAt: issue.createdAt,
      updatedAt: issue.updatedAt,
    );
  }

  /// Construct from GraphQL timeline issue type
  factory IssueCardDataModel.fromGraphQL(
    GuserActivityTimelineFullData_user_issues_edges_node issue,
  ) {
    return IssueCardDataModel(
      title: issue.title,
      number: issue.number,
      state: issue.state.name, // Convert enum to String
      url: issue.url.toString(),
      repositoryOwner: issue.repository.owner.login,
      repositoryName: issue.repository.name,
      repositoryUrl: issue.repository.url.toString(),
      body: issue.body,
      commentCount: issue.comments.totalCount,
      createdAt: issue.createdAt,
      updatedAt: issue.updatedAt,
    );
  }
}

