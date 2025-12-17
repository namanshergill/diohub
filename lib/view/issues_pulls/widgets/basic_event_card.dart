import 'package:cached_network_image/cached_network_image.dart';
import 'package:diohub/common/issues/issue_label.dart';
import 'package:diohub/common/misc/nested_card_with_header.dart';
import 'package:diohub/common/misc/shimmer_widget.dart';
import 'package:diohub/graphql/queries/issues_pulls/__generated__/timeline.data.gql.dart';
import 'package:diohub/models/events/events_model.dart' hide Key;
import 'package:diohub/models/issues/issue_timeline_event_model.dart';
import 'package:diohub/models/users/user_info_model.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

class BasicEventCard extends StatelessWidget {
  const BasicEventCard({
    required this.user,
    required this.content,
    required this.date,
    required this.leading,
    required this.headerText,
    this.iconColor,
    super.key,
  });
  final Gactor? user;
  final IconData leading;
  final Color? iconColor;
  final DateTime date;
  final Widget content;
  final List<TextSpan> headerText;
  @override
  Widget build(final BuildContext context) {
    final Color effectiveIconColor =
        iconColor ?? context.colorScheme.onSurfaceVariant;

    final Widget headerRow = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        // Icon in colored container like BaseEventCard
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: effectiveIconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            leading,
            size: 12,
            color: effectiveIconColor,
          ),
        ),
        const SizedBox(width: 6),
        // Actor avatar
        if (user?.avatarUrl != null)
          ClipOval(
            child: CachedNetworkImage(
              imageUrl: user!.avatarUrl.toString(),
              width: 18,
              height: 18,
              fit: BoxFit.cover,
              placeholder: (context, url) => ShimmerWidget(
                child: Container(
                  width: 18,
                  height: 18,
                  color: context.colorScheme.surfaceVariant,
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: 18,
                height: 18,
                color: context.colorScheme.surfaceVariant,
                child: Icon(
                  Icons.person,
                  size: 10,
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        if (user?.avatarUrl != null) const SizedBox(width: 4),
        // Actor name and action text
        Flexible(
          child: Text.rich(
            TextSpan(
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: context.colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 12,
                  ),
              children: <TextSpan>[
                if (user?.login != null)
                  TextSpan(
                    text: user!.login,
                  ),
                if (user?.login != null) const TextSpan(text: ' '),
                ...headerText,
              ],
            ),
          ),
        ),
      ],
    );

    return NestedCardWithHeader(
      header: headerRow,
      trailing: Text(
        getDate(date.toString()),
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colorScheme.onSurfaceVariant.withOpacity(0.7),
          fontSize: 11,
        ),
      ),
      headerPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      childPadding: const EdgeInsets.all(8),
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.bodyMedium!.asHint(),
        child: content,
      ),
    );
  }
}

class BasicEventTextCard extends StatelessWidget {
  const BasicEventTextCard({
    required this.user,
    required this.textContent,
    required this.date,
    required this.leading,
    this.footer,
    this.iconColor,
    super.key,
  });
  final Gactor? user;
  final IconData leading;
  final Color? iconColor;
  final DateTime date;
  final Widget? footer;
  final String textContent;
  @override
  Widget build(final BuildContext context) => BasicEventCard(
        iconColor: iconColor,
        headerText: <TextSpan>[
          TextSpan(text: textContent),
        ],
        content: footer != null
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: footer!,
              )
            : const SizedBox.shrink(),
        date: date,
        user: user,
        leading: leading,
      );
}

class BasicEventAssignedCard extends StatelessWidget {
  const BasicEventAssignedCard({
    required this.actor,
    required this.assignee,
    required this.createdAt,
    required this.isAssigned,
    super.key,
  });
  final Gactor? actor;
  final Gactor? assignee;
  final DateTime createdAt;
  final bool isAssigned;
  @override
  Widget build(final BuildContext context) => BasicEventCard(
        headerText: <TextSpan>[
          TextSpan(text: isAssigned ? 'Assigned' : 'Unassigned'),
          if (actor?.login != null && actor?.login != assignee?.login) ...[
            const TextSpan(text: ' '),
            TextSpan(
              text: assignee?.login ?? 'themselves',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ] else
            const TextSpan(text: ' themselves'),
          TextSpan(text: ' ${isAssigned ? 'to' : 'from'} the issue.'),
        ],
        content: const SizedBox.shrink(),
        date: createdAt,
        user: actor,
        leading: MdiIcons.account,
      );
}

class BasicEventLabeledCard extends StatelessWidget {
  const BasicEventLabeledCard({
    required this.actor,
    required this.content,
    required this.added,
    required this.date,
    // this.iconColor,
    super.key,
  });
  final Gactor? actor;
  // final Color? iconColor;
  final DateTime date;
  final Glabel content;
  final bool added;
  @override
  Widget build(final BuildContext context) => BasicEventCard(
        headerText: <TextSpan>[
          TextSpan(text: '${added ? 'Added' : 'Removed'} the '),
          TextSpan(text: 'label ${added ? 'to' : 'from'} this.'),
        ],
        content: IssueLabel.gql(content),
        user: actor,
        date: date,
        leading: added ? Icons.label_rounded : Icons.label_off_rounded,
      );
}

class BasicIssueCrossReferencedCard extends StatelessWidget {
  const BasicIssueCrossReferencedCard({
    required this.date,
    this.user,
    this.content,
    this.leading,
    this.iconColor,
    super.key,
  });
  final UserInfoModel? user;
  final IconData? leading;
  final Color? iconColor;
  final DateTime date;
  final Source? content;
  // final String _correctRepo;

  // GitHub API sends the wrong links to the issue where the reference was in.
  // This is here to fix them.
  // Ref: https://github.com/NamanShergill/diohub/issues/7
  // String fixURL(String url) {
  //   final components = url.split('/');
  //   components[4] = _correctRepo.split('/').first;
  //   components[5] = _correctRepo.split('/').last;
  //   return components.join('/');
  // }

  @override
  Widget build(final BuildContext context) {
    return Container();
    // return BasicEventCard(
    //   iconColor: iconColor,
    //   content: Column(
    //     mainAxisSize: MainAxisSize.min,
    //     crossAxisAlignment: CrossAxisAlignment.start,
    //     children: [
    //       const Text(
    //         'Mentioned this.',
    //         style: AppThemeTextStyles.basicIssueEventCardText,
    //       ),
    //       IssueListCard(
    //         content!.issue!.copyWith(
    //             url: fixURL(content!.issue!.url!),
    //             repositoryUrl: fixURL(content!.issue!.repositoryUrl!),
    //             labelsUrl: fixURL(content!.issue!.labelsUrl!),
    //             commentsUrl: fixURL(content!.issue!.commentsUrl!),
    //             eventsUrl: fixURL(content!.issue!.eventsUrl!)),
    //         compact: true,
    //         padding: const EdgeInsets.only(top: 8),
    //       ),
    //     ],
    //   ),
    //   date: date,
    //   // user: user,
    //   leading: leading,
    // );
  }
}

class BasicEventCommitCard extends StatelessWidget {
  const BasicEventCommitCard({
    required this.date,
    this.user,
    this.sha,
    this.commitURL,
    this.message,
    this.leading,
    this.iconColor,
    super.key,
  });
  final Author? user;
  final IconData? leading;
  final Color? iconColor;
  final DateTime date;
  final String? sha;
  final String? message;
  final String? commitURL;
  @override
  Widget build(final BuildContext context) {
    return Container();
    // return BasicEventCard(
    //   iconColor: iconColor,
    //   user : user,
    //   content: Column(
    //     mainAxisSize: MainAxisSize.min,
    //     crossAxisAlignment: CrossAxisAlignment.start,
    //     children: [
    //       Text(
    //         'Added commit.',
    //         style: AppThemeTextStyles.basicIssueEventCardText
    //             .copyWith(fontWeight: FontWeight.bold),
    //       ),
    //       const SizedBox(
    //         height: 4,
    //       ),
    //       Text(
    //         message!,
    //         style: AppThemeTextStyles.basicIssueEventCardText,
    //       ),
    //       const SizedBox(
    //         height: 8,
    //       ),
    //       CommitSHAButton(sha, commitURL),
    //     ],
    //   ),
    //   date: date,
    //   name: user!.name,
    //   leading: leading,
    // );
  }
}
