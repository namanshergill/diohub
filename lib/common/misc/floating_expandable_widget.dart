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
    this.onExpandChanged,
    super.key,
  });

  /// Builder for the content widget.
  /// Receives callbacks to control expand/collapse state.
  /// Should use LayoutBuilder to receive constraints from Positioned widget.
  final Widget Function(BuildContext context, ExpandableCallbacks callbacks)
      contentBuilder;

  /// Position of the widget
  final FloatingPosition position;

  /// Horizontal alignment of the widget
  /// If null, defaults to center for top position, right for bottom position
  final FloatingAlignment? alignment;

  /// Padding around the widget content
  final EdgeInsets padding;

  /// Minimum padding from screen edges (default: 8)
  final double edgePadding;

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
    final screenSize = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;

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
        final isNearTop = _position == null
            ? widget.position == FloatingPosition.top
            : _position!.dy <
                (screenSize.height - safeArea.top - safeArea.bottom) / 2 +
                    safeArea.top;
        _expandedFromTop = isNearTop;
        final centerX = screenSize.width / 2;
        final centerY = safeArea.top +
            (screenSize.height - safeArea.top - safeArea.bottom) / 2;
        _position = Offset(centerX, centerY);
      } else {
        _animationController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _isAnimating = false;
            });
          }
        });
        _expandedFromTop = null;
      }
    });
    widget.onExpandChanged?.call(_isExpanded);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureWidgetSize();
      if (wasExpanded && !_isExpanded && _position != null) {
        _snapToNearestEdge();
      }
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
      final screenSize = MediaQuery.of(context).size;
      final safeArea = MediaQuery.of(context).padding;
      final viewPadding = MediaQuery.of(context).viewPadding;

      double initialX;
      double initialY;

      final widgetWidth = _widgetSize?.width ?? 150.0;
      final widgetHeight = _widgetSize?.height ?? 100.0;

      final effectiveAlignment = widget.alignment ??
          (widget.position == FloatingPosition.top
              ? FloatingAlignment.center
              : FloatingAlignment.right);

      switch (effectiveAlignment) {
        case FloatingAlignment.left:
          initialX = widget.padding.left + safeArea.left + widgetWidth / 2;
          break;
        case FloatingAlignment.right:
          // Position at right edge - account for SafeArea and edge padding
          initialX = screenSize.width -
              safeArea.right -
              widget.edgePadding -
              widgetWidth / 2;
          print(
              '[FloatingExpandableWidget] _onPanStart right: initialX=$initialX (screenWidth=${screenSize.width}, safeArea.right=${safeArea.right}, edgePadding=${widget.edgePadding}, widgetWidth=$widgetWidth)');
          break;
        case FloatingAlignment.center:
          initialX = screenSize.width / 2;
          break;
      }

      switch (widget.position) {
        case FloatingPosition.top:
          initialY = widget.padding.top + safeArea.top + widgetHeight / 2;
          break;
        case FloatingPosition.bottom:
          // Position at bottom edge - account for viewPadding (includes navigation bar) and edge padding
          initialY = screenSize.height -
              viewPadding.bottom -
              widget.edgePadding -
              widgetHeight / 2;
          print(
              '[FloatingExpandableWidget] _onPanStart bottom: initialY=$initialY (screenHeight=${screenSize.height}, viewPadding.bottom=${viewPadding.bottom}, edgePadding=${widget.edgePadding}, widgetHeight=$widgetHeight)');
          break;
      }

      _position = Offset(initialX, initialY);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;
    setState(() {
      if (_position == null) return;

      final newPosition = _position! + details.delta;
      final screenSize = MediaQuery.of(context).size;
      final safeArea = MediaQuery.of(context).padding;

      final currentWidgetWidth =
          _widgetSize?.width ?? (_isExpanded ? 250.0 : 150.0);
      final measuredHeight =
          _widgetSize?.height ?? (_isExpanded ? 300.0 : 100.0);
      final currentWidgetHeight =
          (_widgetSize != null && _isExpanded == false && measuredHeight > 200)
              ? 100.0
              : (_isExpanded ? 300.0 : 100.0);

      final minX = currentWidgetWidth / 2 + widget.edgePadding;
      final maxX =
          screenSize.width - currentWidgetWidth / 2 - widget.edgePadding;
      final clampedX = newPosition.dx.clamp(minX, maxX);

      final minY = safeArea.top + currentWidgetHeight / 2 + widget.edgePadding;
      final maxY = screenSize.height -
          safeArea.bottom -
          currentWidgetHeight / 2 -
          widget.edgePadding;
      final clampedY = newPosition.dy.clamp(minY, maxY);

      _position = Offset(clampedX, clampedY);

      // Auto-expand/collapse logic
      final availableHeight =
          screenSize.height - safeArea.top - safeArea.bottom;
      final edgeThresholdPercent = 0.15;
      final edgeThresholdDistance = availableHeight * edgeThresholdPercent;

      final distanceToTopEdge =
          clampedY - safeArea.top - currentWidgetHeight / 2;
      final distanceToBottomEdge = screenSize.height -
          safeArea.bottom -
          clampedY -
          currentWidgetHeight / 2;
      final distanceToNearestEdge = distanceToTopEdge < distanceToBottomEdge
          ? distanceToTopEdge
          : distanceToBottomEdge;

      final centerY = safeArea.top + availableHeight / 2;

      if (!_isExpanded && distanceToNearestEdge > edgeThresholdDistance) {
        final isNearTop = distanceToTopEdge < distanceToBottomEdge;
        _expandedFromTop = isNearTop;
        _isExpanded = true;
        _isAnimating = true;
        _animationController.forward().then((_) {
          if (mounted) {
            setState(() {
              _isAnimating = false;
            });
          }
        });
        _position = Offset(screenSize.width / 2, centerY);
        widget.onExpandChanged?.call(true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _measureWidgetSize();
        });
      } else if (_isExpanded &&
          distanceToNearestEdge <= edgeThresholdDistance) {
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

    final screenSize = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;
    final availableHeight = screenSize.height - safeArea.top - safeArea.bottom;
    final edgeThresholdPercent = 0.15;
    final edgeThresholdDistance = availableHeight * edgeThresholdPercent;

    final effectiveHeight =
        _widgetSize?.height ?? (_isExpanded ? 300.0 : 100.0);
    final distanceToTopEdge =
        _position!.dy - safeArea.top - effectiveHeight / 2;
    final distanceToBottomEdge = screenSize.height -
        safeArea.bottom -
        _position!.dy -
        effectiveHeight / 2;
    final distanceToNearestEdge = distanceToTopEdge < distanceToBottomEdge
        ? distanceToTopEdge
        : distanceToBottomEdge;

    final centerY = safeArea.top + availableHeight / 2;

    if (!_isExpanded && distanceToNearestEdge > edgeThresholdDistance) {
      final isNearTop = distanceToTopEdge < distanceToBottomEdge;
      setState(() {
        _expandedFromTop = isNearTop;
        _isExpanded = true;
        _isAnimating = true;
        _animationController.forward().then((_) {
          if (mounted) {
            setState(() {
              _isAnimating = false;
            });
          }
        });
        _position = Offset(screenSize.width / 2, centerY);
      });
      widget.onExpandChanged?.call(true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _measureWidgetSize();
      });
    } else if (_isExpanded && distanceToNearestEdge <= edgeThresholdDistance) {
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

    final screenSize = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;
    final viewPadding = MediaQuery.of(context).viewPadding;

    // Get actual widget dimensions - use conservative estimate if not measured
    // Use larger estimate to prevent clipping
    final estimatedWidth = _isExpanded ? screenSize.width * 0.9 : 200.0;
    final widgetWidth = _widgetSize?.width ?? estimatedWidth;

    // If widget hasn't been measured yet, trigger measurement
    if (_widgetSize == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureWidgetSize());
    }
    final effectiveHeight = _getEffectiveHeight(screenSize);

    // Determine which edge to snap to (top or bottom)
    final currentY = _position!.dy;
    final distanceToTop = currentY - safeArea.top - effectiveHeight / 2;
    final distanceToBottom =
        screenSize.height - safeArea.bottom - currentY - effectiveHeight / 2;
    final snappingToTop = distanceToTop < distanceToBottom;

    double targetX;
    // When snapping to top, always center horizontally
    // When snapping to bottom, use the configured alignment
    if (snappingToTop) {
      targetX = screenSize.width / 2;
    } else {
      final effectiveAlignment = widget.alignment ??
          (widget.position == FloatingPosition.top
              ? FloatingAlignment.center
              : FloatingAlignment.right);

      switch (effectiveAlignment) {
        case FloatingAlignment.left:
          targetX = widgetWidth / 2 +
              widget.padding.left +
              safeArea.left +
              widget.edgePadding;
          break;
        case FloatingAlignment.right:
          // Position at right edge - account for SafeArea and edge padding
          // targetX is the center X coordinate, so we need widgetWidth/2 from the right edge
          targetX = screenSize.width -
              safeArea.right -
              widget.edgePadding -
              widgetWidth / 2;
          break;
        case FloatingAlignment.center:
          targetX = screenSize.width / 2;
          break;
      }
    }

    // Ensure targetX keeps widget on screen
    final minX = widgetWidth / 2 + safeArea.left + widget.edgePadding;
    final maxX = screenSize.width -
        widgetWidth / 2 -
        safeArea.right -
        widget.edgePadding;

    if (maxX < minX) {
      // Widget is too wide, center it
      targetX = screenSize.width / 2;
    } else {
      targetX = targetX.clamp(minX, maxX);
    }

    double targetY;

    if (snappingToTop) {
      targetY = safeArea.top + widget.edgePadding + effectiveHeight / 2;
    } else {
      // Calculate bottom position more carefully to prevent clipping
      // Use viewPadding.bottom to account for navigation bar and other system UI
      // Position from bottom edge: viewPadding.bottom + edgePadding + half widget height
      final bottomEdge = screenSize.height - viewPadding.bottom;
      targetY = bottomEdge - widget.edgePadding - effectiveHeight / 2;
    }

    // Ensure targetY keeps widget on screen
    final minY = safeArea.top + widget.edgePadding + effectiveHeight / 2;
    final maxY = screenSize.height -
        viewPadding.bottom -
        widget.edgePadding -
        effectiveHeight / 2;
    targetY = targetY.clamp(minY, maxY);

    final startPosition = _position!;
    final targetPosition = Offset(targetX, targetY);

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

  /// Calculate effective height (handles expanded state mismatch)
  double _getEffectiveHeight(Size screenSize) {
    if (_widgetSize == null) {
      return _isExpanded ? 300.0 : 100.0;
    }
    final measuredHeight = _widgetSize!.height;
    if (!_isExpanded && measuredHeight > 200) {
      return 100.0; // Widget was measured while expanded, but is now collapsed
    }
    return measuredHeight;
  }

  /// Calculate positioning for dragged state
  ({double? left, double? top, double? right, double? bottom})
      _calculateDraggedPosition(
    Size screenSize,
    EdgeInsets safeArea,
    EdgeInsets viewPadding,
  ) {
    // Use actual measured width if available, otherwise estimate conservatively
    // Use a larger estimate to prevent clipping
    final estimatedWidth = _isExpanded ? screenSize.width * 0.9 : 200.0;
    final widgetWidth = _widgetSize?.width ?? estimatedWidth;
    final effectiveHeight = _getEffectiveHeight(screenSize);

    // If widget hasn't been measured yet, trigger measurement
    if (_widgetSize == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureWidgetSize());
    }

    // Calculate left position from center point
    var left = _position!.dx - widgetWidth / 2;

    // Clamp to ensure widget stays on screen with edge padding
    // Account for SafeArea on both sides
    final minLeft = safeArea.left + widget.edgePadding;
    final maxLeft =
        screenSize.width - safeArea.right - widgetWidth - widget.edgePadding;

    // Ensure maxLeft is valid (widget might be wider than screen)
    if (maxLeft < minLeft) {
      // Widget is too wide, center it
      left = (screenSize.width - widgetWidth) / 2;
    } else {
      left = left.clamp(minLeft, maxLeft);
    }

    // Calculate top position from center point
    final calculatedTop = _position!.dy - effectiveHeight / 2;
    final minTop = safeArea.top + widget.edgePadding;
    final maxTop = screenSize.height -
        viewPadding.bottom -
        effectiveHeight -
        widget.edgePadding;
    final top = calculatedTop.clamp(minTop, maxTop);

    return (left: left, top: top, right: null, bottom: null);
  }

  /// Calculate positioning for default (non-dragged) state
  ({double? left, double? top, double? right, double? bottom})
      _calculateDefaultPosition(
    Size screenSize,
    EdgeInsets safeArea,
    EdgeInsets viewPadding,
  ) {
    // Determine effective alignment based on position and widget alignment
    final effectiveAlignment = widget.alignment ??
        (widget.position == FloatingPosition.top
            ? FloatingAlignment.center
            : FloatingAlignment.right);

    double? left, right;

    // Calculate horizontal position
    switch (effectiveAlignment) {
      case FloatingAlignment.left:
        left = widget.padding.left + safeArea.left + widget.edgePadding;
        break;
      case FloatingAlignment.right:
        right = safeArea.right + widget.edgePadding;
        break;
      case FloatingAlignment.center:
        // Don't set left/right - let Align widget handle centering
        break;
    }

    // Calculate vertical position
    double? top, bottom;
    switch (widget.position) {
      case FloatingPosition.top:
        top = widget.padding.top + safeArea.top + widget.edgePadding;
        break;
      case FloatingPosition.bottom:
        bottom = viewPadding.bottom + widget.edgePadding;
        break;
    }

    return (left: left, top: top, right: right, bottom: bottom);
  }

  @override
  Widget build(BuildContext context) {
    final safeArea = MediaQuery.of(context).padding;
    final viewPadding = MediaQuery.of(context).viewPadding;
    final screenSize = MediaQuery.of(context).size;

    // Calculate positioning
    final position = _position != null
        ? _calculateDraggedPosition(screenSize, safeArea, viewPadding)
        : _calculateDefaultPosition(screenSize, safeArea, viewPadding);

    final left = position.left;
    final top = position.top;
    final right = position.right;
    final bottom = position.bottom;

    // Calculate which position the widget is near based on actual position
    final nearPosition = _position == null
        ? widget.position
        : ((_expandedFromTop ??
                (_position!.dy <
                    (screenSize.height - safeArea.top - safeArea.bottom) / 2 +
                        safeArea.top))
            ? FloatingPosition.top
            : FloatingPosition.bottom);

    final callbacks = ExpandableCallbacks(
      expand: _expand,
      collapse: _collapse,
      toggle: _toggleExpand,
      isExpanded: _isExpanded,
      nearPosition: nearPosition,
    );

    final isCenterAlignment = _position == null &&
        (widget.alignment ??
                (widget.position == FloatingPosition.top
                    ? FloatingAlignment.center
                    : FloatingAlignment.right)) ==
            FloatingAlignment.center;

    if (isCenterAlignment) {
      // For center alignment, use Positioned.fill to give full width, then Align to center
      return Positioned.fill(
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Align(
            alignment: widget.position == FloatingPosition.top
                ? Alignment.topCenter
                : Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                top: widget.position == FloatingPosition.top
                    ? widget.padding.top + safeArea.top + widget.edgePadding
                    : 0,
                bottom: widget.position == FloatingPosition.bottom
                    ? viewPadding.bottom + widget.edgePadding
                    : 0,
              ),
              child: _buildContent(context, callbacks),
            ),
          ),
        ),
      );
    }

    // When using left/top positioning, verify widget fits on screen
    double? finalLeft = left;
    double? finalTop = top;
    double? finalRight = right;
    double? finalBottom = bottom;

    if (finalLeft != null && _widgetSize != null) {
      // Verify left positioning doesn't go off-screen
      final widgetWidth = _widgetSize!.width;
      final maxLeft =
          screenSize.width - safeArea.right - widgetWidth - widget.edgePadding;
      if (finalLeft > maxLeft) {
        finalLeft = maxLeft;
      }
    }

    if (finalTop != null && _widgetSize != null) {
      // Verify top positioning doesn't go off-screen
      final effectiveHeight = _getEffectiveHeight(screenSize);
      final maxTop = screenSize.height -
          viewPadding.bottom -
          effectiveHeight -
          widget.edgePadding;
      if (finalTop > maxTop) {
        finalTop = maxTop;
      }
    }

    return Positioned(
      left: finalLeft,
      top: finalTop,
      right: finalRight,
      bottom: finalBottom,
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
