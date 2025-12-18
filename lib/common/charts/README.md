# Charts & Visualization Widgets

This directory contains reusable chart and visualization widgets that can be used throughout the app.

## Widgets

### 1. `radar_chart_widget.dart`
A reusable radar (spider) chart widget for visualizing multivariate data.

**Usage:**
```dart
RadarChartWidget(
  data: [58, 17, 25],
  labels: ['Commits', 'Issues', 'Pull Requests'],
  maxValue: 100,
)

// Or use the contribution-specific wrapper:
ContributionRadarChart(
  commits: 100,
  issues: 30,
  pullRequests: 50,
)
```

**Features:**
- Generic and reusable
- Theme-aware colors
- Customizable styling
- Contribution-specific wrapper included

### 2. `contribution_calendar_widget.dart`
A GitHub-style contribution calendar heatmap widget.

**Usage:**
```dart
ContributionCalendarWidget(
  weeks: contributionWeeks,
  colors: ['#ebedf0', '#9be9a8', '#40c463', '#30a14e', '#216e39'],
  onDayTap: (day) => showDayDetails(day),
)
```

**Features:**
- GitHub-style grid layout
- Interactive (tap, long-press)
- Customizable colors and sizes
- Month and day labels
- Legend support

### 3. `stat_card_widget.dart`
A reusable stat card for displaying metrics with icons.

**Usage:**
```dart
StatCardWidget(
  icon: Octicons.git_commit,
  value: '1,234',
  label: 'Commits',
  color: Colors.green,
  onTap: () => navigateToCommits(),
)

// Or use the grid layout:
StatCardGrid(
  stats: [
    StatCardData(icon: ..., value: ..., label: ...),
    ...
  ],
)
```

**Features:**
- Icon + value + label layout
- Tappable with visual feedback
- Grid layout support
- Theme-aware

### 4. `language_distribution_chart.dart`
A horizontal bar chart for language distribution.

**Usage:**
```dart
LanguageDistributionChart(
  languages: [
    LanguageData(name: 'JavaScript', percentage: 45.0, color: Colors.yellow),
    LanguageData(name: 'TypeScript', percentage: 30.0, color: Colors.blue),
  ],
  maxLanguages: 5,
)
```

**Features:**
- Horizontal bar chart
- Percentage display
- Optional size display
- Color-coded bars
- Tappable bars

## Dependencies

These widgets use:
- `fl_chart: ^0.69.0` - For radar charts
- `contribution_heatmap: ^0.5.1` - Optional, for contribution calendar (we built our own)

## Design Principles

1. **Reusability**: All widgets are generic and can be used in multiple contexts
2. **Theme Awareness**: Widgets adapt to light/dark themes automatically
3. **Customization**: Extensive customization options while maintaining sensible defaults
4. **Accessibility**: Support for screen readers and keyboard navigation
5. **Performance**: Optimized for smooth rendering

## Future Additions

- Line chart widget
- Bar chart widget
- Pie chart widget
- Trend chart widget
- Comparison chart widget

