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

/// Snapping behavior mode for the floating widget
enum SnapMode {
  /// Never snap to edges - free movement
  never,

  /// Always snap to nearest edge when drag ends
  onDragEnd,

  /// Snap when within threshold distance from edge (during drag)
  onThreshold,

  /// Snap both on threshold and on drag end
  always,
}

/// Configuration for floating widget behavior, snapping, and animations.
///
/// Provides various settings to control how the widget behaves when dragged,
/// when it expands/collapses, and how it snaps to edges.
class FloatConfiguration {
  const FloatConfiguration({
    this.snapMode = SnapMode.always,
    this.edgeThresholdPercent = 0.15,
    this.expansionThresholdPercent = 0.15,
    this.topAlignment = FloatingAlignment.center,
    this.bottomAlignment = FloatingAlignment.center,
    this.snapToCenterHorizontally = true,
    this.enableDragging = true,
    this.enableAutoExpand = true,
    this.enableAutoCollapse = true,
    this.centerOnExpand = true,
    this.expandAnimationDuration = const Duration(milliseconds: 300),
    this.snapAnimationDuration = const Duration(milliseconds: 300),
    this.expandAnimationCurve = Curves.easeInOutCubic,
    this.snapAnimationCurve = Curves.easeOutCubic,
  });

  /// Free movement mode - no snapping, widget can be positioned anywhere
  const FloatConfiguration.free()
      : snapMode = SnapMode.never,
        edgeThresholdPercent = 0.0,
        expansionThresholdPercent = 0.0,
        topAlignment = FloatingAlignment.center,
        bottomAlignment = FloatingAlignment.center,
        snapToCenterHorizontally = false,
        enableDragging = true,
        enableAutoExpand = false,
        enableAutoCollapse = false,
        centerOnExpand = false,
        expandAnimationDuration = const Duration(milliseconds: 300),
        snapAnimationDuration = const Duration(milliseconds: 300),
        expandAnimationCurve = Curves.easeInOutCubic,
        snapAnimationCurve = Curves.easeOutCubic;

  /// Default snapping behavior - snaps to edges with threshold-based expansion
  const FloatConfiguration.snapToEdges({
    this.edgeThresholdPercent = 0.15,
    this.expansionThresholdPercent = 0.15,
    this.topAlignment = FloatingAlignment.center,
    this.bottomAlignment = FloatingAlignment.center,
    this.snapToCenterHorizontally = true,
    this.expandAnimationDuration = const Duration(milliseconds: 300),
    this.snapAnimationDuration = const Duration(milliseconds: 300),
  })  : snapMode = SnapMode.always,
        enableDragging = true,
        enableAutoExpand = true,
        enableAutoCollapse = true,
        centerOnExpand = true,
        expandAnimationCurve = Curves.easeInOutCubic,
        snapAnimationCurve = Curves.easeOutCubic;

  /// Custom configuration with all options
  const FloatConfiguration.custom({
    required this.snapMode,
    this.edgeThresholdPercent = 0.15,
    this.expansionThresholdPercent = 0.15,
    this.topAlignment = FloatingAlignment.center,
    this.bottomAlignment = FloatingAlignment.center,
    this.snapToCenterHorizontally = true,
    this.enableDragging = true,
    this.enableAutoExpand = true,
    this.enableAutoCollapse = true,
    this.centerOnExpand = true,
    this.expandAnimationDuration = const Duration(milliseconds: 300),
    this.snapAnimationDuration = const Duration(milliseconds: 300),
    this.expandAnimationCurve = Curves.easeInOutCubic,
    this.snapAnimationCurve = Curves.easeOutCubic,
  });

  /// Default configuration (same as snapToEdges)
  static const FloatConfiguration defaultConfig =
      FloatConfiguration.snapToEdges();

  /// How the widget should snap to edges
  final SnapMode snapMode;

  /// Percentage of screen height used as threshold for edge detection (0.0 to 1.0)
  final double edgeThresholdPercent;

  /// Percentage of screen height used as threshold for auto-expansion (0.0 to 1.0)
  final double expansionThresholdPercent;

  /// Preferred horizontal alignment when widget snaps to top edge
  final FloatingAlignment topAlignment;

  /// Preferred horizontal alignment when widget snaps to bottom edge
  final FloatingAlignment bottomAlignment;

  /// Whether to snap horizontally to center when snapping to edges
  final bool snapToCenterHorizontally;

  /// Whether dragging is enabled
  final bool enableDragging;

  /// Whether widget should auto-expand when dragged away from edges
  final bool enableAutoExpand;

  /// Whether widget should auto-collapse when dragged near edges
  final bool enableAutoCollapse;

  /// Whether to center widget on screen when expanding
  final bool centerOnExpand;

  /// Duration of expand/collapse animation
  final Duration expandAnimationDuration;

  /// Duration of snap-to-edge animation
  final Duration snapAnimationDuration;

  /// Animation curve for expand/collapse
  final Curve expandAnimationCurve;

  /// Animation curve for snap animation
  final Curve snapAnimationCurve;
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

/// A barebones floating expandable widget that handles drag, snap, and expand/collapse logic.
///
/// This is the base layer that handles all the positioning, dragging, snapping, and animation
/// logic. Child widgets are built via builders and receive callbacks to control expand/collapse.
///
/// **Usage:**
/// ```dart
/// FloatingExpandableWidget(
///   collapsedWidget: (context, callbacks) => YourCollapsedWidget(callbacks: callbacks),
///   expandedWidget: (context, callbacks) => YourExpandedWidget(callbacks: callbacks),
///   draggableIndicator: (context, callbacks) => YourPillWidget(),
///   expandCollapseButton: (context, callbacks) => YourArrowButton(
///     onTap: callbacks.toggle,
///   ),
///   position: FloatingPosition.bottom,
///   floatConfiguration: FloatConfiguration.snapToEdges(),
/// )
/// ```
class FloatingExpandableWidget extends StatefulWidget {
  const FloatingExpandableWidget({
    required this.collapsedWidget,
    required this.expandedWidget,
    required this.draggableIndicator,
    required this.expandCollapseButton,
    this.position = FloatingPosition.top,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.floatConfiguration = const FloatConfiguration.snapToEdges(),
    this.onExpandChanged,
    super.key,
  });

  /// Builder for the collapsed state widget
  /// Receives callbacks to control expand/collapse
  final Widget Function(BuildContext context, ExpandableCallbacks callbacks)
      collapsedWidget;

  /// Builder for the expanded state widget
  /// Receives callbacks to control expand/collapse
  final Widget Function(BuildContext context, ExpandableCallbacks callbacks)
      expandedWidget;

  /// Builder for the draggable indicator (pill)
  /// Receives callbacks to control expand/collapse
  final Widget Function(BuildContext context, ExpandableCallbacks callbacks)
      draggableIndicator;

  /// Builder for the expand/collapse button (arrow)
  /// Receives callbacks to control expand/collapse
  final Widget Function(BuildContext context, ExpandableCallbacks callbacks)
      expandCollapseButton;

  /// Initial position of the widget
  final FloatingPosition position;

  /// Padding around the widget content
  final EdgeInsets padding;

  /// Configuration for floating behavior, snapping, and animations
  final FloatConfiguration floatConfiguration;

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
  Offset? _dragStartPosition;
  Offset? _position;
  Size? _widgetSize;
  final GlobalKey _widgetKey = GlobalKey();

  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late AnimationController _snapAnimationController;
  Animation<Offset>? _snapAnimation;

  @override
  void initState() {
    super.initState();
    final config = widget.floatConfiguration;
    _animationController = AnimationController(
      vsync: this,
      duration: config.expandAnimationDuration,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: config.expandAnimationCurve,
    );
    _snapAnimationController = AnimationController(
      vsync: this,
      duration: config.snapAnimationDuration,
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
    final config = widget.floatConfiguration;

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
        if (config.centerOnExpand) {
          final centerX = screenSize.width / 2;
          final centerY = safeArea.top +
              (screenSize.height - safeArea.top - safeArea.bottom) / 2;
          _position = Offset(centerX, centerY);
        }
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
      if (wasExpanded &&
          !_isExpanded &&
          _position != null &&
          config.snapMode != SnapMode.never) {
        _snapToNearestEdge();
      }
    });
  }

  void _expand() {
    if (!_isExpanded) _toggleExpand();
  }

  void _collapse() {
    if (_isExpanded) _toggleExpand();
  }

  void _onPanStart(DragStartDetails details) {
    final config = widget.floatConfiguration;
    if (!config.enableDragging) return;

    _dragStartPosition = _position;
    if (_position == null) {
      final screenSize = MediaQuery.of(context).size;
      final safeArea = MediaQuery.of(context).padding;

      double initialX;
      double initialY;

      final widgetWidth = _widgetSize?.width ?? 150.0;
      final widgetHeight = _widgetSize?.height ?? 100.0;

      final alignment = widget.position == FloatingPosition.top
          ? config.topAlignment
          : config.bottomAlignment;

      switch (alignment) {
        case FloatingAlignment.left:
          initialX = widget.padding.left + safeArea.left + widgetWidth / 2;
          break;
        case FloatingAlignment.right:
          initialX = screenSize.width -
              widget.padding.right -
              safeArea.right -
              widgetWidth / 2;
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
          initialY = screenSize.height -
              widget.padding.bottom -
              safeArea.bottom -
              widgetHeight / 2;
          break;
      }

      _position = Offset(initialX, initialY);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final config = widget.floatConfiguration;
    if (!config.enableDragging) return;

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

      final minY = currentWidgetHeight / 2;
      final maxY =
          screenSize.height - safeArea.bottom - currentWidgetHeight / 2;

      final clampedY = newPosition.dy.clamp(minY, maxY);

      _position = Offset(clampedX, clampedY);

      if (config.enableAutoExpand || config.enableAutoCollapse) {
        final availableHeight =
            screenSize.height - safeArea.top - safeArea.bottom;
        final edgeThresholdDistance =
            availableHeight * config.edgeThresholdPercent;
        final expansionThresholdDistance =
            availableHeight * config.expansionThresholdPercent;

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

        if (config.enableAutoExpand &&
            !_isExpanded &&
            distanceToNearestEdge > expansionThresholdDistance) {
          final referenceY = _dragStartPosition?.dy ?? clampedY;
          final referenceDistanceToTop =
              referenceY - safeArea.top - currentWidgetHeight / 2;
          final referenceDistanceToBottom = screenSize.height -
              safeArea.bottom -
              referenceY -
              currentWidgetHeight / 2;
          final isNearTop = referenceDistanceToTop < referenceDistanceToBottom;

          setState(() {
            _expandedFromTop = isNearTop;
            _isExpanded = true;
            _isAnimating = true;
          });
          _animationController.forward().then((_) {
            if (mounted) {
              setState(() {
                _isAnimating = false;
              });
            }
          });
          if (config.centerOnExpand) {
            _position = Offset(screenSize.width / 2, centerY);
          }
          widget.onExpandChanged?.call(true);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _measureWidgetSize();
          });
        } else if (config.enableAutoCollapse &&
            _isExpanded &&
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
            if (config.snapMode == SnapMode.onThreshold ||
                config.snapMode == SnapMode.always) {
              _snapToNearestEdge();
            }
          });
        }
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final config = widget.floatConfiguration;
    if (!config.enableDragging) return;

    if (_position == null) return;

    final screenSize = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;
    final availableHeight = screenSize.height - safeArea.top - safeArea.bottom;
    final edgeThresholdDistance = availableHeight * config.edgeThresholdPercent;
    final expansionThresholdDistance =
        availableHeight * config.expansionThresholdPercent;

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

    if (config.enableAutoExpand &&
        !_isExpanded &&
        distanceToNearestEdge > expansionThresholdDistance) {
      final referenceY = _dragStartPosition?.dy ?? _position!.dy;
      final referenceDistanceToTop =
          referenceY - safeArea.top - effectiveHeight / 2;
      final referenceDistanceToBottom = screenSize.height -
          safeArea.bottom -
          referenceY -
          effectiveHeight / 2;
      final isNearTop = referenceDistanceToTop < referenceDistanceToBottom;

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
        if (config.centerOnExpand) {
          _position = Offset(screenSize.width / 2, centerY);
        }
      });
      widget.onExpandChanged?.call(true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _measureWidgetSize();
      });
    } else if (config.enableAutoCollapse &&
        _isExpanded &&
        distanceToNearestEdge <= edgeThresholdDistance) {
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
        if (config.snapMode == SnapMode.onDragEnd ||
            config.snapMode == SnapMode.always) {
          _snapToNearestEdge();
        }
      });
    } else if (!_isExpanded &&
        (config.snapMode == SnapMode.onDragEnd ||
            config.snapMode == SnapMode.always)) {
      _snapToNearestEdge();
    }
  }

  void _snapToNearestEdge() {
    final config = widget.floatConfiguration;
    if (config.snapMode == SnapMode.never) return;

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

    final widgetWidth = _widgetSize?.width ?? 150.0;

    final currentY = _position!.dy;
    final distanceToTop = currentY - effectiveHeight / 2;
    final distanceToBottom =
        screenSize.height - safeArea.bottom - currentY - effectiveHeight / 2;

    final isSnappingToTop = distanceToTop < distanceToBottom;

    double targetX;
    if (config.snapToCenterHorizontally) {
      targetX = screenSize.width / 2;
    } else {
      final alignment =
          isSnappingToTop ? config.topAlignment : config.bottomAlignment;

      switch (alignment) {
        case FloatingAlignment.left:
          targetX = widget.padding.left + safeArea.left + widgetWidth / 2;
          break;
        case FloatingAlignment.right:
          targetX = screenSize.width -
              widget.padding.right -
              safeArea.right -
              widgetWidth / 2;
          break;
        case FloatingAlignment.center:
          targetX = screenSize.width / 2;
          break;
      }
    }

    double targetY;
    if (isSnappingToTop) {
      targetY = effectiveHeight / 2;
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
      curve: config.snapAnimationCurve,
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
      final widgetWidth = _widgetSize?.width ?? (_isExpanded ? 250.0 : 150.0);
      final measuredHeight =
          _widgetSize?.height ?? (_isExpanded ? 300.0 : 100.0);
      final effectiveHeight =
          (_widgetSize != null && _isExpanded == false && measuredHeight > 200)
              ? 100.0
              : (_isExpanded ? 300.0 : 100.0);
      left = _position!.dx - widgetWidth / 2;
      final calculatedTop = _position!.dy - effectiveHeight / 2;
      top = calculatedTop.clamp(
          safeArea.top, screenSize.height - safeArea.bottom - effectiveHeight);
    } else {
      final config = widget.floatConfiguration;
      final alignment = widget.position == FloatingPosition.top
          ? config.topAlignment
          : config.bottomAlignment;

      switch (alignment) {
        case FloatingAlignment.left:
          left = widget.padding.left + safeArea.left;
          break;
        case FloatingAlignment.right:
          right = widget.padding.right + safeArea.right;
          break;
        case FloatingAlignment.center:
          break;
      }

      switch (widget.position) {
        case FloatingPosition.top:
          top = widget.padding.top + safeArea.top;
          break;
        case FloatingPosition.bottom:
          bottom = widget.padding.bottom + safeArea.bottom;
          break;
      }
    }

    final callbacks = ExpandableCallbacks(
      expand: _expand,
      collapse: _collapse,
      toggle: _toggleExpand,
      isExpanded: _isExpanded,
    );

    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: widget.floatConfiguration.enableDragging
          ? GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: _position == null &&
                      (widget.position == FloatingPosition.top
                              ? widget.floatConfiguration.topAlignment
                              : widget.floatConfiguration.bottomAlignment) ==
                          FloatingAlignment.center
                  ? Align(
                      alignment: widget.position == FloatingPosition.top
                          ? Alignment.topCenter
                          : Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: widget.position == FloatingPosition.top
                              ? widget.padding.top + safeArea.top
                              : 0,
                          bottom: widget.position == FloatingPosition.bottom
                              ? widget.padding.bottom + safeArea.bottom
                              : 0,
                        ),
                        child: _buildContent(context, callbacks),
                      ),
                    )
                  : _buildContent(context, callbacks),
            )
          : _buildContent(context, callbacks),
    );
  }

  Widget _buildContent(BuildContext context, ExpandableCallbacks callbacks) {
    final screenSize = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;
    final isNearTop = _isExpanded && _expandedFromTop != null
        ? _expandedFromTop!
        : (_position == null
            ? widget.position == FloatingPosition.top
            : _position!.dy <
                (screenSize.height - safeArea.top - safeArea.bottom) / 2 +
                    safeArea.top);

    final expandingFromTop = _expandedFromTop ??
        (_position == null
            ? widget.position == FloatingPosition.top
            : _position!.dy <
                (screenSize.height - safeArea.top - safeArea.bottom) / 2 +
                    safeArea.top);

    return Padding(
      padding: _position == null ? widget.padding : EdgeInsets.zero,
      child: IntrinsicWidth(
        key: _widgetKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: _isExpanded ? 12 : 6,
                vertical: _isExpanded ? 10 : 6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isNearTop) ...[
                    widget.draggableIndicator(context, callbacks),
                    const SizedBox(height: 4),
                  ] else ...[
                    widget.expandCollapseButton(context, callbacks),
                    const SizedBox(height: 4),
                  ],
                  if (!_isExpanded) widget.collapsedWidget(context, callbacks),
                  SizeTransition(
                    sizeFactor: _expandAnimation,
                    axisAlignment: expandingFromTop ? -1.0 : 1.0,
                    child: widget.expandedWidget(context, callbacks),
                  ),
                  if (isNearTop) ...[
                    widget.expandCollapseButton(context, callbacks),
                  ] else ...[
                    const SizedBox(height: 4),
                    widget.draggableIndicator(context, callbacks),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
