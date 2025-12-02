import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/events/cards/base_card.dart';
import 'package:diohub/common/misc/branch_label.dart';
import 'package:diohub/common/misc/custom_expansion_tile.dart';
import 'package:diohub/common/misc/ink_pot.dart';
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
            text: ' pushed to ',
            // style: AppThemeTextStyles.eventCardHeaderMed(context),
          ),
          TextSpan(
            text: event.repo!.name,
            // style: AppThemeTextStyles.eventCardHeaderBold(context),
          ),
        ],
        avatarUrl: event.actor!.avatarUrl,
        child: CustomExpansionTile(
          expanded: false,
          title: Row(
            children: <Widget>[
              Text(
                '${data.size ?? 0} commit${(data.size ?? 0) > 1 ? 's' : ''} to',
                // style: AppThemeTextStyles.eventCardChildTitleSmall(context),
              ),
              Flexible(
                child: BranchLabel(
                  data.ref?.split('/').last ?? '',
                ),
              ),
            ],
          ),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: (data.commits ?? []).isEmpty
                    ? [const SizedBox.shrink()]
                    : List.generate(
                        (data.commits ?? []).length,
                        (final int index) {
                          final commit = (data.commits ?? [])[index];
                          return InkPot(
                    onTap: () async {
                      if (commit.url != null) {
                        await AutoRouter.of(context).push(
                          CommitInfoRoute(
                            commitURL: commit.url!,
                          ),
                        );
                      }
                    },
                    onLongPress: () async {
                      if (data.ref != null && event.repo?.url != null) {
                        await AutoRouter.of(context).push(
                          RepositoryRoute(
                            index: 2,
                            branch: data.ref!.split('/').last,
                            repositoryURL: event.repo!.url!,
                            initSHA: commit.sha,
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      child: Text.rich(
                        TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium,
                          children: <InlineSpan>[
                            if (commit.sha != null)
                              TextSpan(
                                text:
                                    '#${commit.sha!.substring(0, commit.sha!.length > 6 ? 6 : commit.sha!.length)}',
                                style: TextStyle(
                                  color: context.colorScheme.primary,
                                ),
                              ),
                            if (commit.message != null)
                              TextSpan(text: '  ${commit.message}'),
                          ],
                        ),
                      ),
                    ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      );
}
