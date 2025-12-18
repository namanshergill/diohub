import 'package:diohub/common/search_overlay/filters.dart';
import 'package:diohub/common/search_overlay/search_overlay.dart';
import 'package:diohub/common/wrappers/search_scroll_wrapper.dart';
import 'package:flutter/material.dart';

class UserRepositories extends StatelessWidget {
  const UserRepositories(
    this.login, {
    this.currentUser = false,
    super.key,
  });
  final String login;
  final bool? currentUser;

  @override
  Widget build(final BuildContext context) => SearchScrollWrapper(
        SearchData(
          searchFilters: SearchFilters.repositories(
            blacklist: <String>[
              SearchQueryStrings.user,
              SearchQueryStrings.org,
            ],
          ),
          defaultHiddenFilters: <String>[
            SearchQueries().user.toQueryString(login),
          ],
        ),
        quickFilters: <String, String>{
          SearchQueries().iS.toQueryString('public'): 'Public',
          SearchQueries().iS.toQueryString('private'): 'Private',
          SearchQueries().archived.toQueryString('true'): 'Archived',
          SearchQueries().mirror.toQueryString('true'): 'Mirrors',
        },
        quickOptions: <String, String>{
          SearchQueries().fork.toQueryString('true'): 'Include forks',
        },
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        searchBarMessage: "Search in $login's repositories",
        searchHeroTag: '${login}Search',
        // nonSearchFuture: (pageNumber, pageSize, refresh, _, sort, order) {
        //   if (currentUser!)
        //     return UserInfoService.getCurrentUserRepos(
        //         pageSize, pageNumber, refresh,
        //         sort: sort, ascending: order);
        //   return UserInfoService.getUserRepos(
        //       userInfoModel.login, pageSize, pageNumber, refresh, sort);
        // },
      );
}
