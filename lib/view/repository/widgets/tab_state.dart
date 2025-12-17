/// Helper class to centralize tab state information
class TabState {
  const TabState({
    required this.currentTab,
  });

  final String currentTab;

  bool get isOnIssuesTab => currentTab == 'Issues';
  bool get isOnReadmeTab => currentTab == 'Readme';
  bool get isOnCodeTab => currentTab == 'Code';
  bool get isOnPullRequestsTab => currentTab == 'Pull Requests';
  bool get isOnMoreTab => currentTab == 'More';
}
