import 'package:diohub/common/misc/menu_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dynamic_tabs/flutter_dynamic_tabs.dart';
import 'package:pull_down_button/pull_down_button.dart';

class DynamicTabsParent extends StatelessWidget {
  const DynamicTabsParent({
    required this.controller,
    // required this.tabs,
    required this.builder,
    this.onTabClose,
    this.tabBuilder,
    super.key,
  });

  final DynamicTabsController controller;
  final Future<bool> Function(String idenitifier, String? label)? onTabClose;

  // final List<DynamicTab> tabs;
  final Widget Function(BuildContext context, DynamicTab tab)? tabBuilder;
  final Widget Function(
    BuildContext context,
    PreferredSizeWidget tabBar,
    Widget tabView,
  ) builder;

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return DynamicTabsWrapper(
      controller: controller,
      tabBarSettings: DynamicTabSettings(
        // Color-only design: No indicator, just color change
        indicator: const BoxDecoration(),
        indicatorSize: TabBarIndicatorSize.label,
        indicatorPadding: EdgeInsets.zero,
        dividerColor: Colors.transparent,
        tabAlignment: TabAlignment.center,
        labelStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 13,
          letterSpacing: 0.1,
        ),
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant.withOpacity(0.6),
        labelPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        childPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        physics: const BouncingScrollPhysics(),
      ),
      tabBuilder: (final BuildContext context, final DynamicTab tab) =>
          tabBuilder?.call(context, tab) ??
          _buildDynamicTabMenuButton(tab: tab, tabController: controller),
      onTabClose: onTabClose,
      builder: builder,
    );
  }
}

Tab _buildDynamicTabMenuButton({
  required final DynamicTab tab,
  required final DynamicTabsController tabController,
}) =>
    Tab(
      height: 40, // Fixed height to reduce vertical padding
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Flexible(
            child: Text(
              tab.tab?.label ?? tab.identifier,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (tab.isDismissible)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: MenuButton(
                buttonBuilder:
                    (final BuildContext context, final VoidCallback showMenu) =>
                        Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: showMenu,
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.adaptive.more_rounded,
                        size: 14,
                      ),
                    ),
                  ),
                ),
                itemBuilder: (final BuildContext context) =>
                    <PullDownMenuEntry>[
                  PullDownMenuItem(
                    onTap: () {
                      tabController.closeTab(tab.identifier);
                    },
                    title: 'Close Tab',
                    icon: Icons.close_rounded,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
