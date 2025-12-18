import 'package:diohub/common/animations/size_expanded_widget.dart';
import 'package:diohub/common/misc/info_card.dart';
import 'package:diohub/common/misc/repository_card.dart';
import 'package:diohub/common/misc/shimmer_widget.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_info.data.gql.dart';
import 'package:diohub/models/repositories/repo_card_data_model.dart';
import 'package:diohub/models/users/user_info_model.dart';
import 'package:diohub/utils/to_hex_string.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UserOverviewScreen extends StatelessWidget {
  const UserOverviewScreen(
    this.userInfoModel, {
    this.followInfoData,
    super.key,
  });

  final UserInfoModel? userInfoModel;
  final GfollowStatusInfoData_user? followInfoData;

  @override
  Widget build(final BuildContext context) => ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: <Widget>[
          if (followInfoData != null) ...[
            Builder(
              builder: (final BuildContext context) {
                final pinnedItems =
                    followInfoData!.pinnedItems?.edges?.toList() ??
                        <GfollowStatusInfoData_user_pinnedItems_edges?>[];
                if (pinnedItems.isEmpty) {
                  return InfoCard.children(
                    title: 'Pinned Repos',
                    children: const <Widget>[
                      Text('No Pinned items.'),
                    ],
                  );
                }
                return InfoCard.children(
                  title: 'Pinned Repos',
                  children: List<Widget>.generate(
                    pinnedItems.length,
                    (final int index) {
                      final node = pinnedItems[index]?.node?.when(
                            repository: (value) => value,
                            orElse: () => null,
                          );
                      if (node == null) {
                        return const SizedBox.shrink();
                      }
                      return SizeExpandedSection(
                        child: RepositoryCard(
                          RepoCardDataModel.fromGraphQL(node),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
          const SizedBox(
            height: 8,
          ),
          InfoCard(
            title: 'Contribution Graph',
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SvgPicture.network(
                    'http://ghchart.rshah.org/${toHexString(Theme.of(context).colorScheme.primary).substring(2)}/${userInfoModel!.login}',
                    placeholderBuilder: (final BuildContext context) =>
                        ShimmerWidget.container(
                      height: 60,
                    ),
                  ),
                  // Row(
                  //   children: [
                  //     LinkText(
                  //       'https://ghchart.rshah.org/',
                  //       style: TextStyle(color: faded3(context)),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
          ),
//             WrappedCollection(
//               children: <Widget>[
// ,
// ,
//               ],
//             ),
        ],
      );
}
