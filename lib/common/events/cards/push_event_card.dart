import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/events/cards/base_card.dart';
import 'package:diohub/common/misc/branch_label.dart';
import 'package:diohub/models/events/events_model.dart' hide Key;
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

class PushEventCard extends StatelessWidget {
  const PushEventCard(this.event, this.data,
      {super.key, required this.isInTimeline});

  final EventsModel event;
  final Payload data;
  final bool isInTimeline;

  @override
  Widget build(final BuildContext context) => BaseEventCard.singular(
        isInTimeline: isInTimeline,
        eventType: event.type,
        onTap: () async {
          if (event.repo?.url != null && data.ref != null) {
            await AutoRouter.of(context).push(
              RepositoryRoute(
                repositoryURL: event.repo!.url!,
                branch: data.ref!.split('/').last,
                index: 2,
              ),
            );
          }
        },
        userLogin: event.actor!.login,
        date: event.createdAt,
        actor: event.actor!.login,
        headerText: <TextSpan>[
          const TextSpan(
            text: 'pushed to ',
            // style: AppThemeTextStyles.eventCardHeaderMed(context),
          ),
          TextSpan(
            text: event.repo!.name,
            // style: AppThemeTextStyles.eventCardHeaderBold(context),
          ),
        ],
        avatarUrl: event.actor!.avatarUrl,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: <Widget>[
              Text(
                'Branch: ',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
              ),
              Flexible(
                child: BranchLabel(
                  data.ref?.split('/').last ?? '',
                ),
              ),
            ],
          ),
        ),
      );
}
