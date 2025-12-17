// To parse this JSON data, do
//
//     final pullRequestModel = pullRequestModelFromJson(jsonString);
// ignore_for_file: type=lint

import 'dart:convert';

import 'package:diohub/models/issues/issue_model.dart';
import 'package:diohub/models/issues/issue_timeline_event_model.dart';
import 'package:diohub/models/users/user_info_model.dart';

class PullRequestModel {
  PullRequestModel(
      {this.url,
      this.id,
      this.nodeId,
      this.htmlUrl,
      this.diffUrl,
      this.patchUrl,
      this.issueUrl,
      this.number,
      this.state,
      this.locked,
      this.title,
      this.user,
      this.body,
      this.createdAt,
      this.updatedAt,
      this.closedAt,
      this.mergedAt,
      this.mergeCommitSha,
      this.assignee,
      this.assignees,
      this.requestedReviewers,
      this.requestedTeams,
      this.labels,
      this.milestone,
      this.draft,
      this.commitsUrl,
      this.reviewCommentsUrl,
      this.reviewCommentUrl,
      this.commentsUrl,
      this.statusesUrl,
      this.head,
      this.base,
      this.links,
      this.authorAssociation,
      this.autoMerge,
      this.activeLockReason,
      this.comments,
      this.deletions,
      this.additions,
      this.bodyHtml,
      this.commits,
      this.changedFiles,
      this.maintainerCanModify,
      this.mergeable,
      this.mergeableState,
      this.merged,
      this.mergedBy,
      this.rebaseable,
      this.reviewComments});

  String? url;
  int? id;
  String? nodeId;
  String? htmlUrl;
  String? diffUrl;
  String? patchUrl;
  String? issueUrl;
  int? number;
  String? bodyHtml;

  IssueState? state;
  bool? locked;
  String? title;
  UserInfoModel? user;
  String? body;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? closedAt;
  DateTime? mergedAt;
  String? mergeCommitSha;
  UserInfoModel? assignee;
  List<UserInfoModel>? assignees;
  List<UserInfoModel>? requestedReviewers;
  List<dynamic>? requestedTeams;
  List<Label>? labels;
  Milestone? milestone;
  bool? draft;
  String? commitsUrl;
  String? reviewCommentsUrl;
  String? reviewCommentUrl;
  String? commentsUrl;
  String? statusesUrl;
  Base? head;
  Base? base;
  Links? links;
  AuthorAssociation? authorAssociation;
  bool? autoMerge;
  String? activeLockReason;
  bool? merged;
  bool? mergeable;
  bool? rebaseable;
  String? mergeableState;
  UserInfoModel? mergedBy;
  int? comments;
  int? reviewComments;
  bool? maintainerCanModify;
  int? commits;
  int? additions;
  int? deletions;
  int? changedFiles;
  PullRequestModel copyWith({
    String? url,
    int? id,
    String? bodyHtml,
    String? nodeId,
    String? htmlUrl,
    String? diffUrl,
    String? patchUrl,
    String? issueUrl,
    int? number,
    IssueState? state,
    bool? locked,
    String? title,
    UserInfoModel? user,
    String? body,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? closedAt,
    DateTime? mergedAt,
    String? mergeCommitSha,
    UserInfoModel? assignee,
    List<UserInfoModel>? assignees,
    List<UserInfoModel>? requestedReviewers,
    List<dynamic>? requestedTeams,
    List<Label>? labels,
    Milestone? milestone,
    bool? draft,
    String? commitsUrl,
    String? reviewCommentsUrl,
    String? reviewCommentUrl,
    String? commentsUrl,
    String? statusesUrl,
    Base? head,
    Base? base,
    Links? links,
    AuthorAssociation? authorAssociation,
    dynamic autoMerge,
    dynamic activeLockReason,
  }) =>
      PullRequestModel(
        url: url ?? this.url,
        id: id ?? this.id,
        nodeId: nodeId ?? this.nodeId,
        htmlUrl: htmlUrl ?? this.htmlUrl,
        diffUrl: diffUrl ?? this.diffUrl,
        patchUrl: patchUrl ?? this.patchUrl,
        issueUrl: issueUrl ?? this.issueUrl,
        number: number ?? this.number,
        state: state ?? this.state,
        locked: locked ?? this.locked,
        title: title ?? this.title,
        user: user ?? this.user,
        body: body ?? this.body,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        closedAt: closedAt ?? this.closedAt,
        mergedAt: mergedAt ?? this.mergedAt,
        mergeCommitSha: mergeCommitSha ?? this.mergeCommitSha,
        assignee: assignee ?? this.assignee,
        assignees: assignees ?? this.assignees,
        requestedReviewers: requestedReviewers ?? this.requestedReviewers,
        requestedTeams: requestedTeams ?? this.requestedTeams,
        labels: labels ?? this.labels,
        milestone: milestone ?? this.milestone,
        draft: draft ?? this.draft,
        commitsUrl: commitsUrl ?? this.commitsUrl,
        reviewCommentsUrl: reviewCommentsUrl ?? this.reviewCommentsUrl,
        reviewCommentUrl: reviewCommentUrl ?? this.reviewCommentUrl,
        commentsUrl: commentsUrl ?? this.commentsUrl,
        statusesUrl: statusesUrl ?? this.statusesUrl,
        head: head ?? this.head,
        base: base ?? this.base,
        links: links ?? this.links,
        authorAssociation: authorAssociation ?? this.authorAssociation,
        autoMerge: autoMerge ?? this.autoMerge,
        activeLockReason: activeLockReason ?? this.activeLockReason,
      );

  factory PullRequestModel.fromRawJson(String str) =>
      PullRequestModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory PullRequestModel.fromJson(Map<String, dynamic> json) =>
      PullRequestModel(
        url: json["url"] == null ? null : json["url"],
        id: json["id"] == null ? null : json["id"],
        bodyHtml: json['body_html'],
        nodeId: json["node_id"] == null ? null : json["node_id"],
        htmlUrl: json["html_url"] == null ? null : json["html_url"],
        diffUrl: json["diff_url"] == null ? null : json["diff_url"],
        patchUrl: json["patch_url"] == null ? null : json["patch_url"],
        issueUrl: json["issue_url"] == null ? null : json["issue_url"],
        number: json["number"] == null ? null : json["number"],
        state: json["state"] == null ? null : stateValues.map[json["state"]],
        locked: json["locked"] == null ? null : json["locked"],
        title: json["title"] == null ? null : json["title"],
        user:
            json["user"] == null ? null : UserInfoModel.fromJson(json["user"]),
        body: json["body"] == null ? null : json["body"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
        closedAt: json["closed_at"] == null
            ? null
            : DateTime.parse(json["closed_at"]),
        mergedAt: json["merged_at"] == null
            ? null
            : DateTime.parse(json["merged_at"]),
        mergeCommitSha:
            json["merge_commit_sha"] == null ? null : json["merge_commit_sha"],
        assignee: json["assignee"] == null
            ? null
            : UserInfoModel.fromJson(json["assignee"]),
        assignees: json["assignees"] == null
            ? null
            : List<UserInfoModel>.from(
                json["assignees"].map((x) => UserInfoModel.fromJson(x))),
        requestedReviewers: json["requested_reviewers"] == null
            ? null
            : List<UserInfoModel>.from(json["requested_reviewers"]
                .map((x) => UserInfoModel.fromJson(x))),
        requestedTeams: json["requested_teams"] == null
            ? null
            : List<dynamic>.from(json["requested_teams"].map((x) => x)),
        labels: json["labels"] == null
            ? null
            : List<Label>.from(json["labels"].map((x) => Label.fromJson(x))),
        milestone: json["milestone"] == null
            ? null
            : Milestone.fromJson(json["milestone"]),
        draft: json["draft"] == null ? null : json["draft"],
        commitsUrl: json["commits_url"] == null ? null : json["commits_url"],
        reviewCommentsUrl: json["review_comments_url"] == null
            ? null
            : json["review_comments_url"],
        reviewCommentUrl: json["review_comment_url"] == null
            ? null
            : json["review_comment_url"],
        commentsUrl: json["comments_url"] == null ? null : json["comments_url"],
        statusesUrl: json["statuses_url"] == null ? null : json["statuses_url"],
        head: json["head"] == null ? null : Base.fromJson(json["head"]),
        base: json["base"] == null ? null : Base.fromJson(json["base"]),
        links: json["_links"] == null ? null : Links.fromJson(json["_links"]),
        authorAssociation: json["author_association"] == null
            ? null
            : authorAssociationValues.map[json["author_association"]],
        autoMerge:
            json["auto_merge"] is bool ? json["auto_merge"] as bool? : null,
        activeLockReason: json["active_lock_reason"],
        merged: json["merged"] == null ? null : json["merged"],
        mergeable: json["mergeable"],
        rebaseable: json["rebaseable"],
        mergeableState:
            json["mergeable_state"] == null ? null : json["mergeable_state"],
        mergedBy: json["merged_by"] == null
            ? null
            : UserInfoModel.fromJson(json["merged_by"]),
        comments: json["comments"] == null ? null : json["comments"],
        reviewComments:
            json["review_comments"] == null ? null : json["review_comments"],
        maintainerCanModify: json["maintainer_can_modify"] == null
            ? null
            : json["maintainer_can_modify"],
        commits: json["commits"] == null ? null : json["commits"],
        additions: json["additions"] == null ? null : json["additions"],
        deletions: json["deletions"] == null ? null : json["deletions"],
        changedFiles:
            json["changed_files"] == null ? null : json["changed_files"],
      );

  Map<String, dynamic> toJson() => {
        "url": url == null ? null : url,
        "id": id == null ? null : id,
        "node_id": nodeId == null ? null : nodeId,
        "html_url": htmlUrl == null ? null : htmlUrl,
        "diff_url": diffUrl == null ? null : diffUrl,
        "patch_url": patchUrl == null ? null : patchUrl,
        "issue_url": issueUrl == null ? null : issueUrl,
        "number": number == null ? null : number,
        "state": state == null ? null : stateValues.reverse![state!],
        "locked": locked == null ? null : locked,
        "title": title == null ? null : title,
        "user": user == null ? null : user!.toJson(),
        "body": body == null ? null : body,
        "created_at": createdAt == null ? null : createdAt!.toIso8601String(),
        "updated_at": updatedAt == null ? null : updatedAt!.toIso8601String(),
        "closed_at": closedAt == null ? null : closedAt!.toIso8601String(),
        "merged_at": mergedAt == null ? null : mergedAt!.toIso8601String(),
        "merge_commit_sha": mergeCommitSha == null ? null : mergeCommitSha,
        "assignee": assignee == null ? null : assignee!.toJson(),
        "assignees": assignees == null
            ? null
            : List<dynamic>.from(assignees!.map((x) => x.toJson())),
        "requested_reviewers": requestedReviewers == null
            ? null
            : List<dynamic>.from(requestedReviewers!.map((x) => x.toJson())),
        "requested_teams": requestedTeams == null
            ? null
            : List<dynamic>.from(requestedTeams!.map((x) => x)),
        "labels": labels == null
            ? null
            : List<dynamic>.from(labels!.map((x) => x.toJson())),
        "milestone": milestone!.toJson(),
        "draft": draft == null ? null : draft,
        "commits_url": commitsUrl == null ? null : commitsUrl,
        "review_comments_url":
            reviewCommentsUrl == null ? null : reviewCommentsUrl,
        "review_comment_url":
            reviewCommentUrl == null ? null : reviewCommentUrl,
        "comments_url": commentsUrl == null ? null : commentsUrl,
        "statuses_url": statusesUrl == null ? null : statusesUrl,
        "head": head == null ? null : head!.toJson(),
        "base": base == null ? null : base!.toJson(),
        "_links": links == null ? null : links!.toJson(),
        "author_association": authorAssociation == null
            ? null
            : authorAssociationValues.reverse![authorAssociation!],
        "auto_merge": autoMerge,
        "active_lock_reason": activeLockReason,
        "merged": merged == null ? null : merged,
        "mergeable": mergeable,
        "rebaseable": rebaseable,
        "mergeable_state": mergeableState == null ? null : mergeableState,
        "merged_by": mergedBy == null ? null : mergedBy!.toJson(),
        "comments": comments == null ? null : comments,
        "review_comments": reviewComments == null ? null : reviewComments,
        "maintainer_can_modify":
            maintainerCanModify == null ? null : maintainerCanModify,
        "commits": commits == null ? null : commits,
        "additions": additions == null ? null : additions,
        "deletions": deletions == null ? null : deletions,
        "changed_files": changedFiles == null ? null : changedFiles,
      };
}

class Base {
  Base({
    this.label,
    this.ref,
    this.sha,
    this.user,
    this.repo,
  });

  String? label;
  String? ref;
  String? sha;
  UserInfoModel? user;
  Repo? repo;

  Base copyWith({
    String? label,
    String? ref,
    String? sha,
    UserInfoModel? user,
    Repo? repo,
  }) =>
      Base(
        label: label ?? this.label,
        ref: ref ?? this.ref,
        sha: sha ?? this.sha,
        user: user ?? this.user,
        repo: repo ?? this.repo,
      );

  factory Base.fromRawJson(String str) => Base.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Base.fromJson(Map<String, dynamic> json) => Base(
        label: json["label"] == null ? null : json["label"],
        ref: json["ref"] == null ? null : json["ref"],
        sha: json["sha"] == null ? null : json["sha"],
        user:
            json["user"] == null ? null : UserInfoModel.fromJson(json["user"]),
        repo: json["repo"] == null ? null : Repo.fromJson(json["repo"]),
      );

  Map<String, dynamic> toJson() => {
        "label": label == null ? null : label,
        "ref": ref == null ? null : ref,
        "sha": sha == null ? null : sha,
        "user": user == null ? null : user!.toJson(),
        "repo": repo == null ? null : repo!.toJson(),
      };
}

class Repo {
  Repo({
    this.id,
    this.nodeId,
    this.name,
    this.fullName,
    this.private,
    this.owner,
    this.htmlUrl,
    this.description,
    this.fork,
    this.url,
    this.forksUrl,
    this.keysUrl,
    this.collaboratorsUrl,
    this.teamsUrl,
    this.hooksUrl,
    this.issueEventsUrl,
    this.eventsUrl,
    this.assigneesUrl,
    this.branchesUrl,
    this.tagsUrl,
    this.blobsUrl,
    this.gitTagsUrl,
    this.gitRefsUrl,
    this.treesUrl,
    this.statusesUrl,
    this.languagesUrl,
    this.stargazersUrl,
    this.contributorsUrl,
    this.subscribersUrl,
    this.subscriptionUrl,
    this.commitsUrl,
    this.gitCommitsUrl,
    this.commentsUrl,
    this.issueCommentUrl,
    this.contentsUrl,
    this.compareUrl,
    this.mergesUrl,
    this.archiveUrl,
    this.downloadsUrl,
    this.issuesUrl,
    this.pullsUrl,
    this.milestonesUrl,
    this.notificationsUrl,
    this.labelsUrl,
    this.releasesUrl,
    this.deploymentsUrl,
    this.createdAt,
    this.updatedAt,
    this.pushedAt,
    this.gitUrl,
    this.sshUrl,
    this.cloneUrl,
    this.svnUrl,
    this.homepage,
    this.size,
    this.stargazersCount,
    this.watchersCount,
    this.language,
    this.hasIssues,
    this.hasProjects,
    this.hasDownloads,
    this.hasWiki,
    this.hasPages,
    this.forksCount,
    this.mirrorUrl,
    this.archived,
    this.disabled,
    this.openIssuesCount,
    this.license,
    this.forks,
    this.openIssues,
    this.watchers,
    this.defaultBranch,
  });

  int? id;
  String? nodeId;
  String? name;
  String? fullName;
  bool? private;
  UserInfoModel? owner;
  String? htmlUrl;
  String? description;
  bool? fork;
  String? url;
  String? forksUrl;
  String? keysUrl;
  String? collaboratorsUrl;
  String? teamsUrl;
  String? hooksUrl;
  String? issueEventsUrl;
  String? eventsUrl;
  String? assigneesUrl;
  String? branchesUrl;
  String? tagsUrl;
  String? blobsUrl;
  String? gitTagsUrl;
  String? gitRefsUrl;
  String? treesUrl;
  String? statusesUrl;
  String? languagesUrl;
  String? stargazersUrl;
  String? contributorsUrl;
  String? subscribersUrl;
  String? subscriptionUrl;
  String? commitsUrl;
  String? gitCommitsUrl;
  String? commentsUrl;
  String? issueCommentUrl;
  String? contentsUrl;
  String? compareUrl;
  String? mergesUrl;
  String? archiveUrl;
  String? downloadsUrl;
  String? issuesUrl;
  String? pullsUrl;
  String? milestonesUrl;
  String? notificationsUrl;
  String? labelsUrl;
  String? releasesUrl;
  String? deploymentsUrl;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? pushedAt;
  String? gitUrl;
  String? sshUrl;
  String? cloneUrl;
  String? svnUrl;
  String? homepage;
  int? size;
  int? stargazersCount;
  int? watchersCount;
  String? language;
  bool? hasIssues;
  bool? hasProjects;
  bool? hasDownloads;
  bool? hasWiki;
  bool? hasPages;
  int? forksCount;
  dynamic mirrorUrl;
  bool? archived;
  bool? disabled;
  int? openIssuesCount;
  License? license;
  int? forks;
  int? openIssues;
  int? watchers;
  String? defaultBranch;

  Repo copyWith({
    int? id,
    String? nodeId,
    String? name,
    String? fullName,
    bool? private,
    UserInfoModel? owner,
    String? htmlUrl,
    String? description,
    bool? fork,
    String? url,
    String? forksUrl,
    String? keysUrl,
    String? collaboratorsUrl,
    String? teamsUrl,
    String? hooksUrl,
    String? issueEventsUrl,
    String? eventsUrl,
    String? assigneesUrl,
    String? branchesUrl,
    String? tagsUrl,
    String? blobsUrl,
    String? gitTagsUrl,
    String? gitRefsUrl,
    String? treesUrl,
    String? statusesUrl,
    String? languagesUrl,
    String? stargazersUrl,
    String? contributorsUrl,
    String? subscribersUrl,
    String? subscriptionUrl,
    String? commitsUrl,
    String? gitCommitsUrl,
    String? commentsUrl,
    String? issueCommentUrl,
    String? contentsUrl,
    String? compareUrl,
    String? mergesUrl,
    String? archiveUrl,
    String? downloadsUrl,
    String? issuesUrl,
    String? pullsUrl,
    String? milestonesUrl,
    String? notificationsUrl,
    String? labelsUrl,
    String? releasesUrl,
    String? deploymentsUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? pushedAt,
    String? gitUrl,
    String? sshUrl,
    String? cloneUrl,
    String? svnUrl,
    String? homepage,
    int? size,
    int? stargazersCount,
    int? watchersCount,
    String? language,
    bool? hasIssues,
    bool? hasProjects,
    bool? hasDownloads,
    bool? hasWiki,
    bool? hasPages,
    int? forksCount,
    dynamic mirrorUrl,
    bool? archived,
    bool? disabled,
    int? openIssuesCount,
    License? license,
    int? forks,
    int? openIssues,
    int? watchers,
    String? defaultBranch,
  }) =>
      Repo(
        id: id ?? this.id,
        nodeId: nodeId ?? this.nodeId,
        name: name ?? this.name,
        fullName: fullName ?? this.fullName,
        private: private ?? this.private,
        owner: owner ?? this.owner,
        htmlUrl: htmlUrl ?? this.htmlUrl,
        description: description ?? this.description,
        fork: fork ?? this.fork,
        url: url ?? this.url,
        forksUrl: forksUrl ?? this.forksUrl,
        keysUrl: keysUrl ?? this.keysUrl,
        collaboratorsUrl: collaboratorsUrl ?? this.collaboratorsUrl,
        teamsUrl: teamsUrl ?? this.teamsUrl,
        hooksUrl: hooksUrl ?? this.hooksUrl,
        issueEventsUrl: issueEventsUrl ?? this.issueEventsUrl,
        eventsUrl: eventsUrl ?? this.eventsUrl,
        assigneesUrl: assigneesUrl ?? this.assigneesUrl,
        branchesUrl: branchesUrl ?? this.branchesUrl,
        tagsUrl: tagsUrl ?? this.tagsUrl,
        blobsUrl: blobsUrl ?? this.blobsUrl,
        gitTagsUrl: gitTagsUrl ?? this.gitTagsUrl,
        gitRefsUrl: gitRefsUrl ?? this.gitRefsUrl,
        treesUrl: treesUrl ?? this.treesUrl,
        statusesUrl: statusesUrl ?? this.statusesUrl,
        languagesUrl: languagesUrl ?? this.languagesUrl,
        stargazersUrl: stargazersUrl ?? this.stargazersUrl,
        contributorsUrl: contributorsUrl ?? this.contributorsUrl,
        subscribersUrl: subscribersUrl ?? this.subscribersUrl,
        subscriptionUrl: subscriptionUrl ?? this.subscriptionUrl,
        commitsUrl: commitsUrl ?? this.commitsUrl,
        gitCommitsUrl: gitCommitsUrl ?? this.gitCommitsUrl,
        commentsUrl: commentsUrl ?? this.commentsUrl,
        issueCommentUrl: issueCommentUrl ?? this.issueCommentUrl,
        contentsUrl: contentsUrl ?? this.contentsUrl,
        compareUrl: compareUrl ?? this.compareUrl,
        mergesUrl: mergesUrl ?? this.mergesUrl,
        archiveUrl: archiveUrl ?? this.archiveUrl,
        downloadsUrl: downloadsUrl ?? this.downloadsUrl,
        issuesUrl: issuesUrl ?? this.issuesUrl,
        pullsUrl: pullsUrl ?? this.pullsUrl,
        milestonesUrl: milestonesUrl ?? this.milestonesUrl,
        notificationsUrl: notificationsUrl ?? this.notificationsUrl,
        labelsUrl: labelsUrl ?? this.labelsUrl,
        releasesUrl: releasesUrl ?? this.releasesUrl,
        deploymentsUrl: deploymentsUrl ?? this.deploymentsUrl,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        pushedAt: pushedAt ?? this.pushedAt,
        gitUrl: gitUrl ?? this.gitUrl,
        sshUrl: sshUrl ?? this.sshUrl,
        cloneUrl: cloneUrl ?? this.cloneUrl,
        svnUrl: svnUrl ?? this.svnUrl,
        homepage: homepage ?? this.homepage,
        size: size ?? this.size,
        stargazersCount: stargazersCount ?? this.stargazersCount,
        watchersCount: watchersCount ?? this.watchersCount,
        language: language ?? this.language,
        hasIssues: hasIssues ?? this.hasIssues,
        hasProjects: hasProjects ?? this.hasProjects,
        hasDownloads: hasDownloads ?? this.hasDownloads,
        hasWiki: hasWiki ?? this.hasWiki,
        hasPages: hasPages ?? this.hasPages,
        forksCount: forksCount ?? this.forksCount,
        mirrorUrl: mirrorUrl ?? this.mirrorUrl,
        archived: archived ?? this.archived,
        disabled: disabled ?? this.disabled,
        openIssuesCount: openIssuesCount ?? this.openIssuesCount,
        license: license ?? this.license,
        forks: forks ?? this.forks,
        openIssues: openIssues ?? this.openIssues,
        watchers: watchers ?? this.watchers,
        defaultBranch: defaultBranch ?? this.defaultBranch,
      );

  factory Repo.fromRawJson(String str) => Repo.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Repo.fromJson(Map<String, dynamic> json) => Repo(
        id: json["id"] == null ? null : json["id"],
        nodeId: json["node_id"] == null ? null : json["node_id"],
        name: json["name"] == null ? null : json["name"],
        fullName: json["full_name"] == null ? null : json["full_name"],
        private: json["private"] == null ? null : json["private"],
        owner: json["owner"] == null
            ? null
            : UserInfoModel.fromJson(json["owner"]),
        htmlUrl: json["html_url"] == null ? null : json["html_url"],
        description: json["description"] == null ? null : json["description"],
        fork: json["fork"] == null ? null : json["fork"],
        url: json["url"] == null ? null : json["url"],
        forksUrl: json["forks_url"] == null ? null : json["forks_url"],
        keysUrl: json["keys_url"] == null ? null : json["keys_url"],
        collaboratorsUrl: json["collaborators_url"] == null
            ? null
            : json["collaborators_url"],
        teamsUrl: json["teams_url"] == null ? null : json["teams_url"],
        hooksUrl: json["hooks_url"] == null ? null : json["hooks_url"],
        issueEventsUrl:
            json["issue_events_url"] == null ? null : json["issue_events_url"],
        eventsUrl: json["events_url"] == null ? null : json["events_url"],
        assigneesUrl:
            json["assignees_url"] == null ? null : json["assignees_url"],
        branchesUrl: json["branches_url"] == null ? null : json["branches_url"],
        tagsUrl: json["tags_url"] == null ? null : json["tags_url"],
        blobsUrl: json["blobs_url"] == null ? null : json["blobs_url"],
        gitTagsUrl: json["git_tags_url"] == null ? null : json["git_tags_url"],
        gitRefsUrl: json["git_refs_url"] == null ? null : json["git_refs_url"],
        treesUrl: json["trees_url"] == null ? null : json["trees_url"],
        statusesUrl: json["statuses_url"] == null ? null : json["statuses_url"],
        languagesUrl:
            json["languages_url"] == null ? null : json["languages_url"],
        stargazersUrl:
            json["stargazers_url"] == null ? null : json["stargazers_url"],
        contributorsUrl:
            json["contributors_url"] == null ? null : json["contributors_url"],
        subscribersUrl:
            json["subscribers_url"] == null ? null : json["subscribers_url"],
        subscriptionUrl:
            json["subscription_url"] == null ? null : json["subscription_url"],
        commitsUrl: json["commits_url"] == null ? null : json["commits_url"],
        gitCommitsUrl:
            json["git_commits_url"] == null ? null : json["git_commits_url"],
        commentsUrl: json["comments_url"] == null ? null : json["comments_url"],
        issueCommentUrl: json["issue_comment_url"] == null
            ? null
            : json["issue_comment_url"],
        contentsUrl: json["contents_url"] == null ? null : json["contents_url"],
        compareUrl: json["compare_url"] == null ? null : json["compare_url"],
        mergesUrl: json["merges_url"] == null ? null : json["merges_url"],
        archiveUrl: json["archive_url"] == null ? null : json["archive_url"],
        downloadsUrl:
            json["downloads_url"] == null ? null : json["downloads_url"],
        issuesUrl: json["issues_url"] == null ? null : json["issues_url"],
        pullsUrl: json["pulls_url"] == null ? null : json["pulls_url"],
        milestonesUrl:
            json["milestones_url"] == null ? null : json["milestones_url"],
        notificationsUrl: json["notifications_url"] == null
            ? null
            : json["notifications_url"],
        labelsUrl: json["labels_url"] == null ? null : json["labels_url"],
        releasesUrl: json["releases_url"] == null ? null : json["releases_url"],
        deploymentsUrl:
            json["deployments_url"] == null ? null : json["deployments_url"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
        pushedAt: json["pushed_at"] == null
            ? null
            : DateTime.parse(json["pushed_at"]),
        gitUrl: json["git_url"] == null ? null : json["git_url"],
        sshUrl: json["ssh_url"] == null ? null : json["ssh_url"],
        cloneUrl: json["clone_url"] == null ? null : json["clone_url"],
        svnUrl: json["svn_url"] == null ? null : json["svn_url"],
        homepage: json["homepage"] == null ? null : json["homepage"],
        size: json["size"] == null ? null : json["size"],
        stargazersCount:
            json["stargazers_count"] == null ? null : json["stargazers_count"],
        watchersCount:
            json["watchers_count"] == null ? null : json["watchers_count"],
        language: json["language"] == null ? null : json["language"],
        hasIssues: json["has_issues"] == null ? null : json["has_issues"],
        hasProjects: json["has_projects"] == null ? null : json["has_projects"],
        hasDownloads:
            json["has_downloads"] == null ? null : json["has_downloads"],
        hasWiki: json["has_wiki"] == null ? null : json["has_wiki"],
        hasPages: json["has_pages"] == null ? null : json["has_pages"],
        forksCount: json["forks_count"] == null ? null : json["forks_count"],
        mirrorUrl: json["mirror_url"],
        archived: json["archived"] == null ? null : json["archived"],
        disabled: json["disabled"] == null ? null : json["disabled"],
        openIssuesCount: json["open_issues_count"] == null
            ? null
            : json["open_issues_count"],
        license:
            json["license"] == null ? null : License.fromJson(json["license"]),
        forks: json["forks"] == null ? null : json["forks"],
        openIssues: json["open_issues"] == null ? null : json["open_issues"],
        watchers: json["watchers"] == null ? null : json["watchers"],
        defaultBranch:
            json["default_branch"] == null ? null : json["default_branch"],
      );

  Map<String, dynamic> toJson() => {
        "id": id == null ? null : id,
        "node_id": nodeId == null ? null : nodeId,
        "name": name == null ? null : name,
        "full_name": fullName == null ? null : fullName,
        "private": private == null ? null : private,
        "owner": owner == null ? null : owner!.toJson(),
        "html_url": htmlUrl == null ? null : htmlUrl,
        "description": description == null ? null : description,
        "fork": fork == null ? null : fork,
        "url": url == null ? null : url,
        "forks_url": forksUrl == null ? null : forksUrl,
        "keys_url": keysUrl == null ? null : keysUrl,
        "collaborators_url": collaboratorsUrl == null ? null : collaboratorsUrl,
        "teams_url": teamsUrl == null ? null : teamsUrl,
        "hooks_url": hooksUrl == null ? null : hooksUrl,
        "issue_events_url": issueEventsUrl == null ? null : issueEventsUrl,
        "events_url": eventsUrl == null ? null : eventsUrl,
        "assignees_url": assigneesUrl == null ? null : assigneesUrl,
        "branches_url": branchesUrl == null ? null : branchesUrl,
        "tags_url": tagsUrl == null ? null : tagsUrl,
        "blobs_url": blobsUrl == null ? null : blobsUrl,
        "git_tags_url": gitTagsUrl == null ? null : gitTagsUrl,
        "git_refs_url": gitRefsUrl == null ? null : gitRefsUrl,
        "trees_url": treesUrl == null ? null : treesUrl,
        "statuses_url": statusesUrl == null ? null : statusesUrl,
        "languages_url": languagesUrl == null ? null : languagesUrl,
        "stargazers_url": stargazersUrl == null ? null : stargazersUrl,
        "contributors_url": contributorsUrl == null ? null : contributorsUrl,
        "subscribers_url": subscribersUrl == null ? null : subscribersUrl,
        "subscription_url": subscriptionUrl == null ? null : subscriptionUrl,
        "commits_url": commitsUrl == null ? null : commitsUrl,
        "git_commits_url": gitCommitsUrl == null ? null : gitCommitsUrl,
        "comments_url": commentsUrl == null ? null : commentsUrl,
        "issue_comment_url": issueCommentUrl == null ? null : issueCommentUrl,
        "contents_url": contentsUrl == null ? null : contentsUrl,
        "compare_url": compareUrl == null ? null : compareUrl,
        "merges_url": mergesUrl == null ? null : mergesUrl,
        "archive_url": archiveUrl == null ? null : archiveUrl,
        "downloads_url": downloadsUrl == null ? null : downloadsUrl,
        "issues_url": issuesUrl == null ? null : issuesUrl,
        "pulls_url": pullsUrl == null ? null : pullsUrl,
        "milestones_url": milestonesUrl == null ? null : milestonesUrl,
        "notifications_url": notificationsUrl == null ? null : notificationsUrl,
        "labels_url": labelsUrl == null ? null : labelsUrl,
        "releases_url": releasesUrl == null ? null : releasesUrl,
        "deployments_url": deploymentsUrl == null ? null : deploymentsUrl,
        "created_at": createdAt == null ? null : createdAt!.toIso8601String(),
        "updated_at": updatedAt == null ? null : updatedAt!.toIso8601String(),
        "pushed_at": pushedAt == null ? null : pushedAt!.toIso8601String(),
        "git_url": gitUrl == null ? null : gitUrl,
        "ssh_url": sshUrl == null ? null : sshUrl,
        "clone_url": cloneUrl == null ? null : cloneUrl,
        "svn_url": svnUrl == null ? null : svnUrl,
        "homepage": homepage == null ? null : homepage,
        "size": size == null ? null : size,
        "stargazers_count": stargazersCount == null ? null : stargazersCount,
        "watchers_count": watchersCount == null ? null : watchersCount,
        "language": language == null ? null : language,
        "has_issues": hasIssues == null ? null : hasIssues,
        "has_projects": hasProjects == null ? null : hasProjects,
        "has_downloads": hasDownloads == null ? null : hasDownloads,
        "has_wiki": hasWiki == null ? null : hasWiki,
        "has_pages": hasPages == null ? null : hasPages,
        "forks_count": forksCount == null ? null : forksCount,
        "mirror_url": mirrorUrl,
        "archived": archived == null ? null : archived,
        "disabled": disabled == null ? null : disabled,
        "open_issues_count": openIssuesCount == null ? null : openIssuesCount,
        "license": license == null ? null : license!.toJson(),
        "forks": forks == null ? null : forks,
        "open_issues": openIssues == null ? null : openIssues,
        "watchers": watchers == null ? null : watchers,
        "default_branch": defaultBranch == null ? null : defaultBranch,
      };
}

class License {
  License({
    this.key,
    this.name,
    this.spdxId,
    this.url,
    this.nodeId,
  });

  String? key;
  String? name;
  String? spdxId;
  String? url;
  String? nodeId;

  License copyWith({
    String? key,
    String? name,
    String? spdxId,
    String? url,
    String? nodeId,
  }) =>
      License(
        key: key ?? this.key,
        name: name ?? this.name,
        spdxId: spdxId ?? this.spdxId,
        url: url ?? this.url,
        nodeId: nodeId ?? this.nodeId,
      );

  factory License.fromRawJson(String str) => License.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory License.fromJson(Map<String, dynamic> json) => License(
        key: json["key"] == null ? null : json["key"],
        name: json["name"] == null ? null : json["name"],
        spdxId: json["spdx_id"] == null ? null : json["spdx_id"],
        url: json["url"] == null ? null : json["url"],
        nodeId: json["node_id"] == null ? null : json["node_id"],
      );

  Map<String, dynamic> toJson() => {
        "key": key == null ? null : key,
        "name": name == null ? null : name,
        "spdx_id": spdxId == null ? null : spdxId,
        "url": url == null ? null : url,
        "node_id": nodeId == null ? null : nodeId,
      };
}

class Links {
  Links({
    this.self,
    this.html,
    this.issue,
    this.comments,
    this.reviewComments,
    this.reviewComment,
    this.commits,
    this.statuses,
  });

  Comments? self;
  Comments? html;
  Comments? issue;
  Comments? comments;
  Comments? reviewComments;
  Comments? reviewComment;
  Comments? commits;
  Comments? statuses;

  Links copyWith({
    Comments? self,
    Comments? html,
    Comments? issue,
    Comments? comments,
    Comments? reviewComments,
    Comments? reviewComment,
    Comments? commits,
    Comments? statuses,
  }) =>
      Links(
        self: self ?? this.self,
        html: html ?? this.html,
        issue: issue ?? this.issue,
        comments: comments ?? this.comments,
        reviewComments: reviewComments ?? this.reviewComments,
        reviewComment: reviewComment ?? this.reviewComment,
        commits: commits ?? this.commits,
        statuses: statuses ?? this.statuses,
      );

  factory Links.fromRawJson(String str) => Links.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Links.fromJson(Map<String, dynamic> json) => Links(
        self: json["self"] == null ? null : Comments.fromJson(json["self"]),
        html: json["html"] == null ? null : Comments.fromJson(json["html"]),
        issue: json["issue"] == null ? null : Comments.fromJson(json["issue"]),
        comments: json["comments"] == null
            ? null
            : Comments.fromJson(json["comments"]),
        reviewComments: json["review_comments"] == null
            ? null
            : Comments.fromJson(json["review_comments"]),
        reviewComment: json["review_comment"] == null
            ? null
            : Comments.fromJson(json["review_comment"]),
        commits:
            json["commits"] == null ? null : Comments.fromJson(json["commits"]),
        statuses: json["statuses"] == null
            ? null
            : Comments.fromJson(json["statuses"]),
      );

  Map<String, dynamic> toJson() => {
        "self": self == null ? null : self!.toJson(),
        "html": html == null ? null : html!.toJson(),
        "issue": issue == null ? null : issue!.toJson(),
        "comments": comments == null ? null : comments!.toJson(),
        "review_comments":
            reviewComments == null ? null : reviewComments!.toJson(),
        "review_comment":
            reviewComment == null ? null : reviewComment!.toJson(),
        "commits": commits == null ? null : commits!.toJson(),
        "statuses": statuses == null ? null : statuses!.toJson(),
      };
}

class Comments {
  Comments({
    this.href,
  });

  String? href;

  Comments copyWith({
    String? href,
  }) =>
      Comments(
        href: href ?? this.href,
      );

  factory Comments.fromRawJson(String str) =>
      Comments.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Comments.fromJson(Map<String, dynamic> json) => Comments(
        href: json["href"] == null ? null : json["href"],
      );

  Map<String, dynamic> toJson() => {
        "href": href == null ? null : href,
      };
}
