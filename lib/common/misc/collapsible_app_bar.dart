import 'package:diohub/common/misc/scroll_dynamic_elevation.dart';
import 'package:diohub/utils/utils.dart';
import 'package:dynamic_sliver_app_bar/src/animated_dynamic_sliver_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:sliver_tools/sliver_tools.dart';

class DynamicScroll extends StatefulWidget {
  const DynamicScroll({
    required this.expandedWidget,
    required this.collapsedWidget,
    required this.body,
    this.bottom,
    this.pinnedWidget,
    this.contentVersion,
    this.animationController,
    super.key,
  });

  final Widget collapsedWidget;
  final Widget expandedWidget;
  final Widget? bottom;
  final Widget? pinnedWidget;
  final Widget body;
  final int? contentVersion;
  final AnimationController? animationController;

  @override
  State<DynamicScroll> createState() => _DynamicScrollState();
}

class _DynamicScrollState extends State<DynamicScroll> {
  final GlobalKey _expandedWidgetKey = GlobalKey();
  final GlobalKey<AnimatedDynamicSliverAppBarState> _appBarKey = GlobalKey<AnimatedDynamicSliverAppBarState>();
  final ScrollController _appBarContentScrollController = ScrollController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Scroll to collapse the app bar on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // Scroll down by a large amount to ensure app bar is collapsed
        _scrollController.jumpTo(1000);
      }
    });
  }

  @override
  void dispose() {
    _appBarContentScrollController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (final BuildContext context, final bool value) =>
            <Widget>[
          SliverOverlapAbsorber(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            sliver: SliverSafeArea(
              // bottom: false,
              sliver: MultiSliver(children: <Widget>[
                AnimatedDynamicSliverAppBar(
                  key: _appBarKey,
                  animationController: widget.animationController,
                  appBarContentScrollController: _appBarContentScrollController,
                  // backgroundColor: Colors.transparent,
                  // elevation: 0,
                  toolbarHeight: 64,
                  surfaceTintColor: ElevationOverlay.applySurfaceTint(
                    context.colorScheme.background,
                    context.colorScheme.surfaceTint,
                    3,
                  ),
                  flexibleSpace: ClipRect(
                    child: SizeChangedLayoutNotifier(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: context.colorScheme.surfaceContainer,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(20),
                          ),
                        ),
                        child: NotificationListener<SizeChangedLayoutNotification>(
                          onNotification: (notification) {
                            // When size changes, trigger remeasurement after animation completes
                            Future.delayed(const Duration(milliseconds: 350), () {
                              if (mounted) {
                                setState(() {});
                              }
                            });
                            return true;
                          },
                          child: _ScrollableAppBarContent(
                            scrollController: _appBarContentScrollController,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: <Widget>[
                                  KeyedSubtree(
                                    key: _expandedWidgetKey,
                                    child: widget.expandedWidget,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Container(
                                      width: 40,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: context.colorScheme.onInverseSurface,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  title: widget.collapsedWidget,
                  // bottom: bottom,
                  // snap: true,
                  pinned: true,
                  // floating: true,
                ),
                if (widget.pinnedWidget != null)
                  SliverPinnedHeader(
                    child: ScrollDynamicElevation(
                      child: widget.pinnedWidget!,
                    ),
                  ),
                if (widget.bottom != null)
                  SliverPinnedHeader(
                    child: ScrollDynamicElevation(
                      child: widget.bottom!,
                    ),
                  )
              ]),
            ),
          ),
        ],
        body: Builder(
          builder: (final BuildContext context) {
            NestedScrollView.sliverOverlapAbsorberHandleFor(context);

            return widget.body;
          },
        ),
      );
}

/// Wrapper that makes app bar content scrollable when it exceeds available height
/// and prevents collapse when content is not scrolled to top
class _ScrollableAppBarContent extends StatelessWidget {
  const _ScrollableAppBarContent({
    required this.scrollController,
    required this.child,
  });

  final ScrollController scrollController;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Always use SingleChildScrollView to keep widget tree consistent
    // During measurement (unbounded), disable scrolling with NeverScrollableScrollPhysics
    // During display (bounded), enable scrolling with ClampingScrollPhysics
    // Use Align with bottomCenter to keep content at bottom during collapse
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMeasuring = constraints.maxHeight.isInfinite;
        
        // During display, ensure content fills space and aligns to bottom
        if (!isMeasuring && constraints.maxHeight.isFinite) {
          return Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                physics: const ClampingScrollPhysics(),
                primary: false,
                child: child,
              ),
            ),
          );
        }
        
        // During measurement, just use SingleChildScrollView
        return SingleChildScrollView(
          controller: scrollController,
          physics: const NeverScrollableScrollPhysics(),
          primary: false,
          child: child,
        );
      },
    );
  }
}
