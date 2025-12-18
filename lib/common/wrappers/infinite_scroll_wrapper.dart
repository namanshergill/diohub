import 'package:dio/dio.dart';
import 'package:diohub/app/global.dart';
import 'package:diohub/common/misc/button.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/wrappers/scroll_to_top_wrapper.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scroll_to_top/flutter_scroll_to_top.dart';
import 'package:flutter_scroll_to_top/modified_scroll_view.dart' as scrollview;
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:sliver_tools/sliver_tools.dart';

/// Controller for [InfiniteScrollWrapper].
class InfiniteScrollWrapperController {
  late void Function() refresh;
}

class ScrollWrapperFutureArguments<T> {
  ScrollWrapperFutureArguments({
    required this.pageNumber,
    required this.pageSize,
    required this.refresh,
    required this.lastItem,
  });

  final int pageNumber;
  final int pageSize;
  final bool refresh;
  final T? lastItem;
}

class ScrollWrapperBuilderData<T> {
  ScrollWrapperBuilderData({
    required this.item,
    required this.index,
    required this.refresh,
    required this.isCurrentlyLast,
  });

  final T item;
  final int index;
  final bool refresh;
  final bool isCurrentlyLast;
}

typedef ScrollWrapperFuture<T> = Future<List<T>> Function(
  ScrollWrapperFutureArguments<T> data,
);
typedef ScrollWrapperBuilder<T> = Widget Function(
  BuildContext context,
  ScrollWrapperBuilderData<T> data,
);
typedef FilterFn<T> = Function(List<T> items);

/// A wrapper designed to show infinite pagination.
/// [T] type is defined for the kind of elements to be displayed.
class InfiniteScrollWrapper<T> extends StatefulWidget {
  const InfiniteScrollWrapper({
    required this.future,
    required this.builder,
    super.key,
    this.controller,
    // this.nestedScrollViewController,
    this.filterFn,
    this.paginationKey,
    this.separatorBuilder,
    this.header,
    this.pinnedHeader,
    this.showScrollToTopButton = true,
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

  /// How to display the data. Give
  final ScrollWrapperBuilder<T> builder;

  /// The future to fetch data to display from.
  /// Gives you the current [pageNumber] and [pageSize], in that order.
  final ScrollWrapperFuture<T> future;

  /// Total number of elements in each page. Default value is **10**.
  final int pageSize;

  /// Page Number to start with. Default value is **1**.
  final int pageNumber;

  final IndexedWidgetBuilder? separatorBuilder;

  /// Filter the results before displaying them.
  /// Gives the list of results that can be modified and returned.
  final FilterFn<T>? filterFn;

  /// A controller to call the refresh function if required.
  final InfiniteScrollWrapperController? controller;

  /// Spacing to add to the top of the list.
  final EdgeInsets padding;

  /// Show the list end indicator or not.
  final bool listEndIndicator;

  /// Header to show above the list.
  final WidgetBuilder? header;

  /// First page loading indicator.
  final WidgetBuilder? firstPageLoadingBuilder;

  /// ListView ScrollController.
  final ScrollController? scrollController;

  // final ScrollController? nestedScrollViewController;

  // Disable refreshing.
  final bool disableRefresh;

  /// Disable scrolling.
  final bool disableScroll;

  final bool shrinkWrap;

  /// Pinned header to show on scroll.
  final ReplacementBuilder? pinnedHeader;

  /// Show scroll to top button.
  final bool showScrollToTopButton;

  /// [Key] to give the infinite scroll wrapper to force it to rebuild the list
  /// on new data,
  final Key? paginationKey;

  @override
  InfiniteScrollWrapperState<T> createState() =>
      InfiniteScrollWrapperState<T>();
}

class InfiniteScrollWrapperState<T> extends State<InfiniteScrollWrapper<T>> {
  late InfiniteScrollWrapperController controller;

  @override
  void initState() {
    // scrollController =
    //     // widget.isNestedScrollViewChild
    //     //     ? null :
    //     widget.scrollController ?? ScrollController();
    controller = widget.controller ?? InfiniteScrollWrapperController();
    super.initState();
  }

  @override
  Widget build(final BuildContext context) {
    Widget scrollView(final ScrollViewProperties? properties) {
      final ScrollPhysics physics = widget.disableScroll
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics();
      final List<MultiSliver> slivers = <MultiSliver>[
        MultiSliver(
          children: <Widget>[
            if (widget.header != null)
              SliverToBoxAdapter(
                child: widget.header!(context),
              ),
            _InfinitePagination<T>(
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
            ),
          ],
        ),
      ];
      if (properties != null) {
        return scrollview.CustomScrollView(
          properties: properties,
          physics: physics,
          shrinkWrap: widget.shrinkWrap,
          slivers: slivers,
        );
      } else {
        return CustomScrollView(
          controller: widget.scrollController,
          shrinkWrap: widget.shrinkWrap,
          physics: physics,
          slivers: slivers,
        );
      }
    }

    Widget refreshIndicator({final ScrollViewProperties? properties}) {
      if (!widget.disableRefresh) {
        return RefreshIndicator(
          // color:
          //     Provider.of<PaletteSettings>(context).currentSetting.baseElements,
          onRefresh: () => Future<void>.sync(() async {
            controller.refresh();
          }),
          child: scrollView(properties),
        );
      } else {
        return scrollView(properties);
      }
    }

    Widget child() {
      if (widget.showScrollToTopButton) {
        return ScrollToTopWrapper(
          alwaysVisibleAtOffset: widget.pinnedHeader != null,
          scrollController: widget.scrollController,
          promptTheme: PromptButtonTheme(
            color: context.colorScheme.primary,
          ),
          promptReplacementBuilder: widget.pinnedHeader,
          builder: (
            final BuildContext context,
            final ScrollViewProperties properties,
          ) =>
              refreshIndicator(properties: properties),
        );
      } else {
        return refreshIndicator();
      }
    }

    return child();
  }
}

class _InfinitePagination<T> extends StatefulWidget {
  const _InfinitePagination({
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
    super.key,
  });

  /// How to display the data. Give
  final ScrollWrapperBuilder<T> builder;

  /// The future to fetch data to display from.
  /// Gives you the current [pageNumber] and [pageSize], in that order.
  final ScrollWrapperFuture<T> future;

  /// Total number of elements in each page. Default value is **10**.
  final int pageSize;

  /// Page Number to start with. Default value is **1**.
  final int pageNumber;

  final EdgeInsets padding;

  /// Filter the results before displaying them.
  /// Gives the list of results that can be modified and returned.
  final FilterFn<T>? filterFn;

  /// A controller to call the refresh function if required.
  final InfiniteScrollWrapperController controller;

  final IndexedWidgetBuilder? separatorBuilder;

  /// Show the list end indicator or not.
  final bool listEndIndicator;

  /// First page loading indicator.
  final WidgetBuilder? firstPageLoadingBuilder;

  @override
  _InfinitePaginationState<T> createState() => _InfinitePaginationState<T>();
}

class _InfinitePaginationState<T> extends State<_InfinitePagination<T>> {
  // Define the paging controller.
  late final PagingController<int, _ListItem<T>> _pagingController;

  // Start off with the first page.
  late int pageNumber;

  // If the API results are supposed to be refreshed
  // or be fetched from cache, if available.
  bool refresh = false;

  // Track which items have been animated in (for initial load)
  final Set<int> _animatedItems = <int>{};
  // Track if we've started animating items (to distinguish initial load from pagination)
  bool _hasStartedAnimating = false;

  @override
  void initState() {
    super.initState();
    setupController();
    pageNumber = widget.pageNumber;
    _pagingController = PagingController<int, _ListItem<T>>(
      value: PagingState<int, _ListItem<T>>(
        hasNextPage: true, // Initially we have pages to load
      ),
      fetchPage: _fetchPage,
      getNextPageKey: (final PagingState<int, _ListItem<T>> state) {
        // If no pages loaded yet, return 0 for first page
        if (state.pages == null || state.pages!.isEmpty) {
          return 0;
        }
        // Use convenience getter to check if last page is empty
        if (state.lastPageIsEmpty) return null;
        // Use convenience getter to get next page key (increments by 1)
        return state.nextIntPageKey;
      },
    );
    // Trigger initial page load immediately (don't wait for post-frame)
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

  // Refresh everything and reload.
  void resetAndRefresh() {
    refresh = true;
    pageNumber = widget.pageNumber;
    _animatedItems.clear(); // Reset animated items on refresh
    _hasStartedAnimating = false; // Reset animation state
    _pagingController.refresh();
  }

  // Fetch the data to display.
  Future<List<_ListItem<T>>> _fetchPage(final int pageKey) async {
    try {
      // Calculate the actual page number from the page key
      // pageKey starts at 0, so for pageNumber starting at widget.pageNumber:
      // pageKey 0 -> pageNumber widget.pageNumber
      // pageKey 1 -> pageNumber widget.pageNumber + 1
      // etc.
      final int currentPageNumber = widget.pageNumber + pageKey;

      // log.log(Level.debug, 'Fetching page $currentPageNumber, key:$pageKey, $this');
      // Use the supplied APIs accordingly, based on the *refresh* value.
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
      // Filter items based on the provided filterFn.
      List<T> filteredItems;
      if (widget.filterFn != null) {
        filteredItems = widget.filterFn!(newItems) ?? <T>[];
      } else {
        filteredItems = newItems;
      }

      // If the last page, set refresh value to false,
      // as all pages have been refreshed.
      if (filteredItems.length < widget.pageSize) {
        refresh = false;
      }

      return filteredItems
          .map((final T e) => _ListItem<T>(e, refresh: refresh))
          .toList();
    } on DioException catch (error, s) {
      log.e(error.response?.data, stackTrace: s);
      rethrow;
      // Can't really do anything about this, the widget is not propagating the error above.
      // ignore: avoid_catches_without_on_clauses
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
            PagedSliverList<int, _ListItem<T>>.separated(
          state: state,
          fetchNextPage: _pagingController.fetchNextPage,
          separatorBuilder:
              widget.separatorBuilder ?? (final _, final __) => Container(),
          builderDelegate: PagedChildBuilderDelegate<_ListItem<T>>(
            itemBuilder: (
              final BuildContext context,
              final _ListItem<T> item,
              final int index,
            ) {
              // Store refresh value before it's consumed
              final bool isRefresh = item.refreshChildren;

              // Determine if this item should animate:
              // 1. On initial load (first time items appear, index < pageSize)
              // 2. On refresh (when refresh flag is true)
              // 3. Only animate each item once
              final bool isFirstPage = index < widget.pageSize;
              // Allow all first-page items to animate on initial load
              // Check if we're still in initial load phase (no items animated yet OR all animated items are first page)
              final bool isInitialLoadPhase = _animatedItems.isEmpty ||
                  (_animatedItems.isNotEmpty &&
                      _animatedItems.every((i) => i < widget.pageSize));

              // Animate if: not already animated AND (is refresh OR is first page in initial load phase)
              final bool shouldAnimate = !_animatedItems.contains(index) &&
                  (isRefresh || (isFirstPage && isInitialLoadPhase));

              if (shouldAnimate) {
                _animatedItems.add(index);
                // Mark that we've started animating after processing first item
                if (!_hasStartedAnimating) {
                  _hasStartedAnimating = true;
                }
              }

              return Column(
                children: <Widget>[
                  if (index == 0)
                    SizedBox(
                      height: widget.padding.top,
                    ),
                  _StaggeredAnimatedItem(
                    key: ValueKey('animated_${item.item.hashCode}_$index'),
                    index: index,
                    shouldAnimate: shouldAnimate,
                    child: widget.builder(
                      context,
                      ScrollWrapperBuilderData<T>(
                        item: item.item,
                        index: index,
                        refresh: isRefresh,
                        isCurrentlyLast:
                            (state.items?.length ?? 0) - 1 == index,
                      ),
                    ),
                  ),
                ],
              );
            },
            firstPageProgressIndicatorBuilder: (final BuildContext context) =>
                widget.firstPageLoadingBuilder?.call(context) ??
                const Padding(
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
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: widget.padding.top,
                  ),
                  const Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Nothing to see here.',
                          style: TextStyle(
                              // color: Provider.of<PaletteSettings>(context)
                              //     .currentSetting
                              //     .faded3,
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
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
    final String? message = this.message;
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

/// Widget that animates items in with a staggered delay
class _StaggeredAnimatedItem extends StatefulWidget {
  const _StaggeredAnimatedItem({
    super.key,
    required this.index,
    required this.shouldAnimate,
    required this.child,
  });

  final int index;
  final bool shouldAnimate;
  final Widget child;

  @override
  State<_StaggeredAnimatedItem> createState() => _StaggeredAnimatedItemState();
}

class _StaggeredAnimatedItemState extends State<_StaggeredAnimatedItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    if (widget.shouldAnimate) {
      // Initialize controller at 0 (invisible) so items start hidden
      _controller.value = 0.0;
      // Start animation with a delay based on index for staggered effect
      final int delay = (widget.index * 50).clamp(0, 300);
      // Use addPostFrameCallback to ensure widget is fully built before animating
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future<void>.delayed(Duration(milliseconds: delay), () {
          if (mounted && _controller.status == AnimationStatus.dismissed) {
            _controller.forward();
          }
        });
      });
    } else {
      // If not animating, show immediately
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
