import 'package:diohub/common/misc/nested_card_with_header.dart';
import 'package:diohub/common/misc/repository_card.dart';
import 'package:diohub/common/misc/shimmer_widget.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_info.data.gql.dart';
import 'package:diohub/models/repositories/repo_card_data_model.dart';
import 'package:diohub/utils/to_hex_string.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// About screen that includes user details, contribution graph, and pinned repos
class UserAboutScreen extends StatelessWidget {
  const UserAboutScreen(
    this.userData, {
    super.key,
  });

  final GuserInfoData_user userData;

  @override
  Widget build(BuildContext context) {
    final pinnedItems = userData.pinnedItems.edges?.toList() ??
        <GuserInfoData_user_pinnedItems_edges?>[];

    final List<Widget> children = [];

    // Contribution Graph
    children.add(
      NestedCardWithHeader(
        header: Text(
          'Contribution Graph',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SvgPicture.network(
                'http://ghchart.rshah.org/${toHexString(Theme.of(context).colorScheme.primary).substring(2)}/${userData.login}',
                placeholderBuilder: (final BuildContext context) =>
                    ShimmerWidget.container(
                  height: 60,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Pinned Repositories
    if (pinnedItems.isNotEmpty) {
      children.add(
        const SizedBox(height: 8),
      );
      children.add(
        NestedCardWithHeader(
          header: Text(
            'Pinned Repositories',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List<Widget>.generate(
              pinnedItems.length,
              (final int index) {
                final node = pinnedItems[index]?.node;
                // Check if it's a repository by __typename and cast to GrepositoryFields
                if (node == null || node.G__typename != 'Repository') {
                  return const SizedBox.shrink();
                }
                final repo = node as GrepositoryFields;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < pinnedItems.length - 1 ? 12 : 0,
                  ),
                  child: RepositoryCard(
                    RepoCardDataModel.fromGraphQL(repo),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    if (children.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No content available.'),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: children,
    );
  }
}
