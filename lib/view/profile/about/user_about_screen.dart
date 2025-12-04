import 'package:diohub/common/misc/info_card.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/misc/repository_card.dart';
import 'package:diohub/common/misc/shimmer_widget.dart';
import 'package:diohub/common/wrappers/api_wrapper_widget.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_info.data.gql.dart';
import 'package:diohub/models/repositories/repository_model.dart';
import 'package:diohub/models/users/user_info_model.dart';
import 'package:diohub/services/users/user_info_service.dart';
import 'package:diohub/utils/to_hex_string.dart';
import 'package:diohub/view/profile/about/about_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// About screen that includes user details, contribution graph, and pinned repos
class UserAboutScreen extends StatelessWidget {
  const UserAboutScreen(this.userInfoModel, {super.key});

  final UserInfoModel? userInfoModel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // User details (bio, location, company, etc.)
        AboutUser(userInfoModel),
        const SizedBox(height: 16),

        // Contribution Graph
        if (userInfoModel?.login != null)
          InfoCard(
            title: 'Contribution Graph',
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.network(
                    'http://ghchart.rshah.org/${toHexString(Theme.of(context).colorScheme.primary).substring(2)}/${userInfoModel!.login}',
                    placeholderBuilder: (final BuildContext context) =>
                        ShimmerWidget.container(
                      height: 60,
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Pinned Repositories
        APIWrapper<List<GgetUserPinnedReposData_user_pinnedItems_edges?>>(
          apiCall: ({required final bool refresh}) async =>
              UserInfoService.getUserPinnedRepos(
            userInfoModel!.login!,
          ),
          builder: (
            final BuildContext context,
            final APISnapshot<
                    List<GgetUserPinnedReposData_user_pinnedItems_edges?>>
                snapshot,
          ) =>
              InfoCard.children(
            title: 'Pinned Repositories',
            children: snapshot.on(
              loaded: (
                final APISnapshotLoaded<
                        List<GgetUserPinnedReposData_user_pinnedItems_edges?>>
                    snapshot,
              ) =>
                  snapshot.data.isEmpty
                      ? <Widget>[
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No pinned repositories.'),
                          ),
                        ]
                      : List<Widget>.generate(
                          snapshot.data.length,
                          (final int index) {
                            final GgetUserPinnedReposData_user_pinnedItems_edges_node__asRepository
                                node = snapshot.data[index]!.node!.when(
                              repository: (value) => value,
                              orElse: () => throw UnimplementedError(),
                            );
                            return RepositoryCard(
                              RepositoryModel(
                                stargazersCount: node.stargazerCount,
                                description: node.description,
                                language: node.languages!.edges!.isNotEmpty
                                    ? node.languages?.edges?.first!.node.name ??
                                        'N/A'
                                    : 'N/A',
                                owner: Owner(login: node.owner.login),
                                name: node.name,
                                private: false,
                                url: node.url.toString().replaceFirst(
                                      'https://github.com',
                                      'https://api.github.com/repos',
                                    ),
                                updatedAt: node.updatedAt,
                              ),
                            );
                          },
                        ),
              loading: (final APISnapshotLoading<
                          List<
                              GgetUserPinnedReposData_user_pinnedItems_edges?>>
                      snapshot) =>
                  <Widget>[
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: LoadingIndicator(),
                ),
              ],
              error: (final APISnapshotError<
                          List<
                              GgetUserPinnedReposData_user_pinnedItems_edges?>>
                      snapshot) =>
                  <Widget>[snapshot.defaultErrorWidget()],
            ),
          ),
        ),
      ],
    );
  }
}

