import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/misc/highlighted_container.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

// Re-export ActionButtonColors for backward compatibility
export 'package:diohub/common/misc/collapsible_action_buttons.dart'
    show ActionButtonColors;

/// Calculates colors for action buttons based on their state and type
/// This centralizes the color logic used across all action button builders
///
/// This is a convenience wrapper around [ActionButtonData.getColors]
ActionButtonColors calculateActionButtonColors(
  BuildContext context,
  ActionButtonData action, {
  bool forProminentButton = false,
  Color? seedColor,
}) {
  return action.getColors(
    context,
    forProminentButton: forProminentButton,
    seedColor: seedColor,
  );
}

// Generic padding constants for prominent action buttons
// These ensure consistent sizing across MajorActionButton, ExpandableActionButton, and CheckboxActionButton
// This padding applies ONLY to the buttons themselves, not to the expanded widget content
const EdgeInsets _kProminentActionButtonPadding =
    EdgeInsets.symmetric(horizontal: 12, vertical: 8);

/// Formats size in KB to human-readable format (KB, MB, GB)
String formatSize(int? sizeInKB) {
  if (sizeInKB == null) return '';
  if (sizeInKB < 1024) {
    return '$sizeInKB KB';
  } else if (sizeInKB < 1024 * 1024) {
    return '${(sizeInKB / 1024).toStringAsFixed(1)} MB';
  } else {
    return '${(sizeInKB / (1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Helper function to build a trailing widget for action button showing count
Widget buildActionButtonTrailingCount(BuildContext context, int count) {
  return Text(
    count.toString(),
    style: context.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.bold,
    ),
  );
}

/// Helper function to build a modern, sleek count badge for action buttons
/// Uses a subtle pill-shaped design with good contrast
Widget buildModernCountBadge(BuildContext context, int count) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: context.colorScheme.surfaceContainerHighest.withOpacity(0.8),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: context.colorScheme.outline.withOpacity(0.1),
        width: 0.5,
      ),
    ),
    child: Text(
      count.toString(),
      style: context.textTheme.labelSmall?.copyWith(
        color: context.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
        fontSize: 11,
        letterSpacing: 0.2,
      ),
    ),
  );
}

/// Helper function to build a trailing widget for action button showing size
Widget buildActionButtonTrailingSize(BuildContext context, int sizeInKB) {
  return Text(
    formatSize(sizeInKB),
    style: context.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.bold,
    ),
  );
}

/// Builds a standard action card widget matching iOS liquid glass pill-button style.
///
/// Design inspired by iOS navigation bars:
/// - Vertical pill-shaped button (icon above label)
/// - Translucent background with subtle border
/// - Badge as circular overlay on icon
/// - Clean, compact appearance
Widget buildStandardActionCard(
  BuildContext context,
  ActionButtonData action, {
  double iconSize = 20,
  double borderRadius = 14,
  EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
}) {
  final colors = calculateActionButtonColors(context, action);

  // Standard card uses primary for icon, slightly muted text
  final iconColor =
      action.enabled && !action.isDestructive && !action.isPositive
          ? (action.iconColor ?? context.colorScheme.primary)
          : colors.iconColor;
  final textColor =
      action.enabled && !action.isDestructive && !action.isPositive
          ? context.colorScheme.onSurface.withOpacity(0.9)
          : colors.textColor;

  // Special handling for positive actions in standard cards
  final effectiveIconColor =
      action.isPositive ? Colors.green.shade400 : iconColor;
  final effectiveTextColor =
      action.isPositive ? Colors.green.shade300 : textColor;

  // Extract badge text from trailing widget
  final badgeText = action.badgeText;

  return Material(
    color: Colors.transparent,
    child: AbsorbPointer(
      absorbing: !action.enabled,
      child: InkWell(
        onTap: action.enabled
            ? switch (action) {
                MinorActionButton(:final onTap) => onTap,
                CheckboxActionButton(:final onChanged, :final value) => () {
                    print(
                        '[ActionCardBuilder] Checkbox tapped! current value: $value, onChanged is null: ${onChanged == null}');
                    onChanged?.call(!value);
                    print(
                        '[ActionCardBuilder] Checkbox onChanged called with: ${!value}');
                  },
                _ => null,
              }
            : null,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with badge overlay
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: effectiveIconColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      action.displayIcon,
                      size: iconSize,
                      color: effectiveIconColor,
                    ),
                  ),
                  // Badge overlay on icon (top-right)
                  if (badgeText != null && badgeText.isNotEmpty)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.badgeColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Center(
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: colors.badgeTextColor,
                              fontSize: 10,
                              height: 1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              // Label below icon
              Text(
                action.label,
                style: context.textTheme.labelSmall?.copyWith(
                  color: effectiveTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  letterSpacing: -0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Builds a prominent/expanded action card widget for important actions.
///
/// Used for actions like "Comment" on issue screens - larger, more prominent design.
/// Features:
/// - Horizontal layout (icon + label side by side)
/// - More prominent appearance
/// - Larger touch target
/// - Can span full width when in expanded vertical layout
///
/// Accepts MajorActionButton which has onTap field.
Widget buildProminentActionCard(
  BuildContext context,
  ActionButtonData action, {
  double iconSize = 20,
  double borderRadius = 14,
  EdgeInsets? padding,
  Color? seedColor,
}) {
  // Use generic padding constant if not specified
  final effectivePadding = padding ?? _kProminentActionButtonPadding;

  // Calculate colors using shared function
  final colors = calculateActionButtonColors(
    context,
    action,
    forProminentButton: true,
    seedColor: seedColor,
  );

  // Debug: Print checkbox state for AnimatedContainer animation
  if (action is CheckboxActionButton) {
    final isSelected = action.value;
    print(
        '[ActionCardBuilder] buildProminentActionCard: Checkbox ${action.label}, value=$isSelected');
    print(
        '  - Background: ${colors.backgroundColor} (hashCode: ${colors.backgroundColor.hashCode})');
    print(
        '  - IconColor: ${colors.iconColor} (hashCode: ${colors.iconColor.hashCode})');
    print(
        '  - TextColor: ${colors.textColor} (hashCode: ${colors.textColor.hashCode})');
    print('  - AnimatedContainer key: checkbox_${action.label}');
  }

  // Extract badge text from trailing widget or use trailing widget directly
  final badgeText = action.badgeText;
  final trailingWidget = action.trailing != null && action.trailing is! Text
      ? action.trailing
      : null;

  // Get onTap from MajorActionButton or CheckboxActionButton
  final VoidCallback? onTap = switch (action) {
    MajorActionButton(:final onTap) => onTap,
    CheckboxActionButton(:final onChanged, :final value) => () {
        print(
            '[ActionCardBuilder] Checkbox tapped (card)! current value: $value, onChanged is null: ${onChanged == null}');
        onChanged?.call(!value);
        print(
            '[ActionCardBuilder] Checkbox onChanged called (card) with: ${!value}');
      },
    _ => null,
  };

  return Material(
    color: Colors.transparent,
    child: AbsorbPointer(
      absorbing: !action.enabled,
      child: InkWell(
        onTap: action.enabled ? onTap : null,
        borderRadius: BorderRadius.circular(borderRadius),
        child: AnimatedContainer(
          key: ValueKey('checkbox_${action.label}'),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          width: double.infinity,
          padding: effectivePadding,
          onEnd: () {
            if (action is CheckboxActionButton) {
              print(
                  '[ActionCardBuilder] AnimatedContainer animation ended for ${action.label}');
            }
          },
          decoration: BoxDecoration(
            color: colors.backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: context.colorScheme.outline.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Icon
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  action.displayIcon,
                  key: ValueKey(action.displayIcon),
                  size: iconSize,
                  color: colors.iconColor,
                ),
              ),
              const SizedBox(width: 10),
              // Label and subtitle
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      style: context.textTheme.bodyMedium?.copyWith(
                            color: colors.textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            letterSpacing: -0.2,
                            height:
                                1.0, // Prevent extra line height from affecting Row height
                          ) ??
                          const TextStyle(),
                      child: Text(
                        action.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textHeightBehavior: const TextHeightBehavior(
                          applyHeightToFirstAscent: false,
                          applyHeightToLastDescent: false,
                        ),
                      ),
                    ),
                    if (action.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        action.subtitle!,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.textColor.withOpacity(0.7),
                          fontWeight: FontWeight.w400,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Badge or trailing widget (moved to the right side)
              if (trailingWidget != null) ...[
                const SizedBox(width: 8),
                trailingWidget,
              ] else if (badgeText != null && badgeText.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.badgeColor,
                    borderRadius: BorderRadius.circular(10),
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
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colors.badgeTextColor,
                        fontSize: 10,
                        height: 1,
                      ),
                      textAlign: TextAlign.center,
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

/// Builds an expandable prominent action card widget that can expand to show options.
///
/// When expanded, shows a list of options below the button.
/// Uses SizeExpandedSection for smooth expand/collapse animations.
///
/// Accepts ExpandableActionButton which has expandableWidgetBuilder field.
Widget buildExpandableProminentActionCard(
  BuildContext context,
  ActionButtonData action, {
  double iconSize = 16,
  double borderRadius = 14,
  EdgeInsets? padding,
  VoidCallback? onOptionSelected,
}) {
  // Use generic padding constant if not specified
  final effectivePadding = padding ?? _kProminentActionButtonPadding;
  return _ExpandableProminentActionCard(
    action: action,
    iconSize: iconSize,
    borderRadius: borderRadius,
    padding: effectivePadding,
    onOptionSelected: onOptionSelected,
  );
}

/// Internal stateful widget for expandable prominent action card
class _ExpandableProminentActionCard extends StatefulWidget {
  const _ExpandableProminentActionCard({
    required this.action,
    required this.iconSize,
    required this.borderRadius,
    required this.padding,
    this.onOptionSelected,
  });

  final ActionButtonData action;
  final double iconSize;
  final double borderRadius;
  final EdgeInsets padding;
  final VoidCallback? onOptionSelected;

  @override
  State<_ExpandableProminentActionCard> createState() =>
      _ExpandableProminentActionCardState();
}

class _ExpandableProminentActionCardState
    extends State<_ExpandableProminentActionCard> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    print(
        '[buildExpandableProminentActionCard] Toggling expanded state: ${!_isExpanded} for ${widget.action.label}');
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  // Public method to collapse the expandable widget
  void collapse() {
    if (_isExpanded) {
      _toggleExpanded();
    }
  }

  // Call this when an option is selected to collapse
  void _onOptionSelected() {
    if (_isExpanded) {
      collapse();
    }
    widget.onOptionSelected?.call();
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.action;
    final expandableWidgetBuilder = switch (action) {
      ExpandableActionButton(:final expandableWidgetBuilder) =>
        expandableWidgetBuilder,
      _ => throw ArgumentError(
          'buildExpandableProminentActionCard requires ExpandableActionButton'),
    };
    print(
        '[buildExpandableProminentActionCard] Building expandable button: ${action.label}, expandableWidgetBuilder is not null');

    // Calculate colors using shared function
    final colors = calculateActionButtonColors(
      context,
      action,
      forProminentButton: true,
    );

    // Use seedColor from action for expanded state styling
    final effectiveSeedColor = action.seedColor;

    // Extract badge text from trailing widget or use trailing widget directly
    String? badgeText;
    Widget? trailingWidget;
    if (action.trailing != null) {
      if (action.trailing is Text) {
        badgeText = (action.trailing as Text).data;
      } else {
        // Use trailing widget directly for custom designs
        trailingWidget = action.trailing;
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              print(
                  '[buildExpandableProminentActionCard] Button tapped: ${action.label}, enabled: ${action.enabled}');
              if (action.enabled != false) {
                _toggleExpanded();
              }
            },
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: double.infinity,
              padding: widget.padding,
              decoration: BoxDecoration(
                color: _isExpanded
                    ? (effectiveSeedColor ?? context.colorScheme.primary)
                        .withOpacity(0.15)
                    : colors.backgroundColor,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: _isExpanded
                      ? (effectiveSeedColor ?? context.colorScheme.primary)
                          .withOpacity(0.4)
                      : context.colorScheme.outline.withOpacity(0.1),
                  width: _isExpanded ? 1.5 : 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          action.icon,
                          size: widget.iconSize,
                          color: colors.iconColor,
                        ),
                        const SizedBox(width: 8),
                        // Label and subtitle
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                action.label,
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: colors.textColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (action.subtitle != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  action.subtitle!,
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: colors.textColor.withOpacity(0.7),
                                    fontWeight: FontWeight.w400,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Badge or trailing widget (moved to the right side, before expand indicator)
                        if (trailingWidget != null) ...[
                          const SizedBox(width: 8),
                          trailingWidget,
                        ] else if (badgeText != null &&
                            badgeText.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.badgeColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
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
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: colors.badgeTextColor,
                                  fontSize: 10,
                                  height: 1,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: widget.iconSize,
                    color: colors.iconColor.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Expanded options list
        Builder(
          builder: (context) {
            print(
                '[buildExpandableProminentActionCard] Rendering SizeExpandedSection, _isExpanded: $_isExpanded, expandableWidgetBuilder is not null');

            final screenHeight = MediaQuery.of(context).size.height;
            final maxHeight = screenHeight * 0.6;
            final screenWidth = MediaQuery.of(context).size.width;
            final maxWidth = screenWidth * 0.8;

            return AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.fastOutSlowIn,
              child: _isExpanded
                  ? ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: maxWidth,
                        maxHeight: maxHeight,
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: context.colorScheme.surfaceContainerHighest
                              .withOpacity(0.2),
                          borderRadius:
                              BorderRadius.circular(widget.borderRadius),
                          border: Border.all(
                            color: context.colorScheme.outline.withOpacity(0.1),
                            width: 0.5,
                          ),
                        ),
                        child: expandableWidgetBuilder(_onOptionSelected),
                      ),
                    )
                  : const SizedBox.shrink(),
            );
          },
        ),
      ],
    );
  }
}

/// Builds an action card widget specifically for appbar collapsible sections.
///
/// Uses the original buildStandardActionCard design with Material 3 styling.
/// Matches the original UI before toolbar changes.
Widget buildAppBarActionCard(
  BuildContext context,
  ActionButtonData action, {
  double iconSize = 18,
  double borderRadius = 12,
  EdgeInsets padding = const EdgeInsets.all(12),
}) {
  // Calculate base colors
  final colors = calculateActionButtonColors(context, action);

  // AppBar cards have some special styling
  Color backgroundColor;
  Color iconColor;
  Color textColor;

  if (!action.enabled) {
    backgroundColor =
        context.colorScheme.surfaceContainerHighest.withOpacity(0.3);
    iconColor = colors.iconColor;
    textColor = colors.textColor;
  } else if (action.isDestructive) {
    backgroundColor = context.colorScheme.errorContainer;
    iconColor = colors.iconColor;
    textColor = context.colorScheme.onErrorContainer;
  } else if (action.isPositive) {
    backgroundColor = Colors.green.withOpacity(0.12);
    iconColor = Colors.green.shade700;
    textColor = Colors.green.shade900;
  } else {
    // Use surfaceContainerHigh for a slightly darker, more visible background
    backgroundColor = context.colorScheme.surfaceContainerHigh;
    iconColor = action.iconColor ?? context.colorScheme.primary;
    textColor = context.colorScheme.onSurface;
  }

  // Subtle background tint based on action type for distinction
  Color? typeBackgroundColor;
  if (action.actionType != null) {
    switch (action.actionType!) {
      case ActionButtonActionType.tab:
        typeBackgroundColor = context.colorScheme.primary.withOpacity(0.08);
        break;
      case ActionButtonActionType.bottomSheet:
        typeBackgroundColor = context.colorScheme.secondary.withOpacity(0.08);
        break;
      case ActionButtonActionType.navigation:
        typeBackgroundColor = context.colorScheme.tertiary.withOpacity(0.08);
        break;
      case ActionButtonActionType.action:
        break;
    }
  }
  final finalBackgroundColor = typeBackgroundColor != null
      ? Color.alphaBlend(typeBackgroundColor, backgroundColor)
      : backgroundColor;

  return HighlightedContainer(
    highlightColor: iconColor,
    borderRadius: borderRadius,
    child: Material(
      color: finalBackgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      child: AbsorbPointer(
        absorbing: !action.enabled,
        child: InkWell(
          onTap: action.enabled
              ? switch (action) {
                  MinorActionButton(:final onTap) => onTap,
                  _ => null,
                }
              : null,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (action.leading != null) ...[
                      action.leading!,
                      const SizedBox(width: 8),
                    ],
                    Icon(
                      action.icon,
                      size: iconSize,
                      color: iconColor,
                    ),
                    const Spacer(),
                    if (action.trailing != null)
                      DefaultTextStyle(
                        style: context.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ) ??
                            TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                        child: action.trailing!,
                      )
                    else
                      // Reserve space for consistency when no trailing widget
                      SizedBox(
                        width: context.textTheme.titleSmall?.fontSize != null
                            ? (context.textTheme.titleSmall!.fontSize! * 2.2)
                            : 26,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  action.label,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Builds a compact action card widget (smaller, vertical layout).
///
/// Used for issue/pull action buttons that need to be more compact.
Widget buildCompactActionCard(
  BuildContext context,
  ActionButtonData action, {
  double iconSize = 18,
  double borderRadius = 10,
  EdgeInsets padding = const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
}) {
  // Calculate base colors
  final colors = calculateActionButtonColors(context, action);

  // Compact cards have some special styling
  Color backgroundColor;
  Color iconColor;
  Color textColor;

  if (!action.enabled) {
    backgroundColor =
        context.colorScheme.surfaceContainerHighest.withOpacity(0.3);
    iconColor = colors.iconColor;
    textColor = colors.textColor;
  } else if (action.isDestructive) {
    backgroundColor = context.colorScheme.errorContainer;
    iconColor = colors.iconColor;
    textColor = context.colorScheme.onErrorContainer;
  } else if (action.isPositive) {
    backgroundColor = Colors.green.withOpacity(0.12);
    iconColor = Colors.green.shade700;
    textColor = Colors.green.shade900;
  } else {
    // Use surfaceContainerHigh for a slightly darker, more visible background
    backgroundColor = context.colorScheme.surfaceContainerHigh;
    iconColor = action.iconColor ?? context.colorScheme.primary;
    textColor = context.colorScheme.onSurface;
  }

  // Subtle background tint based on action type for distinction
  Color? typeBackgroundColor;
  if (action.actionType != null) {
    switch (action.actionType!) {
      case ActionButtonActionType.tab:
        typeBackgroundColor = context.colorScheme.primary.withOpacity(0.08);
        break;
      case ActionButtonActionType.bottomSheet:
        typeBackgroundColor = context.colorScheme.secondary.withOpacity(0.08);
        break;
      case ActionButtonActionType.navigation:
        typeBackgroundColor = context.colorScheme.tertiary.withOpacity(0.08);
        break;
      case ActionButtonActionType.action:
        break;
    }
  }
  final finalBackgroundColor = typeBackgroundColor != null
      ? Color.alphaBlend(typeBackgroundColor, backgroundColor)
      : backgroundColor;

  return HighlightedContainer(
    highlightColor: iconColor,
    borderRadius: borderRadius,
    // elevation: 4,
    child: Material(
      color: finalBackgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      child: AbsorbPointer(
        absorbing: !action.enabled,
        child: InkWell(
          onTap: action.enabled
              ? switch (action) {
                  MinorActionButton(:final onTap) => onTap,
                  _ => null,
                }
              : null,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  action.icon,
                  size: iconSize,
                  color: iconColor,
                ),
                const SizedBox(height: 4),
                Text(
                  action.label,
                  style: context.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
