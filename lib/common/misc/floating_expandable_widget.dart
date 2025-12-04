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
  });

  /// Callback to expand the widget
  final VoidCallback expand;

  /// Callback to collapse the widget
  final VoidCallback collapse;

  /// Callback to toggle expand/collapse state
  final VoidCallback toggle;

  /// Whether the widget is currently expanded
  final bool isExpanded;
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
      setState(() {
        _widgetSize = renderBox.size;
      });
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
          // No padding for right alignment - position at edge
          initialX = screenSize.width - safeArea.right - widgetWidth / 2;
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
          // No padding for bottom position - position at edge
          initialY = screenSize.height - safeArea.bottom - widgetHeight / 2;
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

      final clampedX = newPosition.dx.clamp(
        currentWidgetWidth / 2,
        screenSize.width - currentWidgetWidth / 2,
      );

      final minY = safeArea.top + currentWidgetHeight / 2;
      final maxY =
          screenSize.height - safeArea.bottom - currentWidgetHeight / 2;
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
    final toolbarHeight = _isExpanded
        ? (_widgetSize?.height ?? 300.0)
        : (_widgetSize?.height ?? 100.0);

    final effectiveHeight = (_widgetSize != null &&
            _isExpanded == false &&
            _widgetSize!.height > 200)
        ? 100.0
        : toolbarHeight;

    final effectiveAlignment = widget.alignment ??
        (widget.position == FloatingPosition.top
            ? FloatingAlignment.center
            : FloatingAlignment.right);
    final widgetWidth = _widgetSize?.width ?? (_isExpanded ? 250.0 : 150.0);
    double targetX;
    switch (effectiveAlignment) {
      case FloatingAlignment.left:
        targetX = widgetWidth / 2 + widget.padding.left + safeArea.left;
        break;
      case FloatingAlignment.right:
        // No padding for right alignment - position at edge
        targetX = screenSize.width - widgetWidth / 2 - safeArea.right;
        break;
      case FloatingAlignment.center:
        targetX = screenSize.width / 2;
        break;
    }
    double targetY;

    final currentY = _position!.dy;
    final distanceToTop = currentY - safeArea.top - effectiveHeight / 2;
    final distanceToBottom =
        screenSize.height - safeArea.bottom - currentY - effectiveHeight / 2;

    if (distanceToTop < distanceToBottom) {
      targetY = safeArea.top + effectiveHeight / 2;
    } else {
      targetY = screenSize.height - safeArea.bottom - effectiveHeight / 2;
    }

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

  @override
  Widget build(BuildContext context) {
    final safeArea = MediaQuery.of(context).padding;
    final screenSize = MediaQuery.of(context).size;

    double? left, top, right, bottom;

    if (_position != null) {
      // Use actual measured width if available, otherwise estimate
      final widgetWidth =
          _widgetSize?.width ?? (_isExpanded ? screenSize.width * 0.9 : 150.0);
      final measuredHeight =
          _widgetSize?.height ?? (_isExpanded ? 300.0 : 100.0);
      final effectiveHeight =
          (_widgetSize != null && _isExpanded == false && measuredHeight > 200)
              ? 100.0
              : (_isExpanded ? 300.0 : 100.0);

      // Calculate left position from center point
      left = _position!.dx - widgetWidth / 2;

      // Clamp to ensure widget stays on screen
      final maxLeft = screenSize.width - widgetWidth;
      if (left < 0) {
        left = 0;
      } else if (left > maxLeft) {
        left = maxLeft;
      }

      final calculatedTop = _position!.dy - effectiveHeight / 2;
      top = calculatedTop.clamp(
          safeArea.top, screenSize.height - safeArea.bottom - effectiveHeight);
    } else {
      final effectiveAlignment = widget.alignment ??
          (widget.position == FloatingPosition.top
              ? FloatingAlignment.center
              : FloatingAlignment.right);

      switch (effectiveAlignment) {
        case FloatingAlignment.left:
          left = widget.padding.left + safeArea.left;
          break;
        case FloatingAlignment.right:
          // No padding for right alignment - position at edge
          right = safeArea.right;
          break;
        case FloatingAlignment.center:
          // Don't set left/right - let Align widget handle centering
          break;
      }

      switch (widget.position) {
        case FloatingPosition.top:
          top = widget.padding.top + safeArea.top;
          break;
        case FloatingPosition.bottom:
          // No padding for bottom position - position at edge
          bottom = safeArea.bottom;
          break;
      }
    }

    final callbacks = ExpandableCallbacks(
      expand: _expand,
      collapse: _collapse,
      toggle: _toggleExpand,
      isExpanded: _isExpanded,
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
                    ? widget.padding.top + safeArea.top
                    : 0,
                bottom: widget.position == FloatingPosition.bottom
                    ? safeArea.bottom
                    : 0,
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
    // Only apply padding when position is null and alignment is not right/bottom
    final effectiveAlignment = widget.alignment ??
        (widget.position == FloatingPosition.top
            ? FloatingAlignment.center
            : FloatingAlignment.right);

    final shouldApplyPadding = _position == null &&
        effectiveAlignment != FloatingAlignment.right &&
        widget.position != FloatingPosition.bottom;

    return Padding(
      padding: shouldApplyPadding ? widget.padding : EdgeInsets.zero,
      child: widget.contentBuilder(context, callbacks),
    );
  }
}
