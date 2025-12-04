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
  final hiddenActions = enabledActions.skip(visibleCount).toList();

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
                            final isNearTop =
                                position.toString().contains('top');

                            final draggableIndicator =
                                buildDraggableIndicator(context);
                            final expandCollapseButton = Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: buildExpandCollapseButton(
                                context,
                                callbacks,
                                position,
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
                                                          .isNotEmpty)
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
                                                      disabledActions.length -
                                                          1)
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
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                SizeTransition(
                                  sizeFactor: expandAnimation,
                                  axisAlignment: -1.0,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      ...enabledActions
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        final index = entry.key;
                                        final action = entry.value;
                                        return Padding(
                                          padding: EdgeInsets.only(
                                            bottom: index <
                                                        enabledActions.length -
                                                            1 ||
                                                    (index ==
                                                            enabledActions
                                                                    .length -
                                                                1 &&
                                                        disabledActions
                                                            .isNotEmpty)
                                                ? 8
                                                : 0,
                                          ),
                                          child: buildExpandedActionWithLabel(
                                            context,
                                            action,
                                            index,
                                            callbacks,
                                            onCollapseRequested,
                                            expandAnimation,
                                            position,
                                          ),
                                        );
                                      }),
                                      ...disabledActions
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        final index = entry.key;
                                        final action = entry.value;
                                        return Padding(
                                          padding: EdgeInsets.only(
                                            bottom: index <
                                                    disabledActions.length - 1
                                                ? 8
                                                : 0,
                                          ),
                                          child: buildExpandedActionWithLabel(
                                            context,
                                            action,
                                            enabledActions.length + index,
                                            callbacks,
                                            onCollapseRequested,
                                            expandAnimation,
                                            position,
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
                      if (prominentActions != null &&
                          prominentActions.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(
                            top: (callbacks.isExpanded &&
                                        hiddenActions.isNotEmpty) ||
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
                                        child: (prominentActionBuilder ??
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
  dynamic position, // FloatingToolbarPosition from floating_action_toolbar.dart
) {
  final isNearTop = position.toString().contains('top');

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
  dynamic position, // FloatingToolbarPosition from floating_action_toolbar.dart
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

      final isExpandingFromTop = position.toString().contains('top');

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
                    size: 18,
                    color: iconColor,
                  ),
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
    ),
  );
}

// FloatingToolbarPosition enum imported from floating_action_toolbar.dart

