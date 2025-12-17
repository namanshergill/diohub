import 'package:diohub/common/misc/profile_banner.dart';
import 'package:diohub/graphql/queries/repositories/__generated__/repo_info.data.gql.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dynamic_tabs/flutter_dynamic_tabs.dart';
import 'package:diohub/view/repository/widgets/repository_detail_tiles.dart';
import 'package:diohub/view/repository/widgets/repository_stats.dart';
import 'package:diohub/view/repository/widgets/repository_action_buttons.dart';
import 'package:diohub/view/repository/widgets/tab_state.dart';

/// Builds the collapsed header for the repository screen
Widget buildCollapsedHeader(
  BuildContext context,
  GrepositoryInfoData_repository repo,
) {
  return Row(
    children: <Widget>[
      ProfileTile.avatar(
        avatarUrl: repo.owner.when(
          user: (u) => u.avatarUrl.toString(),
          organization: (o) => o.avatarUrl.toString(),
          orElse: () => null,
        ),
        userLogin: repo.owner.when(
          user: (u) => u.login,
          organization: (o) => o.login,
          orElse: () => null,
        ),
        size: 20,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text.rich(
          TextSpan(
            style: context.textTheme.bodyLarge,
            children: <InlineSpan>[
              TextSpan(
                text: '${repo.owner.when(
                  user: (u) => u.login,
                  organization: (o) => o.login,
                  orElse: () => '',
                )}/',
              ),
              TextSpan(
                text: repo.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

/// Builds the expanded header for the repository screen
Widget buildExpandedHeader(
  BuildContext context,
  GrepositoryInfoData_repository repo,
  ValueNotifier<String> activeTabNotifier,
  DynamicTabsController tabController,
  AnimationController expandAnimationController,
) {
  const double leadingWidth =
      56.0; // Standard Material Design back button width
  return ValueListenableBuilder<String>(
    valueListenable: activeTabNotifier,
    builder: (context, currentTab, _) {
      final tabState = TabState(currentTab: currentTab);
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Repo name
            Padding(
              padding: EdgeInsets.only(left: leadingWidth),
              child: Text(
                repo.name!,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            // Detail tiles section
            buildDetailTilesSection(
              context,
              repo,
              tabController,
              expandAnimationController,
            ),
            const SizedBox(height: 16),
            // Description and Stats section
            buildDescriptionAndStats(context, repo),
            const SizedBox(height: 16),
            // Action buttons (includes expand button)
            buildActionButtons(
              context,
              repo,
              tabState,
              tabController,
              expandAnimationController: expandAnimationController,
            ),
          ],
        ),
      );
    },
  );
}
