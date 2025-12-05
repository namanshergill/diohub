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
      position, // FloatingToolbarPosition from floating_action_toolbar.dart
  required VoidCallback? onCollapseRequested,
  required Widget Function(BuildContext, ActionButtonData)?
      prominentActionBuilder,
  required Animation<double> expandAnimation,
  required GlobalKey toolbarKey,
}) {
  final regularActions =
      actions.where((a) => !(prominentActions ?? []).contains(a)).toList();

  final enabledActions =
      regularActions.where((a) => a.enabled == true).toList();
  final disabledActions =
      regularActions.where((a) => a.enabled != true).toList();

  final visibleCount = callbacks.isExpanded
      ? (expandedVisibleCount ?? regularActions.length)
      : defaultVisibleCount;

  final visibleEnabledActions = enabledActions.take(visibleCount).toList();

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
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
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
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                        right: spacing),
                                                    child:
                                                        buildCompactIconButton(
                                                      context,
                                                      action,
                                                      callbacks,
                                                      onCollapseRequested,
                                                    ),
                                                  ),
                                                  if (index <
                                                          visibleEnabledActions
                                                                  .length -
                                                              1 ||
                                                      disabledActions
                                                          .isNotEmpty ||
                                                      (prominentActions !=
                                                              null &&
                                                          prominentActions
                                                              .isNotEmpty))
                                                    Container(
                                                      margin: EdgeInsets.only(
                                                          right: spacing),
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
                                            ...disabledActions
                                                .asMap()
                                                .entries
                                                .map((entry) {
                                              final index = entry.key;
                                              final action = entry.value;
                                              return Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                        right: spacing),
                                                    child:
                                                        buildCompactIconButton(
                                                      context,
                                                      action,
                                                      callbacks,
                                                      onCollapseRequested,
                                                    ),
                                                  ),
                                                  if (index <
                                                          disabledActions
                                                                  .length -
                                                              1 ||
                                                      (prominentActions !=
                                                              null &&
                                                          prominentActions
                                                              .isNotEmpty))
                                                    Container(
                                                      margin: EdgeInsets.only(
                                                          right: spacing),
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
                                            // Prominent actions in collapsed state (horizontal with text) - on the right
                                            if (prominentActions != null &&
                                                prominentActions.isNotEmpty)
                                              ...prominentActions.map((action) {
                                                return Padding(
                                                  padding: EdgeInsets.only(
                                                      right: spacing),
                                                  child:
                                                      buildCompactProminentButton(
                                                    context,
                                                    action,
                                                    callbacks,
                                                    onCollapseRequested,
                                                  ),
                                                );
                                              }),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                SizeTransition(
                                  sizeFactor: expandAnimation,
                                  axisAlignment: -1.0,
                                  child: (callbacks.isExpanded &&
                                          expandAnimation.value > 0.01)
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
                                                          0 ||
                                                      expandAnimation.value <=
                                                          0.01) {
                                                    // Return empty container if constraints are invalid or animation is too small
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
                                                    ...enabledActions,
                                                    ...disabledActions,
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
                                                      final actionIndex = index <
                                                              enabledActions
                                                                  .length
                                                          ? index
                                                          : enabledActions
                                                                  .length +
                                                              (index -
                                                                  enabledActions
                                                                      .length);

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
            color:
                Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
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
                  .withOpacity(0.7),
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

  final staggerDelay = index != null ? (index * 0.12).clamp(0.0, 0.6) : 0.0;
  final staggerDuration = 0.25;

  return AnimatedBuilder(
    animation: expandAnimation,
    builder: (context, child) {
      final tileProgress = expandAnimation.value < staggerDelay
          ? 0.0
          : ((expandAnimation.value - staggerDelay) / staggerDuration)
              .clamp(0.0, 1.0);

      final easedProgress = Curves.easeOutCubic.transform(tileProgress);

      final isExpandingFromTop = isNearTop;

      final slideOffset = isExpandingFromTop
          ? Offset(0, (1 - easedProgress) * 25)
          : Offset(0, -(1 - easedProgress) * 25);

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

// FloatingToolbarPosition enum imported from floating_action_toolbar.dart
