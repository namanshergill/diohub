import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:diohub/common/misc/floating_expandable_widget.dart' as base
    show
        FloatingExpandableWidget,
        ExpandableCallbacks,
        FloatConfiguration,
        FloatingPosition,
        FloatingAlignment,
        SnapMode;
import 'package:diohub/common/misc/collapsible_action_buttons.dart';

/// A generic floating toolbar widget with liquid glass effect and expand/collapse functionality.
///
/// This is a reusable library widget that displays action buttons in a horizontal scrollable
/// layout that floats above content. Features include:
/// - Frosted glass background with blur effect
/// - Smooth expand/collapse animations
/// - Draggable positioning
/// - Auto-expand/collapse based on drag position
/// - Customizable action card builders
/// - Support for prominent actions (e.g., "Comment" buttons)
///
/// **Dependencies:**
/// - `flutter/material.dart` - Standard Flutter Material widgets
/// - `liquid_glass_renderer` - For the glass effect (must be added to pubspec.yaml)
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
///           onTap: () {
///             // Handle action
///           },
///         ),
///         ActionButtonData(
///           icon: Icons.comment,
///           label: 'Comment',
///           onTap: () {
///             // Handle action
///           },
///           trailing: Text('5'), // Badge/count
///         ),
///       ],
///       defaultVisibleCount: 3,
///       position: FloatingToolbarPosition.bottom,
///       alignment: FloatingToolbarAlignment.center,
///     ),
///   ],
/// )
/// ```
///
/// **Custom Builders:**
/// You can provide custom builders for action cards:
/// ```dart
/// FloatingActionToolbar(
///   actions: actions,
///   actionCardBuilder: (context, action, onCollapse) {
///     // Custom card widget - call onCollapse when action is tapped
///     return YourCustomCard(
///       action: action,
///       onTap: () {
///         action.onTap?.call();
///         onCollapse(); // Collapse the toolbar after action
///       },
///     );
///   },
///   prominentActionBuilder: (context, action) {
///     // Custom prominent card widget
///     return YourCustomProminentCard(action: action);
///   },
/// )
/// ```
class FloatingActionToolbar extends StatefulWidget {
  const FloatingActionToolbar({
    required this.actions,
    this.actionCardBuilder,
    this.defaultVisibleCount = 3,
    this.expandedVisibleCount,
    this.onExpandChanged,
    this.onCollapseRequested,
    this.position = FloatingToolbarPosition.bottom,
    this.alignment,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.spacing = 8,
    this.maxHeight,
    this.prominentActions,
    this.prominentActionBuilder,
    this.floatConfiguration = const FloatConfiguration.snapToEdges(),
    super.key,
  });

  /// All actions to display in the toolbar
  final List<ActionButtonData> actions;

  /// Builder function to create individual action cards
  /// If not provided, uses default styling
  /// The [onCollapse] callback should be called when the action is tapped to collapse the toolbar
  final Widget Function(BuildContext context, ActionButtonData action,
      VoidCallback onCollapse)? actionCardBuilder;

  /// Prominent actions (like "Comment") that appear as expanded tiles
  final List<ActionButtonData>? prominentActions;

  /// Builder for prominent action cards
  /// If not provided, uses default styling
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
  /// If null, defaults to center for top position and right for bottom position
  final FloatingToolbarAlignment? alignment;

  /// Padding around the toolbar content
  final EdgeInsets padding;

  /// Spacing between action buttons
  final double spacing;

  /// Maximum height of the toolbar when expanded
  final double? maxHeight;

  /// Configuration for floating behavior, snapping, and animations
  final FloatConfiguration floatConfiguration;

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

/// Snapping behavior mode for the floating toolbar
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

/// Configuration for floating toolbar behavior, snapping, and animations.
///
/// Provides various settings to control how the toolbar behaves when dragged,
/// when it expands/collapses, and how it snaps to edges.
///
/// **Usage Examples:**
///
/// ```dart
/// // Free movement - no snapping
/// FloatConfiguration.free()
///
/// // Default snapping behavior
/// FloatConfiguration.snapToEdges()
///
/// // Custom configuration
/// FloatConfiguration.custom(
///   snapMode: SnapMode.onDragEnd,
///   edgeThresholdPercent: 0.2,
///   topAlignment: FloatingToolbarAlignment.left,
///   bottomAlignment: FloatingToolbarAlignment.right,
/// )
/// ```
class FloatConfiguration {
  const FloatConfiguration({
    this.snapMode = SnapMode.always,
    this.edgeThresholdPercent = 0.15,
    this.expansionThresholdPercent = 0.15,
    this.topAlignment = FloatingToolbarAlignment.center,
    this.bottomAlignment = FloatingToolbarAlignment.right,
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

  /// Free movement mode - no snapping, toolbar can be positioned anywhere
  const FloatConfiguration.free()
      : snapMode = SnapMode.never,
        edgeThresholdPercent = 0.0,
        expansionThresholdPercent = 0.0,
        topAlignment = FloatingToolbarAlignment.center,
        bottomAlignment = FloatingToolbarAlignment.center,
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
    this.topAlignment = FloatingToolbarAlignment.center,
    this.bottomAlignment = FloatingToolbarAlignment.right,
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
    this.topAlignment = FloatingToolbarAlignment.center,
    this.bottomAlignment = FloatingToolbarAlignment.right,
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

  /// How the toolbar should snap to edges
  final SnapMode snapMode;

  /// Percentage of screen height used as threshold for edge detection (0.0 to 1.0)
  /// When toolbar is within this percentage from an edge, it will snap to that edge
  final double edgeThresholdPercent;

  /// Percentage of screen height used as threshold for auto-expansion (0.0 to 1.0)
  /// When toolbar is dragged beyond this percentage from nearest edge, it expands
  final double expansionThresholdPercent;

  /// Preferred horizontal alignment when toolbar snaps to top edge
  final FloatingToolbarAlignment topAlignment;

  /// Preferred horizontal alignment when toolbar snaps to bottom edge
  final FloatingToolbarAlignment bottomAlignment;

  /// Whether to snap horizontally to center when snapping to edges
  final bool snapToCenterHorizontally;

  /// Whether dragging is enabled
  final bool enableDragging;

  /// Whether toolbar should auto-expand when dragged away from edges
  final bool enableAutoExpand;

  /// Whether toolbar should auto-collapse when dragged near edges
  final bool enableAutoCollapse;

  /// Whether to center toolbar on screen when expanding
  final bool centerOnExpand;

  /// Duration of expand/collapse animation
  final Duration expandAnimationDuration;

  /// Duration of snap-to-edge animation
  final Duration snapAnimationDuration;

  /// Animation curve for expand/collapse
  final Curve expandAnimationCurve;

  /// Animation curve for snap animation
  final Curve snapAnimationCurve;

  /// Convert to base FloatConfiguration
  base.FloatConfiguration toBaseConfig() {
    base.FloatingAlignment convertAlignment(
        FloatingToolbarAlignment alignment) {
      switch (alignment) {
        case FloatingToolbarAlignment.left:
          return base.FloatingAlignment.left;
        case FloatingToolbarAlignment.center:
          return base.FloatingAlignment.center;
        case FloatingToolbarAlignment.right:
          return base.FloatingAlignment.right;
      }
    }

    base.SnapMode convertSnapMode(SnapMode mode) {
      switch (mode) {
        case SnapMode.never:
          return base.SnapMode.never;
        case SnapMode.onDragEnd:
          return base.SnapMode.onDragEnd;
        case SnapMode.onThreshold:
          return base.SnapMode.onThreshold;
        case SnapMode.always:
          return base.SnapMode.always;
      }
    }

    return base.FloatConfiguration.custom(
      snapMode: convertSnapMode(snapMode),
      edgeThresholdPercent: edgeThresholdPercent,
      expansionThresholdPercent: expansionThresholdPercent,
      topAlignment: convertAlignment(topAlignment),
      bottomAlignment: convertAlignment(bottomAlignment),
      snapToCenterHorizontally: snapToCenterHorizontally,
      enableDragging: enableDragging,
      enableAutoExpand: enableAutoExpand,
      enableAutoCollapse: enableAutoCollapse,
      centerOnExpand: centerOnExpand,
      expandAnimationDuration: expandAnimationDuration,
      snapAnimationDuration: snapAnimationDuration,
      expandAnimationCurve: expandAnimationCurve,
      snapAnimationCurve: snapAnimationCurve,
    );
  }
}

class _FloatingActionToolbarState extends State<FloatingActionToolbar> {
  base.FloatingPosition _convertPosition(FloatingToolbarPosition position) {
    switch (position) {
      case FloatingToolbarPosition.top:
        return base.FloatingPosition.top;
      case FloatingToolbarPosition.bottom:
        return base.FloatingPosition.bottom;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine alignment defaults based on position if not explicitly provided
    final effectiveAlignment = widget.alignment ??
        (widget.position == FloatingToolbarPosition.top
            ? FloatingToolbarAlignment.center
            : FloatingToolbarAlignment.right);

    // Create a FloatConfiguration that respects the alignment
    // Apply the effective alignment to the current position
    final effectiveConfig = FloatConfiguration.custom(
      snapMode: widget.floatConfiguration.snapMode,
      edgeThresholdPercent: widget.floatConfiguration.edgeThresholdPercent,
      expansionThresholdPercent:
          widget.floatConfiguration.expansionThresholdPercent,
      topAlignment: widget.position == FloatingToolbarPosition.top
          ? effectiveAlignment
          : widget.floatConfiguration.topAlignment,
      bottomAlignment: widget.position == FloatingToolbarPosition.bottom
          ? effectiveAlignment
          : widget.floatConfiguration.bottomAlignment,
      snapToCenterHorizontally:
          widget.floatConfiguration.snapToCenterHorizontally,
      enableDragging: widget.floatConfiguration.enableDragging,
      enableAutoExpand: widget.floatConfiguration.enableAutoExpand,
      enableAutoCollapse: widget.floatConfiguration.enableAutoCollapse,
      centerOnExpand: widget.floatConfiguration.centerOnExpand,
      expandAnimationDuration:
          widget.floatConfiguration.expandAnimationDuration,
      snapAnimationDuration: widget.floatConfiguration.snapAnimationDuration,
      expandAnimationCurve: widget.floatConfiguration.expandAnimationCurve,
      snapAnimationCurve: widget.floatConfiguration.snapAnimationCurve,
    );

    return base.FloatingExpandableWidget(
      collapsedWidget: (context, callbacks) =>
          _buildCollapsedContent(context, callbacks),
      expandedWidget: (context, callbacks) =>
          _buildExpandedContent(context, callbacks),
      draggableIndicator: (context, callbacks) =>
          _buildDraggableIndicator(context, callbacks),
      expandCollapseButton: (context, callbacks) =>
          _buildExpandCollapseButton(context, callbacks),
      position: _convertPosition(widget.position),
      padding: widget.padding,
      floatConfiguration: effectiveConfig.toBaseConfig(),
      onExpandChanged: widget.onExpandChanged,
    );
  }

  Widget _buildCollapsedContent(
      BuildContext context, base.ExpandableCallbacks callbacks) {
    final prominentActions = widget.prominentActions ?? [];
    final regularActions =
        widget.actions.where((a) => !prominentActions.contains(a)).toList();

    final enabledActions =
        regularActions.where((a) => a.enabled == true).toList();
    final disabledActions =
        regularActions.where((a) => a.enabled != true).toList();

    final visibleCount = widget.defaultVisibleCount;
    final visibleEnabledActions = enabledActions.take(visibleCount).toList();

    return _buildToolbarWrapper(
      context,
      callbacks,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...visibleEnabledActions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final action = entry.value;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: widget.spacing),
                        child:
                            _buildCompactIconButton(context, action, callbacks),
                      ),
                      if (index < visibleEnabledActions.length - 1 ||
                          disabledActions.isNotEmpty)
                        Container(
                          margin: EdgeInsets.only(right: widget.spacing),
                          width: 1,
                          height: 20,
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
                ...disabledActions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final action = entry.value;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: widget.spacing),
                        child:
                            _buildCompactIconButton(context, action, callbacks),
                      ),
                      if (index < disabledActions.length - 1)
                        Container(
                          margin: EdgeInsets.only(right: widget.spacing),
                          width: 1,
                          height: 20,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(
      BuildContext context, base.ExpandableCallbacks callbacks) {
    final prominentActions = widget.prominentActions ?? [];
    final regularActions =
        widget.actions.where((a) => !prominentActions.contains(a)).toList();

    final enabledActions =
        regularActions.where((a) => a.enabled == true).toList();
    final disabledActions =
        regularActions.where((a) => a.enabled != true).toList();

    return _buildToolbarWrapper(
      context,
      callbacks,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...enabledActions.asMap().entries.map((entry) {
            final index = entry.key;
            final action = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < enabledActions.length - 1 ||
                        (index == enabledActions.length - 1 &&
                            disabledActions.isNotEmpty)
                    ? 8
                    : 0,
              ),
              child: _buildExpandedActionWithLabel(
                  context, action, index, callbacks),
            );
          }),
          ...disabledActions.asMap().entries.map((entry) {
            final index = entry.key;
            final action = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < disabledActions.length - 1 ? 8 : 0,
              ),
              child: _buildExpandedActionWithLabel(
                  context, action, enabledActions.length + index, callbacks),
            );
          }),
          if (prominentActions.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: enabledActions.isNotEmpty ? 8 : 0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...prominentActions.map((action) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: action == prominentActions.last ? 0 : 6,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: widget.prominentActionBuilder != null
                                ? widget.prominentActionBuilder!(
                                    context, action)
                                : _buildDefaultProminentActionCard(
                                    context, action),
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
    );
  }

  Widget _buildToolbarWrapper(
      BuildContext context, base.ExpandableCallbacks callbacks,
      {required Widget child}) {
    return LiquidGlassLayer(
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
                final expandedWidth = screenWidth * 0.9;

                return ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: callbacks.isExpanded ? expandedWidth : 0,
                    maxWidth:
                        callbacks.isExpanded ? expandedWidth : double.infinity,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: callbacks.isExpanded ? 12 : 6,
                      vertical: callbacks.isExpanded ? 10 : 6,
                    ),
                    child: child,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDraggableIndicator(
      BuildContext context, base.ExpandableCallbacks callbacks) {
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

  Widget _buildExpandCollapseButton(
      BuildContext context, base.ExpandableCallbacks callbacks) {
    final isNearTop = widget.position == FloatingToolbarPosition.top;

    IconData arrowIcon;
    if (callbacks.isExpanded) {
      arrowIcon =
          isNearTop ? Icons.expand_less_rounded : Icons.expand_more_rounded;
    } else {
      arrowIcon =
          isNearTop ? Icons.expand_more_rounded : Icons.expand_less_rounded;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: callbacks.toggle,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  VoidCallback _createCollapseCallback(base.ExpandableCallbacks callbacks) {
    return () {
      if (widget.onCollapseRequested != null) {
        widget.onCollapseRequested!();
      } else {
        callbacks.collapse();
      }
    };
  }

  Widget _buildCompactIconButton(BuildContext context, ActionButtonData action,
      base.ExpandableCallbacks callbacks) {
    // Use custom builder if provided
    if (widget.actionCardBuilder != null) {
      return widget.actionCardBuilder!(
        context,
        action,
        _createCollapseCallback(callbacks),
      );
    }

    // Otherwise use default implementation
    Color iconColor;
    if (!action.enabled) {
      iconColor =
          Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3);
    } else if (action.isPositive) {
      iconColor = Colors.green.shade600;
    } else if (action.isDestructive) {
      iconColor = Theme.of(context).colorScheme.error;
    } else {
      iconColor =
          action.iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant;
    }

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
                if (widget.onCollapseRequested != null) {
                  widget.onCollapseRequested!();
                } else {
                  callbacks.collapse();
                }
              }
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Tooltip(
          message: action.label,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(action.icon, size: 22, color: iconColor),
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

  Widget _buildExpandedActionWithLabel(BuildContext context,
      ActionButtonData action, int? index, base.ExpandableCallbacks callbacks) {
    // Use custom builder if provided
    if (widget.actionCardBuilder != null) {
      return widget.actionCardBuilder!(
        context,
        action,
        _createCollapseCallback(callbacks),
      );
    }

    // Otherwise use default implementation
    Color iconColor;
    if (!action.enabled) {
      iconColor =
          Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3);
    } else if (action.isPositive) {
      iconColor = Colors.green.shade600;
    } else if (action.isDestructive) {
      iconColor = Theme.of(context).colorScheme.error;
    } else {
      iconColor =
          action.iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant;
    }

    String? badgeText;
    if (action.trailing != null) {
      if (action.trailing is Text) {
        badgeText = (action.trailing as Text).data;
      }
    }

    return Card(
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
                  if (widget.onCollapseRequested != null) {
                    widget.onCollapseRequested!();
                  } else {
                    callbacks.collapse();
                  }
                }
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(action.icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 12),
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
                if (badgeText != null && badgeText.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
    );
  }

  Widget _buildDefaultProminentActionCard(
      BuildContext context, ActionButtonData action) {
    Color backgroundColor;
    Color iconColor;
    Color textColor;

    if (!action.enabled) {
      backgroundColor = Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withOpacity(0.2);
      iconColor =
          Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3);
      textColor =
          Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4);
    } else if (action.isDestructive) {
      backgroundColor =
          Theme.of(context).colorScheme.errorContainer.withOpacity(0.2);
      iconColor = Theme.of(context).colorScheme.error;
      textColor = Theme.of(context).colorScheme.error;
    } else if (action.isPositive) {
      backgroundColor = Colors.green.withOpacity(0.15);
      iconColor = Colors.green.shade600;
      textColor = Colors.green.shade700;
    } else {
      backgroundColor = Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withOpacity(0.25);
      iconColor = action.iconColor ?? Theme.of(context).colorScheme.primary;
      textColor = Theme.of(context).colorScheme.onSurface;
    }

    String? badgeText;
    if (action.trailing != null) {
      if (action.trailing is Text) {
        badgeText = (action.trailing as Text).data;
      }
    }

    return Material(
      color: Colors.transparent,
      child: AbsorbPointer(
        absorbing: !action.enabled,
        child: InkWell(
          onTap: action.enabled ? action.onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(action.icon, size: 20, color: iconColor),
                    if (badgeText != null && badgeText.isNotEmpty)
                      Positioned(
                        right: -6,
                        top: -5,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: iconColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 1.5,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          child: Center(
                            child: Text(
                              badgeText,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontSize: 8,
                                height: 1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    action.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          letterSpacing: -0.2,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
