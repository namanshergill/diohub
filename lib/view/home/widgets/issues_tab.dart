import 'package:diohub/adapters/deep_linking_handler.dart';
import 'package:diohub/common/search_overlay/filters.dart';
import 'package:diohub/common/search_overlay/search_overlay.dart';
import 'package:diohub/common/wrappers/search_scroll_wrapper.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_info.data.gql.dart';
import 'package:diohub/models/issues/issue_model.dart';
import 'package:diohub/providers/users/current_user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class IssuesTab extends StatefulWidget {
  const IssuesTab({
    this.deepLinkData,
    this.searchWrapperKey,
    this.onButtonDataReady,
    super.key,
  });

  final PathData? deepLinkData;
  final GlobalKey<SearchScrollWrapperState>? searchWrapperKey;
  final void Function(SearchScrollWrapperButtonData)? onButtonDataReady;

  @override
  IssuesTabState createState() => IssuesTabState();
}

class IssuesTabState extends State<IssuesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(final BuildContext context) {
    super.build(context);
    final GviewerInfoData_viewer user =
        Provider.of<CurrentUserProvider>(context).data;
    return SearchScrollWrapper(
      SearchData(
        searchFilters: SearchFilters.issuesPulls(
          blacklist: <String>[SearchQueryStrings.type],
        ),
        defaultHiddenFilters: <String>[
          SearchQueries().involves.toQueryString(user.login),
          SearchQueries().type.toQueryString('issue'),
        ],
        filterStrings: <String>[
          if (widget.deepLinkData?.component(1) == 'assigned')
            SearchQueries().assignee.toQueryString(user.login),
          if (widget.deepLinkData?.component(1) == 'mentioned')
            SearchQueries().mentions.toQueryString(user.login),
        ],
      ),
      quickFilters: <String, String>{
        SearchQueries().assignee.toQueryString(user.login): 'Assigned',
        SearchQueries().author.toQueryString(user.login): 'Created',
        SearchQueries().mentions.toQueryString(user.login): 'Mentioned',
      },
      quickOptions: <String, String>{
        SearchQueries().iS.toQueryString('open'): 'Open Only',
      },
      searchBarMessage: 'Search in your issues',
      searchHeroTag: '${user.login}issueSearch',
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      key: widget.searchWrapperKey,
      onButtonDataReady: widget.onButtonDataReady,
      filterFn: (final List<dynamic> data) {
        final List<IssueModel> filteredData = <IssueModel>[];
        for (final IssueModel item in data) {
          if (item.pullRequest == null) {
            filteredData.add(item);
          }
        }
        return filteredData;
      },
      // nonSearchFuture: (pageNumber, pageSize, refresh, _, sort, isAsc) {
      //   return IssuesService.getUserIssues(
      //       pageNumber: pageNumber,
      //       perPage: pageSize,
      //       refresh: refresh,
      //       ascending: isAsc,
      //       sort: sort);
      // },
    );
  }
}
