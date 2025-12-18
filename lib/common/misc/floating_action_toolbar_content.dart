import 'package:diohub/common/animations/size_expanded_widget.dart';
import 'package:diohub/common/misc/action_card_builder.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/misc/floating_expandable_widget.dart' as base;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

// Re-export shared utilities for convenience
export 'package:diohub/common/misc/action_card_builder.dart'
    show calculateActionButtonColors;
export 'package:diohub/common/misc/collapsible_action_buttons.dart'
    show ActionButtonColors;

/// Builds the toolbar content widget
Widget buildToolbarContent({
  required BuildContext context,
  required base.ExpandableCallbacks callbacks,
  required List<ActionButtonData> actions,
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
  String? subtitle,
  bool debugLogging = false,
}) {
  // Automatically split actions by type:
  // - MinorActionButton → minor actions (row)
  // - MajorActionButton, ExpandableActionButton, CheckboxActionButton → prominent actions
  final regularActions = actions.where((a) => a is MinorActionButton).toList();
  final allProminentActions = actions
      .where((a) =>
          a is MajorActionButton ||
          a is ExpandableActionButton ||
          a is CheckboxActionButton)
      .toList();

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
          // refractiveIndex: 1.5,
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

              final content = AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                alignment: Alignment.center,
                child: Column(
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
                          final isNearTop = callbacks.nearPosition ==
                              base.FloatingPosition.top;

                          // Don't filter by visible here - let animated widgets handle visibility animations
                          // They will filter internally to prevent hit test errors when fully hidden
                          final visibleProminentActionsExpanded =
                              allProminentActions;

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: callbacks.isExpanded ? 2 : 4),
                              if (!callbacks.isExpanded)
                                Center(
                                  child: IntrinsicWidth(
                                    child: _AnimatedCollapsedActionsRow(
                                      enabledActions: allCollapsedEnabled,
                                      disabledActions: allCollapsedDisabled,
                                      prominentActions: allProminentActions,
                                      spacing: spacing,
                                      buildCompactIconButton:
                                          buildCompactIconButton,
                                      buildCompactProminentButton:
                                          buildCompactProminentButton,
                                      prominentActionBuilder:
                                          prominentActionBuilder,
                                      callbacks: callbacks,
                                      onCollapseRequested: onCollapseRequested,
                                      context: context,
                                      expandAnimation: expandAnimation,
                                      toolbarKey: toolbarKey,
                                      debugLogging: debugLogging,
                                    ),
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
                                                  // Title and subtitle (minimal, clean)
                                                  if (title != null &&
                                                      title.isNotEmpty)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 4,
                                                              bottom: 10),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            title,
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .titleLarge
                                                                ?.copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontSize: 19,
                                                                  color: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .onSurface
                                                                      .withOpacity(
                                                                          0.87),
                                                                ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          if (subtitle !=
                                                                  null &&
                                                              subtitle
                                                                  .isNotEmpty)
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      top: 2),
                                                              child: Text(
                                                                subtitle,
                                                                style: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .bodyMedium
                                                                    ?.copyWith(
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .onSurface
                                                                          .withOpacity(
                                                                              0.6),
                                                                      fontSize:
                                                                          13,
                                                                    ),
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  // Regular actions in compact wrapping grid
                                                  LayoutBuilder(
                                                    builder:
                                                        (context, constraints) {
                                                      // Ensure we have bounded constraints
                                                      if (!constraints
                                                              .hasBoundedWidth ||
                                                          constraints.maxWidth
                                                              .isInfinite ||
                                                          constraints
                                                                  .maxWidth <=
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

                                                      // Compact wrapping grid - tighter spacing for modern look
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                bottom: 8),
                                                        child: Wrap(
                                                          spacing: 6.0,
                                                          runSpacing: 6.0,
                                                          alignment:
                                                              WrapAlignment
                                                                  .start,
                                                          children: allActions
                                                              .asMap()
                                                              .entries
                                                              .map((entry) {
                                                            final index =
                                                                entry.key;
                                                            final action =
                                                                entry.value;

                                                            return _AnimatedExpandedAction(
                                                              key: ValueKey(
                                                                  'expanded_${action.label}_${action.icon}'),
                                                              action: action,
                                                              index: index,
                                                              callbacks:
                                                                  callbacks,
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
                                                        ),
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
                              // Always include the section so widgets can animate out smoothly
                              // Use SizeExpandedSection to collapse padding when all actions are hidden
                              if (callbacks.isExpanded &&
                                  visibleProminentActionsExpanded.isNotEmpty)
                                SizeExpandedSection(
                                  expand: visibleProminentActionsExpanded
                                      .any((a) => a.isVisibleInExpanded),
                                  axis: Axis.vertical,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        // Ensure we have bounded constraints
                                        if (!constraints.hasBoundedWidth ||
                                            constraints.maxWidth.isInfinite ||
                                            constraints.maxWidth <= 0) {
                                          return const SizedBox.shrink();
                                        }

                                        // Map over ALL actions (not just visible ones) so animations work properly
                                        // The _AnimatedProminentAction widget handles visibility internally
                                        // Filter to only visible actions for determining last item spacing
                                        final actuallyVisibleExpanded =
                                            visibleProminentActionsExpanded
                                                .where((a) =>
                                                    a.isVisibleInExpanded)
                                                .toList();

                                        return Column(
                                          key: const ValueKey(
                                              'prominent_actions_column'),
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children:
                                              visibleProminentActionsExpanded
                                                  .asMap()
                                                  .entries
                                                  .map((entry) {
                                            final action = entry.value;
                                            // Check if this is the last VISIBLE action for spacing
                                            final isLastVisible =
                                                actuallyVisibleExpanded
                                                        .isNotEmpty &&
                                                    action ==
                                                        actuallyVisibleExpanded[
                                                            actuallyVisibleExpanded
                                                                    .length -
                                                                1];
                                            // Pass bottomPadding to _AnimatedProminentAction so it's inside SizeTransition
                                            return SizedBox(
                                              width: double.infinity,
                                              child: _AnimatedProminentAction(
                                                key: ValueKey(
                                                    'prominent_expanded_${action.label}'),
                                                action: action,
                                                prominentActionBuilder:
                                                    prominentActionBuilder ??
                                                        buildProminentActionCard,
                                                expandAnimation:
                                                    expandAnimation,
                                                callbacks: callbacks,
                                                toolbarKey: toolbarKey,
                                                bottomPadding:
                                                    isLastVisible ? 0 : 8.0,
                                                debugLogging: debugLogging,
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
                ),
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
              return content;
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
  // Calculate colors using shared function
  final colors = calculateActionButtonColors(
    context,
    action,
    forProminentButton: true,
  );

  // Debug: Print checkbox state for AnimatedContainer animation
  if (action is CheckboxActionButton) {
    final isSelected = action.value;
    print(
        '[FloatingToolbar] buildCompactProminentButton: Checkbox ${action.label}, value=$isSelected');
    print(
        '  - Background: ${colors.backgroundColor} (hashCode: ${colors.backgroundColor.hashCode})');
    print(
        '  - IconColor: ${colors.iconColor} (hashCode: ${colors.iconColor.hashCode})');
    print(
        '  - TextColor: ${colors.textColor} (hashCode: ${colors.textColor.hashCode})');
    print('  - AnimatedContainer key: checkbox_${action.label}');
  }

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: action.enabled
          ? () {
              if (action.handleTapAndShouldCollapse()) {
                if (onCollapseRequested != null) {
                  onCollapseRequested();
                } else {
                  callbacks.collapse();
                }
              }
            }
          : null,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        key: ValueKey('checkbox_${action.label}'),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        onEnd: () {
          if (action is CheckboxActionButton) {
            print(
                '[FloatingToolbar] AnimatedContainer animation ended for ${action.label}');
          }
        },
        decoration: BoxDecoration(
          color: colors.backgroundColor,
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
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                action.displayIcon,
                key: ValueKey(action.displayIcon),
                size: 18,
                color: colors.iconColor,
              ),
            ),
            const SizedBox(width: 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ) ??
                  const TextStyle(),
              child: Text(action.label),
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
  final iconColor = action.getIconColor(context);
  final badgeText = action.badgeText;

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: action.enabled
          ? () {
              if (action.handleTapAndShouldCollapse()) {
                if (onCollapseRequested != null) {
                  onCollapseRequested();
                } else {
                  callbacks.collapse();
                }
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
                action.displayIcon,
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

/// Build expanded action as pill/chip for horizontal scrollable row
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
  final iconColor = action.getIconColor(context);
  final badgeText = action.badgeText;
  final colors = calculateActionButtonColors(context, action);

  return base.ExpandedContentItem(
    animation: expandAnimation,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.enabled
            ? () {
                if (action.handleTapAndShouldCollapse()) {
                  if (onCollapseRequested != null) {
                    onCollapseRequested();
                  } else {
                    callbacks.collapse();
                  }
                }
              }
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colors.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.08),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                action.displayIcon,
                size: 16,
                color: iconColor,
              ),
              if (action.label.isNotEmpty) ...[
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    action.label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontSize: 12,
                          color: action.enabled
                              ? colors.textColor
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
                const SizedBox(width: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 9,
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
    required this.prominentActionBuilder,
    required this.callbacks,
    required this.onCollapseRequested,
    required this.context,
    required this.expandAnimation,
    required this.toolbarKey,
    this.debugLogging = false,
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
  final Widget Function(BuildContext context, ActionButtonData action)?
      prominentActionBuilder;
  final base.ExpandableCallbacks callbacks;
  final VoidCallback? onCollapseRequested;
  final BuildContext context;
  final Animation<double> expandAnimation;
  final GlobalKey toolbarKey;
  final bool debugLogging;

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
      crossAxisAlignment: CrossAxisAlignment.center,
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
              mainAxisAlignment: MainAxisAlignment.center,
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
                    debugLogging: widget.debugLogging,
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
                    debugLogging: widget.debugLogging,
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
                      // Use _AnimatedProminentAction for expandable actions to support expandable options
                      // Use _AnimatedActionButton for non-expandable actions
                      if (action is ExpandableActionButton) {
                        return _AnimatedProminentAction(
                          key: ValueKey('prominent_collapsed_${action.label}'),
                          action: action,
                          prominentActionBuilder:
                              widget.prominentActionBuilder ??
                                  buildProminentActionCard,
                          expandAnimation: widget.expandAnimation,
                          callbacks: widget.callbacks,
                          toolbarKey: widget.toolbarKey,
                          bottomPadding: isLastVisible ? 0 : widget.spacing,
                          debugLogging: widget.debugLogging,
                        );
                      } else {
                        // Use _AnimatedProminentAction for all prominent actions (same as expanded state)
                        // This ensures consistent rebuild behavior for checkbox animations
                        return _AnimatedProminentAction(
                          key: ValueKey('prominent_collapsed_${action.label}'),
                          action: action,
                          prominentActionBuilder: (context, action) =>
                              widget.buildCompactProminentButton(
                            context,
                            action,
                            widget.callbacks,
                            widget.onCollapseRequested,
                          ),
                          expandAnimation: widget.expandAnimation,
                          callbacks: widget.callbacks,
                          toolbarKey: widget.toolbarKey,
                          bottomPadding: isLastVisible ? 0 : widget.spacing,
                          debugLogging: widget.debugLogging,
                        );
                      }
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

    // Use SizeTransition to collapse width when hidden
    // When sizeFactor is 0, the widget takes zero space in Wrap
    // Keep widget in tree even when hidden to allow smooth re-animation
    // Wrap widget handles sizing automatically, no need for IntrinsicWidth
    return SizeTransition(
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
    this.debugLogging = false,
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
  final bool debugLogging;

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
    return widget.action.isVisibleWhen(widget.callbacks.isExpanded);
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
    if (widget.debugLogging && kDebugMode) {
      print(
          '[_AnimatedActionButton] initState: action=${widget.action.label}, isExpanded=${widget.callbacks.isExpanded}, expandAnimation.value=${widget.expandAnimation.value}');
    }
  }

  @override
  void didUpdateWidget(_AnimatedActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isNowVisible = _isActionVisible();

    // Check if checkbox value changed (for AnimatedContainer color animation in collapsed state)
    final checkboxValueChanged = oldWidget.action is CheckboxActionButton &&
        widget.action is CheckboxActionButton &&
        (oldWidget.action as CheckboxActionButton).value !=
            (widget.action as CheckboxActionButton).value;

    if (_wasVisible != isNowVisible ||
        oldWidget.action.visibilityState != widget.action.visibilityState ||
        oldWidget.callbacks.isExpanded != widget.callbacks.isExpanded ||
        checkboxValueChanged) {
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

    // Force rebuild if checkbox value changed (even if visibility didn't change)
    // This ensures AnimatedContainer in buildCompactProminentButton sees the color change and animates
    if (checkboxValueChanged) {
      setState(() {});
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
    // For checkbox actions, we need to rebuild when the value changes
    // Create a ValueNotifier that tracks checkbox value changes
    final checkboxValueNotifier = widget.action is CheckboxActionButton
        ? ValueNotifier((widget.action as CheckboxActionButton).value)
        : null;

    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.expandAnimation,
        _fadeAnimation,
        if (checkboxValueNotifier != null) checkboxValueNotifier,
      ]),
      builder: (context, child) {
        // Update checkbox value notifier if it changed
        if (checkboxValueNotifier != null &&
            widget.action is CheckboxActionButton) {
          final currentValue = (widget.action as CheckboxActionButton).value;
          if (checkboxValueNotifier.value != currentValue) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              checkboxValueNotifier.value = currentValue;
            });
          }
        }
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
        if (shouldLog && widget.debugLogging && kDebugMode) {
          _lastLoggedValue = animValue;
          print(
              '[_AnimatedActionButton] build: action=${widget.action.label}, expandAnimation.value=$animValue, collapseProgress=$collapseProgress, easedProgress=$easedProgress');
        }

        // Prevent hit testing when fully hidden to avoid hit test errors
        final isFullyHidden = _fadeAnimation.value == 0.0;

        // Build the button content here (not cached) so it rebuilds when action properties change
        // This is critical for AnimatedContainer to animate checkbox state changes
        final buttonContent = widget.spacing == 0
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
              );

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
                  child: buttonContent,
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
                child: buttonContent,
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
    this.debugLogging = false,
    super.key,
  });

  final ActionButtonData action;
  final Widget Function(BuildContext context, ActionButtonData action)
      prominentActionBuilder;
  final Animation<double> expandAnimation;
  final base.ExpandableCallbacks callbacks;
  final GlobalKey toolbarKey;
  final double bottomPadding;
  final bool debugLogging;

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
    return widget.action.isVisibleWhen(widget.callbacks.isExpanded);
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

    if (widget.debugLogging && kDebugMode) {
      print(
          '[_AnimatedProminentAction] initState: action=${widget.action.label}, _wasVisible=$_wasVisible, visibilityState=${widget.action.visibilityState}, isExpanded=${widget.callbacks.isExpanded}');
    }

    // Always start at 0.0, then animate to target state after first frame
    // This ensures newly created visible widgets animate in smoothly
    _visibilityController.value = 0.0;

    // Animate to target state after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (widget.debugLogging && kDebugMode) {
          print(
              '[_AnimatedProminentAction] postFrameCallback: action=${widget.action.label}, _wasVisible=$_wasVisible, mounted=$mounted');
        }
        if (_wasVisible) {
          if (widget.debugLogging && kDebugMode) {
            print(
                '[_AnimatedProminentAction] postFrameCallback: calling forward() for ${widget.action.label}');
          }
          _visibilityController.forward();
        }
      }
    });
  }

  @override
  void didUpdateWidget(_AnimatedProminentAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isNowVisible = _isActionVisible();
    final visibilityChanged = _wasVisible != isNowVisible ||
        oldWidget.action.visibilityState != widget.action.visibilityState ||
        oldWidget.callbacks.isExpanded != widget.callbacks.isExpanded;

    if (widget.debugLogging && kDebugMode) {
      print(
          '[_AnimatedProminentAction] didUpdateWidget: action=${widget.action.label}, oldVisibilityState=${oldWidget.action.visibilityState}, newVisibilityState=${widget.action.visibilityState}, oldWasVisible=$_wasVisible, isNowVisible=$isNowVisible, visibilityChanged=$visibilityChanged, controllerValue=${_visibilityController.value}');
    }

    if (visibilityChanged) {
      // Remove old listener if exists
      if (_statusListener != null) {
        _visibilityController.removeStatusListener(_statusListener!);
        _statusListener = null;
      }

      // Stop any ongoing animation and ensure controller is in correct state
      if (_visibilityController.isAnimating) {
        _visibilityController.stop();
      }

      // Only animate if transitioning from opposite state
      // Don't animate if already at target state (prevents unnecessary animations for buttons that stay visible/hidden)
      if (isNowVisible) {
        if (widget.debugLogging && kDebugMode) {
          print(
              '[_AnimatedProminentAction] didUpdateWidget: calling forward() for ${widget.action.label}, currentValue=${_visibilityController.value}, wasVisible=$_wasVisible');
        }
        // Only animate if we're transitioning from hidden to visible
        // If already visible (value >= 1.0), skip animation
        if (_visibilityController.value < 1.0) {
          _visibilityController.forward();
        } else {
          if (widget.debugLogging && kDebugMode) {
            print(
                '[_AnimatedProminentAction] didUpdateWidget: skipping forward() for ${widget.action.label} - already at 1.0');
          }
        }
      } else {
        if (widget.debugLogging && kDebugMode) {
          print(
              '[_AnimatedProminentAction] didUpdateWidget: calling reverse() for ${widget.action.label}, currentValue=${_visibilityController.value}, wasVisible=$_wasVisible');
        }
        // Only animate if we're transitioning from visible to hidden
        // If already hidden (value <= 0.0), skip animation
        if (_visibilityController.value > 0.0) {
          _visibilityController.reverse();
        } else {
          if (widget.debugLogging && kDebugMode) {
            print(
                '[_AnimatedProminentAction] didUpdateWidget: skipping reverse() for ${widget.action.label} - already at 0.0');
          }
        }
      }
      _wasVisible = isNowVisible;

      // Trigger size recalculation after visibility animation completes
      _statusListener = (status) {
        if (widget.debugLogging && kDebugMode) {
          print(
              '[_AnimatedProminentAction] animationStatusListener: action=${widget.action.label}, status=$status');
        }
        if (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed) {
          _visibilityController.removeStatusListener(_statusListener!);
          _statusListener = null;
          // Wait for animation to fully complete and layout to update
          // Animation completed - widget will handle position updates automatically
        }
      };
      _visibilityController.addStatusListener(_statusListener!);
    } else {
      if (widget.debugLogging && kDebugMode) {
        print(
            '[_AnimatedProminentAction] didUpdateWidget: visibility NOT changed for ${widget.action.label}, skipping animation');
      }
    }
  }

  @override
  void dispose() {
    if (widget.debugLogging && kDebugMode) {
      print(
          '[_AnimatedProminentAction] dispose: action=${widget.action.label}, controllerValue=${_visibilityController.value}, _wasVisible=$_wasVisible');
    }
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

    // Use expandable builder if action has expandable options, otherwise use regular builder
    final Widget actionWidget;
    final isExpandable = widget.action is ExpandableActionButton;
    if (widget.debugLogging && kDebugMode) {
      print(
          '[_AnimatedProminentAction] build: action=${widget.action.label}, fadeAnimationValue=${_fadeAnimation.value}, controllerValue=${_visibilityController.value}, isFullyHidden=$isFullyHidden, _wasVisible=$_wasVisible, isExpanded=${widget.callbacks.isExpanded}');
    }
    if (isExpandable) {
      if (widget.debugLogging && kDebugMode) {
        print(
            '[FloatingActionToolbarContent] Using expandable card builder for: ${widget.action.label}');
      }
      actionWidget = buildExpandableProminentActionCard(
        context,
        widget.action,
        onOptionSelected: () {
          // Optionally collapse toolbar after option selection
          // widget.callbacks.collapse();
        },
      );
    } else {
      actionWidget = widget.prominentActionBuilder(context, widget.action);
    }

    // Padding is inside SizeTransition so it collapses with the widget
    // Use AnimatedBuilder to make padding reactive to animation changes
    final animatedWidget = SizeTransition(
      sizeFactor: _fadeAnimation,
      axis: Axis.vertical,
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          // Only apply bottom padding when widget is visible (sizeFactor > 0)
          final effectiveBottomPadding =
              _fadeAnimation.value > 0.01 ? widget.bottomPadding : 0.0;
          return Padding(
            padding: EdgeInsets.only(bottom: effectiveBottomPadding),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SizedBox(
                width: double.infinity,
                child: actionWidget,
              ),
            ),
          );
        },
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
