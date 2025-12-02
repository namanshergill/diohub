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
    this.contentVersion,
    this.animationController,
    super.key,
  });

  final Widget collapsedWidget;
  final Widget expandedWidget;
  final Widget? bottom;
  final Widget body;
  final int? contentVersion;
  final AnimationController? animationController;

  @override
  State<DynamicScroll> createState() => _DynamicScrollState();
}

class _DynamicScrollState extends State<DynamicScroll> {
  final GlobalKey _expandedWidgetKey = GlobalKey();
  final GlobalKey<AnimatedDynamicSliverAppBarState> _appBarKey = GlobalKey<AnimatedDynamicSliverAppBarState>();

  @override
  Widget build(final BuildContext context) => NestedScrollView(
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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
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
                  title: widget.collapsedWidget,
                  // bottom: bottom,
                  // snap: true,
                  pinned: true,
                  // floating: true,
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
