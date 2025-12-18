import 'package:diohub/common/events/cards/base_card.dart';
import 'package:diohub/common/pulls/simple_pull_card.dart';
import 'package:diohub/models/events/events_model.dart' hide Key;
import 'package:flutter/material.dart';

class PullEventCard extends StatelessWidget {
  const PullEventCard(this.event, {super.key, required this.isInTimeline});
  final EventsModel event;
  final bool isInTimeline;

  @override
  Widget build(final BuildContext context) => BaseEventCard.singular(
        isInTimeline: isInTimeline,
        // useNestedCard: false,
        eventType: event.type,
        actor: event.actor!.login,
        // childPadding: EdgeInsets.zero,
        headerText: <TextSpan>[
          TextSpan(text: '${event.payload!.action} a pull request in '),
          TextSpan(
            text: event.repo!.name,
          ),
        ],
        userLogin: event.actor!.login,
        date: event.createdAt,
        avatarUrl: event.actor!.avatarUrl,
        child: SimplePullLoadingCard(
          event.payload!.pullRequest!.url!,
          showRepoName: true,
        ),
      );
}
