import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/misc/floating_action_toolbar_content.dart';
import 'package:diohub/common/misc/floating_expandable_widget.dart';
import 'package:diohub/common/misc/scroll_based_minimize_controller.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

// Export enums for convenience
export 'package:diohub/common/misc/floating_expandable_widget.dart'
    show FloatingPosition, FloatingAlignment;

/// Result of position and padding calculation for floating widgets
class PositionAndPadding {
  const PositionAndPadding({
    required this.alignment,
    required this.padding,
  });

  final Alignment alignment;
  final EdgeInsets padding;
}

/// Calculates position alignment and padding for a floating widget
/// based on its position (top/bottom) and horizontal alignment
PositionAndPadding calculatePositionAndPadding(
  BuildContext context,
  FloatingPosition position,
  FloatingAlignment? alignment, {
  double bottomPadding = 0.0,
  double horizontalPadding = 16.0,
  double verticalPadding = 16.0,
}) {
  final effectiveAlignment = alignment ??
      (position == FloatingPosition.bottom ? FloatingAlignment.right : null);

  Alignment resultAlignment;
  EdgeInsets resultPadding;

  if (position == FloatingPosition.bottom) {
    resultPadding = EdgeInsets.only(
      bottom: MediaQuery.of(context).padding.bottom +
          bottomPadding +
          verticalPadding,
    );
    switch (effectiveAlignment) {
      case FloatingAlignment.left:
        resultAlignment = Alignment.bottomLeft;
        resultPadding = resultPadding.copyWith(left: horizontalPadding);
        break;
      case FloatingAlignment.center:
        resultAlignment = Alignment.bottomCenter;
        break;
      case FloatingAlignment.right:
      default:
        resultAlignment = Alignment.bottomRight;
        resultPadding = resultPadding.copyWith(right: horizontalPadding);
        break;
    }
  } else {
    resultPadding = EdgeInsets.only(
      top: MediaQuery.of(context).padding.top + verticalPadding,
    );
    switch (effectiveAlignment) {
      case FloatingAlignment.left:
        resultAlignment = Alignment.topLeft;
        resultPadding = resultPadding.copyWith(left: horizontalPadding);
        break;
      case FloatingAlignment.center:
        resultAlignment = Alignment.topCenter;
        break;
      case FloatingAlignment.right:
      default:
        resultAlignment = Alignment.topRight;
        resultPadding = resultPadding.copyWith(right: horizontalPadding);
        break;
    }
  }

  return PositionAndPadding(
    alignment: resultAlignment,
    padding: resultPadding,
  );
}

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
    this.subtitle,
    this.debugLogging = false,
    this.enableMinimize = true,
    this.enableScrollMinimize = true,
    this.scrollMinimizeOffset = 200.0,
    this.scrollOffsetUntilMinimize = 150.0,
    this.scrollOffsetUntilRestore = 100.0,
    this.scrollInitialOffset = 350.0,
    this.scrollNotificationNotifier,
    this.scrollMinimizeController,
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

  /// Subtitle to display below the title in expanded view
  final String? subtitle;

  /// Enable debug logging for positioning and state changes
  final bool debugLogging;

  /// Whether to enable the minimize feature (3rd state)
  /// When enabled, dragging the toolbar off-screen will minimize it to a small button
  final bool enableMinimize;

  /// Whether to enable scroll-based minimize/unminimize
  /// When enabled, toolbar will minimize when scrolling down and restore when scrolling up
  final bool enableScrollMinimize;

  /// Scroll offset threshold to enable minimize on scroll
  /// Defaults to 200.0
  final double scrollMinimizeOffset;

  /// Scroll offset to trigger minimize when scrolling down
  /// Defaults to 50.0
  final double scrollOffsetUntilMinimize;

  /// Scroll offset to trigger restore when scrolling up
  /// Defaults to 50.0
  final double scrollOffsetUntilRestore;

  /// Initial scroll offset required before tracking starts
  /// This prevents immediate minimize/restore on small scroll movements
  /// Defaults to 20.0
  final double scrollInitialOffset;

  /// ValueNotifier that receives scroll notifications from FloatingToolbarWrapper
  /// If provided, the toolbar will listen to this instead of using NotificationListener
  final ValueNotifier<ScrollNotification?>? scrollNotificationNotifier;

  /// Controller for scroll-based minimize logic
  /// If provided, this will be used instead of internal scroll handling
  final ScrollBasedMinimizeController? scrollMinimizeController;

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
  final GlobalKey _buttonKey = GlobalKey();

  // Scroll-based minimize state
  ScrollBasedMinimizeController? _internalScrollController;
  bool _minimizedByScroll = false;

  // Measured positions for animation (Option E: GlobalKey-based)
  Offset? _toolbarPosition;
  Offset? _buttonPosition;
  Offset? _positionOffset; // Calculated offset from toolbar to button

  bool get _isExpanded => _state == ToolbarState.expanded;

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
      curve: Curves.easeInOutCubic, // Smooth curve for seamless morph
    );
    // Start with toolbar visible (minimize animation at 0)
    _minimizeAnimationController.value = 0.0;

    // Initialize scroll controller
    if (widget.scrollMinimizeController != null) {
      // Use provided controller
      widget.scrollMinimizeController!.addListener(_onScrollControllerChanged);
    } else if (widget.enableScrollMinimize) {
      // Create internal controller
      _internalScrollController = ScrollBasedMinimizeController(
        enableScrollMinimize: widget.enableScrollMinimize,
        scrollMinimizeOffset: widget.scrollMinimizeOffset,
        scrollOffsetUntilMinimize: widget.scrollOffsetUntilMinimize,
        scrollOffsetUntilRestore: widget.scrollOffsetUntilRestore,
        scrollInitialOffset: widget.scrollInitialOffset,
        debugLogging: widget.debugLogging,
      );
      _internalScrollController!.addListener(_onScrollControllerChanged);
    }

    // Listen to scroll notifications from ValueNotifier if provided
    if (widget.enableScrollMinimize &&
        widget.scrollNotificationNotifier != null) {
      widget.scrollNotificationNotifier!
          .addListener(_onScrollNotificationChanged);
    }
  }

  @override
  void dispose() {
    // Remove listeners
    if (widget.scrollMinimizeController != null) {
      widget.scrollMinimizeController!
          .removeListener(_onScrollControllerChanged);
    } else if (_internalScrollController != null) {
      _internalScrollController!.removeListener(_onScrollControllerChanged);
      _internalScrollController!.dispose();
    }

    if (widget.enableScrollMinimize &&
        widget.scrollNotificationNotifier != null) {
      widget.scrollNotificationNotifier!
          .removeListener(_onScrollNotificationChanged);
    }
    _animationController.dispose();
    _minimizeAnimationController.dispose();
    super.dispose();
  }

  void _onScrollNotificationChanged() {
    if (widget.scrollNotificationNotifier?.value != null) {
      final controller =
          widget.scrollMinimizeController ?? _internalScrollController;
      if (controller != null) {
        controller.handleScrollNotification(
            widget.scrollNotificationNotifier!.value!);
      } else {
        _handleScrollNotification(widget.scrollNotificationNotifier!.value!);
      }
    }
  }

  void _onScrollControllerChanged() {
    final controller =
        widget.scrollMinimizeController ?? _internalScrollController;
    if (controller == null) return;

    // React to controller state changes - controller is single source of truth
    switch (controller.state) {
      case ScrollMinimizeState.minimizing:
        // Controller wants to minimize - allow regardless of how we got to current state
        // Only skip if already minimized
        if (_state != ToolbarState.minimized) {
          if (widget.debugLogging && kDebugMode) {
            print(
                '[FloatingActionToolbar] _onScrollControllerChanged: Controller state=minimizing, minimizing toolbar. Current state: $_state, _minimizedByScroll: $_minimizedByScroll');
          }
          _minimizedByScroll = true; // Mark as minimized by scroll
          _minimizeFromScroll();
        }
        break;

      case ScrollMinimizeState.minimized:
        // Minimize animation should complete - mark as complete in controller
        if (_minimizedByScroll && _state == ToolbarState.minimized) {
          controller.onMinimizeComplete();
        }
        break;

      case ScrollMinimizeState.restoring:
        // Controller wants to restore - only if minimized by scroll
        if (_minimizedByScroll && _state == ToolbarState.minimized) {
          if (widget.debugLogging && kDebugMode) {
            print(
                '[FloatingActionToolbar] _onScrollControllerChanged: Controller state=restoring, restoring toolbar');
          }
          _restoreFromScrollMinimize();
        }
        break;

      case ScrollMinimizeState.visible:
        // Restore animation should complete - mark as complete in controller
        if (!_minimizedByScroll && _state != ToolbarState.minimized) {
          controller.onRestoreComplete();
        }
        break;
    }
  }

  void _onExpandChanged(bool isExpanded) {
    setState(() {
      if (isExpanded) {
        _state = ToolbarState.expanded;
        _animationController.forward();
        // When manually expanded, reset scroll minimize flag
        // This allows scroll-based minimize to work again
        _minimizedByScroll = false;
      } else {
        _state = ToolbarState.collapsed;
        _animationController.reverse();
      }
    });
    widget.onExpandChanged?.call(isExpanded);
  }

  /// Measures toolbar and button positions using GlobalKeys
  void _measurePositions() {
    final toolbarContext = _toolbarKey.currentContext;
    final buttonContext = _buttonKey.currentContext;

    if (toolbarContext != null && buttonContext != null) {
      final toolbarBox = toolbarContext.findRenderObject() as RenderBox?;
      final buttonBox = buttonContext.findRenderObject() as RenderBox?;

      if (toolbarBox != null && buttonBox != null) {
        final toolbarPosition = toolbarBox.localToGlobal(Offset.zero);
        final buttonPosition = buttonBox.localToGlobal(Offset.zero);

        // Calculate center positions
        final toolbarCenter = toolbarPosition +
            Offset(toolbarBox.size.width / 2, toolbarBox.size.height / 2);
        final buttonCenter = buttonPosition +
            Offset(buttonBox.size.width / 2, buttonBox.size.height / 2);

        // Calculate offset from toolbar center to button center
        setState(() {
          _toolbarPosition = toolbarCenter;
          _buttonPosition = buttonCenter;
          _positionOffset = buttonCenter - toolbarCenter;
        });

        if (widget.debugLogging && kDebugMode) {
          print(
              '[FloatingActionToolbar] Measured positions - Toolbar: $_toolbarPosition, Button: $_buttonPosition, Offset: $_positionOffset');
        }
      }
    }
  }

  Future<void> _minimize() {
    // Ensure toolbar is collapsed when minimizing
    if (_state == ToolbarState.expanded) {
      _animationController.reverse();
    }

    // Reset position offset
    _positionOffset = null;

    // Animate minimize transition
    widget.onExpandChanged?.call(false);

    // Measure positions after layout (button is always rendered but invisible)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measurePositions();
      // Start animation after measurement
      if (mounted) {
        _minimizeAnimationController.forward().then((_) {
          if (mounted) {
            setState(() {
              _state = ToolbarState.minimized;
            });
          }
        });
      }
    });

    return Future.value();
  }

  Future<void> _restoreFromMinimized() {
    // Set state back to collapsed first
    setState(() {
      _state = ToolbarState.collapsed;
      _animationController.value =
          0.0; // Ensure animation is at collapsed state
    });
    // Animate restore transition
    if (widget.debugLogging && kDebugMode) {
      print(
          '[FloatingActionToolbar] Restored from minimized to collapsed state');
    }
    return _minimizeAnimationController.reverse();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    // Use controller if available, otherwise fall back to old behavior (for backward compatibility)
    final controller =
        widget.scrollMinimizeController ?? _internalScrollController;
    if (controller != null) {
      return controller.handleScrollNotification(notification);
    }

    // Fallback: if no controller and scroll minimize is disabled, don't handle
    if (!widget.enableScrollMinimize) {
      return false;
    }

    // This should not be reached if controller is properly initialized
    return false;
  }

  void _minimizeFromScroll() {
    if (!widget.enableMinimize) {
      if (widget.debugLogging && kDebugMode) {
        print(
            '[FloatingActionToolbar] _minimizeFromScroll: enableMinimize=false, skipping');
      }
      return;
    }

    if (_state == ToolbarState.minimized) {
      if (widget.debugLogging && kDebugMode) {
        print(
            '[FloatingActionToolbar] _minimizeFromScroll: Already minimized (state=$_state), notifying controller');
      }
      // Already minimized, notify controller that it's complete
      _minimizedByScroll = true;
      final controller =
          widget.scrollMinimizeController ?? _internalScrollController;
      controller?.onMinimizeComplete();
      return;
    }

    if (widget.debugLogging && kDebugMode) {
      print(
          '[FloatingActionToolbar] _minimizeFromScroll: Minimizing from scroll, current state: $_state');
    }

    _minimizedByScroll = true;
    _minimize().then((_) {
      // Notify controller when animation completes
      final controller =
          widget.scrollMinimizeController ?? _internalScrollController;
      if (mounted && _state == ToolbarState.minimized) {
        controller?.onMinimizeComplete();
      }
    });
  }

  void _restoreFromScrollMinimize() {
    if (!_minimizedByScroll) {
      if (widget.debugLogging && kDebugMode) {
        print(
            '[FloatingActionToolbar] _restoreFromScrollMinimize: Not minimized by scroll (minimizedByScroll=$_minimizedByScroll), skipping');
      }
      return;
    }

    if (widget.debugLogging && kDebugMode) {
      print(
          '[FloatingActionToolbar] _restoreFromScrollMinimize: Restoring from scroll minimize, current state: $_state');
    }

    if (_state == ToolbarState.minimized) {
      if (widget.debugLogging && kDebugMode) {
        print(
            '[FloatingActionToolbar] _restoreFromScrollMinimize: State is minimized, calling _restoreFromMinimized()');
      }
      _minimizedByScroll = false;
      _restoreFromMinimized().then((_) {
        // Notify controller when animation completes
        final controller =
            widget.scrollMinimizeController ?? _internalScrollController;
        if (mounted && _state != ToolbarState.minimized) {
          controller?.onRestoreComplete();
        }
      });
    } else {
      if (widget.debugLogging && kDebugMode) {
        print(
            '[FloatingActionToolbar] _restoreFromScrollMinimize: State is not minimized (state=$_state), marking as restored');
      }
      // Not minimized, so restoration is already complete
      _minimizedByScroll = false;
      final controller =
          widget.scrollMinimizeController ?? _internalScrollController;
      controller?.onRestoreComplete();
    }
  }

  /// Builds the minimized button (small FAB-like button)
  Widget _buildMinimizedButton(BuildContext context) {
    // Calculate position and padding using shared helper
    final positionAndPadding = calculatePositionAndPadding(
      context,
      widget.position,
      widget.alignment,
      bottomPadding: widget.bottomPadding,
    );

    return Align(
      alignment: positionAndPadding.alignment,
      child: Padding(
        padding: positionAndPadding.padding,
        child: Container(
          key: _buttonKey, // GlobalKey for position measurement
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
                onTap: () => _restoreFromMinimized(),
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
    Widget toolbarWidget;
    if (_state == ToolbarState.minimized &&
        widget.enableMinimize &&
        _minimizeAnimationController.isCompleted) {
      toolbarWidget = _buildMinimizedButton(context);
    } else {
      // Build the toolbar widget with animation inside contentBuilder
      toolbarWidget = AnimatedBuilder(
        animation: _minimizeAnimation,
        builder: (context, child) {
          final animationValue = _minimizeAnimation.value;

          // OPTION E: GlobalKey-based position measurement
          // Use measured positions if available, otherwise fallback to center scale
          Offset toolbarSlide;
          Alignment scaleAlignment;

          if (_positionOffset != null) {
            // Use measured offset from toolbar to button
            toolbarSlide = _positionOffset! * animationValue;
            // Scale toward the button position (use center alignment since we're using measured offset)
            scaleAlignment = Alignment.center;
          } else {
            // Fallback: scale from center if positions not measured yet
            toolbarSlide = Offset.zero;
            scaleAlignment = Alignment.center;
          }

          // OPTION 10: Morph - Toolbar scales to button size and transforms into button
          // Scale down to approximately button size (15% = button-sized relative to toolbar)
          // This makes toolbar appear to shrink to button dimensions
          final toolbarScale = 1.0 -
              (animationValue * 0.85); // Scale down to 15% (button-like size)

          // Keep toolbar visible until it reaches button size, then fade out
          // Use a curve that keeps it visible longer, then fades quickly at the end
          final toolbarFadeStart = 0.7; // Start fading when 70% shrunk
          final toolbarOpacity = animationValue < toolbarFadeStart
              ? 1.0
              : 1.0 -
                  ((animationValue - toolbarFadeStart) /
                      (1.0 - toolbarFadeStart));

          // Button: appears as toolbar reaches button size (seamless morph)
          // Start button fade when toolbar is about 60% shrunk (when it's close to button size)
          final buttonFadeStart = 0.6;
          final buttonOpacity = animationValue < buttonFadeStart
              ? 0.0
              : ((animationValue - buttonFadeStart) / (1.0 - buttonFadeStart))
                  .clamp(0.0, 1.0);

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
                    // Apply scale + slide + fade animation INSIDE the contentBuilder
                    return Opacity(
                      opacity: toolbarOpacity,
                      child: IgnorePointer(
                        ignoring: toolbarOpacity < 0.1,
                        child: Transform.translate(
                          offset: toolbarSlide,
                          child: Transform.scale(
                            scale: toolbarScale,
                            alignment: scaleAlignment,
                            child: buildToolbarContent(
                              context: context,
                              callbacks: callbacks,
                              actions: widget.actions,
                              spacing: widget.spacing,
                              maxHeight: widget.maxHeight,
                              position: widget.position,
                              onCollapseRequested: widget.onCollapseRequested,
                              prominentActionBuilder:
                                  widget.prominentActionBuilder,
                              expandAnimation: _expandAnimation,
                              toolbarKey: _toolbarKey,
                              title: widget.title,
                              subtitle: widget.subtitle,
                              debugLogging: widget.debugLogging,
                            ),
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
                  onMinimizeRequested: widget.enableMinimize
                      ? () {
                          // Manual minimize - mark as NOT minimized by scroll
                          _minimizedByScroll = false;
                          _minimize();
                        }
                      : null,
                ),
              // Button - always rendered (invisible when not needed) for position measurement
              if (widget.enableMinimize)
                Positioned.fill(
                  child: Opacity(
                    opacity: (_state == ToolbarState.minimized ||
                            animationValue > 0.0)
                        ? buttonOpacity
                        : 0.0, // Invisible but rendered for measurement
                    child: IgnorePointer(
                      ignoring: buttonOpacity < 0.1 &&
                          _state != ToolbarState.minimized,
                      child: _buildMinimizedButton(context),
                    ),
                  ),
                ),
            ],
          );
        },
      );
    }

    // If using ValueNotifier, we don't need NotificationListener
    // The notifications are already being handled via the listener in initState
    // Otherwise, wrap in NotificationListener to listen to scroll notifications
    if (widget.enableScrollMinimize &&
        widget.scrollNotificationNotifier == null) {
      return NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: toolbarWidget,
      );
    }

    return toolbarWidget;
  }
}
