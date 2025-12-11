import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/misc/ink_pot.dart';
import 'package:diohub/common/misc/language_indicator.dart';
import 'package:diohub/common/misc/shimmer_widget.dart';
import 'package:diohub/common/wrappers/api_wrapper_widget.dart';
import 'package:diohub/models/repositories/repository_model.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/services/repositories/repo_services.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class PaddedBuilder {
  const PaddedBuilder({
    required this.padding,
  });

  final EdgeInsets padding;

  Widget applyPadding(final Widget child) => Padding(
        padding: padding,
        child: child,
      );
}

class RepositoryCard extends StatelessWidget {
  const RepositoryCard(
    this.repo, {
    // this.isThemed = true,
    this.branch,
    // this.padding = const EdgeInsets.symmetric(vertical: 8),
    super.key,
  });

  final RepositoryModel? repo;

  // final bool isThemed;
  final String? branch;

  // final EdgeInsets padding;

  static const PaddedBuilder paddedBuilderData = PaddedBuilder(
    padding: EdgeInsets.zero,
  );

  Column repoUnthemedWidget(final BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Repository name with icons
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Lock icon for private repos
              if (repo!.private!)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Octicons.lock,
                    size: 16,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              // Repository name
              Expanded(
                child: Text(
                  repo!.name!,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,

                        color: context.colorScheme.onSurface,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Fork indicator
              if (repo!.fork ?? false)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Octicons.repo_forked,
                        size: 12,
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Fork',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          // Description
          if (repo?.description != null) ...[
            const SizedBox(height: 8),
            Text(
              repo!.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                    // height: 1.4,
                  ),
            ),
          ],
          // Footer: Language, Stars
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              LanguageIndicator(
                repo!.language,
              ),
              if ((repo?.stargazersCount ?? 0) > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Octicons.star_fill,
                      size: 12,
                      color: context.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      repo!.stargazersCount!.toShortenedStr(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                context.colorScheme.onSurface.withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      );

  @override
  Widget build(final BuildContext context) => InkPot(
        onTap: () async {
          await pushToRepo(context);
        },
        child: repoUnthemedWidget(context),
      );

  Future<void> pushToRepo(final BuildContext context) async {
    await AutoRouter.of(context).push(
      RepositoryRoute(
        repositoryURL: repo!.url!,
        branch: branch,
      ),
    );
  }
}

class RepoCardLoading extends StatelessWidget {
  const RepoCardLoading(
    this.repoURL,
    this.repoName, {
    this.branch,
    this.refresh = false,
    super.key,
  });

  final String? repoURL;
  final String? repoName;

  // final double elevation;
  final bool refresh;
  final String? branch;

  @override
  Widget build(final BuildContext context) =>
      APIWrapper<RepositoryModel>.deferred(
        // fadeIntoView: false,
        apiCall: ({required final bool refresh}) async =>
            RepositoryServices.fetchRepository(repoURL!, refresh: refresh),
        loadingBuilder: (final BuildContext context) => buildLoading(),
        builder: (final BuildContext context, final RepositoryModel repo) =>
            RepositoryCard(repo, branch: branch),
      );

  Widget buildLoading() => RepositoryCard.paddedBuilderData.applyPadding(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              repoName!.split('/').last,
              // style: AppThemeTextStyles.eventCardChildTitle(context),
            ),
            const SizedBox(
              height: 8,
            ),
            ShimmerWidget.container(),
            const SizedBox(
              height: 4,
            ),
            ShimmerWidget.container(
              width: 200,
            ),
            const SizedBox(
              height: 16,
            ),
          ],
        ),
      );
}
