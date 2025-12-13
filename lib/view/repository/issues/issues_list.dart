import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/animations/slide_expanded_widget.dart';
import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/issues/issue_list_card.dart';
import 'package:diohub/common/misc/ink_pot.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/search_overlay/filters.dart';
import 'package:diohub/common/search_overlay/search_overlay.dart';
import 'package:diohub/common/wrappers/provider_loading_progress_wrapper.dart';
import 'package:diohub/common/wrappers/search_scroll_wrapper.dart';
import 'package:diohub/graphql/queries/repositories/__generated__/repo_info.data.gql.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_info.data.gql.dart';
import 'package:diohub/models/issues/issue_model.dart';
import 'package:diohub/providers/repository/repository_provider.dart';
import 'package:diohub/providers/users/current_user_provider.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/utils/http_to_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';

class IssuesList extends StatelessWidget {
  const IssuesList({super.key});

  @override
  Widget build(final BuildContext context) {
    final RepositoryProvider repo = Provider.of<RepositoryProvider>(context);
    final GviewerInfoData_viewer user =
        Provider.of<CurrentUserProvider>(context).data;
    return Stack(
      children: <Widget>[
        SearchScrollWrapper(
          SearchData(
            searchFilters: SearchFilters.issuesPulls(
              blacklist: <String>[SearchQueryStrings.type],
            ),
            defaultHiddenFilters: <String>[
              SearchQueries().type.toQueryString('issue'),
              SearchQueries().repo.toQueryString(repo.data.nameWithOwner),
            ],
          ),
          quickFilters: <String, String>{
            SearchQueries().assignee.toQueryString(user.login):
                'Assigned to you',
            SearchQueries().author.toQueryString(user.login): 'Your issues',
            SearchQueries().mentions.toQueryString(user.login): 'Mentions you',
          },
          quickOptions: <String, String>{
            SearchQueries().iS.toQueryString('open'): 'Open issues only',
          },
          showRepoNameOnIssues: false,
          searchBarMessage: "Search in ${repo.data.name}'s issues",
          searchHeroTag: 'repoIssueSearch',
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          filterFn: (final List<dynamic> data) {
            final List<IssueModel> filteredData = <IssueModel>[];
            for (final IssueModel item in data) {
              if (item.pullRequest == null) {
                filteredData.add(item);
              }
            }
            return filteredData;
          },
        ),
      ],
    );
  }
}

class IssueTemplateCard extends StatelessWidget {
  const IssueTemplateCard(this.template, {super.key, this.isBlank = false});

  final bool isBlank;
  final GrepositoryInfoData_repository_issueTemplates template;

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Card(
          child: InkPot(
            onTap: () async {
              final repo = context.read<RepositoryProvider>().data;
              await AutoRouter.of(context).push(
                NewIssueRoute(
                  owner: repo.owner.when(
                    user: (u) => u.login,
                    organization: (o) => o.login,
                    orElse: () => '',
                  ),
                  repo: repo.name,
                  template: isBlank ? null : template,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    template.name,
                    // style: AppThemeTextStyles.eventCardChildTitle(context),
                  ),
                  if (template.about != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(template.about!),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
}

class BlankIssueTemplate extends StatelessWidget {
  const BlankIssueTemplate({super.key});

  @override
  Widget build(final BuildContext context) => IssueTemplateCard(
        GrepositoryInfoData_repository_issueTemplates(
          (final GrepositoryInfoData_repository_issueTemplatesBuilder b) => b
            ..name = 'Don’t see your issue here?'
            ..about = 'Open a blank issue.',
        ),
        isBlank: true,
      );
}
