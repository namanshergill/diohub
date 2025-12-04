import 'package:diohub/common/bottom_sheet/url_actions.dart';
import 'package:diohub/common/misc/collapsible_detail_tiles.dart';
import 'package:diohub/common/misc/detail_tile.dart';
import 'package:diohub/common/misc/detail_tile_content.dart';
import 'package:diohub/models/users/user_info_model.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:flutter/material.dart';

class AboutUser extends StatelessWidget {
  const AboutUser(this.userInfoModel, {super.key});
  final UserInfoModel? userInfoModel;

  List<Widget> _buildAlwaysVisibleTiles(BuildContext context) {
    final tiles = <Widget>[];

    if (userInfoModel!.bio != null) {
      tiles.add(
        DetailTile(
          title: 'Bio',
          child: DetailTileText(userInfoModel!.bio!),
        ),
      );
    }

    if (userInfoModel!.location != null) {
      tiles.add(
        DetailTile(
          title: 'Location',
          child: DetailTileText(userInfoModel!.location!),
        ),
      );
    }

    if (userInfoModel!.company != null) {
      tiles.add(
        DetailTile(
          title: 'Company',
          child: DetailTileText(userInfoModel!.company!),
        ),
      );
    }

    if (userInfoModel!.createdAt != null) {
      tiles.add(
        DetailTile(
          title: 'Joined',
          child: DetailTileText(
            getDate(
              userInfoModel!.createdAt.toString(),
              shorten: false,
            ),
          ),
        ),
      );
    }

    return tiles;
  }

  List<Widget> _buildExpandableTiles(BuildContext context) {
    final tiles = <Widget>[];

    if (userInfoModel!.email != null) {
      tiles.add(
        DetailTile(
          title: 'Email',
          onTap: () async =>
              URLActions(uri: Uri.parse('mailto:${userInfoModel!.email}'))
                  .launchURL(),
          child: DetailTileText(userInfoModel!.email!),
        ),
      );
    }

    if (userInfoModel!.twitterUsername != null) {
      tiles.add(
        DetailTile(
          title: 'Twitter',
          onTap: () async => URLActions(
            uri: Uri.parse(
              'https://twitter.com/${userInfoModel!.twitterUsername}',
            ),
          ).launchURL(),
          child: DetailTileText('@${userInfoModel!.twitterUsername}'),
        ),
      );
    }

    if (userInfoModel!.blog?.isNotEmpty ?? false) {
      tiles.add(
        DetailTile(
          title: 'Blog',
          onTap: URLActions(uri: Uri.parse(userInfoModel!.blog!)).launchURL,
          child: DetailTileText(userInfoModel!.blog!),
        ),
      );
    }

    return tiles;
  }

  @override
  Widget build(BuildContext context) {
    if (userInfoModel == null) {
      return const SizedBox.shrink();
    }

    final alwaysVisibleTiles = _buildAlwaysVisibleTiles(context);
    final expandableTiles = _buildExpandableTiles(context);

    if (alwaysVisibleTiles.isEmpty && expandableTiles.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No information available'),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CollapsibleDetailTiles(
          alwaysVisibleTiles: alwaysVisibleTiles,
          expandableTiles: expandableTiles,
          visibilityConfig: DetailTilesVisibilityConfig.fixedCount(
            defaultVisibleCount: alwaysVisibleTiles.length.clamp(0, 3),
          ),
        ),
      ],
    );
  }
}
