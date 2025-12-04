import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:sliver_tools/sliver_tools.dart';

/// A [SliverAppBar] that automatically adjusts its height based on its content
/// and supports smooth animations when the content size changes.
///
/// This widget wraps a standard [SliverAppBar] and continuously measures its
/// [flexibleSpace] content to determine the appropriate [expandedHeight].
///
/// When an [animationController] is provided, the app bar will:
/// - Use [OverflowBox] during animation to allow content to grow naturally
/// - Continuously measure content height on each frame
/// - Smoothly animate the [expandedHeight] as content expands/collapses
///
/// Example:
/// ```dart
/// AnimatedDynamicSliverAppBar(
///   animationController: _myAnimationController,
///   flexibleSpace: Column(
///     children: [
///       // Your content here
///       AnimatedSize(
///         duration: Duration(milliseconds: 300),
///         child: _isExpanded ? ExpandedContent() : CollapsedContent(),
///       ),
///     ],
///   ),
///   title: Text('My Title'),
///   pinned: true,
/// )
/// ```
class AnimatedDynamicSliverAppBar extends StatefulWidget {
  const AnimatedDynamicSliverAppBar({
    this.flexibleSpace,
    super.key,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.title,
    this.actions,
    this.bottom,
    this.elevation,
    this.scrolledUnderElevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.forceElevated = false,
    this.backgroundColor,
    this.backgroundGradient,
    this.foregroundColor,
    this.iconTheme,
    this.actionsIconTheme,
    this.primary = true,
    this.centerTitle,
    this.excludeHeaderSemantics = false,
    this.titleSpacing,
    this.collapsedHeight,
    this.expandedHeight,
    this.floating = false,
    this.pinned = false,
    this.snap = false,
    this.stretch = false,
    this.stretchTriggerOffset = 100.0,
    this.onStretchTrigger,
    this.shape,
    this.toolbarHeight = kToolbarHeight + 20,
    this.leadingWidth,
    this.toolbarTextStyle,
    this.titleTextStyle,
    this.systemOverlayStyle,
    this.forceMaterialTransparency = false,
    this.clipBehavior,
    this.appBarClipper,
    this.scrollController,
    this.appBarContentScrollController,
    this.animationController,
    this.heightBuffer = 1.0,
  });

  final ScrollController? scrollController;

  /// Scroll controller for the app bar content (when it's scrollable).
  /// Used to check if app bar content is scrolled to top before allowing collapse.
  final ScrollController? appBarContentScrollController;

  /// The widget to display in the flexible space area.
  /// This content will be measured to determine the app bar's height.
  final Widget? flexibleSpace;

  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Widget? title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final double? elevation;
  final double? scrolledUnderElevation;
  final Color? shadowColor;
  final Color? surfaceTintColor;
  final bool forceElevated;
  final Color? backgroundColor;

  /// If backgroundGradient is non null, backgroundColor will be ignored
  final LinearGradient? backgroundGradient;
  final Color? foregroundColor;
  final IconThemeData? iconTheme;
  final IconThemeData? actionsIconTheme;
  final bool primary;
  final bool? centerTitle;
  final bool excludeHeaderSemantics;
  final double? titleSpacing;
  final double? expandedHeight;
  final double? collapsedHeight;
  final bool floating;
  final bool pinned;
  final ShapeBorder? shape;
  final double toolbarHeight;
  final double? leadingWidth;
  final TextStyle? toolbarTextStyle;
  final TextStyle? titleTextStyle;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final bool forceMaterialTransparency;
  final Clip? clipBehavior;
  final bool snap;
  final bool stretch;
  final double stretchTriggerOffset;
  final AsyncCallback? onStretchTrigger;
  final CustomClipper<Path>? appBarClipper;

  /// An [AnimationController] that controls when to enable smooth height animations.
  ///
  /// When the controller is animating, the app bar will:
  /// - Wrap content in [OverflowBox] to allow natural growth
  /// - Continuously measure content height on each frame
  /// - Update [expandedHeight] smoothly
  ///
  /// When not animating, uses standard height measurement.
  final AnimationController? animationController;

  /// Additional height buffer (in pixels) to add to measurements.
  ///
  /// Helps prevent tiny overflow errors due to floating-point precision.
  /// Defaults to 1.0 pixel.
  final double heightBuffer;

  @override
  AnimatedDynamicSliverAppBarState createState() =>
      AnimatedDynamicSliverAppBarState();
}

class AnimatedDynamicSliverAppBarState
    extends State<AnimatedDynamicSliverAppBar> {
  final GlobalKey _childKey = GlobalKey();

  // As long as the height is 0 instead of the sliver app bar a sliver to box adapter will be used
  // to calculate dynamically the size for the sliver app bar
  double _height = 0;
  bool _isMeasuring = false;

  @override
  void initState() {
    super.initState();
    widget.animationController?.addListener(_onAnimationTick);
    updateHeight();
  }

  @override
  void didUpdateWidget(covariant AnimatedDynamicSliverAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animationController != widget.animationController) {
      oldWidget.animationController?.removeListener(_onAnimationTick);
      widget.animationController?.addListener(_onAnimationTick);
    }
    updateHeight();
  }

  @override
  void dispose() {
    widget.animationController?.removeListener(_onAnimationTick);
    super.dispose();
  }

  void _onAnimationTick() {
    // Continuously remeasure during animation
    if (widget.animationController?.isAnimating ?? false) {
      if (!_isMeasuring) {
        _isMeasuring = true;
        _scheduleContinuousMeasurement();
      }
    } else {
      // Animation stopped
      _isMeasuring = false;
      // Final measurement after animation completes
      updateHeight();
    }
  }

  void _scheduleContinuousMeasurement() {
    if (!_isMeasuring || !mounted) return;

    // Schedule measurement for next frame
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      if (!mounted || !_isMeasuring) {
        _isMeasuring = false;
        return;
      }

      // Measure the content's natural size
      if (_childKey.currentContext != null) {
        final RenderBox? renderBox =
            _childKey.currentContext!.findRenderObject() as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          final double newHeight = renderBox.size.height;

          if ((newHeight - _height).abs() > 0.5) {
            setState(() {
              _height = newHeight +
                  widget.heightBuffer; // Add buffer to prevent tiny overflow
            });
          }
        }
      }

      // Continue measuring if still animating
      if (widget.animationController?.isAnimating ?? false) {
        _scheduleContinuousMeasurement();
      } else {
        // Animation completed
        _isMeasuring = false;
        // Final measurement to ensure accuracy
        updateHeight();
      }
    });
  }

  /// Measures the content height and updates the app bar's [expandedHeight].
  ///
  /// This is called automatically on init, widget updates, and after animations complete.
  void updateHeight() {
    // Gets the new height and updates the sliver app bar. Needs to be called after the last frame has been rebuild
    // otherwise this will throw an error
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (_childKey.currentContext == null) return;
      final RenderBox? renderBox =
          _childKey.currentContext!.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        setState(() {
          _height = renderBox.size.height +
              widget.heightBuffer; // Add buffer to prevent tiny overflow
        });
      }
    });
  }

  late bool isSnapping = widget.snap;
  late bool isFloating = widget.floating;

  @override
  Widget build(BuildContext context) {
    // Needed to lay out the flexibleSpace the first time, so we can calculate its intrinsic height
    if (_height == 0) {
      return SliverPinnedHeader(
        child: Stack(
          children: [
            Padding(
              // Padding which centers the flexible space within the app bar
              padding: EdgeInsets.symmetric(
                  vertical: MediaQuery.paddingOf(context).top / 2),
              child: Container(
                  key: _childKey,
                  child:
                      widget.flexibleSpace ?? SizedBox(height: kToolbarHeight)),
            ),
            Positioned.fill(
              // 10 is the magic number which the app bar is pushed down within the sliver app bar. Couldnt find exactly where this number
              // comes from and found it through trial and error.
              top: 10,
              child: Align(
                alignment: Alignment.topCenter,
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: widget.leading,
                  actions: widget.actions,
                ),
              ),
            )
          ],
        ),
      );
    }

    return SliverAppBar(
      leading: widget.leading,
      automaticallyImplyLeading: widget.automaticallyImplyLeading,
      title: widget.title != null
          ? GestureDetector(
              onPanDown: (details) {
                try {
                  var sc = PrimaryScrollController.of(context);
                  sc.animateTo(sc.initialScrollOffset + 100,
                      curve: Curves.bounceIn,
                      duration: Duration(milliseconds: 300));
                } catch (e) {
                  // Ignore scroll errors
                }
              },
              child: _InvisibleExpandedTitle(child: widget.title!))
          : null,
      actions: widget.actions,
      bottom: widget.bottom,
      elevation: widget.elevation,
      scrolledUnderElevation: widget.scrolledUnderElevation,
      shadowColor: widget.shadowColor,
      surfaceTintColor: widget.surfaceTintColor,
      forceElevated: widget.forceElevated,
      backgroundColor: widget.backgroundColor,
      foregroundColor: widget.foregroundColor,
      iconTheme: widget.iconTheme,
      actionsIconTheme: widget.actionsIconTheme,
      primary: widget.primary,
      centerTitle: widget.centerTitle,
      excludeHeaderSemantics: widget.excludeHeaderSemantics,
      titleSpacing: widget.titleSpacing,
      collapsedHeight: widget.collapsedHeight,
      floating: isFloating,
      pinned: widget.pinned,
      snap: isSnapping,
      stretch: widget.stretch,
      stretchTriggerOffset: widget.stretchTriggerOffset,
      onStretchTrigger: widget.onStretchTrigger,
      shape: widget.shape,
      toolbarHeight: widget.toolbarHeight,
      expandedHeight: _height,
      leadingWidth: widget.leadingWidth,
      toolbarTextStyle: widget.toolbarTextStyle,
      titleTextStyle: widget.titleTextStyle,
      systemOverlayStyle: widget.systemOverlayStyle,
      forceMaterialTransparency: widget.forceMaterialTransparency,
      clipBehavior: widget.clipBehavior,
      flexibleSpace: _SmartFlexibleSpaceBar(
        scrollController: widget.scrollController,
        appBarContentScrollController: widget.appBarContentScrollController,
        child: FlexibleSpaceBar(
          background: AnimatedBuilder(
            animation:
                widget.animationController ?? const AlwaysStoppedAnimation(0),
            builder: (context, child) {
              final bool isAnimating =
                  widget.animationController?.isAnimating ?? false;
              // During animation, use OverflowBox to allow content to grow naturally
              // When not animating, use normal Container
              return isAnimating
                  ? OverflowBox(
                      minHeight: 0,
                      maxHeight: double.infinity,
                      alignment: Alignment.topCenter,
                      child: Container(
                        key: _childKey,
                        child: widget.flexibleSpace,
                      ),
                    )
                  : Container(
                      key: _childKey,
                      child: widget.flexibleSpace,
                    );
            },
          ),
        ),
      ),
    );
  }
}

/// Helper widget that makes the title invisible when the app bar is expanded
class _InvisibleExpandedTitle extends StatefulWidget {
  final Widget child;

  const _InvisibleExpandedTitle({
    required this.child,
  });

  @override
  _InvisibleExpandedTitleState createState() {
    return _InvisibleExpandedTitleState();
  }
}

class _InvisibleExpandedTitleState extends State<_InvisibleExpandedTitle> {
  ScrollPosition? _position;
  bool? _visible;

  @override
  void dispose() {
    _removeListener();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _removeListener();
    _addListener();
  }

  void _addListener() {
    _position = Scrollable.of(context).position;
    _position?.addListener(_positionListener);
    _positionListener();
  }

  void _removeListener() {
    _position?.removeListener(_positionListener);
  }

  void _positionListener() {
    final FlexibleSpaceBarSettings? settings =
        context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    bool visible =
        settings == null || settings.currentExtent <= settings.minExtent;
    if (_visible != visible) {
      setState(() {
        _visible = visible;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: (_visible ?? false) ? 1 : 0,
      duration: Duration(milliseconds: 200),
      child: widget.child,
    );
  }
}

/// Smart wrapper for FlexibleSpaceBar that handles drag-to-expand when collapsed
/// but allows scrolling when expanded. When expanded, only allows collapse
/// when app bar content is scrolled to the top.
class _SmartFlexibleSpaceBar extends StatefulWidget {
  const _SmartFlexibleSpaceBar({
    required this.child,
    this.scrollController,
    this.appBarContentScrollController,
  });

  final Widget child;
  final ScrollController? scrollController;
  final ScrollController? appBarContentScrollController;

  @override
  State<_SmartFlexibleSpaceBar> createState() => _SmartFlexibleSpaceBarState();
}

class _SmartFlexibleSpaceBarState extends State<_SmartFlexibleSpaceBar> {
  ScrollPosition? _position;
  bool _isCollapsed = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _removeListener();
    _addListener();
    _updateCollapsedState();
  }

  @override
  void dispose() {
    _removeListener();
    super.dispose();
  }

  void _addListener() {
    _position = Scrollable.maybeOf(context)?.position;
    _position?.addListener(_updateCollapsedState);
  }

  void _removeListener() {
    _position?.removeListener(_updateCollapsedState);
  }

  void _updateCollapsedState() {
    final FlexibleSpaceBarSettings? settings =
        context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    final bool isCollapsed =
        settings == null || settings.currentExtent <= settings.minExtent + 10;
    if (_isCollapsed != isCollapsed && mounted) {
      setState(() {
        _isCollapsed = isCollapsed;
      });
    }
  }

  bool _isAppBarContentAtTop() {
    if (widget.appBarContentScrollController == null) {
      return true; // If no controller, assume at top
    }
    return widget.appBarContentScrollController!.positions.isEmpty ||
        widget.appBarContentScrollController!.position.pixels <= 0;
  }

  @override
  Widget build(BuildContext context) {
    // Only handle drag-to-expand when collapsed
    if (_isCollapsed) {
      return GestureDetector(
        onPanDown: (details) {
          // Detect downward drag to expand
          final ScrollController? sc =
              widget.scrollController ?? PrimaryScrollController.of(context);
          if (sc != null && sc.hasClients && sc.position.pixels > 0) {
            sc.animateTo(
              0,
              curve: Curves.easeIn,
              duration: const Duration(milliseconds: 300),
            );
          }
        },
        onVerticalDragStart: (details) {
          // Also handle vertical drag start for better gesture detection
          final ScrollController? sc =
              widget.scrollController ?? PrimaryScrollController.of(context);
          if (sc != null && sc.hasClients && sc.position.pixels > 0) {
            sc.animateTo(
              0,
              curve: Curves.easeIn,
              duration: const Duration(milliseconds: 300),
            );
          }
        },
        behavior: HitTestBehavior.opaque,
        child: widget.child,
      );
    }

    // When expanded, prevent collapse when app bar content is not at top
    // Aggressively consume ALL scroll notifications from main scroll view
    // when app bar content is scrolled, allowing only app bar content to scroll
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Only intercept if app bar content is not at top
        if (!_isAppBarContentAtTop()) {
          // App bar content SingleChildScrollView has depth 0
          // Main NestedScrollView has depth 1 or higher
          // Consume ALL notifications from main scroll view (depth >= 1)
          // This prevents any collapse attempts when app bar content is scrolled
          if (notification.depth >= 1) {
            // This is from the main scroll view - consume it to prevent collapse
            return true; // Consume ALL notifications from main scroll view
          }
          // Allow all notifications from app bar content (depth 0) to pass through
          // This enables app bar content scrolling
        }
        // When app bar content is at top, allow all notifications to pass through
        // This enables normal collapse behavior
        return false;
      },
      child: widget.child,
    );
  }
}
