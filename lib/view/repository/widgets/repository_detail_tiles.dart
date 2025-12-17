import 'package:diohub/common/misc/collapsible_detail_tiles.dart';
import 'package:diohub/common/misc/detail_tile.dart';
import 'package:diohub/common/misc/detail_tile_content.dart';
import 'package:diohub/graphql/queries/repositories/__generated__/repo_info.data.gql.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/common/misc/profile_banner.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dynamic_tabs/flutter_dynamic_tabs.dart';

/// Builds the detail tiles section for the repository header
Widget buildDetailTilesSection(
  BuildContext context,
  GrepositoryInfoData_repository repo,
  DynamicTabsController tabController,
  AnimationController expandAnimationController,
) {
  // Always visible tiles (essential information)
  final List<Widget> alwaysVisibleTiles = [];

  // Owner
  final ownerLogin = repo.owner.when(
    user: (u) => u.login,
    organization: (o) => o.login,
    orElse: () => null,
  );
  final ownerAvatarUrl = repo.owner.when(
    user: (u) => u.avatarUrl.toString(),
    organization: (o) => o.avatarUrl.toString(),
    orElse: () => null,
  );
  if (ownerLogin != null) {
    alwaysVisibleTiles.add(
      DetailTile(
        title: 'Owner',
        actionType: DetailTileActionType.navigation,
        onTap: () {
          navigateToProfile(
            login: ownerLogin,
            context: context,
          );
        },
        child: DetailTileUser(
          avatarUrl: ownerAvatarUrl ?? '',
          login: ownerLogin,
        ),
      ),
    );
  }

  // Language
  if (repo.primaryLanguage != null) {
    alwaysVisibleTiles.add(
      DetailTile(
        title: 'Language',
        actionType: DetailTileActionType.tab,
        onTap: () => tabController.openTab('Code'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: repo.primaryLanguage?.color != null
                    ? Color(int.parse(
                        repo.primaryLanguage!.color!.replaceFirst('#', '0xFF')))
                    : const Color(0xFF878787),
                shape: BoxShape.circle,
              ),
              height: 12,
              width: 12,
            ),
            const SizedBox(width: 6),
            DetailTileText(repo.primaryLanguage?.name ?? ''),
          ],
        ),
      ),
    );
  }

  // Created date
  if (repo.createdAt != null) {
    alwaysVisibleTiles.add(
      DetailTile(
        title: 'Created',
        child: DetailTileText(
          getDate(repo.createdAt!.toIso8601String(), shorten: false),
        ),
      ),
    );
  }

  // Expandable tiles (less relevant information)
  final List<Widget> expandableTiles = [];

  // License
  if (repo.licenseInfo != null) {
    expandableTiles.add(
      DetailTile(
        title: 'License',
        child: DetailTileText(repo.licenseInfo!.name ?? 'Unknown'),
      ),
    );
  }

  // Stats (Open Issues, Forks, Watchers)
  expandableTiles.add(
    DetailTile(
      title: 'Stats',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailTileText('${repo.issues.totalCount} open issues'),
          const SizedBox(height: 4),
          DetailTileText('${repo.forkCount} forks'),
          const SizedBox(height: 4),
          DetailTileText('${repo.watchers.totalCount} watchers'),
        ],
      ),
    ),
  );

  return CollapsibleDetailTiles(
    alwaysVisibleTiles: alwaysVisibleTiles,
    expandableTiles: expandableTiles,
    visibilityConfig: DetailTilesVisibilityConfig.fixedCount(
      defaultVisibleCount:
          3, // Show 3 tiles by default (Owner, Language, Created)
    ),
    onExpandChanged: (isExpanded) {
      if (isExpanded) {
        expandAnimationController.forward();
      } else {
        expandAnimationController.reverse();
      }
    },
  );
}
