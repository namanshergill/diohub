import 'package:diohub/models/repositories/repository_model.dart';
import 'package:diohub/utils/markdown_emoji.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

class AboutRepository extends StatefulWidget {
  const AboutRepository(this.repo, {required this.onTabOpened, super.key});

  final RepositoryModel repo;
  final ValueChanged<String> onTabOpened;

  @override
  AboutRepositoryState createState() => AboutRepositoryState();
}

class AboutRepositoryState extends State<AboutRepository> {
  @override
  Widget build(final BuildContext context) => SafeArea(
        top: false,
        bottom: false,
        child: Builder(
          builder: (BuildContext context) {
            return CustomScrollView(
              key: const PageStorageKey<String>('About'),
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
                        // Description only
                        if (widget.repo.description != null)
                          Text(
                            emoteText(widget.repo.description!),
                            style: context.textTheme.bodyMedium,
                          )
                        else
                          Text(
                            'No description provided.',
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: context.colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
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

