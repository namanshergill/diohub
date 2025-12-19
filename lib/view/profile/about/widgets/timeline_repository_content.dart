import 'package:diohub/common/misc/repository_card.dart';
import 'package:diohub/models/repositories/repo_card_data_model.dart';
import 'package:flutter/material.dart';

/// Simple card content for repository creation events in timeline (no nested cards)
class TimelineRepositoryContent extends StatelessWidget {
  const TimelineRepositoryContent({
    required this.repoData,
    super.key,
  });

  final RepoCardDataModel repoData;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: RepoCardLoading(
        repoData.url,
        repoData.name,
        refresh: false,
      ),
    );
  }
}
