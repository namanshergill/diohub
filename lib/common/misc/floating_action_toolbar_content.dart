import 'package:diohub/common/misc/action_card_builder.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/misc/floating_expandable_widget.dart' as base;
import 'package:flex_list/flex_list.dart';
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
          15 + (expandAnimation.value * 12.0); // 8-20 range

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

              final content = Column(
                key: toolbarKey,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: callbacks.isExpanded ? 12 : 6,
                      vertical: callbacks.isExpanded ? 8 : 6,
                    ),
                    child: Builder(
                      builder: (context) {
                        final isNearTop =
                            callbacks.nearPosition == base.FloatingPosition.top;

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 4),
                            if (!callbacks.isExpanded)
                              IntrinsicWidth(
                                child: _AnimatedCollapsedActionsRow(
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
                              ),
                            AnimatedBuilder(
                              animation: expandAnimation,
                              builder: (context, child) {
                                // Apply easing curve for smoother animation
                                final curvedValue = Curves.easeInOutCubic
                                    .transform(expandAnimation.value);

                                // Add opacity animation for smoother collapse
                                final opacity = curvedValue.clamp(0.0, 1.0);

                                // Add subtle scale animation
                                final scale = 0.95 + (curvedValue * 0.05);

                                return Opacity(
                                  opacity: opacity,
                                  child: Transform.scale(
                                    scale: scale,
                                    alignment: isNearTop
                                        ? Alignment.topCenter
                                        : Alignment.bottomCenter,
                                    child: SizeTransition(
                                      sizeFactor: expandAnimation,
                                      axisAlignment: isNearTop ? -1.0 : 1.0,
                                      child: callbacks.isExpanded
                                          ? Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                // Compact FlexList layout for actions
                                                LayoutBuilder(
                                                  builder:
                                                      (context, constraints) {
                                                    // Ensure we have bounded constraints
                                                    if (!constraints.hasBoundedWidth ||
                                                        constraints.maxWidth
                                                            .isInfinite ||
                                                        constraints.maxWidth <=
                                                            0) {
                                                      // Return empty container if constraints are invalid
                                                      return const SizedBox
                                                          .shrink();
                                                    }

                                                    final allActions = [
                                                      ...visibleExpandedActions,
                                                    ];

                                                    if (allActions.isEmpty) {
                                                      return const SizedBox
                                                          .shrink();
                                                    }

                                                    // Use FlexList to show all items
                                                    return FlexList(
                                                      horizontalSpacing: 6.0,
                                                      verticalSpacing: 6.0,
                                                      children: allActions
                                                          .asMap()
                                                          .entries
                                                          .map((entry) {
                                                        final index = entry.key;
                                                        final action =
                                                            entry.value;

                                                        return buildExpandedActionWithLabel(
                                                          context,
                                                          action,
                                                          index,
                                                          callbacks,
                                                          onCollapseRequested,
                                                          expandAnimation,
                                                          callbacks
                                                                  .nearPosition ==
                                                              base.FloatingPosition
                                                                  .top,
                                                        );
                                                      }).toList(),
                                                    );
                                                  },
                                                ),
                                              ],
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Prominent actions as compact tiles (only when expanded)
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
                                          bottom:
                                              action == prominentActions.last
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
                            const SizedBox(height: 4),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              );

              // Only apply width constraints when expanded
              if (callbacks.isExpanded) {
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: expandedWidth.clamp(0.0, double.infinity),
                    maxWidth: expandedWidth.clamp(0.0, double.infinity),
                  ),
                  child: content,
                );
              }

              // When collapsed, use IntrinsicWidth to prevent full-width expansion
              return IntrinsicWidth(child: content);
            },
          ),
        ),
      ),
    ),
  );
}

/// Build draggable indicator
Widget buildDraggableIndicator(BuildContext context) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        width: 32,
        height: 4,
        decoration: BoxDecoration(
          color:
              Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.08),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ],
  );
}

/// Build expand/collapse button with arrow
Widget buildExpandCollapseButton(
  BuildContext context,
  base.ExpandableCallbacks callbacks,
  bool isNearTop,
) {
  // Arrow direction logic:
  // - When expanded: arrow is situation-aware
  //   - If widget is at bottom: arrow at top pointing down (to collapse down)
  //   - If widget is at top: arrow at bottom pointing up (to collapse up)
  // - When collapsed: arrow points to where it would expand
  //   - At top: points down (to expand down)
  //   - At bottom: points up (to expand up)
  IconData arrowIcon;
  if (callbacks.isExpanded) {
    // Expanded: situation-aware based on widget position
    if (isNearTop) {
      // Widget is at top: arrow at bottom pointing up (to collapse up)
      arrowIcon = Icons.expand_less_rounded;
    } else {
      // Widget is at bottom: arrow at top pointing down (to collapse down)
      arrowIcon = Icons.expand_more_rounded;
    }
  } else {
    // Collapsed: arrow points to where it would expand
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
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              arrowIcon,
              size: 16,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withOpacity(0.3),
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

/// Build expanded action matching collapsed tile styling
Widget buildExpandedActionWithLabel(
  BuildContext context,
  ActionButtonData action,
  int? index,
  base.ExpandableCallbacks callbacks,
  VoidCallback? onCollapseRequested,
  Animation<double> expandAnimation,
  bool isNearTop,
) {
  // Use same color logic as collapsed tiles
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
    child: Material(
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
              if (action.label.isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    action.label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontSize: 12,
                          color: action.enabled
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withOpacity(0.4),
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
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
  double? _lastLoggedValue;

  @override
  void initState() {
    super.initState();
    _lastLoggedValue = widget.expandAnimation.value;
    print(
        '[_AnimatedActionButton] initState: action=${widget.action.label}, isExpanded=${widget.callbacks.isExpanded}, expandAnimation.value=${widget.expandAnimation.value}');
  }

  @override
  Widget build(BuildContext context) {
    // Use AnimatedBuilder to listen to animation without causing rebuild loops
    return AnimatedBuilder(
      animation: widget.expandAnimation,
      builder: (context, child) {
        // When collapsing (expanding -> collapsed), expandAnimation goes from 1 to 0
        // We want buttons to animate in (from 0 to 1) as the toolbar collapses
        // So we use the inverse: 1 - expandAnimation.value
        final collapseProgress = 1.0 - widget.expandAnimation.value;

        // Apply easing curve
        final easedProgress = Curves.easeOut.transform(collapseProgress);

        // Calculate slide offset (vertical)
        final slideOffset = Offset(0, (1 - easedProgress) * 0.1);

        // Only log when value changes significantly (every 0.1 or at endpoints)
        final animValue = widget.expandAnimation.value;
        final shouldLog = _lastLoggedValue == null ||
            (animValue == 0.0 || animValue == 1.0) ||
            ((animValue - _lastLoggedValue!).abs() >= 0.1);
        if (shouldLog) {
          _lastLoggedValue = animValue;
          print(
              '[_AnimatedActionButton] build: action=${widget.action.label}, expandAnimation.value=$animValue, collapseProgress=$collapseProgress, easedProgress=$easedProgress');
        }

        return Opacity(
          opacity: easedProgress,
          child: Transform.translate(
            offset: slideOffset,
            child: child,
          ),
        );
      },
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
                color: Theme.of(widget.context)
                    .colorScheme
                    .outline
                    .withOpacity(0.15),
              ),
            ),
        ],
      ),
    );
  }
}

// FloatingPosition enum imported from floating_expandable_widget.dart
