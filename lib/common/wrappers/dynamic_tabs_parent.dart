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
  Widget build(final BuildContext context) => DynamicTabsWrapper(
        controller: controller,
        tabBarSettings: DynamicTabSettings( 
          // indicatorPadding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
          dividerColor: Colors.transparent,
          // padding: EdgeInsets.zero,
          tabAlignment: TabAlignment.center,
        ),
        tabBuilder: (final BuildContext context, final DynamicTab tab) =>
            tabBuilder?.call(context, tab) ??
            _buildDynamicTabMenuButton(tab: tab, tabController: controller),
        onTabClose: onTabClose,
        builder: builder,
      );
}

Tab _buildDynamicTabMenuButton({
  required final DynamicTab tab,
  required final DynamicTabsController tabController,
}) =>
    Tab(
      // text: tab.tab?.label ?? tab.identifier,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(left: tab.isDismissible ? 8.0 : 0),
            child: Text(tab.tab?.label ?? tab.identifier),
          ),
          if (tab.isDismissible)
            MenuButton(
              buttonBuilder: (final BuildContext context, final showMenu) =>
                  IconButton(
                icon: Icon(
                  Icons.adaptive.more_rounded,
                ),
                // padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),

                onPressed: showMenu,
              ),
              itemBuilder: (final BuildContext context) => <PullDownMenuEntry>[
                PullDownMenuItem(
                  onTap: () {
                    tabController.closeTab(tab.identifier);
                  },
                  title: 'Close Tab',
                  icon: Icons.close_rounded,
                ),
              ],
            ),
        ],
      ),
    );
