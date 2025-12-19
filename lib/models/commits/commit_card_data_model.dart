import 'package:diohub/models/repositories/repo_card_data_model.dart';

/// Unified data model for CommitCard
/// Note: Uses CreatedCommitContribution which provides commitCount per day
/// Individual commit details can be fetched on-demand
class CommitCardDataModel {
  const CommitCardDataModel({
    required this.count,
    required this.date,
    required this.repositories,
  });

  /// Total commit count for this day
  final int count;

  /// Date of the commits
  final DateTime date;

  /// List of repositories with their commit counts
  final List<CommitRepositoryInfo> repositories;

  /// Total number of repositories
  int get repositoryCount => repositories.length;

  /// Primary repository (first one, used for display)
  CommitRepositoryInfo? get primaryRepository =>
      repositories.isNotEmpty ? repositories.first : null;
}

/// Repository information for commit contributions
class CommitRepositoryInfo {
  const CommitRepositoryInfo({
    required this.owner,
    required this.name,
    required this.url,
    required this.count,
    this.id,
    this.repoData, // Full repository metadata from GraphQL
  });

  final String owner;
  final String name;
  final String url;
  final int count; // Commit count for this repository on this date
  final String? id; // Repository ID from GraphQL (for future use)
  final RepoCardDataModel? repoData; // Full repository metadata preserved from GraphQL
}

