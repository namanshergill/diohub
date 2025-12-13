import 'package:diohub/common/search_overlay/filters.dart';
import 'package:diohub/common/search_overlay/search_overlay.dart';
import 'package:diohub/common/wrappers/search_scroll_wrapper.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_info.data.gql.dart';
import 'package:diohub/providers/repository/repository_provider.dart';
import 'package:diohub/providers/users/current_user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PullsList extends StatelessWidget {
  const PullsList({super.key});

  @override
  Widget build(final BuildContext context) {
    final RepositoryProvider repo = Provider.of<RepositoryProvider>(context);
    final GviewerInfoData_viewer user =
        Provider.of<CurrentUserProvider>(context).data;

    return SearchScrollWrapper(
      SearchData(
        searchFilters: SearchFilters.issuesPulls(
          blacklist: <String>[SearchQueryStrings.type],
        ),
        defaultHiddenFilters: <String>[
          SearchQueries().type.toQueryString('pr'),
          SearchQueries().repo.toQueryString(repo.data.nameWithOwner),
        ],
      ),
      showRepoNameOnIssues: false,

      quickFilters: <String, String>{
        SearchQueries().assignee.toQueryString(user.login!): 'Assigned to you',
        SearchQueries().author.toQueryString(user.login!): 'Your pull requests',
        SearchQueries().mentions.toQueryString(user.login!): 'Mentions you',
      },
      quickOptions: <String, String>{
        SearchQueries().iS.toQueryString('open'): 'Open pull requests only',
      },
      searchBarPadding: const EdgeInsets.only(top: 8, left: 8, right: 8),
      searchBarMessage: "Search in ${repo.data.name}'s pull requests",
      searchHeroTag: 'repoPRSearch',
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      // replacementBuilder: (SearchData data, header, child) {
      //   if (data.getSort != null || data.isActive) return child;
      //   return InfiniteScrollWrapper<PullRequestModel>(
      //     future: (pageNumber, pageSize, refresh, _) {
      //       return PullsService.getRepoPulls(
      //           Provider.of<RepositoryProvider>(context, listen: false)
      //               .repositoryModel!
      //               .url,
      //           pageNumber: pageNumber,
      //           perPage: pageSize,
      //           refresh: refresh);
      //     },
      //     header: (context) => Padding(
      //         padding: EdgeInsets.only(top: 8), child: header(context, null)),
      //     scrollController: scrollController,
      //     isNestedScrollViewChild: true,
      //     divider: false,
      //     spacing: 4,
      //     topSpacing: 0,
      //     shrinkWrap: true,
      //     builder: (context, item, index) {
      //       return Padding(
      //         padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      //         child: PullListCard(
      //           item,
      //           padding: EdgeInsets.zero,
      //           showRepoName: false,
      //         ),
      //       );
      //     },
      //   );
      // },
    );
  }
}
