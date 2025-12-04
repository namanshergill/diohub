import 'package:diohub/common/misc/button.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/wrappers/infinite_scroll_wrapper.dart';
import 'package:diohub/providers/issue_pulls/comment_provider.dart';
import 'package:diohub/services/issues/issues_service.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/issues_pulls/widgets/comment_box.dart';
import 'package:diohub/view/issues_pulls/widgets/discussion_comment.dart';
import 'package:diohub/view/issues_pulls/widgets/timeline_item.dart';
import 'package:flutter/material.dart' hide DatePickerTheme;
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class IssuePullTimeline extends StatefulWidget {
  const IssuePullTimeline({
    required this.number,
    required this.owner,
    required this.repoName,
    // required this.initComment,
    required this.issueUrl,
    required this.isPull,
    this.commentsSince,
    this.pullNodeID,
    this.isLocked,
    // required this.nestedScrollViewController,
    this.createdAt,
    super.key,
  });

  // final ScrollController nestedScrollViewController;

  /// Show  comments since.
  final DateTime? commentsSince;
  final String repoName;
  final String owner;
  final String? pullNodeID;
  // final BaseComment initComment;
  final Uri issueUrl;
  final int number;
  final bool? isLocked;
  final bool isPull;
  final DateTime? createdAt;

  @override
  IssuePullTimelineState createState() => IssuePullTimelineState();
}

class IssuePullTimelineState extends State<IssuePullTimeline> {
  DateTime? commentsSince;

  InfiniteScrollWrapperController commentsSinceController =
      InfiniteScrollWrapperController();

  @override
  void initState() {
    commentsSince = widget.commentsSince;
    super.initState();
  }

  Future<void> openCommentSheet() async {
    await showCommentSheet(
      context,
      onSubmit: () async {
        await IssuesService.addComment(
          widget.issueUrl.toString(),
          context.read<CommentProvider>().data,
        );
        if (context.mounted) {
          context.read<CommentProvider>().clearData();
        }
        setState(() {
          commentsSince = DateTime.now();
          commentsSinceController.refresh();
        });
        return;
      },
      initialData: context.read<CommentProvider>().data,
      onChanged: (final String value) {
        Provider.of<CommentProvider>(context, listen: false).updateData(value);
      },
      owner: widget.owner,
      repoName: widget.repoName,
    );
  }

  @override
  Widget build(final BuildContext context) {
    // final theme = Provider.of<PaletteSettings>(context).currentSetting;

    final Widget header = commentsSince != null
        ? Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8),
                child: Button(
                  // color: Provider.of<PaletteSettings>(context)
                  //     .currentSetting
                  //     .secondary,
                  padding: const EdgeInsets.all(12),
                  onTap: () {
                    setState(() {
                      commentsSince = null;
                    });
                    commentsSinceController.refresh();
                  },
                  child: Column(
                    children: <Widget>[
                      Text(
                        'Showing timeline since ${DateFormat('d MMM yyyy').format(commentsSince!)}.',
                        textAlign: TextAlign.center,
                        style: context.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        'Load the whole timeline?',
                        textAlign: TextAlign.center,
                        style: context.textTheme.labelSmall,
                        ),
                    ],
                  ),
                ),
              ),
                //if (widget.initComment.createdAt.isAfter(
                // commentsSince!.subtract(const Duration(seconds: 30)),
              //))
                // PaddingWrap(
                //   // child: widget.initComment,
                //   child: Container(),
                // ),
            ],
          )
        : Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8),
                child: Button(
                  // color: Provider.of<PaletteSettings>(context)
                  //     .currentSetting
                  //     .secondary,
                  onTap: () async {
                    await DatePicker.showDateTimePicker(
                      context,
                      // theme: DatePickerTheme(
                      //   cancelStyle: TextStyle(
                      // color: Provider.of<PaletteSettings>(context)
                      //     .currentSetting
                      //     .baseElements,
                      // ),
                      // doneStyle: TextStyle(
                      // color: context.colorScheme.
                      //     .accent,
                      // ),
                      // itemStyle: TextStyle(
                      //   color: Provider.of<PaletteSettings>(context)
                      //       .currentSetting
                      //       .baseElements,
                      // ),
                      // backgroundColor: Provider.of<PaletteSettings>(context)
                      //     .currentSetting
                      //     .primary,
                      // ),
                      maxTime: DateTime.now(),
                      onConfirm: (final DateTime date) {
                        setState(() {
                          commentsSince = date;
                        });
                        commentsSinceController.refresh();
                      },
                      currentTime: widget.createdAt,
                    );
                  },
                  child: Text(
                    'Show timeline from a specific time?',
                    textAlign: TextAlign.center,
                    style: context.textTheme.labelSmall,
                  ),
                ),
              ),
              // const SizedBox(
              //   height: 16,
              // ),
            
            ],
          );
    return Stack(
      children: <Widget>[
        InfiniteScrollWrapper<dynamic>(
          future: (
            data,
          ) async =>
              IssuesService.getTimeline(
            repo: widget.repoName,
            after: data.lastItem?.cursor,
            number: widget.number,
            owner: widget.owner,
            refresh: data.refresh,
            since: commentsSince?.toUtc().subtract(const Duration(seconds: 30)),
          ).toAsyncList(),
          // scrollController: widget.nestedScrollViewController,
          controller: commentsSinceController,
          firstPageLoadingBuilder: (final BuildContext context) =>
              const LoadingIndicator(),
          // scrollController: widget.nestedScrollViewController,
          header: (final BuildContext context) => header,
          // topSpacing: 8,
          // separatorBuilder: (final BuildContext context, final int index) =>
          //     const Divider(
          //   height: 0,
          // ),
          builder: (
            final BuildContext context,
            final data,
          ) =>
              TimelineItem(
            data.item.node,
            pullNodeID: widget.pullNodeID,
            onQuote: openCommentSheet,
          ),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FloatingActionButton(
              onPressed: () async {
                await openCommentSheet();
              },
              child: const Icon(MdiIcons.commentPlus),
            ),
          ),
        ),
      ],
    );
  }
}
