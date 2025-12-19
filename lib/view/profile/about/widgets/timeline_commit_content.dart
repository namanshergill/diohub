import 'package:diohub/common/misc/repository_card.dart';
import 'package:diohub/models/commits/commit_card_data_model.dart';
import 'package:diohub/models/repositories/repo_card_data_model.dart';
import 'package:flutter/material.dart';

/// Card content for commit events in timeline
/// Shows repository cards with commit counts for each repo
class TimelineCommitContent extends StatelessWidget {
  const TimelineCommitContent({
    required this.commitData,
    required this.userLogin,
    this.userEmail,
    super.key,
  });

  final CommitCardDataModel commitData;
  final String userLogin;
  final String? userEmail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Show repository cards for each repo
        ...commitData.repositories.map((repoInfo) {
          // Use existing repoData if available, otherwise create from basic info
          final repoCardData = repoInfo.repoData ??
              RepoCardDataModel(
                name: repoInfo.name,
                url: repoInfo.url,
              );

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RepositoryCard(
              repoCardData,
              contributionCount: repoInfo.count, // Commit count for this date
              withBackground: true, // Use background for card styling
            ),
          );
        }),
      ],
    );
  }
}
