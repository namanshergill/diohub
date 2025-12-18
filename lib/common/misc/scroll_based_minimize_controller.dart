import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// State of scroll-based minimize behavior
enum ScrollMinimizeState {
  /// Widget is visible (not minimized)
  visible,

  /// Widget should be minimized (transitioning to minimized)
  minimizing,

  /// Widget is minimized by scroll
  minimized,

  /// Widget should be restored (transitioning to visible)
  restoring,
}

/// Controller that handles scroll-based minimize/restore logic
///
/// Tracks scroll position and determines when to minimize/restore based on
/// scroll thresholds. Can be used with any widget that needs scroll-based
/// visibility control.
///
/// **Best Practices:**
/// - This controller is the single source of truth for scroll-based minimize state
/// - Widgets should reactively respond to [state] changes, not maintain duplicate state
/// - Use [state] to determine UI behavior, not internal flags
class ScrollBasedMinimizeController extends ChangeNotifier {
  ScrollBasedMinimizeController({
    this.enableScrollMinimize = true,
    this.scrollMinimizeOffset = 200.0,
    this.scrollOffsetUntilMinimize = 150.0,
    this.scrollOffsetUntilRestore = 150.0,
    this.scrollInitialOffset = 350.0,
    this.debugLogging = false,
  });

  /// Whether scroll-based minimize is enabled
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
  /// Defaults to 350.0
  final double scrollInitialOffset;

  /// Enable debug logging
  final bool debugLogging;

  // Internal state
  double? _currentScrollForwardOffset;
  double? _currentScrollReverseOffset;
  double? _initialScrollForwardOffset;
  double? _initialScrollReverseOffset;
  ScrollMinimizeState _state = ScrollMinimizeState.visible;

  /// Current state of scroll-based minimize behavior
  /// This is the single source of truth - widgets should react to this
  ScrollMinimizeState get state => _state;

  /// Whether the widget was minimized by scroll
  /// Convenience getter for checking if currently minimized
  bool get isMinimizedByScroll =>
      _state == ScrollMinimizeState.minimized ||
      _state == ScrollMinimizeState.minimizing;

  /// Handle a scroll notification
  /// Returns true if the notification was handled and should be consumed
  bool handleScrollNotification(ScrollNotification notification) {
    if (!enableScrollMinimize) {
      return false;
    }

    // Only handle scroll update notifications
    if (notification is! ScrollUpdateNotification) {
      return false;
    }

    final metrics = notification.metrics;

    // Only respond to vertical scroll (up/down), ignore horizontal scroll (left/right)
    if (metrics.axisDirection != AxisDirection.down &&
        metrics.axisDirection != AxisDirection.up) {
      // Horizontal scroll - ignore
      return false;
    }

    final pixels = metrics.pixels;
    final scrollDelta = notification.scrollDelta ?? 0.0;

    // Determine scroll direction from scrollDelta
    // Positive delta = scrolling down, negative delta = scrolling up
    final isScrollingDown = scrollDelta > 0;
    final isScrollingUp = scrollDelta < 0;

    if (debugLogging && kDebugMode) {
      print(
          '[ScrollBasedMinimizeController] Scroll notification: pixels=$pixels, scrollDelta=$scrollDelta, axisDirection=${metrics.axisDirection}, isScrollingDown=$isScrollingDown, state=$_state');
    }

    // Check if we're at the top (should restore)
    if (pixels <= scrollMinimizeOffset && isMinimizedByScroll) {
      if (debugLogging && kDebugMode) {
        print(
            '[ScrollBasedMinimizeController] At top (pixels=$pixels <= threshold=$scrollMinimizeOffset), restoring from scroll minimize');
      }
      _transitionToRestoring();
      return false;
    }

    // Only process if we're past the threshold
    if (pixels <= scrollMinimizeOffset) {
      return false;
    }

    // Track scroll deltas based on direction
    if (isScrollingDown) {
      _handleScrollDown(pixels);
    } else if (isScrollingUp) {
      _handleScrollUp(pixels);
    }

    return false;
  }

  void _handleScrollDown(double pixels) {
    // Reset reverse direction tracking when scrolling down
    _initialScrollReverseOffset = null;
    _currentScrollReverseOffset = null;

    // Set initial tracking point if not set
    _initialScrollForwardOffset ??= pixels;

    // Calculate how far we've scrolled from the initial point
    final initialDelta = pixels - _initialScrollForwardOffset!;

    if (debugLogging && kDebugMode) {
      print(
          '[ScrollBasedMinimizeController] Scrolling DOWN - initialOffset=${_initialScrollForwardOffset}, current=$pixels, initialDelta=$initialDelta, threshold=$scrollInitialOffset');
    }

    // Only start tracking after initial offset threshold
    if (initialDelta < scrollInitialOffset) {
      return;
    }

    // Once past initial threshold, set the tracking point if not already set
    _currentScrollForwardOffset ??= pixels;

    // Calculate delta from tracking point (for minimize threshold)
    final delta = pixels - _currentScrollForwardOffset!;

    if (debugLogging && kDebugMode) {
      print(
          '[ScrollBasedMinimizeController] Scrolling DOWN - tracking offset=${_currentScrollForwardOffset}, current=$pixels, delta=$delta, required=$scrollOffsetUntilMinimize');
    }

    // Check if scrolled enough to minimize (with small tolerance for floating point precision)
    const epsilon = 0.01;
    if (delta >= scrollOffsetUntilMinimize - epsilon) {
      // Only transition if not already minimized or minimizing
      if (_state != ScrollMinimizeState.minimized &&
          _state != ScrollMinimizeState.minimizing) {
        if (debugLogging && kDebugMode) {
          print(
              '[ScrollBasedMinimizeController] Scrolled down enough (delta=$delta >= $scrollOffsetUntilMinimize), transitioning to minimizing');
        }
        _transitionToMinimizing();
      }
      _currentScrollReverseOffset = null;
      _initialScrollReverseOffset = null;
    }
  }

  void _handleScrollUp(double pixels) {
    // Reset forward direction tracking when scrolling up
    _initialScrollForwardOffset = null;
    _currentScrollForwardOffset = null;

    // Set initial tracking point if not set
    _initialScrollReverseOffset ??= pixels;

    // Calculate how far we've scrolled from the initial point
    final initialDelta = _initialScrollReverseOffset! - pixels;

    if (debugLogging && kDebugMode) {
      print(
          '[ScrollBasedMinimizeController] Scrolling UP - initialOffset=${_initialScrollReverseOffset}, current=$pixels, initialDelta=$initialDelta, threshold=$scrollInitialOffset');
    }

    // Only start tracking after initial offset threshold
    if (initialDelta < scrollInitialOffset) {
      return;
    }

    // Once past initial threshold, set the tracking point if not already set
    _currentScrollReverseOffset ??= pixels;

    // Calculate delta from tracking point (for restore threshold)
    final delta = _currentScrollReverseOffset! - pixels;

    if (debugLogging && kDebugMode) {
      print(
          '[ScrollBasedMinimizeController] Scrolling UP - tracking offset=${_currentScrollReverseOffset}, current=$pixels, delta=$delta, required=$scrollOffsetUntilRestore');
    }

    // Check if scrolled enough to restore (with small tolerance for floating point precision)
    const epsilon = 0.01;
    if (delta >= scrollOffsetUntilRestore - epsilon) {
      // Only restore if currently minimized by scroll
      if (isMinimizedByScroll) {
        if (debugLogging && kDebugMode) {
          print(
              '[ScrollBasedMinimizeController] Scrolled up enough (delta=$delta >= $scrollOffsetUntilRestore), transitioning to restoring');
        }
        _transitionToRestoring();
      } else {
        if (debugLogging && kDebugMode) {
          print(
              '[ScrollBasedMinimizeController] Not minimized by scroll (state=$_state), skipping restore');
        }
      }
      _currentScrollForwardOffset = null;
      _initialScrollForwardOffset = null;
    }
  }

  void _transitionToMinimizing() {
    if (_state == ScrollMinimizeState.minimized ||
        _state == ScrollMinimizeState.minimizing) {
      return; // Already minimized or minimizing
    }

    if (debugLogging && kDebugMode) {
      print(
          '[ScrollBasedMinimizeController] _transitionToMinimizing: Transitioning from $_state to minimizing');
    }

    _state = ScrollMinimizeState.minimizing;
    notifyListeners();
  }

  void _transitionToRestoring() {
    if (!isMinimizedByScroll) {
      if (debugLogging && kDebugMode) {
        print(
            '[ScrollBasedMinimizeController] _transitionToRestoring: Not minimized by scroll (state=$_state), skipping');
      }
      return;
    }

    if (debugLogging && kDebugMode) {
      print(
          '[ScrollBasedMinimizeController] _transitionToRestoring: Transitioning from $_state to restoring');
    }

    _state = ScrollMinimizeState.restoring;

    // Reset all scroll tracking offsets
    _currentScrollForwardOffset = null;
    _currentScrollReverseOffset = null;
    _initialScrollForwardOffset = null;
    _initialScrollReverseOffset = null;

    notifyListeners();
  }

  /// Called by the widget when minimize animation completes
  /// This transitions from [ScrollMinimizeState.minimizing] to [ScrollMinimizeState.minimized]
  void onMinimizeComplete() {
    if (_state == ScrollMinimizeState.minimizing) {
      if (debugLogging && kDebugMode) {
        print(
            '[ScrollBasedMinimizeController] onMinimizeComplete: Transitioning from minimizing to minimized');
      }
      _state = ScrollMinimizeState.minimized;
      notifyListeners();
    }
  }

  /// Called by the widget when restore animation completes
  /// This transitions from [ScrollMinimizeState.restoring] to [ScrollMinimizeState.visible]
  void onRestoreComplete() {
    if (_state == ScrollMinimizeState.restoring) {
      if (debugLogging && kDebugMode) {
        print(
            '[ScrollBasedMinimizeController] onRestoreComplete: Transitioning from restoring to visible');
      }
      _state = ScrollMinimizeState.visible;
      notifyListeners();
    }
  }

  /// Reset all scroll tracking state
  void reset() {
    _currentScrollForwardOffset = null;
    _currentScrollReverseOffset = null;
    _initialScrollForwardOffset = null;
    _initialScrollReverseOffset = null;
    _state = ScrollMinimizeState.visible;
    notifyListeners();
  }
}
