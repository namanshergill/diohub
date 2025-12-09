import 'package:diohub/common/issues/nested_issue_card.dart';
import 'package:diohub/common/misc/profile_card.dart';
import 'package:diohub/common/misc/repository_card.dart';
import 'package:diohub/common/misc/round_button.dart';
import 'package:diohub/common/search_overlay/filters.dart';
import 'package:diohub/common/search_overlay/search_bar.dart';
import 'package:diohub/common/search_overlay/search_overlay.dart';
import 'package:diohub/common/wrappers/infinite_scroll_wrapper.dart';
import 'package:diohub/models/issues/issue_model.dart';
import 'package:diohub/models/repositories/repository_model.dart' hide Type;
import 'package:diohub/models/users/user_info_model.dart';
import 'package:diohub/services/search/search_service.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scroll_to_top/flutter_scroll_to_top.dart';
//
// typedef SearchScrollWrapperFuture<T> = Future Function(({
//       int pageNumber,
//       int pageSize,
//       bool refresh,
//       T? lastItem,
//       String? sort,
//       bool? isAscending
//     }) data);

typedef WrapperReplacementBuilder = Widget Function(
  SearchData searchData,
  Widget Function(BuildContext context, VoidCallback function) header,
  Widget child,
);

class SearchScrollWrapper extends StatefulWidget {
  SearchScrollWrapper(
    this.searchData, {
    required this.searchHeroTag,
    this.searchBarMessage,
    this.quickFilters,
    this.replacementBuilder,
    this.quickOptions,
    final EdgeInsets? searchBarPadding,
    this.onChanged,
    this.searchBarColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
    this.filterFn,
    this.showRepoNameOnIssues = true,
    super.key,
  }) : _searchBarPadding = searchBarPadding ?? padding.copyWith(top: 8);

  /// Search Data this search wrapper would be attached to.
  final SearchData searchData;

  /// Filter function for the search results.
  final FilterFn? filterFn;

  /// Message to show on the search bar.
  final String? searchBarMessage;

  /// Hero tag of the search bar.
  final String searchHeroTag;

  /// Padding of wrapper.
  final EdgeInsets padding;
  final EdgeInsets _searchBarPadding;

  /// Background color of the search bar.
  final Color? searchBarColor;

  /// Quick filters to be shown in the search bar in a dropdown.
  final Map<String, String>? quickFilters;

  /// Quick options to be shown in the search bar as a checkbox.
  final Map<String, String>? quickOptions;

  /// Replacement builder if search data is empty.
  final WrapperReplacementBuilder? replacementBuilder;

  /// Callback for when search data is changed.
  final ValueChanged<SearchData>? onChanged;

  final bool showRepoNameOnIssues;
  @override
  SearchScrollWrapperState createState() => SearchScrollWrapperState();
}

class SearchScrollWrapperState extends State<SearchScrollWrapper> {
  late SearchData searchData;

  @override
  void initState() {
    searchData = widget.searchData;
    super.initState();
  }

  bool searchBarHidden = false;
  Size? size;
  InfiniteScrollWrapperController controller =
      InfiniteScrollWrapperController();

  @override
  Widget build(final BuildContext context) {
    Widget header(final BuildContext context, final VoidCallback? function) =>
        Padding(
          padding:
              function != null ? EdgeInsets.zero : widget._searchBarPadding,
          child: AppSearchBar(
            heroTag: widget.searchHeroTag,
            quickFilters: widget.quickFilters,
            quickOptions: widget.quickOptions,
            searchData: searchData,
            isPinned: function != null,
            trailing: function != null
                ? RoundButton(
                    icon: const Icon(
                      Icons.keyboard_arrow_up_rounded,
                      // size: 15,
                      // color: context.palette.accent,
                    ),
                    padding: const EdgeInsets.all(4),
                    // color: context.palette.elementsOnColors,
                    onPressed: function,
                  )
                : null,
            prompt: widget.searchBarMessage,
            backgroundColor:
                widget.searchBarColor ?? context.colorScheme.background,
            onSubmit: (final SearchData data) {
              setState(() {
                searchData = data;
              });
              widget.onChanged?.call(data);

              controller.refresh();
            },
          ),
        );

    final Widget child = Builder(
      builder: (final BuildContext context) {
        if (searchData.searchFilters!.searchType == SearchType.repositories) {
          return _InfiniteWrapper<RepositoryModel>(
            controller: controller,
            searchData: searchData,
            filterFn: widget.filterFn,
            searchFuture: (
              data,
            ) async =>
                SearchService.searchRepos(
              searchData.toQuery,
              perPage: data.pageSize,
              page: data.pageNumber,
              sort: searchData.getSort,
              ascending: searchData.isSortAsc,
              refresh: data.refresh,
            ),
            header: (final BuildContext context) => header(context, null),
            pinnedHeader: searchData.isActive ? header : null,
            builder: (
              final BuildContext context,
              final data,
            ) =>
                Padding(
              padding: widget.padding,
              child: RepositoryCard(
                data.item,
                // padding: EdgeInsets.zero,
              ),
            ),
          );
        } else if (searchData.searchFilters!.searchType ==
            SearchType.issuesPulls) {
          return _InfiniteWrapper<IssueModel>(
            filterFn: widget.filterFn,
            controller: controller,
            searchData: searchData,
            searchFuture: (
              data,
            ) async =>
                SearchService.searchIssues(
              searchData.toQuery,
              perPage: data.pageSize,
              page: data.pageNumber,
              sort: searchData.getSort,
              ascending: searchData.isSortAsc,
              refresh: data.refresh,
            ),
            header: (final BuildContext context) => header(context, null),
            pinnedHeader: searchData.isActive ? header : null,
            builder: (
              final BuildContext context,
              final data,
            ) =>
                NestedIssueCard(
              data.item,
              showRepoName: widget.showRepoNameOnIssues,
            ),
          );
        } else if (searchData.searchFilters!.searchType == SearchType.users) {
          return _InfiniteWrapper<UserInfoModel>(
            filterFn: widget.filterFn,
            controller: controller,
            searchData: searchData,
            header: (final BuildContext context) => header(context, null),
            pinnedHeader: searchData.isActive ? header : null,
            searchFuture: (
              data,
            ) async =>
                SearchService.searchUsers(
              searchData.toQuery,
              perPage: data.pageSize,
              page: data.pageNumber,
              sort: searchData.getSort,
              ascending: searchData.isSortAsc,
              refresh: data.refresh,
            ),
            builder: (
              final BuildContext context,
              data,
            ) =>
                Row(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: widget.padding,
                    child: ProfileCard(
                      data.item,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return Container();
      },
    );
    if (widget.replacementBuilder != null) {
      return widget.replacementBuilder!(searchData, header, child);
    }
    return child;
  }
}

class _InfiniteWrapper<T> extends StatelessWidget {
  const _InfiniteWrapper({
    required this.builder,
    required this.header,
    required this.controller,
    required this.searchFuture,
    required this.searchData,
    this.filterFn,
    this.pinnedHeader,
    super.key,
  });

  final InfiniteScrollWrapperController controller;
  final WidgetBuilder header;
  final ScrollWrapperFuture<T> searchFuture;
  final ScrollWrapperBuilder<T> builder;
  final SearchData searchData;
  final FilterFn? filterFn;
  final ReplacementBuilder? pinnedHeader;

  @override
  Widget build(final BuildContext context) => InfiniteScrollWrapper<T>(
        pageSize: 20,
        controller: controller,
        header: header,
        filterFn: filterFn,
        future: searchFuture,
        paginationKey: ValueKey<String>(
          searchData.toQuery + searchData.isActive.toString() + searchData.sort,
        ),
        separatorBuilder: (final BuildContext context, final int index) =>
            const SizedBox(
          height: 4,
        ),
        pinnedHeader: pinnedHeader,
        shrinkWrap: true,
        builder: builder,
      );
}
