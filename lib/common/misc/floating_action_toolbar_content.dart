import 'package:diohub/common/misc/action_card_builder.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/misc/floating_expandable_widget.dart' as base;
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// Builds the toolbar content widget
Widget buildToolbarContent({
  required BuildContext context,
  required base.ExpandableCallbacks callbacks,
  required List<ActionButtonData> actions,
  required List<ActionButtonData>? prominentActions,
  required int defaultVisibleCount,
  required int? expandedVisibleCount,
  required double spacing,
  required double? maxHeight,
  required dynamic
      position, // FloatingPosition from floating_expandable_widget.dart
  required VoidCallback? onCollapseRequested,
  required Widget Function(BuildContext, ActionButtonData)?
      prominentActionBuilder,
  required Animation<double> expandAnimation,
  required GlobalKey toolbarKey,
}) {
  final regularActions =
      actions.where((a) => !(prominentActions ?? []).contains(a)).toList();

  // Split actions by visibility state
  final alwaysVisibleActions = regularActions
      .where(
          (a) => a.visibilityState == ActionButtonVisibilityState.alwaysVisible)
      .toList();
  final maybeVisibleActions = regularActions
      .where(
          (a) => a.visibilityState == ActionButtonVisibilityState.maybeVisible)
      .toList();

  // Determine visible actions based on expanded state
  final List<ActionButtonData> visibleCollapsedActions;
  final List<ActionButtonData> visibleExpandedActions;

  if (callbacks.isExpanded) {
    // When expanded, show all actions except alwaysHidden
    visibleExpandedActions = [
      ...alwaysVisibleActions,
      ...maybeVisibleActions,
    ];
    visibleCollapsedActions = [];
  } else {
    // When collapsed:
    // 1. Always show alwaysVisible actions
    // 2. Show maybeVisible actions up to defaultVisibleCount (after alwaysVisible)
    final remainingSlots = (defaultVisibleCount - alwaysVisibleActions.length)
        .clamp(0, maybeVisibleActions.length);
    visibleCollapsedActions = [
      ...alwaysVisibleActions,
      ...maybeVisibleActions.take(remainingSlots),
    ];
    visibleExpandedActions = [
      ...alwaysVisibleActions,
      ...maybeVisibleActions,
    ]; // For expanded view when calculating grid
  }

  // Split by enabled state for display
  final visibleCollapsedEnabled =
      visibleCollapsedActions.where((a) => a.enabled == true).toList();
  final visibleCollapsedDisabled =
      visibleCollapsedActions.where((a) => a.enabled != true).toList();

  return AnimatedBuilder(
    animation: expandAnimation,
    builder: (context, child) {
      // Animate blur from weak (collapsed) to strong (expanded)
      final double blurAmount =
          8 + (expandAnimation.value * 12.0); // 8-20 range

      return LiquidGlassLayer(
        settings: LiquidGlassSettings(
          blur: blurAmount,
          glassColor: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withOpacity(0.2),
          thickness: 2,
        ),
        child: child!,
      );
    },
    child: LiquidGlass(
      shape: LiquidRoundedRectangle(
        borderRadius: 28,
      ),
      child: Container(
        constraints:
            maxHeight != null ? BoxConstraints(maxHeight: maxHeight) : null,
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
                child: IntrinsicWidth(
                  key: toolbarKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: callbacks.isExpanded ? 12 : 6,
                          vertical: callbacks.isExpanded ? 10 : 6,
                        ),
                        child: Builder(
                          builder: (context) {
                            final draggableIndicator =
                                buildDraggableIndicator(context);
                            final isNearTop = callbacks.nearPosition ==
                                base.FloatingPosition.top;
                            final expandCollapseButton = Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: buildExpandCollapseButton(
                                context,
                                callbacks,
                                isNearTop,
                              ),
                            );

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isNearTop) ...[
                                  draggableIndicator,
                                  const SizedBox(height: 4),
                                ] else ...[
                                  expandCollapseButton,
                                  const SizedBox(height: 4),
                                ],
                                if (!callbacks.isExpanded)
                                  _AnimatedCollapsedActionsRow(
                                    enabledActions: visibleCollapsedEnabled,
                                    disabledActions: visibleCollapsedDisabled,
                                    prominentActions: prominentActions,
                                    spacing: spacing,
                                    buildCompactIconButton:
                                        buildCompactIconButton,
                                    buildCompactProminentButton:
                                        buildCompactProminentButton,
                                    callbacks: callbacks,
                                    onCollapseRequested: onCollapseRequested,
                                    context: context,
                                    expandAnimation: expandAnimation,
                                  ),
                                SizeTransition(
                                  sizeFactor: expandAnimation,
                                  axisAlignment: -1.0,
                                  child: callbacks.isExpanded
                                      ? Padding(
                                          padding:
                                              const EdgeInsets.only(top: 0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              // Grid layout for basic buttons
                                              LayoutBuilder(
                                                builder:
                                                    (context, constraints) {
                                                  // Ensure we have bounded constraints
                                                  if (!constraints
                                                          .hasBoundedWidth ||
                                                      constraints.maxWidth
                                                          .isInfinite ||
                                                      constraints.maxWidth <=
                                                          0) {
                                                    // Return empty container if constraints are invalid
                                                    return const SizedBox
                                                        .shrink();
                                                  }

                                                  // Calculate number of columns based on available width
                                                  // Each button needs ~120px width, with 8px spacing
                                                  const double minButtonWidth =
                                                      120.0;
                                                  const double spacing = 8.0;
                                                  final double availableWidth =
                                                      constraints.maxWidth
                                                          .clamp(0.0,
                                                              double.infinity);
                                                  final int crossAxisCount =
                                                      ((availableWidth +
                                                                  spacing) /
                                                              (minButtonWidth +
                                                                  spacing))
                                                          .floor()
                                                          .clamp(2, 4);

                                                  final allActions = [
                                                    ...visibleExpandedActions,
                                                  ];

                                                  if (allActions.isEmpty) {
                                                    return const SizedBox
                                                        .shrink();
                                                  }

                                                  // Calculate item width for grid layout
                                                  final double itemWidth =
                                                      (availableWidth -
                                                              (spacing *
                                                                  (crossAxisCount -
                                                                      1))) /
                                                          crossAxisCount;
                                                  final double itemHeight =
                                                      itemWidth /
                                                          2.5; // Based on childAspectRatio

                                                  // Calculate number of rows needed for height calculation
                                                  final int rowCount =
                                                      (allActions.length /
                                                              crossAxisCount)
                                                          .ceil();
                                                  final double totalHeight =
                                                      (rowCount * itemHeight) +
                                                          ((rowCount - 1) *
                                                              spacing);

                                                  // Ensure we have a valid height
                                                  // Add extra padding to prevent cutoff
                                                  final double safeHeight =
                                                      totalHeight + spacing;

                                                  if (safeHeight <= 0) {
                                                    return const SizedBox
                                                        .shrink();
                                                  }

                                                  // Use Wrap for simpler layout that handles last row naturally

                                                  return Wrap(
                                                    spacing: spacing,
                                                    runSpacing: spacing,
                                                    children: allActions
                                                        .asMap()
                                                        .entries
                                                        .map((entry) {
                                                      final index = entry.key;
                                                      final action =
                                                          entry.value;
                                                      final actionIndex = index;

                                                      // Calculate width - make last row items fill if incomplete
                                                      final int itemsInLastRow =
                                                          allActions.length %
                                                              crossAxisCount;
                                                      final bool isLastRow =
                                                          index >=
                                                              (allActions
                                                                      .length -
                                                                  itemsInLastRow);
                                                      final double width = isLastRow &&
                                                              itemsInLastRow >
                                                                  0 &&
                                                              itemsInLastRow <
                                                                  crossAxisCount
                                                          ? (availableWidth -
                                                                  (spacing *
                                                                      (itemsInLastRow -
                                                                          1))) /
                                                              itemsInLastRow
                                                          : itemWidth;

                                                      return SizedBox(
                                                        width: width,
                                                        child:
                                                            buildExpandedActionWithLabel(
                                                          context,
                                                          action,
                                                          actionIndex,
                                                          callbacks,
                                                          onCollapseRequested,
                                                          expandAnimation,
                                                          callbacks
                                                                  .nearPosition ==
                                                              base.FloatingPosition
                                                                  .top,
                                                        ),
                                                      );
                                                    }).toList(),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                                // Prominent actions as full-width tiles (only when expanded)
                                if (callbacks.isExpanded &&
                                    prominentActions != null &&
                                    prominentActions.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        ...prominentActions.map((action) {
                                          return Padding(
                                            padding: EdgeInsets.only(
                                              bottom: action ==
                                                      prominentActions.last
                                                  ? 0
                                                  : 6,
                                            ),
                                            child: (prominentActionBuilder ??
                                                buildProminentActionCard)(
                                              context,
                                              action,
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                if (isNearTop) ...[
                                  expandCollapseButton,
                                ] else ...[
                                  const SizedBox(height: 4),
                                  draggableIndicator,
                                ],
                              ],
                            );
                          },
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
  );
}

/// Build draggable indicator
Widget buildDraggableIndicator(BuildContext context) {
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
                .withOpacity(0.15), // More subtle - reduced from 0.4
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    ),
  );
}

/// Build expand/collapse button
Widget buildExpandCollapseButton(
  BuildContext context,
  base.ExpandableCallbacks callbacks,
  bool isNearTop,
) {
  // Arrow direction logic:
  // - Always collapses down, so arrow always points down when expanded
  // - When collapsed at top: points down (to expand down)
  // - When collapsed at bottom: points up (to expand up)
  IconData arrowIcon;
  if (callbacks.isExpanded) {
    // Expanded: always points down (to collapse down)
    arrowIcon = Icons.expand_more_rounded;
  } else {
    // Collapsed: down at top, up at bottom
    arrowIcon = isNearTop
        ? Icons.expand_more_rounded // Down arrow to expand downward
        : Icons.expand_less_rounded; // Up arrow to expand upward
  }

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: callbacks.toggle,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              arrowIcon,
              size: 16,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withOpacity(0.3), // More subtle - reduced from 0.7
            ),
          ],
        ),
      ),
    ),
  );
}

/// Build compact prominent button with icon and text (for collapsed state)
Widget buildCompactProminentButton(
  BuildContext context,
  ActionButtonData action,
  base.ExpandableCallbacks callbacks,
  VoidCallback? onCollapseRequested,
) {
  Color iconColor;
  Color textColor;
  Color backgroundColor;

  if (!action.enabled) {
    backgroundColor =
        Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.2);
    iconColor = Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3);
    textColor = Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4);
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
    backgroundColor =
        Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.25);
    iconColor = action.iconColor ?? Theme.of(context).colorScheme.primary;
    textColor = Theme.of(context).colorScheme.onSurface;
  }

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: action.enabled
          ? () {
              action.onTap?.call();
              if (onCollapseRequested != null) {
                onCollapseRequested();
              } else {
                callbacks.collapse();
              }
            }
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              action.icon,
              size: 18,
              color: iconColor,
            ),
            const SizedBox(width: 6),
            Text(
              action.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Build compact icon-only button (for collapsed state)
Widget buildCompactIconButton(
  BuildContext context,
  ActionButtonData action,
  base.ExpandableCallbacks callbacks,
  VoidCallback? onCollapseRequested,
) {
  Color iconColor;
  if (!action.enabled) {
    iconColor = Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3);
  } else if (action.icon == Octicons.issue_opened) {
    iconColor = Colors.green.shade600;
  } else if (action.icon == Octicons.git_pull_request) {
    iconColor = Colors.purple.shade600;
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
              if (onCollapseRequested != null) {
                onCollapseRequested();
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
              Icon(
                action.icon,
                size: 22,
                color: iconColor,
              ),
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
Widget buildExpandedActionWithLabel(
  BuildContext context,
  ActionButtonData action,
  int? index,
  base.ExpandableCallbacks callbacks,
  VoidCallback? onCollapseRequested,
  Animation<double> expandAnimation,
  bool isNearTop,
) {
  Color iconColor;
  if (!action.enabled) {
    iconColor = Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3);
  } else if (action.icon == Octicons.issue_opened) {
    iconColor = Colors.green.shade600;
  } else if (action.icon == Octicons.git_pull_request) {
    iconColor = Colors.purple.shade600;
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

  return base.ExpandedContentItem(
    animation: expandAnimation,
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
                  if (onCollapseRequested != null) {
                    onCollapseRequested();
                  } else {
                    callbacks.collapse();
                  }
                }
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon and count on same row
                Row(
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
                        size: 18,
                        color: iconColor,
                      ),
                    ),
                    if (badgeText != null && badgeText.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Text(
                        badgeText,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: 12,
                              color: iconColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ],
                ),
                // Title on separate row below
                if (action.label.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

/// Animated row widget for collapsed actions with fade/slide animations
class _AnimatedCollapsedActionsRow extends StatefulWidget {
  const _AnimatedCollapsedActionsRow({
    required this.enabledActions,
    required this.disabledActions,
    required this.prominentActions,
    required this.spacing,
    required this.buildCompactIconButton,
    required this.buildCompactProminentButton,
    required this.callbacks,
    required this.onCollapseRequested,
    required this.context,
    required this.expandAnimation,
  });

  final List<ActionButtonData> enabledActions;
  final List<ActionButtonData> disabledActions;
  final List<ActionButtonData>? prominentActions;
  final double spacing;
  final Widget Function(
    BuildContext context,
    ActionButtonData action,
    base.ExpandableCallbacks callbacks,
    VoidCallback? onCollapseRequested,
  ) buildCompactIconButton;
  final Widget Function(
    BuildContext context,
    ActionButtonData action,
    base.ExpandableCallbacks callbacks,
    VoidCallback? onCollapseRequested,
  ) buildCompactProminentButton;
  final base.ExpandableCallbacks callbacks;
  final VoidCallback? onCollapseRequested;
  final BuildContext context;
  final Animation<double> expandAnimation;

  @override
  State<_AnimatedCollapsedActionsRow> createState() =>
      _AnimatedCollapsedActionsRowState();
}

class _AnimatedCollapsedActionsRowState
    extends State<_AnimatedCollapsedActionsRow> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...widget.enabledActions.asMap().entries.map((entry) {
                final index = entry.key;
                final action = entry.value;
                return _AnimatedActionButton(
                  key: ValueKey('enabled_${action.label}_${action.icon}'),
                  action: action,
                  spacing: widget.spacing,
                  buildCompactIconButton: widget.buildCompactIconButton,
                  callbacks: widget.callbacks,
                  onCollapseRequested: widget.onCollapseRequested,
                  context: widget.context,
                  showDivider: index < widget.enabledActions.length - 1 ||
                      widget.disabledActions.isNotEmpty ||
                      (widget.prominentActions != null &&
                          widget.prominentActions!.isNotEmpty),
                  expandAnimation: widget.expandAnimation,
                );
              }),
              ...widget.disabledActions.asMap().entries.map((entry) {
                final index = entry.key;
                final action = entry.value;
                return _AnimatedActionButton(
                  key: ValueKey('disabled_${action.label}_${action.icon}'),
                  action: action,
                  spacing: widget.spacing,
                  buildCompactIconButton: widget.buildCompactIconButton,
                  callbacks: widget.callbacks,
                  onCollapseRequested: widget.onCollapseRequested,
                  context: widget.context,
                  showDivider: index < widget.disabledActions.length - 1 ||
                      (widget.prominentActions != null &&
                          widget.prominentActions!.isNotEmpty),
                  expandAnimation: widget.expandAnimation,
                );
              }),
              // Prominent actions in collapsed state (horizontal with text) - on the right
              if (widget.prominentActions != null &&
                  widget.prominentActions!.isNotEmpty)
                ...widget.prominentActions!.map((action) {
                  return _AnimatedActionButton(
                    key: ValueKey('prominent_${action.label}_${action.icon}'),
                    action: action,
                    spacing: widget.spacing,
                    buildCompactIconButton:
                        (context, action, callbacks, onCollapse) =>
                            widget.buildCompactProminentButton(
                      context,
                      action,
                      callbacks,
                      onCollapse,
                    ),
                    callbacks: widget.callbacks,
                    onCollapseRequested: widget.onCollapseRequested,
                    context: widget.context,
                    showDivider: false,
                    expandAnimation: widget.expandAnimation,
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}

/// Animated wrapper for individual action buttons in collapsed state
/// Each button animates independently when it appears/disappears
class _AnimatedActionButton extends StatefulWidget {
  const _AnimatedActionButton({
    required this.action,
    required this.spacing,
    required this.buildCompactIconButton,
    required this.callbacks,
    required this.onCollapseRequested,
    required this.context,
    required this.showDivider,
    required this.expandAnimation,
    super.key,
  });

  final ActionButtonData action;
  final double spacing;
  final Widget Function(
    BuildContext context,
    ActionButtonData action,
    base.ExpandableCallbacks callbacks,
    VoidCallback? onCollapseRequested,
  ) buildCompactIconButton;
  final base.ExpandableCallbacks callbacks;
  final VoidCallback? onCollapseRequested;
  final BuildContext context;
  final bool showDivider;
  final Animation<double> expandAnimation;

  @override
  State<_AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<_AnimatedActionButton> {
  // Track if this button was previously visible to detect when it appears/disappears
  bool _wasVisible = false;

  @override
  void initState() {
    super.initState();
    _wasVisible = !widget.callbacks.isExpanded;
    // Listen to expand animation to sync button animation with collapse
    widget.expandAnimation.addListener(_onExpandAnimationChanged);
    print(
        '[_AnimatedActionButton] initState: action=${widget.action.label}, isExpanded=${widget.callbacks.isExpanded}, expandAnimation.value=${widget.expandAnimation.value}');
  }

  @override
  void didUpdateWidget(_AnimatedActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expandAnimation != widget.expandAnimation) {
      oldWidget.expandAnimation.removeListener(_onExpandAnimationChanged);
      widget.expandAnimation.addListener(_onExpandAnimationChanged);
    }
    // Detect when button visibility changes (for tab swipes)
    final isNowVisible = !widget.callbacks.isExpanded;
    if (_wasVisible != isNowVisible) {
      _wasVisible = isNowVisible;
    }
  }

  @override
  void dispose() {
    widget.expandAnimation.removeListener(_onExpandAnimationChanged);
    super.dispose();
  }

  void _onExpandAnimationChanged() {
    if (mounted) {
      setState(() {
        // Trigger rebuild when expand animation changes
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // When collapsing (expanding -> collapsed), expandAnimation goes from 1 to 0
    // We want buttons to animate in (from 0 to 1) as the toolbar collapses
    // So we use the inverse: 1 - expandAnimation.value
    final collapseProgress = 1.0 - widget.expandAnimation.value;

    // Apply easing curve
    final easedProgress = Curves.easeOut.transform(collapseProgress);

    // Calculate slide offset (vertical)
    final slideOffset = Offset(0, (1 - easedProgress) * 0.1);

    return Opacity(
      opacity: easedProgress,
      child: Transform.translate(
        offset: slideOffset,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.only(right: widget.spacing),
              child: widget.buildCompactIconButton(
                widget.context,
                widget.action,
                widget.callbacks,
                widget.onCollapseRequested,
              ),
            ),
            if (widget.showDivider)
              Container(
                margin: EdgeInsets.only(right: widget.spacing),
                width: 1,
                height: 20,
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.outline.withOpacity(0.15),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// FloatingPosition enum imported from floating_expandable_widget.dart
