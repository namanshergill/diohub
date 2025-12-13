import 'package:auto_route/auto_route.dart';
import 'package:diohub/adapters/deep_linking_handler.dart';
import 'package:diohub/common/markdown_view/markdown_body.dart';
import 'package:diohub/common/misc/custom_expand_tile.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/wrappers/loading_wrapper.dart';
import 'package:diohub/graphql/queries/repositories/__generated__/repo_info.data.gql.dart';
import 'package:diohub/models/issues/issue_model.dart';
import 'package:diohub/routes/router.dart';
import 'package:diohub/services/issues/issues_service.dart';
import 'package:diohub/style/text_field_themes.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/issues_pulls/issue_pull_screen.dart';
import 'package:flutter/material.dart';
import 'package:markdown_editable_textinput/markdown_text_input.dart';

@RoutePage()
class NewIssueScreen extends StatefulWidget {
  const NewIssueScreen({
    required this.repo,
    required this.owner,
    super.key,
    this.template,
  });

  final GrepositoryInfoData_repository_issueTemplates? template;
  final String owner;
  final String repo;

  @override
  NewIssueScreenState createState() => NewIssueScreenState();
}

class NewIssueScreenState extends State<NewIssueScreen> {
  bool expanded = false;
  bool markdownView = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController controller = TextEditingController();
  String comment = '';
  PageStatus status = PageStatus.loaded;

  @override
  void initState() {
    if (widget.template?.body != null) {
      comment = widget.template!.body!;
    }
    if (widget.template?.title != null) {
      controller.text = widget.template!.title!;
    }
    super.initState();
  }

  Future<void> createIssue() async {
    final StackRouter router = autoRoute(context);
    try {
      setState(() {
        status = PageStatus.loading;
      });
      final IssueModel res = await IssuesService.createIssue(
        title: controller.text,
        body: comment,
        owner: widget.owner,
        repo: widget.repo,
      );
      await router.replace(issuePullScreenRoute(PathData.fromURL(res.url!)));
      // setState(() {
      //   status = PageStatus.loaded;
      // });
    } catch (e) {
      setState(() {
        status = PageStatus.error;
      });
    }
  }

  @override
  Widget build(final BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'New Issue',
                // style: TextStyle(12),
              ),
              Text(
                '${widget.owner}/${widget.repo}',
                style: context.textTheme.bodySmall?.asBold(),
              ),
            ],
          ),
          actions: <Widget>[
            IconButton(
              onPressed: comment.isNotEmpty && status == PageStatus.loaded
                  ? () {
                      setState(() {
                        markdownView = !markdownView;
                      });
                    }
                  : null,
              icon: const Icon(Icons.remove_red_eye_rounded),
              // disabledColor: Provider.of<PaletteSettings>(context)
              //     .currentSetting
              //     .faded3
              //     .withOpacity(0.5),
              // color: markdownView
              //     ? Provider.of<PaletteSettings>(context)
              //         .currentSetting
              //         .baseElements
              //     : Provider.of<PaletteSettings>(context).currentSetting.faded3,
            ),
            IconButton(
              onPressed: status == PageStatus.loaded
                  ? () async {
                      if (_formKey.currentState!.validate()) {
                        await createIssue();
                      }
                    }
                  : null,
              // disabledColor: Provider.of<PaletteSettings>(context)
              //     .currentSetting
              //     .faded3
              //     .withOpacity(0.5),
              icon: const Icon(
                Icons.add,
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: LoadingWrapper(
            status: status,
            loadingBuilder: (final BuildContext context) => const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                LoadingIndicator(),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Creating Issue'),
                ),
              ],
            ),
            builder: (final BuildContext context) => Padding(
              padding: const EdgeInsets.all(8),
              child: !markdownView
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SizedBox(
                          height: 8,
                        ),
                        if (widget.template != null)
                          Column(
                            children: <Widget>[
                              CustomExpandTile(
                                expanded: expanded,
                                title: Text(
                                  widget.template!.name,
                                  overflow:
                                      expanded ? null : TextOverflow.ellipsis,
                                  // style: AppThemeTextStyles.eventCardChildTitle(
                                  //   context,
                                  // ),
                                ),
                                onTap: () {
                                  setState(() {
                                    expanded = !expanded;
                                  });
                                },
                                child: Column(
                                  children: <Widget>[
                                    if (widget.template!.about != null)
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(widget.template!.about!),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                            ],
                          ),
                        TextFormField(
                          decoration: inputDecoration(
                            context: context,
                            labelText: 'Title',
                          ),
                          controller: controller,
                          validator: (final String? value) {
                            if (value!.isEmpty) {
                              return 'Title cannot be empty!';
                            }
                            return null;
                          },
                          maxLines: 5,
                          minLines: 1,
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        Expanded(
                          child: MarkdownTextInput(
                            maxLines: 99,
                            initialValue: comment,
                            onTextChanged: (final String value) {
                              setState(() {
                                comment = value;
                              });
                            },
                            label: 'Leave a comment',
                            boxDecoration: const BoxDecoration(
                                // color: Provider.of<PaletteSettings>(context)
                                //     .currentSetting
                                //     .secondary,
                                // borderRadius: medBorderRadius,
                                ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SizedBox(
                          height: 8,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            controller.text.isNotEmpty
                                ? controller.text
                                : 'No title yet.',
                            // style: AppThemeTextStyles.appBarTitle(context),
                          ),
                        ),
                        const Divider(),
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                                // color: Provider.of<PaletteSettings>(context)
                                //     .currentSetting
                                //     .secondary,
                                // borderRadius: medBorderRadius,
                                ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: MarkdownRenderAPI(comment),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      );
}
