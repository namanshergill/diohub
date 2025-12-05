import 'package:diohub/common/misc/floating_widget_position_calculator.dart';
import 'package:flutter/material.dart';

/// Position of the floating widget
enum FloatingPosition {
  top,
  bottom,
}

/// Horizontal alignment of the floating widget
enum FloatingAlignment {
  left,
  center,
  right,
}

/// Callbacks provided to child widgets for controlling expand/collapse state
class ExpandableCallbacks {
  const ExpandableCallbacks({
    required this.expand,
    required this.collapse,
    required this.toggle,
    required this.isExpanded,
    required this.nearPosition,
  });

  /// Callback to expand the widget
  final VoidCallback expand;

  /// Callback to collapse the widget
  final VoidCallback collapse;

  /// Callback to toggle expand/collapse state
  final VoidCallback toggle;

  /// Whether the widget is currently expanded
  final bool isExpanded;

  /// The position the widget is near (top or bottom)
  final FloatingPosition nearPosition;
}

/// A floating expandable widget that handles drag, snap, and expand/collapse logic.
///
/// This widget handles positioning, dragging, snapping, and animation logic.
/// The content builder receives constraints via LayoutBuilder to properly handle
/// width constraints from Positioned widget.
///
/// **Usage:**
/// ```dart
/// FloatingExpandableWidget(
///   contentBuilder: (context, callbacks) => LayoutBuilder(
///     builder: (context, constraints) {
///       // Use constraints here for proper width handling
///       // Use callbacks.isExpanded to check expanded state
///       return YourContent(callbacks: callbacks);
///     },
///   ),
///   position: FloatingPosition.bottom,
///   alignment: FloatingAlignment.right,
///   padding: EdgeInsets.all(16),
///   onExpandChanged: (isExpanded) {},
/// )
/// ```
class FloatingExpandableWidget extends StatefulWidget {
  const FloatingExpandableWidget({
    required this.contentBuilder,
    this.position = FloatingPosition.top,
    this.alignment,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.edgePadding = 8.0,
    this.bottomPadding = 0.0,
    this.onExpandChanged,
    super.key,
  }) : calculator = null;

  /// Custom float constructor that accepts a custom position calculator.
  ///
  /// Allows for custom positioning behavior by providing a custom calculator.
  /// The calculator can be extended to override specific calculation methods.
  ///
  /// **Usage:**
  /// ```dart
  /// FloatingExpandableWidget.customFloat(
  ///   calculator: CustomPositionCalculator(...),
  ///   contentBuilder: (context, callbacks) => YourContent(),
  /// )
  /// ```
  const FloatingExpandableWidget.customFloat({
    required this.calculator,
    required this.contentBuilder,
    this.onExpandChanged,
    super.key,
  })  : position = FloatingPosition.top,
        alignment = null,
        padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        edgePadding = 8.0,
        bottomPadding = 0.0;

  /// Builder for the content widget.
  /// Receives callbacks to control expand/collapse state.
  /// Should use LayoutBuilder to receive constraints from Positioned widget.
  /// The expanded state is available via callbacks.isExpanded.
  final Widget Function(BuildContext context, ExpandableCallbacks callbacks)
      contentBuilder;

  /// Position of the widget (used when calculator is null)
  final FloatingPosition position;

  /// Horizontal alignment of the widget (used when calculator is null)
  /// If null, defaults to center for top position, right for bottom position
  final FloatingAlignment? alignment;

  /// Padding around the widget content (used when calculator is null)
  final EdgeInsets padding;

  /// Minimum padding from screen edges (used when calculator is null)
  final double edgePadding;

  /// Additional bottom padding to account for app-level UI elements (e.g., tab bars)
  /// This is added on top of system UI padding (viewPadding.bottom)
  final double bottomPadding;

  /// Custom position calculator for advanced positioning behavior.
  /// If null, a default calculator is created from position, alignment, padding, and edgePadding.
  final FloatingWidgetPositionCalculator? calculator;

  /// Callback when expand state changes
  final void Function(bool isExpanded)? onExpandChanged;

  @override
  State<FloatingExpandableWidget> createState() =>
      _FloatingExpandableWidgetState();
}

class _FloatingExpandableWidgetState extends State<FloatingExpandableWidget>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool? _expandedFromTop;
  bool _isAnimating = false;
  late AnimationController _animationController;
  late AnimationController _snapAnimationController;
  Animation<Offset>? _snapAnimation;

  // Draggable state - using absolute screen coordinates
  Offset?
      _position; // null means use default alignment, otherwise absolute position (center point)
  Size? _widgetSize; // Actual measured size of the widget
  final GlobalKey _widgetKey = GlobalKey();

  /// Gets the position calculator, creating a default one if needed.
  FloatingWidgetPositionCalculator get _calculator {
    return widget.calculator ??
        FloatingWidgetPositionCalculator(
          position: widget.position,
          alignment: widget.alignment,
          padding: widget.padding,
          edgePadding: widget.edgePadding,
          bottomPadding: widget.bottomPadding,
        );
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _snapAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _snapAnimationController.addListener(_onSnapAnimationUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureWidgetSize());
  }

  void _onSnapAnimationUpdate() {
    if (_snapAnimation != null && mounted) {
      final newValue = _snapAnimation!.value;
      setState(() {
        _position = newValue;
      });
    }
  }

  @override
  void dispose() {
    _snapAnimationController.removeListener(_onSnapAnimationUpdate);
    _animationController.dispose();
    _snapAnimationController.dispose();
    super.dispose();
  }

  void _measureWidgetSize() {
    if (!mounted) return;
    final RenderBox? renderBox =
        _widgetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final newSize = renderBox.size;
      if (_widgetSize != newSize) {
        print(
            '[FloatingExpandableWidget] _measureWidgetSize: old=$_widgetSize, new=$newSize');
        setState(() {
          _widgetSize = newSize;
        });
      }
    } else {
      print(
          '[FloatingExpandableWidget] _measureWidgetSize: renderBox is null or has no size');
    }
  }

  void _toggleExpand() {
    final wasExpanded = _isExpanded;
    final mediaQuery = MediaQuery.of(context);

    setState(() {
      _isExpanded = !_isExpanded;
      _isAnimating = true;
      if (_isExpanded) {
        _animationController.forward().then((_) {
          if (mounted) {
            setState(() {
              _isAnimating = false;
            });
          }
        });
        final isNearTop = _calculator.isPositionNearTop(
          currentCenterPosition: _position,
          mediaQuery: mediaQuery,
        );
        _expandedFromTop = isNearTop;
        final expandedSize = Size(
          _widgetSize?.width ?? 250.0,
          _widgetSize?.height ?? 300.0,
        );
        _position = _calculator.calculateExpandedCenterPosition(
          mediaQuery: mediaQuery,
          expandedWidgetSize: expandedSize,
        );
      } else {
        _animationController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _isAnimating = false;
            });
          }
        });
        _expandedFromTop = null;
        // On collapse, snap back to default bottom position
        final mediaQuery = MediaQuery.of(context);
        final collapsedSize = Size(
          _widgetSize?.width ?? 150.0,
          _widgetSize?.height ?? 100.0,
        );
        _position = _calculator.calculateInitialDragPosition(
          mediaQuery: mediaQuery,
          widgetSize: collapsedSize,
        );
      }
    });
    widget.onExpandChanged?.call(_isExpanded);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureWidgetSize();
    });
  }

  void _collapse() {
    if (_isExpanded) {
      _toggleExpand();
    }
  }

  void _expand() {
    if (!_isExpanded) {
      _toggleExpand();
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (_position == null) {
      final mediaQuery = MediaQuery.of(context);

      final widgetWidth = _widgetSize?.width ?? 150.0;
      final widgetHeight = _widgetSize?.height ?? 100.0;

      _position = _calculator.calculateInitialDragPosition(
        mediaQuery: mediaQuery,
        widgetSize: Size(widgetWidth, widgetHeight),
      );
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;
    setState(() {
      if (_position == null) return;

      final newPosition = _position! + details.delta;
      final mediaQuery = MediaQuery.of(context);

      final currentWidgetWidth =
          _widgetSize?.width ?? (_isExpanded ? 250.0 : 150.0);
      final currentWidgetHeight =
          _widgetSize?.height ?? (_isExpanded ? 300.0 : 100.0);
      final widgetSize = Size(currentWidgetWidth, currentWidgetHeight);

      _position = _calculator.clampPosition(
        position: newPosition,
        mediaQuery: mediaQuery,
        widgetSize: widgetSize,
        isExpanded: _isExpanded,
      );

      // Auto-expand/collapse logic
      if (_calculator.shouldAutoExpand(
        currentCenterPosition: _position!,
        mediaQuery: mediaQuery,
        widgetSize: widgetSize,
        isExpanded: _isExpanded,
      )) {
        final edgeDistances = _calculator.calculateEdgeDistances(
          currentCenterPosition: _position!,
          mediaQuery: mediaQuery,
          widgetSize: widgetSize,
          isExpanded: _isExpanded,
        );
        _expandedFromTop = edgeDistances.isNearTop;
        _isExpanded = true;
        _isAnimating = true;
        _animationController.forward().then((_) {
          if (mounted) {
            setState(() {
              _isAnimating = false;
            });
          }
        });
        final expandedSize = Size(
          _widgetSize?.width ?? 250.0,
          _widgetSize?.height ?? 300.0,
        );
        _position = _calculator.calculateExpandedCenterPosition(
          mediaQuery: mediaQuery,
          expandedWidgetSize: expandedSize,
        );
        widget.onExpandChanged?.call(true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _measureWidgetSize();
        });
      } else if (_calculator.shouldAutoCollapse(
        currentCenterPosition: _position!,
        mediaQuery: mediaQuery,
        widgetSize: widgetSize,
        isExpanded: _isExpanded,
      )) {
        _isExpanded = false;
        _isAnimating = true;
        _animationController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _isAnimating = false;
            });
          }
        });
        _expandedFromTop = null;
        widget.onExpandChanged?.call(false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _measureWidgetSize();
          _snapToNearestEdge();
        });
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_position == null) return;

    final mediaQuery = MediaQuery.of(context);

    final currentWidgetWidth =
        _widgetSize?.width ?? (_isExpanded ? 250.0 : 150.0);
    final currentWidgetHeight =
        _widgetSize?.height ?? (_isExpanded ? 300.0 : 100.0);
    final widgetSize = Size(currentWidgetWidth, currentWidgetHeight);

    if (_calculator.shouldAutoExpand(
      currentCenterPosition: _position!,
      mediaQuery: mediaQuery,
      widgetSize: widgetSize,
      isExpanded: _isExpanded,
    )) {
      final edgeDistances = _calculator.calculateEdgeDistances(
        currentCenterPosition: _position!,
        mediaQuery: mediaQuery,
        widgetSize: widgetSize,
        isExpanded: _isExpanded,
      );
      setState(() {
        _expandedFromTop = edgeDistances.isNearTop;
        _isExpanded = true;
        _isAnimating = true;
        _animationController.forward().then((_) {
          if (mounted) {
            setState(() {
              _isAnimating = false;
            });
          }
        });
        final expandedSize = Size(
          _widgetSize?.width ?? 250.0,
          _widgetSize?.height ?? 300.0,
        );
        _position = _calculator.calculateExpandedCenterPosition(
          mediaQuery: mediaQuery,
          expandedWidgetSize: expandedSize,
        );
      });
      widget.onExpandChanged?.call(true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _measureWidgetSize();
      });
    } else if (_calculator.shouldAutoCollapse(
      currentCenterPosition: _position!,
      mediaQuery: mediaQuery,
      widgetSize: widgetSize,
      isExpanded: _isExpanded,
    )) {
      setState(() {
        _isExpanded = false;
        _isAnimating = true;
        _animationController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _isAnimating = false;
            });
          }
        });
        _expandedFromTop = null;
      });
      widget.onExpandChanged?.call(false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _measureWidgetSize();
        _snapToNearestEdge();
      });
    } else if (!_isExpanded) {
      _snapToNearestEdge();
    }
  }

  void _snapToNearestEdge() {
    if (_position == null || !mounted) return;

    final mediaQuery = MediaQuery.of(context);

    // Get actual widget dimensions - use conservative estimate if not measured
    // Use larger estimate to prevent clipping
    final estimatedWidth = _isExpanded ? mediaQuery.size.width * 0.9 : 200.0;
    final widgetWidth = _widgetSize?.width ?? estimatedWidth;
    final widgetHeight = _widgetSize?.height ?? (_isExpanded ? 300.0 : 100.0);
    final widgetSize = Size(widgetWidth, widgetHeight);

    // If widget hasn't been measured yet, trigger measurement
    if (_widgetSize == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureWidgetSize());
    }

    final targetPosition = _calculator.calculateSnapPosition(
      currentCenterPosition: _position!,
      mediaQuery: mediaQuery,
      widgetSize: widgetSize,
      isExpanded: _isExpanded,
    );

    // If behavior is freeDrag, don't snap
    if (targetPosition == null) return;

    final startPosition = _position!;

    _snapAnimationController.removeListener(_onSnapAnimationUpdate);
    _snapAnimationController.stop();
    _snapAnimationController.reset();

    _snapAnimation = Tween<Offset>(
      begin: startPosition,
      end: targetPosition,
    ).animate(CurvedAnimation(
      parent: _snapAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _snapAnimationController.addListener(_onSnapAnimationUpdate);

    _isAnimating = true;
    _snapAnimationController.forward(from: 0.0).then((_) {
      if (mounted) {
        _snapAnimationController.removeListener(_onSnapAnimationUpdate);
        _snapAnimationController.reset();
        setState(() {
          _position = targetPosition;
          _isAnimating = false;
        });
        _snapAnimationController.addListener(_onSnapAnimationUpdate);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    // Calculate positioning
    final position = _position != null
        ? _calculator.calculateDraggedPosition(
            currentCenterPosition: _position!,
            mediaQuery: mediaQuery,
            widgetSize: Size(
              _widgetSize?.width ?? (_isExpanded ? 250.0 : 150.0),
              _widgetSize?.height ?? (_isExpanded ? 300.0 : 100.0),
            ),
            isExpanded: _isExpanded,
          )
        : _calculator.calculateDefaultPosition(
            mediaQuery: mediaQuery,
            widgetSize: Size(
              _widgetSize?.width ?? (_isExpanded ? 250.0 : 150.0),
              _widgetSize?.height ?? (_isExpanded ? 300.0 : 100.0),
            ),
          );

    // Validate and adjust position
    final validatedPosition = _calculator.validatePosition(
      position: position,
      mediaQuery: mediaQuery,
      widgetSize: _widgetSize,
      isExpanded: _isExpanded,
    );

    final left = validatedPosition.left;
    final top = validatedPosition.top;
    final right = validatedPosition.right;
    final bottom = validatedPosition.bottom;

    // Calculate which position the widget is near based on actual position
    final nearPosition = _calculator.determineNearPosition(
      currentCenterPosition: _position,
      mediaQuery: mediaQuery,
      expandedFromTop: _expandedFromTop,
    );

    final callbacks = ExpandableCallbacks(
      expand: _expand,
      collapse: _collapse,
      toggle: _toggleExpand,
      isExpanded: _isExpanded,
      nearPosition: nearPosition,
    );

    final isCenterAlignment = _position == null &&
        _calculator.getEffectiveAlignment() == FloatingAlignment.center;

    if (isCenterAlignment) {
      // For center alignment, use Positioned.fill to give full width, then Align to center
      return Positioned.fill(
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Align(
            alignment: _calculator.position == FloatingPosition.top
                ? Alignment.topCenter
                : Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                top: _calculator.calculateTopPaddingForCenterAlignment(
                  mediaQuery: mediaQuery,
                ),
                bottom: _calculator.calculateBottomPaddingForCenterAlignment(
                  mediaQuery: mediaQuery,
                ),
              ),
              child: _buildContent(context, callbacks),
            ),
          ),
        ),
      );
    }

    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: _buildContent(context, callbacks),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ExpandableCallbacks callbacks) {
    // Wrap content with key for size measurement
    return KeyedSubtree(
      key: _widgetKey,
      child: widget.contentBuilder(context, callbacks),
    );
  }
}

/// A reusable widget that animates expanded content items with scale and fade.
///
/// Wraps child widgets with a scale animation (0.8 to 1.0) and opacity fade
/// when used with FloatingExpandableWidget's expandAnimation.
///
/// **Usage:**
/// ```dart
/// ExpandedContentItem(
///   animation: expandAnimation,
///   child: YourWidget(),
/// )
/// ```
class ExpandedContentItem extends StatelessWidget {
  const ExpandedContentItem({
    required this.animation,
    required this.child,
    this.scaleStart = 0.8,
    this.scaleEnd = 1.0,
    this.curve = Curves.easeOutCubic,
    super.key,
  });

  /// The animation that drives the expand/collapse transition
  final Animation<double> animation;

  /// The child widget to animate
  final Widget child;

  /// Starting scale value (default: 0.8)
  final double scaleStart;

  /// Ending scale value (default: 1.0)
  final double scaleEnd;

  /// Animation curve (default: Curves.easeOutCubic)
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // Scale animation with easing
        final easedProgress = curve.transform(animation.value);
        final scale = scaleStart + (easedProgress * (scaleEnd - scaleStart));

        return Opacity(
          opacity: animation.value,
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
      child: this.child,
    );
  }
}
