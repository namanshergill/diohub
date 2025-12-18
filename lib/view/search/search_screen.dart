import 'package:auto_route/annotations.dart';
import 'package:diohub/common/search_overlay/filters.dart';
import 'package:diohub/common/search_overlay/search_overlay.dart';
import 'package:diohub/common/wrappers/infinite_scroll_wrapper.dart';
import 'package:diohub/common/wrappers/search_scroll_wrapper.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_info.data.gql.dart';
import 'package:diohub/models/issues/issue_model.dart';
import 'package:diohub/providers/users/current_user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class SearchScreen extends StatefulWidget {
  const SearchScreen({
    required this.initialSearchData,
    super.key,
  });

  final SearchData initialSearchData;

  @override
  SearchScreenState createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  late SearchData searchData;

  @override
  void initState() {
    super.initState();
    searchData = widget.initialSearchData;
  }

  @override
  Widget build(BuildContext context) {
    final GviewerInfoData_viewer user =
        Provider.of<CurrentUserProvider>(context).data;

    // Determine search type and configure accordingly
    final SearchType searchType = searchData.searchFilters?.searchType ??
        SearchType.issuesPulls;

    // Build quick filters based on search type
    Map<String, String>? quickFilters;
    Map<String, String>? quickOptions;
    FilterFn? filterFn;

    if (searchType == SearchType.issuesPulls) {
      quickFilters = <String, String>{
        SearchQueries().assignee.toQueryString(user.login): 'Assigned',
        SearchQueries().author.toQueryString(user.login): 'Created',
        SearchQueries().mentions.toQueryString(user.login): 'Mentioned',
      };
      quickOptions = <String, String>{
        SearchQueries().iS.toQueryString('open'): 'Open Only',
      };
      filterFn = (final List<dynamic> data) {
        final List<IssueModel> filteredData = <IssueModel>[];
        for (final IssueModel item in data) {
          if (item.pullRequest == null) {
            filteredData.add(item);
          }
        }
        return filteredData;
      };
    }

    // Ensure searchFilters is set
    SearchData finalSearchData = searchData;
    if (finalSearchData.searchFilters == null) {
      finalSearchData = finalSearchData.copyWith(
        searchFilters: SearchFilters.issuesPulls(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: SearchScrollWrapper(
        finalSearchData,
        quickFilters: quickFilters,
        quickOptions: quickOptions,
        searchBarMessage: 'Search ${searchTypeValues.reverse![searchType]}',
        searchHeroTag: 'search_screen_${user.login}',
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        filterFn: filterFn,
        onChanged: (SearchData newSearchData) {
          setState(() {
            searchData = newSearchData;
          });
        },
      ),
    );
  }
}

