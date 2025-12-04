import 'package:flutter/material.dart';

/// A widget that animates a tab bar in and out, with default padding when hidden.
///
/// When the tab bar is not visible, it provides default padding to maintain spacing.
/// This ensures consistent layout whether the tab bar is shown or hidden.
///
/// Example usage:
/// ```dart
/// AnimatedTabBar(
///   showTabBar: tabController.activeLength > 1,
///   tabBar: tabs,
///   defaultPadding: const EdgeInsets.only(bottom: 8),
/// )
/// ```
class AnimatedTabBar extends StatelessWidget {
  const AnimatedTabBar({
    required this.showTabBar,
    required this.tabBar,
    this.defaultPadding = const EdgeInsets.only(bottom: 8),
    this.topSpacing = 4.0,
    super.key,
  });

  /// Whether to show the tab bar
  final bool showTabBar;

  /// The tab bar widget to animate
  final Widget tabBar;

  /// Default padding to show when tab bar is hidden
  final EdgeInsets defaultPadding;

  /// Spacing above the tab bar when visible
  final double topSpacing;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SizeTransition(
          sizeFactor: animation,
          child: child,
        );
      },
      child: showTabBar
          ? Column(
              key: const ValueKey('tabBar'),
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: topSpacing),
                SizedBox(
                  width: double.infinity,
                  child: tabBar,
                ),
              ],
            )
          : Padding(
              key: const ValueKey('padding'),
              padding: defaultPadding,
              child: const SizedBox.shrink(),
            ),
    );
  }
}

