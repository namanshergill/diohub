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
    // Measure toolbar size after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureToolbarSize());
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

  @override
  void dispose() {
    _animationController.dispose();
    _snapAnimationController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    final wasExpanded = _isExpanded;
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
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

  void _onPanStart(DragStartDetails details) {
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
          initialY = widget.padding.top + safeArea.top;
          break;
        case FloatingToolbarPosition.bottom:
          initialY =
              screenSize.height - widget.padding.bottom - safeArea.bottom;
          break;
      }

      _position = Offset(initialX, initialY);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      if (_position == null) return;

      // Update absolute position
      final newPosition = _position! + details.delta;
      final screenSize = MediaQuery.of(context).size;
      final safeArea = MediaQuery.of(context).padding;

      // Use actual measured size if available, otherwise use estimate
      final toolbarWidth = _toolbarSize?.width ?? (_isExpanded ? 250.0 : 150.0);
      final toolbarHeight =
          _toolbarSize?.height ?? (_isExpanded ? 300.0 : 100.0);

      // Clamp horizontal position (allow full width movement)
      // _position.dx is the center X, so allow it to go from toolbarWidth/2 to screenWidth - toolbarWidth/2
      final clampedX = newPosition.dx.clamp(
        toolbarWidth / 2, // Allow center to go to left edge (x=0)
        screenSize.width - toolbarWidth / 2, // Allow center to go to right edge
      );

      // Clamp vertical position (allow full height movement, including above SafeArea)
      final clampedY = newPosition.dy.clamp(
        toolbarHeight / 2, // Allow going to top of screen (above app bar)
        screenSize.height -
            toolbarHeight / 2 -
            widget.padding.bottom -
            safeArea.bottom,
      );

      _position = Offset(clampedX, clampedY);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    // Only snap to edge if collapsed
    if (!_isExpanded && _position != null) {
      _snapToNearestEdge();
    }
  }

  void _snapToNearestEdge() {
    if (_position == null) return;

    final screenSize = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;
    final toolbarWidth = _toolbarSize?.width ?? 150.0;
    final toolbarHeight = _toolbarSize?.height ?? 100.0;

    // Calculate distances to each edge
    final currentX = _position!.dx;
    final currentY = _position!.dy;

    final distanceToLeft = currentX - toolbarWidth / 2;
    final distanceToRight = screenSize.width - (currentX + toolbarWidth / 2);
    final distanceToTop = currentY - toolbarHeight / 2;
    final distanceToBottom = screenSize.height - (currentY + toolbarHeight / 2);

    // Find the nearest edge
    double targetX = currentX;
    double targetY = currentY;

    // Determine which horizontal edge is closer
    if (distanceToLeft < distanceToRight) {
      // Snap to left edge
      targetX = toolbarWidth / 2;
    } else {
      // Snap to right edge
      targetX = screenSize.width - toolbarWidth / 2;
    }

    // Determine which vertical edge is closer
    if (distanceToTop < distanceToBottom) {
      // Snap to top edge
      targetY = toolbarHeight / 2;
    } else {
      // Snap to bottom edge
      targetY = screenSize.height - toolbarHeight / 2 - safeArea.bottom;
    }

    // Choose the edge with the smallest distance
    final minHorizontalDistance =
        distanceToLeft < distanceToRight ? distanceToLeft : distanceToRight;
    final minVerticalDistance =
        distanceToTop < distanceToBottom ? distanceToTop : distanceToBottom;

    // If horizontal distance is smaller, prioritize horizontal snap
    if (minHorizontalDistance < minVerticalDistance) {
      // Keep Y as is, only snap X
      targetY = currentY.clamp(
        toolbarHeight / 2,
        screenSize.height - toolbarHeight / 2 - safeArea.bottom,
      );
    } else {
      // Keep X as is, only snap Y
      targetX = currentX.clamp(
        toolbarWidth / 2,
        screenSize.width - toolbarWidth / 2,
      );
    }

    // Animate to the target position
    final startPosition = _position!;
    final targetPosition = Offset(targetX, targetY);

    _snapAnimation = Tween<Offset>(
      begin: startPosition,
      end: targetPosition,
    ).animate(CurvedAnimation(
      parent: _snapAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _snapAnimationController.addListener(() {
      if (_snapAnimation != null) {
        setState(() {
          _position = _snapAnimation!.value;
        });
      }
    });

    _snapAnimationController.forward(from: 0.0).then((_) {
      _snapAnimationController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate initial position if not dragged yet
    final safeArea = MediaQuery.of(context).padding;

    double? left, top, right, bottom;

    if (_position != null) {
      // Use absolute positioning when dragged
      // _position.dx is the center X, convert to left edge
      // Use actual measured size if available, otherwise use estimate
      final toolbarWidth = _toolbarSize?.width ?? (_isExpanded ? 250.0 : 150.0);
      left = _position!.dx - toolbarWidth / 2;
      top = _position!.dy;
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
    final hasHiddenActions = hiddenActions.isNotEmpty;

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
              child: IntrinsicWidth(
                key: _toolbarKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Main toolbar content
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Compact mode - horizontal icons with expand button
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Icons section - wrap content
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ...visibleEnabledActions.map((action) {
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          right: widget.spacing,
                                        ),
                                        child: _buildCompactIconButton(
                                            context, action),
                                      );
                                    }),
                                    ...disabledActions.map((action) {
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          right: widget.spacing,
                                        ),
                                        child: _buildCompactIconButton(
                                            context, action),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              // Expand button on the right
                              if (hasHiddenActions)
                                Padding(
                                  padding:
                                      EdgeInsets.only(left: widget.spacing),
                                  child: _buildExpandCollapseButton(context),
                                ),
                            ],
                          ),
                          // Expanded mode - vertical layout with animation
                          SizeTransition(
                            sizeFactor: _expandAnimation,
                            axisAlignment: -1.0,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Divider
                                Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  height: 1,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outline
                                        .withOpacity(0.15),
                                  ),
                                ),
                                // All actions (visible + hidden) with labels
                                ...enabledActions.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final action = entry.value;
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildExpandedActionWithLabel(
                                          context, action),
                                      if (index < enabledActions.length - 1)
                                        Container(
                                          margin: EdgeInsets.symmetric(
                                            vertical: widget.spacing / 2,
                                          ),
                                          height: 1,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outline
                                                .withOpacity(0.15),
                                          ),
                                        ),
                                    ],
                                  );
                                }),
                                // Disabled actions
                                ...disabledActions.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final action = entry.value;
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildExpandedActionWithLabel(
                                          context, action),
                                      if (index < disabledActions.length - 1)
                                        Container(
                                          margin: EdgeInsets.symmetric(
                                            vertical: widget.spacing / 2,
                                          ),
                                          height: 1,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outline
                                                .withOpacity(0.15),
                                          ),
                                        ),
                                    ],
                                  );
                                }),
                                // Collapse button at bottom
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: _buildExpandCollapseButton(context),
                                ),
                              ],
                            ),
                          ),
                          // Draggable indicator at bottom
                          _buildDraggableIndicator(context),
                        ],
                      ),
                    ),
                    // Prominent actions row - always shown at bottom
                    if (prominentActions.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          top: (_isExpanded && hiddenActions.isNotEmpty) ||
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
                                  bottom:
                                      action == prominentActions.last ? 0 : 6,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: (widget.prominentActionBuilder ??
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleExpand,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isExpanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
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
        onTap: action.enabled ? action.onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Tooltip(
          message: action.label,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  action.icon,
                  size: 16,
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
        onTap: action.enabled ? action.onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Icon(
                action.icon,
                size: 16,
                color: iconColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  action.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: iconColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              // Count badge on the right side
              if (badgeText != null && badgeText.isNotEmpty) ...[
                const SizedBox(width: 8),
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
    );
  }
}
