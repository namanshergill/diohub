import 'dart:math';

import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/misc/floating_action_toolbar_content.dart';
import 'package:diohub/common/misc/floating_expandable_widget.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

// Export enums for convenience
export 'package:diohub/common/misc/floating_expandable_widget.dart'
    show FloatingPosition, FloatingAlignment;

/// State of the floating toolbar
enum ToolbarState {
  /// Minimized state - shows only a small button
  minimized,

  /// Collapsed state - shows compact toolbar
  collapsed,

  /// Expanded state - shows full toolbar
  expanded,
}

/// A floating toolbar widget with liquid glass effect and expand/collapse functionality.
///
/// Displays action buttons in a horizontal scrollable layout that floats above content.
/// Features a frosted glass background with blur effect and smooth expand/collapse animations.
/// Supports three states: minimized (small button), collapsed (compact toolbar), expanded (full toolbar).
///
/// **State Flow:**
/// - Minimized → tap button → Collapsed → drag to center/tap → Expanded
/// - Expanded → drag to edge/tap → Collapsed → drag off-screen → Minimized
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
///           onTap: () {},
///         ),
///         // ... more actions
///       ],
///       actionCardBuilder: buildStandardActionCard,
///       position: FloatingPosition.bottom,
///     ),
///   ],
/// )
/// ```
class FloatingActionToolbar extends StatefulWidget {
  const FloatingActionToolbar({
    required this.actions,
    required this.actionCardBuilder,
    this.onExpandChanged,
    this.onCollapseRequested,
    this.position = FloatingPosition.bottom,
    this.alignment,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.spacing = 8,
    this.maxHeight,
    this.prominentActionBuilder,
    this.bottomPadding = 0.0,
    this.title,
    this.debugLogging = false,
    this.enableMinimize = true,
    super.key,
  });

  /// All actions to display in the toolbar.
  /// Actions are automatically split by type:
  /// - MinorActionButton → displayed in the horizontal row (minor actions)
  /// - MajorActionButton, ExpandableActionButton, CheckboxActionButton → displayed as prominent actions above the row
  final List<ActionButtonData> actions;

  /// Builder function to create individual action cards
  final Widget Function(BuildContext context, ActionButtonData action)
      actionCardBuilder;

  /// Builder for prominent action cards (uses buildProminentActionCard by default)
  final Widget Function(BuildContext context, ActionButtonData action)?
      prominentActionBuilder;

  /// Callback when expand state changes
  final void Function(bool isExpanded)? onExpandChanged;

  /// Callback to collapse the toolbar (called after action tap by default)
  /// If null, defaults to collapsing the toolbar when an action is tapped
  final VoidCallback? onCollapseRequested;

  /// Position of the toolbar
  final FloatingPosition position;

  /// Horizontal alignment of the toolbar
  /// If null, defaults to center for top position, right for bottom position
  final FloatingAlignment? alignment;

  /// Padding around the toolbar content
  final EdgeInsets padding;

  /// Spacing between action buttons
  final double spacing;

  /// Maximum height of the toolbar when expanded
  final double? maxHeight;

  /// Additional bottom padding to account for app-level UI elements (e.g., tab bars)
  /// This is added on top of system UI padding (viewPadding.bottom)
  final double bottomPadding;

  /// Title to display in expanded view (e.g., username on home, repo name on repo screen)
  final String? title;

  /// Enable debug logging for positioning and state changes
  final bool debugLogging;

  /// Whether to enable the minimize feature (3rd state)
  /// When enabled, dragging the toolbar off-screen will minimize it to a small button
  final bool enableMinimize;

  @override
  State<FloatingActionToolbar> createState() => _FloatingActionToolbarState();
}

class _FloatingActionToolbarState extends State<FloatingActionToolbar>
    with TickerProviderStateMixin {
  ToolbarState _state = ToolbarState.collapsed;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late AnimationController _minimizeAnimationController;
  late Animation<double> _minimizeAnimation;
  final GlobalKey _toolbarKey = GlobalKey();

  bool get _isExpanded => _state == ToolbarState.expanded;
  bool get _isMinimized => _state == ToolbarState.minimized;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    _minimizeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _minimizeAnimation = CurvedAnimation(
      parent: _minimizeAnimationController,
      curve: Curves.easeInOutCubic,
    );
    // Start with toolbar visible (minimize animation at 0)
    _minimizeAnimationController.value = 0.0;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _minimizeAnimationController.dispose();
    super.dispose();
  }

  void _onExpandChanged(bool isExpanded) {
    setState(() {
      if (isExpanded) {
        _state = ToolbarState.expanded;
        _animationController.forward();
      } else {
        _state = ToolbarState.collapsed;
        _animationController.reverse();
      }
    });
    widget.onExpandChanged?.call(isExpanded);
  }

  void _minimize() {
    // Ensure toolbar is collapsed when minimizing
    if (_state == ToolbarState.expanded) {
      _animationController.reverse();
    }
    // Animate minimize transition
    _minimizeAnimationController.forward().then((_) {
      if (mounted) {
        setState(() {
          _state = ToolbarState.minimized;
        });
      }
    });
    widget.onExpandChanged?.call(false);
  }

  void _restoreFromMinimized() {
    // Set state back to collapsed first
    setState(() {
      _state = ToolbarState.collapsed;
      _animationController.value =
          0.0; // Ensure animation is at collapsed state
    });
    // Animate restore transition
    _minimizeAnimationController.reverse();
    if (widget.debugLogging && kDebugMode) {
      print(
          '[FloatingActionToolbar] Restored from minimized to collapsed state');
    }
  }

  /// Builds the minimized button (small FAB-like button)
  Widget _buildMinimizedButton(BuildContext context) {
    final effectiveAlignment = widget.alignment ??
        (widget.position == FloatingPosition.bottom
            ? FloatingAlignment.right
            : null);

    // Calculate position based on alignment and position
    Alignment alignment;
    EdgeInsets padding;

    if (widget.position == FloatingPosition.bottom) {
      padding = EdgeInsets.only(
        bottom:
            MediaQuery.of(context).padding.bottom + widget.bottomPadding + 16,
      );
      switch (effectiveAlignment) {
        case FloatingAlignment.left:
          alignment = Alignment.bottomLeft;
          padding = padding.copyWith(left: 16);
          break;
        case FloatingAlignment.center:
          alignment = Alignment.bottomCenter;
          break;
        case FloatingAlignment.right:
        default:
          alignment = Alignment.bottomRight;
          padding = padding.copyWith(right: 16);
          break;
      }
    } else {
      padding = EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
      );
      switch (effectiveAlignment) {
        case FloatingAlignment.left:
          alignment = Alignment.topLeft;
          padding = padding.copyWith(left: 16);
          break;
        case FloatingAlignment.center:
          alignment = Alignment.topCenter;
          break;
        case FloatingAlignment.right:
        default:
          alignment = Alignment.topRight;
          padding = padding.copyWith(right: 16);
          break;
      }
    }

    return Align(
      alignment: alignment,
      child: Padding(
        padding: padding,
        child: LiquidGlassLayer(
          settings: LiquidGlassSettings(
            blur: 12,
            glassColor: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withOpacity(0.25),
            thickness: 2.5,
            refractiveIndex: 1.5,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _restoreFromMinimized,
              borderRadius: BorderRadius.circular(28),
              child: LiquidGlass(
                shape: LiquidRoundedRectangle(
                  borderRadius: 28,
                ),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.15),
                      width: 0.5,
                    ),
                  ),
                  child: Icon(
                    Octicons.kebab_horizontal,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveAlignment = widget.alignment ??
        (widget.position == FloatingPosition.bottom
            ? FloatingAlignment.right
            : null);

    if (widget.debugLogging && kDebugMode) {
      print(
          '[FloatingActionToolbar] build: position=${widget.position}, alignment=${widget.alignment}, effectiveAlignment=$effectiveAlignment, state=$_state');
    }

    // If minimized and animation complete, show only button
    if (_state == ToolbarState.minimized &&
        widget.enableMinimize &&
        _minimizeAnimationController.isCompleted) {
      return _buildMinimizedButton(context);
    }

    // Build the toolbar widget with animation inside contentBuilder
    return AnimatedBuilder(
      animation: _minimizeAnimation,
      builder: (context, child) {
        final animationValue = _minimizeAnimation.value;

        // Calculate slide direction based on position
        // For bottom position: slide down (positive Y), for top: slide up (negative Y)
        final slideDistance = 100.0; // Distance to slide
        final slideY = widget.position == FloatingPosition.bottom
            ? slideDistance * animationValue // Slide down when minimizing
            : -slideDistance * animationValue; // Slide up when minimizing

        // Toolbar: slides toward edge and fades out
        final toolbarOpacity = 1.0 - animationValue;
        final toolbarSlide = Offset(0, slideY);

        // Button: slides from opposite direction and fades in
        final buttonOpacity = animationValue;
        final buttonSlide = Offset(0, -slideY * (1 - animationValue));

        return Stack(
          children: [
            // Toolbar - only visible when not fully minimized
            if (_state != ToolbarState.minimized || animationValue < 1.0)
              FloatingExpandableWidget(
                contentBuilder: (context, callbacks) {
                  // Sync local state with callbacks
                  if (_isExpanded != callbacks.isExpanded) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _onExpandChanged(callbacks.isExpanded);
                      }
                    });
                  }
                  // Apply slide + fade animation INSIDE the contentBuilder
                  return Opacity(
                    opacity: toolbarOpacity,
                    child: IgnorePointer(
                      ignoring: toolbarOpacity < 0.1,
                      child: Transform.translate(
                        offset: toolbarSlide,
                        child: buildToolbarContent(
                          context: context,
                          callbacks: callbacks,
                          actions: widget.actions,
                          spacing: widget.spacing,
                          maxHeight: widget.maxHeight,
                          position: widget.position,
                          onCollapseRequested: widget.onCollapseRequested,
                          prominentActionBuilder: widget.prominentActionBuilder,
                          expandAnimation: _expandAnimation,
                          toolbarKey: _toolbarKey,
                          title: widget.title,
                          debugLogging: widget.debugLogging,
                        ),
                      ),
                    ),
                  );
                },
                position: widget.position,
                alignment: effectiveAlignment,
                padding: widget.padding,
                bottomPadding: widget.bottomPadding,
                debugLogging: widget.debugLogging,
                onExpandChanged: _onExpandChanged,
                onMinimizeRequested: widget.enableMinimize ? _minimize : null,
              ),
            // Button - visible during transition or when minimized
            if (widget.enableMinimize &&
                (_state == ToolbarState.minimized || animationValue > 0.0))
              Positioned.fill(
                child: Opacity(
                  opacity: buttonOpacity,
                  child: IgnorePointer(
                    ignoring: buttonOpacity < 0.1,
                    child: Transform.translate(
                      offset: buttonSlide,
                      child: _buildMinimizedButton(context),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
