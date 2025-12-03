import 'package:diohub/common/issues/issue_label.dart';
import 'package:diohub/common/misc/editable_text.dart';
import 'package:diohub/common/misc/reaction_bar.dart';
import 'package:diohub/common/markdown_view/markdown_body.dart';
import 'package:diohub/common/wrappers/editing_wrapper.dart';
import 'package:diohub/graphql/queries/issues_pulls/__generated__/timeline.data.gql.dart';
import 'package:diohub/utils/markdown_to_html.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

class AboutTab extends StatelessWidget {
  const AboutTab({
    required this.bodyHTML,
    required this.body,
    required this.reactionGroups,
    required this.viewerCanReact,
    required this.title,
    required this.titleEditingController,
    required this.labels,
    required this.labelsEditingController,
    super.key,
  });

  final String bodyHTML;
  final String body;
  final List<GreactionGroups> reactionGroups;
  final bool viewerCanReact;
  final String title;
  final EditingController<String> titleEditingController;
  final List<Glabel?> labels;
  final EditingController<List<Glabel?>> labelsEditingController;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Builder(
        builder: (BuildContext context) {
          return CustomScrollView(
            key: PageStorageKey<String>('About'),
            slivers: <Widget>[
              SliverOverlapInjector(
                handle:
                    NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Labels
                      EditWidget<List<Glabel?>>(
                        editingController: labelsEditingController,
                        builder: (
                          final BuildContext context,
                          final EditingData<List<Glabel?>> data,
                        ) {
                          return Row(
                            children: [
                              if (data.editingController.currentValue.isEmpty)
                                Text(
                                  'No Labels',
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: context.colorScheme.onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                              else
                                Expanded(
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: data
                                        .editingController.currentValue
                                        .map((final Glabel? e) =>
                                            IssueLabel.gql(e!))
                                        .toList(),
                                  ),
                                ),
                              data.tools,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Title
                      EditableTextItem(
                        titleEditingController,
                        builder: (final BuildContext context,
                                final String? newValue) =>
                            MarkdownBody(
                          newValue != null ? mdToHtml(newValue) : title,
                          textStyle: context.textTheme.headlineSmall,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Reactions
                      ReactionBar(
                        reactionGroups,
                        viewerCanReact: viewerCanReact,
                      ),
                      const SizedBox(height: 16),
                      // Description
                      _DescriptionSection(
                        bodyHTML: bodyHTML,
                        body: body,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DescriptionSection extends StatefulWidget {
  const _DescriptionSection({
    required this.bodyHTML,
    required this.body,
  });

  final String bodyHTML;
  final String body;

  @override
  State<_DescriptionSection> createState() => _DescriptionSectionState();
}

class _DescriptionSectionState extends State<_DescriptionSection> {
  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      widget.bodyHTML,
      textStyle: context.textTheme.bodyMedium,
    );
  }
}
