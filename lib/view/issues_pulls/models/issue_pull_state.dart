import 'package:diohub/graphql/__generated__/schema.schema.gql.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class IssuePullState {
  IssuePullState(this.state, {this.isDraft = false})
      : assert(
          state is GPullRequestState || state is GIssueState,
          'Not a valid state!',
        );

  final bool isDraft;
  final dynamic state;

  Icon icon({
    final double size = 16,
    final Color? color,
  }) =>
      Icon(
        iconData,
        size: size,
        color: color ?? this.color,
      );

  IconData get iconData {
    if (state == GIssueState.OPEN) {
      return Octicons.issue_opened;
    } else if (state == GIssueState.CLOSED) {
      return Octicons.issue_closed;
    } else if (state == GPullRequestState.OPEN ||
        state == GPullRequestState.CLOSED) {
      return Octicons.git_pull_request;
    } else if (state == GPullRequestState.MERGED) {
      return Octicons.git_merge;
    } else {
      throw UnimplementedError();
    }
  }

  Color get color {
    if (state == GIssueState.CLOSED || state == GPullRequestState.CLOSED) {
      return Colors.red;
    } else if (isDraft) {
      return Colors.grey;
    } else if (state == GIssueState.OPEN || state == GPullRequestState.OPEN) {
      return Colors.green;
    } else if (state == GPullRequestState.MERGED) {
      return Colors.deepPurple;
    } else {
      throw UnimplementedError();
    }
  }

  String get text {
    if (state == GIssueState.CLOSED || state == GPullRequestState.CLOSED) {
      return 'Closed';
    } else if (isDraft) {
      return 'Draft';
    } else if (state == GIssueState.OPEN || state == GPullRequestState.OPEN) {
      return 'Open';
    } else if (state == GPullRequestState.MERGED) {
      return 'Merged';
    } else {
      throw UnimplementedError();
    }
  }
}

