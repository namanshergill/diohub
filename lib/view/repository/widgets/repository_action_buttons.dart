import 'package:auto_route/auto_route.dart';
import 'package:diohub/adapters/deep_linking_handler.dart';
import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/issues/issue_label.dart';
import 'package:diohub/common/misc/action_card_builder.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/misc/ink_pot.dart';
import 'package:diohub/common/wrappers/infinite_scroll_list_view.dart';
import 'package:diohub/common/wrappers/infinite_scroll_wrapper.dart';
import 'package:diohub/graphql/queries/repositories/__generated__/branches_list.data.gql.dart';
import 'package:diohub/graphql/queries/repositories/__generated__/repo_info.data.gql.dart';
import 'package:diohub/graphql/__generated__/schema.schema.gql.dart' as _i2;
import 'package:diohub/models/issues/issue_model.dart';
import 'package:diohub/models/repositories/branch_list_model.dart';
import 'package:diohub/models/users/user_info_model.dart';
import 'package:diohub/providers/repository/branch_provider.dart';
import 'package:diohub/providers/repository/repository_provider.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/services/repositories/repo_services.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/issues_pulls/issue_pull_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dynamic_tabs/flutter_dynamic_tabs.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';
import 'package:diohub/view/repository/readme/repository_readme.dart';
import 'tab_state.dart';

/// Builds all action buttons for the floating action toolbar
List<ActionButtonData> buildAllActions(
  BuildContext context,
  GrepositoryInfoData_repository repo,
  TabState tabState,
  List<({String text, String id, int level})> readmeHeadings,
  GlobalKey<RepositoryReadmeState> readmeStateKey,
  DynamicTabsController tabController,
) {
  final List<ActionButtonData> allActions = [];

  // Get readme headings for "Jump to" button (stored via callback)
  final currentReadmeHeadings =
      tabState.isOnReadmeTab ? readmeHeadings : <({String text, String id})>[];

  // Get issue templates for "New Issue" button - use repo data directly
  final issueTemplates = repo.issueTemplates?.toList() ?? [];
  final hasTemplates = issueTemplates.isNotEmpty;

  // Get pinned issues for "Pinned Issues" button - use repo data directly
  final pinnedIssuesNodes = repo.pinnedIssues?.nodes;
  final pinnedIssues = pinnedIssuesNodes?.toList() ??
      <GrepositoryInfoData_repository_pinnedIssues_nodes?>[];
  final filteredPinnedIssues = pinnedIssues
      .whereType<GrepositoryInfoData_repository_pinnedIssues_nodes>()
      .toList();

  // Build "Jump to" button
  // Always create it to maintain consistent list structure (prevents widget recreation)
  // Use visibilityState to control visibility instead of conditionally adding/removing
  final jumpToButton = ExpandableActionButton(
    icon: Octicons.book,
    label: 'Table of Contents',
    enabled: readmeHeadings.isNotEmpty,
    seedColor: Colors.white,
    visibilityState: (tabState.isOnReadmeTab && readmeHeadings.isNotEmpty)
        ? ActionButtonVisibilityState.both
        : ActionButtonVisibilityState.none,
    expandableWidgetBuilder: (onCollapse) => Builder(
      builder: (context) {
        // Use currentReadmeHeadings from closure - it will be empty when not on Readme tab
        final headings = tabState.isOnReadmeTab
            ? readmeHeadings
            : <({String text, String id})>[];
        if (headings.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Text(
              'No headings available',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          );
        }
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: headings.asMap().entries.map((entry) {
              final index = entry.key;
              final heading =
                  entry.value as ({String id, int level, String text});
              final isLast = index == headings.length - 1;
              final indent = (heading.level - 1) * 16.0;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (readmeStateKey.currentState != null) {
                      readmeStateKey.currentState!.scrollToAnchor(heading.id);
                    }
                    onCollapse();
                  },
                  borderRadius: BorderRadius.only(
                    bottomLeft:
                        isLast ? const Radius.circular(14) : Radius.zero,
                    bottomRight:
                        isLast ? const Radius.circular(14) : Radius.zero,
                  ),
                  child: Container(
                    padding: EdgeInsets.only(
                      left: 16 + indent,
                      right: 16,
                      top: 12,
                      bottom: 12,
                    ),
                    decoration: BoxDecoration(
                      border: isLast
                          ? null
                          : Border(
                              bottom: BorderSide(
                                color: context.colorScheme.outline
                                    .withOpacity(0.1),
                                width: 0.5,
                              ),
                            ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          heading.level == 1
                              ? Octicons.number
                              : heading.level == 2
                                  ? Octicons.dot
                                  : heading.level == 3
                                      ? Icons.circle
                                      : Icons.fiber_manual_record,
                          size: heading.level <= 2 ? 16 : 12,
                          color: context.colorScheme.onSurfaceVariant
                              .withOpacity(0.7),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            heading.text,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: context.colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    ),
  );

  // Build "Pinned Issues" button
  final pinnedIssuesCount = repo.pinnedIssues?.totalCount ?? 0;
  final pinnedIssuesButton = filteredPinnedIssues.isNotEmpty
      ? ExpandableActionButton(
          icon: Octicons.pin,
          label: 'Pinned Issues',
          trailing: pinnedIssuesCount > 0
              ? buildModernCountBadge(context, pinnedIssuesCount)
              : null,
          enabled: pinnedIssuesCount > 0,
          visibilityState: tabState.isOnIssuesTab
              ? ActionButtonVisibilityState.both
              : ActionButtonVisibilityState.none,
          expandableWidgetBuilder: (onCollapse) => Builder(
            builder: (context) {
              final filteredIssues = filteredPinnedIssues;

              if (filteredIssues.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Text(
                    'No pinned issues available',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: filteredIssues.asMap().entries.map((entry) {
                    final index = entry.key;
                    final node = entry.value;
                    final issue = node.issue;
                    final issueModel = _convertPinnedIssueToIssueModel(issue);
                    final isLast = index == filteredIssues.length - 1;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          await AutoRouter.of(context).push(
                            issuePullScreenRoute(
                              PathData.fromURL(issue.url.toString()),
                            ),
                          );
                          onCollapse();
                        },
                        borderRadius: BorderRadius.only(
                          bottomLeft:
                              isLast ? const Radius.circular(14) : Radius.zero,
                          bottomRight:
                              isLast ? const Radius.circular(14) : Radius.zero,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: isLast
                                ? null
                                : Border(
                                    bottom: BorderSide(
                                      color: context.colorScheme.outline
                                          .withOpacity(0.1),
                                      width: 0.5,
                                    ),
                                  ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: issueModel.state == IssueState.OPEN
                                          ? Colors.green.withOpacity(0.12)
                                          : Colors.red.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          issueModel.state == IssueState.OPEN
                                              ? Octicons.issue_opened
                                              : Octicons.issue_closed,
                                          size: 12,
                                          color: issueModel.state ==
                                                  IssueState.OPEN
                                              ? Colors.green.shade700
                                              : Colors.red.shade700,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${issue.number}',
                                          style: context.textTheme.bodySmall
                                              ?.copyWith(
                                            color: issueModel.state ==
                                                    IssueState.OPEN
                                                ? Colors.green.shade700
                                                : Colors.red.shade700,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (issueModel.user?.login != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      issueModel.user!.login!,
                                      style:
                                          context.textTheme.bodySmall?.copyWith(
                                        color: context
                                            .colorScheme.onSurfaceVariant
                                            .withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                issue.title ?? 'Untitled',
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: context.colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (issueModel.labels != null &&
                                  issueModel.labels!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: issueModel.labels!
                                      .map((label) => IssueLabel(label))
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        )
      : MajorActionButton(
          icon: Octicons.pin,
          label: 'Pinned Issues',
          trailing: pinnedIssuesCount > 0
              ? buildModernCountBadge(context, pinnedIssuesCount)
              : null,
          enabled: false,
          visibilityState: tabState.isOnIssuesTab
              ? ActionButtonVisibilityState.both
              : ActionButtonVisibilityState.none,
          onTap: null,
        );

  // Build "New Issue" button
  final newIssueButton = hasTemplates
      ? ExpandableActionButton(
          icon: Octicons.plus,
          label: 'New Issue',
          isPositive: true,
          visibilityState: tabState.isOnIssuesTab
              ? ActionButtonVisibilityState.both
              : ActionButtonVisibilityState.expandedOnly,
          expandableWidgetBuilder: (onCollapse) => Builder(
            builder: (context) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...issueTemplates.asMap().entries.map((entry) {
                    final index = entry.key;
                    final template = entry.value;
                    final isLast = index == issueTemplates.length - 1;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          await AutoRouter.of(context).push(
                            NewIssueRoute(
                              owner: repo.owner.when(
                                user: (u) => u.login,
                                organization: (o) => o.login,
                                orElse: () => '',
                              ),
                              repo: repo.name,
                              template: template,
                            ),
                          );
                          onCollapse();
                        },
                        borderRadius: BorderRadius.only(
                          bottomLeft: isLast && issueTemplates.length == 1
                              ? const Radius.circular(14)
                              : Radius.zero,
                          bottomRight: isLast && issueTemplates.length == 1
                              ? const Radius.circular(14)
                              : Radius.zero,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: isLast
                                ? null
                                : Border(
                                    bottom: BorderSide(
                                      color: context.colorScheme.outline
                                          .withOpacity(0.1),
                                      width: 0.5,
                                    ),
                                  ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Octicons.file,
                                size: 18,
                                color: context.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  template.name,
                                  style: context.textTheme.bodyMedium?.copyWith(
                                    color: context.colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        await AutoRouter.of(context).push(
                          NewIssueRoute(
                            owner: repo.owner.when(
                              user: (u) => u.login,
                              organization: (o) => o.login,
                              orElse: () => '',
                            ),
                            repo: repo.name,
                          ),
                        );
                        onCollapse();
                      },
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Octicons.plus,
                              size: 18,
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Blank Issue',
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: context.colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        )
      : MajorActionButton(
          icon: Octicons.plus,
          label: 'New Issue',
          isPositive: true,
          visibilityState: tabState.isOnIssuesTab
              ? ActionButtonVisibilityState.both
              : ActionButtonVisibilityState.expandedOnly,
          onTap: () async {
            await AutoRouter.of(context).push(
              NewIssueRoute(
                owner: repo.owner.when(
                  user: (u) => u.login,
                  organization: (o) => o.login,
                  orElse: () => '',
                ),
                repo: repo.name,
              ),
            );
          },
        );

  // Build branch button (always add, use visibilityState for animation)
  final branchProvider =
      Provider.of<RepoBranchProvider>(context, listen: false);
  final currentBranchName = branchProvider.currentSHA;

  // Get committed date for current branch
  DateTime? currentBranchDate;

  // Check if current branch is the default branch
  final defaultBranchName = repo.defaultBranchRef?.name;
  if (currentBranchName == defaultBranchName && repo.defaultBranchRef != null) {
    // Use defaultBranchRef target for better performance
    print('Using defaultBranchRef for current branch: $currentBranchName');
    repo.defaultBranchRef!.target?.when(
      commit: (c) {
        currentBranchDate = c.committedDate;
        print('Default branch committedDate: $currentBranchDate');
      },
      orElse: () {
        print('Default branch target is not a commit');
      },
    );
  } else {
    // Search through branches list
    final edges = repo.refs?.edges?.toList() ?? [];
    final branches = edges
        .map((edge) => edge?.node)
        .whereType<GrepositoryInfoData_repository_refs_edges_node>()
        .toList();

    for (final branch in branches) {
      if (branch.name == currentBranchName) {
        print('Found branch in list: $currentBranchName');
        branch.target?.when(
          commit: (c) {
            currentBranchDate = c.committedDate;
            print('Branch committedDate: $currentBranchDate');
          },
          orElse: () {
            print('Branch target is not a commit');
          },
        );
        break;
      }
    }
  }

  print('Current branch date for subtitle: $currentBranchDate');

  final branchButton = ExpandableActionButton(
    icon: Octicons.git_branch,
    label: currentBranchName,
    subtitle: currentBranchDate != null
        ? currentBranchDate
            .toRelativeDate(shorten: false)
            .replaceAll(' ago', '')
        : null,
    visibilityState: (tabState.isOnCodeTab || tabState.isOnReadmeTab)
        ? ActionButtonVisibilityState.both
        : ActionButtonVisibilityState.none,
    expandableWidgetBuilder: (onCollapse) {
      return _BranchListExpandedWidget(
        repo: repo,
        currentBranchName: currentBranchName,
        onCollapse: onCollapse,
      );
    },
  );

  // Add prominent actions
  // Always add jumpToButton to maintain consistent list structure
  allActions.add(jumpToButton);
  allActions.add(pinnedIssuesButton);
  allActions.add(newIssueButton);
  allActions.add(branchButton);

  // Add minor actions (will appear in the row)
  allActions.addAll([
    MinorActionButton(
      icon: Octicons.file_code,
      label: repo.primaryLanguage?.name ?? 'Code',
      iconColor: () {
        final color = repo.primaryLanguage?.color;
        return color != null
            ? Color(int.parse(color.replaceFirst('#', '0xFF')))
            : null;
      }(),
      trailing: repo.diskUsage != null
          ? buildActionButtonTrailingSize(context, repo.diskUsage!)
          : null,
      visibilityState: tabState.isOnCodeTab
          ? ActionButtonVisibilityState.none
          : ActionButtonVisibilityState.both,
      onTap: () => tabController.openTab('Code'),
    ),
    MinorActionButton(
      icon: Octicons.issue_opened,
      label: 'Issues',
      trailing: repo.issues.totalCount > 0
          ? buildActionButtonTrailingCount(context, repo.issues.totalCount)
          : null,
      visibilityState: tabState.isOnIssuesTab
          ? ActionButtonVisibilityState.none
          : ActionButtonVisibilityState.both,
      onTap: () => tabController.openTab('Issues'),
    ),
    MinorActionButton(
      icon: Octicons.git_pull_request,
      label: 'Pull Requests',
      trailing: repo.issues.totalCount > 0
          ? buildActionButtonTrailingCount(context, repo.issues.totalCount)
          : null,
      visibilityState: tabState.isOnPullRequestsTab
          ? ActionButtonVisibilityState.none
          : ActionButtonVisibilityState.both,
      onTap: () => tabController.openTab('Pull Requests'),
    ),
    MinorActionButton(
      icon: Octicons.book,
      label: 'Readme',
      visibilityState: tabState.isOnReadmeTab
          ? ActionButtonVisibilityState.none
          : ActionButtonVisibilityState.expandedOnly,
      onTap: () => tabController.openTab('Readme'),
    ),
    MinorActionButton(
      icon: Octicons.kebab_horizontal,
      label: 'More',
      visibilityState: tabState.isOnMoreTab
          ? ActionButtonVisibilityState.none
          : ActionButtonVisibilityState.expandedOnly,
      onTap: () => tabController.openTab('More'),
    ),
  ]);

  return allActions;
}

/// Builds the action buttons section for the expanded header
Widget buildActionButtons(
  BuildContext context,
  GrepositoryInfoData_repository repo,
  TabState tabState,
  DynamicTabsController tabController, {
  AnimationController? expandAnimationController,
}) {
  final primaryActions = <ActionButtonData>[
    MinorActionButton(
      icon: Octicons.file_code,
      label: repo.primaryLanguage?.name ?? 'Code',
      iconColor: () {
        final color = repo.primaryLanguage?.color;
        return color != null
            ? Color(int.parse(color.replaceFirst('#', '0xFF')))
            : null;
      }(),
      trailing: repo.diskUsage != null
          ? buildActionButtonTrailingSize(context, repo.diskUsage!)
          : null,
      actionType: ActionButtonActionType.tab,
      visibilityState: tabState.isOnCodeTab
          ? ActionButtonVisibilityState.none
          : ActionButtonVisibilityState.both,
      onTap: () => tabController.openTab('Code'),
    ),
    MinorActionButton(
      icon: Octicons.issue_opened,
      label: 'Issues',
      trailing: repo.issues.totalCount > 0
          ? buildActionButtonTrailingCount(context, repo.issues.totalCount)
          : null,
      actionType: ActionButtonActionType.tab,
      visibilityState: tabState.isOnIssuesTab
          ? ActionButtonVisibilityState.none
          : ActionButtonVisibilityState.both,
      onTap: () => tabController.openTab('Issues'),
    ),
    MinorActionButton(
      icon: Octicons.git_pull_request,
      label: 'Pull Requests',
      trailing: repo.issues.totalCount > 0
          ? buildActionButtonTrailingCount(context, repo.issues.totalCount)
          : null,
      actionType: ActionButtonActionType.tab,
      visibilityState: tabState.isOnPullRequestsTab
          ? ActionButtonVisibilityState.none
          : ActionButtonVisibilityState.both,
      onTap: () => tabController.openTab('Pull Requests'),
    ),
    MinorActionButton(
      icon: Icons.menu_rounded,
      label: 'More',
      actionType: ActionButtonActionType.tab,
      visibilityState: tabState.isOnMoreTab
          ? ActionButtonVisibilityState.none
          : ActionButtonVisibilityState.expandedOnly,
      onTap: () => tabController.openTab('More'),
    ),
  ];

  final secondaryActions = <ActionButtonData>[];

  return CollapsibleActionButtons(
    primaryActions: primaryActions,
    secondaryActions: secondaryActions,
    actionCardBuilder: (context, action) => buildAppBarActionCard(
      context,
      action,
      iconSize: 16,
      padding: const EdgeInsets.all(10),
    ),
    visibilityConfig: const ActionButtonsVisibilityConfig(),
    onExpandChanged: expandAnimationController != null
        ? (isExpanded) {
            if (isExpanded) {
              expandAnimationController.forward();
            } else {
              expandAnimationController.reverse();
            }
          }
        : null,
  );
}

// Helper function for building branch list items
Widget _buildBranchListItem(
  BuildContext context,
  ScrollWrapperBuilderData<RepoBranchListItemModel> data,
  VoidCallback onCollapse,
  GrepositoryInfoData_repository repo,
) {
  final currentBranch =
      Provider.of<RepoBranchProvider>(context, listen: false).currentSHA;
  final isDefault = repo.defaultBranchRef?.name == data.item.name;

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () async {
        await Provider.of<RepoBranchProvider>(context, listen: false)
            .setBranch(data.item.name!);
        onCollapse();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: data.item.name == currentBranch
              ? context.colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Octicons.git_branch,
              size: 18,
              color: data.item.name == currentBranch
                  ? context.colorScheme.primary
                  : context.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                data.item.name!,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: data.item.name == currentBranch
                      ? context.colorScheme.primary
                      : context.colorScheme.onSurface,
                  fontWeight: data.item.name == currentBranch
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isDefault)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Default',
                    style: context.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

// Helper function for building branch list items in the bottom sheet
Widget _buildBranchListItemForSheet(
  final ScrollWrapperBuilderData<RepoBranchListItemModel> data,
  final String currentBranch,
  final BuildContext context,
) {
  final repo = Provider.of<RepositoryProvider>(
    context,
    listen: false,
  ).data;
  final isDefault = repo.defaultBranchRef?.name == data.item.name;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Flexible(
          child: Row(
            children: <Widget>[
              const Icon(Octicons.git_branch),
              const SizedBox(
                width: 8,
              ),
              Flexible(
                child: Text(
                  data.item.name!,
                  style: TextStyle(
                    fontWeight: data.item.name == currentBranch
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
        Visibility(
          visible: isDefault,
          replacement: Container(),
          child: Text(
            'Default',
            style: context.textTheme.bodySmall,
          ),
        ),
      ],
    ),
  );
}

// Branch list expanded widget with search and pagination
class _BranchListExpandedWidget extends StatefulWidget {
  const _BranchListExpandedWidget({
    required this.repo,
    required this.currentBranchName,
    required this.onCollapse,
  });

  final GrepositoryInfoData_repository repo;
  final String currentBranchName;
  final VoidCallback onCollapse;

  @override
  State<_BranchListExpandedWidget> createState() =>
      _BranchListExpandedWidgetState();
}

class _BranchListExpandedWidgetState extends State<_BranchListExpandedWidget> {
  Future<void> changeBranch(String branch) async {
    await Provider.of<RepoBranchProvider>(
      context,
      listen: false,
    ).setBranch(branch);
    widget.onCollapse();
  }

  void _showAllBranches() {
    final repo = Provider.of<RepositoryProvider>(
      context,
      listen: false,
    ).data;
    final ownerLogin = repo.owner.when(
      user: (u) => u.login,
      organization: (o) => o.login,
      orElse: () => '',
    );

    final searchQueryNotifier = ValueNotifier<String>('');

    showScrollableBottomSheet<GbranchesListData_repository_refs_edges>(
      context,
      headerBuilder: (context, setState) => _BranchesBottomSheetHeader(
        repo: widget.repo,
        currentBranchName: widget.currentBranchName,
        owner: ownerLogin,
        repoName: repo.name,
        searchQueryNotifier: searchQueryNotifier,
      ),
      scrollableBodyBuilder: (context, setState, scrollController) =>
          _BranchesBottomSheetBody(
        repo: widget.repo,
        currentBranchName: widget.currentBranchName,
        owner: ownerLogin,
        repoName: repo.name,
        scrollController: scrollController,
        searchQueryNotifier: searchQueryNotifier,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final edges = widget.repo.refs?.edges?.toList() ?? [];
    final branches = edges
        .map((edge) => edge?.node)
        .whereType<GrepositoryInfoData_repository_refs_edges_node>()
        .toList();
    final hasMoreBranches = widget.repo.refs?.pageInfo?.hasNextPage ?? false;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Branch list from repo data
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: branches.asMap().entries.map((entry) {
                  final index = entry.key;
                  final branch = entry.value;
                  final branchName = branch.name;
                  final isCurrent = branchName == widget.currentBranchName;
                  final isDefault =
                      widget.repo.defaultBranchRef?.name == branchName;
                  final isProtected = branch.branchProtectionRule != null;

                  // Get committed date from target
                  DateTime? committedDate;
                  print(
                      'Expandable - Branch: $branchName, target: ${branch.target}, typename: ${branch.target?.G__typename}');
                  branch.target?.when(
                    commit: (c) {
                      committedDate = c.committedDate;
                      print(
                          'Expandable - Branch: $branchName, committedDate: $committedDate');
                    },
                    orElse: () {
                      print(
                          'Expandable - Branch: $branchName, target is not a commit, typename was: ${branch.target?.G__typename}');
                    },
                  );

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => changeBranch(branchName),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? context.colorScheme.primaryContainer
                                      .withOpacity(0.3)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: isCurrent
                                  ? Border.all(
                                      color: context.colorScheme.primary
                                          .withOpacity(0.3),
                                      width: 1,
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? context.colorScheme.primary
                                            .withOpacity(0.1)
                                        : context
                                            .colorScheme.surfaceContainerHighest
                                            .withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Octicons.git_branch,
                                    size: 16,
                                    color: isCurrent
                                        ? context.colorScheme.primary
                                        : context.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              branchName,
                                              style: context
                                                  .textTheme.bodyMedium
                                                  ?.copyWith(
                                                color: isCurrent
                                                    ? context
                                                        .colorScheme.primary
                                                    : context
                                                        .colorScheme.onSurface,
                                                fontWeight: isCurrent
                                                    ? FontWeight.w600
                                                    : FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isProtected) ...[
                                            Icon(
                                              Octicons.lock,
                                              size: 14,
                                              color: context
                                                  .colorScheme.onSurfaceVariant
                                                  .withOpacity(0.7),
                                            ),
                                            const SizedBox(width: 6),
                                          ],
                                          if (isDefault) ...[
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: context.colorScheme
                                                    .secondaryContainer,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                'Default',
                                                style: context
                                                    .textTheme.labelSmall
                                                    ?.copyWith(
                                                  color: context.colorScheme
                                                      .onSecondaryContainer,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (committedDate != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          committedDate.toRelativeDate(
                                              shorten: false),
                                          style: context.textTheme.bodySmall
                                              ?.copyWith(
                                            color: context
                                                .colorScheme.onSurfaceVariant
                                                .withOpacity(0.7),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (index < branches.length - 1)
                        Divider(
                          height: 1,
                          thickness: 1,
                          indent: 48,
                          endIndent: 16,
                          color: context.colorScheme.outline.withOpacity(0.1),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          // Show all button (only if there are more branches)
          if (hasMoreBranches)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: TextButton(
                onPressed: _showAllBranches,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 36),
                ),
                child: Text(
                  'Show all',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Bottom sheet header with search bar
class _BranchesBottomSheetHeader extends StatefulWidget {
  const _BranchesBottomSheetHeader({
    required this.repo,
    required this.currentBranchName,
    required this.owner,
    required this.repoName,
    required this.searchQueryNotifier,
  });

  final GrepositoryInfoData_repository repo;
  final String currentBranchName;
  final String owner;
  final String repoName;
  final ValueNotifier<String> searchQueryNotifier;

  @override
  State<_BranchesBottomSheetHeader> createState() =>
      _BranchesBottomSheetHeaderState();
}

class _BranchesBottomSheetHeaderState
    extends State<_BranchesBottomSheetHeader> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Branches',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.colorScheme.outline.withOpacity(0.12),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: context.textTheme.bodyMedium?.copyWith(
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'Search branches...',
                hintStyle: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant.withOpacity(0.6),
                  fontSize: 15,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: context.colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
                suffixIcon: widget.searchQueryNotifier.value.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          size: 18,
                          color: context.colorScheme.onSurfaceVariant
                              .withOpacity(0.7),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          widget.searchQueryNotifier.value = '';
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                filled: true,
                fillColor: Colors.transparent,
              ),
              onChanged: (value) {
                widget.searchQueryNotifier.value = value.toLowerCase();
              },
            ),
          ),
        ),
      ],
    );
  }
}

// Bottom sheet body with InfiniteScrollWrapper
class _BranchesBottomSheetBody extends StatefulWidget {
  const _BranchesBottomSheetBody({
    required this.repo,
    required this.currentBranchName,
    required this.owner,
    required this.repoName,
    required this.scrollController,
    required this.searchQueryNotifier,
  });

  final GrepositoryInfoData_repository repo;
  final String currentBranchName;
  final String owner;
  final String repoName;
  final ScrollController scrollController;
  final ValueNotifier<String> searchQueryNotifier;

  @override
  State<_BranchesBottomSheetBody> createState() =>
      _BranchesBottomSheetBodyState();
}

class _BranchesBottomSheetBodyState extends State<_BranchesBottomSheetBody> {
  String? _lastCursor;
  String _searchQuery = '';
  late final InfiniteScrollWrapperController _controller;

  @override
  void initState() {
    super.initState();
    _controller = InfiniteScrollWrapperController();
    _searchQuery = widget.searchQueryNotifier.value;
    widget.searchQueryNotifier.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    widget.searchQueryNotifier.removeListener(_onSearchChanged);
    super.dispose();
  }

  void _onSearchChanged() {
    final newQuery = widget.searchQueryNotifier.value;
    // Reset cursor when search query changes to start from beginning
    if (_searchQuery != newQuery) {
      _lastCursor = null;
    }
    setState(() {
      _searchQuery = newQuery;
    });
    // Refresh the list when search query changes
    _controller.refresh();
  }

  Future<void> changeBranch(String branch) async {
    await Provider.of<RepoBranchProvider>(
      context,
      listen: false,
    ).setBranch(branch);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return InfiniteScrollWrapper<GbranchesListData_repository_refs_edges>(
      controller: _controller,
      scrollController: widget.scrollController,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 1,
        indent: 48,
        endIndent: 16,
        color: context.colorScheme.outline.withOpacity(0.1),
      ),
      future: (data) async {
        // For cursor-based pagination, reset cursor on refresh or when search changes
        if (data.refresh) {
          _lastCursor = null;
        }

        // Use cursor from last item (edge) if available
        final cursor = data.lastItem?.cursor ?? _lastCursor;

        // Use search query for server-side filtering
        final searchQuery = _searchQuery.isEmpty ? null : _searchQuery;

        final result = await RepositoryServices.fetchBranchListGQL(
          owner: widget.owner,
          repo: widget.repoName,
          first: data.pageSize,
          after: cursor,
          query: searchQuery,
          refresh: data.refresh,
        );

        // Store cursor from last edge for next page
        if (result.isNotEmpty) {
          _lastCursor = result.last.cursor;
        }

        return result;
      },
      builder: (context, data) {
        final edge = data.item;
        final branch = edge.node;
        if (branch == null) return const SizedBox.shrink();
        final branchName = branch.name;
        final isCurrent = branchName == widget.currentBranchName;
        final isDefault = widget.repo.defaultBranchRef?.name == branchName;
        final isProtected = branch.branchProtectionRule != null;

        // Get committed date from target
        DateTime? committedDate;
        print(
            'BottomSheet - Branch: $branchName, target: ${branch.target}, typename: ${branch.target?.G__typename}');
        branch.target?.when(
          commit: (c) {
            committedDate = c.committedDate;
            print(
                'BottomSheet - Branch: $branchName, committedDate: $committedDate');
          },
          orElse: () {
            print(
                'BottomSheet - Branch: $branchName, target is not a commit, typename was: ${branch.target?.G__typename}');
          },
        );

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => changeBranch(branchName),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: isCurrent
                    ? context.colorScheme.primaryContainer.withOpacity(0.3)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isCurrent
                    ? Border.all(
                        color: context.colorScheme.primary.withOpacity(0.3),
                        width: 1,
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? context.colorScheme.primary.withOpacity(0.1)
                          : context.colorScheme.surfaceContainerHighest
                              .withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Octicons.git_branch,
                      size: 18,
                      color: isCurrent
                          ? context.colorScheme.primary
                          : context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                branchName,
                                style: context.textTheme.bodyLarge?.copyWith(
                                  color: isCurrent
                                      ? context.colorScheme.primary
                                      : context.colorScheme.onSurface,
                                  fontWeight: isCurrent
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isProtected) ...[
                              Icon(
                                Octicons.lock,
                                size: 16,
                                color: context.colorScheme.onSurfaceVariant
                                    .withOpacity(0.7),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (isDefault) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: context.colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Default',
                                  style: context.textTheme.labelSmall?.copyWith(
                                    color: context
                                        .colorScheme.onSecondaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (committedDate != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            committedDate.toRelativeDate(shorten: false),
                            style: context.textTheme.bodySmall?.copyWith(
                              color: context.colorScheme.onSurfaceVariant
                                  .withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      pageSize: 10,
      padding: const EdgeInsets.symmetric(vertical: 4),
    );
  }
}

// Helper functions for converting GraphQL data to models

IssueState? _convertGraphQLStateToIssueState(_i2.GIssueState? state) {
  if (state == null) return null;
  if (state == _i2.GIssueState.OPEN) {
    return IssueState.OPEN;
  } else if (state == _i2.GIssueState.CLOSED) {
    return IssueState.CLOSED;
  }
  return null;
}

UserInfoModel? _convertGraphQLAuthorToUserInfoModel(
    GrepositoryInfoData_repository_pinnedIssues_nodes_issue_author? author) {
  if (author == null) return null;
  return UserInfoModel(
    login: author.login,
    avatarUrl: author.avatarUrl.toString(),
  );
}

List<Label> _convertGraphQLLabelsToLabels(
    GrepositoryInfoData_repository_pinnedIssues_nodes_issue_labels? labels) {
  if (labels == null || labels.nodes == null) return [];
  return labels.nodes!
      .whereType<
          GrepositoryInfoData_repository_pinnedIssues_nodes_issue_labels_nodes>()
      .map((label) => Label(
            name: label.name,
            color: label.color,
          ))
      .toList();
}

IssueModel _convertPinnedIssueToIssueModel(
  GrepositoryInfoData_repository_pinnedIssues_nodes_issue issue,
) {
  return IssueModel(
    url: issue.url.toString(),
    number: issue.number,
    title: issue.title,
    state: _convertGraphQLStateToIssueState(issue.state),
    user: _convertGraphQLAuthorToUserInfoModel(issue.author),
    labels: _convertGraphQLLabelsToLabels(issue.labels),
    comments: 0,
    createdAt: null,
    closedAt: null,
    pullRequest: null,
  );
}
