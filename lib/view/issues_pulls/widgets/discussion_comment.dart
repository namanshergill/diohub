import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:diohub/common/markdown_view/markdown_body.dart';
import 'package:diohub/common/misc/menu_button.dart';
import 'package:diohub/common/misc/nested_card_with_header.dart';
import 'package:diohub/common/misc/profile_banner.dart';
import 'package:diohub/common/misc/reaction_bar.dart';
import 'package:diohub/graphql/__generated__/schema.schema.gql.dart';
import 'package:diohub/graphql/queries/issues_pulls/__generated__/timeline.data.gql.dart';
import 'package:diohub/providers/issue_pulls/comment_provider.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/utils/copy_to_clipboard.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:share_plus/share_plus.dart';

class BaseComment extends StatefulWidget {
  const BaseComment({
    required this.onQuote,
    required this.isMinimized,
    required this.reactions,
    required this.viewerCanDelete,
    required this.viewerCanMinimize,
    required this.viewerCannotUpdateReasons,
    required this.viewerCanReact,
    required this.viewerCanUpdate,
    required this.viewerDidAuthor,
    required this.createdAt,
    required this.author,
    required this.body,
    required this.lastEditedAt,
    required this.bodyHTML,
    required this.authorAssociation,
    super.key,
    // this.headerPadding = const EdgeInsets.symmetric(horizontal: 16),
    // this.header,
    this.minimizedReason,
    this.leading,
    this.description,
    this.footer,
    this.footerPadding = const EdgeInsets.only(top: 8, left: 8, right: 8),
    required this.resourceUri,
  });

  final Gactor? author;
  final GCommentAuthorAssociation authorAssociation;
  final String body;
  final IconData? leading;
  final String? bodyHTML;
  final List<GreactionGroups> reactions;
  final DateTime? lastEditedAt;
  final DateTime createdAt;
  final bool isMinimized;
  final String? minimizedReason;
  final bool viewerCanMinimize;
  final bool viewerCanDelete;
  final bool viewerCanUpdate;
  final bool viewerDidAuthor;

  // TODO(namanshergill): Temp nullable
  final List<GCommentCannotUpdateReason>? viewerCannotUpdateReasons;
  final bool viewerCanReact;
  final Widget? footer;
  final String? description;

  // final Widget? header;
  final VoidCallback onQuote;

  // final EdgeInsets headerPadding;
  final EdgeInsets footerPadding;
  final Uri resourceUri;

  @override
  BaseCommentState createState() => BaseCommentState();
}

class BaseCommentState extends State<BaseComment> {
  void addQuote(final String data) {
    context.read<CommentProvider>().addQuote(widget.body);
  }

  @override
  Widget build(final BuildContext context) => MenuButton(
        itemBuilder: (final BuildContext context) => <PullDownMenuEntry>[
          PullDownMenuActionsRow.medium(
            items: <PullDownMenuItem>[
              PullDownMenuItem(
                onTap: () {},
                title: 'React (Placeholder)',
                iconWidget: AppReactionButton(
                  reactionGroups: widget.reactions,
                  loading: false,
                ),
              ),
            ],
          ),
          PullDownMenuActionsRow.medium(
            items: <PullDownMenuItem>[
              PullDownMenuItem(
                onTap: () async {
                  await Share.share(widget.resourceUri.toString());
                },
                title: 'Share',
                icon: Icons.adaptive.share_rounded,
              ),
              PullDownMenuItem(
                onTap: () {
                  addQuote(widget.body);
                  widget.onQuote();
                },
                title: 'Quote',
                icon: Icons.format_quote_rounded,
              ),
              PullDownMenuItem(
                onTap: () async => showDialog(
                  context: context,
                  builder: (final BuildContext cxt) =>
                      ListenableProvider<CommentProvider>.value(
                    value: Provider.of<CommentProvider>(context),
                    builder:
                        (final BuildContext context, final Widget? child) =>
                            SelectAndCopy(
                      widget.body,
                      onQuote: widget.onQuote,
                    ),
                  ),
                ),
                title: 'Select',
                icon: MdiIcons.clipboardSearch,
              ),
            ],
          ),
          const PullDownMenuDivider.large(),
          PullDownMenuHeader(
            leading: CachedNetworkImage(
              imageUrl: widget.author!.avatarUrl.toString(),
            ),
            title: widget.author!.login,
            subtitle: 'Go to profile',
            onTap: () async {
              await context.router.push(
                OtherUserProfileRoute(login: widget.author!.login),
              );
            },
          ).themed(context),
        ],
        builder: (
          final BuildContext context,
          final Widget button,
          final Future<void> Function() showMenu,
        ) =>
            NestedCardWithHeader(
          header: _buildHeaderContent(context),
          trailing: button,
          headerPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          childPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          spacing: 0,
          footer: _reactionsNotEmpty()
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: ReactionBar(
                    widget.reactions,
                    viewerCanReact: widget.viewerCanReact,
                  ),
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (widget.description != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    widget.description!,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                ),
              if (widget.bodyHTML?.isNotEmpty ?? false)
                MarkdownBody(
                  widget.bodyHTML!,
                  buildAsync: false,
                  style: MarkdownBodyStyle(
                    codeBlockStyle: MarkdownBodyCodeBlockStyle(
                      elevation: 3,
                      headerColor: context.colorScheme.surfaceVariant.asHint(),
                    ),
                  ),
                ),
              if (widget.footer != null)
                Padding(
                  padding: widget.footerPadding.copyWith(top: 8),
                  child: widget.footer,
                ),
            ],
          ),
        ),
      );

  bool _reactionsNotEmpty() => widget.reactions
      .where(
        (final GreactionGroups element) => element.reactors.totalCount > 0,
      )
      .isNotEmpty;

  Widget _buildHeaderContent(final BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // Leading icon
          if (widget.leading != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(
                widget.leading,
                size: 16,
                color: context.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),

          // Avatar
          ProfileTile.avatar(
            avatarUrl: widget.author?.avatarUrl.toString(),
            userLogin: widget.author?.login,
            padding: EdgeInsets.zero,
            size: 32,
          ),

          const SizedBox(width: 10),

          // Author info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        widget.author?.login ?? 'N/A',
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.authorAssociation !=
                            GCommentAuthorAssociation.MEMBER &&
                        widget.authorAssociation !=
                            GCommentAuthorAssociation.NONE)
                      Builder(
                        builder: (final BuildContext context) {
                          String? str;
                          Color? badgeColor;
                          if (widget.authorAssociation ==
                              GCommentAuthorAssociation.COLLABORATOR) {
                            str = 'Collaborator';
                            badgeColor = context.colorScheme.secondaryContainer;
                          } else if (widget.authorAssociation ==
                              GCommentAuthorAssociation.CONTRIBUTOR) {
                            str = 'Contributor';
                            badgeColor = context.colorScheme.tertiaryContainer;
                          } else if (widget.authorAssociation ==
                              GCommentAuthorAssociation.OWNER) {
                            str = 'Owner';
                            badgeColor = context.colorScheme.primaryContainer;
                          }
                          return Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor?.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              str ?? '',
                              style: context.textTheme.labelSmall?.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: context.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    text: getDate(widget.createdAt.toString()),
                    style: context.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: context.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    children: <InlineSpan>[
                      if (widget.lastEditedAt != null)
                        TextSpan(
                          text:
                              ' • Edited ${getDate(widget.lastEditedAt.toString())}',
                          style: context.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color:
                                context.colorScheme.onSurface.withOpacity(0.5),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

class SelectAndCopy extends StatefulWidget {
  const SelectAndCopy(this.data, {super.key, this.onQuote});

  final String data;
  final VoidCallback? onQuote;

  @override
  _SelectAndCopyState createState() => _SelectAndCopyState();
}

class _SelectAndCopyState extends State<SelectAndCopy> {
  String selectedText = '';

  @override
  Widget build(final BuildContext context) => AlertDialog(
        title: Text(
          'Select and copy',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            widget.data,
            style: Theme.of(context).textTheme.bodyMedium,
            onSelectionChanged: (
              final TextSelection selection,
              final SelectionChangedCause? cause,
            ) {
              setState(() {
                selectedText = selection.textInside(widget.data);
              });
            },
          ),
        ),
        actions: <Widget>[
          MaterialButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Text('Cancel'),
            ),
          ),
          MaterialButton(
            onPressed: selectedText.isNotEmpty
                ? () async {
                    await copyToClipboard(selectedText);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                : null,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Text('Copy'),
            ),
          ),
          if (widget.onQuote != null)
            MaterialButton(
              onPressed: selectedText.isNotEmpty
                  ? () {
                      context.read<CommentProvider>().addQuote(selectedText);
                      Navigator.pop(context);

                      widget.onQuote!();
                    }
                  : null,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Text('Quote'),
              ),
            ),
        ],
      );
}
