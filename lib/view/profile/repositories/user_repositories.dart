import 'package:diohub/common/search_overlay/filters.dart';
import 'package:diohub/common/search_overlay/search_overlay.dart';
import 'package:diohub/common/wrappers/search_scroll_wrapper.dart';
import 'package:flutter/material.dart';

class UserRepositories extends StatelessWidget {
  const UserRepositories(
    this.login, {
    this.currentUser = false,
    this.isOrganization = false,
    super.key,
  });
  final String login;
  final bool? currentUser;

  /// Organization repositories are filtered with the `org:` search qualifier
  /// instead of `user:`. Both work for organizations today, but `org:` is the
  /// documented qualifier and behaves consistently for private repositories
  /// the token can see.
  final bool isOrganization;

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
            isOrganization
                ? SearchQueries().org.toQueryString(login)
                : SearchQueries().user.toQueryString(login),
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
      );
}
