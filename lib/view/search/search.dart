import 'package:auto_route/annotations.dart';
import 'package:diohub/common/animations/size_expanded_widget.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/misc/repository_card.dart';
import 'package:diohub/common/search_overlay/filters.dart';
import 'package:diohub/common/search_overlay/search_bar.dart';
import 'package:diohub/common/wrappers/api_wrapper_widget.dart';
import 'package:diohub/common/wrappers/search_scroll_wrapper.dart';
import 'package:diohub/models/repositories/repo_card_data_model.dart';
import 'package:diohub/models/repositories/repository_model.dart';
import 'package:diohub/providers/search_data_provider.dart';
import 'package:diohub/services/search/search_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

@RoutePage()
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  SearchScreenState createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(final BuildContext context) {
    super.build(context);
    final SearchDataProvider search = Provider.of<SearchDataProvider>(context);
    return search.searchData.searchFilters != null
        ? SearchScrollWrapper(
            search.searchData,
            key: ValueKey<String>(search.searchData.toQuery),
            onChanged: search.updateSearchData,
            // searchBarColor: Provider.of<PaletteSettings>(context).currentSetting.onBackground,
            searchHeroTag: 'searchScreen',
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          )
        : SizeExpandedSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Search GitHub',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium!
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: AppSearchBar(
                    // backgroundColor: Provider.of<PaletteSettings>(context)
                    //     .currentSetting
                    //     .primary,
                    heroTag: 'searchScreen',
                    onSubmit: search.updateSearchData,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Card(
                      // borderRadius: BorderRadius.vertical(
                      //   top: medBorderRadius.topRight,
                      // ),
                      // color: Provider.of<PaletteSettings>(context)
                      //     .currentSetting
                      //     .primary,
                      child: APIWrapper<List<RepositoryModel>>.deferred(
                        apiCall: ({required final bool refresh}) async =>
                            SearchService.searchRepos(
                          SearchQueries().pushed.toQueryString(
                                '>${DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 7)))}',
                              ),
                          page: 1,
                          perPage: 25,
                        ),
                        loadingBuilder: (final BuildContext context) =>
                            const Padding(
                          padding: EdgeInsets.all(48),
                          child: LoadingIndicator(),
                        ),
                        builder: (
                          final BuildContext context,
                          final List<RepositoryModel> data,
                        ) =>
                            SizeExpandedSection(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemBuilder: (
                                final BuildContext context,
                                final int index,
                              ) =>
                                  Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  if (index == 0)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 16,
                                            left: 24,
                                            right: 16,
                                            bottom: 8,
                                          ),
                                          child: Text(
                                            'Trending Repositories',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge,
                                          ),
                                        ),
                                        // Divider(
                                        //   height: 0,
                                        // ),
                                      ],
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: RepositoryCard(
                                      RepoCardDataModel.fromRepositoryModel(
                                        data[index],
                                      ),
                                      // isThemed: false,
                                      // padding: const EdgeInsets.symmetric(
                                      //   horizontal: 8,
                                      // ),
                                    ),
                                  ),
                                ],
                              ),
                              separatorBuilder: (
                                final BuildContext context,
                                final int index,
                              ) =>
                                  const Divider(),
                              itemCount: data.length,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}
