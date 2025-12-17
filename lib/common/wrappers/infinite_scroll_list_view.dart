import 'package:dio/dio.dart';
import 'package:diohub/app/global.dart';
import 'package:diohub/common/misc/button.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/wrappers/infinite_scroll_wrapper.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

/// A simplified wrapper for infinite pagination using ListView instead of CustomScrollView.
/// Designed for use in expandable action buttons and other constrained contexts.
/// [T] type is defined for the kind of elements to be displayed.
class InfiniteScrollListView<T> extends StatefulWidget {
  const InfiniteScrollListView({
    required this.future,
    required this.builder,
    super.key,
    this.controller,
    this.filterFn,
    this.paginationKey,
    this.separatorBuilder,
    this.pageNumber = 1,
    this.pageSize = 10,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
    this.disableScroll = false,
    this.disableRefresh = false,
    this.firstPageLoadingBuilder,
    this.scrollController,
    this.shrinkWrap = false,
    this.listEndIndicator = true,
  });

  /// How to display the data.
  final ScrollWrapperBuilder<T> builder;

  /// The future to fetch data to display from.
  final ScrollWrapperFuture<T> future;

  /// Total number of elements in each page. Default value is **10**.
  final int pageSize;

  /// Page Number to start with. Default value is **1**.
  final int pageNumber;

  final IndexedWidgetBuilder? separatorBuilder;

  /// Filter the results before displaying them.
  final FilterFn<T>? filterFn;

  /// A controller to call the refresh function if required.
  final InfiniteScrollWrapperController? controller;

  /// Spacing to add to the top of the list.
  final EdgeInsets padding;

  /// Show the list end indicator or not.
  final bool listEndIndicator;

  /// First page loading indicator.
  final WidgetBuilder? firstPageLoadingBuilder;

  /// ListView ScrollController.
  final ScrollController? scrollController;

  /// Disable refreshing.
  final bool disableRefresh;

  /// Disable scrolling.
  final bool disableScroll;

  final bool shrinkWrap;

  /// [Key] to give the infinite scroll wrapper to force it to rebuild the list
  /// on new data.
  final Key? paginationKey;

  @override
  InfiniteScrollListViewState<T> createState() =>
      InfiniteScrollListViewState<T>();
}

class InfiniteScrollListViewState<T> extends State<InfiniteScrollListView<T>> {
  late InfiniteScrollWrapperController controller;

  @override
  void initState() {
    controller = widget.controller ?? InfiniteScrollWrapperController();
    super.initState();
  }

  @override
  Widget build(final BuildContext context) {
    Widget listView() {
      final ScrollPhysics physics = widget.disableScroll
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics();

      return _InfinitePaginationListView<T>(
        future: widget.future,
        builder: widget.builder,
        controller: controller,
        key: widget.paginationKey,
        filterFn: widget.filterFn,
        firstPageLoadingBuilder: widget.firstPageLoadingBuilder,
        padding: widget.padding,
        pageNumber: widget.pageNumber,
        separatorBuilder: widget.separatorBuilder,
        pageSize: widget.pageSize,
        listEndIndicator: widget.listEndIndicator,
        scrollController: widget.scrollController,
        shrinkWrap: widget.shrinkWrap,
        physics: physics,
      );
    }

    Widget refreshIndicator() {
      if (!widget.disableRefresh) {
        return RefreshIndicator(
          onRefresh: () => Future<void>.sync(() async {
            controller.refresh();
          }),
          child: listView(),
        );
      } else {
        return listView();
      }
    }

    return refreshIndicator();
  }
}

class _InfinitePaginationListView<T> extends StatefulWidget {
  const _InfinitePaginationListView({
    required this.future,
    required this.builder,
    required this.filterFn,
    required this.controller,
    required this.firstPageLoadingBuilder,
    required this.pageNumber,
    required this.pageSize,
    required this.padding,
    required this.separatorBuilder,
    required this.listEndIndicator,
    required this.scrollController,
    required this.shrinkWrap,
    required this.physics,
    super.key,
  });

  final ScrollWrapperBuilder<T> builder;
  final ScrollWrapperFuture<T> future;
  final int pageSize;
  final int pageNumber;
  final EdgeInsets padding;
  final FilterFn<T>? filterFn;
  final InfiniteScrollWrapperController controller;
  final IndexedWidgetBuilder? separatorBuilder;
  final bool listEndIndicator;
  final WidgetBuilder? firstPageLoadingBuilder;
  final ScrollController? scrollController;
  final bool shrinkWrap;
  final ScrollPhysics physics;

  @override
  _InfinitePaginationListViewState<T> createState() =>
      _InfinitePaginationListViewState<T>();
}

class _InfinitePaginationListViewState<T>
    extends State<_InfinitePaginationListView<T>> {
  late final PagingController<int, _ListItem<T>> _pagingController;
  late int pageNumber;
  bool refresh = false;

  @override
  void initState() {
    super.initState();
    setupController();
    pageNumber = widget.pageNumber;
    _pagingController = PagingController<int, _ListItem<T>>(
      value: PagingState<int, _ListItem<T>>(
        hasNextPage: true,
      ),
      fetchPage: _fetchPage,
      getNextPageKey: (final PagingState<int, _ListItem<T>> state) {
        if (state.pages == null || state.pages!.isEmpty) {
          return 0;
        }
        if (state.lastPageIsEmpty) return null;
        return state.nextIntPageKey;
      },
    );
    _pagingController.fetchNextPage();
  }

  void setupController() {
    widget.controller.refresh = resetAndRefresh;
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  void resetAndRefresh() {
    refresh = true;
    pageNumber = widget.pageNumber;
    _pagingController.refresh();
  }

  Future<List<_ListItem<T>>> _fetchPage(final int pageKey) async {
    try {
      final int currentPageNumber = widget.pageNumber + pageKey;

      final List<T> newItems = await widget.future(
        ScrollWrapperFutureArguments<T>(
          pageNumber: currentPageNumber,
          pageSize: widget.pageSize,
          refresh: refresh,
          lastItem: (_pagingController.value.items?.isNotEmpty ?? false)
              ? _pagingController.value.items?.last.item
              : null,
        ),
      );

      List<T> filteredItems;
      if (widget.filterFn != null) {
        filteredItems = widget.filterFn!(newItems) ?? <T>[];
      } else {
        filteredItems = newItems;
      }

      if (filteredItems.length < widget.pageSize) {
        refresh = false;
      }

      return filteredItems
          .map((final T e) => _ListItem<T>(e, refresh: refresh))
          .toList();
    } on DioException catch (error, s) {
      log.e(error.response?.data, stackTrace: s);
      rethrow;
    } catch (error) {
      log.e(
        'Pagination exception',
        error: error,
      );
      rethrow;
    }
  }

  @override
  Widget build(final BuildContext context) =>
      ValueListenableBuilder<PagingState<int, _ListItem<T>>>(
        valueListenable: _pagingController,
        builder: (context, state, _) =>
            PagedListView<int, _ListItem<T>>.separated(
          state: state,
          
          fetchNextPage: _pagingController.fetchNextPage,
          scrollController: widget.scrollController,
          shrinkWrap: widget.shrinkWrap,
          physics: widget.physics,
          separatorBuilder:
              widget.separatorBuilder ?? (final _, final __) => Container(),
          builderDelegate: PagedChildBuilderDelegate<_ListItem<T>>(
            itemBuilder: (
              final BuildContext context,
              final _ListItem<T> item,
              final int index,
            ) {
              return Column(
                children: <Widget>[
                  if (index == 0)
                    SizedBox(
                      height: widget.padding.top,
                    ),
                  widget.builder(
                    context,
                    ScrollWrapperBuilderData<T>(
                      item: item.item,
                      index: index,
                      refresh: item.refreshChildren,
                      isCurrentlyLast: (state.items?.length ?? 0) - 1 == index,
                    ),
                  ),
                ],
              );
            },
            firstPageProgressIndicatorBuilder: widget.firstPageLoadingBuilder ??
                (final BuildContext context) => const Padding(
                      padding: EdgeInsets.all(32),
                      child: LoadingIndicator(),
                    ),
            newPageProgressIndicatorBuilder: (final BuildContext context) =>
                const Padding(
              padding: EdgeInsets.all(32),
              child: LoadingIndicator(),
            ),
            noItemsFoundIndicatorBuilder: (final BuildContext context) =>
                Center(
              child: Padding(
                padding: EdgeInsets.only(top: widget.padding.top),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Nothing to see here.',
                  ),
                ),
              ),
            ),
            noMoreItemsIndicatorBuilder: (final BuildContext context) =>
                widget.listEndIndicator
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: <Widget>[
                              Text(
                                '----*----',
                                style: context.textTheme.labelSmall?.asHint(),
                              ),
                              SizedBox(
                                height: widget.padding.bottom,
                              ),
                            ],
                          ),
                        ),
                      )
                    : Padding(
                        padding: EdgeInsets.only(bottom: widget.padding.bottom),
                        child: Container(),
                      ),
            firstPageErrorIndicatorBuilder: (final BuildContext context) =>
                _FirstPageErrorIndicator(
              onTryAgain: () => _pagingController.refresh(),
              error: state.error,
            ),
          ),
        ),
      );
}

class _ListItem<T> {
  _ListItem(this.item, {required this.refresh});

  final T item;
  bool refresh;

  bool get refreshChildren {
    final bool temp = refresh;
    refresh = false;
    return temp;
  }
}

class _FirstPageErrorIndicator extends StatelessWidget {
  const _FirstPageErrorIndicator({
    required this.error,
    this.onTryAgain,
  });

  final Object? error;
  final VoidCallback? onTryAgain;

  @override
  Widget build(final BuildContext context) => _FirstPageExceptionIndicator(
        title: 'Something went wrong',
        message: error is Error
            ? (error! as Error).stackTrace.toString()
            : error.toString(),
        onTryAgain: onTryAgain,
      );
}

class _FirstPageExceptionIndicator extends StatelessWidget {
  const _FirstPageExceptionIndicator({
    required this.title,
    this.message,
    this.onTryAgain,
    super.key,
  });

  final String title;
  final String? message;
  final VoidCallback? onTryAgain;

  @override
  Widget build(final BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 32,
          horizontal: 16,
        ),
        child: Button(
          onTap: onTryAgain,
          child: const Text(
            'Retry',
          ),
        ),
      ),
    );
  }
}
