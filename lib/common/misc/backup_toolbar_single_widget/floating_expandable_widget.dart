import 'package:diohub/common/misc/floating_widget_position_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  bool _justCollapsed =
      false; // Track if widget just collapsed to prevent immediate re-expansion
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
      final oldPosition = _centerPosition;
      final newPosition = _snapAnimation!.value;
      setState(() {
        _centerPosition = newPosition;
      });
      // Log only occasionally to avoid spam (every 10th frame or significant changes)
      final positionChange = oldPosition != null
          ? ((oldPosition.dx - newPosition.dx).abs() +
              (oldPosition.dy - newPosition.dy).abs())
          : double.infinity;
      final shouldLog = oldPosition == null ||
          positionChange > 5.0 ||
          (_snapController.value < 0.1 || _snapController.value > 0.9);
      if (shouldLog) {
        print(
            '[FloatingExpandableWidget] _onSnapUpdate: position=$newPosition, oldPosition=$oldPosition, animationValue=${_snapController.value}');
      }
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
    final oldSize = _widgetSize;
    final RenderBox? box =
        _widgetKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final newSize = box.size;
      if (_widgetSize != newSize) {
        setState(() {
          _widgetSize = newSize;
        });
        print(
            '[FloatingExpandableWidget] _measureSize: Size changed - oldSize=$oldSize, newSize=$newSize, _centerPosition=$_centerPosition');
      } else {
        print(
            '[FloatingExpandableWidget] _measureSize: Size unchanged - size=$newSize, _centerPosition=$_centerPosition');
      }
    } else {
      print(
          '[FloatingExpandableWidget] _measureSize: Could not measure size - box is null or has no size, _widgetSize=$_widgetSize');
    }
  }

  /// Collapses the widget immediately without animation (used during drag)
  void _collapseImmediately() {
    if (!_isExpanded) return;
    HapticFeedback.mediumImpact();
    _expandController.stop();
    _expandController.value = 0.0;
    widget.onExpandChanged?.call(false);
    setState(() {
      _isExpanded = false;
      _justCollapsed = true; // Set flag to prevent immediate re-expansion
    });
  }

  /// Collapses the widget with animation and snaps to edge
  void _collapse() {
    if (!_isExpanded) return;
    HapticFeedback.mediumImpact();
    print(
        '[FloatingExpandableWidget] _collapse: Starting collapse, current position=$_centerPosition, widgetSize=$_widgetSize');
    setState(() {
      _isExpanded = false;
      _justCollapsed = true; // Set flag to prevent immediate re-expansion
    });
    widget.onExpandChanged?.call(false);
    // Wait for collapse animation to complete, then snap to nearest edge
    _expandController.reverse().then((_) {
      if (mounted) {
        print(
            '[FloatingExpandableWidget] _collapse: Collapse animation completed, position=$_centerPosition');
        _snapToEdgeWithMeasurement();
      }
    });
  }

  /// Unlocks size and stops dragging state
  void _unlockSizeAndStopDragging() {
    final positionBeforeUnlock = _centerPosition;
    final sizeBeforeUnlock = _widgetSize;
    final lockedSizeBeforeUnlock = _lockedSizeDuringDrag;
    setState(() {
      _isDragging = false;
      _lockedSizeDuringDrag = null;
      _dragStartCenterOffset = null;
    });
    print(
        '[FloatingExpandableWidget] _unlockSizeAndStopDragging: positionBeforeUnlock=$positionBeforeUnlock, positionAfterUnlock=$_centerPosition, sizeBeforeUnlock=$sizeBeforeUnlock, sizeAfterUnlock=$_widgetSize, lockedSizeBeforeUnlock=$lockedSizeBeforeUnlock');
  }

  /// Measures widget size and snaps to edge
  void _snapToEdgeWithMeasurement() {
    print(
        '[FloatingExpandableWidget] _snapToEdgeWithMeasurement: START - _centerPosition=$_centerPosition, _widgetSize=$_widgetSize, _isExpanded=$_isExpanded');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print(
          '[FloatingExpandableWidget] _snapToEdgeWithMeasurement: First postFrameCallback - measuring size, _centerPosition=$_centerPosition, _widgetSize=$_widgetSize');
      _measureSize();
      print(
          '[FloatingExpandableWidget] _snapToEdgeWithMeasurement: After _measureSize - _centerPosition=$_centerPosition, _widgetSize=$_widgetSize');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          print(
              '[FloatingExpandableWidget] _snapToEdgeWithMeasurement: Second postFrameCallback - About to snap to edge, position=$_centerPosition, widgetSize=$_widgetSize');
          _snapToEdge();
        }
      });
    });
  }

  void _expand() {
    if (_isExpanded) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _isExpanded = true;
    });
    widget.onExpandChanged?.call(true);
    // Wait for expand animation to complete, then snap to nearest edge
    // This preserves the current position and snaps to the appropriate edge
    _expandController.forward().then((_) {
      if (mounted) {
        _snapToEdgeWithMeasurement();
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

    // Lock widget size at drag start to prevent position jumps
    // Use current size (don't collapse immediately - collapse only when swiping toward edge)
    final currentSize = _widgetSize ?? Size(150.0, 100.0);
    final sizeToLock = currentSize;

    // Calculate offset from touch point to widget center
    // This ensures smooth dragging regardless of where you touch the widget
    // IMPORTANT: Calculate offset AFTER we know the final size (collapsed or expanded)
    // This prevents the jump when collapsing because the offset is based on the correct size
    Offset? centerOffset;
    if (_centerPosition != null) {
      // _centerPosition is in screen coordinates (center of widget)
      // details.globalPosition is where user touched (also screen coordinates)
      // Calculate offset: where is the center relative to the touch point
      centerOffset = _centerPosition! - details.globalPosition;
    }

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

    // Check if expanded widget should collapse when swiped toward edge
    if (_isExpanded) {
      // Get edge distances to determine which edge we're near
      final edgeDistances = _calculator.calculateEdgeDistances(
        currentCenterPosition: clampedCenter,
        mediaQuery: mediaQuery,
        widgetSize: widgetSize,
        isExpanded: true,
      );

      // Get threshold to check if we're "near" an edge
      final threshold = _calculator.calculateEdgeThreshold(
        mediaQuery: mediaQuery,
        thresholdPercent: 0.15,
      );

      // Check if near an edge
      final isNearEdge = edgeDistances.distanceToNearestEdge <= threshold;

      // Get swipe direction (delta.dy > 0 = swiping down, < 0 = swiping up)
      final isSwipingDown = details.delta.dy > 0;
      final isSwipingUp = details.delta.dy < 0;

      // Collapse conditions:
      // 1. Near bottom edge AND swiping down (toward bottom)
      // 2. Near top edge AND swiping up (toward top)
      final shouldCollapse = isNearEdge &&
          ((edgeDistances.isNearTop && isSwipingUp) || // Near top, swiping up
              (!edgeDistances.isNearTop &&
                  isSwipingDown)); // Near bottom, swiping down

      if (shouldCollapse) {
        print(
            '[FloatingExpandableWidget] _onPanUpdate: AUTO-COLLAPSING! Swiping ${isSwipingDown ? "down" : "up"} near ${edgeDistances.isNearTop ? "top" : "bottom"} edge.');
        print(
            '[FloatingExpandableWidget] _onPanUpdate: BEFORE collapse - clampedCenter=$clampedCenter, newCenter=$newCenter, widgetSize=$widgetSize, _centerPosition=$_centerPosition, _wasExpandedBeforeDrag=$_wasExpandedBeforeDrag, _isExpanded=$_isExpanded');
        HapticFeedback.mediumImpact();

        // Track that widget was expanded before this collapse
        if (!_wasExpandedBeforeDrag) {
          _wasExpandedBeforeDrag = true;
          print(
              '[FloatingExpandableWidget] _onPanUpdate: Setting _wasExpandedBeforeDrag=true');
        }

        _collapseImmediately();
        print(
            '[FloatingExpandableWidget] _onPanUpdate: AFTER _collapseImmediately - _isExpanded=$_isExpanded, _justCollapsed=$_justCollapsed');

        // Update locked size to collapsed size
        final currentSize = _widgetSize ?? Size(150.0, 100.0);
        Size? estimatedCollapsedSize;
        if (currentSize.height > 200) {
          final estimatedHeight = (currentSize.height / 3).clamp(60.0, 200.0);
          estimatedCollapsedSize = Size(
            currentSize.width.clamp(60.0, 200.0),
            estimatedHeight,
          );
          print(
              '[FloatingExpandableWidget] _onPanUpdate: Estimated collapsed size - currentSize=$currentSize, estimatedCollapsedSize=$estimatedCollapsedSize');
        }
        final finalCollapsedSize = estimatedCollapsedSize ?? Size(150.0, 100.0);

        // Maintain current visual position (clampedCenter) to prevent jump
        // Only clamp if the position would be off-screen with the collapsed size
        final maintainedPosition = _calculator.clampPosition(
          position:
              clampedCenter, // Use current clamped position, not newCenter
          mediaQuery: mediaQuery,
          widgetSize: finalCollapsedSize,
          isExpanded: false,
        );

        print(
            '[FloatingExpandableWidget] _onPanUpdate: Position calculation - clampedCenter=$clampedCenter, finalCollapsedSize=$finalCollapsedSize, maintainedPosition=$maintainedPosition');

        // Update locked size and position
        setState(() {
          _lockedSizeDuringDrag = finalCollapsedSize;
          final oldPosition = _centerPosition;
          _centerPosition = maintainedPosition;
          _dragStartCenterOffset = maintainedPosition - details.globalPosition;
          print(
              '[FloatingExpandableWidget] _onPanUpdate: setState - oldPosition=$oldPosition, newPosition=$maintainedPosition, _dragStartCenterOffset=$_dragStartCenterOffset');
        });
        print(
            '[FloatingExpandableWidget] _onPanUpdate: AFTER setState - _centerPosition=$_centerPosition, _lockedSizeDuringDrag=$_lockedSizeDuringDrag');
        return; // Early return after collapsing
      }
    }

    // Check if collapsed widget should expand when near center
    // Don't auto-expand if we just collapsed (prevent immediate re-expansion)
    // Also don't auto-expand if widget was expanded before drag started (it collapsed on drag start)
    if (!_isExpanded && !_justCollapsed && !_wasExpandedBeforeDrag) {
      print(
          '[FloatingExpandableWidget] _onPanUpdate: Checking shouldAutoExpand, position=$clampedCenter, widgetSize=$widgetSize, isExpanded=$_isExpanded, justCollapsed=$_justCollapsed, wasExpandedBeforeDrag=$_wasExpandedBeforeDrag');
      final shouldExpand = _calculator.shouldAutoExpand(
        currentCenterPosition: clampedCenter,
        mediaQuery: mediaQuery,
        widgetSize: widgetSize,
        isExpanded: false,
      );
      print(
          '[FloatingExpandableWidget] _onPanUpdate: shouldAutoExpand=$shouldExpand');

      if (shouldExpand) {
        print(
            '[FloatingExpandableWidget] _onPanUpdate: AUTO-EXPANDING! Position=$clampedCenter, widgetSize=$widgetSize');
        HapticFeedback.mediumImpact();
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
    final oldPosition = _centerPosition;
    setState(() {
      _centerPosition = clampedCenter;
    });
    print(
        '[FloatingExpandableWidget] _onPanUpdate: Normal position update - oldPosition=$oldPosition, newPosition=$clampedCenter, _isExpanded=$_isExpanded, _justCollapsed=$_justCollapsed, _wasExpandedBeforeDrag=$_wasExpandedBeforeDrag, _lockedSizeDuringDrag=$_lockedSizeDuringDrag');
  }

  void _onPanEnd(DragEndDetails details) {
    if (_centerPosition == null) return;

    print(
        '[FloatingExpandableWidget] _onPanEnd: START - _centerPosition=$_centerPosition, _isExpanded=$_isExpanded, _justCollapsed=$_justCollapsed, _wasExpandedBeforeDrag=$_wasExpandedBeforeDrag, _lockedSizeDuringDrag=$_lockedSizeDuringDrag, _widgetSize=$_widgetSize');

    final mediaQuery = MediaQuery.of(context);

    final widgetSize = _widgetSize ?? Size(150.0, 100.0);

    // If tile is currently expanded OR was expanded before drag, always snap to edge
    // (don't collapse or expand/center)
    // Note: Tile collapses on drag start if it was expanded, so check both states
    if (_isExpanded || _wasExpandedBeforeDrag) {
      print(
          '[FloatingExpandableWidget] _onPanEnd: Widget was expanded - _isExpanded=$_isExpanded, _wasExpandedBeforeDrag=$_wasExpandedBeforeDrag');

      // If it was expanded before drag, it collapsed on drag start (via _collapseImmediately)
      // We need to measure the collapsed size first, then snap
      // This prevents the jump that happens when using expanded size for snap calculation
      if (_wasExpandedBeforeDrag && !_isExpanded) {
        print(
            '[FloatingExpandableWidget] _onPanEnd: Widget collapsed during drag - unlocking size and measuring');
        // Widget was collapsed during drag - unlock size, measure collapsed size, then snap
        final positionBeforeUnlock = _centerPosition;
        final sizeBeforeUnlock = _widgetSize;
        _unlockSizeAndStopDragging();
        print(
            '[FloatingExpandableWidget] _onPanEnd: After unlock - positionBeforeUnlock=$positionBeforeUnlock, positionAfterUnlock=$_centerPosition, sizeBeforeUnlock=$sizeBeforeUnlock, sizeAfterUnlock=$_widgetSize');
        // Force a rebuild to get the collapsed size before snapping
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isExpanded) {
            print(
                '[FloatingExpandableWidget] _onPanEnd: First postFrameCallback - measuring size, _centerPosition=$_centerPosition, _widgetSize=$_widgetSize');
            _measureSize();
            print(
                '[FloatingExpandableWidget] _onPanEnd: After _measureSize - _centerPosition=$_centerPosition, _widgetSize=$_widgetSize');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_isExpanded) {
                print(
                    '[FloatingExpandableWidget] _onPanEnd: Second postFrameCallback - about to snap, _centerPosition=$_centerPosition, _widgetSize=$_widgetSize');
                _snapToEdge();
                // Reset flags after snapping is initiated
                _wasExpandedBeforeDrag = false;
              }
            });
          }
        });
      } else {
        print(
            '[FloatingExpandableWidget] _onPanEnd: Widget still expanded - unlocking size and snapping');
        // Currently expanded - unlock size and measure expanded size
        final positionBeforeUnlock = _centerPosition;
        final sizeBeforeUnlock = _widgetSize;
        _unlockSizeAndStopDragging();
        print(
            '[FloatingExpandableWidget] _onPanEnd: After unlock (expanded) - positionBeforeUnlock=$positionBeforeUnlock, positionAfterUnlock=$_centerPosition, sizeBeforeUnlock=$sizeBeforeUnlock, sizeAfterUnlock=$_widgetSize');
        _snapToEdgeWithMeasurement();
        _wasExpandedBeforeDrag = false;
      }
      return;
    }

    // Unlock size and stop dragging for normal collapsed widgets
    _unlockSizeAndStopDragging();

    // Check position - use shouldAutoExpand to determine if near center
    // Don't auto-expand if we just collapsed (prevent immediate re-expansion)
    final shouldExpand = !_justCollapsed &&
        _calculator.shouldAutoExpand(
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
      print(
          '[FloatingExpandableWidget] _onPanEnd: AUTO-EXPANDING from shouldExpand check! Position=$_centerPosition, widgetSize=$widgetSize');
      HapticFeedback.mediumImpact();
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
      HapticFeedback.mediumImpact();
      setState(() {
        _isExpanded = false;
        _justCollapsed = true; // Set flag to prevent immediate re-expansion
      });
      widget.onExpandChanged?.call(false);

      // Start collapse animation and wait for it to complete before snapping
      // If already at 0.0, skip animation and snap directly
      if (_expandController.value == 0.0) {
        // Already collapsed, skip animation and snap directly
        _snapToEdgeWithMeasurement();
      } else {
        // Animate collapse and wait for completion
        _expandController.reverse().then((_) {
          if (mounted) {
            _snapToEdgeWithMeasurement();
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
            _snapToEdgeWithMeasurement();
          }
        });
      } else {
        // Ensure size is measured before snapping
        _snapToEdgeWithMeasurement();
      }
    }
  }

  void _snapToEdge() {
    if (_centerPosition == null || !mounted) return;
    print(
        '[FloatingExpandableWidget] _snapToEdge: Starting snap, position=$_centerPosition, isExpanded=$_isExpanded, widgetSize=$_widgetSize, _wasExpandedBeforeDrag=$_wasExpandedBeforeDrag, _justCollapsed=$_justCollapsed');

    // Don't snap if expand/collapse animation is running
    // Wait for animation to complete first
    if (_expandController.isAnimating) {
      print(
          '[FloatingExpandableWidget] _snapToEdge: Animation is running, waiting for completion');
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
      print(
          '[FloatingExpandableWidget] _snapToEdge: Animation status is $status, waiting for completion');
      _expandController.removeStatusListener(_snapAfterAnimationListener);
      _expandController.addStatusListener(_snapAfterAnimationListener);
      return;
    }

    final mediaQuery = MediaQuery.of(context);
    // Use measured size - should be correct after _measureSize() is called
    // If collapsed and size seems wrong (still expanded), estimate collapsed size
    // CRITICAL: If widget was expanded before drag, it's now collapsed, so use collapsed size
    Size widgetSize;
    if (!_isExpanded) {
      if (_widgetSize != null && _widgetSize!.height > 200) {
        // Likely using expanded size, estimate collapsed size
        // Collapsed is typically much smaller (roughly 1/3 the height)
        // Ensure minimum reasonable size
        final estimatedHeight = (_widgetSize!.height / 3).clamp(60.0, 200.0);
        widgetSize =
            Size(_widgetSize!.width.clamp(60.0, 200.0), estimatedHeight);
        print(
            '[FloatingExpandableWidget] _snapToEdge: Estimated collapsed size - _widgetSize=$_widgetSize, estimated=$widgetSize');
      } else {
        widgetSize = _widgetSize ?? Size(150.0, 100.0);
      }
    } else {
      widgetSize = _widgetSize ?? Size(150.0, 100.0);
    }
    print(
        '[FloatingExpandableWidget] _snapToEdge: Using widgetSize=$widgetSize for snap calculation');

    var targetCenter = _calculator.calculateSnapPosition(
      currentCenterPosition: _centerPosition!,
      mediaQuery: mediaQuery,
      widgetSize: widgetSize,
      isExpanded: _isExpanded,
    );
    print(
        '[FloatingExpandableWidget] _snapToEdge: calculateSnapPosition returned targetCenter=$targetCenter, _centerPosition=$_centerPosition');

    if (targetCenter == null) {
      print(
          '[FloatingExpandableWidget] _snapToEdge: targetCenter is null (freeDrag), returning');
      return; // freeDrag behavior
    }

    // If tile was expanded before drag or is currently expanded, force snap to nearest edge
    // even if not within thresholds (calculateSnapPosition returns currentPosition if not within thresholds)
    final shouldForceSnap = (_wasExpandedBeforeDrag || _isExpanded);
    final targetEqualsCurrent = targetCenter == _centerPosition;
    print(
        '[FloatingExpandableWidget] _snapToEdge: shouldForceSnap=$shouldForceSnap, targetEqualsCurrent=$targetEqualsCurrent');

    if (shouldForceSnap && targetEqualsCurrent) {
      print(
          '[FloatingExpandableWidget] _snapToEdge: Forcing snap to edge - calculating edge position');
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
      print(
          '[FloatingExpandableWidget] _snapToEdge: After forced snap calculation - targetCenter=$targetCenter, startCenter=$_centerPosition, widgetSize=$widgetSize, snappingToTop=$snappingToTop, effectiveHeight=$effectiveHeight');
      // Reset flag after using it
      _wasExpandedBeforeDrag = false;
    } else if (shouldForceSnap && !targetEqualsCurrent) {
      print(
          '[FloatingExpandableWidget] _snapToEdge: Widget was expanded but calculateSnapPosition found edge (targetCenter != _centerPosition). Using calculated targetCenter=$targetCenter');
    }

    final distance = ((_centerPosition!.dx - targetCenter.dx).abs() +
        (_centerPosition!.dy - targetCenter.dy).abs());
    print(
        '[FloatingExpandableWidget] _snapToEdge: Final snap target - startCenter=$_centerPosition, targetCenter=$targetCenter, distance=$distance');

    final startCenter = _centerPosition!;

    _snapController.removeListener(_onSnapUpdate);
    _snapController.stop();
    _snapController.reset();

    print(
        '[FloatingExpandableWidget] _snapToEdge: Setting up snap animation - startCenter=$startCenter, targetCenter=$targetCenter');

    _snapAnimation =
        Tween<Offset>(begin: startCenter, end: targetCenter).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic),
    );

    _snapController.addListener(_onSnapUpdate);
    print(
        '[FloatingExpandableWidget] _snapToEdge: Starting snap animation from $startCenter to $targetCenter');
    _snapController.forward(from: 0.0).then((_) {
      if (mounted) {
        print(
            '[FloatingExpandableWidget] _snapToEdge: Snap animation completed callback - setting position to $targetCenter');
        _snapController.removeListener(_onSnapUpdate);
        _snapController.reset();
        HapticFeedback.lightImpact();
        final positionBeforeSetState = _centerPosition;
        setState(() {
          _centerPosition = targetCenter;
          _justCollapsed = false; // Clear flag after snap completes
        });
        print(
            '[FloatingExpandableWidget] _snapToEdge: Snap animation completed - positionBeforeSetState=$positionBeforeSetState, positionAfterSetState=$targetCenter, justCollapsed cleared');
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
