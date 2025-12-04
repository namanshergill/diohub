import 'dart:ui';

import 'package:diohub/common/misc/action_card_builder.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// A floating toolbar widget with liquid glass effect and expand/collapse functionality.
///
/// Displays action buttons in a horizontal scrollable layout that floats above content.
/// Features a frosted glass background with blur effect and smooth expand/collapse animations.
///
/// **Usage:**
/// ```dart
/// Stack(
///   children: [
///     // Your content here
///     FloatingActionToolbar(
///       actions: [
///         ActionButtonData(
///           icon: Icons.code,
///           label: 'Code',
///           onTap: () {},
///         ),
///         // ... more actions
///       ],
///       actionCardBuilder: buildStandardActionCard,
///       defaultVisibleCount: 3,
///       position: FloatingToolbarPosition.bottom,
///     ),
///   ],
/// )
/// ```
class FloatingActionToolbar extends StatefulWidget {
  const FloatingActionToolbar({
    required this.actions,
    required this.actionCardBuilder,
    this.defaultVisibleCount = 3,
    this.expandedVisibleCount,
    this.onExpandChanged,
    this.onCollapseRequested,
    this.position = FloatingToolbarPosition.top,
    this.alignment = FloatingToolbarAlignment.center,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.spacing = 8,
    this.maxHeight,
    this.prominentActions,
    this.prominentActionBuilder,
    super.key,
  });

  /// All actions to display in the toolbar
  final List<ActionButtonData> actions;

  /// Builder function to create individual action cards
  final Widget Function(BuildContext context, ActionButtonData action)
      actionCardBuilder;

  /// Prominent actions (like "Comment") that appear as expanded tiles
  final List<ActionButtonData>? prominentActions;

  /// Builder for prominent action cards (uses buildProminentActionCard by default)
  final Widget Function(BuildContext context, ActionButtonData action)?
      prominentActionBuilder;

  /// Number of actions visible when collapsed (default: 3)
  final int defaultVisibleCount;

  /// Number of actions visible when expanded (if null, shows all)
  final int? expandedVisibleCount;

  /// Callback when expand state changes
  final void Function(bool isExpanded)? onExpandChanged;

  /// Callback to collapse the toolbar (called after action tap by default)
  /// If null, defaults to collapsing the toolbar when an action is tapped
  final VoidCallback? onCollapseRequested;

  /// Position of the toolbar
  final FloatingToolbarPosition position;

  /// Horizontal alignment of the toolbar
  final FloatingToolbarAlignment alignment;

  /// Padding around the toolbar content
  final EdgeInsets padding;

  /// Spacing between action buttons
  final double spacing;

  /// Maximum height of the toolbar when expanded
  final double? maxHeight;

  @override
  State<FloatingActionToolbar> createState() => _FloatingActionToolbarState();
}

enum FloatingToolbarPosition {
  top,
  bottom,
}

enum FloatingToolbarAlignment {
  left,
  center,
  right,
}

class _FloatingActionToolbarState extends State<FloatingActionToolbar>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool? _expandedFromTop; // Track if expanded from top or bottom position
  bool _isAnimating =
      false; // Track if toolbar is animating (expand/collapse/snap)
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late AnimationController _snapAnimationController;
  Animation<Offset>? _snapAnimation;

  // Draggable state - using absolute screen coordinates
  Offset?
      _position; // null means use default alignment, otherwise absolute position (center point)
  Size? _toolbarSize; // Actual measured size of the toolbar
  final GlobalKey _toolbarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    _snapAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // Add listener once in initState
    _snapAnimationController.addListener(_onSnapAnimationUpdate);
    // Measure toolbar size after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureToolbarSize());
  }

  void _onSnapAnimationUpdate() {
    if (_snapAnimation != null && mounted) {
      final newValue = _snapAnimation!.value;
      setState(() {
        _position = newValue;
      });
      print('[Toolbar] _onSnapAnimationUpdate: Updated _position to $newValue');
    }
  }

  @override
  void dispose() {
    _snapAnimationController.removeListener(_onSnapAnimationUpdate);
    _animationController.dispose();
    _snapAnimationController.dispose();
    super.dispose();
  }

  void _measureToolbarSize() {
    if (!mounted) return;
    final RenderBox? renderBox =
        _toolbarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      setState(() {
        _toolbarSize = renderBox.size;
      });
    }
  }

  void _toggleExpand() {
    final wasExpanded = _isExpanded;
    final screenSize = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;

    setState(() {
      _isExpanded = !_isExpanded;
      _isAnimating = true; // Set flag to ignore drags during animation
      if (_isExpanded) {
        _animationController.forward().then((_) {
          if (mounted) {
            setState(() {
              _isAnimating = false; // Clear flag when animation completes
            });
          }
        });
        // Store the position state when expanding (top or bottom)
        final isNearTop = _position == null
            ? widget.position == FloatingToolbarPosition.top
            : _position!.dy <
                (screenSize.height - safeArea.top - safeArea.bottom) / 2 +
                    safeArea.top;
        _expandedFromTop = isNearTop;
        // Center toolbar on screen when expanding (both horizontally and vertically)
        final centerX = screenSize.width / 2;
        final centerY = safeArea.top +
            (screenSize.height - safeArea.top - safeArea.bottom) / 2;
        print(
            '[Toolbar] _toggleExpand: Centering toolbar on expand, centerX=$centerX, centerY=$centerY, expandedFromTop=$_expandedFromTop');
        _position = Offset(centerX, centerY);
      } else {
        _animationController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _isAnimating = false; // Clear flag when animation completes
            });
          }
        });
        _expandedFromTop = null; // Reset when collapsing
      }
    });
    widget.onExpandChanged?.call(_isExpanded);
    // Remeasure size after expansion changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureToolbarSize();
      // Snap to edge when collapsing
      if (wasExpanded && !_isExpanded && _position != null) {
        _snapToNearestEdge();
      }
    });
  }

  /// Collapse the toolbar if it's currently expanded
  void _collapseIfExpanded() {
    if (_isExpanded) {
      _toggleExpand();
    }
  }

  void _onPanStart(DragStartDetails details) {
    print('[Toolbar] _onPanStart: _position=$_position');
    // Initialize position if not already set
    if (_position == null) {
      final screenSize = MediaQuery.of(context).size;
      final safeArea = MediaQuery.of(context).padding;

      // Calculate initial position based on alignment and position
      double initialX;
      double initialY;

      // Calculate center X position based on alignment
      // Use actual measured size if available, otherwise use estimate
      final toolbarWidth = _toolbarSize?.width ?? 150.0;
      final toolbarHeight = _toolbarSize?.height ?? 100.0;

      switch (widget.alignment) {
        case FloatingToolbarAlignment.left:
          // Left edge + half width = center
          initialX = widget.padding.left + safeArea.left + toolbarWidth / 2;
          break;
        case FloatingToolbarAlignment.right:
          // Right edge - half width = center
          initialX = screenSize.width -
              widget.padding.right -
              safeArea.right -
              toolbarWidth / 2;
          break;
        case FloatingToolbarAlignment.center:
          initialX = screenSize.width / 2;
          break;
      }

      switch (widget.position) {
        case FloatingToolbarPosition.top:
          // Top edge + half height = center Y
          initialY = widget.padding.top + safeArea.top + toolbarHeight / 2;
          break;
        case FloatingToolbarPosition.bottom:
          // Bottom edge - half height = center Y
          initialY = screenSize.height -
              widget.padding.bottom -
              safeArea.bottom -
              toolbarHeight / 2;
          break;
      }

      print(
          '[Toolbar] _onPanStart: Initializing position: initialX=$initialX, initialY=$initialY (center coords)');
      _position = Offset(initialX, initialY);
    } else {
      print('[Toolbar] _onPanStart: Using existing position: $_position');
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    // Ignore drags if animating
    if (_isAnimating) {
      print('[Toolbar] _onPanUpdate: Ignoring drag - toolbar is animating');
      return;
    }
    setState(() {
      if (_position == null) {
        print('[Toolbar] _onPanUpdate: _position is null, returning');
        return;
      }

      // Update absolute position
      final newPosition = _position! + details.delta;
      final screenSize = MediaQuery.of(context).size;
      final safeArea = MediaQuery.of(context).padding;

      // Use actual measured size if available, otherwise use estimate based on CURRENT state
      // Important: Use current state, not expanded state, for accurate clamping
      final currentToolbarWidth =
          _toolbarSize?.width ?? (_isExpanded ? 250.0 : 150.0);
      // If we have a measured size but it doesn't match current state, use estimate
      final measuredHeight =
          _toolbarSize?.height ?? (_isExpanded ? 300.0 : 100.0);
      final currentToolbarHeight = (_toolbarSize != null &&
              _isExpanded == false &&
              measuredHeight > 200)
          ? 100.0 // Use collapsed estimate if measured size is clearly expanded
          : (_isExpanded ? 300.0 : 100.0);

      print(
          '[Toolbar] _onPanUpdate: delta=${details.delta}, newPosition=$newPosition');
      print(
          '[Toolbar] _onPanUpdate: screenSize=$screenSize, toolbarSize=w:$currentToolbarWidth h:$currentToolbarHeight, _isExpanded=$_isExpanded');

      // Clamp horizontal position (allow full width movement)
      // _position.dx is the center X, so allow it to go from toolbarWidth/2 to screenWidth - toolbarWidth/2
      final clampedX = newPosition.dx.clamp(
        currentToolbarWidth / 2, // Allow center to go to left edge (x=0)
        screenSize.width -
            currentToolbarWidth / 2, // Allow center to go to right edge
      );

      // Clamp vertical position respecting SafeArea
      // Use current toolbar height for accurate clamping
      // Allow toolbar to reach the very top (accounting for toolbar height)
      final minY = currentToolbarHeight /
          2; // Allow center to be at toolbarHeight/2 from top
      final maxY =
          screenSize.height - safeArea.bottom - currentToolbarHeight / 2;

      print(
          '[Toolbar] _onPanUpdate: Y clamp range: minY=$minY, maxY=$maxY, newY=${newPosition.dy}, safeArea.top=${safeArea.top}, safeArea.bottom=${safeArea.bottom}');

      final clampedY = newPosition.dy.clamp(minY, maxY);

      print(
          '[Toolbar] _onPanUpdate: Clamped position: clampedX=$clampedX, clampedY=$clampedY');
      _position = Offset(clampedX, clampedY);

      // Auto-expand/collapse logic based on 15% edge distance
      final availableHeight =
          screenSize.height - safeArea.top - safeArea.bottom;
      final edgeThresholdPercent = 0.15; // 15% of screen height
      final edgeThresholdDistance = availableHeight * edgeThresholdPercent;

      // Calculate distances to edges
      final distanceToTopEdge =
          clampedY - safeArea.top - currentToolbarHeight / 2;
      final distanceToBottomEdge = screenSize.height -
          safeArea.bottom -
          clampedY -
          currentToolbarHeight / 2;
      final distanceToNearestEdge = distanceToTopEdge < distanceToBottomEdge
          ? distanceToTopEdge
          : distanceToBottomEdge;

      final centerY = safeArea.top + availableHeight / 2;

      print(
          '[Toolbar] _onPanUpdate: edgeThresholdDistance=$edgeThresholdDistance, distanceToNearestEdge=$distanceToNearestEdge');

      // If collapsed and dragged more than 15% away from nearest edge, expand and snap to center
      if (!_isExpanded && distanceToNearestEdge > edgeThresholdDistance) {
        print(
            '[Toolbar] _onPanUpdate: Auto-expanding (collapsed -> center, distance=$distanceToNearestEdge > threshold=$edgeThresholdDistance)');
        // Store the position state when expanding (top or bottom)
        final isNearTop = distanceToTopEdge < distanceToBottomEdge;
        _expandedFromTop = isNearTop;
        _isExpanded = true;
        _isAnimating = true; // Set flag to ignore drags during animation
        _animationController.forward().then((_) {
          if (mounted) {
            setState(() {
              _isAnimating = false; // Clear flag when animation completes
            });
          }
        });
        // Center horizontally and vertically
        _position = Offset(screenSize.width / 2, centerY);
        widget.onExpandChanged?.call(true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _measureToolbarSize();
        });
      }
      // If expanded and dragged within 15% of an edge, collapse and snap to that edge
      else if (_isExpanded && distanceToNearestEdge <= edgeThresholdDistance) {
        print(
            '[Toolbar] _onPanUpdate: Auto-collapsing (expanded -> edge, distance=$distanceToNearestEdge <= threshold=$edgeThresholdDistance)');
        _isExpanded = false;
        _isAnimating = true; // Set flag to ignore drags during animation
        _animationController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _isAnimating = false; // Clear flag when animation completes
            });
          }
        });
        _expandedFromTop = null; // Reset when collapsing
        widget.onExpandChanged?.call(false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _measureToolbarSize();
          // Snap to nearest edge after collapse
          _snapToNearestEdge();
        });
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    print(
        '[Toolbar] _onPanEnd: _isExpanded=$_isExpanded, _position=$_position');
    if (_position == null) return;

    final screenSize = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;
    final availableHeight = screenSize.height - safeArea.top - safeArea.bottom;
    final edgeThresholdPercent = 0.15; // 15% of screen height
    final edgeThresholdDistance = availableHeight * edgeThresholdPercent;

    final effectiveHeight =
        _toolbarSize?.height ?? (_isExpanded ? 300.0 : 100.0);
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

    print(
        '[Toolbar] _onPanEnd: edgeThresholdDistance=$edgeThresholdDistance, distanceToNearestEdge=$distanceToNearestEdge');

    // If collapsed and dragged more than 15% away from nearest edge, expand and snap to center
    if (!_isExpanded && distanceToNearestEdge > edgeThresholdDistance) {
      print('[Toolbar] _onPanEnd: Expanding and snapping to center');
      // Store the position state when expanding (top or bottom)
      final isNearTop = distanceToTopEdge < distanceToBottomEdge;
      setState(() {
        _expandedFromTop = isNearTop;
        _isExpanded = true;
        _isAnimating = true; // Set flag to ignore drags during animation
        _animationController.forward().then((_) {
          if (mounted) {
            setState(() {
              _isAnimating = false; // Clear flag when animation completes
            });
          }
        });
        _position = Offset(screenSize.width / 2, centerY);
      });
      widget.onExpandChanged?.call(true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _measureToolbarSize();
      });
    }
    // If expanded and dragged within 15% of an edge, collapse and snap to that edge
    else if (_isExpanded && distanceToNearestEdge <= edgeThresholdDistance) {
      print('[Toolbar] _onPanEnd: Collapsing and snapping to edge');
      setState(() {
        _isExpanded = false;
        _isAnimating = true; // Set flag to ignore drags during animation
        _animationController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _isAnimating = false; // Clear flag when animation completes
            });
          }
        });
        _expandedFromTop = null; // Reset when collapsing
      });
      widget.onExpandChanged?.call(false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _measureToolbarSize();
        _snapToNearestEdge();
      });
    }
    // If collapsed and within 15% of edge, snap to nearest edge
    else if (!_isExpanded) {
      print('[Toolbar] _onPanEnd: Snapping to nearest edge');
      _snapToNearestEdge();
    }
  }

  void _snapToNearestEdge() {
    if (_position == null || !mounted) {
      print(
          '[Toolbar] _snapToNearestEdge: Early return - _position=$_position, mounted=$mounted');
      return;
    }

    final screenSize = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;
    // Use current state's height estimate if toolbarSize hasn't been updated yet
    // When collapsed, _toolbarSize.height might still be the expanded height
    final toolbarHeight = _isExpanded
        ? (_toolbarSize?.height ?? 300.0)
        : (_toolbarSize?.height ?? 100.0);

    // If we have a measured size but it doesn't match current state, use estimate
    final effectiveHeight = (_toolbarSize != null &&
            _isExpanded == false &&
            _toolbarSize!.height > 200)
        ? 100.0 // Use collapsed estimate if measured size is clearly expanded
        : toolbarHeight;

    print('[Toolbar] _snapToNearestEdge: currentPosition=$_position');

    // Determine target position - snap to nearest edge
    double targetX = screenSize.width / 2; // Center horizontally
    double targetY;

    // Calculate distances to top and bottom edges
    final currentY = _position!.dy;
    final distanceToTop = currentY - effectiveHeight / 2;
    final distanceToBottom =
        screenSize.height - safeArea.bottom - currentY - effectiveHeight / 2;

    // Snap to nearest edge (top or bottom)
    if (distanceToTop < distanceToBottom) {
      // Snap to top
      targetY = effectiveHeight / 2;
      print(
          '[Toolbar] _snapToNearestEdge: Snapping to TOP CENTER, targetX=$targetX, targetY=$targetY');
    } else {
      // Snap to bottom (preferred position on collapse if expanded from bottom)
      targetY = screenSize.height - safeArea.bottom - effectiveHeight / 2;
      print(
          '[Toolbar] _snapToNearestEdge: Snapping to BOTTOM CENTER, targetX=$targetX, targetY=$targetY (safeArea.bottom=${safeArea.bottom})');
    }

    // Animate to the target position
    final startPosition = _position!;
    final targetPosition = Offset(targetX, targetY);

    print(
        '[Toolbar] _snapToNearestEdge: startPosition=$startPosition, targetPosition=$targetPosition');

    // Don't auto-expand when snapping - let the drag logic handle expansion
    // This prevents the collapse button from causing re-expansion

    // Stop any ongoing animation first and remove listener to prevent interference
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

    // Re-add listener after creating new animation
    _snapAnimationController.addListener(_onSnapAnimationUpdate);

    print('[Toolbar] _snapToNearestEdge: Starting animation');
    _isAnimating = true; // Set flag to ignore drags during snap animation
    _snapAnimationController.forward(from: 0.0).then((_) {
      print(
          '[Toolbar] _snapToNearestEdge: Animation completed, setting final position=$targetPosition');
      // Ensure final position is set correctly and stop any further updates
      if (mounted) {
        // Remove listener BEFORE reset to prevent it from firing with old values
        _snapAnimationController.removeListener(_onSnapAnimationUpdate);
        _snapAnimationController.reset();
        // Set final position AFTER reset to ensure it's not overwritten
        setState(() {
          _position = targetPosition;
          _isAnimating = false; // Clear flag when animation completes
          print(
              '[Toolbar] _snapToNearestEdge: setState called, _position set to $_position');
        });
        // Re-add listener for future animations
        _snapAnimationController.addListener(_onSnapAnimationUpdate);
      } else {
        print(
            '[Toolbar] _snapToNearestEdge: Widget not mounted, skipping setState');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate initial position if not dragged yet
    final safeArea = MediaQuery.of(context).padding;
    final screenSize = MediaQuery.of(context).size;

    double? left, top, right, bottom;

    if (_position != null) {
      // Use absolute positioning when dragged
      // _position.dx is the center X, convert to left edge
      // _position.dy is the center Y, convert to top edge
      // Use actual measured size if available, otherwise use estimate
      final toolbarWidth = _toolbarSize?.width ?? (_isExpanded ? 250.0 : 150.0);
      final measuredHeight =
          _toolbarSize?.height ?? (_isExpanded ? 300.0 : 100.0);
      // If we have a measured size but it doesn't match current state, use estimate
      final effectiveHeight = (_toolbarSize != null &&
              _isExpanded == false &&
              measuredHeight > 200)
          ? 100.0 // Use collapsed estimate if measured size is clearly expanded
          : (_isExpanded ? 300.0 : 100.0);
      left = _position!.dx - toolbarWidth / 2;
      // Ensure top position respects SafeArea using effective height
      final calculatedTop = _position!.dy - effectiveHeight / 2;
      top = calculatedTop.clamp(
          safeArea.top, screenSize.height - safeArea.bottom - effectiveHeight);
      print(
          '[Toolbar] build: _position=$_position, calculated left=$left, top=$top (toolbarSize=w:$toolbarWidth h:$measuredHeight, effectiveHeight=$effectiveHeight, _isExpanded=$_isExpanded, safeArea.top=${safeArea.top}, safeArea.bottom=${safeArea.bottom})');
    } else {
      // Use default alignment-based positioning
      switch (widget.alignment) {
        case FloatingToolbarAlignment.left:
          left = widget.padding.left + safeArea.left;
          break;
        case FloatingToolbarAlignment.right:
          right = widget.padding.right + safeArea.right;
          break;
        case FloatingToolbarAlignment.center:
          // Will use Align for centering
          break;
      }

      switch (widget.position) {
        case FloatingToolbarPosition.top:
          top = widget.padding.top + safeArea.top;
          break;
        case FloatingToolbarPosition.bottom:
          bottom = widget.padding.bottom + safeArea.bottom;
          break;
      }
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
        child: _position == null &&
                widget.alignment == FloatingToolbarAlignment.center
            ? Align(
                alignment: widget.position == FloatingToolbarPosition.top
                    ? Alignment.topCenter
                    : Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: widget.position == FloatingToolbarPosition.top
                        ? widget.padding.top + safeArea.top
                        : 0,
                    bottom: widget.position == FloatingToolbarPosition.bottom
                        ? widget.padding.bottom + safeArea.bottom
                        : 0,
                  ),
                  child: _buildToolbarContent(context),
                ),
              )
            : _buildToolbarContent(context),
      ),
    );
  }

  Widget _buildToolbarContent(BuildContext context) {
    final prominentActions = widget.prominentActions ?? [];
    final regularActions =
        widget.actions.where((a) => !prominentActions.contains(a)).toList();

    final enabledActions =
        regularActions.where((a) => a.enabled == true).toList();
    final disabledActions =
        regularActions.where((a) => a.enabled != true).toList();

    // Calculate visible actions
    final visibleCount = _isExpanded
        ? (widget.expandedVisibleCount ?? regularActions.length)
        : widget.defaultVisibleCount;

    final visibleEnabledActions = enabledActions.take(visibleCount).toList();
    final hiddenActions = enabledActions.skip(visibleCount).toList();

    return Padding(
      padding: _position == null ? widget.padding : EdgeInsets.zero,
      child: LiquidGlassLayer(
        settings: LiquidGlassSettings(
          blur: 20,
          glassColor: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withOpacity(0.2),
          thickness: 2,
        ),
        child: LiquidGlass(
          shape: LiquidRoundedRectangle(
            borderRadius: 28,
          ),
          child: Container(
            constraints: widget.maxHeight != null
                ? BoxConstraints(maxHeight: widget.maxHeight!)
                : null,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
                width: 0.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final expandedWidth =
                      screenWidth * 0.9; // 90% of screen width

                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: _isExpanded ? expandedWidth : 0,
                      maxWidth: _isExpanded ? expandedWidth : double.infinity,
                    ),
                    child: IntrinsicWidth(
                      key: _toolbarKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Main toolbar content
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: _isExpanded
                                  ? 12
                                  : 6, // More padding when expanded
                              vertical: _isExpanded
                                  ? 10
                                  : 6, // More padding when expanded
                            ),
                            child: Builder(
                              builder: (context) {
                                // Use stored expansion position if expanded, otherwise determine from current position
                                final screenSize = MediaQuery.of(context).size;
                                final safeArea = MediaQuery.of(context).padding;
                                final isNearTop =
                                    _isExpanded && _expandedFromTop != null
                                        ? _expandedFromTop!
                                        : (_position == null
                                            ? widget.position ==
                                                FloatingToolbarPosition.top
                                            : _position!.dy <
                                                (screenSize.height -
                                                            safeArea.top -
                                                            safeArea.bottom) /
                                                        2 +
                                                    safeArea.top);

                                final draggableIndicator =
                                    _buildDraggableIndicator(context);
                                final expandCollapseButton = Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: _buildExpandCollapseButton(context),
                                );

                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // If near top: pill at top, arrow at bottom
                                    // If near bottom: arrow at top, pill at bottom
                                    if (isNearTop) ...[
                                      draggableIndicator,
                                      const SizedBox(height: 4),
                                    ] else ...[
                                      expandCollapseButton,
                                      const SizedBox(height: 4),
                                    ],
                                    // Compact mode - horizontal icons with dividers (only show when collapsed)
                                    if (!_isExpanded)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Icons section - wrap content
                                          SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                ...visibleEnabledActions
                                                    .asMap()
                                                    .entries
                                                    .map((entry) {
                                                  final index = entry.key;
                                                  final action = entry.value;
                                                  return Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                          right: widget.spacing,
                                                        ),
                                                        child:
                                                            _buildCompactIconButton(
                                                                context,
                                                                action),
                                                      ),
                                                      // Divider between icons
                                                      if (index <
                                                              visibleEnabledActions
                                                                      .length -
                                                                  1 ||
                                                          disabledActions
                                                              .isNotEmpty)
                                                        Container(
                                                          margin:
                                                              EdgeInsets.only(
                                                                  right: widget
                                                                      .spacing),
                                                          width: 1,
                                                          height: 20,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .outline
                                                                .withOpacity(
                                                                    0.15),
                                                          ),
                                                        ),
                                                    ],
                                                  );
                                                }),
                                                ...disabledActions
                                                    .asMap()
                                                    .entries
                                                    .map((entry) {
                                                  final index = entry.key;
                                                  final action = entry.value;
                                                  return Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                          right: widget.spacing,
                                                        ),
                                                        child:
                                                            _buildCompactIconButton(
                                                                context,
                                                                action),
                                                      ),
                                                      // Divider between icons
                                                      if (index <
                                                          disabledActions
                                                                  .length -
                                                              1)
                                                        Container(
                                                          margin:
                                                              EdgeInsets.only(
                                                                  right: widget
                                                                      .spacing),
                                                          width: 1,
                                                          height: 20,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .outline
                                                                .withOpacity(
                                                                    0.15),
                                                          ),
                                                        ),
                                                    ],
                                                  );
                                                }),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    // Expanded mode - vertical layout with animation
                                    SizeTransition(
                                      sizeFactor: _expandAnimation,
                                      axisAlignment: -1.0,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          // All actions (visible + hidden) with labels
                                          ...enabledActions
                                              .asMap()
                                              .entries
                                              .map((entry) {
                                            final index = entry.key;
                                            final action = entry.value;
                                            return Padding(
                                              padding: EdgeInsets.only(
                                                bottom: index <
                                                            enabledActions
                                                                    .length -
                                                                1 ||
                                                        (index ==
                                                                enabledActions
                                                                        .length -
                                                                    1 &&
                                                            disabledActions
                                                                .isNotEmpty)
                                                    ? 8 // Spacing between cards
                                                    : 0,
                                              ),
                                              child:
                                                  _buildExpandedActionWithLabel(
                                                      context, action, index),
                                            );
                                          }),
                                          // Disabled actions
                                          ...disabledActions
                                              .asMap()
                                              .entries
                                              .map((entry) {
                                            final index = entry.key;
                                            final action = entry.value;
                                            return Padding(
                                              padding: EdgeInsets.only(
                                                bottom: index <
                                                        disabledActions.length -
                                                            1
                                                    ? 8 // Spacing between cards
                                                    : 0,
                                              ),
                                              child:
                                                  _buildExpandedActionWithLabel(
                                                      context,
                                                      action,
                                                      enabledActions.length +
                                                          index),
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                    // Place pill/arrow based on position
                                    if (isNearTop) ...[
                                      // Arrow at bottom when near top
                                      expandCollapseButton,
                                    ] else ...[
                                      // Pill at bottom when near bottom
                                      const SizedBox(height: 4),
                                      draggableIndicator,
                                    ],
                                  ],
                                );
                              },
                            ),
                          ),
                          // Prominent actions row - always shown at bottom
                          if (prominentActions.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(
                                top:
                                    (_isExpanded && hiddenActions.isNotEmpty) ||
                                            visibleEnabledActions.isNotEmpty
                                        ? 8
                                        : 0,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ...prominentActions.map((action) {
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        bottom: action == prominentActions.last
                                            ? 0
                                            : 6,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: (widget
                                                    .prominentActionBuilder ??
                                                buildProminentActionCard)(
                                              context,
                                              action,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build draggable indicator
  Widget _buildDraggableIndicator(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  /// Build expand/collapse button
  Widget _buildExpandCollapseButton(BuildContext context) {
    // Determine arrow direction based on position and state
    final screenSize = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;
    final isNearTop = _position == null
        ? widget.position == FloatingToolbarPosition.top
        : _position!.dy <
            (screenSize.height - safeArea.top - safeArea.bottom) / 2 +
                safeArea.top;

    IconData arrowIcon;
    if (_isExpanded) {
      // When expanded, arrow points toward the edge it will snap to
      arrowIcon = isNearTop
          ? Icons.expand_less_rounded // Point up (toward top edge)
          : Icons.expand_more_rounded; // Point down (toward bottom edge)
    } else {
      // When collapsed, arrow points away from edge (toward center)
      arrowIcon = isNearTop
          ? Icons
              .expand_more_rounded // Point down (away from top, toward center)
          : Icons
              .expand_less_rounded; // Point up (away from bottom, toward center)
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleExpand,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity, // Take full width
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 4), // Reduced vertical padding
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                arrowIcon,
                size: 16,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build compact icon-only button (for collapsed state)
  Widget _buildCompactIconButton(
      BuildContext context, ActionButtonData action) {
    // Determine icon color based on action type
    Color iconColor;
    if (!action.enabled) {
      iconColor =
          Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3);
    } else if (action.icon == Octicons.issue_opened) {
      // Green for issues
      iconColor = Colors.green.shade600;
    } else if (action.icon == Octicons.git_pull_request) {
      // Purple for PRs
      iconColor = Colors.purple.shade600;
    } else {
      iconColor =
          action.iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant;
    }

    // Extract badge text from trailing widget
    String? badgeText;
    if (action.trailing != null) {
      if (action.trailing is Text) {
        badgeText = (action.trailing as Text).data;
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.enabled
            ? () {
                action.onTap?.call();
                // Default behavior: collapse toolbar after action tap
                if (widget.onCollapseRequested != null) {
                  widget.onCollapseRequested!();
                } else {
                  _collapseIfExpanded();
                }
              }
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Tooltip(
          message: action.label,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8), // Increased padding for easier tapping
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  action.icon,
                  size: 22, // Increased from 16 to 22 for better visibility
                  color: iconColor,
                ),
                // Count badge on the side
                if (badgeText != null && badgeText.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: iconColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build expanded action with icon and label (vertical layout)
  Widget _buildExpandedActionWithLabel(
      BuildContext context, ActionButtonData action,
      [int? index]) {
    // Determine icon color based on action type
    Color iconColor;
    if (!action.enabled) {
      iconColor =
          Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3);
    } else if (action.icon == Octicons.issue_opened) {
      // Green for issues
      iconColor = Colors.green.shade600;
    } else if (action.icon == Octicons.git_pull_request) {
      // Purple for PRs
      iconColor = Colors.purple.shade600;
    } else {
      iconColor =
          action.iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant;
    }

    // Extract badge text from trailing widget
    String? badgeText;
    if (action.trailing != null) {
      if (action.trailing is Text) {
        badgeText = (action.trailing as Text).data;
      }
    }

    // Create staggered animation using Interval curves
    // Each tile starts animating slightly after the previous one - make it more noticeable
    final staggerDelay = index != null ? (index * 0.12).clamp(0.0, 0.6) : 0.0;
    final staggerDuration = 0.25; // Duration of each tile's animation

    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        // Calculate progress for this specific tile with stagger
        final tileProgress = _expandAnimation.value < staggerDelay
            ? 0.0
            : ((_expandAnimation.value - staggerDelay) / staggerDuration)
                .clamp(0.0, 1.0);

        // Apply easing curve
        final easedProgress = Curves.easeOutCubic.transform(tileProgress);

        // Determine animation direction based on where toolbar expanded from
        final screenSize = MediaQuery.of(context).size;
        final safeArea = MediaQuery.of(context).padding;
        final isExpandingFromTop = _expandedFromTop ??
            (_position == null
                ? widget.position == FloatingToolbarPosition.top
                : _position!.dy <
                    (screenSize.height - safeArea.top - safeArea.bottom) / 2 +
                        safeArea.top);

        // Animate from top if expanding from top, from bottom if expanding from bottom
        final slideOffset = isExpandingFromTop
            ? Offset(0, (1 - easedProgress) * 25) // Slide down from top
            : Offset(0, -(1 - easedProgress) * 25); // Slide up from bottom

        return Opacity(
          opacity: easedProgress,
          child: Transform.translate(
            offset: slideOffset,
            child: child,
          ),
        );
      },
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: action.enabled
                ? () {
                    action.onTap?.call();
                    // Default behavior: collapse toolbar after action tap
                    if (widget.onCollapseRequested != null) {
                      widget.onCollapseRequested!();
                    } else {
                      _collapseIfExpanded();
                    }
                  }
                : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12), // More compact padding
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      action.icon,
                      size: 18, // Compact icon size
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(width: 12), // Compact spacing
                  Expanded(
                    child: Text(
                      action.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 15,
                            color: action.enabled
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withOpacity(0.5),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  // Count badge on the right side
                  if (badgeText != null && badgeText.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: iconColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
