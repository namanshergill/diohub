import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/misc/highlighted_container.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

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
  VoidCallback? onCollapse,
}) {
  Color iconColor;
  Color textColor;
  Color badgeColor;
  Color badgeTextColor;

  if (!action.enabled) {
    iconColor = context.colorScheme.onSurfaceVariant.withOpacity(0.3);
    textColor = context.colorScheme.onSurfaceVariant.withOpacity(0.4);
    badgeColor = Colors.transparent;
    badgeTextColor = context.colorScheme.onSurfaceVariant.withOpacity(0.4);
  } else if (action.isDestructive) {
    iconColor = context.colorScheme.error;
    textColor = context.colorScheme.error;
    badgeColor = context.colorScheme.error;
    badgeTextColor = Colors.white;
  } else if (action.isPositive) {
    iconColor = Colors.green.shade400;
    textColor = Colors.green.shade300;
    badgeColor = Colors.green.shade500;
    badgeTextColor = Colors.white;
  } else {
    // More vibrant colors - use primary color for icons
    iconColor = action.iconColor ?? context.colorScheme.primary;
    textColor = context.colorScheme.onSurface.withOpacity(0.9);
    badgeColor = context.colorScheme.primary;
    badgeTextColor = Colors.white;
  }

  // Extract badge text from trailing widget
  String? badgeText;
  if (action.trailing != null) {
    if (action.trailing is Text) {
      badgeText = (action.trailing as Text).data;
    } else {
      badgeText = null;
    }
  }

  return Material(
    color: Colors.transparent,
    child: AbsorbPointer(
      absorbing: !action.enabled,
      child: InkWell(
        onTap: action.enabled
            ? () {
                action.onTap?.call();
                onCollapse?.call();
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
                      color: iconColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      action.icon,
                      size: iconSize,
                      color: iconColor,
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
                          color: badgeColor,
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
                              color: badgeTextColor,
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
                  color: textColor,
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
Widget buildProminentActionCard(
  BuildContext context,
  ActionButtonData action, {
  double iconSize = 20,
  double borderRadius = 14,
  EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
}) {
  Color iconColor;
  Color textColor;
  Color backgroundColor;
  Color badgeColor;
  Color badgeTextColor;

  if (!action.enabled) {
    backgroundColor =
        context.colorScheme.surfaceContainerHighest.withOpacity(0.2);
    iconColor = context.colorScheme.onSurfaceVariant.withOpacity(0.3);
    textColor = context.colorScheme.onSurfaceVariant.withOpacity(0.4);
    badgeColor = Colors.transparent;
    badgeTextColor = context.colorScheme.onSurfaceVariant.withOpacity(0.4);
  } else if (action.isDestructive) {
    backgroundColor = context.colorScheme.errorContainer.withOpacity(0.2);
    iconColor = context.colorScheme.error;
    textColor = context.colorScheme.error;
    badgeColor = context.colorScheme.error;
    badgeTextColor = Colors.white;
  } else if (action.isPositive) {
    backgroundColor = Colors.green.withOpacity(0.15);
    iconColor = Colors.green.shade600;
    textColor = Colors.green.shade700;
    badgeColor = Colors.green.shade600;
    badgeTextColor = Colors.white;
  } else {
    // Prominent actions get a subtle background
    backgroundColor =
        context.colorScheme.surfaceContainerHighest.withOpacity(0.25);
    iconColor = action.iconColor ?? context.colorScheme.primary;
    textColor = context.colorScheme.onSurface;
    badgeColor = context.colorScheme.primary;
    badgeTextColor = Colors.white;
  }

  // Extract badge text from trailing widget
  String? badgeText;
  if (action.trailing != null) {
    if (action.trailing is Text) {
      badgeText = (action.trailing as Text).data;
    } else {
      badgeText = null;
    }
  }

  return Material(
    color: Colors.transparent,
    child: AbsorbPointer(
      absorbing: !action.enabled,
      child: InkWell(
        onTap: action.enabled ? action.onTap : null,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: context.colorScheme.outline.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    action.icon,
                    size: iconSize,
                    color: iconColor,
                  ),
                  // Badge overlay
                  if (badgeText != null && badgeText.isNotEmpty)
                    Positioned(
                      right: -6,
                      top: -5,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: badgeColor,
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
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: badgeTextColor,
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
              // Label
              Flexible(
                child: Text(
                  action.label,
                  style: context.textTheme.bodyMedium?.copyWith(
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
  Color backgroundColor;
  Color iconColor;
  Color textColor;

  if (!action.enabled) {
    backgroundColor =
        context.colorScheme.surfaceContainerHighest.withOpacity(0.3);
    iconColor = context.colorScheme.onSurfaceVariant.withOpacity(0.3);
    textColor = context.colorScheme.onSurfaceVariant.withOpacity(0.3);
  } else if (action.isDestructive) {
    backgroundColor = context.colorScheme.errorContainer;
    iconColor = context.colorScheme.error;
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
          onTap: action.enabled ? action.onTap : null,
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
  Color backgroundColor;
  Color iconColor;
  Color textColor;

  if (!action.enabled) {
    backgroundColor =
        context.colorScheme.surfaceContainerHighest.withOpacity(0.3);
    iconColor = context.colorScheme.onSurfaceVariant.withOpacity(0.3);
    textColor = context.colorScheme.onSurfaceVariant.withOpacity(0.3);
  } else if (action.isDestructive) {
    backgroundColor = context.colorScheme.errorContainer;
    iconColor = context.colorScheme.error;
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
          onTap: action.enabled ? action.onTap : null,
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
