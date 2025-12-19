import 'package:diohub/common/events/cards/base_card.dart';
import 'package:diohub/common/misc/repository_card.dart';
import 'package:diohub/models/repositories/repo_card_data_model.dart';
import 'package:flutter/material.dart';

/// Card widget for displaying repository creation in timeline using BaseEventCard pattern
class TimelineRepositoryCard extends StatelessWidget {
  const TimelineRepositoryCard({
    required this.repoData,
    required this.userLogin,
    required this.userAvatarUrl,
    required this.date,
    super.key,
  });

  final RepoCardDataModel repoData;
  final String userLogin;
  final String? userAvatarUrl;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return BaseEventCard.singular(
      isInTimeline: true,
      eventType: null, // RepositoryCard handles its own styling
      actor: userLogin,
      avatarUrl: userAvatarUrl,
      date: date,
      useNestedCard: false,
      headerText: [
        const TextSpan(
          text: 'created ',
        ),
        TextSpan(
          text: repoData.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
      child: RepoCardLoading(
        repoData.url,
        repoData.name,
        refresh: false,
      ),
    );
  }
}
