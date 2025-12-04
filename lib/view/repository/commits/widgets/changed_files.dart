import 'package:diohub/common/misc/changed_files_list_card.dart';
import 'package:diohub/models/commits/commit_model.dart';
import 'package:diohub/providers/commits/commit_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChangedFiles extends StatefulWidget {
  const ChangedFiles({super.key});

  @override
  ChangedFilesState createState() => ChangedFilesState();
}

class ChangedFilesState extends State<ChangedFiles> {
  @override
  Widget build(final BuildContext context) {
    final provider = Provider.of<CommitProvider>(context);
    final commit = provider.data;
    final List<FileElement>? files = provider.files;
    
    if (files == null || files.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No changed files available'),
        ),
      );
    }
    
    return ListView(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Showing ${files.length} changed files with ${commit.additions} additions and ${commit.deletions} deletions.',
            textAlign: TextAlign.center,
          ),
        ),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: files.length,
          separatorBuilder: (final BuildContext context, final int index) =>
              const SizedBox(
            height: 12,
          ),
          itemBuilder: (final BuildContext context, final int index) =>
              ChangedFilesListCard(files[index]),
        ),
      ],
    );
  }
}
