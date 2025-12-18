import 'package:flutter/material.dart';

/// A wrapper widget that provides scroll notifications to a floating toolbar
///
/// Wraps a child widget with a NotificationListener that captures scroll notifications
/// and passes them to the toolbar via a ValueNotifier. This allows the toolbar to
/// receive scroll notifications even when it's a sibling of the scrollable content.
///
/// **Usage:**
/// ```dart
/// FloatingToolbarWrapper(
///   toolbarBuilder: (scrollNotificationNotifier) {
///     return FloatingActionToolbar(
///       actions: actions,
///       scrollNotificationNotifier: scrollNotificationNotifier,
///       // ... other params
///     );
///   },
///   child: YourScrollableContent(),
/// )
/// ```
class FloatingToolbarWrapper extends StatefulWidget {
  const FloatingToolbarWrapper({
    required this.child,
    required this.toolbarBuilder,
    super.key,
  });

  /// The scrollable content widget
  final Widget child;

  /// Builder function that creates the toolbar widget
  /// Receives a ValueNotifier<ScrollNotification?> that provides scroll notifications
  final Widget Function(
          ValueNotifier<ScrollNotification?> scrollNotificationNotifier)
      toolbarBuilder;

  @override
  State<FloatingToolbarWrapper> createState() => _FloatingToolbarWrapperState();
}

class _FloatingToolbarWrapperState extends State<FloatingToolbarWrapper> {
  final ValueNotifier<ScrollNotification?> _scrollNotificationNotifier =
      ValueNotifier<ScrollNotification?>(null);

  @override
  void dispose() {
    _scrollNotificationNotifier.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    // Pass notification to toolbar via ValueNotifier
    _scrollNotificationNotifier.value = notification;
    return false; // Don't consume the notification
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Wrap child with NotificationListener to capture scroll notifications
        NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: widget.child,
        ),
        // Build toolbar with access to scroll notifications
        widget.toolbarBuilder(_scrollNotificationNotifier),
      ],
    );
  }
}
