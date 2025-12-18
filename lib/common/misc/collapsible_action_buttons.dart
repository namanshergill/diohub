import 'package:diohub/common/misc/compact_expand_button.dart';
import 'package:flex_list/flex_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Color set for action buttons
class ActionButtonColors {
  const ActionButtonColors({
    required this.backgroundColor,
    required this.iconColor,
    required this.textColor,
    required this.badgeColor,
    required this.badgeTextColor,
  });

  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;
  final Color badgeColor;
  final Color badgeTextColor;
}

/// Configuration for determining how many action buttons should be visible
/// based on available width.
class ActionButtonsVisibilityConfig {
  const ActionButtonsVisibilityConfig({
    this.minPerRow = 3,
    this.maxPerRow = 4,
    this.defaultVisibleCount,
  });

  /// Minimum number of buttons per row
  final int minPerRow;

  /// Maximum number of buttons per row
  final int maxPerRow;

  /// Number of primary actions visible by default
  /// If null, uses width-based calculation to show buttonsPerRow number of actions
  final int? defaultVisibleCount;

  /// Default configuration: Uses width-based calculation
  static const ActionButtonsVisibilityConfig defaultConfig =
      ActionButtonsVisibilityConfig(
    minPerRow: 3,
    maxPerRow: 4,
    defaultVisibleCount: null,
  );

  /// Configuration with fixed visible count
  /// Uses default minPerRow (3) and maxPerRow (4)
  static ActionButtonsVisibilityConfig fixedCount({
    required int defaultVisibleCount,
  }) =>
      ActionButtonsVisibilityConfig(
        minPerRow: 3,
        maxPerRow: 4,
        defaultVisibleCount: defaultVisibleCount,
      );
}

/// Type of action that will be performed when an ActionButton is tapped
enum ActionButtonActionType {
  /// Opens a tab within the current screen
  tab,

  /// Opens a bottom sheet
  bottomSheet,

  /// Navigates to a new screen
  navigation,

  /// Performs an action (default)
  action,
}

/// Visibility state for action buttons in collapsed toolbar state
enum ActionButtonVisibilityState {
  /// Visible only in collapsed state
  /// These buttons are hidden when the toolbar is expanded
  collapsedOnly,

  /// Visible only in expanded state
  /// These buttons are hidden when the toolbar is collapsed
  expandedOnly,

  /// Visible in both collapsed and expanded states
  /// These buttons are always shown regardless of toolbar state
  both,

  /// Never visible in either state
  /// These buttons are hidden in both collapsed and expanded states
  none,
}

/// An option that can be displayed when an expandable button is expanded
class ExpandableOption {
  const ExpandableOption({
    required this.label,
    this.icon,
    required this.onTap,
    this.customWidget,
    this.enabled = true,
  });

  /// Label text for the option
  final String label;

  /// Optional icon for the option
  final IconData? icon;

  /// Callback when the option is tapped
  final VoidCallback onTap;

  /// Optional custom widget to display instead of standard label/icon
  final Widget? customWidget;

  /// Whether the option is enabled
  final bool enabled;
}

/// Base class for all action button types
///
/// Use sealed class for exhaustive pattern matching
sealed class ActionButtonData {
  const ActionButtonData({
    required this.icon,
    required this.label,
    this.subtitle,
    this.leading,
    this.trailing,
    this.iconColor,
    this.enabled = true,
    this.isDestructive = false,
    this.isPositive = false,
    this.actionType,
    this.visibilityState = ActionButtonVisibilityState.both,
    this.seedColor,
    this.category,
  });

  final IconData icon;
  final String label;

  /// Optional subtitle text to display below the label
  final String? subtitle;

  /// Optional widget to display on the leading side (left) of the card
  final Widget? leading;

  /// Optional widget to display on the trailing side (right) of the card
  final Widget? trailing;
  final Color? iconColor;
  final bool enabled;
  final bool isDestructive;
  final bool isPositive;

  /// Type of action this button performs (determines trailing icon if trailing is not provided)
  final ActionButtonActionType? actionType;

  /// Visibility state that determines when this button appears
  /// Controls visibility in both collapsed and expanded toolbar states
  final ActionButtonVisibilityState visibilityState;

  /// Optional seed color used to determine button colors (for prominent action cards)
  /// When provided, this color is used as the base for generating icon, text, and background colors
  final Color? seedColor;

  /// Optional category/section identifier for grouping actions
  /// Actions with the same category will be grouped together with dividers between groups
  final String? category;

  /// Gets the display icon for this action button
  /// For CheckboxActionButton, returns checked icon when value is true
  IconData get displayIcon {
    if (this is CheckboxActionButton && (this as CheckboxActionButton).value) {
      return Icons.check_box_rounded;
    }
    return icon;
  }

  /// Gets the badge text from the trailing widget if it's a Text widget
  /// Returns null if trailing is null or not a Text widget
  String? get badgeText {
    if (trailing != null && trailing is Text) {
      return (trailing as Text).data;
    }
    return null;
  }

  /// Checks if this is a selected checkbox action button
  bool get isSelectedCheckbox {
    return this is CheckboxActionButton && (this as CheckboxActionButton).value;
  }

  /// Checks if this action button should be visible in expanded state
  bool get isVisibleInExpanded {
    return visibilityState == ActionButtonVisibilityState.expandedOnly ||
        visibilityState == ActionButtonVisibilityState.both;
  }

  /// Checks if this action button should be visible in collapsed state
  bool get isVisibleInCollapsed {
    return visibilityState == ActionButtonVisibilityState.collapsedOnly ||
        visibilityState == ActionButtonVisibilityState.both;
  }

  /// Checks if this action button should be visible based on toolbar state
  ///
  /// [isExpanded] - whether the toolbar is currently expanded
  bool isVisibleWhen(bool isExpanded) {
    if (isExpanded) {
      return isVisibleInExpanded;
    } else {
      return isVisibleInCollapsed;
    }
  }

  /// Handles the tap action and returns whether the toolbar should collapse
  ///
  /// Returns `true` if the toolbar should collapse after this action,
  /// `false` if it should remain open (e.g., for toggle actions like checkboxes)
  bool handleTapAndShouldCollapse() {
    switch (this) {
      case MinorActionButton(:final onTap):
      case MajorActionButton(:final onTap):
        onTap?.call();
        return true; // Should collapse
      case CheckboxActionButton(:final onChanged, :final value):
        onChanged?.call(!value);
        return false; // Don't collapse for checkbox - it's a toggle
      case ExpandableActionButton():
        // Expandable buttons handle their own expansion
        return false;
    }
  }

  /// Gets the icon color for this action based on its state and type
  /// Used for simple icon buttons in collapsed toolbar
  Color getIconColor(BuildContext context) {
    if (!enabled) {
      return Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3);
    } else if (icon == Octicons.issue_opened) {
      return Colors.green.shade600;
    } else if (icon == Octicons.git_pull_request) {
      return Colors.purple.shade600;
    } else {
      return iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  /// Calculates colors for this action button based on its state and type
  /// Returns an ActionButtonColors object with all color values
  ActionButtonColors getColors(
    BuildContext context, {
    bool forProminentButton = false,
    Color? seedColor,
  }) {
    // Use seedColor from action if provided, otherwise use parameter
    final effectiveSeedColor = this.seedColor ?? seedColor;

    Color backgroundColor;
    Color iconColor;
    Color textColor;
    Color badgeColor;
    Color badgeTextColor;

    final colorScheme = Theme.of(context).colorScheme;

    if (!enabled) {
      final baseOpacity = forProminentButton ? 0.2 : 0.3;
      backgroundColor =
          colorScheme.surfaceContainerHighest.withOpacity(baseOpacity);
      iconColor = colorScheme.onSurfaceVariant.withOpacity(0.3);
      textColor = colorScheme.onSurfaceVariant
          .withOpacity(forProminentButton ? 0.4 : 0.3);
      badgeColor = Colors.transparent;
      badgeTextColor = colorScheme.onSurfaceVariant.withOpacity(0.4);
    } else if (isDestructive) {
      backgroundColor = colorScheme.errorContainer
          .withOpacity(forProminentButton ? 0.2 : 1.0);
      iconColor = colorScheme.error;
      textColor =
          forProminentButton ? colorScheme.error : colorScheme.onErrorContainer;
      badgeColor = colorScheme.error;
      badgeTextColor = Colors.white;
    } else if (isPositive) {
      backgroundColor =
          Colors.green.withOpacity(forProminentButton ? 0.15 : 0.12);
      iconColor =
          forProminentButton ? Colors.green.shade600 : Colors.green.shade700;
      textColor =
          forProminentButton ? Colors.green.shade700 : Colors.green.shade900;
      badgeColor =
          forProminentButton ? Colors.green.shade600 : Colors.green.shade500;
      badgeTextColor = Colors.white;
    } else if (isSelectedCheckbox) {
      // Highlight selected checkboxes with primary color
      backgroundColor = colorScheme.primaryContainer.withOpacity(0.3);
      iconColor = colorScheme.primary;
      textColor = forProminentButton
          ? colorScheme.onPrimaryContainer
          : colorScheme.primary;
      badgeColor = colorScheme.primary;
      badgeTextColor = Colors.white;
    } else if (effectiveSeedColor != null) {
      // Use seedColor to generate colors
      backgroundColor = effectiveSeedColor.withOpacity(0.15);
      iconColor = effectiveSeedColor;
      textColor = effectiveSeedColor;
      badgeColor = effectiveSeedColor;
      badgeTextColor = Colors.white;
    } else if (forProminentButton) {
      // Prominent actions get a subtle background
      backgroundColor = colorScheme.surfaceContainerHighest.withOpacity(0.25);
      iconColor = this.iconColor ?? colorScheme.primary;
      textColor = colorScheme.onSurface;
      badgeColor = colorScheme.primary;
      badgeTextColor = Colors.white;
    } else {
      // Standard actions
      backgroundColor = colorScheme.surfaceContainerHigh;
      iconColor = this.iconColor ?? colorScheme.primary;
      textColor = colorScheme.onSurface;
      badgeColor = colorScheme.primary;
      badgeTextColor = Colors.white;
    }

    return ActionButtonColors(
      backgroundColor: backgroundColor,
      iconColor: iconColor,
      textColor: textColor,
      badgeColor: badgeColor,
      badgeTextColor: badgeTextColor,
    );
  }
}

/// Small action button (replaces the previous ActionButtonData for minor actions)
class MinorActionButton extends ActionButtonData {
  const MinorActionButton({
    required super.icon,
    required super.label,
    required this.onTap,
    super.subtitle,
    super.leading,
    super.trailing,
    super.iconColor,
    super.enabled,
    super.isDestructive,
    super.isPositive,
    super.actionType,
    super.visibilityState,
    super.seedColor,
    super.category,
  });

  final VoidCallback? onTap;

  /// Creates a copy of this MinorActionButton with updated properties
  MinorActionButton copyWith({
    IconData? icon,
    String? label,
    VoidCallback? onTap,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
    Color? iconColor,
    bool? enabled,
    bool? isDestructive,
    bool? isPositive,
    ActionButtonActionType? actionType,
    ActionButtonVisibilityState? visibilityState,
    Color? seedColor,
    String? category,
  }) {
    return MinorActionButton(
      icon: icon ?? this.icon,
      label: label ?? this.label,
      onTap: onTap ?? this.onTap,
      subtitle: subtitle ?? this.subtitle,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      iconColor: iconColor ?? this.iconColor,
      enabled: enabled ?? this.enabled,
      isDestructive: isDestructive ?? this.isDestructive,
      isPositive: isPositive ?? this.isPositive,
      actionType: actionType ?? this.actionType,
      visibilityState: visibilityState ?? this.visibilityState,
      seedColor: seedColor ?? this.seedColor,
      category: category ?? this.category,
    );
  }
}

/// Major action button for prominent actions (has onTap field)
class MajorActionButton extends ActionButtonData {
  const MajorActionButton({
    required super.icon,
    required super.label,
    required this.onTap,
    super.subtitle,
    super.leading,
    super.trailing,
    super.iconColor,
    super.enabled,
    super.isDestructive,
    super.isPositive,
    super.actionType,
    super.visibilityState,
    super.seedColor,
    super.category,
  });

  final VoidCallback? onTap;

  /// Creates a copy of this MajorActionButton with updated properties
  MajorActionButton copyWith({
    IconData? icon,
    String? label,
    VoidCallback? onTap,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
    Color? iconColor,
    bool? enabled,
    bool? isDestructive,
    bool? isPositive,
    ActionButtonActionType? actionType,
    ActionButtonVisibilityState? visibilityState,
    Color? seedColor,
    String? category,
  }) {
    return MajorActionButton(
      icon: icon ?? this.icon,
      label: label ?? this.label,
      onTap: onTap ?? this.onTap,
      subtitle: subtitle ?? this.subtitle,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      iconColor: iconColor ?? this.iconColor,
      enabled: enabled ?? this.enabled,
      isDestructive: isDestructive ?? this.isDestructive,
      isPositive: isPositive ?? this.isPositive,
      actionType: actionType ?? this.actionType,
      visibilityState: visibilityState ?? this.visibilityState,
      seedColor: seedColor ?? this.seedColor,
      category: category ?? this.category,
    );
  }
}

/// Expandable action button that can expand to show additional content
class ExpandableActionButton extends ActionButtonData {
  const ExpandableActionButton({
    required super.icon,
    required super.label,
    required this.expandableWidgetBuilder,
    super.subtitle,
    super.leading,
    super.trailing,
    super.iconColor,
    super.enabled,
    super.isDestructive,
    super.isPositive,
    super.actionType,
    super.visibilityState,
    super.seedColor,
    super.category,
  });

  /// Builder function to create widget to show when this button is expanded
  /// The builder receives a collapse callback that can be called to collapse the expandable widget
  final Widget Function(VoidCallback onCollapse) expandableWidgetBuilder;

  /// Whether this button is expandable (always true for ExpandableActionButton)
  bool get isExpandable => true;

  /// Creates a copy` of this ExpandableActionButton with updated properties
  ExpandableActionButton copyWith({
    IconData? icon,
    String? label,
    Widget Function(VoidCallback onCollapse)? expandableWidgetBuilder,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
    Color? iconColor,
    bool? enabled,
    bool? isDestructive,
    bool? isPositive,
    ActionButtonActionType? actionType,
    ActionButtonVisibilityState? visibilityState,
    Color? seedColor,
    String? category,
  }) {
    return ExpandableActionButton(
      icon: icon ?? this.icon,
      label: label ?? this.label,
      expandableWidgetBuilder:
          expandableWidgetBuilder ?? this.expandableWidgetBuilder,
      subtitle: subtitle ?? this.subtitle,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      iconColor: iconColor ?? this.iconColor,
      enabled: enabled ?? this.enabled,
      isDestructive: isDestructive ?? this.isDestructive,
      isPositive: isPositive ?? this.isPositive,
      actionType: actionType ?? this.actionType,
      visibilityState: visibilityState ?? this.visibilityState,
      seedColor: seedColor ?? this.seedColor,
      category: category ?? this.category,
    );
  }
}

/// Checkbox action button for toggleable actions
class CheckboxActionButton extends ActionButtonData {
  const CheckboxActionButton({
    required super.icon,
    required super.label,
    required this.value,
    required this.onChanged,
    super.subtitle,
    super.leading,
    super.trailing,
    super.iconColor,
    super.enabled,
    super.isDestructive,
    super.isPositive,
    super.actionType,
    super.visibilityState,
    super.seedColor,
    super.category,
  });

  /// Current checkbox value
  final bool value;

  /// Callback when checkbox value changes
  final ValueChanged<bool>? onChanged;

  /// Creates a copy of this CheckboxActionButton with updated properties
  CheckboxActionButton copyWith({
    IconData? icon,
    String? label,
    bool? value,
    ValueChanged<bool>? onChanged,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
    Color? iconColor,
    bool? enabled,
    bool? isDestructive,
    bool? isPositive,
    ActionButtonActionType? actionType,
    ActionButtonVisibilityState? visibilityState,
    Color? seedColor,
    String? category,
  }) {
    return CheckboxActionButton(
      icon: icon ?? this.icon,
      label: label ?? this.label,
      value: value ?? this.value,
      onChanged: onChanged ?? this.onChanged,
      subtitle: subtitle ?? this.subtitle,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      iconColor: iconColor ?? this.iconColor,
      enabled: enabled ?? this.enabled,
      isDestructive: isDestructive ?? this.isDestructive,
      isPositive: isPositive ?? this.isPositive,
      actionType: actionType ?? this.actionType,
      visibilityState: visibilityState ?? this.visibilityState,
      seedColor: seedColor ?? this.seedColor,
      category: category ?? this.category,
    );
  }
}

/// A reusable widget that displays action buttons with expand/collapse functionality.
///
/// Automatically handles the expand/collapse state and animation.
/// Uses a responsive grid layout based on available width.
/// Optionally shows an expand button below the buttons.
class CollapsibleActionButtons extends StatefulWidget {
  const CollapsibleActionButtons({
    required this.primaryActions,
    required this.secondaryActions,
    required this.actionCardBuilder,
    this.visibilityConfig = ActionButtonsVisibilityConfig.defaultConfig,
    this.showExpandButton = true,
    this.horizontalSpacing = 8,
    this.verticalSpacing = 8,
    this.fixedHeight,
    this.onExpandChanged,
    super.key,
  });

  /// Primary actions that are always visible (or visible based on width config)
  final List<ActionButtonData> primaryActions;

  /// Secondary actions that are shown when expanded
  final List<ActionButtonData> secondaryActions;

  /// Builder function to create individual action cards
  final Widget Function(BuildContext context, ActionButtonData action)
      actionCardBuilder;

  /// Configuration for determining visible buttons based on width
  final ActionButtonsVisibilityConfig visibilityConfig;

  /// Whether to show the expand button below the buttons
  final bool showExpandButton;

  /// Horizontal spacing between cards
  final double horizontalSpacing;

  /// Vertical spacing between cards
  final double verticalSpacing;

  /// Fixed height for all cards (optional)
  final double? fixedHeight;

  /// Callback when expand state changes (useful for triggering app bar animations)
  final void Function(bool isExpanded)? onExpandChanged;

  @override
  State<CollapsibleActionButtons> createState() =>
      _CollapsibleActionButtonsState();
}

class _CollapsibleActionButtonsState extends State<CollapsibleActionButtons> {
  bool _showAllActions = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final config = widget.visibilityConfig;

        // Calculate how many buttons fit per row based on screen width
        // Account for horizontal spacing between cards and add buffer to prevent overflow
        int buttonsPerRow = config.maxPerRow;
        double cardWidth = 0;

        // Find the maximum buttonsPerRow that fits without overflow
        // Use minimum card width of ~85px to ensure content fits
        // Add 2px buffer per card to account for rounding and prevent overflow
        const double overflowBuffer = 2.0;
        for (int i = config.maxPerRow; i >= config.minPerRow; i--) {
          final double totalSpacing = widget.horizontalSpacing * (i - 1);
          final double totalBuffer = overflowBuffer * i;
          final double availableWidth =
              constraints.maxWidth - totalSpacing - totalBuffer;
          final double testCardWidth = availableWidth / i;

          // Ensure minimum card width to prevent overflow
          // Use realistic minimum (~100px) to ensure content fits without overflow
          if (testCardWidth >= 100) {
            buttonsPerRow = i;
            cardWidth = testCardWidth;
            break;
          }
        }

        // If no valid width found, use minPerRow
        if (cardWidth == 0) {
          buttonsPerRow = config.minPerRow;
          final double totalSpacing =
              widget.horizontalSpacing * (buttonsPerRow - 1);
          final double totalBuffer = overflowBuffer * buttonsPerRow;
          cardWidth = (constraints.maxWidth - totalSpacing - totalBuffer) /
              buttonsPerRow;
        }

        // Split primary actions into enabled and disabled
        final enabledPrimaryActions =
            widget.primaryActions.where((a) => a.enabled).toList();
        final disabledPrimaryActions =
            widget.primaryActions.where((a) => !a.enabled).toList();

        // Split secondary actions into enabled and disabled
        final enabledSecondaryActions =
            widget.secondaryActions.where((a) => a.enabled).toList();
        final disabledSecondaryActions =
            widget.secondaryActions.where((a) => !a.enabled).toList();

        // Calculate visible actions based on configuration
        final List<ActionButtonData> visiblePrimaryActions;
        final List<ActionButtonData> hiddenPrimaryActions;

        if (config.defaultVisibleCount != null) {
          // Use fixed count if specified
          final visibleCount = config.defaultVisibleCount!
              .clamp(0, enabledPrimaryActions.length);
          visiblePrimaryActions =
              enabledPrimaryActions.take(visibleCount).toList();
          hiddenPrimaryActions =
              enabledPrimaryActions.skip(visibleCount).toList();
        } else {
          // Width-based: show as many primary actions as fit in one row
          // Use buttonsPerRow to determine how many to show
          final totalPrimaryActions = enabledPrimaryActions.length;

          // Show buttonsPerRow number of primary actions (or all if less)
          final int visibleCount = buttonsPerRow.clamp(0, totalPrimaryActions);

          visiblePrimaryActions =
              enabledPrimaryActions.take(visibleCount).toList();
          hiddenPrimaryActions =
              enabledPrimaryActions.skip(visibleCount).toList();
        }

        // Always include disabled primary actions in visible (they're always shown)
        // Combine visible and hidden primary actions based on expand state
        final visibleActions = <ActionButtonData>[
          ...visiblePrimaryActions,
          ...disabledPrimaryActions,
          if (_showAllActions) ...hiddenPrimaryActions,
          if (_showAllActions) ...enabledSecondaryActions,
          if (_showAllActions) ...disabledSecondaryActions,
        ];

        // Determine if expand button should be shown
        final hasHiddenActions = hiddenPrimaryActions.isNotEmpty ||
            widget.secondaryActions.isNotEmpty;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: visibleActions.isNotEmpty
                  ? FlexList(
                      horizontalSpacing: widget.horizontalSpacing,
                      verticalSpacing: widget.verticalSpacing,
                      children: visibleActions.map((action) {
                        final card = widget.actionCardBuilder(context, action);
                        if (widget.fixedHeight != null) {
                          return SizedBox(
                            width: cardWidth,
                            height: widget.fixedHeight,
                            child: card,
                          );
                        }
                        return SizedBox(
                          width: cardWidth,
                          child: card,
                        );
                      }).toList(),
                    )
                  : const SizedBox.shrink(),
            ),
            // Expand button (show if there are hidden actions)
            if (widget.showExpandButton && hasHiddenActions) ...[
              Padding(
                padding: EdgeInsets.only(
                  top: _showAllActions ? 16 : 8,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: CompactExpandButton(
                    isExpanded: _showAllActions,
                    onTap: () {
                      setState(() {
                        _showAllActions = !_showAllActions;
                      });
                      widget.onExpandChanged?.call(_showAllActions);
                    },
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
