import 'package:diohub/common/misc/floating_widget_position_calculator.dart';
import 'package:flutter/material.dart';

/// Position of the floating widget
enum FloatingPosition { top, bottom }

/// Horizontal alignment of the floating widget
enum FloatingAlignment { left, center, right }

/// Callbacks provided to child widgets for controlling expand/collapse state
class ExpandableCallbacks {
  const ExpandableCallbacks({
    required this.expand,
    required this.collapse,
    required this.toggle,
    required this.isExpanded,
    required this.nearPosition,
  });

  final VoidCallback expand;
  final VoidCallback collapse;
  final VoidCallback toggle;
  final bool isExpanded;
  final FloatingPosition nearPosition;
}

/// A floating expandable widget with drag-to-expand behavior.
///
/// Behavior:
/// - Starts collapsed at default position
/// - Dragging collapses immediately and stays collapsed during drag
/// - Drag ends near center: expands and centers
/// - Drag ends near edge: collapses and snaps to edge
class FloatingExpandableWidget extends StatefulWidget {
  const FloatingExpandableWidget({
    required this.contentBuilder,
    this.position = FloatingPosition.top,
    this.alignment,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.edgePadding = 8.0,
    this.bottomPadding = 0.0,
    this.debugLogging = false,
    this.onExpandChanged,
    super.key,
  }) : calculator = null;

  const FloatingExpandableWidget.customFloat({
    required this.calculator,
    required this.contentBuilder,
    this.debugLogging = false,
    this.onExpandChanged,
    super.key,
  })  : position = FloatingPosition.top,
        alignment = null,
        padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        edgePadding = 8.0,
        bottomPadding = 0.0;

  final Widget Function(BuildContext context, ExpandableCallbacks callbacks)
      contentBuilder;
  final FloatingPosition position;
  final FloatingAlignment? alignment;
  final EdgeInsets padding;
  final double edgePadding;
  final double bottomPadding;
  final FloatingWidgetPositionCalculator? calculator;
  final bool debugLogging;
  final void Function(bool isExpanded)? onExpandChanged;

  @override
  State<FloatingExpandableWidget> createState() =>
      _FloatingExpandableWidgetState();
}

class _FloatingExpandableWidgetState extends State<FloatingExpandableWidget>
    with TickerProviderStateMixin {
  // State
  bool _isExpanded = false;
  bool _isDragging = false;
  bool _wasExpandedBeforeDrag =
      false; // Track if tile was expanded before drag started
  Offset?
      _centerPosition; // null = use default, otherwise absolute center point
  Size? _widgetSize;
  Size? _lockedSizeDuringDrag; // Lock size during drag to prevent jumps
  Offset? _dragStartCenterOffset; // Offset from drag start to widget center
  final GlobalKey _widgetKey = GlobalKey();

  // Animations
  late AnimationController _expandController;
  late AnimationController _snapController;
  Animation<Offset>? _snapAnimation;

  FloatingWidgetPositionCalculator get _calculator {
    if (widget.calculator != null) {
      if (widget.calculator!.bottomPadding != widget.bottomPadding ||
          widget.calculator!.debugLogging != widget.debugLogging) {
        return FloatingWidgetPositionCalculator(
          position: widget.position,
          alignment: widget.alignment,
          padding: widget.padding,
          edgePadding: widget.edgePadding,
          bottomPadding: widget.bottomPadding,
          debugLogging: widget.debugLogging,
        );
      }
      return widget.calculator!;
    }
    return FloatingWidgetPositionCalculator(
      position: widget.position,
      alignment: widget.alignment,
      padding: widget.padding,
      edgePadding: widget.edgePadding,
      bottomPadding: widget.bottomPadding,
      debugLogging: widget.debugLogging,
    );
  }

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _snapController.addListener(_onSnapUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureSize());
  }

  @override
  void dispose() {
    _snapController.removeListener(_onSnapUpdate);
    _expandController.dispose();
    _snapController.dispose();
    super.dispose();
  }

  void _onSnapUpdate() {
    if (_snapAnimation != null && mounted) {
      setState(() {
        _centerPosition = _snapAnimation!.value;
      });
    }
  }

  void _snapAfterAnimationListener(AnimationStatus status) {
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      _expandController.removeStatusListener(_snapAfterAnimationListener);
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _snapToEdge();
          }
        });
      }
    }
  }

  void _measureSize() {
    if (!mounted) return;
    final RenderBox? box =
        _widgetKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final newSize = box.size;
      if (_widgetSize != newSize) {
        setState(() {
          _widgetSize = newSize;
        });
      }
    }
  }

  void _expand() {
    if (_isExpanded) return;
    setState(() {
      _isExpanded = true;
    });
    widget.onExpandChanged?.call(true);
    // Wait for expand animation to complete, then snap to nearest edge
    // This preserves the current position and snaps to the appropriate edge
    _expandController.forward().then((_) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _measureSize();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _snapToEdge();
            }
          });
        });
      }
    });
  }

  void _collapse() {
    if (!_isExpanded) return;
    setState(() {
      _isExpanded = false;
    });
    widget.onExpandChanged?.call(false);
    // Wait for collapse animation to complete, then snap to nearest edge
    // This preserves the current position and snaps to the appropriate edge
    _expandController.reverse().then((_) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _measureSize();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _snapToEdge();
            }
          });
        });
      }
    });
  }

  void _toggle() {
    if (_isExpanded) {
      _collapse();
    } else {
      _expand();
    }
  }

  void _onPanStart(DragStartDetails details) {
    // Track if tile was expanded before drag starts
    _wasExpandedBeforeDrag = _isExpanded;

    // If expanded, collapse immediately when drag starts
    Size? collapsedSize;
    if (_isExpanded) {
      _expandController.stop();
      _expandController.value = 0.0;
      widget.onExpandChanged?.call(false);

      // Estimate collapsed size if we have expanded size
      final currentSize = _widgetSize ?? Size(150.0, 100.0);
      if (currentSize.height > 200) {
        // Likely expanded size, estimate collapsed size
        final estimatedHeight = (currentSize.height / 3).clamp(60.0, 200.0);
        collapsedSize = Size(
          currentSize.width.clamp(60.0, 200.0),
          estimatedHeight,
        );
      }

      setState(() {
        _isExpanded = false;
      });
    }

    // Calculate offset from touch point to widget center
    // This ensures smooth dragging regardless of where you touch the widget
    Offset? centerOffset;
    if (_centerPosition != null) {
      // _centerPosition is in screen coordinates (center of widget)
      // details.globalPosition is where user touched (also screen coordinates)
      // Calculate offset: where is the center relative to the touch point
      centerOffset = _centerPosition! - details.globalPosition;
    }

    // Lock widget size at drag start to prevent position jumps
    // Use collapsed size if we collapsed, otherwise use current size
    final currentSize = _widgetSize ?? Size(150.0, 100.0);
    final sizeToLock = collapsedSize ?? currentSize;

    setState(() {
      _isDragging = true;
      _lockedSizeDuringDrag =
          sizeToLock; // Lock size (collapsed if we just collapsed)
      _dragStartCenterOffset = centerOffset;
    });

    // Initialize center position if needed
    if (_centerPosition == null) {
      final mediaQuery = MediaQuery.of(context);
      setState(() {
        _centerPosition = _calculator.calculateInitialDragPosition(
          mediaQuery: mediaQuery,
          widgetSize: _lockedSizeDuringDrag ?? currentSize,
        );
        // Recalculate offset with new center
        _dragStartCenterOffset = _centerPosition! - details.globalPosition;
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_centerPosition == null || _dragStartCenterOffset == null) return;

    // Use LOCKED size during drag to prevent position jumps
    final mediaQuery = MediaQuery.of(context);
    final widgetSize =
        _lockedSizeDuringDrag ?? _widgetSize ?? Size(150.0, 100.0);

    // Calculate new center position using absolute position tracking
    // This prevents jumps that can occur with delta accumulation
    // New center = current touch position + offset from touch to center
    final newCenter = details.globalPosition + _dragStartCenterOffset!;

    // Clamp to screen bounds
    final clampedCenter = _calculator.clampPosition(
      position: newCenter,
      mediaQuery: mediaQuery,
      widgetSize: widgetSize,
      isExpanded: _isExpanded,
    );

    // Check if collapsed widget should expand when near center
    // BUT: If widget was expanded before drag started, don't allow re-expansion during drag
    // This prevents the loop where user tries to collapse a tall expanded widget by dragging,
    // but it keeps re-expanding because the collapsed center is far from edge
    if (!_isExpanded && !_wasExpandedBeforeDrag) {
      final shouldExpand = _calculator.shouldAutoExpand(
        currentCenterPosition: clampedCenter,
        mediaQuery: mediaQuery,
        widgetSize: widgetSize,
        isExpanded: false,
      );

      if (shouldExpand) {
        // Expand but keep current position - don't force center
        // This allows user to continue dragging while expanded
        setState(() {
          _isExpanded = true;
          _expandController.forward();
          // Keep current position, don't jump to center
          _centerPosition = clampedCenter;
          // Recalculate drag offset to maintain relative position
          _dragStartCenterOffset = clampedCenter - details.globalPosition;
        });

        // Update locked size to actual expanded size after measurement
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _isExpanded) {
            _measureSize();
            if (_widgetSize != null) {
              setState(() {
                _lockedSizeDuringDrag = _widgetSize;
              });
            }
          }
        });
        widget.onExpandChanged?.call(true);
        return; // Early return after expanding
      }
    }

    // Update position
    setState(() {
      _centerPosition = clampedCenter;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_centerPosition == null) return;

    // Unlock size and stop dragging
    setState(() {
      _isDragging = false;
      _lockedSizeDuringDrag = null; // Unlock size
      _dragStartCenterOffset = null;
    });

    final mediaQuery = MediaQuery.of(context);

    final widgetSize = _widgetSize ?? Size(150.0, 100.0);

    // If tile is currently expanded OR was expanded before drag, always snap to edge
    // (don't collapse or expand/center)
    // Note: Tile collapses on drag start if it was expanded, so check both states
    if (_isExpanded || _wasExpandedBeforeDrag) {
      // If it was expanded before drag, it collapsed on drag start, so measure collapsed size
      // If it's currently expanded, measure expanded size
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _measureSize();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _snapToEdge();
            // Reset flag after snapping is initiated
            _wasExpandedBeforeDrag = false;
          }
        });
      });
      return;
    }

    // Check position - use shouldAutoExpand to determine if near center
    final shouldExpand = _calculator.shouldAutoExpand(
      currentCenterPosition: _centerPosition!,
      mediaQuery: mediaQuery,
      widgetSize: widgetSize,
      isExpanded: _isExpanded,
    );
    final shouldCollapse = _calculator.shouldAutoCollapse(
      currentCenterPosition: _centerPosition!,
      mediaQuery: mediaQuery,
      widgetSize: widgetSize,
      isExpanded: _isExpanded,
    );

    if (shouldExpand) {
      // Expand and center
      setState(() {
        _isExpanded = true;
        _expandController.forward();
        _centerPosition = _calculator.calculateExpandedCenterPosition(
          mediaQuery: mediaQuery,
          expandedWidgetSize: widgetSize,
        );
      });
      widget.onExpandChanged?.call(true);
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureSize());
    } else if (shouldCollapse) {
      // Collapse and snap to edge - wait for animation to complete
      // Note: This should only happen if tile was expanded before drag started
      // If tile was expanded and dragged, it collapsed on drag start, so this won't execute
      setState(() {
        _isExpanded = false;
      });
      widget.onExpandChanged?.call(false);

      // Start collapse animation and wait for it to complete before snapping
      // If already at 0.0, skip animation and snap directly
      if (_expandController.value == 0.0) {
        // Already collapsed, skip animation and snap directly
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _measureSize();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _snapToEdge();
            }
          });
        });
      } else {
        // Animate collapse and wait for completion
        _expandController.reverse().then((_) {
          if (mounted) {
            // Wait for widget to rebuild and measure collapsed size before snapping
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _measureSize();
              // Wait another frame to ensure size is updated
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _snapToEdge();
                }
              });
            });
          }
        });
      }
    } else {
      // Not near center or edge, OR expanded tile near edge - keep current state and snap
      // If expanded, stay expanded; if collapsed, stay collapsed
      // If expand animation is running, wait for it to complete first
      if (_expandController.isAnimating ||
          _expandController.status == AnimationStatus.forward) {
        _expandController.addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _expandController.removeStatusListener((_) {});
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _measureSize();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _snapToEdge();
                }
              });
            });
          }
        });
      } else {
        // Ensure size is measured before snapping
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _measureSize();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _snapToEdge();
            }
          });
        });
      }
    }
  }

  void _snapToEdge() {
    if (_centerPosition == null || !mounted) return;

    // Don't snap if expand/collapse animation is running
    // Wait for animation to complete first
    if (_expandController.isAnimating) {
      // Remove listener first to avoid duplicates, then add it
      _expandController.removeStatusListener(_snapAfterAnimationListener);
      _expandController.addStatusListener(_snapAfterAnimationListener);
      return;
    }

    // Also check if animation is at a transition state (not completed/dismissed)
    // If it's in the middle, wait for it to complete
    final status = _expandController.status;
    if (status == AnimationStatus.forward ||
        status == AnimationStatus.reverse) {
      _expandController.removeStatusListener(_snapAfterAnimationListener);
      _expandController.addStatusListener(_snapAfterAnimationListener);
      return;
    }

    final mediaQuery = MediaQuery.of(context);
    // Use measured size - should be correct after _measureSize() is called
    // If collapsed and size seems wrong (still expanded), estimate collapsed size
    Size widgetSize;
    if (!_isExpanded && _widgetSize != null && _widgetSize!.height > 200) {
      // Likely using expanded size, estimate collapsed size
      // Collapsed is typically much smaller (roughly 1/3 the height)
      // Ensure minimum reasonable size
      final estimatedHeight = (_widgetSize!.height / 3).clamp(60.0, 200.0);
      widgetSize = Size(_widgetSize!.width.clamp(60.0, 200.0), estimatedHeight);
    } else {
      widgetSize = _widgetSize ?? Size(150.0, 100.0);
    }

    var targetCenter = _calculator.calculateSnapPosition(
      currentCenterPosition: _centerPosition!,
      mediaQuery: mediaQuery,
      widgetSize: widgetSize,
      isExpanded: _isExpanded,
    );

    // If calculateSnapPosition returns null (not within threshold), force snap for collapsed widgets
    // or widgets that were expanded before drag
    final shouldForceSnap =
        targetCenter == null && (!_isExpanded || _wasExpandedBeforeDrag);
    if (targetCenter == null) {
      if (shouldForceSnap) {
        // Force snap to nearest edge - set to current position to trigger force snap logic below
        targetCenter = _centerPosition;
      } else {
        return; // freeDrag behavior for expanded widgets
      }
    }

    // If tile was expanded before drag, is currently expanded, or should force snap,
    // force snap to nearest edge even if not within thresholds
    if ((_wasExpandedBeforeDrag || _isExpanded || shouldForceSnap) &&
        targetCenter == _centerPosition) {
      // Force snap to nearest edge by calculating edge position directly
      final screenSize = mediaQuery.size;
      final effectiveHeight = _calculator.calculateEffectiveHeight(
        widgetSize: widgetSize,
        isExpanded: _isExpanded,
      );
      final widgetWidth = widgetSize.width;

      // Determine which edge is closer (top or bottom)
      final topEdgeY =
          _calculator.getTopInset(mediaQuery) + _calculator.edgePadding;
      final bottomEdgeY = _calculator.getEffectiveBottomEdge(mediaQuery) -
          _calculator.edgePadding;
      final distanceToTop = _centerPosition!.dy - topEdgeY;
      final distanceToBottom = bottomEdgeY - _centerPosition!.dy;
      final snappingToTop = distanceToTop < distanceToBottom;

      // Calculate target X based on alignment
      double targetX;
      final effectiveAlignment = _calculator.getEffectiveAlignment();
      if (snappingToTop) {
        targetX = screenSize.width / 2; // Top always centers horizontally
      } else {
        switch (effectiveAlignment) {
          case FloatingAlignment.left:
            targetX = widgetWidth / 2 +
                _calculator.padding.left +
                _calculator.getLeftInset(mediaQuery) +
                _calculator.edgePadding;
            break;
          case FloatingAlignment.right:
            targetX = screenSize.width -
                _calculator.getRightInset(mediaQuery) -
                _calculator.edgePadding -
                widgetWidth / 2;
            break;
          case FloatingAlignment.center:
            targetX = screenSize.width / 2;
            break;
        }
      }

      // Calculate target Y
      double targetY;
      if (snappingToTop) {
        targetY = topEdgeY + effectiveHeight / 2;
      } else {
        targetY = bottomEdgeY - effectiveHeight / 2;
      }

      // Clamp to ensure widget stays on screen
      final minX = widgetWidth / 2 +
          _calculator.getLeftInset(mediaQuery) +
          _calculator.edgePadding;
      final maxX = screenSize.width -
          widgetWidth / 2 -
          _calculator.getRightInset(mediaQuery) -
          _calculator.edgePadding;
      targetX = targetX.clamp(minX, maxX);

      final minY = topEdgeY + effectiveHeight / 2;
      final maxY = bottomEdgeY - effectiveHeight / 2;
      targetY = targetY.clamp(minY, maxY);

      targetCenter = Offset(targetX, targetY);
      // Reset flag after using it
      _wasExpandedBeforeDrag = false;
    }

    final startCenter = _centerPosition!;

    _snapController.removeListener(_onSnapUpdate);
    _snapController.stop();
    _snapController.reset();

    _snapAnimation =
        Tween<Offset>(begin: startCenter, end: targetCenter).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic),
    );

    _snapController.addListener(_onSnapUpdate);
    _snapController.forward(from: 0.0).then((_) {
      if (mounted) {
        _snapController.removeListener(_onSnapUpdate);
        _snapController.reset();
        setState(() {
          _centerPosition = targetCenter;
        });
        _snapController.addListener(_onSnapUpdate);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    // Use LOCKED size during drag, otherwise actual size or estimate
    final widgetSize =
        _lockedSizeDuringDrag ?? _widgetSize ?? Size(150.0, 100.0);

    // When dragging, still show expanded state if widget is expanded
    // This prevents the toolbar from collapsing when dragging an expanded widget
    final effectiveExpanded = _isExpanded;

    // Calculate position using actual size
    final position = _centerPosition != null
        ? _calculator.calculateDraggedPosition(
            currentCenterPosition: _centerPosition!,
            mediaQuery: mediaQuery,
            widgetSize: widgetSize,
            isExpanded: effectiveExpanded,
          )
        : _calculator.calculateDefaultPosition(
            mediaQuery: mediaQuery,
            widgetSize: widgetSize,
          );

    // Determine near position
    final nearPosition = _calculator.determineNearPosition(
      currentCenterPosition: _centerPosition,
      mediaQuery: mediaQuery,
    );

    final callbacks = ExpandableCallbacks(
      expand: _expand,
      collapse: _collapse,
      toggle: _toggle,
      isExpanded: effectiveExpanded,
      nearPosition: nearPosition,
    );

    final isCenterAlignment = _centerPosition == null &&
        _calculator.getEffectiveAlignment() == FloatingAlignment.center;

    if (isCenterAlignment) {
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
              child: KeyedSubtree(
                key: _widgetKey,
                child: widget.contentBuilder(context, callbacks),
              ),
            ),
          ),
        ),
      );
    }

    return Positioned(
      left: position.left,
      top: position.top,
      right: position.right,
      bottom: position.bottom,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: KeyedSubtree(
          key: _widgetKey,
          child: widget.contentBuilder(context, callbacks),
        ),
      ),
    );
  }
}

/// Animation wrapper for expanded content items
class ExpandedContentItem extends StatelessWidget {
  const ExpandedContentItem({
    required this.animation,
    required this.child,
    this.scaleStart = 0.8,
    this.scaleEnd = 1.0,
    this.curve = Curves.easeOutCubic,
    super.key,
  });

  final Animation<double> animation;
  final Widget child;
  final double scaleStart;
  final double scaleEnd;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final easedProgress = curve.transform(animation.value);
        final scale = scaleStart + (easedProgress * (scaleEnd - scaleStart));
        return Opacity(
          opacity: animation.value,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: this.child,
    );
  }
}
