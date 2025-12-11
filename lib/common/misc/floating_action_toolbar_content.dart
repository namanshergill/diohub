import 'package:diohub/common/animations/size_expanded_widget.dart';
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
  String? title,
}) {
  // Keep all actions (including hidden ones) for animation support
  // The animated widgets will handle visibility with animation and collapse to zero size
  final regularActions =
      actions.where((a) => !(prominentActions ?? []).contains(a)).toList();
  final allProminentActions = prominentActions ?? [];

  // Helper function to check if action should be visible in expanded state
  // Used for prominent actions visibility checks
  bool _isVisibleInExpanded(ActionButtonData action) {
    return action.visibilityState == ActionButtonVisibilityState.expandedOnly ||
        action.visibilityState == ActionButtonVisibilityState.both;
  }

  // Pass ALL actions to animated widgets so they can animate in/out smoothly
  // The animated widgets will handle visibility based on visibilityState
  // Don't filter by visible here - let animated widgets handle visibility animations
  // They will filter internally to prevent hit test errors when fully hidden
  final allCollapsedEnabled =
      regularActions.where((a) => a.enabled == true).toList();
  final allCollapsedDisabled =
      regularActions.where((a) => a.enabled != true).toList();

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
                      horizontal: callbacks.isExpanded ? 20 : 8,
                      vertical: callbacks.isExpanded ? 12 : 8,
                    ),
                    child: Builder(
                      builder: (context) {
                        final isNearTop =
                            callbacks.nearPosition == base.FloatingPosition.top;

                        // Don't filter by visible here - let animated widgets handle visibility animations
                        // They will filter internally to prevent hit test errors when fully hidden
                        final visibleProminentActionsExpanded =
                            allProminentActions;

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: callbacks.isExpanded ? 4 : 4),
                            if (!callbacks.isExpanded)
                              IntrinsicWidth(
                                child: _AnimatedCollapsedActionsRow(
                                  enabledActions: allCollapsedEnabled,
                                  disabledActions: allCollapsedDisabled,
                                  prominentActions: allProminentActions,
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
                                                // Title in expanded view
                                                if (title != null &&
                                                    title.isNotEmpty)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                      bottom: 12,
                                                    ),
                                                    child: Text(
                                                      title,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleLarge
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 20,
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .onSurface
                                                                .withOpacity(
                                                                    0.8),
                                                          ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
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

                                                    // Don't filter by visible here - let animated widgets handle visibility animations
                                                    // They will filter internally to prevent hit test errors when fully hidden
                                                    final allActions =
                                                        regularActions;

                                                    if (allActions.isEmpty) {
                                                      return const SizedBox
                                                          .shrink();
                                                    }

                                                    // Use FlexList to show all items with animation support
                                                    return FlexList(
                                                      horizontalSpacing: 8.0,
                                                      verticalSpacing: 8.0,
                                                      children: allActions
                                                          .asMap()
                                                          .entries
                                                          .map((entry) {
                                                        final index = entry.key;
                                                        final action =
                                                            entry.value;

                                                        return _AnimatedExpandedAction(
                                                          key: ValueKey(
                                                              'expanded_${action.label}_${action.icon}'),
                                                          action: action,
                                                          index: index,
                                                          callbacks: callbacks,
                                                          onCollapseRequested:
                                                              onCollapseRequested,
                                                          expandAnimation:
                                                              expandAnimation,
                                                          isNearTop: callbacks
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
                            // Prominent actions using Column (only when expanded)
                            // Use SizeExpandedSection to collapse padding when all actions are hidden
                            // This keeps all actions in tree while preventing empty padding
                            if (callbacks.isExpanded &&
                                visibleProminentActionsExpanded.isNotEmpty)
                              SizeExpandedSection(
                                expand: visibleProminentActionsExpanded
                                    .any((a) => _isVisibleInExpanded(a)),
                                axis: Axis.vertical,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      // Ensure we have bounded constraints
                                      if (!constraints.hasBoundedWidth ||
                                          constraints.maxWidth.isInfinite ||
                                          constraints.maxWidth <= 0) {
                                        return const SizedBox.shrink();
                                      }

                                      // Use Column instead of FlexList for prominent actions
                                      // FlexList can have issues with zero-sized animated widgets
                                      // Column with SizeTransition handles animations better
                                      // Padding wraps the animated widget so it collapses with hidden actions
                                      // Filter to only visible actions for determining last item
                                      final actuallyVisibleExpanded =
                                          visibleProminentActionsExpanded
                                              .where((a) =>
                                                  _isVisibleInExpanded(a))
                                              .toList();
                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children:
                                            visibleProminentActionsExpanded
                                                .asMap()
                                                .entries
                                                .map((entry) {
                                          final action = entry.value;
                                          // Check if this is the last VISIBLE action
                                          final isLastVisible =
                                              actuallyVisibleExpanded
                                                      .isNotEmpty &&
                                                  action ==
                                                      actuallyVisibleExpanded[
                                                          actuallyVisibleExpanded
                                                                  .length -
                                                              1];
                                          return SizedBox(
                                            width: double.infinity,
                                            child: _AnimatedProminentAction(
                                              key: ValueKey(
                                                  'prominent_expanded_${action.label}_${action.icon}'),
                                              action: action,
                                              prominentActionBuilder:
                                                  prominentActionBuilder ??
                                                      buildProminentActionCard,
                                              expandAnimation: expandAnimation,
                                              callbacks: callbacks,
                                              toolbarKey: toolbarKey,
                                              bottomPadding:
                                                  isLastVisible ? 0 : 4.0,
                                            ),
                                          );
                                        }).toList(),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            SizedBox(height: callbacks.isExpanded ? 4 : 4),
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
        width: double.infinity,
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
          mainAxisAlignment: MainAxisAlignment.start,
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
  // Helper function to check if action should be visible in collapsed state
  bool _isVisibleInCollapsed(ActionButtonData action) {
    return action.visibilityState ==
            ActionButtonVisibilityState.collapsedOnly ||
        action.visibilityState == ActionButtonVisibilityState.both;
  }

  @override
  Widget build(BuildContext context) {
    // Don't filter by visible here - let animated widgets handle visibility animations
    // They will filter internally to prevent hit test errors when fully hidden
    final visibleProminentActionsCollapsed = widget.prominentActions ?? [];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horizontal row of regular actions
        Builder(
          builder: (context) {
            // Filter to only visible actions for divider calculation
            final visibleEnabled = widget.enabledActions
                .where((a) => _isVisibleInCollapsed(a))
                .toList();
            final visibleDisabled = widget.disabledActions
                .where((a) => _isVisibleInCollapsed(a))
                .toList();

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...widget.enabledActions.map((action) {
                  // Check if this is the last VISIBLE enabled action
                  final isLastVisibleEnabled = visibleEnabled.isNotEmpty &&
                      action == visibleEnabled[visibleEnabled.length - 1];
                  // Show divider if not the last visible enabled action, or if there are visible disabled actions
                  final hasVisibleDisabled = visibleDisabled.isNotEmpty;
                  final showDivider =
                      !isLastVisibleEnabled || hasVisibleDisabled;

                  return _AnimatedActionButton(
                    key: ValueKey('enabled_${action.label}_${action.icon}'),
                    action: action,
                    spacing: widget.spacing,
                    buildCompactIconButton: widget.buildCompactIconButton,
                    callbacks: widget.callbacks,
                    onCollapseRequested: widget.onCollapseRequested,
                    context: widget.context,
                    showDivider: showDivider,
                    expandAnimation: widget.expandAnimation,
                  );
                }),
                ...widget.disabledActions.map((action) {
                  // Check if this is the last VISIBLE disabled action
                  final isLastVisibleDisabled = visibleDisabled.isNotEmpty &&
                      action == visibleDisabled[visibleDisabled.length - 1];
                  // Show divider only if not the last visible disabled action

                  return _AnimatedActionButton(
                    key: ValueKey('disabled_${action.label}_${action.icon}'),
                    action: action,
                    spacing: widget.spacing,
                    buildCompactIconButton: widget.buildCompactIconButton,
                    callbacks: widget.callbacks,
                    onCollapseRequested: widget.onCollapseRequested,
                    context: widget.context,
                    showDivider: !isLastVisibleDisabled,
                    expandAnimation: widget.expandAnimation,
                  );
                }),
              ],
            );
          },
        ),
        // Prominent actions in collapsed state (vertical) - below other actions
        // Use SizeExpandedSection to collapse padding when all actions are hidden
        // This keeps all actions in tree while preventing empty padding
        if (visibleProminentActionsCollapsed.isNotEmpty)
          SizeExpandedSection(
            expand: visibleProminentActionsCollapsed
                .any((a) => _isVisibleInCollapsed(a)),
            axis: Axis.vertical,
            child: Padding(
              padding: EdgeInsets.only(top: widget.spacing),
              child: Builder(
                builder: (context) {
                  // Filter to only visible actions for determining last item
                  final actuallyVisibleCollapsed =
                      visibleProminentActionsCollapsed
                          .where((a) => _isVisibleInCollapsed(a))
                          .toList();
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: visibleProminentActionsCollapsed
                        .asMap()
                        .entries
                        .map((entry) {
                      final action = entry.value;
                      // Check if this is the last VISIBLE action
                      final isLastVisible =
                          actuallyVisibleCollapsed.isNotEmpty &&
                              action ==
                                  actuallyVisibleCollapsed[
                                      actuallyVisibleCollapsed.length - 1];
                      // Padding is inside the animated widget so it collapses with hidden actions
                      return _AnimatedActionButton(
                        key: ValueKey(
                            'prominent_${action.label}_${action.icon}'),
                        action: action,
                        spacing:
                            0, // No spacing for vertical layout (triggers SizeTransition)
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
                        bottomPadding: isLastVisible ? 0 : widget.spacing,
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

/// Animated wrapper for expanded actions with visibility support
class _AnimatedExpandedAction extends StatefulWidget {
  const _AnimatedExpandedAction({
    required this.action,
    required this.index,
    required this.callbacks,
    required this.onCollapseRequested,
    required this.expandAnimation,
    required this.isNearTop,
    super.key,
  });

  final ActionButtonData action;
  final int index;
  final base.ExpandableCallbacks callbacks;
  final VoidCallback? onCollapseRequested;
  final Animation<double> expandAnimation;
  final bool isNearTop;

  @override
  State<_AnimatedExpandedAction> createState() =>
      _AnimatedExpandedActionState();
}

class _AnimatedExpandedActionState extends State<_AnimatedExpandedAction>
    with SingleTickerProviderStateMixin {
  late AnimationController _visibilityController;
  late Animation<double> _fadeAnimation;
  bool _wasVisible = true;
  AnimationStatusListener? _statusListener;

  bool _isActionVisible() {
    // Expanded actions are always in expanded state
    return widget.action.visibilityState ==
            ActionButtonVisibilityState.expandedOnly ||
        widget.action.visibilityState == ActionButtonVisibilityState.both;
  }

  @override
  void initState() {
    super.initState();
    _wasVisible = _isActionVisible();
    _visibilityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _visibilityController,
      curve: Curves.easeInOut,
    );
    if (_wasVisible) {
      _visibilityController.value = 1.0;
    } else {
      _visibilityController.value = 0.0;
    }
  }

  @override
  void didUpdateWidget(_AnimatedExpandedAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isNowVisible = _isActionVisible();
    if (_wasVisible != isNowVisible) {
      // Remove old listener if exists
      if (_statusListener != null) {
        _visibilityController.removeStatusListener(_statusListener!);
        _statusListener = null;
      }

      if (isNowVisible) {
        _visibilityController.forward();
      } else {
        _visibilityController.reverse();
      }
      _wasVisible = isNowVisible;

      // Trigger size recalculation after visibility animation completes
      _statusListener = (status) {
        if (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed) {
          _visibilityController.removeStatusListener(_statusListener!);
          _statusListener = null;
          // Animation completed - widget will handle position updates automatically
        }
      };
      _visibilityController.addStatusListener(_statusListener!);
    }
  }

  @override
  void dispose() {
    if (_statusListener != null) {
      _visibilityController.removeStatusListener(_statusListener!);
    }
    _visibilityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFullyHidden = _fadeAnimation.value == 0.0;

    // Use SizeTransition to collapse width, wrapped in IntrinsicWidth for proper measurement
    // When sizeFactor is 0, the widget takes zero space in FlexList
    // Keep widget in tree even when hidden to allow smooth re-animation
    return IntrinsicWidth(
      child: SizeTransition(
        sizeFactor: _fadeAnimation,
        axis: Axis.horizontal,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: IgnorePointer(
            ignoring: isFullyHidden,
            child: buildExpandedActionWithLabel(
              context,
              widget.action,
              widget.index,
              widget.callbacks,
              widget.onCollapseRequested,
              widget.expandAnimation,
              widget.isNearTop,
            ),
          ),
        ),
      ),
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
    this.bottomPadding = 0,
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
  final double bottomPadding;

  @override
  State<_AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<_AnimatedActionButton>
    with SingleTickerProviderStateMixin {
  double? _lastLoggedValue;
  late AnimationController _visibilityController;
  late Animation<double> _fadeAnimation;
  bool _wasVisible = true;
  AnimationStatusListener? _statusListener;

  bool _isActionVisible() {
    // Check visibility based on current expanded/collapsed state
    if (widget.callbacks.isExpanded) {
      return widget.action.visibilityState ==
              ActionButtonVisibilityState.expandedOnly ||
          widget.action.visibilityState == ActionButtonVisibilityState.both;
    } else {
      return widget.action.visibilityState ==
              ActionButtonVisibilityState.collapsedOnly ||
          widget.action.visibilityState == ActionButtonVisibilityState.both;
    }
  }

  @override
  void initState() {
    super.initState();
    _lastLoggedValue = widget.expandAnimation.value;
    _wasVisible = _isActionVisible();
    _visibilityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _visibilityController,
      curve: Curves.easeInOut,
    );
    if (_wasVisible) {
      _visibilityController.value = 1.0;
    } else {
      _visibilityController.value = 0.0;
    }
    print(
        '[_AnimatedActionButton] initState: action=${widget.action.label}, isExpanded=${widget.callbacks.isExpanded}, expandAnimation.value=${widget.expandAnimation.value}');
  }

  @override
  void didUpdateWidget(_AnimatedActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isNowVisible = _isActionVisible();
    if (_wasVisible != isNowVisible ||
        oldWidget.action.visibilityState != widget.action.visibilityState ||
        oldWidget.callbacks.isExpanded != widget.callbacks.isExpanded) {
      // Remove old listener if exists
      if (_statusListener != null) {
        _visibilityController.removeStatusListener(_statusListener!);
        _statusListener = null;
      }

      if (isNowVisible) {
        _visibilityController.forward();
      } else {
        _visibilityController.reverse();
      }
      _wasVisible = isNowVisible;

      // Trigger size recalculation after visibility animation completes
      _statusListener = (status) {
        if (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed) {
          _visibilityController.removeStatusListener(_statusListener!);
          _statusListener = null;
          // Animation completed - widget will handle position updates automatically
        }
      };
      _visibilityController.addStatusListener(_statusListener!);
    }
  }

  @override
  void dispose() {
    if (_statusListener != null) {
      _visibilityController.removeStatusListener(_statusListener!);
    }
    _visibilityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use AnimatedBuilder to listen to animation without causing rebuild loops
    return AnimatedBuilder(
      animation: Listenable.merge([widget.expandAnimation, _fadeAnimation]),
      builder: (context, child) {
        // When collapsing (expanding -> collapsed), expandAnimation goes from 1 to 0
        // We want buttons to animate in (from 0 to 1) as the toolbar collapses
        // So we use the inverse: 1 - expandAnimation.value
        final collapseProgress = 1.0 - widget.expandAnimation.value;

        // Apply easing curve
        final easedProgress = Curves.easeOut.transform(collapseProgress);

        // Calculate slide offset (vertical)
        final slideOffset = Offset(0, (1 - easedProgress) * 0.1);

        // Combine collapse animation with visibility animation
        final combinedOpacity = easedProgress * _fadeAnimation.value;

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

        // Prevent hit testing when fully hidden to avoid hit test errors
        final isFullyHidden = _fadeAnimation.value == 0.0;

        // For prominent actions (spacing == 0), use SizeTransition to collapse vertically
        // For regular actions (spacing > 0), use SizeTransition to collapse horizontally
        Widget animatedWidget;
        if (widget.spacing == 0) {
          // Prominent actions: use SizeTransition to collapse vertically
          // Padding is inside SizeTransition so it collapses with the widget
          animatedWidget = SizeTransition(
            sizeFactor: _fadeAnimation,
            axis: Axis.vertical,
            child: Padding(
              padding: EdgeInsets.only(bottom: widget.bottomPadding),
              child: Opacity(
                opacity: combinedOpacity.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: slideOffset,
                  child: child,
                ),
              ),
            ),
          );
        } else {
          // Regular actions: use SizeTransition to collapse width while staying in tree
          // This allows smooth animations without removing widgets from tree
          // Don't wrap in IntrinsicWidth - it causes overflow issues in Row layouts
          animatedWidget = SizeTransition(
            sizeFactor: _fadeAnimation,
            axis: Axis.horizontal,
            child: Opacity(
              opacity: combinedOpacity.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: slideOffset,
                child: child,
              ),
            ),
          );
        }

        // Prevent hit testing when fully hidden
        if (isFullyHidden) {
          return IgnorePointer(
            child: animatedWidget,
          );
        }
        return animatedWidget;
      },
      child: widget.spacing == 0
          ? // For prominent actions (spacing == 0), the parent Column with crossAxisAlignment.stretch
          // will expand to full width, so we don't need SizedBox(width: double.infinity)
          // which causes IntrinsicWidth calculation issues
          widget.buildCompactIconButton(
              widget.context,
              widget.action,
              widget.callbacks,
              widget.onCollapseRequested,
            )
          : // For regular actions, use horizontal row layout
          Row(
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

/// Animated wrapper for prominent actions in expanded state
class _AnimatedProminentAction extends StatefulWidget {
  const _AnimatedProminentAction({
    required this.action,
    required this.prominentActionBuilder,
    required this.expandAnimation,
    required this.callbacks,
    required this.toolbarKey,
    this.bottomPadding = 0,
    super.key,
  });

  final ActionButtonData action;
  final Widget Function(BuildContext context, ActionButtonData action)
      prominentActionBuilder;
  final Animation<double> expandAnimation;
  final base.ExpandableCallbacks callbacks;
  final GlobalKey toolbarKey;
  final double bottomPadding;

  @override
  State<_AnimatedProminentAction> createState() =>
      _AnimatedProminentActionState();
}

class _AnimatedProminentActionState extends State<_AnimatedProminentAction>
    with SingleTickerProviderStateMixin {
  late AnimationController _visibilityController;
  late Animation<double> _fadeAnimation;
  bool _wasVisible = true;
  AnimationStatusListener? _statusListener;

  bool _isActionVisible() {
    // Check visibility based on current expanded/collapsed state
    if (widget.callbacks.isExpanded) {
      return widget.action.visibilityState ==
              ActionButtonVisibilityState.expandedOnly ||
          widget.action.visibilityState == ActionButtonVisibilityState.both;
    } else {
      return widget.action.visibilityState ==
              ActionButtonVisibilityState.collapsedOnly ||
          widget.action.visibilityState == ActionButtonVisibilityState.both;
    }
  }

  @override
  void initState() {
    super.initState();
    _wasVisible = _isActionVisible();
    _visibilityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _visibilityController,
      curve: Curves.easeInOut,
    );
    if (_wasVisible) {
      _visibilityController.value = 1.0;
    } else {
      _visibilityController.value = 0.0;
    }
  }

  @override
  void didUpdateWidget(_AnimatedProminentAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isNowVisible = _isActionVisible();
    final visibilityChanged = _wasVisible != isNowVisible ||
        oldWidget.action.visibilityState != widget.action.visibilityState ||
        oldWidget.callbacks.isExpanded != widget.callbacks.isExpanded;

    if (visibilityChanged) {
      // Remove old listener if exists
      if (_statusListener != null) {
        _visibilityController.removeStatusListener(_statusListener!);
        _statusListener = null;
      }

      // Always animate - don't check current value, just animate
      if (isNowVisible) {
        _visibilityController.forward();
      } else {
        _visibilityController.reverse();
      }
      _wasVisible = isNowVisible;

      // Trigger size recalculation after visibility animation completes
      _statusListener = (status) {
        if (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed) {
          _visibilityController.removeStatusListener(_statusListener!);
          _statusListener = null;
          // Wait for animation to fully complete and layout to update
          // Animation completed - widget will handle position updates automatically
        }
      };
      _visibilityController.addStatusListener(_statusListener!);
    }
  }

  @override
  void dispose() {
    if (_statusListener != null) {
      _visibilityController.removeStatusListener(_statusListener!);
    }
    _visibilityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // SizeTransition expects an Animation<double>, not a double value
    // The animation controller should already provide values between 0.0 and 1.0
    final isFullyHidden = _fadeAnimation.value == 0.0;

    // Padding is inside SizeTransition so it collapses with the widget
    final animatedWidget = SizeTransition(
      sizeFactor: _fadeAnimation,
      axis: Axis.vertical,
      child: Padding(
        padding: EdgeInsets.only(bottom: widget.bottomPadding),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SizedBox(
            width: double.infinity,
            child: widget.prominentActionBuilder(context, widget.action),
          ),
        ),
      ),
    );

    // Prevent hit testing when fully hidden
    if (isFullyHidden) {
      return IgnorePointer(
        child: animatedWidget,
      );
    }
    return animatedWidget;
  }
}

// FloatingPosition enum imported from floating_expandable_widget.dart
